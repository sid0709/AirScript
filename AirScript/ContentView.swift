import SwiftUI

struct ContentView: View {
    @Environment(CaptionBoardViewModel.self) private var board

    var body: some View {
        CaptionBoardView(board: board)
    }
}

#Preview {
    ContentView()
        .environment(CaptionBoardViewModel())
        .environment(AppSettings())
}
