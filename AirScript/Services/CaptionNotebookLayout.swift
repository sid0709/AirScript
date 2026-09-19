import Foundation

enum CaptionNotebookLayout {
    struct Layer: Equatable, Identifiable, Sendable {
        let id: String
        let languageCode: String
        let text: String
        let isSource: Bool
        let isPending: Bool
    }

    struct Segment: Equatable, Identifiable, Sendable {
        let id: String
        let source: String
        let layers: [Layer]
    }

    static func segments(
        in text: String,
        showSource: Bool,
        languages: [TranslationLanguage],
        translation: (String, String) -> String?
    ) -> [Segment] {
        CaptionSentenceGrab.sentences(in: text).enumerated().compactMap { index, sentence in
            var layers: [Layer] = []
            if showSource {
                layers.append(
                    Layer(
                        id: "en-\(index)",
                        languageCode: TranslationLanguage.english.code,
                        text: sentence,
                        isSource: true,
                        isPending: false
                    )
                )
            }
            for language in languages {
                guard let translated = translation(sentence, language.id), !translated.isEmpty else {
                    continue
                }
                layers.append(
                    Layer(
                        id: "\(language.id)-\(index)",
                        languageCode: language.id,
                        text: translated,
                        isSource: false,
                        isPending: false
                    )
                )
            }
            guard !layers.isEmpty else { return nil }
            return Segment(id: "\(index)-\(sentence)", source: sentence, layers: layers)
        }
    }
}
