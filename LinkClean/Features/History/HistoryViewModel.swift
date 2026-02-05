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

    func deleteEntry(_ entry: HistoryEntry, from context: ModelContext) {
        context.delete(entry)
    }

    func cancelTasks() {
        copyTask?.cancel()
    }
}
