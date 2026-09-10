import SwiftUI

struct StatusToolbarChip: View {
    let status: LiveCaptionStatus

    var body: some View {
        Label(status.toolbarLabel, systemImage: symbol)
            .foregroundStyle(.secondary)
            .font(.callout)
            .labelStyle(.titleAndIcon)
            .padding(.leading, DS.Spacing.sm)
            .padding(.trailing, DS.Spacing.xxs)
            .padding(.vertical, DS.Spacing.xxs)
    }

    private var symbol: String {
        switch status {
        case .listening: "waveform"
        case .paused: "pause.circle"
        case .needsAccessibility: "hand.raised"
        case .waitingForLiveCaptions: "captions.bubble"
        }
    }
}

#Preview {
    StatusToolbarChip(status: .listening)
        .padding(DS.Spacing.md)
}
