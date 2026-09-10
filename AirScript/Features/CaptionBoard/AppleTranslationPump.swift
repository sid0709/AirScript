import SwiftUI
import Translation

struct AppleTranslationPump: View {
    let language: TranslationLanguage
    let batch: CaptionTranslationStore.AppleBatch
    var onComplete: ([String: String]) -> Void
    var onFailure: ([String]) -> Void

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityHidden(true)
            .translationTask(
                source: Locale.Language(identifier: "en"),
                target: language.localeLanguage
            ) { session in
                let texts = batch.texts
                guard !texts.isEmpty else { return }
                do {
                    let requests = texts.map { text in
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
                    onFailure(texts)
                }
            }
            .id("\(language.id)-\(batch.token)")
    }
}
