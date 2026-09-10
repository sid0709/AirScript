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
                StatusToolbarChip(status: board.status)
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
                ForEach(board.committedLines) { line in
                    captionRow(line)
                }
                if let live = board.liveLine {
                    captionRow(live)
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
            .onChange(of: board.liveLine?.id) { _, _ in
                scrollToLatest(proxy)
            }
            .onChange(of: board.liveLine?.text) { _, _ in
                scrollToLatest(proxy)
            }
            .onChange(of: board.committedLines.last?.id) { _, _ in
                scrollToLatest(proxy)
            }
        }
    }

    private func captionRow(_ line: CaptionLine) -> some View {
        CaptionLineRow(line: line)
            .equatable()
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

    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        if let id = board.liveLine?.id ?? board.committedLines.last?.id {
            proxy.scrollTo(id, anchor: .bottom)
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
}

#Preview {
    CaptionBoardView(board: CaptionBoardViewModel())
        .frame(width: 640, height: 420)
}
