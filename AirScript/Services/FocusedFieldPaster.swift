import AppKit
import CoreGraphics
import Foundation

/// Replaces the focused field in the frontmost app without activating AirScript.
enum FocusedFieldPaster {
    static func replaceFocusedField(with text: String) {
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(40))
            postKey(Self.a, flags: .maskCommand)
            try? await Task.sleep(for: .milliseconds(40))
            postKey(Self.delete)
            try? await Task.sleep(for: .milliseconds(40))
            postKey(Self.v, flags: .maskCommand)
        }
    }

    private static let a: CGKeyCode = 0x00
    private static let v: CGKeyCode = 0x09
    private static let delete: CGKeyCode = 0x33

    private static func postKey(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let source = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        down?.flags = flags
        down?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        up?.flags = flags
        up?.post(tap: .cghidEventTap)
    }
}
