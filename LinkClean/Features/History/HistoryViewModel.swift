//
//  HistoryViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import LinkCleanCore
import LinkCleanAnalytics
import LinkCleanData
import Observation
import SwiftData
import UIKit

@MainActor
@Observable
final class HistoryViewModel {
    var searchText = "" {
        didSet { handleSearchTextChange() }
    }
    var copiedEntryID: UUID?
    @ObservationIgnored private var copyTask: Task<Void, Never>?
    @ObservationIgnored private let history: HistoryStore
    @ObservationIgnored private let analytics: AnalyticsService
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private var didSignalSearch = false

    private(set) var isSaveHistoryEnabled: Bool

    /// Entries currently being enriched — the ``HistoryStore`` owns the fetch
    /// pool now; the cell reads this for its spinner (observes the store).
    var fetchingEntryIDs: Set<UUID> { history.enrichingIDs }

    init(
        history: HistoryStore = .inMemoryPreview,
        analytics: AnalyticsService = TelemetryDeckAnalytics(),
        settings: SettingsStore = SettingsStore()
    ) {
        self.history = history
        self.analytics = analytics
        self.settings = settings
        self.isSaveHistoryEnabled = settings.saveHistoryEnabled
    }

    enum ViewState {
        case disabled
        case empty
        case populated
    }

    func refreshSettings() {
        isSaveHistoryEnabled = settings.saveHistoryEnabled
    }

    /// Called when the History tab appears. Refreshes settings, resets the
    /// per-visit search flag, and emits `History.Screen.shown`. `entryCount`
    /// comes from the View's `@Query`.
    func handleAppear(entryCount: Int) {
        didSignalSearch = false
        refreshSettings()
        analytics.capture(.historyScreenShown(entryCount: entryCount))
    }

    private func handleSearchTextChange() {
        guard !didSignalSearch, !searchText.isEmpty else { return }
        didSignalSearch = true
        analytics.capture(.historySearchUsed)
    }

    func filteredEntries(from entries: [HistoryEntry]) -> [HistoryEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter { entry in
            (entry.pageTitle?.localizedStandardContains(searchText) ?? false)
                || entry.output.localizedStandardContains(searchText)
        }
    }

    /// The History 7-day window gate (T1 / §9-A). Pro sees everything in
    /// `visible`; a free user sees only the last ``ProGate/freeHistoryWindowDays``
    /// days, with aged-out entries surfaced as counts (and a few blurred teasers)
    /// — never as interactive rows, and never deleted.
    struct Archive {
        /// Entries to render fully, already search-filtered.
        var visible: [HistoryEntry]
        /// Up to three most-recent aged-out entries, for the blurred teaser rows.
        var teaser: [HistoryEntry]
        /// Total aged-out entries (count only — the rows themselves stay hidden).
        var olderCount: Int
        /// Aged-out entries matching the active search (count only).
        var olderMatchCount: Int
    }

    func archive(from entries: [HistoryEntry], isPro: Bool, now: Date = .now) -> Archive {
        if isPro {
            return Archive(visible: filteredEntries(from: entries), teaser: [], olderCount: 0, olderMatchCount: 0)
        }
        let cutoff = now.addingTimeInterval(-Double(ProGate.freeHistoryWindowDays) * 86_400)
        var within: [HistoryEntry] = []
        var older: [HistoryEntry] = []
        for entry in entries {
            if entry.createdAt >= cutoff { within.append(entry) } else { older.append(entry) }
        }
        return Archive(
            visible: filteredEntries(from: within),
            teaser: Array(older.prefix(3)),
            olderCount: older.count,
            olderMatchCount: filteredEntries(from: older).count
        )
    }

    func viewState(hasEntries: Bool) -> ViewState {
        if !isSaveHistoryEnabled { return .disabled }
        if !hasEntries { return .empty }
        return .populated
    }

    func copyURL(for entry: HistoryEntry) {
        UIPasteboard.general.string = entry.output
        analytics.capture(.historyEntryActioned(.copy))
        showCopiedFeedback(for: entry)
    }

    func copyMarkdown(for entry: HistoryEntry) {
        UIPasteboard.general.string = MarkdownFormatter.markdownLink(title: entry.pageTitle, url: entry.output)
        analytics.capture(.historyEntryActioned(.markdown))
        showCopiedFeedback(for: entry)
    }

    /// Records a share *initiation*. `ShareLink` exposes no completion callback,
    /// so the View fires this from a simultaneous tap gesture when the share
    /// sheet is invoked — a tap-then-cancel still counts. `.share` is therefore
    /// initiation, asymmetric with `.copy`/`.markdown`, which fire on a
    /// completed action. Interpret share volume accordingly.
    func recordShared(for entry: HistoryEntry) {
        analytics.capture(.historyEntryActioned(.share))
    }

    /// Records an open-in-browser action and returns the URL to open. The View
    /// owns the `openURL` environment action, so it performs the actual open.
    func urlToOpen(for entry: HistoryEntry) -> URL? {
        analytics.capture(.historyEntryActioned(.openInBrowser))
        return URL(string: entry.output)
    }

    private func showCopiedFeedback(for entry: HistoryEntry) {
        copiedEntryID = entry.id

        copyTask?.cancel()
        copyTask = Task {
            try? await Task.sleep(for: .seconds(1.4))
            if !Task.isCancelled {
                copiedEntryID = nil
            }
        }
    }

    func deleteEntry(_ entry: HistoryEntry) {
        analytics.capture(.historyEntryDeleted)
        history.delete(entry)
    }

    /// Enrichment is delegated to the ``HistoryStore`` (it owns the fetch pool and
    /// the concurrency cap). The cell calls this from its `.task(id:)`.
    func fetchMetadataIfNeeded(for entry: HistoryEntry) {
        history.enrich(entry)
    }

    func retryMetadataFetch(for entry: HistoryEntry) {
        history.retryEnrich(entry)
    }

    func cancelTasks() {
        copyTask?.cancel()
        history.cancelEnrichment()
    }
}
