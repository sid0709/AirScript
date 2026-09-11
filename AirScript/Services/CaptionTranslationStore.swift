import Foundation
import Observation
import Translation

@Observable
final class CaptionTranslationStore {
    struct Key: Hashable, Sendable {
        let source: String
        let target: String
    }

    struct AppleJob: Equatable, Sendable {
        let token: Int
        let sentences: [String]
    }

    private(set) var values: [Key: String] = [:]
    private(set) var appleJobs: [String: AppleJob] = [:]

    @ObservationIgnored private var inFlight: Set<Key> = []
    @ObservationIgnored private var failedUntil: [Key: Date] = [:]
    @ObservationIgnored private var appleSupported: [String: Bool] = [:]
    @ObservationIgnored private var idleTask: Task<Void, Never>?
    @ObservationIgnored private var retryTask: Task<Void, Never>?
    @ObservationIgnored private var idleFingerprint = ""
    @ObservationIgnored private var lastSentences: [String] = []
    @ObservationIgnored private var lastLanguages: [TranslationLanguage] = []
    @ObservationIgnored private var generation = 0

    func value(source: String, target: String) -> String? {
        let text = values[Key(source: source, target: target)]
        guard let text, !text.isEmpty else { return nil }
        return text
    }

    func reset() {
        generation += 1
        idleTask?.cancel()
        retryTask?.cancel()
        idleTask = nil
        retryTask = nil
        idleFingerprint = ""
        lastSentences = []
        lastLanguages = []
        values.removeAll()
        appleJobs.removeAll()
        inFlight.removeAll()
        failedUntil.removeAll()
    }

    func observe(sentences: [String], languages: [TranslationLanguage]) {
        lastSentences = sentences
        lastLanguages = languages
        guard !languages.isEmpty else {
            idleTask?.cancel()
            return
        }
        for language in languages {
            let plan = CaptionTranslationPlanner.plan(sentences: sentences) { source in
                shouldSkip(source, language: language)
            }
            enqueue(plan.completedBatch, language: language)
        }
        scheduleIdle(sentences: sentences, languages: languages)
    }

    func applyAppleResults(_ results: [String: String], language: TranslationLanguage, token: Int) {
        guard appleJobs[language.id]?.token == token else { return }
        let job = appleJobs[language.id]
        appleJobs[language.id] = nil
        var missing: [String] = []
        for source in job?.sentences ?? [] {
            if let translated = results[source], !translated.isEmpty {
                storeSuccess(source, language: language, text: translated)
            } else {
                missing.append(source)
            }
        }
        if !missing.isEmpty {
            fallbackToGoogle(missing, language: language)
        }
    }

    func fallbackToGoogle(_ sentences: [String], language: TranslationLanguage) {
        Task { await translateWithGoogle(sentences, language: language) }
    }

    private func shouldSkip(_ source: String, language: TranslationLanguage) -> Bool {
        let key = Key(source: source, target: language.id)
        if let text = values[key], !text.isEmpty { return true }
        if inFlight.contains(key) { return true }
        if let until = failedUntil[key], until > Date() { return true }
        return false
    }

    private func storeSuccess(_ source: String, language: TranslationLanguage, text: String) {
        let key = Key(source: source, target: language.id)
        values[key] = text
        inFlight.remove(key)
        failedUntil[key] = nil
    }

    private func markFailed(_ sentences: [String], language: TranslationLanguage) {
        let until = Date().addingTimeInterval(8)
        for source in sentences {
            let key = Key(source: source, target: language.id)
            inFlight.remove(key)
            failedUntil[key] = until
        }
        scheduleRetry()
    }

    private func enqueue(_ sentences: [String], language: TranslationLanguage) {
        let pending = sentences.filter { !shouldSkip($0, language: language) }
        guard !pending.isEmpty else { return }
        for sentence in pending {
            inFlight.insert(Key(source: sentence, target: language.id))
        }
        Task {
            if await usesApple(language) {
                let token = (appleJobs[language.id]?.token ?? 0) + 1
                appleJobs[language.id] = AppleJob(token: token, sentences: pending)
                try? await Task.sleep(for: .seconds(2))
                let leftover = pending.filter {
                    inFlight.contains(Key(source: $0, target: language.id))
                }
                if !leftover.isEmpty {
                    await translateWithGoogle(leftover, language: language)
                }
            } else {
                await translateWithGoogle(pending, language: language)
            }
        }
    }

    private func usesApple(_ language: TranslationLanguage) async -> Bool {
        if let cached = appleSupported[language.id] { return cached }
        let status = await LanguageAvailability().status(
            from: Locale.Language(identifier: "en"),
            to: language.localeLanguage
        )
        let supported: Bool
        switch status {
        case .installed, .supported:
            supported = true
        default:
            supported = false
        }
        appleSupported[language.id] = supported
        return supported
    }

    private func translateWithGoogle(_ sentences: [String], language: TranslationLanguage) async {
        let translated = (try? await GoogleGTXTranslator.translateSentences(
            sentences,
            to: language.googleCode
        )) ?? []
        var failed: [String] = []
        for (index, source) in sentences.enumerated() {
            if index < translated.count, !translated[index].isEmpty {
                storeSuccess(source, language: language, text: translated[index])
            } else {
                failed.append(source)
            }
        }
        if !failed.isEmpty {
            markFailed(failed, language: language)
        }
    }

    private func scheduleIdle(sentences: [String], languages: [TranslationLanguage]) {
        let fingerprint = sentences.joined(separator: "\u{1e}")
        idleFingerprint = fingerprint
        idleTask?.cancel()
        let needsIdle = languages.contains { language in
            !CaptionTranslationPlanner.idleBatch(sentences: sentences) { source in
                shouldSkip(source, language: language)
            }.isEmpty
        }
        guard needsIdle else { return }
        idleTask = Task { [generation] in
            try? await Task.sleep(for: CaptionTranslationPlanner.idleInterval)
            guard !Task.isCancelled, self.generation == generation, idleFingerprint == fingerprint else { return }
            for language in languages {
                enqueue(
                    CaptionTranslationPlanner.idleBatch(sentences: sentences) { source in
                        shouldSkip(source, language: language)
                    },
                    language: language
                )
            }
        }
    }

    private func scheduleRetry() {
        retryTask?.cancel()
        let gen = generation
        retryTask = Task {
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled, generation == gen else { return }
            observe(sentences: lastSentences, languages: lastLanguages)
        }
    }
}
