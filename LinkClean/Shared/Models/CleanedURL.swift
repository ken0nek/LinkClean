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

    /// Whether cleaning removed at least one tracking parameter.
    var changed: Bool { removedCount > 0 }

    init(id: UUID = UUID(), input: String, output: String, removedCount: Int = 0) {
        self.id = id
        self.input = input
        self.output = output
        self.removedCount = removedCount
    }
}
