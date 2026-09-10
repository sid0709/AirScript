import AppKit
import ApplicationServices
import Foundation

/// Polls macOS Live Captions through the Accessibility API.
final class LiveCaptionAXClient {
    private var timer: Timer?
    private var lastText = ""
    private var onText: ((String) -> Void)?

    func start(onText: @escaping (String) -> Void) {
        stop()
        self.onText = onText
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.poll()
        }
        poll()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        onText = nil
        lastText = ""
    }

    static var isLiveCaptionsRunning: Bool {
        liveCaptionsApp() != nil
    }

    private func poll() {
        let text = Self.readCaptionText()
        guard !text.isEmpty, text != lastText else { return }
        lastText = text
        onText?(text)
    }

    private static func liveCaptionsApp() -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first {
            $0.bundleIdentifier == "com.apple.accessibility.LiveTranscriptionAgent"
                || $0.localizedName == "Live Captions"
        }
    }

    private static func readCaptionText() -> String {
        guard let pid = liveCaptionsApp()?.processIdentifier else { return "" }
        let app = AXUIElementCreateApplication(pid)
        var lines: [String] = []
        collect(from: app, into: &lines, depth: 0)
        for window in (attribute(app, kAXWindowsAttribute as String) as? [AXUIElement] ?? []) {
            collect(from: window, into: &lines, depth: 0)
        }
        return CaptionTextMerge.collapse(lines).joined(separator: "\n")
    }

    private static func collect(from element: AXUIElement, into lines: inout [String], depth: Int) {
        guard depth < 12, lines.count < 40 else { return }
        let role = string(element, kAXRoleAttribute as String) ?? ""
        if role.contains("Menu") { return }

        if let value = string(element, kAXValueAttribute as String)
            ?? string(element, kAXDescriptionAttribute as String),
           !value.isEmpty {
            for line in value.split(whereSeparator: \.isNewline).map({ $0.trimmingCharacters(in: .whitespaces) })
            where !line.isEmpty && !CaptionTextMerge.isChrome(line) && !lines.contains(line) {
                lines.append(line)
            }
        }

        for child in children(element) {
            collect(from: child, into: &lines, depth: depth + 1)
        }
    }

    private static func attribute(_ element: AXUIElement, _ name: String) -> AnyObject? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    private static func string(_ element: AXUIElement, _ attribute: String) -> String? {
        guard let string = self.attribute(element, attribute) as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func children(_ element: AXUIElement) -> [AXUIElement] {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success else {
            return []
        }
        return value as? [AXUIElement] ?? []
    }
}
