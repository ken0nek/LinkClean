//
//  HistoryCellView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import LinkCleanCommon
import SwiftUI
import UIKit

struct HistoryCellView: View {
    let entry: HistoryEntry
    let viewModel: HistoryViewModel

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

    private var isFetching: Bool {
        viewModel.fetchingEntryIDs.contains(entry.id)
    }

    var body: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                if let title = entry.pageTitle {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                } else {
                    Text(entry.output)
                        .font(.body)
                        .foregroundStyle(.tint)
                        .lineLimit(2)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(domain)
                            .foregroundStyle(.secondary)

                        if isFetching {
                            ProgressView()
                                .controlSize(.mini)
                        }
                    }

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
        .task(id: entry.id) {
            viewModel.fetchMetadataIfNeeded(for: entry)
        }
        .contextMenu {
            Button {
                viewModel.copyURL(for: entry)
            } label: {
                Label("Copy Clean URL", systemImage: "doc.on.doc")
            }

            Button {
                viewModel.copyMarkdown(for: entry)
            } label: {
                Label("Copy as Markdown", systemImage: "curlybraces")
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

            if entry.metadataFetchAttempted && entry.pageTitle == nil {
                Button {
                    viewModel.retryMetadataFetch(for: entry)
                } label: {
                    Label("Retry Metadata", systemImage: "arrow.clockwise")
                }
            }

            Divider()

            Button(role: .destructive) {
                viewModel.deleteEntry(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteEntry(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = entry.thumbnailData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            domainInitialView
        }
    }

    private var domainInitialView: some View {
        Text(domainInitial)
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 64, height: 64)
            .background(.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    List {
        HistoryCellView(
            entry: HistoryEntry(
                input: "https://x.com/user/status/123456?s=20&t=abc",
                output: "https://x.com/user/status/123456"
            ),
            viewModel: HistoryViewModel()
        )
        HistoryCellView(
            entry: HistoryEntry(
                input: "https://www.example.com/page?utm_source=test",
                output: "https://www.example.com/page"
            ),
            viewModel: HistoryViewModel()
        )
    }
}
