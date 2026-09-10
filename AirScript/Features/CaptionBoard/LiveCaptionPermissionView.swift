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
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: DS.Spacing.xs) {
                    if status == .needsAccessibility {
                        Button("Allow Accessibility", action: onGrantAccessibility)
                            .keyboardShortcut(.defaultAction)
                    }
                    if status == .waitingForLiveCaptions || status == .overlayHidden {
                        Button("Open Live Captions", action: onOpenLiveCaptions)
                            .keyboardShortcut(.defaultAction)
                    }
                }
                .controlSize(.regular)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: 520)
    }

    private var title: String {
        switch status {
        case .needsAccessibility: "Accessibility access"
        case .waitingForLiveCaptions: "Live Captions is off"
        case .overlayHidden: "Waiting for speech"
        case .listening, .paused: ""
        }
    }

    private var icon: String {
        switch status {
        case .needsAccessibility: "hand.raised.fill"
        case .waitingForLiveCaptions: "captions.bubble"
        case .overlayHidden: "ear"
        case .listening, .paused: "captions.bubble"
        }
    }

    private var message: String {
        switch status {
        case .needsAccessibility:
            "AirScript reads macOS Live Captions through Accessibility. Enable AirScript in System Settings → Privacy & Security → Accessibility."
        case .waitingForLiveCaptions:
            "Turn on Live Captions in System Settings → Accessibility → Live Captions. AirScript mirrors that overlay in real time."
        case .overlayHidden:
            "Live Captions is running. Play audio or choose Keep Onscreen in the Live Captions menu extra so the overlay has text to read."
        case .listening, .paused:
            ""
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
