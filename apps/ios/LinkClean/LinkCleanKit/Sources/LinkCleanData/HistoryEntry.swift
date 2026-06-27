//
//  HistoryEntry.swift
//  LinkCleanKit
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
    public var pageTitle: String?
    public var thumbnailData: Data?
    public var metadataFetchAttempted: Bool = false
    /// The host the link arrived as when the real destination sits elsewhere — a
    /// short link expanded or a redirect unwrapped (e.g. `"bit.ly"`); `nil` when the
    /// pasted link and its cleaned destination share a host. Optional with a `nil`
    /// default, so it is a lightweight SwiftData migration. On-device only.
    public var arrivedFromHost: String?

    public init(id: UUID = UUID(), input: String, output: String, createdAt: Date = .now, pageTitle: String? = nil, thumbnailData: Data? = nil, metadataFetchAttempted: Bool = false, arrivedFromHost: String? = nil) {
        self.id = id
        self.input = input
        self.output = output
        self.createdAt = createdAt
        self.pageTitle = pageTitle
        self.thumbnailData = thumbnailData
        self.metadataFetchAttempted = metadataFetchAttempted
        self.arrivedFromHost = arrivedFromHost
    }
}
