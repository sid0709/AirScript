import AppKit
import SwiftUI

struct MenuBarIcon: View {
    var body: some View {
        Image(nsImage: Self.statusItemImage)
            .renderingMode(.original)
            .accessibilityLabel("AirScript")
    }

    /// MenuBarExtra uses the NSImage point size, not SwiftUI `.frame`.
    /// Status bar is 22 pt; app icons also have transparent margin, so we scale the tile to match other extras.
    private static let statusItemImage: NSImage = {
        let side = NSStatusBar.system.thickness
        let pointSize = NSSize(width: side, height: side)
        let source = NSApplication.shared.applicationIconImage
        let image = NSImage(size: pointSize, flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .high
            let bleed = rect.width * 0.12
            source?.draw(in: rect.insetBy(dx: -bleed, dy: -bleed))
            return true
        }
        image.isTemplate = false
        return image
    }()
}

#Preview {
    MenuBarIcon()
        .padding(DS.Spacing.md)
}
