import SwiftUI

struct CaptionLineRow: View, Equatable {
    let line: CaptionLine

    var body: some View {
        Text(line.text)
            .font(.body)
            .fontWeight(line.isLive ? .medium : .regular)
            .foregroundStyle(line.isLive ? .primary : .secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DS.Spacing.xxs)
            .accessibilityLabel(line.isLive ? "Live caption, \(line.text)" : line.text)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
        CaptionLineRow(line: CaptionLine(text: "Committed caption line.", isLive: false))
        CaptionLineRow(line: CaptionLine(text: "Live caption updating…", isLive: true))
    }
    .padding(DS.Spacing.md)
    .frame(width: 420)
}
