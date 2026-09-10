import SwiftUI

struct LiveCaptionPermissionView: View {
    let status: LiveCaptionStatus
    var onGrantAccessibility: () -> Void
    var onOpenLiveCaptions: () -> Void

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Label(title, systemImage: icon)
                    .font(.title2)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if status == .needsAccessibility {
                    Button("Allow Accessibility", action: onGrantAccessibility)
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Open Live Captions", action: onOpenLiveCaptions)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: 520)
    }

    private var title: String {
        status == .needsAccessibility ? "Accessibility access" : "Live Captions is off"
    }

    private var icon: String {
        status == .needsAccessibility ? "hand.raised.fill" : "captions.bubble"
    }

    private var message: String {
        if status == .needsAccessibility {
            "Enable AirScript in System Settings → Privacy & Security → Accessibility, then quit this app (⌘Q) and open Build/Debug/AirScript.app again. Do not use AirScriptUITests-Runner."
        } else {
            "Turn on Live Captions in System Settings → Accessibility → Live Captions."
        }
    }
}

#Preview {
    LiveCaptionPermissionView(
        status: .needsAccessibility,
        onGrantAccessibility: {},
        onOpenLiveCaptions: {}
    )
    .padding(DS.Spacing.lg)
}
