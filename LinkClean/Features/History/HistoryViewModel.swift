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
    var copiedEntryID: UUID?
    @ObservationIgnored private var copyTask: Task<Void, Never>?
    @ObservationIgnored private var modelContext: ModelContext?

    enum ViewState {
        case disabled
        case empty
        case populated
    }

    var isSaveHistoryEnabled: Bool {
        UserDefaults(suiteName: AppGroup.identifier)?
            .object(forKey: SettingsKeys.saveHistoryEnabled) as? Bool ?? true
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

    func cancelTasks() {
        copyTask?.cancel()
    }
}
