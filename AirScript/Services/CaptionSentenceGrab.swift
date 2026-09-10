import Foundation

/// Splits the caption cache into sentences the way LastCry did (`.!?`),
/// then returns the most recent slice for a numpad grab.
enum CaptionSentenceGrab {
    static func grab(from lines: [CaptionLine], count: Int) -> String? {
        let cache = lines
            .map(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cache.isEmpty else { return nil }
        if count <= 0 { return cache }

        let parts = sentences(in: cache)
        guard !parts.isEmpty else { return cache }
        return parts.suffix(count).joined(separator: " ")
    }

    static func sentences(in text: String) -> [String] {
        var result: [String] = []
        var current = ""
        for character in text {
            current.append(character)
            if character == "." || character == "!" || character == "?"
                || character == "。" || character == "！" || character == "？" {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    result.append(trimmed)
                }
                current = ""
            }
        }
        let leftover = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !leftover.isEmpty {
            result.append(leftover)
        }
        return result
    }

    static func isComplete(_ text: String) -> Bool {
        guard let last = text.last else { return false }
        return ".!?。！？".contains(last)
    }

    /// Live leftovers stay off this list so English can paint before a translation exists.
    static func translatableSentences(from lines: [CaptionLine]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for line in lines {
            let parts = sentences(in: line.text)
            let slice = line.isLive ? parts.filter(isComplete) : parts
            for sentence in slice {
                let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 2, seen.insert(trimmed).inserted else { continue }
                result.append(trimmed)
            }
        }
        return result
    }
}
