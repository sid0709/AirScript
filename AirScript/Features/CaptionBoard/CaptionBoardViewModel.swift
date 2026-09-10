import Foundation
import Observation

@Observable
final class CaptionBoardViewModel {
    private(set) var lines: [CaptionLine] = []
    private(set) var status: LiveCaptionStatus = .needsAccessibility
    private(set) var isRunning = false

    private var assembler = CaptionLineAssembler()
    private let reader: LiveCaptionReading
    private var statusTimer: Timer?

    init(reader: LiveCaptionReading = LiveCaptionAXClient()) {
        self.reader = reader
        refreshStatus()
    }

    func start() {
        isRunning = true
        refreshStatus()
        if !AccessibilityTrust.isTrusted {
            AccessibilityTrust.request()
        }
        reader.start { [weak self] text in
            self?.handle(text)
        }
        statusTimer?.invalidate()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
    }

    func stop() {
        isRunning = false
        reader.stop()
        statusTimer?.invalidate()
        statusTimer = nil
        status = .paused
    }

    func clear() {
        assembler.reset()
        lines = []
        refreshStatus()
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
        if isRunning {
            status = .listening
        }
    }

    private func refreshStatus() {
        if !AccessibilityTrust.isTrusted {
            status = .needsAccessibility
            return
        }
        guard isRunning else {
            status = .paused
            return
        }
        if !LiveCaptionProcess.isRunning {
            status = .waitingForLiveCaptions
            return
        }
        status = lines.contains(where: \.isLive) ? .listening : .overlayHidden
    }
}
