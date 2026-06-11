//
//  URLCleaningService.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation
import LinkCleanCore
import LinkCleanData

protocol URLCleaningService: Sendable {
    func isValidURL(_ input: String) -> Bool
    /// Cleans `input` with the user's enabled parameters plus `extraParameters`
    /// — transient, caller-owned removals (the "remove once" pill path) that are
    /// never persisted to the store.
    func clean(_ input: String, removingAlso extraParameters: Set<String>) async throws -> CleanedURL?
}

extension URLCleaningService {
    func clean(_ input: String) async throws -> CleanedURL? {
        try await clean(input, removingAlso: [])
    }
}

struct DefaultURLCleaningService: URLCleaningService {
    private let store: TrackingParameterStore

    init(store: TrackingParameterStore = TrackingParameterStore()) {
        self.store = store
    }

    func isValidURL(_ input: String) -> Bool {
        URLCleaner.isValidURL(input)
    }

    func clean(_ input: String, removingAlso extraParameters: Set<String>) async throws -> CleanedURL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        guard isValidURL(trimmed) else {
            return nil
        }

        let enabled = store.enabledParameters(forHost: URLCleaner.ruleHost(of: trimmed))
            .union(extraParameters.map { $0.lowercased() })
        let result = URLCleaner.cleanResult(trimmed, removing: enabled)
        return CleanedURL(
            input: trimmed,
            output: result.cleaned,
            removedCount: result.removedCount,
            leftoverCount: result.leftoverCount,
            removedKindIDs: result.removedKindIDs,
            referenceMatches: result.referenceMatches,
            removedNames: URLCleaner.removedParameterNames(trimmed, removing: enabled),
            leftoverNames: URLCleaner.leftoverParameterNames(trimmed, removing: enabled)
        )
    }
}
