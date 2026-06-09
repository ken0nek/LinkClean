//
//  HistoryView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import LinkCleanKit
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
        @Bindable var viewModel = viewModel
        Group {
            switch viewModel.viewState(hasEntries: !entries.isEmpty) {
            case .disabled:
                ContentUnavailableView {
                    Label { Text(.historyDisabledTitle) } icon: { Image(systemName: "clock.badge.xmark") }
                } description: {
                    Text(.historyDisabledMessage)
                }
            case .empty:
                ContentUnavailableView {
                    Label { Text(.historyEmptyTitle) } icon: { Image(systemName: "clock") }
                } description: {
                    Text(.historyEmptyMessage)
                }
            case .populated:
                List(viewModel.filteredEntries(from: entries)) { entry in
                    HistoryCellView(entry: entry, viewModel: viewModel)
                        .listRowBackground(Color.clear)
                }
                .contentMargins(.top, 8)
                .searchable(text: $viewModel.searchText)
                .scrollDismissesKeyboard(.immediately)
                .overlay {
                    if viewModel.filteredEntries(from: entries).isEmpty && !viewModel.searchText.isEmpty {
                        ContentUnavailableView.search
                    }
                }
            }
        }
        .screenBackground()
        .navigationTitle(Text(.historyTitle))
        .task {
            viewModel.setModelContext(modelContext)
        }
        .onAppear {
            viewModel.handleAppear(entryCount: entries.count)
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
