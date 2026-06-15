//
//  QRResultView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/14/26.
//

import LinkCleanCore
import SwiftUI

/// The cleaned-link result of a scan, shown in a sheet over the live scanner: the
/// link, a calm proof-of-work badge, the "redirect expanded" note, and the export
/// actions (Copy / Share / Open). Reads the `@Observable` ``QRViewModel`` directly
/// — passed by reference, observed when its properties are read here.
struct QRResultView: View {
    let viewModel: QRViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 22) {
                resultCard
                actionBar
                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .screenBackground()
            .navigationTitle(Text(.qrResultTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Text(.commonClose) }
                }
            }
        }
        .sensoryFeedback(trigger: viewModel.didCopy) { _, didCopy in didCopy ? .success : nil }
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.removedParameters.isEmpty {
                removedBadge
            }

            Text(viewModel.cleanedText)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(.tint)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let host = viewModel.unwrappedFromHost {
                Label {
                    Text(.homeCleanedUnwrapped(host))
                } icon: {
                    Image(systemName: "arrowshape.turn.up.right")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 26)
    }

    /// Calm proof-of-work: "✓ N removed" as a tinted pill (informational, no undo —
    /// the same stance as Home's badge).
    private var removedBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.tint)
            Text(verbatim: "\(viewModel.removedParameters.count)")
                .monospacedDigit()
            Text(.homeRemovedHeader)
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.tint.opacity(0.14), in: .capsule)
        .accessibilityElement(children: .combine)
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.copyCleanedURL()
            } label: {
                Label {
                    Text(viewModel.didCopy ? .commonCopied : .homeCopyAction)
                } icon: {
                    Image(systemName: viewModel.didCopy ? "checkmark" : "doc.on.doc")
                }
                .primaryButtonLabel()
            }
            .buttonStyle(.glassProminent)
            .symbolEffect(.bounce, value: viewModel.didCopy)

            ShareLink(item: viewModel.cleanedText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                    .frame(minWidth: 28)
            }
            .buttonStyle(.glass)
            .accessibilityLabel(Text(.historyCellShare))
            .simultaneousGesture(TapGesture().onEnded { viewModel.recordShare() })

            if let url = viewModel.cleanedURL {
                Button {
                    viewModel.recordOpen()
                    openURL(url)
                } label: {
                    Image(systemName: "safari")
                        .font(.body.weight(.semibold))
                        .frame(minWidth: 28)
                }
                .buttonStyle(.glass)
                .accessibilityLabel(Text(.qrResultOpen))
            }
        }
        .controlSize(.large)
    }
}
