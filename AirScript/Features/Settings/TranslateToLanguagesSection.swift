import SwiftUI

struct TranslateToLanguagesSection: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Section {
            ForEach(settings.translateToLanguages) { language in
                LabeledContent(language.name) {
                    Button("Remove", role: .destructive) {
                        settings.removeTranslateToLanguage(language)
                    }
                    .controlSize(.small)
                }
            }

            if settings.languagesAvailableToAdd.isEmpty {
                Text("Every supported language is already added.")
                    .foregroundStyle(.secondary)
            } else {
                Menu("Add Language") {
                    ForEach(settings.languagesAvailableToAdd) { language in
                        Button("\(language.name) (\(language.shortLabel))") {
                            settings.addTranslateToLanguage(language)
                        }
                    }
                }
                .controlSize(.regular)
            }
        } header: {
            Text("Translate to")
        } footer: {
            Text("English is the source. Translations run on this Mac, so AirScript still works if you move the app. The first time you use a language, macOS may download that language pack.")
        }
    }
}

#Preview {
    Form {
        TranslateToLanguagesSection(settings: AppSettings())
    }
    .formStyle(.grouped)
    .frame(width: 300, height: 280)
}
