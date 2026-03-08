import Foundation
import Speech
import AVFoundation

enum SpeechRecognitionStatus {
    case idle
    case listening
    case unavailable
    case denied
}

@MainActor
final class SpeechRecognitionService: ObservableObject {
    @Published var status: SpeechRecognitionStatus = .idle
    @Published var currentTranscript: String = ""
    @Published var lastDetections: [DetectionResult] = []

    private let speechRecognizer: SFSpeechRecognizer
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let wordDetectionService = WordDetectionService()

    // Deduplication: track recently detected words with timestamps
    private var recentDetections: [String: Date] = [:]
    private let deduplicationWindow: TimeInterval = 3.0

    // Auto-restart timer for the ~1 minute recognition cap
    private var restartTimer: Timer?

    var triggerWords: [String] = []
    var onDetection: (([DetectionResult]) -> Void)?

    init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    }

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            status = .denied
            return false
        }

        let audioStatus: Bool
        if #available(iOS 17.0, *) {
            audioStatus = await AVAudioApplication.requestRecordPermission()
        } else {
            audioStatus = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        if !audioStatus {
            status = .denied
            return false
        }

        return true
    }

    func startListening() {
        guard speechRecognizer.isAvailable else {
            status = .unavailable
            return
        }

        stopListening()
        startRecognitionSession()
        scheduleRestart()
        status = .listening
    }

    func stopListening() {
        restartTimer?.invalidate()
        restartTimer = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        status = .idle
    }

    func updateLocale(_ locale: Locale) {
        let wasListening = status == .listening
        stopListening()

        // Recreate with new locale — SFSpeechRecognizer is not mutable
        // The caller should create a new service or we re-init
        if wasListening {
            startListening()
        }
    }

    // MARK: - Private

    private func startRecognitionSession() {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true

        if #available(iOS 17.0, *) {
            request.addsPunctuation = false
        }

        self.recognitionRequest = request

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            status = .unavailable
            return
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        do {
            try audioEngine.start()
        } catch {
            print("Audio engine failed to start: \(error)")
            status = .unavailable
            return
        }

        var lastProcessedText = ""

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.currentTranscript = text
                }

                // Only process new text (delta since last check)
                let newText: String
                if text.hasPrefix(lastProcessedText) {
                    newText = String(text.dropFirst(lastProcessedText.count))
                } else {
                    newText = text
                }
                lastProcessedText = text

                if !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let detections = self.wordDetectionService.detect(
                        in: newText,
                        triggerWords: self.triggerWords
                    )
                    let deduped = self.deduplicate(detections)
                    if !deduped.isEmpty {
                        Task { @MainActor in
                            self.lastDetections = deduped
                            self.onDetection?(deduped)
                        }
                    }
                }

                if result.isFinal {
                    self.restartSession()
                }
            }

            if let error {
                print("Recognition error: \(error.localizedDescription)")
                self.restartSession()
            }
        }
    }

    private func deduplicate(_ detections: [DetectionResult]) -> [DetectionResult] {
        let now = Date()
        // Clean old entries
        recentDetections = recentDetections.filter { now.timeIntervalSince($0.value) < deduplicationWindow }

        return detections.filter { detection in
            if let lastTime = recentDetections[detection.word],
               now.timeIntervalSince(lastTime) < deduplicationWindow {
                return false
            }
            recentDetections[detection.word] = now
            return true
        }
    }

    /// Restart recognition to work around the ~1 minute cap
    private func scheduleRestart() {
        restartTimer?.invalidate()
        restartTimer = Timer.scheduledTimer(withTimeInterval: 55, repeats: true) { [weak self] _ in
            self?.restartSession()
        }
    }

    private func restartSession() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // Brief delay before restarting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, self.status == .listening else { return }
            self.startRecognitionSession()
        }
    }
}
