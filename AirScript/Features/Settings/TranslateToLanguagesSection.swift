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
            Text("English is the source. Added languages appear as floating toggles on the board. Turn a language on to stack its translation under every sentence.")
        }
    }
}

#Preview {
    Form {
        TranslateToLanguagesSection(settings: AppSettings())
    }
    .formStyle(.grouped)
    .frame(width: 460, height: 280)
}
