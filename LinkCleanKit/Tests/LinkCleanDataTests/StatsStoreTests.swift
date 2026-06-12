//
//  StatsStoreTests.swift
//  LinkCleanDataTests
//

import Testing
import Foundation
import LinkCleanCore
@testable import LinkCleanData

struct StatsStoreTests {
    /// A store over a throwaway UserDefaults suite, plus its name so the test can
    /// tear it down.
    private func makeStore() -> (store: StatsStore, suite: String) {
        let suite = "test.stats.\(UUID().uuidString)"
        return (StatsStore(suiteName: suite), suite)
    }

    private func telemetry(
        removedCount: Int = 0,
        removedKindIDs: Set<String> = [],
        domain: String = "example.com"
    ) -> CleanOutcome.Telemetry {
        .init(
            changed: removedCount > 0,
            removedCount: removedCount,
            leftoverCount: 0,
            removedKindIDs: removedKindIDs,
            referenceMatches: [],
            domain: domain
        )
    }

    @Test func startsZeroed() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        #expect(store.current() == Stats())
    }

    @Test func accumulatesAcrossCleans() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        store.record(telemetry(removedCount: 3, removedKindIDs: ["utm", "ads"], domain: "youtube.com"))
        store.record(telemetry(removedCount: 2, removedKindIDs: ["utm"], domain: "youtube.com"))

        let stats = store.current()
        #expect(stats.totalCleans == 2)
        #expect(stats.totalParametersRemoved == 5)
        #expect(stats.removalsByKind == ["utm": 2, "ads": 1])
        #expect(stats.cleansByHost == ["youtube.com": 2])
    }

    @Test func countsAnUnchangedCleanButAddsNoRemovals() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        store.record(telemetry(removedCount: 0, removedKindIDs: [], domain: "example.com"))
        let stats = store.current()
        #expect(stats.totalCleans == 1)
        #expect(stats.totalParametersRemoved == 0)
        #expect(stats.removalsByKind.isEmpty)
        #expect(stats.cleansByHost == ["example.com": 1])
    }

    @Test func skipsUnknownHost() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        store.record(telemetry(removedCount: 1, domain: "unknown"))
        #expect(store.current().totalCleans == 1)
        #expect(store.current().cleansByHost.isEmpty)
    }
}
