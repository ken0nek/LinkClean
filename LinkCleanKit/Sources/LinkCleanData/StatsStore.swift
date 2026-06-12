//
//  StatsStore.swift
//  LinkCleanData
//
//  Created by Ken Tominaga on 6/12/26.
//

import Foundation
import LinkCleanCore

/// Lifetime cleaning aggregates, persisted in the App Group suite so they survive
/// History's rolling 7-day window and accrue across every clean surface — the
/// app, both action extensions, and the App Intents. Silent in 1.1 (no UI yet);
/// this is the data the 1.2 stats dashboard + shareable privacy card read, which
/// is why it has to start accruing a release early (growth-roadmap §5 V1).
///
/// `record` is a read-modify-write of one JSON blob, so concurrent writes from
/// different processes can lose an increment — acceptable for an approximate
/// aggregate (no exactness is promised), and the same best-effort posture the
/// rest of the App Group state takes.
public nonisolated struct StatsStore: Sendable {
    // Store the suite *name* (Sendable), not the `UserDefaults` instance (which is
    // not) — same as `SettingsStore`/`TrackingParameterStore`. `UserDefaults`
    // returns a cached shared instance per suite, so resolving it per access is cheap.
    private let suiteName: String?

    public init(suiteName: String? = AppGroup.identifier) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    /// The aggregates so far (a zeroed ``Stats`` when nothing has been recorded).
    public func current() -> Stats {
        guard let data = defaults?.data(forKey: SettingsKeys.lifetimeStats),
              let stats = try? JSONDecoder().decode(Stats.self, from: data)
        else {
            return Stats()
        }
        return stats
    }

    /// Folds one clean's analytics-safe telemetry into the lifetime totals. Called
    /// once per *distinct* clean at each surface's success point — never per
    /// keystroke: Home hooks the deduped `Home.URL.cleaned` site, the extensions
    /// hook `ActionPipeline.run`, and the intents hook after their success signal.
    public func record(_ telemetry: CleanOutcome.Telemetry) {
        var stats = current()
        stats.totalCleans += 1
        stats.totalParametersRemoved += telemetry.removedCount
        for kind in telemetry.removedKindIDs {
            stats.removalsByKind[kind, default: 0] += 1
        }
        if telemetry.domain != "unknown", !telemetry.domain.isEmpty {
            stats.cleansByHost[telemetry.domain, default: 0] += 1
        }
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults?.set(data, forKey: SettingsKeys.lifetimeStats)
    }
}

/// Lifetime cleaning aggregates (see ``StatsStore``). Counts and sums only — the
/// host and catalog-kind names are public, the same privacy class as the clean
/// telemetry they come from (`analytics.md` §3); no raw query keys, paths, or
/// full URLs.
public nonisolated struct Stats: Codable, Sendable, Equatable {
    /// Distinct cleans performed across all surfaces.
    public var totalCleans: Int
    /// Sum of tracking parameters removed.
    public var totalParametersRemoved: Int
    /// How many cleans each catalog kind appeared in, by kind id (`utm`, `ads`, …).
    public var removalsByKind: [String: Int]
    /// Cleans per site host (`youtube.com` → n) for the "top sites" view.
    public var cleansByHost: [String: Int]

    public init(
        totalCleans: Int = 0,
        totalParametersRemoved: Int = 0,
        removalsByKind: [String: Int] = [:],
        cleansByHost: [String: Int] = [:]
    ) {
        self.totalCleans = totalCleans
        self.totalParametersRemoved = totalParametersRemoved
        self.removalsByKind = removalsByKind
        self.cleansByHost = cleansByHost
    }
}
