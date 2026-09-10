import Foundation
import Observation

@Observable
final class CaptionBoardViewModel {
    private(set) var lines: [CaptionLine] = []
    private(set) var status: LiveCaptionStatus = .needsAccessibility
    private(set) var isRunning = false

    @ObservationIgnored private var assembler = CaptionLineAssembler()
    @ObservationIgnored private let client = LiveCaptionAXClient()
    @ObservationIgnored private var statusTimer: Timer?
    @ObservationIgnored private var hotkeys: NumpadHotkeyMonitor?

    func start() {
        isRunning = true
        if !AccessibilityTrust.isTrusted {
            AccessibilityTrust.request()
        }
        client.start { [weak self] text in
            self?.handle(text)
        }
        ensureHotkeys()
        refreshStatus()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
    }

    func stop() {
        isRunning = false
        client.stop()
        hotkeys?.stop()
        hotkeys = nil
        statusTimer?.invalidate()
        statusTimer = nil
        status = .paused
    }

    func clear() {
        assembler.reset()
        client.ignoreCurrentSnapshot()
        lines = []
    }

    func copyAll() {
        copyRecentSentences(0)
    }

    func copyRecentSentences(_ count: Int) {
        guard let text = CaptionSentenceGrab.grab(from: lines, count: count) else { return }
        FocusedFieldPaster.replaceFocusedField(with: text)
    }

    func requestAccessibility() {
        AccessibilityTrust.request()
        SystemSettingsLink.openAccessibility()
        refreshStatus()
    }

    func openLiveCaptionsSettings() {
        SystemSettingsLink.openLiveCaptions()
    }

    private func handleHotkey(_ action: NumpadHotkeyAction) {
        switch action {
        case .clear:
            clear()
        case .grab(let sentenceCount):
            copyRecentSentences(sentenceCount)
        }
    }

    private func ensureHotkeys() {
        guard isRunning, AccessibilityTrust.isTrusted else {
            hotkeys?.stop()
            return
        }
        if hotkeys == nil {
            hotkeys = NumpadHotkeyMonitor { [weak self] action in
                DispatchQueue.main.async {
                    self?.handleHotkey(action)
                }
            }
        }
        hotkeys?.start()
    }

    private func handle(_ text: String) {
        assembler.ingest(text)
        lines = assembler.lines
        status = .listening
    }

    private func refreshStatus() {
        if !AccessibilityTrust.isTrusted {
            status = .needsAccessibility
            hotkeys?.stop()
            return
        }
        if !isRunning {
            status = .paused
            return
        }
        ensureHotkeys()
        if !LiveCaptionAXClient.isLiveCaptionsRunning {
            status = .waitingForLiveCaptions
            return
        }
        status = .listening
    }
}
