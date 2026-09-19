import AppKit
import SwiftUI

/// SwiftUI `MenuBarExtra` always presents its menu on a left-click.
/// Route a plain left-click to the main window; Control-click and right-click keep the menu.
enum StatusItemLeftClickMonitor {
    private static var monitor: Any?
    private static var onLeftClick: (() -> Void)?
    private static var swallowedLeftMouseDown = false

    static func showMainWindow(using openWindow: OpenWindowAction) {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "main")
        DispatchQueue.main.async {
            bringBoardWindowForward()
        }
    }

    static func install(using openWindow: OpenWindowAction) {
        install {
            showMainWindow(using: openWindow)
        }
    }

    static func install(onLeftClick: @escaping () -> Void) {
        self.onLeftClick = onLeftClick
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { event in
            if event.type == .leftMouseDown {
                guard isStatusItemClick(event), !event.modifierFlags.contains(.control) else {
                    swallowedLeftMouseDown = false
                    return event
                }
                swallowedLeftMouseDown = true
                Self.onLeftClick?()
                return nil
            }
            if swallowedLeftMouseDown {
                swallowedLeftMouseDown = false
                return nil
            }
            return event
        }
    }

    static func bringBoardWindowForward() {
        let window = NSApp.windows.first(where: isBoardWindow)
            ?? NSApp.windows.first(where: { $0.canBecomeMain && !isStatusItemWindow($0) })
        guard let window else { return }
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.makeKeyAndOrderFront(nil)
    }

    private static func isBoardWindow(_ window: NSWindow) -> Bool {
        window.identifier?.rawValue == "main" || window.title == "AirScript"
    }

    private static func isStatusItemClick(_ event: NSEvent) -> Bool {
        if let window = event.window, isStatusItemWindow(window) {
            return true
        }
        let mouse = NSEvent.mouseLocation
        return NSApp.windows.contains { isStatusItemWindow($0) && $0.frame.contains(mouse) }
    }

    private static func isStatusItemWindow(_ window: NSWindow) -> Bool {
        if window.contentView is NSStatusBarButton {
            return true
        }
        if window.contentView?.subviews.contains(where: { $0 is NSStatusBarButton }) == true {
            return true
        }
        return window.className.contains("StatusBar") || window.className.contains("StatusItem")
    }
}

extension View {
    func showsMainWindowOnStatusItemClick() -> some View {
        modifier(StatusItemLeftClickModifier())
    }
}

private struct StatusItemLeftClickModifier: ViewModifier {
    @Environment(\.openWindow) private var openWindow

    func body(content: Content) -> some View {
        content.onAppear {
            StatusItemLeftClickMonitor.install(using: openWindow)
        }
    }
}
