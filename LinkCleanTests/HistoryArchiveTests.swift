//
//  HistoryArchiveTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
@testable import LinkClean
import LinkCleanCore
import LinkCleanData

@MainActor
struct HistoryArchiveTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func entry(daysAgo: Double, output: String = "https://example.com/page", title: String? = nil) -> HistoryEntry {
        HistoryEntry(
            input: output,
            output: output,
            createdAt: now.addingTimeInterval(-daysAgo * 86_400),
            pageTitle: title
        )
    }

    private func makeVM() -> HistoryViewModel {
        HistoryViewModel(analytics: SpyAnalytics())
    }

    @Test func proSeesEverythingNoArchive() {
        let entries = [entry(daysAgo: 1), entry(daysAgo: 30)]
        let archive = makeVM().archive(from: entries, isPro: true, now: now)
        #expect(archive.visible.count == 2)
        #expect(archive.olderCount == 0)
        #expect(archive.teaser.isEmpty)
    }

    @Test func freeSplitsAtSevenDays() {
        let entries = [
            entry(daysAgo: 1),
            entry(daysAgo: 5),
            entry(daysAgo: 9),
            entry(daysAgo: 40),
        ]
        let archive = makeVM().archive(from: entries, isPro: false, now: now)
        #expect(archive.visible.count == 2)   // within 7 days: 1, 5
        #expect(archive.olderCount == 2)      // older: 9, 40
        #expect(archive.teaser.count == 2)
    }

    @Test func teaserCapsAtThree() {
        let entries = (0..<5).map { entry(daysAgo: Double(15 + $0)) }
        let archive = makeVM().archive(from: entries, isPro: false, now: now)
        #expect(archive.olderCount == 5)
        #expect(archive.teaser.count == 3)
    }

    @Test func freeWithNothingAgedOutHasNoArchive() {
        let entries = [entry(daysAgo: 1), entry(daysAgo: 5)]
        let archive = makeVM().archive(from: entries, isPro: false, now: now)
        #expect(archive.visible.count == 2)
        #expect(archive.olderCount == 0)
    }

    @Test func searchCountsOlderMatchesSeparately() {
        let vm = makeVM()
        let entries = [
            entry(daysAgo: 1, output: "https://within.com/keepme"),
            entry(daysAgo: 20, output: "https://old.com/keepme"),
            entry(daysAgo: 25, output: "https://old.com/other"),
        ]
        vm.searchText = "keepme"
        let archive = vm.archive(from: entries, isPro: false, now: now)
        #expect(archive.visible.count == 1)
        #expect(archive.olderMatchCount == 1)
        #expect(archive.olderCount == 2)
    }
}
