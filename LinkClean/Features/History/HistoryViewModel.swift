//
//  HistoryViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import LinkCleanCommon
import Observation
import SwiftData
import UIKit

@MainActor
@Observable
final class HistoryViewModel {
    var searchText = ""
    var copiedEntryID: UUID?
    var fetchingEntryIDs: Set<UUID> = []
    @ObservationIgnored private var copyTask: Task<Void, Never>?
    @ObservationIgnored private var fetchTasks: [UUID: Task<Void, Never>] = [:]
    @ObservationIgnored private var modelContext: ModelContext?
    @ObservationIgnored private let metadataService: LinkMetadataService
    private let maxConcurrentFetches = 3

    private(set) var isSaveHistoryEnabled: Bool

    init(metadataService: LinkMetadataService = DefaultLinkMetadataService()) {
        self.metadataService = metadataService
        self.isSaveHistoryEnabled = UserDefaults(suiteName: AppGroup.identifier)?
            .object(forKey: SettingsKeys.saveHistoryEnabled) as? Bool ?? true
    }

    enum ViewState {
        case disabled
        case empty
        case populated
    }

    func refreshSettings() {
        isSaveHistoryEnabled = UserDefaults(suiteName: AppGroup.identifier)?
            .object(forKey: SettingsKeys.saveHistoryEnabled) as? Bool ?? true
    }

    func filteredEntries(from entries: [HistoryEntry]) -> [HistoryEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter { entry in
            (entry.pageTitle?.localizedStandardContains(searchText) ?? false)
                || entry.output.localizedStandardContains(searchText)
        }
    }

    func viewState(hasEntries: Bool) -> ViewState {
        if !isSaveHistoryEnabled { return .disabled }
        if !hasEntries { return .empty }
        return .populated
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func copyURL(for entry: HistoryEntry) {
        UIPasteboard.general.string = entry.output
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
        modelContext?.delete(entry)
    }

    func fetchMetadataIfNeeded(for entry: HistoryEntry) {
        guard !entry.metadataFetchAttempted,
              !fetchingEntryIDs.contains(entry.id),
              fetchingEntryIDs.count < maxConcurrentFetches else { return }

        fetchingEntryIDs.insert(entry.id)
        let entryID = entry.id

        guard let url = URL(string: entry.output) else {
            entry.metadataFetchAttempted = true
            fetchingEntryIDs.remove(entryID)
            return
        }

        fetchTasks[entryID] = Task {
            let metadata = await metadataService.fetchMetadata(for: url)
            entry.pageTitle = metadata.title
            entry.thumbnailData = metadata.thumbnailData
            entry.metadataFetchAttempted = true
            fetchingEntryIDs.remove(entryID)
            fetchTasks.removeValue(forKey: entryID)
        }
    }

    func retryMetadataFetch(for entry: HistoryEntry) {
        entry.metadataFetchAttempted = false
        entry.pageTitle = nil
        entry.thumbnailData = nil
        fetchMetadataIfNeeded(for: entry)
    }

    func cancelTasks() {
        copyTask?.cancel()
        for task in fetchTasks.values {
            task.cancel()
        }
        fetchTasks.removeAll()
    }
}
