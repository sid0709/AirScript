import ApplicationServices
import CoreGraphics
import Foundation

enum NumpadHotkeyAction: Equatable {
    case grab(sentenceCount: Int)
    case clear
}

/// Global keypad tap. Swallows 0–9 and decimal so they do not type into the front app.
///
/// The tap is serviced on a dedicated user-interactive thread rather than the main run loop:
/// an active tap stalls every keystroke system-wide until its callback returns, so it must
/// never wait behind SwiftUI layout, translation updates, or AX work on the main thread.
/// `onAction` is invoked on that thread; callers hop to main themselves.
final class NumpadHotkeyMonitor: @unchecked Sendable {
    private var thread: Thread?
    private var runLoop: CFRunLoop?
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let lock = NSLock()
    private var stopped: DispatchSemaphore?
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
        lock.lock()
        let alreadyRunning = thread != nil
        lock.unlock()
        guard !alreadyRunning, AccessibilityTrust.isTrusted else { return }

        let ready = DispatchSemaphore(value: 0)
        let stopped = DispatchSemaphore(value: 0)
        let thread = Thread { [weak self] in
            guard let self else {
                ready.signal()
                return
            }
            let current = CFRunLoopGetCurrent()
            let tap = self.makeTap()
            let source: CFRunLoopSource? = tap.flatMap { CFMachPortCreateRunLoopSource(kCFAllocatorDefault, $0, 0) }
            if let source {
                CFRunLoopAddSource(current, source, .commonModes)
            }
            self.lock.lock()
            self.runLoop = current
            self.tap = tap
            self.runLoopSource = source
            self.lock.unlock()
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            ready.signal()
            if source != nil {
                CFRunLoopRun()
            }
            self.lock.lock()
            self.runLoop = nil
            self.tap = nil
            self.runLoopSource = nil
            self.thread = nil
            self.lock.unlock()
            stopped.signal()
        }
        thread.name = "AirScript.NumpadHotkeyTap"
        thread.qualityOfService = .userInteractive
        lock.lock()
        self.thread = thread
        self.stopped = stopped
        lock.unlock()
        thread.start()
        ready.wait()
    }

    func stop() {
        lock.lock()
        let tap = tap
        let runLoop = runLoop
        let source = runLoopSource
        let thread = thread
        let stopped = stopped
        self.stopped = nil
        lock.unlock()
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoop {
            if let source {
                CFRunLoopRemoveSource(runLoop, source, .commonModes)
            }
            CFRunLoopStop(runLoop)
        }
        // Wait for the tap thread to wind down so a following `start()` isn't a no-op.
        if let thread, let stopped, Thread.current !== thread {
            _ = stopped.wait(timeout: .now() + 1)
        }
        lastDecimalAt = nil
    }

    /// HID-level sits one stage earlier than session-level, ahead of other apps' session taps.
    /// Fall back to session-level if the system refuses a HID tap.
    private func makeTap() -> CFMachPort? {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        for location in [CGEventTapLocation.cghidEventTap, .cgSessionEventTap] {
            if let tap = CGEvent.tapCreate(
                tap: location,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: mask,
                callback: Self.eventCallback,
                userInfo: pointer
            ) {
                return tap
            }
        }
        return nil
    }

    private static let eventCallback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon else {
            return Unmanaged.passUnretained(event)
        }
        let monitor = Unmanaged<NumpadHotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
        return monitor.handle(type: type, event: event)
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            lock.lock()
            let tap = tap
            lock.unlock()
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
