//
//  ScreenBackground.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import SwiftUI

/// The shared screen backdrop: a soft vertical gradient with a faint brand-tinted
/// glow at the top. The glow gives Liquid Glass surfaces some accent color to
/// refract (so the teal identity reads) without tinting foreground content.
private struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .overlay(alignment: .topTrailing) {
                    RadialGradient(
                        colors: [Color.accentColor.opacity(0.16), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 380
                    )
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }
}
