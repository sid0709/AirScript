import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                Toggle(isOn: $settings.alwaysOnTop) {
                    VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                        Text("Always on top")
                        Text("Keep AirScript above other windows.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.regular)

                Toggle(isOn: $settings.hideFromScreenCapture) {
                    VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                        Text("Hide from recordings")
                        Text("Visible on your display, hidden from screenshots and screen sharing.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.regular)
            } header: {
                Text("Window")
            }

            TranslateToLanguagesSection(settings: settings)
        }
        .formStyle(.grouped)
        .frame(width: 300)
        .frame(minHeight: 340)
        .containerBackground(for: .window) {
            WindowGlassBackground()
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppSettings())
        .frame(width: 300, height: 400)
}
