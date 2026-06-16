//
//  ParameterKindTitle.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/12/26.
//

import SwiftUI

/// Maps a catalog `TrackingParameterKind` id (`"utm"`, `"ads"`, …) to its
/// localized title. The domain ships identifiers, not copy (ARCHITECTURE.md), so
/// the mapping lives in the presenting layer, where the string catalog generates
/// the symbols. Shared by `ManageParametersView` (section headers) and `StatsView`
/// (the by-category breakdown); an unknown id falls back to the raw identifier,
/// exactly as the kit did.
func parameterKindTitle(_ id: String) -> Text {
    if let resource = parameterKindTitleResource(id) {
        Text(resource)
    } else {
        Text(verbatim: id)
    }
}

/// The eager `String` form of ``parameterKindTitle(_:)``, for callers that compose
/// titles into a single plain string (e.g. the share card's middot-joined label
/// row, which renders one `Text` for `ImageRenderer`). Shares the same mapping.
func parameterKindTitleString(_ id: String) -> String {
    if let resource = parameterKindTitleResource(id) {
        String(localized: resource)
    } else {
        id
    }
}

private func parameterKindTitleResource(_ id: String) -> LocalizedStringResource? {
    switch id {
    case "utm": .parametersKindUtm
    case "referral": .parametersKindReferral
    case "ads": .parametersKindAds
    case "analytics": .parametersKindAnalytics
    case "email": .parametersKindEmail
    case "social": .parametersKindSocial
    case "affiliate": .parametersKindAffiliate
    default: nil
    }
}
