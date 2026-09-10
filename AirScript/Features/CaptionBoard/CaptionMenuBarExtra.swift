import SwiftUI

struct CaptionMenuBarExtra: View {
    @Bindable var board: CaptionBoardViewModel

    var body: some View {
        Button(board.isRunning ? "Pause" : "Listen") {
            board.isRunning ? board.stop() : board.start()
        }
        Button("Clear Board", action: board.clear)
            .disabled(board.lines.isEmpty)
        Divider()
        Button("Show AirScript", action: board.showMainWindow)
        Button("Live Captions Settings…", action: board.openLiveCaptionsSettings)
    }
}
