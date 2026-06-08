//
//  CleanedURL.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation

struct CleanedURL: Identifiable, Equatable {
    let id: UUID
    let input: String
    let output: String
    /// Number of tracking parameters removed in producing `output`. Carried from
    /// the cleaner so analytics needn't re-parse the URL to count.
    let removedCount: Int
    /// Privacy-safe catalog-gap analysis, carried from the cleaner (see
    /// `CleanResult` / `parameter-telemetry.md`). `referenceMatches` holds only
    /// public reference-catalog names.
    let leftoverCount: Int
    let removedKindIDs: Set<String>
    let referenceMatches: [String]
    /// Exact names of the parameters removed in producing `output`, for the
    /// Home "removed" transparency display. Display-only and on-device — unlike
    /// the fields above, these are raw query-key names, so they must never be
    /// routed into an analytics event (which uses the name-free `CleanResult`).
    let removedNames: [String]
    /// Exact names of the parameters that survived cleaning, for the Home
    /// "remaining" pills. Same rule as `removedNames`: raw query keys, display-
    /// only and on-device, never routed into analytics. (Telemetry still sees
    /// only `referenceMatches` — the public-catalog subset.)
    let leftoverNames: [String]

    /// Whether cleaning removed at least one tracking parameter.
    var changed: Bool { removedCount > 0 }

    init(
        id: UUID = UUID(),
        input: String,
        output: String,
        removedCount: Int = 0,
        leftoverCount: Int = 0,
        removedKindIDs: Set<String> = [],
        referenceMatches: [String] = [],
        removedNames: [String] = [],
        leftoverNames: [String] = []
    ) {
        self.id = id
        self.input = input
        self.output = output
        self.removedCount = removedCount
        self.leftoverCount = leftoverCount
        self.removedKindIDs = removedKindIDs
        self.referenceMatches = referenceMatches
        self.removedNames = removedNames
        self.leftoverNames = leftoverNames
    }
}
