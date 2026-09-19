import AppKit
import Foundation

/// Excludes AirScript windows from screenshots, recordings, and screen sharing.
/// Uses `NSWindow.sharingType = .none` so the windows stay on your display.
enum ScreenCaptureStealth {
    private static var observers: [NSObjectProtocol] = []
    private static var isAppReady = false

    /// Register launch observers only. Do not touch `NSApp` here — it traps during `App.init`.
    static func start() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(
            center.addObserver(
                forName: NSApplication.didFinishLaunchingNotification,
                object: nil,
                queue: .main
            ) { _ in
                noteReady(enabled: AppSettings.hideFromScreenCapture)
            }
        )
        observers.append(
            center.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { _ in
                apply(enabled: AppSettings.hideFromScreenCapture)
            }
        )
    }

    static func noteReady(enabled: Bool) {
        isAppReady = true
        apply(enabled: enabled)
    }

    static func apply(enabled: Bool) {
        guard isAppReady else { return }
        // Settings can be mutated off-main (tests, background tasks); NSWindow is main-only.
        guard Thread.isMainThread else {
            DispatchQueue.main.async { apply(enabled: enabled) }
            return
        }
        let sharing: NSWindow.SharingType = enabled ? .none : .readOnly
        for window in NSApp.windows {
            window.sharingType = sharing
        }
    }
}
