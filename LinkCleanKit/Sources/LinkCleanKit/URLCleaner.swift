//
//  URLCleaner.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/1/26.
//

import Foundation

/// The outcome of cleaning a URL: the cleaned string, how many tracking
/// parameters were removed, and a privacy-safe analysis of what was left behind
/// (for catalog-gap telemetry — see `parameter-telemetry.md`). Everything is
/// derived from the same single pass `clean` makes over the query items, so the
/// fields can never disagree, and callers (analytics) never re-parse the URL.
public nonisolated struct CleanResult: Sendable, Equatable {
    public let cleaned: String
    public let removedCount: Int
    /// Number of query *items* remaining after cleaning (duplicates counted).
    /// Sizes the gap between our catalog and the trackers in real URLs (Tier 0).
    /// Note: this counts items, whereas `referenceMatches` is de-duplicated by
    /// name — so the two are only directly comparable when a URL has no repeated
    /// query keys (rare).
    public let leftoverCount: Int
    /// Catalog kind ids that fired in this clean (which categories earn their
    /// keep). Finite, known set — safe to send (Tier 0).
    public let removedKindIDs: Set<String>
    /// Leftover names that match the bundled reference catalog — known trackers
    /// missing from our defaults. Sorted, unique; all *public* names, never
    /// user-authored or arbitrary URL keys (Tier 1).
    public let referenceMatches: [String]

    /// Whether cleaning removed at least one tracking parameter.
    public var changed: Bool { removedCount > 0 }

    public init(
        cleaned: String,
        removedCount: Int,
        leftoverCount: Int = 0,
        removedKindIDs: Set<String> = [],
        referenceMatches: [String] = []
    ) {
        self.cleaned = cleaned
        self.removedCount = removedCount
        self.leftoverCount = leftoverCount
        self.removedKindIDs = removedKindIDs
        self.referenceMatches = referenceMatches
    }
}

public nonisolated enum URLCleaner {

    public static func isValidURL(_ urlString: String) -> Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host,
              !host.isEmpty
        else {
            return false
        }

        return true
    }

    /// URL-object counterpart of `isValidURL(_:)` so the app and the
    /// action extension share a single web-link policy.
    public static func isWebURL(_ url: URL) -> Bool {
        isValidURL(url.absoluteString)
    }

    public static func clean(_ urlString: String) -> String {
        clean(urlString, removing: TrackingParameterCatalog.defaultEnabledSet)
    }

    public static func clean(_ urlString: String, removing parameters: Set<String>) -> String {
        cleanResult(urlString, removing: parameters).cleaned
    }

    /// Cleans `urlString` and, in the same single pass over the query items,
    /// reports the removed count plus the privacy-safe catalog-gap analysis
    /// (`leftoverCount`, `removedKindIDs`, `referenceMatches`). Callers never
    /// re-parse the URL, and the analysis can never disagree with the cleaning.
    public static func cleanResult(
        _ urlString: String,
        removing parameters: Set<String>,
        referenceNames: Set<String> = ReferenceParameterCatalog.names
    ) -> CleanResult {
        guard var components = URLComponents(string: urlString),
              let queryItems = components.queryItems, !queryItems.isEmpty
        else {
            return CleanResult(cleaned: urlString, removedCount: 0)
        }

        let normalized = Set(parameters.map { $0.lowercased() })
        var kept: [URLQueryItem] = []
        var removedKindIDs = Set<String>()
        var leftoverNames = Set<String>()
        for item in queryItems {
            let name = item.name.lowercased()
            if normalized.contains(name) {
                if let kindID = TrackingParameterCatalog.kindID(for: name) {
                    removedKindIDs.insert(kindID)
                }
            } else {
                kept.append(item)
                leftoverNames.insert(name)
            }
        }

        components.queryItems = kept.isEmpty ? nil : kept

        return CleanResult(
            cleaned: components.string ?? urlString,
            removedCount: queryItems.count - kept.count,
            leftoverCount: kept.count,
            removedKindIDs: removedKindIDs,
            referenceMatches: leftoverNames.intersection(referenceNames).sorted()
        )
    }

    /// The exact parameter names removed from `urlString` by `parameters`, in
    /// first-seen order, de-duplicated case-insensitively with the first
    /// occurrence's original case preserved.
    ///
    /// Display-only — for *showing the user their own link* on Home. It lives
    /// apart from ``cleanResult(_:removing:referenceNames:)`` on purpose: that
    /// result is the analytics-bound, name-free catalog-gap summary
    /// (`parameter-telemetry.md`), and raw query-key names must never reach it.
    /// These names never leave the device.
    public static func removedParameterNames(
        _ urlString: String,
        removing parameters: Set<String>
    ) -> [String] {
        guard let components = URLComponents(string: urlString),
              let queryItems = components.queryItems
        else {
            return []
        }

        let normalized = Set(parameters.map { $0.lowercased() })
        var seen = Set<String>()
        var names: [String] = []
        for item in queryItems where normalized.contains(item.name.lowercased()) {
            if seen.insert(item.name.lowercased()).inserted {
                names.append(item.name)
            }
        }
        return names
    }

    /// The exact parameter names that survive cleaning `urlString` with
    /// `parameters` — everything *not* removed — in first-seen order,
    /// de-duplicated case-insensitively with the first occurrence's original
    /// case preserved.
    ///
    /// Same contract as ``removedParameterNames(_:removing:)``: these are raw
    /// query keys (potentially arbitrary or sensitive), so they exist only to
    /// show the user their own link on-device and must never reach analytics.
    /// The name-free ``CleanResult`` stays the telemetry path, and
    /// `referenceMatches` remains the only leftover names that may be *sent*.
    public static func leftoverParameterNames(
        _ urlString: String,
        removing parameters: Set<String>
    ) -> [String] {
        guard let components = URLComponents(string: urlString),
              let queryItems = components.queryItems
        else {
            return []
        }

        let normalized = Set(parameters.map { $0.lowercased() })
        var seen = Set<String>()
        var names: [String] = []
        for item in queryItems where !normalized.contains(item.name.lowercased()) {
            if seen.insert(item.name.lowercased()).inserted {
                names.append(item.name)
            }
        }
        return names
    }

    public static func clean(_ url: URL) -> URL {
        clean(url, removing: TrackingParameterCatalog.defaultEnabledSet)
    }

    public static func clean(_ url: URL, removing parameters: Set<String>) -> URL {
        cleanResult(url, removing: parameters).cleaned
    }

    /// URL counterpart of `cleanResult(_:removing:)`: the cleaned URL plus the
    /// full ``CleanResult`` (removed count and catalog-gap analysis).
    public static func cleanResult(_ url: URL, removing parameters: Set<String>) -> (cleaned: URL, result: CleanResult) {
        let result = cleanResult(url.absoluteString, removing: parameters)
        return (URL(string: result.cleaned) ?? url, result)
    }

    /// The lowercased host of `urlString` for site-popularity analytics, with a
    /// leading `www.` and any trailing root dot stripped
    /// (`https://www.YouTube.com./watch?v=x` → `"youtube.com"`); `"unknown"` when
    /// no host can be parsed. Subdomains other
    /// than `www.` are preserved, so `m.youtube.com` stays distinct from
    /// `youtube.com` (cheap to map together later if desired).
    ///
    /// Unlike every other path in this type, this **intentionally** derives an
    /// analytics value from URL content — the deliberate, disclosed exception to
    /// the "nothing URL-derived leaves the device" rule (`analytics.md` §3),
    /// answering *which sites are cleaned most*. It is the only host signal
    /// `AnalyticsEvent` is permitted to carry; full URLs, paths, query strings,
    /// and values still never leave the device.
    public static func analyticsDomain(from urlString: String) -> String {
        guard var host = URLComponents(string: urlString)?.host?.lowercased(), !host.isEmpty else {
            return "unknown"
        }
        // A fully-qualified host may carry a trailing root dot (`youtube.com.`);
        // drop it so it aggregates with the common form.
        if host.hasSuffix(".") {
            host.removeLast()
        }
        // Strip a leading `www.`, but only when a real label remains.
        if host.hasPrefix("www."), host.count > 4 {
            host.removeFirst(4)
        }
        return host.isEmpty ? "unknown" : host
    }

    /// `URL` overload of ``analyticsDomain(from:)-(String)`` for call sites that
    /// already hold a parsed `URL` (the Clean action extension).
    public static func analyticsDomain(from url: URL) -> String {
        analyticsDomain(from: url.absoluteString)
    }
}
