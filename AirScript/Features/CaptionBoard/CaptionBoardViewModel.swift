import AppKit
import Foundation
import Observation

@Observable
final class CaptionBoardViewModel {
    private(set) var committedLines: [CaptionLine] = []
    private(set) var liveLine: CaptionLine?
    private(set) var status: LiveCaptionStatus = .needsAccessibility
    private(set) var isRunning = false

    var lines: [CaptionLine] {
        if let liveLine {
            return committedLines + [liveLine]
        }
        return committedLines
    }

    private(set) var translations = CaptionTranslationStore()

    @ObservationIgnored private var assembler = CaptionLineAssembler()
    @ObservationIgnored private let client = LiveCaptionAXClient()
    @ObservationIgnored private var hotkeys: NumpadHotkeyMonitor?
    @ObservationIgnored private var activationObserver: NSObjectProtocol?
    @ObservationIgnored private var showsEnglish = true
    @ObservationIgnored private var visibleTranslateLanguages: [TranslationLanguage] = []

    func start() {
        isRunning = true
        if !AccessibilityTrust.isTrusted {
            AccessibilityTrust.request()
        }
        client.start { [weak self] text in
            self?.handle(text)
        }
        client.onRunningChange = { [weak self] in
            self?.refreshStatus()
        }
        observeActivation()
        ensureHotkeys()
        refreshStatus()
    }

    func stop() {
        isRunning = false
        client.stop()
        hotkeys?.stop()
        hotkeys = nil
        removeActivationObserver()
        status = .paused
    }

    func clear() {
        assembler.reset()
        client.ignoreCurrentSnapshot()
        committedLines = []
        liveLine = nil
        translations.reset()
    }

    func copyAll() {
        copyRecentSentences(0)
    }

    func copyRecentSentences(_ count: Int) {
        let store = translations
        let english = showsEnglish
        let languages = visibleTranslateLanguages
        guard let text = CaptionNotebookText.grab(
            from: lines,
            count: count,
            showSource: english,
            languages: languages,
            translation: { source, target in
                store.value(source: source, target: target)
            }
        ) else { return }
        FocusedFieldPaster.replaceFocusedField(with: text)
    }

    func syncTranslations(from settings: AppSettings) {
        showsEnglish = settings.showsEnglish
        visibleTranslateLanguages = settings.visibleTranslateLanguages
        requestTranslations()
    }

    func requestAccessibility() {
        AccessibilityTrust.request()
        SystemSettingsLink.openAccessibility()
        refreshStatus()
    }

    func openLiveCaptionsSettings() {
        SystemSettingsLink.openLiveCaptions()
    }

    func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeMain || $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
        }
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
        guard assembler.ingest(text) else { return }
        publishLines()
        if status != .listening {
            status = .listening
        }
        requestTranslations()
    }

    private func requestTranslations() {
        let languages = visibleTranslateLanguages
        guard !languages.isEmpty else { return }
        translations.ensure(
            sentences: CaptionSentenceGrab.translatableSentences(from: lines),
            languages: languages
        )
    }

    private func publishLines() {
        let nextCommitted = assembler.lines.filter { !$0.isLive }
        let nextLive = assembler.lines.last(where: \.isLive)
        if committedLines != nextCommitted {
            committedLines = nextCommitted
        }
        if liveLine != nextLive {
            liveLine = nextLive
        }
    }

    private func observeActivation() {
        removeActivationObserver()
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshStatus()
        }
    }

    private func removeActivationObserver() {
        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
        }
        activationObserver = nil
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
        if !client.isProcessRunning {
            status = .waitingForLiveCaptions
            return
        }
        status = .listening
    }
}
