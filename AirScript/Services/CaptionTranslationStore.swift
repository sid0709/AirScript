import Foundation
import Observation

@Observable
final class CaptionTranslationStore {
    struct Key: Hashable, Sendable {
        let source: String
        let target: String
    }

    private(set) var values: [Key: String] = [:]

    @ObservationIgnored private var inFlight: Set<Key> = []
    @ObservationIgnored private var flushTail: Task<Void, Never> = Task {}
    @ObservationIgnored private var generation = 0

    func value(source: String, target: String) -> String? {
        let text = values[Key(source: source, target: target)]
        guard let text, !text.isEmpty else { return nil }
        return text
    }

    func reset() {
        generation += 1
        flushTail = Task {}
        values.removeAll()
        inFlight.removeAll()
    }

    func ensure(sentences: [String], languages: [TranslationLanguage]) {
        guard !languages.isEmpty, !sentences.isEmpty else { return }
        enqueueFlush(sentences: sentences, languages: languages)
    }

    private func enqueueFlush(sentences: [String], languages: [TranslationLanguage]) {
        let gen = generation
        flushTail = Task { [flushTail] in
            await flushTail.value
            guard generation == gen else { return }
            await flush(sentences: sentences, languages: languages)
        }
    }

    private func flush(sentences: [String], languages: [TranslationLanguage]) async {
        for language in languages {
            let pending = sentences.filter { sentence in
                let key = Key(source: sentence, target: language.id)
                return values[key] == nil && !inFlight.contains(key)
            }
            guard !pending.isEmpty else { continue }
            for sentence in pending {
                inFlight.insert(Key(source: sentence, target: language.id))
            }
            await translate(pending, language: language)
        }
    }

    private func translate(_ texts: [String], language: TranslationLanguage) async {
        await withTaskGroup(of: (Key, String?).self) { group in
            for text in texts {
                let key = Key(source: text, target: language.id)
                group.addTask {
                    let translated = try? await GoogleGTXTranslator.translate(text, to: language.googleCode)
                    return (key, translated)
                }
            }
            for await (key, translated) in group {
                values[key] = (translated?.isEmpty == false) ? translated : ""
                inFlight.remove(key)
            }
        }
    }
}
