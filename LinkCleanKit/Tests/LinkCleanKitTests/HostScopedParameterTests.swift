//
//  HostScopedParameterTests.swift
//  LinkCleanKitTests
//

import Testing
import Foundation
@testable import LinkCleanKit

/// The catalog's three rule classes — global, host-scoped, and
/// off-by-default — exist so cleaning never breaks a functional parameter:
/// `?t=` is a share tracker on x.com but a timestamp on YouTube and a thread
/// id on forums. These tests pin the class boundaries end-to-end.
struct HostScopedParameterTests {

    // MARK: - Catalog defaults via URLCleaner.clean

    @Test func keepsYouTubeTimestampWhileStrippingShareTracker() {
        let result = URLCleaner.clean("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=120s&si=AbCdEf")
        #expect(result == "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=120s")
    }

    @Test func stripsShareTokensOnYoutuBeShortLinks() {
        let result = URLCleaner.clean("https://youtu.be/dQw4w9WgXcQ?si=AbCdEf&t=42")
        #expect(result == "https://youtu.be/dQw4w9WgXcQ?t=42")
    }

    @Test func stripsShareTokensOnXAndTwitter() {
        #expect(URLCleaner.clean("https://x.com/user/status/1?s=46&t=AbCdE") == "https://x.com/user/status/1")
        #expect(URLCleaner.clean("https://twitter.com/user/status/1?s=20") == "https://twitter.com/user/status/1")
    }

    @Test func subdomainsMatchScopedHosts() {
        #expect(URLCleaner.clean("https://mobile.twitter.com/u/status/1?t=x") == "https://mobile.twitter.com/u/status/1")
        #expect(URLCleaner.clean("https://m.youtube.com/watch?v=a&si=x") == "https://m.youtube.com/watch?v=a")
    }

    @Test func keepsScopedNamesOnUnrelatedHosts() {
        // WordPress search and a generic session key must survive.
        #expect(URLCleaner.clean("https://myblog.com/?s=swift+concurrency") == "https://myblog.com/?s=swift+concurrency")
        #expect(URLCleaner.clean("https://example.com/page?si=session&feature=flags") == "https://example.com/page?si=session&feature=flags")
    }

    @Test func suffixMatchRequiresALabelBoundary() {
        // notx.com must not match the x.com rule.
        #expect(URLCleaner.clean("https://notx.com/page?t=1") == "https://notx.com/page?t=1")
    }

    @Test func stripsSpotifyShareTokens() {
        let result = URLCleaner.clean("https://open.spotify.com/track/abc?si=XyZ123")
        #expect(result == "https://open.spotify.com/track/abc")
    }

    @Test func keepsSharePayloadAndGenericNamesEverywhere() {
        // Share-intent payloads, sharer targets, and issue templates are the
        // very links over-cleaning would destroy.
        #expect(
            URLCleaner.clean("https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fexample.com")
                == "https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fexample.com"
        )
        #expect(
            URLCleaner.clean("https://github.com/o/r/issues/new?title=Bug&body=Steps")
                == "https://github.com/o/r/issues/new?title=Bug&body=Steps"
        )
        #expect(
            URLCleaner.clean("https://wa.me/123?text=Hello")
                == "https://wa.me/123?text=Hello"
        )
    }

    @Test func newVendorParametersStripEverywhere() {
        let result = URLCleaner.clean(
            "https://example.com/p?utm_id=1&gbraid=2&wbraid=3&srsltid=4&gad_source=5&gad_campaignid=6&twclid=7&ttclid=8&yclid=9&mibextid=10&_hsenc=11&_hsmi=12&mkt_tok=13&keep=yes"
        )
        #expect(result == "https://example.com/p?keep=yes")
    }

    @Test func defaultRemovalSetWithoutHostHasNoScopedNames() {
        let set = TrackingParameterCatalog.defaultRemovalSet(forHost: nil)
        #expect(set.contains("utm_source"))
        for scoped in ["t", "s", "si", "feature", "rcm", "referrer", "xmt"] {
            #expect(!set.contains(scoped), "\(scoped) is host-scoped and must not apply without a host")
        }
        for off in ["url", "text", "title", "summary", "mini", "u", "app", "ref", "cid", "aid"] {
            #expect(!set.contains(off), "\(off) ships disabled")
        }
    }

    @Test func definitionHostMatchingNormalizesCase() {
        let definition = TrackingParameterCatalog.definition(for: "t")
        #expect(definition?.appliesTo(host: "x.com") == true)
        #expect(definition?.appliesTo(host: "mobile.x.com") == true)
        #expect(definition?.appliesTo(host: "example.com") == false)
        #expect(URLCleaner.clean("https://X.com/u/status/1?t=x") == "https://X.com/u/status/1")
    }

    // MARK: - Store overrides

    private func makeStore() -> TrackingParameterStore {
        TrackingParameterStore(suiteName: "test.scoping.\(UUID().uuidString)")
    }

    @Test func isEnabledReflectsCatalogDefault() {
        let store = makeStore()
        #expect(store.isEnabled("utm_source") == true)
        #expect(store.isEnabled("t") == true)       // scoped but on
        #expect(store.isEnabled("title") == false)  // ships disabled
    }

    @Test func optInEnablesAnOffByDefaultParameter() {
        let store = makeStore()
        store.setEnabled("title", isEnabled: true)

        #expect(store.isEnabled("title") == true)
        #expect(store.enabledParameters(forHost: "example.com").contains("title"))
    }

    @Test func optInRoundTripsBackToDefault() {
        let store = makeStore()
        store.setEnabled("title", isEnabled: true)
        store.setEnabled("title", isEnabled: false)

        #expect(store.isEnabled("title") == false)
        #expect(store.disabledParameterNames().isEmpty) // matching the default stores no override
    }

    @Test func disablingAScopedRuleStopsStrippingOnItsHosts() {
        let store = makeStore()
        store.setEnabled("t", isEnabled: false)

        #expect(!store.enabledParameters(forHost: "x.com").contains("t"))
    }

    @Test func enabledParametersResolveHostScope() {
        let store = makeStore()

        let onX = store.enabledParameters(forHost: "x.com")
        let onYouTube = store.enabledParameters(forHost: "www.youtube.com")
        let elsewhere = store.enabledParameters(forHost: "example.com")

        #expect(onX.contains("t") && onX.contains("s"))
        #expect(!onX.contains("si"))
        #expect(onYouTube.contains("si") && onYouTube.contains("feature"))
        #expect(!onYouTube.contains("t"))
        #expect(!elsewhere.contains("t") && !elsewhere.contains("si"))
        for set in [onX, onYouTube, elsewhere] {
            #expect(set.contains("utm_source"))
        }
    }

    @Test func customParameterAppliesOnEveryHost() {
        // The leftover-pill path: adding `t` as a custom parameter is the
        // explicit "strip this everywhere", YouTube included.
        let store = makeStore()
        store.addCustomParameter("t")

        #expect(store.enabledParameters(forHost: "youtube.com").contains("t"))
        #expect(store.enabledParameters(forHost: nil).contains("t"))
    }

    @Test func deletingACustomParameterKeepsTheCatalogToggleDisabled() {
        // The toggle and the custom entry are independent choices: disabling
        // the scoped `t` rule, adding custom `t`, then deleting the custom
        // entry must leave the rule disabled — not silently restore it.
        let store = makeStore()
        store.setEnabled("t", isEnabled: false)
        store.addCustomParameter("t")
        store.removeCustomParameter("t")

        #expect(store.isEnabled("t") == false)
        #expect(!store.enabledParameters(forHost: "x.com").contains("t"))
    }

    @Test func normalizeHostStripsCaseAndTrailingDot() {
        #expect(TrackingParameterStore.normalize(host: "YouTube.com.") == "youtube.com")
        #expect(TrackingParameterStore.normalize(host: "") == nil)
        #expect(TrackingParameterStore.normalize(host: nil) == nil)
    }

    @Test func ruleHostParsesAndNormalizes() {
        #expect(URLCleaner.ruleHost(of: "https://WWW.YouTube.com./watch?v=x") == "www.youtube.com")
        #expect(URLCleaner.ruleHost(of: "not a url") == nil)
        #expect(URLCleaner.ruleHost(of: URL(string: "https://x.com/a")!) == "x.com")
    }
}
