//
//  HistoryDetailView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/25/26.
//

import LinkCleanCore
import LinkCleanData
import SwiftUI

/// The before→after detail for one History entry — the original link, the cleaned
/// link, and exactly what changed between them per ``HistoryDiff``. The diff is
/// computed from the two stored strings (never a re-clean), so it always reflects
/// what actually happened to this link, even after a later catalog update.
struct HistoryDetailView: View {
    let entry: HistoryEntry
    let viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss

    /// Computed once at init (a pure function of the entry), not per `body` pass.
    private let diff: HistoryDiff

    init(entry: HistoryEntry, viewModel: HistoryViewModel) {
        self.entry = entry
        self.viewModel = viewModel
        self.diff = HistoryDiff(input: entry.input, output: entry.output, arrivedFromHost: entry.arrivedFromHost)
    }

    var body: some View {
        NavigationStack {
            List {
                if let host = diff.expandedFromHost {
                    Section {
                        Label {
                            Text(.historyDetailExpandedFrom(host))
                        } icon: {
                            Image(systemName: "arrow.up.right.square")
                        }
                        .foregroundStyle(.tint)
                    }
                }

                Section {
                    linkText(entry.input)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(.historyDetailOriginal)
                }

                Section {
                    linkText(entry.output)
                    Button {
                        viewModel.copyURL(for: entry)
                    } label: {
                        Label { Text(.commonCopyCleanedUrl) } icon: { Image(systemName: "doc.on.doc") }
                    }
                } header: {
                    Text(.historyDetailCleaned)
                }

                removedSection
            }
            .navigationTitle(Text(.historyDetailTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Text(.commonClose) }
                }
            }
        }
    }

    @ViewBuilder
    private var removedSection: some View {
        if diff.isEmpty {
            Section {
                Text(.historyDetailNothingRemoved)
                    .foregroundStyle(.secondary)
            }
        } else if !diff.removedParameters.isEmpty || diff.removedFragment != nil {
            Section {
                ForEach(Array(diff.removedParameters.enumerated()), id: \.offset) { _, param in
                    HStack(alignment: .firstTextBaseline) {
                        Text(param.name)
                            .fontWeight(.medium)
                        Spacer(minLength: 12)
                        Text(param.value)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .font(.callout.monospaced())
                }

                if let fragment = diff.removedFragment {
                    // verbatim: a raw URL fragment is user data, not a localizable
                    // key — the interpolating `Text(_:)` overload would route it
                    // through the string catalog (and auto-extract a "#%@" key).
                    Text(verbatim: "#\(fragment)")
                        .font(.callout.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            } header: {
                Text(.historyDetailRemoved)
            }
        }
    }

    private func linkText(_ string: String) -> some View {
        Text(string)
            .font(.callout.monospaced())
            .textSelection(.enabled)
    }
}

#Preview("Removed params") {
    HistoryDetailView(
        entry: HistoryEntry(
            input: "https://example.com/page?utm_source=newsletter&utm_medium=email&id=42#:~:text=hi",
            output: "https://example.com/page?id=42"
        ),
        viewModel: HistoryViewModel()
    )
}

#Preview("Expanded short link") {
    HistoryDetailView(
        entry: HistoryEntry(
            input: "https://www.youtube.com/watch?v=dQw4&feature=share",
            output: "https://www.youtube.com/watch?v=dQw4",
            arrivedFromHost: "bit.ly"
        ),
        viewModel: HistoryViewModel()
    )
}
