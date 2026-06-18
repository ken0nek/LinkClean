//
//  DefaultCleaningServiceTests.swift
//  LinkCleanDataTests
//
//  Created by Ken Tominaga on 6/12/26.
//

import Testing
import Foundation
@testable import LinkCleanCore
@testable import LinkCleanData

/// The seam where redirect unwrapping meets parameter rules: `clean` peels a
/// known wrapper, then resolves the removal set against the *destination's* host
/// from the store — not the wrapper's. Pure unwrap/catalog behavior is covered in
/// `RedirectUnwrappingTests`; these pin the wiring end-to-end through the service.
struct DefaultCleaningServiceTests {

    @Test func unwrapsAWrapperAndCleansTheRevealedTrackers() async throws {
        let suiteName = "LinkCleanKitTests.cleaning.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }
        let service = DefaultCleaningService(store: TrackingParameterStore(suiteName: suiteName))

        let wrapped = "https://www.google.com/url?q=https%3A%2F%2Fshop.example.com%2Fsneakers%3Futm_source%3Dnewsletter%26fbclid%3Dabc&sa=D"
        let outcome = try #require(await service.clean(wrapped))
        #expect(outcome.cleaned == "https://shop.example.com/sneakers")
        #expect(outcome.telemetry.wrappers == ["google.com"])
    }

    @Test func resolvesRemovalRulesForTheDestinationHostNotTheWrapper() async throws {
        let suiteName = "LinkCleanKitTests.cleaning.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }
        let service = DefaultCleaningService(store: TrackingParameterStore(suiteName: suiteName))

        // A YouTube destination behind a Google redirect: t= (timestamp) must
        // survive, si= (share token) must be stripped — only possible if the
        // removal set resolves against youtube.com, the unwrapped host.
        let wrapped = "https://www.google.com/url?q=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3Dx%26t%3D120s%26si%3DAbC"
        let outcome = try #require(await service.clean(wrapped))
        #expect(outcome.cleaned == "https://www.youtube.com/watch?v=x&t=120s")
    }

    @Test func leavesOrdinaryLinksUntouchedByUnwrapping() async throws {
        let suiteName = "LinkCleanKitTests.cleaning.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }
        let service = DefaultCleaningService(store: TrackingParameterStore(suiteName: suiteName))

        // No wrapper host: unwrap is a no-op, normal cleaning still applies.
        let outcome = try #require(await service.clean("https://example.com/article?utm_source=x&id=5"))
        #expect(outcome.cleaned == "https://example.com/article?id=5")
        #expect(outcome.telemetry.wrappers.isEmpty)
    }

    @Test func stripsTheScrollToTextDirectiveByDefault() async throws {
        let suiteName = "LinkCleanKitTests.cleaning.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }
        let service = DefaultCleaningService(
            store: TrackingParameterStore(suiteName: suiteName),
            settings: SettingsStore(appGroupSuiteName: suiteName)        // unset → default on
        )

        let outcome = try #require(await service.clean("https://example.com/page#:~:text=hello"))
        #expect(outcome.cleaned == "https://example.com/page")
    }

    @Test func preservesTheScrollToTextDirectiveWhenTheSettingIsOff() async throws {
        let suiteName = "LinkCleanKitTests.cleaning.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }
        let settings = SettingsStore(appGroupSuiteName: suiteName)
        settings.removeTextFragmentsEnabled = false
        let service = DefaultCleaningService(store: TrackingParameterStore(suiteName: suiteName), settings: settings)

        let outcome = try #require(await service.clean("https://example.com/page#:~:text=hello"))
        #expect(outcome.cleaned == "https://example.com/page#:~:text=hello")
    }

    // MARK: - Short-link expansion (E4)

    /// A short-link host with the toggle **off**: the resolver is wired but must
    /// never be consulted, and the original link is cleaned as-is.
    @Test func doesNotExpandWhenTheToggleIsOff() async throws {
        let suiteName = "LinkCleanKitTests.cleaning.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }
        let settings = SettingsStore(appGroupSuiteName: suiteName)        // unset → off
        let resolver = StubShortLinkResolver(destination: URL(string: "https://example.com/real?utm_source=x"))
        let service = DefaultCleaningService(
            store: TrackingParameterStore(suiteName: suiteName),
            settings: settings,
            resolver: resolver
        )

        let outcome = try #require(await service.clean("https://bit.ly/abc"))
        #expect(await resolver.resolveCallCount == 0)
        #expect(outcome.cleaned == "https://bit.ly/abc")
        #expect(!outcome.telemetry.expanded)   // no resolve fired → no expansion signal
    }

    /// Toggle on + a known shortener host: the resolver's destination is what gets
    /// cleaned (its trackers stripped), not the short link.
    @Test func expandsAShortLinkThenCleansTheDestination() async throws {
        let suiteName = "LinkCleanKitTests.cleaning.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }
        let settings = SettingsStore(appGroupSuiteName: suiteName)
        settings.expandShortLinksEnabled = true
        let resolver = StubShortLinkResolver(destination: URL(string: "https://example.com/article?utm_source=newsletter&id=5"))
        let service = DefaultCleaningService(
            store: TrackingParameterStore(suiteName: suiteName),
            settings: settings,
            resolver: resolver
        )

        let outcome = try #require(await service.clean("https://bit.ly/abc"))
        #expect(await resolver.resolveCallCount == 1)
        #expect(outcome.cleaned == "https://example.com/article?id=5")
        #expect(outcome.telemetry.expanded)   // a network resolve fired → the E4 signal
    }

    /// A failed resolve (`nil`) falls back to cleaning the original short link and
    /// never throws — expansion is additive, so it can't break a clean.
    @Test func fallsBackToTheOriginalWhenTheResolverReturnsNil() async throws {
        let suiteName = "LinkCleanKitTests.cleaning.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }
        let settings = SettingsStore(appGroupSuiteName: suiteName)
        settings.expandShortLinksEnabled = true
        let resolver = StubShortLinkResolver(destination: nil)
        let service = DefaultCleaningService(
            store: TrackingParameterStore(suiteName: suiteName),
            settings: settings,
            resolver: resolver
        )

        let outcome = try #require(await service.clean("https://bit.ly/abc?utm_source=x"))
        #expect(await resolver.resolveCallCount == 1)
        #expect(outcome.cleaned == "https://bit.ly/abc")
        #expect(!outcome.telemetry.expanded)   // resolve returned nil → not counted as expanded
    }

    /// Toggle on but the host is **not** a shortener: the resolver is left untouched
    /// (no needless network call) and the link cleans offline as usual.
    @Test func doesNotExpandANonShortenerHostEvenWhenEnabled() async throws {
        let suiteName = "LinkCleanKitTests.cleaning.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }
        let settings = SettingsStore(appGroupSuiteName: suiteName)
        settings.expandShortLinksEnabled = true
        let resolver = StubShortLinkResolver(destination: URL(string: "https://evil.example/phish"))
        let service = DefaultCleaningService(
            store: TrackingParameterStore(suiteName: suiteName),
            settings: settings,
            resolver: resolver
        )

        let outcome = try #require(await service.clean("https://example.com/page?utm_source=x"))
        #expect(await resolver.resolveCallCount == 0)
        #expect(outcome.cleaned == "https://example.com/page")
        #expect(!outcome.telemetry.expanded)   // non-shortener host → resolver untouched, no expansion
    }
}

/// A ``ShortLinkResolving`` double: returns a canned destination and records whether
/// it was consulted, so a test can assert expansion happens (or doesn't) with no
/// network. An `actor` so its call counter is race-free under Swift Testing's
/// parallelism.
private actor StubShortLinkResolver: ShortLinkResolving {
    let destination: URL?
    private(set) var resolveCallCount = 0

    init(destination: URL?) {
        self.destination = destination
    }

    func resolve(_ url: URL) async -> URL? {
        resolveCallCount += 1
        return destination
    }
}
