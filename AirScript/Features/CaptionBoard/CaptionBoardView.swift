import SwiftUI

struct CaptionBoardView: View {
    @Bindable var board: CaptionBoardViewModel

    var body: some View {
        Group {
            if board.lines.isEmpty, board.status == .needsAccessibility || board.status == .waitingForLiveCaptions {
                LiveCaptionPermissionView(
                    status: board.status,
                    onGrantAccessibility: board.requestAccessibility,
                    onOpenLiveCaptions: board.openLiveCaptionsSettings
                )
                .frame(maxHeight: .infinity)
            } else {
                captionScroll
            }
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItemGroup {
                Label(board.status.toolbarLabel, systemImage: statusSymbol)
                    .foregroundStyle(.secondary)
                    .font(.callout)
                Spacer()
                Button(board.isRunning ? "Pause" : "Listen") {
                    board.isRunning ? board.stop() : board.start()
                }
                Button("Clear", action: board.clear)
                    .disabled(board.lines.isEmpty)
            }
        }
        .onAppear {
            if !board.isRunning { board.start() }
        }
    }

    private var captionScroll: some View {
        GlassPanel {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        ForEach(board.lines) { line in
                            CaptionLineRow(line: line)
                                .id(line.id)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: board.lines.last?.text) { _, _ in
                    if let id = board.lines.last?.id {
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var statusSymbol: String {
        switch board.status {
        case .listening: "waveform"
        case .paused: "pause.circle"
        case .needsAccessibility: "hand.raised"
        case .waitingForLiveCaptions: "captions.bubble"
        }
    }
}

#Preview {
    CaptionBoardView(board: CaptionBoardViewModel())
        .frame(width: 640, height: 420)
}
