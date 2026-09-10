import Foundation
import Observation
import Translation

@Observable
final class CaptionTranslationStore {
    struct Key: Hashable, Sendable {
        let source: String
        let target: String
    }

    struct AppleBatch: Equatable, Sendable {
        let token: Int
        let texts: [String]
    }

    private(set) var values: [Key: String] = [:]
    private(set) var appleBatches: [String: AppleBatch] = [:]

    @ObservationIgnored private var inFlight: Set<Key> = []
    @ObservationIgnored private var failed: Set<Key> = []
    @ObservationIgnored private var appleSupported: [String: Bool] = [:]
    @ObservationIgnored private var debounceTask: Task<Void, Never>?
    @ObservationIgnored private var delayedWork: (sentences: [String], languages: [TranslationLanguage])?
    @ObservationIgnored private var flushTail: Task<Void, Never> = Task {}
    @ObservationIgnored private var generation = 0

    func value(source: String, target: String) -> String? {
        values[Key(source: source, target: target)]
    }

    func reset() {
        generation += 1
        debounceTask?.cancel()
        debounceTask = nil
        delayedWork = nil
        flushTail = Task {}
        values.removeAll()
        appleBatches.removeAll()
        inFlight.removeAll()
        failed.removeAll()
    }

    func ensure(sentences: [String], languages: [TranslationLanguage]) {
        guard !languages.isEmpty else {
            debounceTask?.cancel()
            appleBatches.removeAll()
            return
        }

        let usable = Self.usableSentences(sentences)
        let complete = usable.filter(Self.isComplete)
        let incomplete = usable.filter { !Self.isComplete($0) }

        if !complete.isEmpty {
            enqueueFlush(sentences: complete, languages: languages)
        }

        delayedWork = (incomplete, languages)
        debounceTask?.cancel()
        guard !incomplete.isEmpty else { return }
        debounceTask = Task { [delayedWork] in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled, let delayedWork else { return }
            enqueueFlush(sentences: delayedWork.sentences, languages: delayedWork.languages)
        }
    }

    private func enqueueFlush(sentences: [String], languages: [TranslationLanguage]) {
        let gen = generation
        flushTail = Task { [flushTail] in
            await flushTail.value
            guard generation == gen else { return }
            await flush(sentences: sentences, languages: languages)
        }
    }

    func applyAppleResults(_ results: [String: String], language: TranslationLanguage) {
        for (source, translated) in results where !translated.isEmpty {
            let key = Key(source: source, target: language.id)
            values[key] = translated
            inFlight.remove(key)
        }
        let missing = (appleBatches[language.id]?.texts ?? []).filter { results[$0] == nil || results[$0]?.isEmpty == true }
        if missing.isEmpty {
            appleBatches[language.id] = nil
        } else {
            fallbackToGoogle(missing, language: language)
        }
    }

    func fallbackToGoogle(_ texts: [String], language: TranslationLanguage) {
        Task { await translateWithGoogle(texts, language: language) }
    }

    private func flush(sentences: [String], languages: [TranslationLanguage]) async {
        for language in languages {
            if let previous = appleBatches[language.id] {
                for text in previous.texts {
                    inFlight.remove(Key(source: text, target: language.id))
                }
            }

            let pending = Self.uniqued(sentences).filter { sentence in
                let key = Key(source: sentence, target: language.id)
                return values[key] == nil && !inFlight.contains(key) && !failed.contains(key)
            }
            guard !pending.isEmpty else { continue }
            for sentence in pending {
                inFlight.insert(Key(source: sentence, target: language.id))
            }

            if await usesApple(for: language) {
                let token = (appleBatches[language.id]?.token ?? 0) + 1
                appleBatches[language.id] = AppleBatch(token: token, texts: pending)
            } else {
                await translateWithGoogle(pending, language: language)
            }
        }
    }

    private func usesApple(for language: TranslationLanguage) async -> Bool {
        if let cached = appleSupported[language.id] { return cached }
        let status = await LanguageAvailability().status(
            from: Locale.Language(identifier: "en"),
            to: language.localeLanguage
        )
        let supported: Bool
        switch status {
        case .installed, .supported:
            supported = true
        case .unsupported:
            supported = false
        @unknown default:
            supported = false
        }
        appleSupported[language.id] = supported
        return supported
    }

    private func translateWithGoogle(_ texts: [String], language: TranslationLanguage) async {
        await withTaskGroup(of: (Key, String?).self) { group in
            for text in texts {
                let key = Key(source: text, target: language.id)
                group.addTask {
                    let translated = try? await GoogleGTXTranslator.translate(text, to: language.googleCode)
                    return (key, translated)
                }
            }
            for await (key, translated) in group {
                if let translated, !translated.isEmpty {
                    values[key] = translated
                } else {
                    failed.insert(key)
                }
                inFlight.remove(key)
            }
        }
        appleBatches[language.id] = nil
    }

    private static func usableSentences(_ sentences: [String]) -> [String] {
        uniqued(
            sentences
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count >= 2 }
        )
    }

    private static func uniqued(_ items: [String]) -> [String] {
        var seen = Set<String>()
        return items.filter { seen.insert($0).inserted }
    }

    private static func isComplete(_ text: String) -> Bool {
        guard let last = text.last else { return false }
        return ".!?。！？".contains(last)
    }
}
