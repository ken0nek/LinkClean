//
//  CleaningService.swift
//  LinkCleanData
//
//  Created by Ken Tominaga on 6/11/26.
//

import Foundation
import LinkCleanCore

/// The one place that composes the user's parameter rules with the cleaner:
/// peel any known redirect wrapper (``URLCleaner/unwrap(_:maxDepth:)``) so the
/// real destination is cleaned, resolve *that host's* enabled set from the
/// ``TrackingParameterStore``, fold in any transient extras, and run
/// ``URLCleaner/outcome(for:removing:)`` — yielding a single ``CleanOutcome``.
/// Lives in `LinkCleanData` so the app **and both action extensions** share it
/// instead of each hand-rolling unwrap + `enabledParameters(forHost:)` +
/// `URLCleaner.outcome`.
public protocol CleaningService: Sendable {
    func isValidURL(_ input: String) -> Bool
    /// Cleans `input` with the user's enabled parameters plus `extraParameters` —
    /// transient, caller-owned removals (the "remove once" pill path) that are
    /// never persisted to the store. Returns `nil` for empty / non-web input.
    func clean(_ input: String, removingAlso extraParameters: Set<String>) async throws -> CleanOutcome?
}

public extension CleaningService {
    func clean(_ input: String) async throws -> CleanOutcome? {
        try await clean(input, removingAlso: [])
    }
}

public struct DefaultCleaningService: CleaningService {
    private let store: TrackingParameterStore

    public init(store: TrackingParameterStore = TrackingParameterStore()) {
        self.store = store
    }

    public func isValidURL(_ input: String) -> Bool {
        URLCleaner.isValidURL(input)
    }

    public func clean(_ input: String, removingAlso extraParameters: Set<String>) async throws -> CleanOutcome? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, URLCleaner.isValidURL(trimmed) else {
            return nil
        }

        // Peel known redirect wrappers first, then resolve rules against the
        // *destination's* host — not the wrapper's (a google.com/url?q=… link
        // must clean by the inner site's rules, e.g. youtube's t=/si=).
        let unwrapped = URLCleaner.unwrap(trimmed).destination
        let enabled = store.enabledParameters(forHost: URLCleaner.ruleHost(of: unwrapped))
            .union(extraParameters.map { $0.lowercased() })
        return URLCleaner.outcome(for: unwrapped, removing: enabled)
    }
}
