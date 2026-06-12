//
//  MockCleaningService.swift
//  LinkCleanTests
//

import Foundation
@testable import LinkClean
import LinkCleanCore
import LinkCleanData

@MainActor
struct MockCleaningService: CleaningService {
    var isValidURLHandler: @Sendable (String) -> Bool = { _ in true }
    var cleanHandler: @MainActor (String) async throws -> CleanOutcome? = { input in
        .stub(input: input, cleaned: input)
    }

    func isValidURL(_ input: String) -> Bool {
        isValidURLHandler(input)
    }

    func clean(_ input: String, removingAlso extraParameters: Set<String>) async throws -> CleanOutcome? {
        try await cleanHandler(input)
    }
}

extension CleanOutcome {
    /// Test convenience: build an outcome from the handful of fields a Home test
    /// asserts on. `changed` is derived (`removedCount > 0`) and `domain` from
    /// `input` (via `analyticsDomain`), mirroring what `URLCleaner.outcome`
    /// produces, so a stubbed outcome's telemetry matches the real pipeline's.
    static func stub(
        input: String,
        cleaned: String,
        removedCount: Int = 0,
        leftoverCount: Int = 0,
        removedKindIDs: Set<String> = [],
        referenceMatches: [String] = [],
        removedNames: [String] = [],
        leftoverNames: [String] = [],
        wrappers: [String] = []
    ) -> CleanOutcome {
        CleanOutcome(
            input: input,
            cleaned: cleaned,
            telemetry: .init(
                changed: removedCount > 0,
                removedCount: removedCount,
                leftoverCount: leftoverCount,
                removedKindIDs: removedKindIDs,
                referenceMatches: referenceMatches,
                domain: URLCleaner.analyticsDomain(from: input),
                wrappers: wrappers
            ),
            display: .init(removedNames: removedNames, leftoverNames: leftoverNames)
        )
    }
}

struct MockLinkMetadataService: LinkMetadataService {
    func fetchMetadata(for url: URL) async -> (title: String?, thumbnailData: Data?) {
        (nil, nil)
    }
}
