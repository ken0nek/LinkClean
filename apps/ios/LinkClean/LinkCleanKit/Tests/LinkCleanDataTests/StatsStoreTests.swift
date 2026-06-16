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

    /// An outcome that removed `removedNames` (used as both the display names the
    /// store buckets by parameter and the telemetry count) on `domain`.
    private func outcome(removedNames: [String], domain: String = "example.com") -> CleanOutcome {
        CleanOutcome(
            input: "https://\(domain)/x",
            cleaned: "https://\(domain)/",
            telemetry: .init(
                changed: !removedNames.isEmpty,
                removedCount: removedNames.count,
                leftoverCount: 0,
                removedKindIDs: [],
                referenceMatches: [],
                domain: domain
            ),
            display: .init(removedNames: removedNames, leftoverNames: [])
        )
    }

    @Test func startsZeroed() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        #expect(store.current() == Stats())
    }

    @Test func accumulatesByParameterAcrossCleans() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        store.record(outcome(removedNames: ["utm_source", "utm_medium", "fbclid"], domain: "youtube.com"))
        store.record(outcome(removedNames: ["utm_source", "utm_campaign"], domain: "youtube.com"))

        let stats = store.current()
        #expect(stats.totalCleans == 2)
        #expect(stats.totalParametersRemoved == 5)
        // Counts are kept per *parameter name* — the category breakdown is derived
        // later from the current catalog, never frozen here.
        #expect(stats.removalsByParameter == [
            "utm_source": 2, "utm_medium": 1, "utm_campaign": 1, "fbclid": 1
        ])
        #expect(stats.cleansByHost == ["youtube.com": 2])
    }

    @Test func storesOnlyCatalogNamesNotCustomOrArbitrary() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        // A custom / arbitrary removed name counts toward the totals but its
        // (possibly user-authored) name is never stored.
        store.record(outcome(removedNames: ["utm_source", "my_private_param"], domain: "example.com"))

        let stats = store.current()
        #expect(stats.totalCleans == 1)
        #expect(stats.totalParametersRemoved == 2)
        #expect(stats.removalsByParameter == ["utm_source": 1]) // my_private_param not kept
    }

    @Test func countsAnUnchangedCleanButAddsNoRemovals() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        store.record(outcome(removedNames: [], domain: "example.com"))
        let stats = store.current()
        #expect(stats.totalCleans == 1)
        #expect(stats.totalParametersRemoved == 0)
        #expect(stats.removalsByParameter.isEmpty)
        #expect(stats.cleansByHost == ["example.com": 1])
    }

    @Test func skipsUnknownHost() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        store.record(outcome(removedNames: ["utm_source"], domain: "unknown"))
        #expect(store.current().totalCleans == 1)
        #expect(store.current().cleansByHost.isEmpty)
    }
}
