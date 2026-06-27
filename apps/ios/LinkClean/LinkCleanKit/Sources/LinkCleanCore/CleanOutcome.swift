//
//  CleanOutcome.swift
//  LinkCleanCore
//
//  Created by Ken Tominaga on 6/11/26.
//

import Foundation

/// Everything one clean produces, in a single value built in one pass over the
/// query items (see ``URLCleaner/outcome(for:removing:referenceNames:)``). The
/// privacy boundary is expressed as two nested types instead of doc comments:
///
/// - ``Telemetry`` is the *only* shape an ``AnalyticsEvent`` accepts. By
///   construction it carries no raw query-key names — only finite, public values
///   (counts, kind ids, reference-catalog names, the site domain).
/// - ``Display`` carries the raw removed/leftover key names for the on-device
///   transparency UI. Nothing in ``AnalyticsEvent`` accepts a `Display`, so a
///   raw name cannot reach analytics without a deliberate, reviewable conversion.
///
/// That makes the project's strongest invariant — *raw names never leave the
/// device* — a compile-time guarantee rather than a convention.
public struct CleanOutcome: Sendable, Equatable {
    /// The trimmed input that was cleaned.
    public let input: String
    /// The cleaned URL string (equal to `input` when nothing was removed).
    public let cleaned: String

    /// The host the link *arrived* as when the real destination sits elsewhere — a
    /// short link expanded (E4) or a redirect unwrapped (E1), e.g. `"bit.ly"`.
    /// Already normalized for display (lowercased, `www.`-stripped, via
    /// ``URLCleaner/analyticsDomain(from:)-(String)``). `nil` when the input and
    /// destination share a host. On-device only — it rides to History and, like
    /// ``input``/``cleaned``, is never part of ``Telemetry``, so it cannot reach
    /// analytics.
    public let arrivedFromHost: String?

    /// The analytics-safe view of a clean — the only part an ``AnalyticsEvent``
    /// can accept. No raw query-key names, by construction.
    public struct Telemetry: Sendable, Equatable {
        /// Whether cleaning removed at least one tracking parameter.
        public let changed: Bool
        /// Number of tracking parameters removed.
        public let removedCount: Int
        /// Number of query *items* remaining after cleaning (duplicates counted).
        /// Sizes the gap between our catalog and the trackers in real URLs
        /// (`parameter-telemetry.md` Tier 0).
        public let leftoverCount: Int
        /// Catalog kind ids that fired in this clean (a finite, known set —
        /// `parameter-telemetry.md` Tier 0). Safe to send.
        public let removedKindIDs: Set<String>
        /// Leftover names that match the bundled reference catalog — known
        /// trackers missing from our defaults (`parameter-telemetry.md` Tier 1).
        /// Sorted, unique; all *public* names, never user-authored or arbitrary
        /// URL keys.
        public let referenceMatches: [String]
        /// The link's host for site-popularity analytics, via
        /// ``URLCleaner/analyticsDomain(from:)-(String)`` — the one URL-derived
        /// value sent (`analytics.md` §3). `"unknown"` when no host parses.
        public let domain: String
        /// The redirect wrappers peeled before this clean, outermost first — e.g.
        /// `["google.com"]` for a `google.com/url?q=…` link (see
        /// ``URLCleaner/unwrap(_:maxDepth:)``). Canonical public wrapper domains,
        /// the same risk class as `domain` and safe to send; empty when the input
        /// was not a wrapper. This is the *offline* (E1) signal — set independently
        /// of ``expanded``.
        public let wrappers: [String]
        /// Whether a short link (`bit.ly`, `t.co`, …) was resolved over the network
        /// to its destination before this clean (E4). The app's only network egress,
        /// so this is the load-bearing signal for whether that opt-in cost earns its
        /// keep: paired with `changed` / `removedCount` it answers *when expansion
        /// fires, does the clean then find trackers?* — value the `domain` alone
        /// can't show, since after expansion `domain` is the destination host, not
        /// the shortener. A bool, never the resolved URL (§3); `false` unless a
        /// network resolve actually yielded a destination.
        public let expanded: Bool

        public init(
            changed: Bool,
            removedCount: Int,
            leftoverCount: Int,
            removedKindIDs: Set<String>,
            referenceMatches: [String],
            domain: String,
            wrappers: [String] = [],
            expanded: Bool = false
        ) {
            self.changed = changed
            self.removedCount = removedCount
            self.leftoverCount = leftoverCount
            self.removedKindIDs = removedKindIDs
            self.referenceMatches = referenceMatches
            self.domain = domain
            self.wrappers = wrappers
            self.expanded = expanded
        }
    }
    public let telemetry: Telemetry

    /// On-device display only. These are raw query keys (potentially arbitrary
    /// or sensitive), so nothing in ``AnalyticsEvent`` accepts this type — they
    /// exist only to show the user their own link on Home.
    public struct Display: Sendable, Equatable {
        /// Exact names removed in producing `cleaned`, first-seen order,
        /// de-duplicated case-insensitively with the first case preserved.
        public let removedNames: [String]
        /// Exact names that survived cleaning, same ordering/dedup contract.
        public let leftoverNames: [String]

        public init(removedNames: [String], leftoverNames: [String]) {
            self.removedNames = removedNames
            self.leftoverNames = leftoverNames
        }
    }
    public let display: Display

    public init(input: String, cleaned: String, telemetry: Telemetry, display: Display, arrivedFromHost: String? = nil) {
        self.input = input
        self.cleaned = cleaned
        self.telemetry = telemetry
        self.display = display
        self.arrivedFromHost = arrivedFromHost
    }
}
