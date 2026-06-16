//
//  TemplateRendererTests.swift
//  LinkCleanCoreTests
//

import Testing
import Foundation
@testable import LinkCleanCore

struct TemplateRendererTests {
    /// A fixed context so token substitution is fully deterministic. The date is a
    /// known instant; tests format it with a UTC calendar so `{date}`/`{time}`
    /// don't depend on the test machine's time zone.
    private let context = TemplateContext(
        cleaned: "https://youtube.com/watch?v=abc&t=10",
        original: "https://www.youtube.com/watch?v=abc&t=10&utm_source=share",
        host: "youtube.com",
        removedCount: 3,
        title: "Big Buck Bunny",
        date: Date(timeIntervalSince1970: 1_750_000_000) // 2025-06-15 15:06:40 UTC
    )

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func render(_ format: String) -> String {
        TemplateRenderer.render(format: format, context, calendar: utc)
    }

    // MARK: - Sync tokens

    @Test func substitutesLink() {
        #expect(render("{link}") == "https://youtube.com/watch?v=abc&t=10")
    }

    @Test func substitutesOriginalLink() {
        #expect(render("{originalLink}") == "https://www.youtube.com/watch?v=abc&t=10&utm_source=share")
    }

    @Test func substitutesHostAndRemovedCount() {
        #expect(render("{host} removed {removedCount}") == "youtube.com removed 3")
    }

    @Test func substitutesURLComponents() {
        #expect(render("{scheme}") == "https")
        #expect(render("{path}") == "/watch")
        #expect(render("{query}") == "v=abc&t=10")
    }

    @Test func urlComponentsKeepPercentEncodingForRoundTrip() {
        // {path}/{query} must preserve percent-encoding so a reassembled URL stays
        // equivalent — decoding would turn %20→space and %2B→'+' and break the link.
        let encoded = TemplateContext(
            cleaned: "https://x.com/a%20b?q=hello%20world&n=1%2B2",
            original: "https://x.com/a%20b?q=hello%20world&n=1%2B2",
            host: "x.com", removedCount: 0, title: nil, date: .now
        )
        #expect(TemplateRenderer.render(format: "{path}", encoded) == "/a%20b")
        #expect(TemplateRenderer.render(format: "{query}", encoded) == "q=hello%20world&n=1%2B2")
    }

    @Test func substitutesNewlineAndTab() {
        #expect(render("a{newline}b{tab}c") == "a\nb\tc")
    }

    // MARK: - Title (async-sourced) and the markdown shorthand

    @Test func substitutesTitle() {
        #expect(render("{title}") == "Big Buck Bunny")
    }

    @Test func absentTitleRendersEmpty() {
        let titleless = TemplateContext(
            cleaned: "https://x.com/a", original: "https://x.com/a",
            host: "x.com", removedCount: 0, title: nil, date: .now
        )
        #expect(TemplateRenderer.render(format: "[{title}]", titleless) == "[]")
    }

    @Test func markdownTokenUsesFormatterWithTitle() {
        #expect(render("{markdown}") == "[Big Buck Bunny](https://youtube.com/watch?v=abc&t=10)")
    }

    @Test func markdownTokenFallsBackToURLWhenNoTitle() {
        // MarkdownFormatter uses the URL as link text when title is nil — the
        // shorthand inherits that, unlike a bare `{title}` which renders empty.
        let titleless = TemplateContext(
            cleaned: "https://x.com/a", original: "https://x.com/a",
            host: "x.com", removedCount: 0, title: nil, date: .now
        )
        #expect(TemplateRenderer.render(format: "{markdown}", titleless) == "[https://x.com/a](https://x.com/a)")
    }

    // MARK: - Unknown tokens stay literal (the forgiving design, §2.1)

    @Test func unknownTokenIsLeftLiteral() {
        #expect(render("{foo}") == "{foo}")
        #expect(render("{link} {foo} {host}") == "https://youtube.com/watch?v=abc&t=10 {foo} youtube.com")
    }

    @Test func emptyBracesAreLiteral() {
        #expect(render("{}") == "{}")
    }

    @Test func unmatchedOpenBraceIsLiteral() {
        #expect(render("{link} {unclosed") == "https://youtube.com/watch?v=abc&t=10 {unclosed")
    }

    @Test func literalTextWithoutTokensPassesThrough() {
        #expect(render("just plain text") == "just plain text")
    }

    // MARK: - Date / time formatting (deterministic via injected calendar)

    @Test func formatsDateAndTimeFromInjectedClock() {
        #expect(render("{date}") == "2025-06-15")
        #expect(render("{time}") == "15:06")
    }

    @Test func dateRespectsCalendarTimeZone() {
        // The same instant in a +14h zone lands on the next calendar day.
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Pacific/Kiritimati")! // UTC+14
        #expect(TemplateRenderer.render(format: "{date}", context, calendar: tokyo) == "2025-06-16")
    }

    // MARK: - Built-in presets render as documented (§3)

    @Test func builtinPresetsRender() {
        func r(_ t: LinkTemplate) -> String { TemplateRenderer.render(t, context, calendar: utc) }
        #expect(r(.cleanPreset) == "https://youtube.com/watch?v=abc&t=10")
        #expect(r(.markdownPreset) == "[Big Buck Bunny](https://youtube.com/watch?v=abc&t=10)")
        #expect(r(.titleAndURLPreset) == "Big Buck Bunny\nhttps://youtube.com/watch?v=abc&t=10")
        #expect(r(.htmlPreset) == "<a href=\"https://youtube.com/watch?v=abc&t=10\">Big Buck Bunny</a>")
        #expect(r(.quotePreset) == "> Big Buck Bunny\nhttps://youtube.com/watch?v=abc&t=10")
        #expect(r(.citationPreset) == "Big Buck Bunny — youtube.com (2025-06-15)")
        #expect(r(.slackPreset) == "<https://youtube.com/watch?v=abc&t=10|Big Buck Bunny>")
        #expect(r(.plainTitlePreset) == "Big Buck Bunny")
    }

    @Test func markdownPresetFallsBackToURLLabelWhenNoTitle() {
        // The free Markdown default must render `[url](url)` (not a broken empty
        // `[](url)` label) on the common no-title path — it uses the {markdown}
        // shorthand precisely so it inherits MarkdownFormatter's URL fallback.
        let titleless = TemplateContext(
            cleaned: "https://x.com/?id=1", original: "https://x.com/?id=1",
            host: "x.com", removedCount: 0, title: nil, date: .now
        )
        #expect(TemplateRenderer.render(.markdownPreset, titleless)
            == "[https://x.com/?id=1](https://x.com/?id=1)")
    }

    // MARK: - usesTitle drives whether the strategy pays for a title fetch (§5)

    @Test func usesTitleReflectsTokenPresence() {
        #expect(LinkTemplate.markdownPreset.usesTitle)   // contains {title}
        #expect(LinkTemplate.plainTitlePreset.usesTitle)
        #expect(LinkTemplate.citationPreset.usesTitle)
        #expect(!LinkTemplate.cleanPreset.usesTitle)     // {link} only
        // The {markdown} shorthand also implies a title lookup.
        #expect(LinkTemplate.custom(id: UUID(), name: "x", format: "{markdown}").usesTitle)
        #expect(!LinkTemplate.custom(id: UUID(), name: "x", format: "{host} {date}").usesTitle)
    }

    // MARK: - TemplateContext from a CleanOutcome derives host and counts

    @Test func contextFromOutcomeDerivesHostStrippingWWW() {
        let outcome = URLCleaner.outcome(for: "https://www.youtube.com/watch?v=abc&utm_source=x", removing: ["utm_source"])
        let ctx = TemplateContext(outcome: outcome, title: "T", date: .now)
        #expect(ctx.host == "youtube.com")        // www. stripped
        #expect(ctx.cleaned == outcome.cleaned)
        #expect(ctx.original == outcome.input)
        #expect(ctx.removedCount == 1)
    }

    @Test func contextFromOutcomeRendersEmptyHostForHostlessInput() {
        let outcome = URLCleaner.outcome(for: "not a url", removing: [])
        let ctx = TemplateContext(outcome: outcome, title: nil, date: .now)
        // The "unknown" analytics sentinel is mapped to empty for display.
        #expect(ctx.host == "")
    }
}
