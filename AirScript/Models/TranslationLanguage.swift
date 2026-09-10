import Foundation

struct TranslationLanguage: Identifiable, Hashable, Codable, Sendable {
    var id: String { code }

    /// BCP-47 code used by Apple Translation (`zh-Hans`).
    let code: String
    /// Google GTX `tl` code (`zh-CN`).
    let googleCode: String
    /// Compact chip label (`CN`).
    let shortLabel: String
    let name: String

    var localeLanguage: Locale.Language {
        Locale.Language(identifier: code)
    }
}

extension TranslationLanguage {
    static let english = TranslationLanguage(
        code: "en",
        googleCode: "en",
        shortLabel: "EN",
        name: "English"
    )

    static let catalog: [TranslationLanguage] = [
        TranslationLanguage(code: "zh-Hans", googleCode: "zh-CN", shortLabel: "CN", name: "Chinese, Simplified"),
        TranslationLanguage(code: "zh-Hant", googleCode: "zh-TW", shortLabel: "TW", name: "Chinese, Traditional"),
        TranslationLanguage(code: "ja", googleCode: "ja", shortLabel: "JA", name: "Japanese"),
        TranslationLanguage(code: "ko", googleCode: "ko", shortLabel: "KO", name: "Korean"),
        TranslationLanguage(code: "es", googleCode: "es", shortLabel: "ES", name: "Spanish"),
        TranslationLanguage(code: "fr", googleCode: "fr", shortLabel: "FR", name: "French"),
        TranslationLanguage(code: "de", googleCode: "de", shortLabel: "DE", name: "German"),
        TranslationLanguage(code: "pt-BR", googleCode: "pt", shortLabel: "PT", name: "Portuguese"),
        TranslationLanguage(code: "it", googleCode: "it", shortLabel: "IT", name: "Italian"),
        TranslationLanguage(code: "ru", googleCode: "ru", shortLabel: "RU", name: "Russian"),
        TranslationLanguage(code: "ar", googleCode: "ar", shortLabel: "AR", name: "Arabic"),
        TranslationLanguage(code: "hi", googleCode: "hi", shortLabel: "HI", name: "Hindi"),
        TranslationLanguage(code: "vi", googleCode: "vi", shortLabel: "VI", name: "Vietnamese"),
        TranslationLanguage(code: "th", googleCode: "th", shortLabel: "TH", name: "Thai"),
        TranslationLanguage(code: "id", googleCode: "id", shortLabel: "ID", name: "Indonesian"),
        TranslationLanguage(code: "nl", googleCode: "nl", shortLabel: "NL", name: "Dutch"),
        TranslationLanguage(code: "pl", googleCode: "pl", shortLabel: "PL", name: "Polish"),
        TranslationLanguage(code: "tr", googleCode: "tr", shortLabel: "TR", name: "Turkish"),
        TranslationLanguage(code: "uk", googleCode: "uk", shortLabel: "UK", name: "Ukrainian"),
        TranslationLanguage(code: "sv", googleCode: "sv", shortLabel: "SV", name: "Swedish"),
    ]

    static func named(_ code: String) -> TranslationLanguage? {
        if code == english.code { return english }
        return catalog.first { $0.code == code }
    }
}
