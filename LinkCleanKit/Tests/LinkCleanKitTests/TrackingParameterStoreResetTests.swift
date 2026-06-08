//
//  TrackingParameterStoreResetTests.swift
//  LinkCleanKitTests
//

import Testing
import Foundation
@testable import LinkCleanKit

struct TrackingParameterStoreResetTests {

    private func makeStore() -> TrackingParameterStore {
        TrackingParameterStore(suiteName: "test.\(UUID().uuidString)")
    }

    @Test func reenableAllClearsDisabledSet() {
        let store = makeStore()
        store.setEnabled("utm_source", isEnabled: false)
        #expect(store.isEnabled("utm_source") == false)

        store.reenableAllDefaultParameters()

        #expect(store.isEnabled("utm_source") == true)
        #expect(store.disabledParameterNames().isEmpty)
    }

    @Test func removeAllCustomClearsCustomParameters() {
        let store = makeStore()
        store.addCustomParameter("mycustomparam")
        #expect(store.customParameters().contains("mycustomparam"))

        store.removeAllCustomParameters()

        #expect(store.customParameters().isEmpty)
    }

    @Test func disabledParameterNamesReflectState() {
        let store = makeStore()
        #expect(store.disabledParameterNames().isEmpty)

        store.setEnabled("fbclid", isEnabled: false)

        #expect(store.disabledParameterNames() == ["fbclid"])
    }
}
