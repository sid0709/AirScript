import AppKit
import Foundation

enum WindowAlwaysOnTop {
    private static var observers: [NSObjectProtocol] = []
    private static var isAppReady = false

    static func start() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(
            center.addObserver(
                forName: NSApplication.didFinishLaunchingNotification,
                object: nil,
                queue: .main
            ) { _ in
                noteReady(enabled: AppSettings.alwaysOnTop)
            }
        )
        observers.append(
            center.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { _ in
                apply(enabled: AppSettings.alwaysOnTop)
            }
        )
    }

    static func noteReady(enabled: Bool) {
        isAppReady = true
        apply(enabled: enabled)
    }

    static func apply(enabled: Bool) {
        guard isAppReady else { return }
        let level: NSWindow.Level = enabled ? .floating : .normal
        for window in NSApp.windows where !isStatusItem(window) {
            window.level = level
        }
    }

    private static func isStatusItem(_ window: NSWindow) -> Bool {
        if window.contentView is NSStatusBarButton { return true }
        return window.className.contains("StatusBar") || window.className.contains("StatusItem")
    }
}
