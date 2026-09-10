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

    @Test func collapsesGrowingPrefixesFromOneAXSnapshot() {
        var assembler = CaptionLineAssembler()
        assembler.ingest("""
        Live Captions Running
        I talk a lot about this spotot that I built
        I talk a lot about this spotot that I built called Benny and
        I talk a lot about this spotot that I built called Benny and I wanted to
        I talk a lot about this bot that I built called Benny, and I wanted to figure out how would I make it so my agents can just automatically fix bugs for me while I sleep?
        """)
        #expect(assembler.lines.count == 1)
        #expect(assembler.lines[0].isLive)
        #expect(assembler.lines[0].text.contains("fix bugs for me while I sleep"))
        #expect(assembler.lines[0].text.contains("Live Captions") == false)
    }

    @Test func growingPartialsUpdateTheLiveLineInsteadOfStacking() {
        var assembler = CaptionLineAssembler()
        assembler.ingest("I talk a lot about this spotot that I built")
        assembler.ingest("I talk a lot about this spotot that I built called Benny and")
        assembler.ingest("I talk a lot about this spotot that I built called Benny and I wanted to figure out how would I")
        assembler.ingest("I talk a lot about this bot that I built called Benny, and I wanted to figure out how would I make it so my agents")
        #expect(assembler.lines.count == 1)
        #expect(assembler.lines[0].isLive)
        #expect(assembler.lines[0].text.contains("called Benny"))
    }

    @Test func commitsWhenANewUtteranceAppears() {
        var assembler = CaptionLineAssembler()
        assembler.ingest("I talk a lot about this bot that I built called Benny")
        assembler.ingest("""
        I talk a lot about this bot that I built called Benny, and I wanted to figure out how would I make it so my agents can just automatically fix bugs for me while I sleep?
        And so that was the inspiration for some of our earlier experiments, like you know, what if everybody could define one of their own
        """)
        #expect(assembler.lines.count == 2)
        #expect(assembler.lines[0].isLive == false)
        #expect(assembler.lines[0].text.contains("fix bugs for me while I sleep"))
        #expect(assembler.lines[1].isLive)
        #expect(assembler.lines[1].text.hasPrefix("And so that was the inspiration"))
    }

    @Test func dropsLiveCaptionsChrome() {
        #expect(CaptionTextMerge.isChrome("Live Captions Running"))
        #expect(CaptionTextMerge.collapse(["Live Captions Running", "Hello there"]) == ["Hello there"])
    }

    @Test func scrolledOffOverlapCommitsTheStablePrefix() {
        var assembler = CaptionLineAssembler()
        assembler.ingest("I talk a lot about this bot that I built called Benny and I wanted to figure out")
        assembler.ingest("called Benny and I wanted to figure out how would I make it so my agents")
        #expect(assembler.lines.count == 2)
        #expect(assembler.lines[0].isLive == false)
        #expect(assembler.lines[0].text.contains("I talk a lot about this bot"))
        #expect(assembler.lines[1].isLive)
        #expect(assembler.lines[1].text.hasPrefix("called Benny"))
    }

    @Test func replacesLiveChunkOnPunctuationAndSmallGrowth() {
        var assembler = CaptionLineAssembler()
        assembler.ingest("The max which we have")
        assembler.ingest("The max which we have\nThe max which we have $130,000 per a year.")
        assembler.ingest("Should I quote you")
        assembler.ingest("Should I quote you?")
        assembler.ingest("So just be here")
        assembler.ingest("So just be here with me.")
        #expect(assembler.lines.map(\.text) == [
            "The max which we have $130,000 per a year.",
            "Should I quote you?",
            "So just be here with me.",
        ])
        #expect(assembler.lines.last?.isLive == true)
    }

    @Test func doesNotStackWhenAXTreeKeepsEveryPartial() {
        var assembler = CaptionLineAssembler()
        assembler.ingest("if the client also have")
        assembler.ingest("""
        if the client also have
        if the client also have avility uh
        if the client also have avility uh if they also are
        """)
        assembler.ingest("""
        if the client also have
        if the client also have avility uh
        if the client also have avility uh if they also are available at that time then they will schedule an interview with you over one of virtual longterm interview.
        If the client also have ability, uh if they also are available at that time, then they will schedule an interview with you over a virtual long-term interview.
        """)
        #expect(assembler.lines.count == 1)
        #expect(assembler.lines[0].isLive)
        #expect(assembler.lines[0].text.contains("long-term interview"))
    }
}
