//
//  GlassCard.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/8/26.
//

import SwiftUI

/// The app's translucent card surface: an ultra-thin material fill with a
/// subtle hairline stroke, clipped to a continuous rounded rectangle. Shared
/// so the corner radius and stroke don't drift between cards.
private struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: .rect(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.08))
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}
