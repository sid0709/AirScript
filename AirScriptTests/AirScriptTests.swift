import Testing
@testable import AirScript

struct CaptionLineAssemblerTests {
    @Test func splitsOnLineBreaks() {
        let parts = CaptionLineAssembler.splitLines("hello\nworld\r\nthird\u{2028}fourth")
        #expect(parts == ["hello", "world", "third", "fourth"])
    }

    @Test func growsTheLiveLineInPlace() {
        var assembler = CaptionLineAssembler()
        assembler.ingest("Hel")
        assembler.ingest("Hello")
        assembler.ingest("Hello there")
        #expect(assembler.lines.count == 1)
        #expect(assembler.lines[0].text == "Hello there")
        #expect(assembler.lines[0].isLive)
    }

    @Test func startsANewLineAfterALineBreak() {
        var assembler = CaptionLineAssembler()
        assembler.ingest("Hello there")
        assembler.ingest("Hello there\nHow are you")
        #expect(assembler.lines.count == 2)
        #expect(assembler.lines[0].text == "Hello there")
        #expect(assembler.lines[0].isLive == false)
        #expect(assembler.lines[1].text == "How are you")
        #expect(assembler.lines[1].isLive)
    }

    @Test func commitsEachOverlayLineAndKeepsTheLastLive() {
        var assembler = CaptionLineAssembler()
        assembler.ingest("One\nTwo\nThree")
        #expect(assembler.lines.map(\.text) == ["One", "Two", "Three"])
        #expect(assembler.lines.map(\.isLive) == [false, false, true])
    }

    @Test func ignoresEmptySnapshotsSoHistoryRemains() {
        var assembler = CaptionLineAssembler()
        assembler.ingest("Kept line")
        assembler.ingest("   \n")
        #expect(assembler.lines.map(\.text) == ["Kept line"])
    }

    @Test func sameSnapshotIsANoOp() {
        var assembler = CaptionLineAssembler()
        assembler.ingest("Stable")
        let id = assembler.lines[0].id
        assembler.ingest("Stable")
        #expect(assembler.lines[0].id == id)
    }
}
