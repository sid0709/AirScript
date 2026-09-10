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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(DS.Spacing.lg)
            } else {
                captionList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            numpadLegend
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Label(board.status.toolbarLabel, systemImage: statusSymbol)
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .labelStyle(.titleAndIcon)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    board.isRunning ? board.stop() : board.start()
                } label: {
                    Label(
                        board.isRunning ? "Pause" : "Listen",
                        systemImage: board.isRunning ? "pause.fill" : "waveform"
                    )
                }
                .help(board.isRunning ? "Pause" : "Listen")
                .controlSize(.regular)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: board.clear) {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(board.lines.isEmpty)
                .help("Clear")
                .controlSize(.regular)
            }
        }
        .onAppear {
            if !board.isRunning { board.start() }
        }
    }

    private var captionList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(board.lines) { line in
                    CaptionLineRow(line: line)
                        .id(line.id)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(
                            top: DS.Spacing.xs,
                            leading: DS.Spacing.md,
                            bottom: DS.Spacing.xs,
                            trailing: DS.Spacing.md
                        ))
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
            .onChange(of: board.lines.last?.id) { _, id in
                guard let id else { return }
                proxy.scrollTo(id, anchor: .bottom)
            }
            .onChange(of: board.lines.last?.text) { _, _ in
                if let id = board.lines.last?.id {
                    proxy.scrollTo(id, anchor: .bottom)
                }
            }
        }
    }

    private var numpadLegend: some View {
        Text("1–9 sentences · 0 all · . . clear")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
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
