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

        public init(
            changed: Bool,
            removedCount: Int,
            leftoverCount: Int,
            removedKindIDs: Set<String>,
            referenceMatches: [String],
            domain: String
        ) {
            self.changed = changed
            self.removedCount = removedCount
            self.leftoverCount = leftoverCount
            self.removedKindIDs = removedKindIDs
            self.referenceMatches = referenceMatches
            self.domain = domain
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

    public init(input: String, cleaned: String, telemetry: Telemetry, display: Display) {
        self.input = input
        self.cleaned = cleaned
        self.telemetry = telemetry
        self.display = display
    }
}
