//
//  SpyAnalytics.swift
//  LinkCleanTestSupport
//

import Foundation
import LinkCleanCore

/// Test double for ``AnalyticsService`` that records captured events in order so
/// tests can assert which signals a ViewModel or pipeline emitted.
///
/// Shared across the package test suites (Core/Data/ExtensionUI) — one spy, not
/// a copy per suite. `public` so each `@testable`-free test target can construct
/// it; lives in the test-only `LinkCleanTestSupport` target, never shipped.
@MainActor
public final class SpyAnalytics: AnalyticsService {
    public private(set) var events: [AnalyticsEvent] = []

    public init() {}

    public func capture(_ event: AnalyticsEvent) {
        events.append(event)
    }

    /// Captured signal names, in order — convenience for coarse assertions.
    public var signalNames: [String] {
        events.map(\.signalName)
    }

    public func reset() {
        events.removeAll()
    }
}
