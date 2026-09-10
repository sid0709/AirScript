import AppKit
import Foundation

enum LiveCaptionProcess {
    static let bundleIdentifier = "com.apple.accessibility.LiveTranscriptionAgent"
    static let localizedName = "Live Captions"

    static func runningApplication() -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first { app in
            app.bundleIdentifier == bundleIdentifier
                || app.localizedName == localizedName
        }
    }

    static var isRunning: Bool {
        runningApplication() != nil
    }
}
