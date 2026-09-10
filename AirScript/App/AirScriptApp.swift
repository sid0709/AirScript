import SwiftUI

@main
struct AirScriptApp: App {
    @State private var board = CaptionBoardViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(board)
                .background(.regularMaterial)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 720, height: 480)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Captions") {
                Button(board.isRunning ? "Pause" : "Listen") {
                    board.isRunning ? board.stop() : board.start()
                }
                .keyboardShortcut("l", modifiers: [.command])
                Button("Clear Board") {
                    board.clear()
                }
                .keyboardShortcut("k", modifiers: [.command])
                Divider()
                Button("Live Captions Settings…") {
                    board.openLiveCaptionsSettings()
                }
            }
        }
    }
}
