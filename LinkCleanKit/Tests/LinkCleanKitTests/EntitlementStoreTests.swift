//
//  EntitlementStoreTests.swift
//  LinkCleanKit
//
//  Created by Gemini CLI on 6/9/26.
//

import Testing
import Foundation
@testable import LinkCleanCore
@testable import LinkCleanData

@Suite struct EntitlementStoreTests {
    private let suiteName = "test.LinkCleanKit.EntitlementStore"

    init() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    @Test func testDefaultsToFree() {
        let store = EntitlementStore(suiteName: suiteName)
        #expect(store.current() == .free)
    }

    @Test func testRoundTrip() {
        let store = EntitlementStore(suiteName: suiteName)
        store.save(.pro)
        #expect(store.current() == .pro)

        store.save(.free)
        #expect(store.current() == .free)
    }

    @Test func testFailsClosedOnGarbage() {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set("not_a_valid_entitlement", forKey: SettingsKeys.currentEntitlement)

        let store = EntitlementStore(suiteName: suiteName)
        #expect(store.current() == .free)
    }
}
