import SwiftUI

struct CaptionLineRow: View, Equatable {
    let line: CaptionLine
    let segments: [CaptionNotebookLayout.Segment]

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            ForEach(segments) { segment in
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    ForEach(Array(segment.layers.enumerated()), id: \.element.id) { index, layer in
                        Text(layer.text)
                            .font(index == 0 ? .body : .callout)
                            .fontWeight(line.isLive && layer.isSource ? .medium : .regular)
                            .foregroundStyle(style(for: layer, isFirst: index == 0))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DS.Spacing.xxs)
        .accessibilityLabel(accessibilityText)
    }

    private func style(for layer: CaptionNotebookLayout.Layer, isFirst: Bool) -> AnyShapeStyle {
        if layer.isPending { return AnyShapeStyle(.tertiary) }
        if isFirst {
            return AnyShapeStyle(line.isLive ? .primary : .secondary)
        }
        return AnyShapeStyle(.tertiary)
    }

    private var accessibilityText: String {
        let spoken = segments.flatMap(\.layers).map(\.text).joined(separator: ". ")
        return line.isLive ? "Live caption, \(spoken)" : spoken
    }
}

#Preview {
    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
        CaptionLineRow(
            line: CaptionLine(text: "Hello, how are you doing? Good.", isLive: false),
            segments: CaptionNotebookLayout.segments(
                in: "Hello, how are you doing? Good.",
                showSource: true,
                languages: [TranslationLanguage.catalog[0]],
                translation: { source, _ in
                    source == "Hello, how are you doing?" ? "你好，你怎么样？" : "好。"
                }
            )
        )
        CaptionLineRow(
            line: CaptionLine(text: "Live caption updating…", isLive: true),
            segments: CaptionNotebookLayout.segments(
                in: "Live caption updating…",
                showSource: true,
                languages: [],
                translation: { _, _ in nil }
            )
        )
    }
    .padding(DS.Spacing.md)
    .frame(width: 420)
}
