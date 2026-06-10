//
//  SpyAnalytics.swift
//  LinkCleanTests
//

import Foundation
import LinkCleanKit
import StoreKit

/// Test double for ``AnalyticsService`` that records captured events in order so
/// tests can assert which signals a ViewModel emitted.
@MainActor
final class SpyAnalytics: AnalyticsService {
    private(set) var events: [AnalyticsEvent] = []

    func capture(_ event: AnalyticsEvent) {
        events.append(event)
    }

    func recordPurchase(transaction: Transaction) {
        // No-op for now in spy
    }

    /// Captured signal names, in order — convenience for coarse assertions.
    var signalNames: [String] {
        events.map(\.signalName)
    }

    func reset() {
        events.removeAll()
    }
}
