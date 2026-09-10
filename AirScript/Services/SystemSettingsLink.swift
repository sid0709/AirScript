import AppKit
import Foundation

enum SystemSettingsLink {
    static func openAccessibility() {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")!
        )
    }

    static func openLiveCaptions() {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.Accessibility-Settings.extension?LiveCaptions")!
        )
    }
}
