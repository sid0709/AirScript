import SwiftUI

struct ContentView: View {
    @Environment(CaptionBoardViewModel.self) private var board

    var body: some View {
        CaptionBoardView(board: board)
    }
}

#Preview {
    ContentView()
        .environment(CaptionBoardViewModel(reader: PreviewCaptionReader()))
}

private final class PreviewCaptionReader: LiveCaptionReading {
    func start(onText: @escaping (String) -> Void) {
        onText("Live Captions overlay text")
    }

    func stop() {}
}
