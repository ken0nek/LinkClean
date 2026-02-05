//
//  HistoryView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import LinkCleanCommon
import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \HistoryEntry.createdAt, order: .reverse) private var entries: [HistoryEntry]
    @State private var viewModel = HistoryViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No History",
                    systemImage: "clock",
                    description: Text("Cleaned URLs you copy will appear here.")
                )
            } else {
                List(entries) { entry in
                    HistoryCellView(entry: entry, viewModel: viewModel, modelContext: modelContext)
                }
                .contentMargins(.top, 16)
            }
        }
        .screenBackground()
        .navigationTitle("History")
        .onDisappear {
            viewModel.cancelTasks()
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .modelContainer(HistoryContainer.makeInMemory())
    }
}
