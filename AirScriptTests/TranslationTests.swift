import Foundation
import Testing
@testable import AirScript

struct CaptionNotebookLayoutTests {
    private var chinese: TranslationLanguage { TranslationLanguage.catalog[0] }

    @Test func stacksTranslationUnderEachSentence() {
        let segments = CaptionNotebookLayout.segments(
            in: "Hello, how are you doing? Good.",
            showSource: true,
            languages: [chinese],
            translation: { source, _ in
                source.hasPrefix("Hello") ? "你好吗？" : "好。"
            }
        )
        #expect(segments.map(\.source) == ["Hello, how are you doing?", "Good."])
        #expect(segments[0].layers.map(\.text) == ["Hello, how are you doing?", "你好吗？"])
        #expect(segments[1].layers.map(\.text) == ["Good.", "好。"])
    }

    @Test func hidingEnglishLeavesOnlyTranslations() {
        let segments = CaptionNotebookLayout.segments(
            in: "Hello, how are you doing? Good.",
            showSource: false,
            languages: [chinese],
            translation: { source, _ in
                source.hasPrefix("Hello") ? "你好吗？" : "好。"
            }
        )
        #expect(segments[0].layers.map(\.text) == ["你好吗？"])
        #expect(segments[1].layers.map(\.text) == ["好。"])
        #expect(segments.flatMap(\.layers).allSatisfy { !$0.isSource })
    }

    @Test func originalShowsBeforeTranslationArrives() {
        let segments = CaptionNotebookLayout.segments(
            in: "Hello, how are you doing? Still talking",
            showSource: true,
            languages: [chinese],
            translation: { _, _ in nil }
        )
        #expect(segments.map(\.source) == ["Hello, how are you doing?", "Still talking"])
        #expect(segments[0].layers.map(\.text) == ["Hello, how are you doing?"])
        #expect(segments[1].layers.map(\.text) == ["Still talking"])
    }

    @Test func copyMatchesVisibleNotebook() {
        let lines = [
            CaptionLine(text: "Hello, how are you doing?", isLive: false),
            CaptionLine(text: "Good.", isLive: true),
        ]
        let text = CaptionNotebookText.grab(
            from: lines,
            count: 0,
            showSource: true,
            languages: [chinese],
            translation: { source, _ in
                source.hasPrefix("Hello") ? "你好吗？" : "好。"
            }
        )
        #expect(
            text == """
            Hello, how are you doing?
            你好吗？
            Good.
            好。
            """
        )
    }

    @Test func copyOmitsEnglishWhenToggledOff() {
        let lines = [CaptionLine(text: "Hello, how are you doing? Good.", isLive: false)]
        let text = CaptionNotebookText.grab(
            from: lines,
            count: 0,
            showSource: false,
            languages: [chinese],
            translation: { source, _ in
                source.hasPrefix("Hello") ? "你好吗？" : "好。"
            }
        )
        #expect(
            text == """
            你好吗？
            好。
            """
        )
    }
}

struct GoogleGTXTranslatorTests {
    @Test func parsesDJ1Sentences() throws {
        let json = Data(#"{"sentences":[{"trans":"你好。","orig":"Hello."}],"src":"en"}"#.utf8)
        #expect(try GoogleGTXTranslator.translatedText(from: json) == "你好。")
    }

    @Test func rejectsHtmlBlockPage() {
        let html = Data("<html><body>Sorry...</body></html>".utf8)
        #expect(throws: GoogleGTXError.blocked) {
            try GoogleGTXTranslator.translatedText(from: html)
        }
    }
}

struct AppSettingsTranslationTests {
    @Test func addingALanguageShowsAToggleAndTurnsItOn() {
        let settings = AppSettings(defaults: Self.freshDefaults())
        let chinese = TranslationLanguage.catalog[0]
        #expect(settings.toggleLanguages == [TranslationLanguage.english])
        #expect(settings.showsEnglish)

        settings.addTranslateToLanguage(chinese)
        #expect(settings.translateToLanguageCodes == [chinese.id])
        #expect(settings.isLanguageVisible(chinese.id))
        #expect(settings.toggleLanguages.map(\.shortLabel) == ["EN", "CN"])

        settings.toggleLanguage(TranslationLanguage.english.code)
        #expect(settings.showsEnglish == false)
        settings.toggleLanguage(chinese.id)
        #expect(settings.visibleTranslateLanguages.isEmpty)

        settings.removeTranslateToLanguage(chinese)
        #expect(settings.translateToLanguages.isEmpty)
        #expect(settings.toggleLanguages == [TranslationLanguage.english])
    }

    private static func freshDefaults() -> UserDefaults {
        let name = "AirScriptTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
