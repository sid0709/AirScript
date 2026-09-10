import ApplicationServices
import Foundation

enum AXAttribute {
    static func copy(_ element: AXUIElement, _ attribute: String) -> AnyObject? {
        var value: AnyObject?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        return error == .success ? value : nil
    }

    static func string(_ element: AXUIElement, _ attribute: String) -> String? {
        copy(element, attribute) as? String
    }

    static func children(_ element: AXUIElement) -> [AXUIElement] {
        copy(element, kAXChildrenAttribute as String) as? [AXUIElement] ?? []
    }

    static func role(_ element: AXUIElement) -> String {
        string(element, kAXRoleAttribute as String) ?? ""
    }

    static func identifier(_ element: AXUIElement) -> String {
        string(element, kAXIdentifierAttribute as String) ?? ""
    }

    static func windows(_ app: AXUIElement) -> [AXUIElement] {
        copy(app, kAXWindowsAttribute as String) as? [AXUIElement] ?? []
    }
}
