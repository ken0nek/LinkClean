//
//  URLCleaner.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/1/26.
//

import Foundation

public enum URLCleaner {

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
        clean(urlString, removing: TrackingParameterCatalog.defaultRemovalSet(forHost: ruleHost(of: urlString)))
    }

    public static func clean(_ urlString: String, removing parameters: Set<String>) -> String {
        outcome(for: urlString, removing: parameters).cleaned
    }

    public static func clean(_ url: URL) -> URL {
        clean(url, removing: TrackingParameterCatalog.defaultRemovalSet(forHost: ruleHost(of: url)))
    }

    public static func clean(_ url: URL, removing parameters: Set<String>) -> URL {
        URL(string: outcome(for: url.absoluteString, removing: parameters).cleaned) ?? url
    }

    /// Cleans `input` and reports everything a caller could need — the cleaned
    /// string, the analytics-safe ``CleanOutcome/Telemetry`` (counts, kind ids,
    /// reference matches, site domain), and the on-device ``CleanOutcome/Display``
    /// names — all in a single pass over the query items. One parse, so the
    /// shapes can never disagree, and the privacy boundary is a type, not a
    /// comment (raw key names live only in `display`, which no event accepts).
    ///
    /// `wrappers` records redirect wrappers a caller already peeled to reach
    /// `input` (``CleaningService`` passes ``unwrap(_:maxDepth:)``'s result). It
    /// is reported verbatim in the telemetry; it does not affect cleaning.
    public static func outcome(
        for input: String,
        removing parameters: Set<String>,
        referenceNames: Set<String> = ReferenceParameterCatalog.names,
        wrappers: [String] = []
    ) -> CleanOutcome {
        let domain = analyticsDomain(from: input)
        let normalized = Set(parameters.map { $0.lowercased() })

        guard var components = URLComponents(string: input) else {
            return CleanOutcome(
                input: input,
                cleaned: input,
                telemetry: .init(
                    changed: false,
                    removedCount: 0,
                    leftoverCount: 0,
                    removedKindIDs: [],
                    referenceMatches: [],
                    domain: domain,
                    wrappers: wrappers
                ),
                display: .init(removedNames: [], leftoverNames: [])
            )
        }

        // Fragment cleaning, independent of the query: a URL can carry tracking
        // params or a scroll-to-text directive in its fragment with no query at
        // all. Anchors (#section) and SPA routes (#/path) are left untouched.
        let fragment = cleanFragment(components.percentEncodedFragment, removing: normalized)
        components.percentEncodedFragment = fragment.cleaned

        // Iterate the *percent-encoded* items, not `queryItems`. Reading
        // `queryItems` decodes values and assigning it back re-encodes with a
        // charset that leaves `+`, `/`, etc. bare — so a kept `%2B` round-trips
        // to a literal `+`, which form-decoding servers read as a space. That
        // would silently change a kept param's value, even on a URL where we
        // remove nothing (we still reassign the items). Keeping each encoded
        // item verbatim preserves kept params byte-for-byte; we decode only the
        // *name* for catalog matching and display (a key may itself be encoded).
        let queryItems = components.percentEncodedQueryItems ?? []
        var kept: [URLQueryItem] = []
        var removedKindIDs = Set<String>()
        // Lowercased keys of kept items, for the reference-catalog intersection.
        var leftoverKeys = Set<String>()
        // First-seen display names (original case), de-duplicated per lowercased key.
        var removedNames: [String] = []
        var removedSeen = Set<String>()
        var leftoverNames: [String] = []
        var leftoverSeen = Set<String>()

        for item in queryItems {
            let decoded = item.name.removingPercentEncoding ?? item.name
            let key = decoded.lowercased()
            if normalized.contains(key) {
                if let kindID = TrackingParameterCatalog.kindID(for: key) {
                    removedKindIDs.insert(kindID)
                }
                if removedSeen.insert(key).inserted {
                    removedNames.append(decoded)
                }
            } else {
                kept.append(item)
                leftoverKeys.insert(key)
                if leftoverSeen.insert(key).inserted {
                    leftoverNames.append(decoded)
                }
            }
        }

        components.percentEncodedQueryItems = kept.isEmpty ? nil : kept

        // Fold fragment-borne tracking-param removals into the same totals so the
        // "N removed" proof-of-work and telemetry count them like query params.
        for name in fragment.removedNames {
            let key = name.lowercased()
            if let kindID = TrackingParameterCatalog.kindID(for: key) {
                removedKindIDs.insert(kindID)
            }
            if removedSeen.insert(key).inserted {
                removedNames.append(name)
            }
        }

        let removedCount = (queryItems.count - kept.count) + fragment.removedNames.count
        // `changed` tracks intentional cleaning — query/fragment param removals or
        // a stripped text directive — never incidental `URLComponents` re-encoding,
        // so an untouched link round-trips to itself byte-for-byte.
        let changed = removedCount > 0 || fragment.removedTextDirective

        return CleanOutcome(
            input: input,
            cleaned: changed ? (components.string ?? input) : input,
            telemetry: .init(
                changed: changed,
                removedCount: removedCount,
                leftoverCount: kept.count,
                removedKindIDs: removedKindIDs,
                referenceMatches: leftoverKeys.intersection(referenceNames).sorted(),
                domain: domain,
                wrappers: wrappers
            ),
            display: .init(removedNames: removedNames, leftoverNames: leftoverNames)
        )
    }

    /// Cleans a URL fragment: strips the spec scroll-to-text directive (everything
    /// from `:~:`) and any fragment-borne tracking params (matched against the same
    /// `removing` set as the query). A fragment is treated as parameters only when
    /// it is a *pure* `key=value(&…)` list (optionally `?`-prefixed) — a bare anchor
    /// (`#section`) or single-page-app route (`#/path`) has a `=`-less segment, so it
    /// is left entirely untouched. Returns `nil` when nothing meaningful remains.
    static func cleanFragment(
        _ fragment: String?,
        removing normalized: Set<String>
    ) -> (cleaned: String?, removedNames: [String], removedTextDirective: Bool) {
        guard let fragment, !fragment.isEmpty else { return (nil, [], false) }

        // Drop the text-fragment directive — everything from the spec delimiter
        // `:~:` onward. It is a browser highlight/scroll directive, never a
        // navigation anchor, and it leaks the quoted passage.
        var base = fragment
        var removedTextDirective = false
        if let directive = base.range(of: ":~:") {
            removedTextDirective = true
            base = String(base[..<directive.lowerBound])
        }
        guard !base.isEmpty else { return (nil, [], removedTextDirective) }

        // A fragment beginning with "/" is a single-page-app route (#/path),
        // never a tracking-param list — leave it untouched even when it carries a
        // "&key=value" tail, so client-side routing never breaks.
        guard !base.hasPrefix("/") else { return (base, [], removedTextDirective) }

        // Treat the remainder as parameters only when every `&`-segment is a
        // `key=value` pair; otherwise it is an anchor or SPA route — leave it be.
        let hasQueryPrefix = base.hasPrefix("?")
        let core = hasQueryPrefix ? String(base.dropFirst()) : base
        let segments = core.components(separatedBy: "&")
        guard !core.isEmpty, segments.allSatisfy({ $0.contains("=") }) else {
            return (base, [], removedTextDirective)
        }

        var removedNames: [String] = []
        var kept: [String] = []
        for segment in segments {
            let encodedKey = String(segment.prefix { $0 != "=" })
            let decodedKey = encodedKey.removingPercentEncoding ?? encodedKey
            if normalized.contains(decodedKey.lowercased()) {
                removedNames.append(decodedKey)
            } else {
                kept.append(segment)
            }
        }

        guard !removedNames.isEmpty else {
            // Nothing matched — preserve the fragment (minus any directive) verbatim.
            return (base, [], removedTextDirective)
        }
        let rebuilt = kept.joined(separator: "&")
        let cleaned = rebuilt.isEmpty ? nil : (hasQueryPrefix ? "?" + rebuilt : rebuilt)
        return (cleaned, removedNames, removedTextDirective)
    }

    /// The lowercased host of `urlString` for host-scoped rule matching, with
    /// any trailing root dot stripped; `nil` when no host can be parsed.
    /// Unlike ``analyticsDomain(from:)-(String)`` the `www.` prefix is kept —
    /// `TrackingParameterDefinition.appliesTo(host:)` suffix-matches, so
    /// `www.x.com` already matches an `x.com` rule. Never sent anywhere; this
    /// exists so every call site resolves `enabledParameters(forHost:)` from
    /// the same host string.
    public static func ruleHost(of urlString: String) -> String? {
        TrackingParameterCatalog.normalize(host: URLComponents(string: urlString)?.host)
    }

    /// `URL` overload of ``ruleHost(of:)-(String)`` for call sites that already
    /// hold a parsed `URL` (the action extensions).
    public static func ruleHost(of url: URL) -> String? {
        ruleHost(of: url.absoluteString)
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
