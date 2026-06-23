//
//  ShareSheetMockView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/7/26.
//

import SwiftUI

/// An illustrative, non-interactive replica of the iOS share-sheet action
/// list, used by the extension guide to show users where LinkClean's actions
/// appear. The two LinkClean rows ("Clean URL", "Copy link as…") are
/// highlighted and gently pulse to draw the eye.
///
/// Row titles are intentionally `verbatim`: "Clean URL" and "Copy link as…"
/// must match the extensions' `CFBundleDisplayName`s exactly, and the system
/// rows match what iOS itself renders, so the mock stays truthful regardless
/// of app localization.
struct ShareSheetMockView: View {
    /// When `false`, the highlight stays static (no animation). Callers pass
    /// `false` once the guide reaches its success state so an off-screen mock
    /// isn't animating forever.
    var pulseActive = true

    private enum Row {
        case plain(title: String, systemImage: String)
        case linkClean(title: String, systemImage: String)
        case edit(title: String, systemImage: String)
    }

    private let rows: [Row] = [
        .plain(title: "Copy", systemImage: "doc.on.doc"),
        .linkClean(title: "Clean URL", systemImage: "scissors"),
        .linkClean(title: "Copy link as…", systemImage: "curlybraces"),
        .plain(title: "Add to Reading List", systemImage: "eyeglasses"),
        .edit(title: "Edit Actions…", systemImage: "slider.horizontal.3")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                rowView(for: row)
                if index < rows.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .glassCard(cornerRadius: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(.guideMockAccessibility))
    }

    @ViewBuilder
    private func rowView(for row: Row) -> some View {
        switch row {
        case let .plain(title, systemImage):
            MockActionRow(title: title, systemImage: systemImage, style: .plain, pulseActive: false)
        case let .linkClean(title, systemImage):
            MockActionRow(title: title, systemImage: systemImage, style: .highlighted, pulseActive: pulseActive)
        case let .edit(title, systemImage):
            MockActionRow(title: title, systemImage: systemImage, style: .plain, pulseActive: false)
        }
    }
}

private struct MockActionRow: View {
    enum Style { case plain, highlighted }

    let title: String
    let systemImage: String
    let style: Style
    let pulseActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    private var animates: Bool {
        style == .highlighted && pulseActive && !reduceMotion
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(verbatim: title)
                .font(.body)
                .foregroundStyle(style == .highlighted ? .primary : .secondary)

            Spacer(minLength: 12)

            iconTile
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(.rect)
    }

    private var iconForeground: Color {
        style == .highlighted ? .white : .secondary
    }

    private var iconBackground: Color {
        style == .highlighted ? .accentColor : Color(.tertiarySystemFill)
    }

    private var iconTile: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(iconForeground)
            .frame(width: 30, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconBackground)
            )
            .scaleEffect(pulsing ? 1.08 : 1.0)
            .shadow(color: .accentColor.opacity(pulsing ? 0.5 : 0.0), radius: pulsing ? 8 : 0)
            .animation(animates ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default, value: pulsing)
            .onAppear { pulsing = animates }
            .onChange(of: animates) { _, newValue in pulsing = newValue }
    }
}

#Preview {
    ShareSheetMockView()
        .padding()
        .screenBackground()
}
