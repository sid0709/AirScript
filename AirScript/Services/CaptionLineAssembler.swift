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
        let parts = CaptionTextMerge.collapse(Self.splitLines(raw))
        guard !parts.isEmpty, parts != lastParts else { return }

        let liveText = parts[parts.count - 1]
        let overlayCommitted = Array(parts.dropLast())

        if let liveIndex = lines.lastIndex(where: \.isLive) {
            let previousLive = lines[liveIndex].text
            // LastCry: same rolling caption → pop last chunk and replace it.
            if CaptionTextMerge.isSameUtterance(previousLive, liveText) {
                lines[liveIndex].text = CaptionTextMerge.preferred(previousLive, liveText)
                for line in overlayCommitted where !CaptionTextMerge.isSameUtterance(line, lines[liveIndex].text) {
                    ensureCommitted(line)
                }
                lastParts = parts
                return
            }
            if let stable = CaptionTextMerge.scrolledOffPrefix(prev: previousLive, current: liveText) {
                lines[liveIndex].text = stable
                lines[liveIndex].isLive = false
                lines.append(CaptionLine(text: liveText, isLive: true))
                lastParts = parts
                return
            }
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

    private mutating func ensureCommitted(_ line: String) {
        if CaptionTextMerge.isChrome(line) { return }
        if let index = lines.lastIndex(where: {
            !$0.isLive && CaptionTextMerge.isSameUtterance($0.text, line)
        }) {
            lines[index].text = CaptionTextMerge.preferred(lines[index].text, line)
            return
        }
        if let last = lines.last, last.isLive, CaptionTextMerge.isSameUtterance(last.text, line) {
            return
        }
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
