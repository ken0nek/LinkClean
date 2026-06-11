//
//  HistoryStore.swift
//  LinkCleanData
//
//  Created by Ken Tominaga on 6/11/26.
//

import Foundation
import OSLog
import SwiftData
import LinkCleanCore

/// The single front door to History writes and enrichment. Constructed once with
/// the app's `ModelContainer` (composition root) and injected into ViewModels —
/// replacing the fragile optional-`ModelContext` dance (a forgotten `.task` used
/// to drop history silently rather than error). Reads stay `@Query` in the view;
/// this owns the *write* side and the metadata fetch pool.
///
/// One save semantics everywhere: explicit `save()`, failures logged (not the
/// silent `try?` Settings used). It writes through `container.mainContext`, the
/// same context `@Query` observes, so records/deletes reflect immediately.
@MainActor
@Observable
public final class HistoryStore {
    /// Entries currently being enriched — drives the per-row spinner. Observed.
    public private(set) var enrichingIDs: Set<UUID> = []

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let metadata: LinkMetadataService
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private var enrichTasks: [UUID: Task<Void, Never>] = [:]
    @ObservationIgnored private let maxConcurrentFetches = 3

    public init(container: ModelContainer, metadata: LinkMetadataService, settings: SettingsStore) {
        self.context = container.mainContext
        self.metadata = metadata
        self.settings = settings
    }

    // MARK: - Writes

    /// Writes a history row for `outcome` when history saving is enabled.
    public func record(_ outcome: CleanOutcome) {
        guard settings.saveHistoryEnabled else { return }
        context.insert(HistoryEntry(input: outcome.input, output: outcome.cleaned))
        save("record")
    }

    public func delete(_ entry: HistoryEntry) {
        // Production deletes come from `@Query` rows (in this context). Guard
        // against an unmanaged entry (e.g. a test stub) so we never call
        // `context.delete` on an object that isn't in a context.
        guard entry.modelContext != nil else { return }
        context.delete(entry)
        save("delete")
    }

    public func clearAll() {
        do {
            try context.delete(model: HistoryEntry.self)
            try context.save()
        } catch {
            Log.app.error("History clearAll failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func save(_ operation: String) {
        do {
            try context.save()
        } catch {
            Log.app.error("History \(operation, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Metadata enrichment (fetch pool, cap 3)

    /// Fetches title + thumbnail for `entry` if it hasn't been attempted, isn't
    /// already in flight, and we're under the concurrency cap. Owns the pool the
    /// History screen used to hand-roll inside its ViewModel.
    public func enrich(_ entry: HistoryEntry) {
        guard !entry.metadataFetchAttempted,
              !enrichingIDs.contains(entry.id),
              enrichingIDs.count < maxConcurrentFetches else { return }

        enrichingIDs.insert(entry.id)
        let id = entry.id

        guard let url = URL(string: entry.output) else {
            entry.metadataFetchAttempted = true
            enrichingIDs.remove(id)
            save("enrich")
            return
        }

        enrichTasks[id] = Task { [metadata] in
            let result = await metadata.fetchMetadata(for: url)
            entry.pageTitle = result.title
            entry.thumbnailData = result.thumbnailData
            entry.metadataFetchAttempted = true
            enrichingIDs.remove(id)
            enrichTasks.removeValue(forKey: id)
            save("enrich")
        }
    }

    public func retryEnrich(_ entry: HistoryEntry) {
        entry.metadataFetchAttempted = false
        entry.pageTitle = nil
        entry.thumbnailData = nil
        enrich(entry)
    }

    public func cancelEnrichment() {
        for task in enrichTasks.values {
            task.cancel()
        }
        enrichTasks.removeAll()
    }
}
