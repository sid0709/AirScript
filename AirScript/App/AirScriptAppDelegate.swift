import AppKit

final class AirScriptAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // Accessory apps don't activate on launch; surface the board window so
        // its `onAppear` kicks off caption reading right away.
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            StatusItemLeftClickMonitor.bringBoardWindowForward()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        false
    }
}
