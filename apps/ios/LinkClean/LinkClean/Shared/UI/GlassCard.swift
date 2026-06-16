//
//  GlassCard.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/8/26.
//

import SwiftUI

/// The app's floating card surface: native iOS 26 Liquid Glass clipped to a
/// continuous rounded rectangle. Shared so the corner radius stays consistent
/// between cards. Glass adapts to light/dark and draws its own edge, so no
/// hand-rolled material fill or hairline stroke is needed (and the old
/// dark-mode-only `white.opacity` stroke is gone).
private struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}
