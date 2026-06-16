//
//  StubLinkMetadataService.swift
//  LinkCleanTestSupport
//

import Foundation
import LinkCleanData

/// Offline ``LinkMetadataService`` for tests: returns a canned title/thumbnail
/// without touching the network, so the Markdown strategy and History
/// enrichment can be exercised deterministically.
public struct StubLinkMetadataService: LinkMetadataService {
    public var title: String?
    public var thumbnailData: Data?

    public init(title: String? = nil, thumbnailData: Data? = nil) {
        self.title = title
        self.thumbnailData = thumbnailData
    }

    public func fetchMetadata(for url: URL) async -> (title: String?, thumbnailData: Data?) {
        (title, thumbnailData)
    }
}
