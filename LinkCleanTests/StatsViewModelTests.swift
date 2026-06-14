//
//  StatsViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
@testable import LinkClean
import LinkCleanCore
import LinkCleanData

@MainActor
struct StatsViewModelTests {
    /// A stats store over a throwaway suite, plus its name for teardown (mirrors
    /// `StatsStoreTests`).
    private func makeStore() -> (store: StatsStore, suite: String) {
        let suite = "test.statsvm.\(UUID().uuidString)"
        return (StatsStore(suiteName: suite), suite)
    }

    /// An outcome that removed `removedNames` on `domain` (the names drive both the
    /// store's per-parameter buckets and the telemetry count).
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

    @Test func emptyStoreHasNoData() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        let viewModel = StatsViewModel(stats: store)

        #expect(viewModel.hasData == false)
        #expect(viewModel.totalCleans == 0)
        #expect(viewModel.totalParametersRemoved == 0)
        #expect(viewModel.categories.isEmpty)
        #expect(viewModel.topSites.isEmpty)
        #expect(viewModel.maxCategoryCount == 0)
    }

    @Test func aggregatesAndRanksByCount() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        store.record(outcome(removedNames: ["utm_source", "fbclid"], domain: "youtube.com"))
        store.record(outcome(removedNames: ["utm_source"], domain: "x.com"))
        store.record(outcome(removedNames: ["utm_source"], domain: "youtube.com"))

        let viewModel = StatsViewModel(stats: store)

        #expect(viewModel.hasData)
        #expect(viewModel.totalCleans == 3)
        #expect(viewModel.totalParametersRemoved == 4)
        // utm_source removed 3× (→ utm), fbclid 1× (→ ads) — categories derived
        // from the current catalog, most-first.
        #expect(viewModel.categories.map(\.id) == ["utm", "ads"])
        #expect(viewModel.categories.map(\.count) == [3, 1])
        #expect(viewModel.maxCategoryCount == 3)
        // youtube.com cleaned twice, x.com once — most-first.
        #expect(viewModel.topSites.map(\.host) == ["youtube.com", "x.com"])
        #expect(viewModel.topSites.map(\.count) == [2, 1])
    }

    @Test func topSitesCapAtFiveMostCleaned() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        // Seven hosts, each cleaned a distinct number of times (a.com once … g.com
        // seven times), so the ranking is unambiguous.
        let hosts = ["a.com", "b.com", "c.com", "d.com", "e.com", "f.com", "g.com"]
        for (index, host) in hosts.enumerated() {
            for _ in 0...index {
                store.record(outcome(removedNames: ["utm_source"], domain: host))
            }
        }

        let viewModel = StatsViewModel(stats: store)

        // Only the five most-cleaned hosts survive, most-first.
        #expect(viewModel.topSites.count == 5)
        #expect(viewModel.topSites.map(\.host) == ["g.com", "f.com", "e.com", "d.com", "c.com"])
    }

    @Test func shareCardIsNilUntilThereIsData() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        let viewModel = StatsViewModel(stats: store)

        // No share affordance with nothing to show (growth-roadmap §5 V3).
        #expect(viewModel.shareCard == nil)
    }

    @Test func shareCardCarriesTotalsAndTopThreeCategories() throws {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        // Four distinct categories at descending frequencies (utm 4 › ads 3 ›
        // analytics 2 › social 1), each clean removing one parameter.
        for _ in 0..<4 { store.record(outcome(removedNames: ["utm_source"])) }
        for _ in 0..<3 { store.record(outcome(removedNames: ["fbclid"])) }
        for _ in 0..<2 { store.record(outcome(removedNames: ["_ga"])) }
        store.record(outcome(removedNames: ["igshid"]))

        let viewModel = StatsViewModel(stats: store)
        let card = try #require(viewModel.shareCard)

        #expect(card.parametersRemoved == viewModel.totalParametersRemoved)
        #expect(card.parametersRemoved == 10)
        #expect(card.cleans == viewModel.totalCleans)
        #expect(card.cleans == 10)
        // Every category counts toward the total, but only the top three ride the
        // card — and in the same ranking the dashboard shows, just truncated.
        #expect(card.categoryCount == 4)
        #expect(card.topCategories.count == 3)
        #expect(card.topCategories.map(\.id) == ["utm", "ads", "analytics"])
        #expect(card.topCategories.map(\.count) == [4, 3, 2])
        #expect(card.topCategories.map(\.id) == Array(viewModel.categories.prefix(3).map(\.id)))
        // The one category beyond the top-3 cap (social, count 1) folds into the
        // bar's "other" segment rather than vanishing.
        #expect(card.otherCount == 1)
    }

    @Test func onAppearPicksUpLaterCleans() {
        let (store, suite) = makeStore()
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }

        let viewModel = StatsViewModel(stats: store)
        #expect(viewModel.totalCleans == 0)

        // Another surface (an extension / App Intent) records into the same App
        // Group suite while the screen is alive; onAppear re-reads it.
        store.record(outcome(removedNames: ["utm_source", "utm_medium", "utm_campaign", "utm_term"], domain: "youtube.com"))
        viewModel.onAppear()

        #expect(viewModel.totalCleans == 1)
        #expect(viewModel.totalParametersRemoved == 4)
        #expect(viewModel.topSites.map(\.host) == ["youtube.com"])
    }
}
