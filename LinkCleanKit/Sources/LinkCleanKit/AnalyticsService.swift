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
/// this protocol (see ``TelemetryDeckAnalytics``); the app and extension targets
/// depend only on this typed API, never on the SDK directly. Inject a spy in
/// tests. See `docs/plans/analytics.md`.
public protocol AnalyticsService: Sendable {
    func capture(_ event: AnalyticsEvent)
}
