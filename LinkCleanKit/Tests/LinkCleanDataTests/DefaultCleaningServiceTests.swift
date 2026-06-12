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
    }
}
