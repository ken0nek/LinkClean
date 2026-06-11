//
//  TrackingParameterStoreTests.swift
//  LinkCleanDataTests
//
//  Created by Ken Tominaga on 2/2/26.
//

import Testing
import Foundation
@testable import LinkCleanData

struct TrackingParameterStoreTests {

    @Test func normalizesAndEnablesCustomParameters() {
        let suiteName = "LinkCleanKitTests.custom.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }

        let store = TrackingParameterStore(suiteName: suiteName)
        store.addCustomParameter("  UTM_Source  ")

        #expect(store.customParameters() == ["utm_source"])
        #expect(store.enabledParameters(forHost: nil).contains("utm_source"))
    }

    @Test func removesCustomParameters() {
        let suiteName = "LinkCleanKitTests.custom.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }

        let store = TrackingParameterStore(suiteName: suiteName)
        store.addCustomParameter("custom_param")
        store.removeCustomParameter("custom_param")

        #expect(store.customParameters().isEmpty)
        #expect(!store.enabledParameters(forHost: nil).contains("custom_param"))
    }
}
