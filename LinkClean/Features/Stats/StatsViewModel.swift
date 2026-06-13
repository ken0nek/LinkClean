//
//  StatsViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/12/26.
//

import Foundation
import Observation
import LinkCleanCore
import LinkCleanData

/// Reads the lifetime cleaning aggregates (`StatsStore`) for the Statistics
/// dashboard (growth-roadmap §5 V2). The counters accrued silently since 1.1
/// across every clean surface — the app, both action extensions, and the App
/// Intents — so this screen has real depth the day it ships.
///
/// `@Observable` doesn't track external `UserDefaults`, and the App Group blob is
/// written by other processes (the extensions, the intents) while this screen may
/// be open, so the snapshot is re-read on `onAppear` — the same lifecycle-boundary
/// refresh `SettingsViewModel` uses for its App Group settings.
@MainActor
@Observable
final class StatsViewModel {
    private(set) var totalCleans = 0
    private(set) var totalParametersRemoved = 0
    /// Catalog kinds that appeared in a clean, most-removed first.
    private(set) var categories: [CategoryCount] = []
    /// The most-cleaned hosts, most first, capped at ``topSiteLimit``.
    private(set) var topSites: [SiteCount] = []

    @ObservationIgnored private let stats: StatsStore

    /// Whether anything has been cleaned yet — drives the empty state.
    var hasData: Bool { totalCleans > 0 }
    /// The largest category count, for scaling the by-category bars.
    var maxCategoryCount: Int { categories.map(\.count).max() ?? 0 }

    init(stats: StatsStore = StatsStore()) {
        self.stats = stats
        refresh()
    }

    func onAppear() {
        refresh()
    }

    private func refresh() {
        let snapshot = stats.current()
        totalCleans = snapshot.totalCleans
        totalParametersRemoved = snapshot.totalParametersRemoved
        // Derive the by-category breakdown from the *current* catalog: the store
        // keeps parameter-level counts, so a later re-categorization re-buckets all
        // history here, with no migration.
        var byKind: [String: Int] = [:]
        for (name, count) in snapshot.removalsByParameter {
            guard let kind = TrackingParameterCatalog.kindID(for: name) else { continue }
            byKind[kind, default: 0] += count
        }
        // Sort by count, with an id tiebreaker so equal counts keep a stable order
        // between reads (dictionary iteration order is nondeterministic).
        categories = byKind
            .map { CategoryCount(id: $0.key, count: $0.value) }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.id < $1.id }
        topSites = Array(
            snapshot.cleansByHost
                .map { SiteCount(host: $0.key, count: $0.value) }
                .sorted { $0.count != $1.count ? $0.count > $1.count : $0.host < $1.host }
                .prefix(Self.topSiteLimit)
        )
    }

    private static let topSiteLimit = 5

    struct CategoryCount: Identifiable, Equatable {
        /// The catalog kind id (`"utm"`, `"ads"`, …); mapped to a localized title
        /// in the view via `parameterKindTitle(_:)`.
        let id: String
        let count: Int
    }

    struct SiteCount: Identifiable, Equatable {
        let host: String
        let count: Int
        var id: String { host }
    }

    #if DEBUG
    /// Preview/test seed that bypasses the store with display-ready values.
    init(
        totalCleans: Int,
        totalParametersRemoved: Int,
        categories: [CategoryCount],
        topSites: [SiteCount]
    ) {
        self.stats = StatsStore()
        self.totalCleans = totalCleans
        self.totalParametersRemoved = totalParametersRemoved
        self.categories = categories
        self.topSites = topSites
    }
    #endif
}
