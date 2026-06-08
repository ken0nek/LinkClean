//
//  PrimaryButtonLabel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/8/26.
//

import SwiftUI

/// The app's filled primary call-to-action styling. Applied to a button's (or
/// ShareLink's) label content so it works uniformly across both, and so the
/// radius/padding stay consistent between CTAs instead of drifting per site.
private struct PrimaryButtonLabel: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.tint, in: .rect(cornerRadius: cornerRadius))
            .foregroundStyle(.white)
    }
}

extension View {
    func primaryButtonLabel(cornerRadius: CGFloat = 16) -> some View {
        modifier(PrimaryButtonLabel(cornerRadius: cornerRadius))
    }
}
