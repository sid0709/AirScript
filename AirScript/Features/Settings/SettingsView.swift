import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                Toggle(isOn: $settings.hideFromScreenCapture) {
                    VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                        Text("Hide from screen recordings")
                        Text("Windows stay on your screen, but screenshots, recordings, and screen sharing will not include them.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.regular)
            } header: {
                Text("Stealth")
            }

            TranslateToLanguagesSection(settings: settings)
        }
        .formStyle(.grouped)
        .frame(minWidth: 420, idealWidth: 460, minHeight: 280)
        .containerBackground(for: .window) {
            WindowGlassBackground()
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppSettings())
        .frame(width: 460, height: 360)
}
