# MindMyWords

iOS speech habit coach app. Listens for custom trigger words/phrases using Apple SFSpeechRecognizer.

## Stack
- Swift / SwiftUI, iOS 17+
- SFSpeechRecognizer (on-device, no server)
- SwiftData for persistence
- MVVM architecture
- XcodeGen for project generation

## Project Structure
- `MindMyWords/Models/` — SwiftData models (TriggerWord, DetectionLog)
- `MindMyWords/Services/` — Speech recognition, word detection, haptics, sound
- `MindMyWords/ViewModels/` — MVVM view models
- `MindMyWords/Views/` — SwiftUI views
- `MindMyWords/Persistence/` — SettingsManager (UserDefaults)
- `project.yml` — XcodeGen project definition

## Build
Run `xcodegen generate` to create .xcodeproj, then build with Xcode or xcodebuild.
CI uses GitHub Actions with macos-15 runner.

## Key Patterns
- SFSpeechRecognizer has ~1 min cap per request — auto-restarts in a loop
- Word detection uses word-boundary matching (from SwearJar)
- 3-second deduplication window prevents repeated detections
- On-device recognition only (requiresOnDeviceRecognition = true)
