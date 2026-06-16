//
//  PrimaryButtonLabel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/8/26.
//

import SwiftUI

/// Sizing + weight for the app's primary call-to-action *label* content, so the
/// CTA fills its container and reads consistently across Buttons and ShareLinks.
/// The fill itself comes from the native glass button style — pair this with
/// `.buttonStyle(.glassProminent)` (and usually `.controlSize(.large)`) on the
/// owning Button/ShareLink:
///
/// ```swift
/// Button(action: …) { Text(…).primaryButtonLabel() }
///     .buttonStyle(.glassProminent)
///     .controlSize(.large)
/// ```
private struct PrimaryButtonLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func primaryButtonLabel() -> some View {
        modifier(PrimaryButtonLabel())
    }
}
