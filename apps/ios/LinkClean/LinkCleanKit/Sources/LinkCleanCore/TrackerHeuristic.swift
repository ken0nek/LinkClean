//
//  TrackerHeuristic.swift
//  LinkCleanCore
//
//  Created by Ken Tominaga on 6/13/26.
//

import Foundation

/// The deterministic, every-device tier of the unknown-parameter advisor
/// (growth-roadmap §5 "ai-A", tier 1). Classifies a single leftover query-key
/// name by shape alone — no model, no network — so the advisor surfaces
/// suggestions even on devices without Apple Intelligence. The model tier
/// (`ParameterAdvising`) is consulted only for the names this returns
/// ``Verdict/unknown`` for.
///
/// Precision over recall by design: a false positive is a parameter the user
/// promotes to always-remove that then breaks a site (recoverable via the
/// toggle/delete escape hatches, but trust-eroding), so the structural signals
/// are deliberately narrow and a denylist keeps famously functional keys from
/// ever being questioned.
public enum TrackerHeuristic {

    /// Why a name reads as a tracker. An identifier only — the app maps it to
    /// localized reason copy (the kit ships ids, not text) — and the analytics
    /// tier slice keys off it via ``AnalyticsEvent/AdvisorTier``.
    public enum Signal: String, Sendable, Equatable, CaseIterable {
        /// Listed in the bundled ``ReferenceParameterCatalog`` — a vetted known
        /// tracker missing from the default removal catalog.
        case known
        /// `utm_*` / `*campaign*` analytics-campaign shapes.
        case campaign
        /// Click identifiers — `*clid`, `*clkid`, `*click*`.
        case clickID
        /// Affiliate / partner referral tags.
        case affiliate
        /// Other tracker-shaped names (`*track*`).
        case generic
    }

    /// The classification of one leftover name.
    public enum Verdict: Sendable, Equatable {
        /// Surface deterministically with this signal's reason — every device.
        case likelyTracker(Signal)
        /// Famously functional or sensitive — never suggest removing it.
        case functional
        /// No strong signal; hand to the model tier on eligible devices.
        case unknown
    }

    /// Names so commonly functional (or security-sensitive) that the advisor
    /// must never propose removing them — suggesting one would offer to break
    /// search, pagination, language, an item id, or auth. Lowercased; matched
    /// **exactly**, never as substrings (so `cmpid` is still reachable while `id`
    /// is off-limits).
    private static let functionalNames: Set<String> = [
        // Search / query
        "q", "query", "search", "s", "k", "keyword", "keywords",
        // Identity / pagination / paging
        "id", "p", "page", "pg", "offset", "limit", "start", "count",
        // Bare media/interaction words the structural rules below would otherwise
        // over-match: `track` (a music/podcast/video track number — Spotify,
        // Apple Music, SoundCloud) and `click` (an image-map / heatmap
        // coordinate). The compound tracker shapes (`trackid`, `gclid`,
        // `ad_click`) still match — only the bare functional words are excused.
        "track", "click",
        // Versioning / time / ordering
        "v", "version", "t", "time", "ts", "tab", "sort", "order", "dir",
        // Locale / presentation
        "lang", "language", "locale", "hl", "l", "format", "type", "mode",
        "view", "filter", "category", "cat", "theme", "color",
        // Resource addressing
        "name", "title", "url", "u", "code",
        // Geometry / media
        "w", "h", "width", "height", "size", "zoom", "z",
        "lat", "lng", "lon", "latitude", "longitude",
        // Security-sensitive — removing these breaks the link
        "token", "key", "auth", "sig", "signature", "hash",
    ]

    /// Classifies a single leftover query-key name. Pure and allocation-light —
    /// runs on every candidate of every clean, so it stays cheap.
    public static func assess(_ name: String) -> Verdict {
        let key = name.lowercased()
        guard !key.isEmpty else { return .unknown }

        // Vetted known trackers win outright — the reference catalog is the
        // heuristic's curated knowledge source.
        if ReferenceParameterCatalog.names.contains(key) {
            return .likelyTracker(.known)
        }
        // Famously functional / sensitive keys are off-limits to every signal
        // below — checked before the structural rules so e.g. a `type` key is
        // never reinterpreted by a future substring rule.
        if functionalNames.contains(key) {
            return .functional
        }
        // Structural signals, most specific first.
        if key.contains("utm") || key.contains("campaign") {
            return .likelyTracker(.campaign)
        }
        if key.hasSuffix("clid") || key.hasSuffix("clkid") || key.contains("click") {
            return .likelyTracker(.clickID)
        }
        if key == "aff" || key.hasPrefix("aff_") || key.contains("affiliate") || key.contains("partnerid") {
            return .likelyTracker(.affiliate)
        }
        if key.contains("track") {
            return .likelyTracker(.generic)
        }
        return .unknown
    }
}
