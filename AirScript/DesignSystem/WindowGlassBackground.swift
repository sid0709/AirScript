import SwiftUI

struct WindowGlassBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Group {
            if reduceTransparency {
                Color(nsColor: .windowBackgroundColor)
            } else {
                Rectangle().fill(DS.MaterialRole.sidebar)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    WindowGlassBackground()
        .frame(width: 360, height: 240)
}
