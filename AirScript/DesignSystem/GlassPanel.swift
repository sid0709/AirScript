import SwiftUI

struct GlassPanel<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var material: Material = DS.MaterialRole.card
    var radius: CGFloat = DS.Radius.panel
    var padding: CGFloat = DS.Spacing.md
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(reduceTransparency
                          ? AnyShapeStyle(Color(nsColor: .windowBackgroundColor))
                          : AnyShapeStyle(material))
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(.primary.opacity(DS.Stroke.hairlineOpacity), lineWidth: DS.Stroke.width)
            }
            .shadow(color: DS.Elevation.color, radius: DS.Elevation.radius, y: DS.Elevation.y)
    }
}

#Preview {
    GlassPanel {
        Text("Live Captions")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(DS.Spacing.lg)
    .frame(width: 360)
}
