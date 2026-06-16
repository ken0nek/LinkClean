//
//  RealizedCleanRecorder.swift
//  LinkCleanData
//

import LinkCleanCore

/// The shared tail every in-app clean runs *after* its surface-specific success
/// signal: fan out the Tier-1 catalog-gap reference signals, then bump the
/// lifetime ``StatsStore`` aggregates. One ordered place so each surface (Home,
/// QR, and the next) doesn't re-derive it.
///
/// History is deliberately *not* here: the surfaces persist at different moments —
/// Home on export (deduped per output), QR at scan time, the extension / App
/// Intents through their own short-lived static `HistoryRecorder` path — so each
/// owns its own write. What they genuinely share is "emit the catalog-gap signals
/// and count the clean," which is this.
public struct RealizedCleanRecorder {
    private let analytics: AnalyticsService
    private let stats: StatsStore

    public init(analytics: AnalyticsService, stats: StatsStore) {
        self.analytics = analytics
        self.stats = stats
    }

    /// Fan out the reference-observed signals (catalog-gap Tier 1), then record the
    /// clean into lifetime Stats. Call once per realized clean, after the surface's
    /// own success event.
    public func record(_ outcome: CleanOutcome) {
        for event in outcome.telemetry.referenceObservedEvents {
            analytics.capture(event)
        }
        stats.record(outcome)
    }
}
