import Foundation

final class WordDetectionService {
    /// Detects trigger words in the given text using word-boundary matching.
    /// Sorted by phrase length (longest first) to match multi-word phrases before single words.
    /// Tracks matched ranges to prevent overlapping detections.
    func detect(in text: String, triggerWords: [String]) -> [DetectionResult] {
        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty, !triggerWords.isEmpty else { return [] }

        let sortedPhrases = triggerWords
            .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted { $0.count > $1.count }

        var results: [DetectionResult] = []
        var matchedRanges: [Range<String.Index>] = []

        for phrase in sortedPhrases {
            var searchStart = normalizedText.startIndex

            while let range = normalizedText.range(of: phrase, range: searchStart..<normalizedText.endIndex) {
                // Check word boundaries
                let beforeOk = range.lowerBound == normalizedText.startIndex ||
                    !normalizedText[normalizedText.index(before: range.lowerBound)].isLetterOrDigit
                let afterOk = range.upperBound == normalizedText.endIndex ||
                    !normalizedText[range.upperBound].isLetterOrDigit

                // Check no overlap with existing matches
                let overlaps = matchedRanges.contains { existing in
                    range.overlaps(existing)
                }

                if beforeOk && afterOk && !overlaps {
                    results.append(DetectionResult(word: phrase))
                    matchedRanges.append(range)
                }

                searchStart = range.upperBound
            }
        }

        return results
    }
}

private extension Character {
    var isLetterOrDigit: Bool {
        isLetter || isNumber
    }
}
