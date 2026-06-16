//
//  ShareCardView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/13/26.
//

import SwiftUI
import UniformTypeIdentifiers

/// The data the shareable privacy card renders (growth-roadmap §5 V3). Pure
/// display values; `StatsViewModel.shareCard` derives it from the lifetime
/// aggregates. Counts only and public catalog kind ids — never a host or a custom
/// parameter name — so nothing personal rides onto a publicly-posted image.
struct ShareCardData: Equatable {
    let parametersRemoved: Int
    let cleans: Int
    let categoryCount: Int
    /// The most-removed categories (kind id + count), most-first, for the
    /// segmented bar and its labels.
    let topCategories: [Segment]
    /// Combined removals across the categories *beyond* `topCategories` (0 when
    /// none). Drives the bar's faint "other" segment so the bar represents all
    /// `categoryCount` categories — matching the proof row's count and keeping the
    /// top segments' proportions honest (normalized to the whole, not to their own
    /// sum).
    let otherCount: Int

    struct Segment: Equatable, Identifiable {
        /// The catalog kind id (`"utm"`, `"ads"`, …), localized via
        /// `parameterKindTitle(_:)` in the view.
        let id: String
        let count: Int
    }
}

/// A rendered privacy card packaged for sharing (growth-roadmap §5 V3). Carries
/// the PNG bytes so `ShareLink` vends a real, named file — Apple's `ShareLink`
/// guidance notes some targets (Save to Files, Mail, Messages) only accept files,
/// not a bare in-memory `Image` — plus the `Image` for the share-sheet preview.
struct SharePrivacyCard: Transferable {
    let image: Image
    let pngData: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { $0.pngData }
            .suggestedFileName("LinkClean-privacy-card.png")
    }
}

/// A square, self-contained privacy card the user can post (growth-roadmap §5 V3,
/// growth-marketing §6 — the highest-leverage organic loop): the talkable hero
/// figure ("1,247 trackers removed") over the brand gradient, a calm proof row,
/// and the category mix.
///
/// **No precedent — this is the app's first view-to-image render** (every other
/// `ShareLink` shares text). `ImageRenderer` does not capture live Liquid Glass or
/// materials, so this view is deliberately *opaque*: explicit brand colors and no
/// `glassCard`/`screenBackground`, so the export looks identical on every device,
/// independent of light/dark. The fixed `.dark` colorScheme is a forward guard:
/// every color is explicit today, but it keeps any future semantic color stable.
struct ShareCardView: View {
    let data: ShareCardData

    /// The render size in points; `ImageRenderer` scales this up for a crisp PNG.
    static let side: CGFloat = 360
    /// Width available to content inside the card's padding — the layout constant
    /// the category bar sizes against (see `padding(32)` below).
    private static let contentWidth: CGFloat = side - 64

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            wordmark
            Spacer(minLength: 20)
            hero
            Spacer(minLength: 18)
            proofRow
            if !data.topCategories.isEmpty {
                categoryBar.padding(.top, 16)
                categoryLabels.padding(.top, 10)
            }
            Spacer(minLength: 20)
            tagline
        }
        .padding(32)
        .frame(width: Self.side, height: Self.side, alignment: .topLeading)
        .background(background)
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Wordmark

    private var wordmark: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 20, weight: .semibold))
            Text(verbatim: "LinkClean")
                .font(.system(size: 20, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
    }

    // MARK: - Hero figure

    private var hero: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(data.parametersRemoved, format: .number)
                .font(.system(size: 84, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.white)

            Text(.statsMetricRemoved)
                .font(.system(size: 15, weight: .semibold))
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    // MARK: - Proof row

    private var proofRow: some View {
        let links = String(localized: .shareCardProofLinks(data.cleans))
        let categories = String(localized: .shareCardProofCategories(data.categoryCount))
        return Text(verbatim: "\(links)   ·   \(categories)")
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.9))
    }

    // MARK: - Category mix

    /// A proportional, multi-segment bar of the category mix (graduated white),
    /// normalized to *all* categories so the top segments read at their true share
    /// and a faint trailing "other" segment accounts for the rest. Widths are
    /// computed from the constant content width rather than a `GeometryReader`:
    /// `ImageRenderer` lays the card out once, and a fixed geometry is more robust
    /// to rasterize than a greedy reader.
    private var categoryBar: some View {
        let segments = barSegments
        let total = CGFloat(max(segments.reduce(0) { $0 + $1.count }, 1))
        let spacing: CGFloat = 4
        let available = Self.contentWidth - spacing * CGFloat(max(segments.count - 1, 0))
        return HStack(spacing: spacing) {
            ForEach(segments) { segment in
                Capsule()
                    .fill(.white.opacity(segment.opacity))
                    .frame(width: max(available * CGFloat(segment.count) / total, 6))
            }
        }
        .frame(height: 12)
    }

    /// The top categories (graduated white) plus a faint "other" segment when there
    /// are more categories than the card names.
    private var barSegments: [BarSegment] {
        var segments = data.topCategories.enumerated().map { index, segment in
            BarSegment(id: segment.id, count: segment.count, opacity: Self.segmentOpacity(index))
        }
        if data.otherCount > 0 {
            segments.append(BarSegment(id: "__other", count: data.otherCount, opacity: 0.22))
        }
        return segments
    }

    private struct BarSegment: Identifiable {
        let id: String
        let count: Int
        let opacity: Double
    }

    /// One line, scaled down to fit the content width if the joined names are long.
    /// A single scaled line is deterministic under `ImageRenderer`'s one layout
    /// pass — a wrapped second line competes with the tall hero for vertical space
    /// and can truncate unpredictably.
    private var categoryLabels: some View {
        labelsText
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.8))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: Self.contentWidth, alignment: .leading)
    }

    /// The top category titles joined with a middot — built as one `Text` so the
    /// localized kind titles render as a single run for `ImageRenderer`.
    private var labelsText: Text {
        let joined = data.topCategories
            .map { parameterKindTitleString($0.id) }
            .joined(separator: "  ·  ")
        return Text(verbatim: joined)
    }

    private static func segmentOpacity(_ index: Int) -> Double {
        switch index {
        case 0: 1.0
        case 1: 0.66
        default: 0.4
        }
    }

    // MARK: - Tagline

    private var tagline: some View {
        Text(.shareCardTagline)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.7))
    }

    // MARK: - Background

    /// The brand gradient with a faint top-trailing glow — the opaque counterpart
    /// to `ScreenBackground`'s teal glow, so the card reads as the same family.
    ///
    /// Loads the accent **asset by name** rather than `Color.accentColor`:
    /// `ImageRenderer` renders in an isolated environment that doesn't inherit the
    /// app's tint, so `.accentColor` there falls back to system blue. The named
    /// asset resolves to the real privacy-teal regardless.
    private var background: some View {
        let brand = Color("AccentColor")
        return LinearGradient(
            colors: [
                brand.mix(with: .white, by: 0.05),
                brand.mix(with: .black, by: 0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            RadialGradient(
                colors: [.white.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 280
            )
        }
    }
}

#if DEBUG
#Preview("Share card") {
    ShareCardView(data: ShareCardData(
        parametersRemoved: 1247,
        cleans: 318,
        categoryCount: 5,
        topCategories: [
            .init(id: "utm", count: 412),
            .init(id: "ads", count: 388),
            .init(id: "analytics", count: 201)
        ],
        otherCount: 246
    ))
}
#endif
