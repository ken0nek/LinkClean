//
//  RealizedCleanRecorderTests.swift
//  LinkCleanDataTests
//

import Testing
import Foundation
import LinkCleanCore
import LinkCleanTestSupport
@testable import LinkCleanData

@MainActor
struct RealizedCleanRecorderTests {
    @Test func recordFansOutReferenceSignalsThenBumpsStats() {
        let spy = SpyAnalytics()
        let suite = "test.recorder.\(UUID().uuidString)"
        let stats = StatsStore(suiteName: suite)
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }

        let outcome = CleanOutcome(
            input: "https://x.com/?epik=1&li_fat_id=2",
            cleaned: "https://x.com/",
            telemetry: .init(
                changed: true, removedCount: 2, leftoverCount: 2,
                removedKindIDs: [], referenceMatches: ["epik", "li_fat_id"],
                domain: "x.com", wrappers: []
            ),
            display: .init(removedNames: ["epik", "li_fat_id"], leftoverNames: [])
        )

        RealizedCleanRecorder(analytics: spy, stats: stats).record(outcome)

        // The tail fans out one reference signal per catalog-gap match — and ONLY
        // those: the surface-specific success event stays the caller's job.
        #expect(spy.events == [
            .parametersReferenceObserved(parameter: "epik"),
            .parametersReferenceObserved(parameter: "li_fat_id"),
        ])
        #expect(stats.current().totalCleans == 1)
    }
}
