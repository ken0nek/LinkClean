//
//  MockURLCleaningService.swift
//  LinkCleanTests
//

import Foundation
@testable import LinkClean
import LinkCleanCommon

@MainActor
struct MockURLCleaningService: URLCleaningService {
    var isValidURLHandler: @Sendable (String) -> Bool = { _ in true }
    var cleanHandler: @MainActor (String) async throws -> CleanedURL? = { input in
        CleanedURL(input: input, output: input)
    }

    func isValidURL(_ input: String) -> Bool {
        isValidURLHandler(input)
    }

    func clean(_ input: String) async throws -> CleanedURL? {
        try await cleanHandler(input)
    }
}

struct MockLinkMetadataService: LinkMetadataService {
    func fetchMetadata(for url: URL) async -> (title: String?, thumbnailData: Data?) {
        (nil, nil)
    }
}
