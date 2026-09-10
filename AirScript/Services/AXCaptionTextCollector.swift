import ApplicationServices
import Foundation

enum AXCaptionTextCollector {
    private static let skippedRoles: Set<String> = [
        kAXMenuBarRole as String,
        kAXMenuRole as String,
        kAXMenuItemRole as String,
        kAXMenuBarItemRole as String,
    ]

    private static let chromePhrases: Set<String> = [
        "Live Captions",
        "Stop Live Captions",
        "Start Live Captions",
        "Computer Audio",
        "Microphone",
        "Keep Onscreen",
        "Type to Speak",
        "Restore Default Position",
        "About KeyboardAccessAgent",
        "KeyboardAccessAgent Help",
    ]

    static func captionText(from app: AXUIElement) -> String {
        var lines: [String] = []
        var seen = 0
        collect(from: app, into: &lines, seen: &seen, depth: 0)
        return lines.joined(separator: "\n")
    }

    private static func collect(
        from element: AXUIElement,
        into lines: inout [String],
        seen: inout Int,
        depth: Int
    ) {
        guard depth < 16, seen < 250 else { return }
        seen += 1

        let role = AXAttribute.role(element)
        if skippedRoles.contains(role) { return }

        if AXAttribute.identifier(element) == "captions.list.label",
           let value = readableValue(element) {
            append(value, into: &lines)
            return
        }

        if let value = readableValue(element), shouldKeep(value) {
            append(value, into: &lines)
            if role == (kAXTextAreaRole as String) || role == (kAXTextFieldRole as String) {
                return
            }
        }

        for child in AXAttribute.children(element) {
            collect(from: child, into: &lines, seen: &seen, depth: depth + 1)
        }
    }

    private static func readableValue(_ element: AXUIElement) -> String? {
        let candidates = [
            AXAttribute.string(element, kAXValueAttribute as String),
            AXAttribute.string(element, kAXTitleAttribute as String),
            AXAttribute.string(element, kAXDescriptionAttribute as String),
        ]
        let value = candidates
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        return value
    }

    static func isChrome(_ value: String) -> Bool {
        chromePhrases.contains(value)
    }

    private static func shouldKeep(_ value: String) -> Bool {
        !isChrome(value)
    }

    private static func append(_ value: String, into lines: inout [String]) {
        for part in CaptionLineAssembler.splitLines(value) where !lines.contains(part) {
            lines.append(part)
        }
    }
}
