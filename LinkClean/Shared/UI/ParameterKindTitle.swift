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
    switch id {
    case "utm": Text(.parametersKindUtm)
    case "referral": Text(.parametersKindReferral)
    case "ads": Text(.parametersKindAds)
    case "analytics": Text(.parametersKindAnalytics)
    case "email": Text(.parametersKindEmail)
    case "social": Text(.parametersKindSocial)
    case "affiliate": Text(.parametersKindAffiliate)
    default: Text(verbatim: id)
    }
}
