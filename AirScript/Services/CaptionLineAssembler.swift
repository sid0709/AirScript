import Foundation

/// Turns the Live Captions overlay snapshot into a scrolling board.
/// The last line stays live and updates in place; a line break commits it.
struct CaptionLineAssembler {
    private(set) var lines: [CaptionLine] = []
    private var lastParts: [String] = []

    mutating func reset() {
        lines = []
        lastParts = []
    }

    mutating func ingest(_ raw: String) {
        let parts = Self.splitLines(raw)
        guard !parts.isEmpty, parts != lastParts else { return }

        let liveText = parts[parts.count - 1]
        let overlayCommitted = Array(parts.dropLast())

        if shouldCommit(for: parts) {
            commitLiveIfNeeded()
        }

        for line in overlayCommitted {
            ensureCommitted(line)
        }
        replaceLive(with: liveText)
        lastParts = parts
    }

    static func splitLines(_ raw: String) -> [String] {
        let normalized = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{2028}", with: "\n")
            .replacingOccurrences(of: "\u{2029}", with: "\n")
        return normalized
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " ")) }
            .filter { !$0.isEmpty }
    }

    private func shouldCommit(for parts: [String]) -> Bool {
        guard let oldLive = lastParts.last else { return false }
        if parts.count > lastParts.count { return true }
        let old = lastParts.joined(separator: "\n")
        let next = parts.joined(separator: "\n")
        if next.hasPrefix(old + "\n") { return true }
        return parts.dropLast().contains(oldLive)
    }

    private mutating func ensureCommitted(_ line: String) {
        if lines.contains(where: { !$0.isLive && $0.text == line }) { return }
        if lines.last?.isLive == true, lines.last?.text == line { return }
        let insertAt = lines.lastIndex(where: \.isLive) ?? lines.endIndex
        lines.insert(CaptionLine(text: line, isLive: false), at: insertAt)
    }

    private mutating func commitLiveIfNeeded() {
        guard let index = lines.lastIndex(where: \.isLive) else { return }
        if lines[index].text.isEmpty {
            lines.remove(at: index)
            return
        }
        lines[index].isLive = false
    }

    private mutating func replaceLive(with text: String) {
        guard !text.isEmpty else { return }
        if let index = lines.lastIndex(where: \.isLive) {
            lines[index].text = text
            return
        }
        lines.append(CaptionLine(text: text, isLive: true))
    }
}
