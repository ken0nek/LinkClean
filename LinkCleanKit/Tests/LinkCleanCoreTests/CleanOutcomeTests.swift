//
//  CleanOutcomeTests.swift
//  LinkCleanCoreTests
//

import Testing
import Foundation
@testable import LinkCleanCore

struct CleanOutcomeTests {

    @Test func countsRemovedParameters() {
        let outcome = URLCleaner.outcome(
            for: "https://x.com/?utm_source=a&utm_medium=b&id=1",
            removing: ["utm_source", "utm_medium"]
        )

        #expect(outcome.telemetry.removedCount == 2)
        #expect(outcome.telemetry.changed == true)
        #expect(!outcome.cleaned.contains("utm_source"))
        #expect(!outcome.cleaned.contains("utm_medium"))
        #expect(outcome.cleaned.contains("id=1"))
    }

    @Test func zeroWhenNothingRemoved() {
        let outcome = URLCleaner.outcome(for: "https://x.com/?id=1", removing: ["utm_source"])

        #expect(outcome.telemetry.removedCount == 0)
        #expect(outcome.telemetry.changed == false)
        #expect(outcome.cleaned == "https://x.com/?id=1")
    }

    @Test func zeroForNoQuery() {
        let outcome = URLCleaner.outcome(for: "https://x.com/path", removing: ["utm_source"])

        #expect(outcome.telemetry.removedCount == 0)
        #expect(outcome.cleaned == "https://x.com/path")
    }

    @Test func cleanDelegatesToOutcome() {
        let input = "https://x.com/?fbclid=z&id=1"
        #expect(URLCleaner.clean(input, removing: ["fbclid"]) == URLCleaner.outcome(for: input, removing: ["fbclid"]).cleaned)
    }

    @Test func urlOverloadCleansAndOutcomeCounts() {
        let url = URL(string: "https://x.com/?fbclid=z&id=1")!
        #expect(URLCleaner.clean(url, removing: ["fbclid"]).absoluteString == "https://x.com/?id=1")

        let outcome = URLCleaner.outcome(for: url.absoluteString, removing: ["fbclid"])
        #expect(outcome.telemetry.removedCount == 1)
        #expect(outcome.cleaned == "https://x.com/?id=1")
    }

    // MARK: - Telemetry: catalog-gap analysis (parameter-telemetry.md Tier 0/1)

    @Test func reportsLeftoverCountAndRemovedKinds() {
        let outcome = URLCleaner.outcome(
            for: "https://x.com/?utm_source=a&fbclid=b&id=1&page=2",
            removing: ["utm_source", "fbclid"]
        )

        #expect(outcome.telemetry.removedCount == 2)
        #expect(outcome.telemetry.leftoverCount == 2)              // id, page survive
        #expect(outcome.telemetry.removedKindIDs == ["utm", "ads"]) // utm_source→utm, fbclid→ads
    }

    @Test func removedKindsOmitsCustomParametersWithoutACatalogKind() {
        // A removed parameter outside the built-in catalog contributes no kind.
        let outcome = URLCleaner.outcome(
            for: "https://x.com/?my_custom=a&id=1",
            removing: ["my_custom"]
        )

        #expect(outcome.telemetry.removedCount == 1)
        #expect(outcome.telemetry.removedKindIDs.isEmpty)
    }

    @Test func referenceMatchesFlagKnownButNotDefaultTrackers() {
        // epik is a known tracker that is NOT in our catalog — a catalog gap.
        // (yclid, the previous example, graduated into the defaults.)
        let outcome = URLCleaner.outcome(
            for: "https://x.com/?utm_source=a&epik=b&id=1",
            removing: ["utm_source"]
        )

        #expect(outcome.telemetry.referenceMatches == ["epik"])
        #expect(outcome.telemetry.leftoverCount == 2) // epik + id survive (only utm_source removed)
    }

    @Test func referenceMatchesAreSortedUniqueAndUseInjectedSet() {
        let outcome = URLCleaner.outcome(
            for: "https://x.com/?b=1&a=2&b=3&plain=4",
            removing: [],
            referenceNames: ["a", "b"]
        )

        #expect(outcome.telemetry.referenceMatches == ["a", "b"]) // sorted, deduped despite repeated b
        #expect(outcome.telemetry.leftoverCount == 4)
    }

    @Test func noAnalysisNoiseForPlainParams() {
        let outcome = URLCleaner.outcome(for: "https://x.com/?id=1&page=2", removing: [])

        #expect(outcome.telemetry.referenceMatches.isEmpty)
        #expect(outcome.telemetry.removedKindIDs.isEmpty)
        #expect(outcome.telemetry.leftoverCount == 2)
    }

    @Test func telemetryDomainMatchesAnalyticsDomain() {
        let outcome = URLCleaner.outcome(for: "https://www.YouTube.com/watch?v=x&si=a", removing: ["si"])
        #expect(outcome.telemetry.domain == "youtube.com")
    }

    @Test func recordsTheWrappersItIsGiven() {
        let outcome = URLCleaner.outcome(
            for: "https://shop.example.com/?utm_source=x",
            removing: ["utm_source"],
            wrappers: ["google.com"]
        )
        #expect(outcome.telemetry.wrappers == ["google.com"])
    }

    @Test func recordsWrappersOnTheNoQueryGuardPath() {
        // The early-return (no query items) path must still report the wrappers —
        // a wrapper can resolve to a destination that carries no query at all.
        let outcome = URLCleaner.outcome(for: "https://example.com/", removing: [], wrappers: ["google.com", "l.facebook.com"])
        #expect(outcome.telemetry.wrappers == ["google.com", "l.facebook.com"])
    }

    @Test func wrappersDefaultToEmptyForADirectClean() {
        #expect(URLCleaner.outcome(for: "https://x.com/?utm_source=a", removing: ["utm_source"]).telemetry.wrappers.isEmpty)
    }

    // MARK: - Display: removed/leftover names (Home transparency, on-device only)

    @Test func displayRemovedNamesListsRemovedKeysInURLOrder() {
        let outcome = URLCleaner.outcome(
            for: "https://x.com/?utm_source=a&id=1&fbclid=b",
            removing: ["utm_source", "fbclid"]
        )

        #expect(outcome.display.removedNames == ["utm_source", "fbclid"]) // only removed keys, in URL order
    }

    @Test func displayRemovedNamesDedupeCaseInsensitivelyKeepingFirstCase() {
        let outcome = URLCleaner.outcome(
            for: "https://x.com/?Ref=a&ref=b&id=1",
            removing: ["ref"]
        )

        #expect(outcome.display.removedNames == ["Ref"]) // matched case-insensitively, first-seen case kept, deduped
    }

    @Test func displayRemovedNamesEmptyWhenNothingRemoved() {
        #expect(URLCleaner.outcome(for: "https://x.com/?id=1", removing: ["utm_source"]).display.removedNames.isEmpty)
        #expect(URLCleaner.outcome(for: "https://x.com/path", removing: ["utm_source"]).display.removedNames.isEmpty)
    }

    @Test func displayLeftoverNamesListSurvivingKeysIncludingArbitraryOnes() {
        let outcome = URLCleaner.outcome(
            for: "https://x.com/?utm_source=a&test=xxx&id=1",
            removing: ["utm_source"]
        )

        #expect(outcome.display.leftoverNames == ["test", "id"]) // everything not removed, arbitrary keys included, URL order
    }

    @Test func displayLeftoverNamesEmptyWhenAllRemovedOrNoQuery() {
        #expect(URLCleaner.outcome(for: "https://x.com/?utm_source=a", removing: ["utm_source"]).display.leftoverNames.isEmpty)
        #expect(URLCleaner.outcome(for: "https://x.com/path", removing: []).display.leftoverNames.isEmpty)
    }

    @Test func novelLeftoverNamesNeverBecomeReferenceMatches() {
        // Privacy guard at the source: referenceMatches is the ONLY place a
        // leftover key name is surfaced *to telemetry*, and it can only ever
        // contain names from the public reference catalog. An arbitrary/novel key
        // (which could hold anything sensitive) must never leak through it — even
        // though it does appear in `display.leftoverNames` for the on-device UI.
        let outcome = URLCleaner.outcome(
            for: "https://x.com/?my_private_token=secret&q=hello&id=1",
            removing: []
        )

        #expect(outcome.telemetry.referenceMatches.isEmpty)
        #expect(outcome.telemetry.leftoverCount == 3)
        #expect(outcome.display.leftoverNames == ["my_private_token", "q", "id"])
    }

    // MARK: - Analytics domain (site-popularity signal, analytics.md §3)

    @Test func analyticsDomainLowercasesAndStripsLeadingWWW() {
        #expect(URLCleaner.analyticsDomain(from: "https://www.YouTube.com/watch?v=abc&si=x") == "youtube.com")
        #expect(URLCleaner.analyticsDomain(from: "https://X.com/foo?s=20") == "x.com")
    }

    @Test func analyticsDomainPreservesNonWWWSubdomains() {
        // Only `www.` is stripped — `m.`/shorteners stay distinct for now.
        #expect(URLCleaner.analyticsDomain(from: "https://m.youtube.com/watch?v=abc") == "m.youtube.com")
    }

    @Test func analyticsDomainReturnsUnknownWhenNoHost() {
        #expect(URLCleaner.analyticsDomain(from: "mailto:hi@example.com") == "unknown")
        #expect(URLCleaner.analyticsDomain(from: "not a url") == "unknown")
    }

    @Test func analyticsDomainURLOverloadMatchesStringOverload() {
        let url = URL(string: "https://www.amazon.com/dp/B0?tag=aff")!
        #expect(URLCleaner.analyticsDomain(from: url) == "amazon.com")
    }

    @Test func analyticsDomainStripsTrailingRootDot() {
        // A fully-qualified host (`youtube.com.`) must aggregate with the common form.
        #expect(URLCleaner.analyticsDomain(from: "https://youtube.com./watch?v=x") == "youtube.com")
        #expect(URLCleaner.analyticsDomain(from: "https://www.youtube.com./x") == "youtube.com")
    }

    @Test func analyticsDomainDoesNotOverStripWWWLikeLabels() {
        // `hasPrefix("www.")` (with the dot) must not strip `www2`.
        #expect(URLCleaner.analyticsDomain(from: "https://www2.example.com/x") == "www2.example.com")
    }

    @Test func analyticsDomainKeepsOnlyHostNeverUserinfoPortOrPath() {
        // Privacy lock (analytics.md §3): only the bare host ever leaves — never
        // userinfo, port, path, query, or fragment.
        #expect(URLCleaner.analyticsDomain(from: "https://user:pass@host.com:8443/p?token=SECRET#frag") == "host.com")
    }
}
