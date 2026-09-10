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
                if let translated = translation(sentence, language.id) {
                    layers.append(
                        Layer(
                            id: "\(language.id)-\(index)",
                            languageCode: language.id,
                            text: translated,
                            isSource: false,
                            isPending: false
                        )
                    )
                } else {
                    layers.append(
                        Layer(
                            id: "\(language.id)-\(index)-pending",
                            languageCode: language.id,
                            text: "…",
                            isSource: false,
                            isPending: true
                        )
                    )
                }
            }
            guard !layers.isEmpty else { return nil }
            return Segment(id: "\(index)-\(sentence)", source: sentence, layers: layers)
        }
    }
}

enum CaptionNotebookText {
    static func grab(
        from lines: [CaptionLine],
        count: Int,
        showSource: Bool,
        languages: [TranslationLanguage],
        translation: (String, String) -> String?
    ) -> String? {
        let sentences = CaptionSentenceGrab.sentences(
            in: lines.map(\.text).joined(separator: " ")
        )
        guard !sentences.isEmpty else { return nil }
        let slice = count <= 0 ? sentences[...] : sentences.suffix(count)
        if languages.isEmpty && showSource {
            return CaptionSentenceGrab.grab(from: lines, count: count)
        }

        var blocks: [String] = []
        for sentence in slice {
            var rows: [String] = []
            if showSource { rows.append(sentence) }
            for language in languages {
                if let translated = translation(sentence, language.id) {
                    rows.append(translated)
                }
            }
            if !rows.isEmpty {
                blocks.append(rows.joined(separator: "\n"))
            }
        }
        let joined = blocks.joined(separator: "\n")
        return joined.isEmpty ? nil : joined
    }
}
