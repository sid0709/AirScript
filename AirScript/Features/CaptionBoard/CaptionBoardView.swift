import SwiftUI

struct CaptionBoardView: View {
    @Bindable var board: CaptionBoardViewModel

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            if shouldShowGate {
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
        .background(Color.clear)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                statusLabel
                Spacer()
                Button(board.isRunning ? "Pause" : "Listen", action: toggleListening)
                    .keyboardShortcut(.space, modifiers: [])
                Button("Clear", action: board.clear)
                    .disabled(board.lines.isEmpty)
                Button("Live Captions Settings", action: board.openLiveCaptionsSettings)
            }
        }
        .onAppear {
            if !board.isRunning {
                board.start()
            }
        }
    }

    private var shouldShowGate: Bool {
        board.lines.isEmpty && (board.status == .needsAccessibility
            || board.status == .waitingForLiveCaptions
            || board.status == .overlayHidden)
    }

    private var captionScroll: some View {
        GlassPanel(material: DS.MaterialRole.card, padding: DS.Spacing.md) {
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
                    if let lastID = board.lines.last?.id {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var statusLabel: some View {
        Label(board.status.toolbarLabel, systemImage: statusSymbol)
            .foregroundStyle(.secondary)
            .font(.callout)
    }

    private var statusSymbol: String {
        switch board.status {
        case .listening: "waveform"
        case .paused: "pause.circle"
        case .needsAccessibility: "hand.raised"
        case .waitingForLiveCaptions: "captions.bubble"
        case .overlayHidden: "ear"
        }
    }

    private func toggleListening() {
        if board.isRunning {
            board.stop()
        } else {
            board.start()
        }
    }
}

#Preview {
    CaptionBoardView(board: {
        let board = CaptionBoardViewModel(reader: PreviewCaptionReader())
        return board
    }())
    .frame(width: 640, height: 420)
}

private final class PreviewCaptionReader: LiveCaptionReading {
    func start(onText: @escaping (String) -> Void) {
        onText("Hello from Live Captions.\nThis line is still forming")
    }

    func stop() {}
}
