import AppKit
import SwiftUI

struct MenuBarIcon: View {
    var body: some View {
        Image(nsImage: Self.statusItemImage)
            .renderingMode(.original)
            .accessibilityLabel("AirScript")
    }

    /// MenuBarExtra uses the NSImage point size, not SwiftUI `.frame`.
    /// `applicationIconImage` is a dock icon (256–1024 pt), which is why the tray was huge.
    private static let statusItemImage: NSImage = {
        let source = NSApplication.shared.applicationIconImage
        let pointSize = NSSize(width: 18, height: 18)
        let image = NSImage(size: pointSize, flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .high
            source.draw(in: rect)
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
