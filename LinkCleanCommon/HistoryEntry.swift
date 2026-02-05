//
//  HistoryEntry.swift
//  LinkCleanCommon
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation
import SwiftData

@Model
public final class HistoryEntry {
    public var id: UUID
    public var input: String
    public var output: String
    public var createdAt: Date

    public init(id: UUID = UUID(), input: String, output: String, createdAt: Date = .now) {
        self.id = id
        self.input = input
        self.output = output
        self.createdAt = createdAt
    }
}
