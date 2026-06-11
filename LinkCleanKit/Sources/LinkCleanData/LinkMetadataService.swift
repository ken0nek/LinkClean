//
//  LinkMetadataService.swift
//  LinkCleanData
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation
import LinkPresentation
import UniformTypeIdentifiers

/// Fetches a link's title and thumbnail via `LPMetadataProvider`. Lives in
/// `LinkCleanData` so the app's History enrichment and the Markdown action
/// extension share one fetcher instead of each wrapping `LPMetadataProvider`.
public nonisolated protocol LinkMetadataService: Sendable {
    func fetchMetadata(for url: URL) async -> (title: String?, thumbnailData: Data?)
}

public nonisolated struct DefaultLinkMetadataService: LinkMetadataService {
    public init() {}

    public func fetchMetadata(for url: URL) async -> (title: String?, thumbnailData: Data?) {
        let provider = LPMetadataProvider()
        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            let title = metadata.title
            var imageData = await loadImageData(from: metadata.imageProvider)
            if imageData == nil {
                imageData = await loadImageData(from: metadata.iconProvider)
            }
            return (title, imageData)
        } catch {
            return (nil, nil)
        }
    }

    private func loadImageData(from itemProvider: NSItemProvider?) async -> Data? {
        guard let itemProvider else { return nil }
        return try? await withCheckedThrowingContinuation { continuation in
            _ = itemProvider.loadDataRepresentation(for: UTType.image) { data, error in
                if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: error ?? URLError(.cannotDecodeContentData))
                }
            }
        }
    }
}
