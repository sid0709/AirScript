import AppKit
import ApplicationServices
import Foundation

protocol LiveCaptionReading: AnyObject {
    func start(onText: @escaping (String) -> Void)
    func stop()
}

/// Reads macOS Accessibility Live Captions (`com.apple.accessibility.LiveTranscriptionAgent`)
/// from the system overlay via the Accessibility API.
final class LiveCaptionAXClient: LiveCaptionReading {
    private var observer: AXObserver?
    private var observerContext: ObserverContext?
    private var observedPID: pid_t = 0
    private var pollTimer: Timer?
    private var onText: ((String) -> Void)?
    private var lastEmitted = ""

    func start(onText: @escaping (String) -> Void) {
        stop()
        self.onText = onText
        attachIfPossible()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            self?.attachIfPossible()
            self?.emitSnapshot()
        }
        timer.tolerance = 0.02
        pollTimer = timer
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        detachObserver()
        onText = nil
        lastEmitted = ""
    }

    private func attachIfPossible() {
        guard AccessibilityTrust.isTrusted,
              let app = LiveCaptionProcess.runningApplication() else {
            detachObserver()
            return
        }
        let pid = app.processIdentifier
        guard pid != observedPID else { return }
        detachObserver()
        installObserver(pid: pid)
    }

    private func installObserver(pid: pid_t) {
        let context = ObserverContext(client: self)
        var newObserver: AXObserver?
        let error = AXObserverCreateWithInfoCallback(pid, { _, element, notification, info, refcon in
            guard let refcon else { return }
            Unmanaged<ObserverContext>.fromOpaque(refcon).takeUnretainedValue()
                .client?.handleNotification(element: element, notification: notification, info: info)
        }, &newObserver)

        guard error == .success, let newObserver else { return }

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(newObserver),
            .commonModes
        )

        let app = AXUIElementCreateApplication(pid)
        let notifications = [
            kAXValueChangedNotification,
            kAXLayoutChangedNotification,
            kAXWindowCreatedNotification,
            kAXTitleChangedNotification,
            kAXAnnouncementRequestedNotification,
        ]
        let pointer = Unmanaged.passUnretained(context).toOpaque()
        for notification in notifications {
            AXObserverAddNotification(newObserver, app, notification as CFString, pointer)
        }

        observerContext = context
        observer = newObserver
        observedPID = pid
    }

    private func detachObserver() {
        if let observer {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                AXObserverGetRunLoopSource(observer),
                .commonModes
            )
        }
        observer = nil
        observerContext = nil
        observedPID = 0
    }

    private func handleNotification(
        element: AXUIElement,
        notification: CFString,
        info: CFDictionary?
    ) {
        if let announcement = announcementText(from: element, info: info) {
            emit(announcement)
            return
        }
        emitSnapshot()
    }

    private func announcementText(from element: AXUIElement, info: CFDictionary?) -> String? {
        if let info = info as? [String: Any] {
            for key in ["AXAnnouncement", kAXValueAttribute as String] {
                if let value = info[key] as? String, !value.isEmpty {
                    return value
                }
            }
        }
        return AXAttribute.string(element, kAXValueAttribute as String)
            ?? AXAttribute.string(element, kAXDescriptionAttribute as String)
    }

    private func emitSnapshot() {
        for pid in candidatePIDs() {
            let app = AXUIElementCreateApplication(pid)
            var snapshot = AXCaptionTextCollector.captionText(from: app)
            if snapshot.isEmpty {
                for window in AXAttribute.windows(app) {
                    snapshot = AXCaptionTextCollector.captionText(from: window)
                    if !snapshot.isEmpty { break }
                }
            }
            if !snapshot.isEmpty {
                emit(snapshot)
                return
            }
        }
    }

    private func candidatePIDs() -> [pid_t] {
        var pids: [pid_t] = []
        if let pid = LiveCaptionProcess.runningApplication()?.processIdentifier {
            pids.append(pid)
        }
        for app in NSWorkspace.shared.runningApplications {
            guard let identifier = app.bundleIdentifier else { continue }
            if identifier == "com.apple.AccessibilityUIServer"
                || identifier == "com.apple.accessibility.AXVisualSupportAgent" {
                pids.append(app.processIdentifier)
            }
        }
        return pids
    }

    private func emit(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != lastEmitted else { return }
        if AXCaptionTextCollector.isChrome(trimmed) { return }
        lastEmitted = trimmed
        onText?(trimmed)
    }
}

private final class ObserverContext {
    weak var client: LiveCaptionAXClient?

    init(client: LiveCaptionAXClient) {
        self.client = client
    }
}
