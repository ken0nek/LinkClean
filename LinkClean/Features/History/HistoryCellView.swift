//
//  HistoryCellView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import LinkCleanCommon
import SwiftData
import SwiftUI

struct HistoryCellView: View {
    let entry: HistoryEntry
    let viewModel: HistoryViewModel
    let modelContext: ModelContext

    @Environment(\.openURL) private var openURL

    private var didCopy: Bool {
        viewModel.copiedEntryID == entry.id
    }

    private var domain: String {
        guard let host = URL(string: entry.output)?.host() else { return entry.output }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    private var domainInitial: String {
        guard let first = domain.first, first.isLetter else { return "?" }
        return String(first).uppercased()
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(domainInitial)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.output)
                    .font(.body)
                    .foregroundStyle(.tint)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(domain)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(entry.createdAt, format: .relative(presentation: .named))
                        .foregroundStyle(.tertiary)
                }
                .font(.footnote)
                .lineLimit(1)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button {
                    viewModel.copyURL(for: entry)
                } label: {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(didCopy ? .green : .secondary)
                        .frame(width: 34, height: 34)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.borderless)
                .symbolEffect(.bounce, value: didCopy)
                .accessibilityLabel(didCopy ? "Copied" : "Copy cleaned URL")

                ShareLink(item: entry.output) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Share cleaned URL")
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                viewModel.copyURL(for: entry)
            } label: {
                Label("Copy Clean URL", systemImage: "doc.on.doc")
            }

            ShareLink(item: entry.output) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Button {
                if let url = URL(string: entry.output) {
                    openURL(url)
                }
            } label: {
                Label("Open in Browser", systemImage: "safari")
            }

            Divider()

            Button(role: .destructive) {
                viewModel.deleteEntry(entry, from: modelContext)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteEntry(entry, from: modelContext)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    List {
        HistoryCellView(
            entry: HistoryEntry(
                input: "https://x.com/user/status/123456?s=20&t=abc",
                output: "https://x.com/user/status/123456"
            ),
            viewModel: HistoryViewModel(),
            modelContext: try! ModelContext(ModelContainer(for: HistoryEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        )
        HistoryCellView(
            entry: HistoryEntry(
                input: "https://www.example.com/page?utm_source=test",
                output: "https://www.example.com/page"
            ),
            viewModel: HistoryViewModel(),
            modelContext: try! ModelContext(ModelContainer(for: HistoryEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        )
    }
}
