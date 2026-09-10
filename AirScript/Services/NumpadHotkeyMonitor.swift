import ApplicationServices
import CoreGraphics
import Foundation

enum NumpadHotkeyAction: Equatable {
    case grab(sentenceCount: Int)
    case clear
}

/// Global keypad tap. Swallows 0–9 and decimal so they do not type into the front app.
final class NumpadHotkeyMonitor {
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var lastDecimalAt: Date?
    private let decimalWindow: TimeInterval = 0.4
    private let onAction: (NumpadHotkeyAction) -> Void

    init(onAction: @escaping (NumpadHotkeyAction) -> Void) {
        self.onAction = onAction
    }

    deinit {
        stop()
    }

    func start() {
        guard tap == nil, AccessibilityTrust.isTrusted else { return }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
            | CGEventMask(1 << CGEventType.keyUp.rawValue)
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: numpadTapCallback,
            userInfo: pointer
        ) else { return }

        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
        lastDecimalAt = nil
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        guard Self.isKeypad(keyCode) else {
            return Unmanaged.passUnretained(event)
        }

        let flags = event.flags
        if flags.contains(.maskCommand) || flags.contains(.maskControl) || flags.contains(.maskAlternate) {
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown, let action = action(for: keyCode) {
            onAction(action)
        }
        return nil
    }

    private func action(for keyCode: CGKeyCode) -> NumpadHotkeyAction? {
        if keyCode == Self.decimal {
            let now = Date()
            if let lastDecimalAt, now.timeIntervalSince(lastDecimalAt) <= decimalWindow {
                self.lastDecimalAt = nil
                return .clear
            }
            lastDecimalAt = now
            return nil
        }

        lastDecimalAt = nil
        guard let digit = Self.digits[keyCode] else { return nil }
        if digit == 0 {
            return .grab(sentenceCount: 0)
        }
        return .grab(sentenceCount: digit * 2)
    }

    private static let decimal: CGKeyCode = 0x41
    private static let digits: [CGKeyCode: Int] = [
        0x52: 0,
        0x53: 1,
        0x54: 2,
        0x55: 3,
        0x56: 4,
        0x57: 5,
        0x58: 6,
        0x59: 7,
        0x5B: 8,
        0x5C: 9,
    ]

    private static func isKeypad(_ keyCode: CGKeyCode) -> Bool {
        keyCode == decimal || digits[keyCode] != nil
    }
}

private func numpadTapCallback(
    proxy _: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else {
        return Unmanaged.passUnretained(event)
    }
    let monitor = Unmanaged<NumpadHotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
    return monitor.handle(type: type, event: event)
}
