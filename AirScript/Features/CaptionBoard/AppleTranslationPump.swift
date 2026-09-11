import SwiftUI
import Translation

struct AppleTranslationPump: View {
    let language: TranslationLanguage
    let job: CaptionTranslationStore.AppleJob
    var onComplete: ([String: String]) -> Void
    var onFailure: ([String]) -> Void

    var body: some View {
        Color.clear
            .accessibilityHidden(true)
            .allowsHitTesting(false)
            .translationTask(
                source: Locale.Language(identifier: "en"),
                target: language.localeLanguage
            ) { session in
                let sentences = job.sentences
                guard !sentences.isEmpty else { return }
                do {
                    let requests = sentences.map { text in
                        TranslationSession.Request(sourceText: text, clientIdentifier: text)
                    }
                    let responses = try await session.translations(from: requests)
                    var map: [String: String] = [:]
                    for response in responses {
                        if let identifier = response.clientIdentifier {
                            map[identifier] = response.targetText
                        }
                    }
                    onComplete(map)
                } catch {
                    onFailure(sentences)
                }
            }
            .id("\(language.id)-\(job.token)")
    }
}
