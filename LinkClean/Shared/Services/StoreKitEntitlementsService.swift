//
//  StoreKitEntitlementsService.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/10/26.
//

import Foundation
import LinkCleanKit
import OSLog
import StoreKit

/// StoreKit 2-backed ``EntitlementsService``. The only type in the app that
/// touches StoreKit purchasing; the paywall, gates, and `EntitlementStore` stay
/// engine-agnostic, so swapping to another billing backend later is one new
/// implementation of this protocol (see `docs/plans/iap-implementation-plan.md`).
///
/// LinkClean Pro is a single non-consumable, so StoreKit needs no server: the
/// device is the entitlement store of record (`Transaction.currentEntitlements`
/// syncs across the user's devices), restore is `AppStore.sync()`, and refunds
/// arrive on-device as a revocation through `Transaction.updates` — no App Store
/// Server Notifications, no receipt-validation backend.
final class StoreKitEntitlementsService: EntitlementsService {
    /// The non-consumable product ID — must match App Store Connect and
    /// `LinkClean.storekit`.
    static let lifetimeProductID = "linkclean_pro_lifetime"

    private let store: EntitlementStore
    private let analytics: AnalyticsService
    private let logger = Logger(subsystem: "com.ken0nek.LinkClean", category: "Entitlements")
    /// Transaction IDs already reported for revenue, so a foreground purchase
    /// isn't double-counted if it also echoes through `Transaction.updates`.
    /// In-memory (reset per launch) is enough — finished transactions aren't
    /// redelivered across launches.
    private var recordedTransactionIDs: Set<UInt64> = []

    init(
        analytics: AnalyticsService = TelemetryDeckAnalytics(),
        store: EntitlementStore = EntitlementStore()
    ) {
        self.analytics = analytics
        self.store = store
    }

    func currentEntitlement() -> Entitlement {
        store.current()
    }

    @discardableResult
    func refreshEntitlement() async -> Entitlement {
        await resolveAndCache()
    }

    func entitlementStream() -> AsyncStream<Entitlement> {
        AsyncStream { continuation in
            let task = Task {
                // Paint the live state immediately — covers launch, restore on a
                // new device, and refunds processed while the app was closed.
                continuation.yield(await self.resolveAndCache())
                // React to every future transaction change: purchase, ask-to-buy
                // approval, and refund/revocation (including off-device events).
                for await update in Transaction.updates {
                    if case .verified(let transaction) = update {
                        // Covers Ask-to-Buy / SCA approvals and purchases made on
                        // another device — the verified transaction lands here, not
                        // in the purchase() call that already returned `.pending`.
                        self.recordCompletedPurchase(transaction)
                        await transaction.finish()
                    }
                    continuation.yield(await self.resolveAndCache())
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func proProduct() async throws -> ProProduct? {
        guard let product = try await loadProduct() else { return nil }
        return ProProduct(
            id: product.id,
            displayName: product.displayName,
            localizedPrice: product.displayPrice,
            price: product.price
        )
    }

    func purchase() async throws -> PurchaseOutcome {
        guard let product = try await loadProduct() else {
            throw EntitlementsError.productUnavailable
        }
        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw EntitlementsError.unverified
            }
            await transaction.finish()
            recordCompletedPurchase(transaction)
            let entitlement = await resolveAndCache()
            logger.info("Purchase completed → \(entitlement.rawValue, privacy: .public)")
            return .completed(entitlement)
        case .userCancelled:
            return .cancelled
        case .pending:
            // Ask-to-Buy / Strong Customer Authentication: not an error — the
            // entitlement arrives later via `Transaction.updates`.
            return .pending
        @unknown default:
            return .cancelled
        }
    }

    func restorePurchases() async throws -> Entitlement {
        logger.info("Restoring purchases…")
        try await AppStore.sync()
        // Restore grants, never revokes: only persist a resolved `.pro` so a
        // restore against the wrong Apple ID (or a transient empty result) can't
        // overwrite a real owner's snapshot. Genuine loss (a refund) is a
        // revocation that arrives through `Transaction.updates` instead.
        let entitlement = await currentEntitlementFromStoreKit()
        if entitlement == .pro { store.save(entitlement) }
        logger.info("Restore complete → \(entitlement.rawValue, privacy: .public)")
        return entitlement
    }

    /// Recomputes the entitlement from StoreKit and persists it to the App Group
    /// snapshot the action extensions read.
    @discardableResult
    private func resolveAndCache() async -> Entitlement {
        let entitlement = await currentEntitlementFromStoreKit()
        store.save(entitlement)
        return entitlement
    }

    /// Records revenue for a newly completed Pro purchase, exactly once. Called
    /// from both the foreground `purchase()` and the `Transaction.updates` loop
    /// (Ask-to-Buy / SCA approvals, cross-device purchases); the seen-ID set keeps
    /// a transaction that surfaces in both paths from double-counting. The revenue
    /// preset (plan §3) is directional USD, blind to later refunds, and no-ops
    /// unless TelemetryDeck is initialized.
    private func recordCompletedPurchase(_ transaction: Transaction) {
        guard transaction.productID == Self.lifetimeProductID,
              transaction.revocationDate == nil,
              recordedTransactionIDs.insert(transaction.id).inserted else { return }
        analytics.recordPurchase(transaction: transaction)
    }

    /// `.pro` iff the user owns a verified, non-revoked lifetime transaction.
    /// Unverified or revoked entitlements resolve to `.free` (fail-closed). A
    /// DEBUG override (set from the Developer menu) is honored first, so it
    /// survives relaunch and the `Transaction.updates` stream can't clobber it.
    private func currentEntitlementFromStoreKit() async -> Entitlement {
        #if DEBUG
        if let override = Self.debugOverride() { return override }
        #endif
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.lifetimeProductID, transaction.revocationDate == nil {
                return .pro
            }
        }
        return .free
    }

    /// Loads the Pro product fresh from StoreKit. Deliberately uncached: a stored
    /// `Product` keeps a stale storefront price after the user changes App Store
    /// region, and StoreKit caches product metadata internally, so the refetch is
    /// cheap for an infrequently-opened paywall.
    private func loadProduct() async throws -> Product? {
        try await Product.products(for: [Self.lifetimeProductID]).first
    }

    #if DEBUG
    /// Developer entitlement override (Developer menu). Persisted so it survives
    /// relaunch; `nil` means "resolve from StoreKit" (the real path).
    static let debugOverrideKey = "debug.entitlementOverride"

    static func debugOverride() -> Entitlement? {
        guard let raw = UserDefaults.standard.string(forKey: debugOverrideKey) else { return nil }
        return Entitlement(rawValue: raw)
    }
    #endif
}
