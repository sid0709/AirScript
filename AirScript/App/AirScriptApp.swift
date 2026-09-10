import SwiftUI

@main
struct AirScriptApp: App {
    @State private var board = CaptionBoardViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(board)
                .containerBackground(for: .window) {
                    WindowGlassBackground()
                }
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
                Button("Copy All Captions") {
                    board.copyAll()
                }
                Menu("Copy Recent") {
                    ForEach(1...9, id: \.self) { n in
                        Button("Last \(n * 2) Sentences") {
                            board.copyRecentSentences(n * 2)
                        }
                    }
                }
                Divider()
                Button("Live Captions Settings…") {
                    board.openLiveCaptionsSettings()
                }
            }
        }

        MenuBarExtra {
            CaptionMenuBarExtra(board: board)
        } label: {
            MenuBarIcon()
        }
        .menuBarExtraStyle(.menu)
    }
}
