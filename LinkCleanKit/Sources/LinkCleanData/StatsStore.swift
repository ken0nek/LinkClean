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

    /// Folds one clean's outcome into the lifetime totals. Called once per
    /// *distinct* clean at each surface's success point — never per keystroke:
    /// Home hooks the deduped `Home.URL.cleaned` site, the extensions hook
    /// `ActionPipeline.run`, and the intents hook after their success signal.
    public func record(_ outcome: CleanOutcome) {
        var stats = current()
        stats.totalCleans += 1
        stats.totalParametersRemoved += outcome.telemetry.removedCount
        // Record by *parameter name*, not by category, so the by-category
        // breakdown is derived from the *current* catalog at display time
        // (`StatsViewModel`) — re-categorizing a parameter then re-buckets its
        // entire history, no migration. Only catalog names are stored (a finite,
        // public set); custom / one-time removals still count toward the totals,
        // but their (possibly user-authored) names are never kept.
        for name in outcome.display.removedNames {
            let key = name.lowercased()
            guard TrackingParameterCatalog.allNames.contains(key) else { continue }
            stats.removalsByParameter[key, default: 0] += 1
        }
        let domain = outcome.telemetry.domain
        if domain != "unknown", !domain.isEmpty {
            stats.cleansByHost[domain, default: 0] += 1
        }
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults?.set(data, forKey: SettingsKeys.lifetimeStats)
    }
}

/// Lifetime cleaning aggregates (see ``StatsStore``). Counts and sums only, stored
/// on-device in the App Group and never sent — the host and the catalog parameter
/// names are public (a finite, known set, the same privacy class as the clean
/// telemetry, `analytics.md` §3). Custom / one-time removals are counted in the
/// totals but their names are never stored; no paths or full URLs are kept.
public nonisolated struct Stats: Codable, Sendable, Equatable {
    /// Distinct cleans performed across all surfaces.
    public var totalCleans: Int
    /// Sum of tracking parameters removed.
    public var totalParametersRemoved: Int
    /// How many cleans each catalog parameter was removed in, by lowercased name
    /// (`utm_source`, `fbclid`, …). The by-category breakdown is derived from the
    /// *current* catalog at display time (``TrackingParameterCatalog/kindID(for:)``),
    /// so re-categorizing a parameter re-buckets its whole history retroactively.
    public var removalsByParameter: [String: Int]
    /// Cleans per site host (`youtube.com` → n) for the "top sites" view.
    public var cleansByHost: [String: Int]

    public init(
        totalCleans: Int = 0,
        totalParametersRemoved: Int = 0,
        removalsByParameter: [String: Int] = [:],
        cleansByHost: [String: Int] = [:]
    ) {
        self.totalCleans = totalCleans
        self.totalParametersRemoved = totalParametersRemoved
        self.removalsByParameter = removalsByParameter
        self.cleansByHost = cleansByHost
    }
}
