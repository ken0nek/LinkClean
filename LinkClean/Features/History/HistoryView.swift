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
    @Environment(EntitlementsModel.self) private var entitlements
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var paywallTrigger: AnalyticsEvent.PaywallTrigger?

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
                populatedList
            }
        }
        .screenBackground()
        .navigationTitle(Text(.historyTitle))
        .paywallSheet(trigger: $paywallTrigger, entitlements: entitlements)
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

    private var populatedList: some View {
        @Bindable var viewModel = viewModel
        let archive = viewModel.archive(from: entries, isPro: entitlements.entitlement == .pro)
        return List {
            Section {
                ForEach(archive.visible) { entry in
                    HistoryCellView(entry: entry, viewModel: viewModel)
                        .listRowBackground(Color.clear)
                }
            }

            if archive.olderCount > 0 {
                if viewModel.searchText.isEmpty {
                    earlierSection(archive)
                } else if archive.olderMatchCount > 0 {
                    archiveSearchHint(archive.olderMatchCount)
                }
            }
        }
        .contentMargins(.top, 8)
        .searchable(text: $viewModel.searchText)
        .scrollDismissesKeyboard(.immediately)
        .overlay {
            if archive.visible.isEmpty, archive.olderMatchCount == 0, !viewModel.searchText.isEmpty {
                ContentUnavailableView.search
            }
        }
    }

    // MARK: - Earlier archive (T1)

    /// The collapsed, counted, blurred-teaser archive below the active window
    /// (§9-A). Self-explanatory and ambient — it never nags or interrupts.
    private func earlierSection(_ archive: HistoryViewModel.Archive) -> some View {
        Section {
            ForEach(archive.teaser) { entry in
                Button {
                    paywallTrigger = .historyArchive
                } label: {
                    archiveTeaserRow(entry)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }

            Button {
                paywallTrigger = .historyArchive
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                    Text(.historyArchiveUnlock)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .font(.subheadline.weight(.semibold))
            }
            .listRowBackground(Color.clear)
            .accessibilityIdentifier("history-archive-unlock")
        } header: {
            Text(.historyArchiveHeader(archive.olderCount))
        } footer: {
            Text(.historyArchiveDisclosure)
        }
    }

    /// Search over the window only; aged-out matches surface as a count, never as
    /// blurred result rows (§9 / §6 "search free within the window, depth is Pro").
    private func archiveSearchHint(_ count: Int) -> some View {
        Section {
            Button {
                paywallTrigger = .historyArchive
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text(.historyArchiveSearchHint(count))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
            .accessibilityIdentifier("history-archive-search-hint")
        }
    }

    /// A blurred silhouette of an aged-out entry; tapping anywhere on it opens the
    /// paywall, the same as the unlock button. Blurred hard enough that no URL is
    /// legible in a screenshot, and hidden from VoiceOver so the link never leaks
    /// through assistive tech (the labeled unlock button is the VoiceOver path).
    private func archiveTeaserRow(_ entry: HistoryEntry) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.tint.opacity(0.5))
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.pageTitle ?? entry.output)
                    .font(.body)
                    .lineLimit(1)
                Text(entry.createdAt, format: .relative(presentation: .named))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .blur(radius: 10)
        .contentShape(Rectangle())
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .modelContainer(HistoryContainer.makeInMemory())
            .environment(EntitlementsModel.preview)
    }
}
