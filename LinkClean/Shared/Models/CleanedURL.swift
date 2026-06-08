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

    /// Whether cleaning removed at least one tracking parameter.
    var changed: Bool { removedCount > 0 }

    init(
        id: UUID = UUID(),
        input: String,
        output: String,
        removedCount: Int = 0,
        leftoverCount: Int = 0,
        removedKindIDs: Set<String> = [],
        referenceMatches: [String] = []
    ) {
        self.id = id
        self.input = input
        self.output = output
        self.removedCount = removedCount
        self.leftoverCount = leftoverCount
        self.removedKindIDs = removedKindIDs
        self.referenceMatches = referenceMatches
    }
}
