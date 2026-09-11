import Foundation

struct CaptionTranslationPlan: Equatable, Sendable {
    /// Untranslated completed sentences from the first gap through the previous sentence.
    var completedBatch: [String]
    /// In-progress sentence; translate only after it stays unchanged.
    var idleSentence: String?
}

enum CaptionTranslationPlanner {
    static let idleInterval: Duration = .seconds(3)
    static let minimumLength = 2

    static func plan(sentences: [String], translated: (String) -> Bool) -> CaptionTranslationPlan {
        let parts = split(sentences)
        var batch: [String] = []
        if parts.current != nil {
            batch = untranslatedRange(parts.completed, translated: translated)
        }
        return CaptionTranslationPlan(completedBatch: batch, idleSentence: parts.current)
    }

    /// 3s of silence: the live fragment, or leftover completed sentences if speech stopped on a period.
    static func idleBatch(sentences: [String], translated: (String) -> Bool) -> [String] {
        let parts = split(sentences)
        if let current = parts.current {
            return usable(current, translated: translated)
        }
        return untranslatedRange(parts.completed, translated: translated)
    }

    private static func split(_ sentences: [String]) -> (completed: [String], current: String?) {
        let trimmed = sentences
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let last = trimmed.last else { return ([], nil) }
        if CaptionSentenceGrab.isComplete(last) {
            return (trimmed, nil)
        }
        return (Array(trimmed.dropLast()), last)
    }

    private static func untranslatedRange(_ completed: [String], translated: (String) -> Bool) -> [String] {
        guard let start = completed.firstIndex(where: { !translated($0) && $0.count >= minimumLength }) else {
            return []
        }
        return completed[start...].filter { !translated($0) && $0.count >= minimumLength }
    }

    private static func usable(_ sentence: String, translated: (String) -> Bool) -> [String] {
        sentence.count >= minimumLength && !translated(sentence) ? [sentence] : []
    }
}
