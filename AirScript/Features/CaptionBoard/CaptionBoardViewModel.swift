import Foundation
import Observation

@Observable
final class CaptionBoardViewModel {
    private(set) var lines: [CaptionLine] = []
    private(set) var status: LiveCaptionStatus = .needsAccessibility
    private(set) var isRunning = false

    private var assembler = CaptionLineAssembler()
    private let client = LiveCaptionAXClient()
    private var statusTimer: Timer?

    func start() {
        isRunning = true
        if !AccessibilityTrust.isTrusted {
            AccessibilityTrust.request()
        }
        client.start { [weak self] text in
            self?.handle(text)
        }
        refreshStatus()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
    }

    func stop() {
        isRunning = false
        client.stop()
        statusTimer?.invalidate()
        statusTimer = nil
        status = .paused
    }

    func clear() {
        assembler.reset()
        lines = []
    }

    func requestAccessibility() {
        AccessibilityTrust.request()
        SystemSettingsLink.openAccessibility()
        refreshStatus()
    }

    func openLiveCaptionsSettings() {
        SystemSettingsLink.openLiveCaptions()
    }

    private func handle(_ text: String) {
        assembler.ingest(text)
        lines = assembler.lines
        status = .listening
    }

    private func refreshStatus() {
        if !AccessibilityTrust.isTrusted {
            status = .needsAccessibility
            return
        }
        if !isRunning {
            status = .paused
            return
        }
        if !LiveCaptionAXClient.isLiveCaptionsRunning {
            status = .waitingForLiveCaptions
            return
        }
        status = .listening
    }
}
