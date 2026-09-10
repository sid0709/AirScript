import AppKit
import Foundation

enum SystemSettingsLink {
    static func openAccessibility() {
        open([
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
        ])
    }

    static func openLiveCaptions() {
        open([
            "x-apple.systempreferences:com.apple.Accessibility-Settings.extension?LiveCaptions",
            "x-apple.systempreferences:com.apple.preference.universalaccess?LiveCaptions",
        ])
    }

    private static func open(_ candidates: [String]) {
        for candidate in candidates {
            if let url = URL(string: candidate) {
                NSWorkspace.shared.open(url)
                return
            }
        }
    }
}
