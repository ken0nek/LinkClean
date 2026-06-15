//
//  EntitlementsService.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/9/26.
//

import Foundation
import LinkCleanCore
import StoreKit

/// A lightweight, `Sendable` snapshot of the Pro product for the paywall. Keeps
/// StoreKit's `Product` behind the service boundary so the UI never imports the
/// purchasing engine.
struct ProProduct: Sendable, Equatable, Identifiable {
    let id: String
    let displayName: String
    /// Storefront-localized price string, e.g. "$4.99".
    let localizedPrice: String
    let price: Decimal
}

/// The outcome of a purchase attempt. A genuine store failure (or an unverified
/// transaction) is thrown; cancellation and Ask-to-Buy/SCA `pending` are calm,
/// non-error states the paywall reflects without an alert.
enum PurchaseOutcome: Sendable {
    case completed(Entitlement)
    case cancelled
    case pending
}

enum EntitlementsError: Error {
    /// The product could not be loaded (no StoreKit config / App Store Connect
    /// product, or offline).
    case productUnavailable
    /// StoreKit returned a transaction that failed JWS verification.
    case unverified
}

/// Manages and monitors the user's entitlement. The single abstraction over the
/// purchasing engine (StoreKit 2 today, via ``StoreKitEntitlementsService``) —
/// views and ViewModels depend only on this, never on StoreKit purchasing APIs.
protocol EntitlementsService: Sendable {
    /// The current entitlement from the local cache (fast, no `await`).
    func currentEntitlement() -> Entitlement

    /// A stream of entitlement updates (purchase, restore, refund/revocation).
    func entitlementStream() -> AsyncStream<Entitlement>

    /// Re-resolves the entitlement live from the store and re-caches it.
    @discardableResult
    func refreshEntitlement() async -> Entitlement

    /// The Pro product for display, or `nil` if it can't be loaded.
    func proProduct() async throws -> ProProduct?

    /// Starts the purchase flow for the Pro product.
    func purchase() async throws -> PurchaseOutcome

    /// Restores previous purchases and returns the resulting entitlement.
    func restorePurchases() async throws -> Entitlement
}

/// The small app-facing surface a paywall needs from ``EntitlementsModel`` —
/// product load, purchase, restore. ViewModels depend on this protocol rather
/// than the concrete model, so the paywall is testable against a stub (the one
/// ViewModel that previously couldn't take a double). The model keeps the stream
/// consumption and grant-only restore semantics as its real, un-abstracted job.
@MainActor
protocol EntitlementsProviding {
    func proProduct() async throws -> ProProduct?
    /// `trigger` is the gate that raised the paywall; it tags the `Pro.Purchase.*`
    /// funnel so conversion can be read per gate.
    func purchase(trigger: AnalyticsEvent.PaywallTrigger) async throws -> PurchaseOutcome
    @discardableResult
    func restorePurchases() async throws -> Entitlement
}
