//
//  StatsView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/12/26.
//

import SwiftUI
import UIKit
import LinkCleanCore

/// The Statistics dashboard (growth-roadmap §5 V2): the lifetime privacy impact
/// the `StatsStore` counters have been accruing since 1.1, surfaced as Liquid
/// Glass cards in the Home idiom — a hero figure, the two headline totals, then
/// by-category and top-site breakdowns. Free; reached from Settings.
struct StatsView: View {
    @State private var viewModel: StatsViewModel
    /// The rendered, shareable privacy card. Re-rendered whenever the underlying
    /// figures change; `nil` until there's data to show.
    @State private var renderedCard: SharePrivacyCard?
    @Environment(\.scenePhase) private var scenePhase

    init(deps: AppDependencies) {
        _viewModel = State(initialValue: StatsViewModel(deps: deps))
    }

    #if DEBUG
    /// Inject a seeded ViewModel (previews/tests).
    init(viewModel: StatsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    #endif

    var body: some View {
        Group {
            if viewModel.hasData {
                ScrollView {
                    content.padding(20)
                }
                .scrollBounceBehavior(.basedOnSize)
            } else {
                emptyState
            }
        }
        .screenBackground()
        .navigationTitle(Text(.statsTitle))
        .toolbar {
            if renderedCard != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    shareLink { Image(systemName: "square.and.arrow.up") }
                        .simultaneousGesture(TapGesture().onEnded {
                            viewModel.recordCardShared(entryPoint: .toolbar)
                        })
                        .accessibilityLabel(Text(.shareCardButton))
                        .accessibilityIdentifier("share-privacy-card-toolbar")
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
            viewModel.handleScreenShown()   // after the refresh, so hasData is current
        }
        // The stats blob is written by other surfaces (the extensions, Control
        // Center, a Shortcut) while this pushed screen stays on-screen — where
        // onAppear won't fire again on foreground — so re-read on .active, like
        // HistoryView/HomeView. withAnimation so the numeric figures roll.
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            withAnimation { viewModel.onAppear() }
        }
        // Render the privacy card off the current figures. `ImageRenderer` is a UI
        // concern, so the View owns it; the ViewModel only derives the data.
        .task(id: viewModel.shareCard) {
            renderedCard = viewModel.shareCard.flatMap(renderShareCard)
        }
    }

    private var content: some View {
        VStack(spacing: 18) {
            heroCard
            metricsRow
            if !viewModel.categories.isEmpty { categoriesCard }
            if !viewModel.topSites.isEmpty { sitesCard }
            if renderedCard != nil { shareCTA }
        }
    }

    // MARK: - Share

    /// The prominent share affordance at the foot of the dashboard — the privacy
    /// card is the highest-leverage organic loop (growth-marketing §6), so it gets
    /// a real CTA, not just the toolbar icon.
    private var shareCTA: some View {
        shareLink {
            Label { Text(.shareCardButton) } icon: { Image(systemName: "square.and.arrow.up") }
                .primaryButtonLabel()
        }
        .simultaneousGesture(TapGesture().onEnded {
            viewModel.recordCardShared(entryPoint: .cta)
        })
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .accessibilityIdentifier("share-privacy-card")
    }

    /// A `ShareLink` over the rendered card, sharing the same PNG from the toolbar
    /// and the CTA. Empty until the card has rendered. Each call site adds its own
    /// `.simultaneousGesture` to record the share entry point (`ShareLink` has no
    /// completion callback — mirrors `HomeView`'s share hook).
    @ViewBuilder
    private func shareLink(@ViewBuilder label: () -> some View) -> some View {
        if let renderedCard {
            ShareLink(
                item: renderedCard,
                preview: SharePreview(String(localized: .shareCardPreviewTitle), image: renderedCard.image),
                label: label
            )
        }
    }

    /// Renders the privacy card to a shareable PNG. `ImageRenderer` doesn't capture
    /// live Liquid Glass, which is why `ShareCardView` is opaque by design; the PNG
    /// bytes let `ShareLink` vend a real file (not just an in-memory `Image`).
    @MainActor
    private func renderShareCard(_ data: ShareCardData) -> SharePrivacyCard? {
        let renderer = ImageRenderer(content: ShareCardView(data: data))
        renderer.scale = 3   // crisp PNG regardless of the device's display scale
        guard let uiImage = renderer.uiImage, let pngData = uiImage.pngData() else { return nil }
        return SharePrivacyCard(image: Image(uiImage: uiImage), pngData: pngData)
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 40))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            Text(viewModel.totalParametersRemoved, format: .number)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(.statsMetricRemoved)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .glassCard(cornerRadius: 28)
    }

    // MARK: - Headline totals

    private var metricsRow: some View {
        HStack(spacing: 14) {
            metricCard(value: viewModel.totalCleans, label: .statsMetricCleaned, systemImage: "link")
            metricCard(value: viewModel.totalParametersRemoved, label: .statsMetricRemoved, systemImage: "checkmark.shield")
        }
    }

    private func metricCard(value: Int, label: LocalizedStringResource, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)

            Text(value, format: .number)
                .font(.system(.title, design: .rounded).weight(.bold))
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard(cornerRadius: 22)
    }

    // MARK: - By category

    private var categoriesCard: some View {
        let maxCount = max(viewModel.maxCategoryCount, 1)
        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader(.statsSectionCategories)

            VStack(spacing: 12) {
                ForEach(viewModel.categories) { category in
                    HStack(spacing: 12) {
                        parameterKindTitle(category.id)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                            .frame(width: 96, alignment: .leading)

                        ProgressView(value: Double(category.count), total: Double(maxCount))
                            .tint(.accentColor)

                        Text(category.count, format: .number)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .trailing)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 26)
    }

    // MARK: - Top sites

    private var sitesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(.statsSectionSites)

            VStack(spacing: 12) {
                ForEach(viewModel.topSites) { site in
                    HStack(spacing: 12) {
                        Text(site.host)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer(minLength: 12)

                        Text(site.count, format: .number)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 26)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label { Text(.statsEmptyTitle) } icon: { Image(systemName: "chart.bar.xaxis") }
        } description: {
            Text(.statsEmptyMessage)
        }
    }

}

#if DEBUG
#Preview("Populated") {
    NavigationStack {
        StatsView(viewModel: StatsViewModel(
            totalCleans: 318,
            totalParametersRemoved: 1247,
            categories: [
                .init(id: "utm", count: 412),
                .init(id: "ads", count: 388),
                .init(id: "analytics", count: 201),
                .init(id: "social", count: 142),
                .init(id: "email", count: 104)
            ],
            topSites: [
                .init(host: "youtube.com", count: 92),
                .init(host: "x.com", count: 54),
                .init(host: "amazon.com", count: 31),
                .init(host: "google.com", count: 22),
                .init(host: "reddit.com", count: 18)
            ]
        ))
    }
}

#Preview("Empty") {
    NavigationStack {
        StatsView(deps: .preview())
    }
}
#endif
