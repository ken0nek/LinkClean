//
//  CleanResultTests.swift
//  LinkCleanKitTests
//

import Testing
import Foundation
@testable import LinkCleanKit

struct CleanResultTests {

    @Test func countsRemovedParameters() {
        let result = URLCleaner.cleanResult(
            "https://x.com/?utm_source=a&utm_medium=b&id=1",
            removing: ["utm_source", "utm_medium"]
        )

        #expect(result.removedCount == 2)
        #expect(result.changed == true)
        #expect(!result.cleaned.contains("utm_source"))
        #expect(!result.cleaned.contains("utm_medium"))
        #expect(result.cleaned.contains("id=1"))
    }

    @Test func zeroWhenNothingRemoved() {
        let result = URLCleaner.cleanResult("https://x.com/?id=1", removing: ["utm_source"])

        #expect(result.removedCount == 0)
        #expect(result.changed == false)
        #expect(result.cleaned == "https://x.com/?id=1")
    }

    @Test func zeroForNoQuery() {
        let result = URLCleaner.cleanResult("https://x.com/path", removing: ["utm_source"])

        #expect(result.removedCount == 0)
        #expect(result.cleaned == "https://x.com/path")
    }

    @Test func cleanDelegatesToCleanResult() {
        let input = "https://x.com/?fbclid=z&id=1"
        #expect(URLCleaner.clean(input, removing: ["fbclid"]) == URLCleaner.cleanResult(input, removing: ["fbclid"]).cleaned)
    }

    @Test func urlOverloadReturnsCleanedURLAndResult() {
        let (cleaned, result) = URLCleaner.cleanResult(
            URL(string: "https://x.com/?fbclid=z&id=1")!,
            removing: ["fbclid"]
        )

        #expect(result.removedCount == 1)
        #expect(cleaned.absoluteString == "https://x.com/?id=1")
    }

    // MARK: - Catalog-gap analysis (parameter-telemetry.md Tier 0/1)

    @Test func reportsLeftoverCountAndRemovedKinds() {
        let result = URLCleaner.cleanResult(
            "https://x.com/?utm_source=a&fbclid=b&id=1&page=2",
            removing: ["utm_source", "fbclid"]
        )

        #expect(result.removedCount == 2)
        #expect(result.leftoverCount == 2)              // id, page survive
        #expect(result.removedKindIDs == ["utm", "ads"]) // utm_source→utm, fbclid→ads
    }

    @Test func removedKindsOmitsCustomParametersWithoutACatalogKind() {
        // A removed parameter outside the built-in catalog contributes no kind.
        let result = URLCleaner.cleanResult(
            "https://x.com/?my_custom=a&id=1",
            removing: ["my_custom"]
        )

        #expect(result.removedCount == 1)
        #expect(result.removedKindIDs.isEmpty)
    }

    @Test func referenceMatchesFlagKnownButNotDefaultTrackers() {
        // epik is a known tracker that is NOT in our catalog — a catalog gap.
        // (yclid, the previous example, graduated into the defaults.)
        let result = URLCleaner.cleanResult(
            "https://x.com/?utm_source=a&epik=b&id=1",
            removing: ["utm_source"]
        )

        #expect(result.referenceMatches == ["epik"])
        #expect(result.leftoverCount == 2) // epik + id survive (only utm_source removed)
    }

    @Test func referenceMatchesAreSortedUniqueAndUseInjectedSet() {
        let result = URLCleaner.cleanResult(
            "https://x.com/?b=1&a=2&b=3&plain=4",
            removing: [],
            referenceNames: ["a", "b"]
        )

        #expect(result.referenceMatches == ["a", "b"]) // sorted, deduped despite repeated b
        #expect(result.leftoverCount == 4)
    }

    @Test func noAnalysisNoiseForPlainParams() {
        let result = URLCleaner.cleanResult("https://x.com/?id=1&page=2", removing: [])

        #expect(result.referenceMatches.isEmpty)
        #expect(result.removedKindIDs.isEmpty)
        #expect(result.leftoverCount == 2)
    }

    // MARK: - Removed parameter names (Home transparency display)

    @Test func removedParameterNamesListsRemovedKeysInURLOrder() {
        let names = URLCleaner.removedParameterNames(
            "https://x.com/?utm_source=a&id=1&fbclid=b",
            removing: ["utm_source", "fbclid"]
        )

        #expect(names == ["utm_source", "fbclid"]) // only removed keys, in URL order
    }

    @Test func removedParameterNamesDedupesCaseInsensitivelyKeepingFirstCase() {
        let names = URLCleaner.removedParameterNames(
            "https://x.com/?Ref=a&ref=b&id=1",
            removing: ["ref"]
        )

        #expect(names == ["Ref"]) // matched case-insensitively, first-seen case kept, deduped
    }

    @Test func removedParameterNamesEmptyWhenNothingRemoved() {
        #expect(URLCleaner.removedParameterNames("https://x.com/?id=1", removing: ["utm_source"]).isEmpty)
        #expect(URLCleaner.removedParameterNames("https://x.com/path", removing: ["utm_source"]).isEmpty)
    }

    @Test func leftoverParameterNamesListSurvivingKeysIncludingArbitraryOnes() {
        let names = URLCleaner.leftoverParameterNames(
            "https://x.com/?utm_source=a&test=xxx&id=1",
            removing: ["utm_source"]
        )

        #expect(names == ["test", "id"]) // everything not removed, arbitrary keys included, URL order
    }

    @Test func leftoverParameterNamesEmptyWhenAllRemovedOrNoQuery() {
        #expect(URLCleaner.leftoverParameterNames("https://x.com/?utm_source=a", removing: ["utm_source"]).isEmpty)
        #expect(URLCleaner.leftoverParameterNames("https://x.com/path", removing: []).isEmpty)
    }

    @Test func novelLeftoverNamesNeverBecomeReferenceMatches() {
        // Privacy guard at the source: referenceMatches is the ONLY place a
        // leftover key name is surfaced, and it can only ever contain names from
        // the public reference catalog. An arbitrary/novel key (which could hold
        // anything sensitive) must never leak through it.
        let result = URLCleaner.cleanResult(
            "https://x.com/?my_private_token=secret&q=hello&id=1",
            removing: []
        )

        #expect(result.referenceMatches.isEmpty)
        #expect(result.leftoverCount == 3)
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
