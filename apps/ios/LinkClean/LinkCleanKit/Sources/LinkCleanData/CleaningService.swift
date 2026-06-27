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

/// `nonisolated` like the stores it composes (``TrackingParameterStore`` /
/// ``SettingsStore``): a stateless value type with no MainActor state, so it can
/// be constructed and run from any isolation — the app and extensions (MainActor)
/// and the App Intents (which run nonisolated, off the main thread, for speed).
public nonisolated struct DefaultCleaningService: CleaningService {
    private let store: TrackingParameterStore
    private let settings: SettingsStore
    /// The network short-link resolver, or `nil` to keep this service fully offline.
    /// Wired only by surfaces that opted into the network — the app (always) and, in
    /// DEBUG, the extensions/intents. When `nil`, `expandShortLinksEnabled` has no
    /// effect: short links pass through to the offline pipeline unexpanded.
    private let resolver: (any ShortLinkResolving)?

    public init(
        store: TrackingParameterStore = TrackingParameterStore(),
        settings: SettingsStore = SettingsStore(),
        resolver: (any ShortLinkResolving)? = nil
    ) {
        self.store = store
        self.settings = settings
        self.resolver = resolver
    }

    public func isValidURL(_ input: String) -> Bool {
        URLCleaner.isValidURL(input)
    }

    public func clean(_ input: String, removingAlso extraParameters: Set<String>) async throws -> CleanOutcome? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, URLCleaner.isValidURL(trimmed) else {
            return nil
        }

        // E4: when the user opts in *and* this surface wired a network resolver,
        // resolve a short link (t.co, bit.ly, …) to its real destination before any
        // offline work, so the rest of the pipeline cleans the true URL. Fail-soft:
        // a failed or declined expand falls back to the original link. A non-nil
        // result means a network resolve actually fired — recorded as the outcome's
        // `expanded` telemetry so we can measure whether this (the app's only
        // network egress) earns its keep.
        let expansion = await expandedShortLink(from: trimmed)
        let working = expansion ?? trimmed

        // Peel known redirect wrappers first, then resolve rules against the
        // *destination's* host — not the wrapper's (a google.com/url?q=… link
        // must clean by the inner site's rules, e.g. youtube's t=/si=). The
        // peeled wrapper hosts ride along in the outcome's telemetry.
        let unwrap = URLCleaner.unwrap(working)
        let enabled = store.enabledParameters(forHost: URLCleaner.ruleHost(of: unwrap.destination))
            .union(extraParameters.map { $0.lowercased() })

        // The host the user actually pasted, surfaced when the real destination
        // lives elsewhere — a short link expanded (E4) or a redirect unwrapped (E1).
        // Compared on the normalized display host so casing / `www.` don't read as a
        // change; `nil` when the destination shares the arrival host. On-device only
        // (rides the outcome to History), never analytics.
        let arrivalHost = URLCleaner.analyticsDomain(from: trimmed)
        let destinationHost = URLCleaner.analyticsDomain(from: unwrap.destination)
        let arrivedFromHost = (arrivalHost != "unknown" && destinationHost != "unknown" && arrivalHost != destinationHost)
            ? arrivalHost
            : nil

        return URLCleaner.outcome(
            for: unwrap.destination,
            removing: enabled,
            wrappers: unwrap.wrappers,
            stripTextFragment: settings.removeTextFragmentsEnabled,
            expanded: expansion != nil,
            arrivedFromHost: arrivedFromHost
        )
    }

    /// The resolved destination of a short link, or `nil` to clean the input
    /// unchanged — when expansion is off, no resolver is wired, the host isn't a
    /// known shortener, or the network resolve failed. Never throws: expansion is
    /// additive and must never break a clean.
    private func expandedShortLink(from trimmed: String) async -> String? {
        guard settings.expandShortLinksEnabled,
              let resolver,
              let url = URL(string: trimmed),
              ShortenerCatalog.isShortener(host: url.host),
              let destination = await resolver.resolve(url)
        else {
            return nil
        }
        return destination.absoluteString
    }
}
