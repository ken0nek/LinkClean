//
//  AnalyticsService.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 6/8/26.
//

/// A typed analytics sink. The single `capture(_:)` entry point takes an
/// ``AnalyticsEvent``, so call sites can never invent signal names or parameter
/// keys — the entire taxonomy lives in ``AnalyticsEvent``.
///
/// All TelemetryDeck usage in the codebase is funnelled through conformers of
/// this protocol (see `TelemetryDeckAnalytics` in `LinkCleanAnalytics`); the app
/// and extension targets depend only on this typed API, never on the SDK
/// directly. Inject a spy in tests. See `docs/plans/analytics.md`.
///
/// `@MainActor`: every `capture(_:)` call site is main-actor-isolated (the
/// ViewModels, the extension host) and the test spy records on the main actor,
/// matching the app's MainActor-default isolation. The thread-safe
/// `TelemetryDeckAnalytics` satisfies it with a `nonisolated` implementation.
@MainActor
public protocol AnalyticsService: Sendable {
    func capture(_ event: AnalyticsEvent)
}
