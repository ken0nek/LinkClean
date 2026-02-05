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
    @State private var viewModel: HistoryViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: HistoryViewModel = HistoryViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.viewState(hasEntries: !entries.isEmpty) {
            case .disabled:
                ContentUnavailableView(
                    "History Disabled",
                    systemImage: "clock.badge.xmark",
                    description: Text("History is currently disabled. Enable history in Settings to save your cleaned URLs.")
                )
            case .empty:
                ContentUnavailableView(
                    "No History",
                    systemImage: "clock",
                    description: Text("Cleaned URLs you copy will appear here.")
                )
            case .populated:
                List(entries) { entry in
                    HistoryCellView(entry: entry, viewModel: viewModel)
                }
                .contentMargins(.top, 16)
            }
        }
        .screenBackground()
        .navigationTitle("History")
        .task {
            viewModel.setModelContext(modelContext)
        }
        .onAppear {
            viewModel.refreshSettings()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.refreshSettings()
            }
        }
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
