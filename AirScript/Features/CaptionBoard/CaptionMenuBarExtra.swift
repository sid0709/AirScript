import AppKit
import SwiftUI

struct CaptionMenuBarExtra: View {
    @Bindable var board: CaptionBoardViewModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button(board.isRunning ? "Pause" : "Listen") {
            board.isRunning ? board.stop() : board.start()
        }
        Button("Clear Board", action: board.clear)
            .disabled(board.lines.isEmpty)
        Divider()
        Button("Show AirScript", action: board.showMainWindow)
        Button("Settings…") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        Button("Live Captions Settings…", action: board.openLiveCaptionsSettings)
        Divider()
        Button("Quit AirScript") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
