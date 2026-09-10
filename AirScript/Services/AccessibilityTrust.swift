import ApplicationServices
import Foundation

enum AccessibilityTrust {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func request() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }
}
