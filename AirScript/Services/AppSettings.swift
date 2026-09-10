import Foundation
import Observation

@Observable
final class AppSettings {
    static let hideFromScreenCaptureKey = "hideFromScreenCapture"
    static let translateToLanguageCodesKey = "translateToLanguageCodes"
    static let visibleLanguageCodesKey = "visibleLanguageCodes"
    static let englishCode = TranslationLanguage.english.code

    static var hideFromScreenCapture: Bool {
        UserDefaults.standard.bool(forKey: hideFromScreenCaptureKey)
    }

    var hideFromScreenCapture = false {
        didSet {
            defaults.set(hideFromScreenCapture, forKey: Self.hideFromScreenCaptureKey)
            ScreenCaptureStealth.apply(enabled: hideFromScreenCapture)
        }
    }

    /// Target languages the user added in Settings, in display order.
    var translateToLanguageCodes: [String] = [] {
        didSet { defaults.set(translateToLanguageCodes, forKey: Self.translateToLanguageCodesKey) }
    }

    /// Board toggles currently on (`en` plus any added targets).
    var visibleLanguageCodes: [String] = [TranslationLanguage.english.code] {
        didSet { defaults.set(visibleLanguageCodes, forKey: Self.visibleLanguageCodesKey) }
    }

    var translateToLanguages: [TranslationLanguage] {
        translateToLanguageCodes.compactMap(TranslationLanguage.named)
    }

    var visibleTranslateLanguages: [TranslationLanguage] {
        translateToLanguages.filter { visibleLanguageCodes.contains($0.id) }
    }

    var showsEnglish: Bool {
        visibleLanguageCodes.contains(Self.englishCode)
    }

    var toggleLanguages: [TranslationLanguage] {
        [TranslationLanguage.english] + translateToLanguages
    }

    var languagesAvailableToAdd: [TranslationLanguage] {
        TranslationLanguage.catalog.filter { !translateToLanguageCodes.contains($0.id) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hideFromScreenCapture = defaults.bool(forKey: Self.hideFromScreenCaptureKey)
        let targets = Self.sanitizedTargets(
            defaults.stringArray(forKey: Self.translateToLanguageCodesKey) ?? []
        )
        translateToLanguageCodes = targets
        if defaults.object(forKey: Self.visibleLanguageCodesKey) == nil {
            visibleLanguageCodes = [Self.englishCode]
        } else {
            visibleLanguageCodes = Self.sanitizedVisible(
                defaults.stringArray(forKey: Self.visibleLanguageCodesKey) ?? [Self.englishCode],
                targets: targets
            )
        }
    }

    func addTranslateToLanguage(_ language: TranslationLanguage) {
        guard language.id != Self.englishCode else { return }
        if !translateToLanguageCodes.contains(language.id) {
            translateToLanguageCodes.append(language.id)
        }
        if !visibleLanguageCodes.contains(language.id) {
            visibleLanguageCodes.append(language.id)
        }
    }

    func removeTranslateToLanguage(_ language: TranslationLanguage) {
        translateToLanguageCodes.removeAll { $0 == language.id }
        visibleLanguageCodes.removeAll { $0 == language.id }
    }

    func isLanguageVisible(_ code: String) -> Bool {
        visibleLanguageCodes.contains(code)
    }

    func toggleLanguage(_ code: String) {
        if visibleLanguageCodes.contains(code) {
            visibleLanguageCodes.removeAll { $0 == code }
        } else {
            visibleLanguageCodes.append(code)
        }
    }

    private static func sanitizedTargets(_ codes: [String]) -> [String] {
        var seen = Set<String>()
        return codes.filter { code in
            guard code != englishCode, TranslationLanguage.named(code) != nil else { return false }
            return seen.insert(code).inserted
        }
    }

    private static func sanitizedVisible(_ codes: [String], targets: [String]) -> [String] {
        var seen = Set<String>()
        return codes.filter { code in
            let allowed = code == englishCode || targets.contains(code)
            return allowed && seen.insert(code).inserted
        }
    }
}
