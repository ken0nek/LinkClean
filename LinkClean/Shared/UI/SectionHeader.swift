//
//  SectionHeader.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/12/26.
//

import SwiftUI

/// The app's section-header label: a tinted-secondary, uppercase, tracked caption
/// drawn above grouped content. Shared so every screen renders the identical
/// header (Home, Stats, …); consume as `sectionHeader(.someKey)`.
func sectionHeader(_ key: LocalizedStringResource) -> some View {
    Text(key)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .tracking(1.1)
}
