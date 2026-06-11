//
//  TrackingParameterStoreResetTests.swift
//  LinkCleanKitTests
//

import Testing
import Foundation
@testable import LinkCleanData

struct TrackingParameterStoreResetTests {

    private func makeStore() -> (store: TrackingParameterStore, suiteName: String) {
        let suiteName = "test.\(UUID().uuidString)"
        return (TrackingParameterStore(suiteName: suiteName), suiteName)
    }

    private func removeSuite(_ suiteName: String) {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    @Test func resetClearsDisabledSet() {
        let (store, suiteName) = makeStore()
        defer { removeSuite(suiteName) }
        store.setEnabled("utm_source", isEnabled: false)
        #expect(store.isEnabled("utm_source") == false)

        store.resetDefaultParameterOverrides()

        #expect(store.isEnabled("utm_source") == true)
        #expect(store.disabledParameterNames().isEmpty)
    }

    @Test func resetClearsOffByDefaultOptIns() {
        // `title` ships disabled; an opt-in is an override that reset undoes.
        let (store, suiteName) = makeStore()
        defer { removeSuite(suiteName) }
        store.setEnabled("title", isEnabled: true)
        #expect(store.isEnabled("title") == true)

        store.resetDefaultParameterOverrides()

        #expect(store.isEnabled("title") == false)
    }

    @Test func removeAllCustomClearsCustomParameters() {
        let (store, suiteName) = makeStore()
        defer { removeSuite(suiteName) }
        store.addCustomParameter("mycustomparam")
        #expect(store.customParameters().contains("mycustomparam"))

        store.removeAllCustomParameters()

        #expect(store.customParameters().isEmpty)
    }

    @Test func disabledParameterNamesReflectState() {
        let (store, suiteName) = makeStore()
        defer { removeSuite(suiteName) }
        #expect(store.disabledParameterNames().isEmpty)

        store.setEnabled("fbclid", isEnabled: false)

        #expect(store.disabledParameterNames() == ["fbclid"])
    }
}
