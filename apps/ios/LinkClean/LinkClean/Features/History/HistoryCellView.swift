//
//  HistoryCellView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import LinkCleanCore
import LinkCleanData
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
            // The leading content (everything but the trailing button cluster) opens
            // the before→after detail. Scoped here, not on the whole row, so taps in
            // the borderless Copy/Share buttons' padding don't fall through to it.
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
            }
            .contentShape(Rectangle())
            .onTapGesture { viewModel.showBeforeAfter(for: entry) }

            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 6) {
                    Button {
                        viewModel.copyURL(for: entry)
                    } label: {
                        Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(didCopy ? .green : .secondary)
                            .frame(width: 38, height: 38)
                            .glassEffect(.regular.interactive(), in: .circle)
                            .frame(width: 44, height: 44)
                            .contentShape(.circle)
                    }
                    .buttonStyle(.borderless)
                    .symbolEffect(.bounce, value: didCopy)
                    .accessibilityLabel(didCopy ? Text(.commonCopied) : Text(.commonCopyCleanedUrl))

                    ShareLink(item: entry.output) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 38, height: 38)
                            .glassEffect(.regular.interactive(), in: .circle)
                            .frame(width: 44, height: 44)
                            .contentShape(.circle)
                    }
                    .buttonStyle(.borderless)
                    .simultaneousGesture(TapGesture().onEnded { viewModel.recordShared(for: entry) })
                    .accessibilityLabel(Text(.historyCellShare))
                }
            }
        }
        .padding(.vertical, 4)
        .sensoryFeedback(trigger: didCopy) { _, didCopy in didCopy ? .success : nil }
        .task(id: entry.id) {
            viewModel.fetchMetadataIfNeeded(for: entry)
        }
        .contextMenu {
            Button {
                viewModel.showBeforeAfter(for: entry)
            } label: {
                Label { Text(.historyMenuBeforeAfter) } icon: { Image(systemName: "arrow.left.arrow.right") }
            }

            Button {
                viewModel.copyURL(for: entry)
            } label: {
                Label { Text(.historyMenuCopyCleanUrl) } icon: { Image(systemName: "doc.on.doc") }
            }

            Button {
                viewModel.copyMarkdown(for: entry)
            } label: {
                Label { Text(.historyMenuCopyAsMarkdown) } icon: { Image(systemName: "curlybraces") }
            }

            ShareLink(item: entry.output) {
                Label { Text(.historyMenuShare) } icon: { Image(systemName: "square.and.arrow.up") }
            }
            .simultaneousGesture(TapGesture().onEnded { viewModel.recordShared(for: entry) })

            Button {
                if let url = viewModel.urlToOpen(for: entry) {
                    openURL(url)
                }
            } label: {
                Label { Text(.historyMenuOpenInBrowser) } icon: { Image(systemName: "safari") }
            }

            if entry.metadataFetchAttempted && entry.pageTitle == nil {
                Button {
                    viewModel.retryMetadataFetch(for: entry)
                } label: {
                    Label { Text(.historyMenuRetryMetadata) } icon: { Image(systemName: "arrow.clockwise") }
                }
            }

            Divider()

            Button(role: .destructive) {
                viewModel.deleteEntry(entry)
            } label: {
                Label { Text(.commonDelete) } icon: { Image(systemName: "trash") }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteEntry(entry)
            } label: {
                Label { Text(.commonDelete) } icon: { Image(systemName: "trash") }
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
