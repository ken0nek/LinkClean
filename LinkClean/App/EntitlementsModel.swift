//
//  EntitlementsModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/9/26.
//

import Foundation
import LinkCleanKit
import Observation

/// A global, observable model of the user's current entitlement.
///
/// The source of truth for UI gating, injected into the environment at the app
/// root. Holds a **stored** `entitlement` updated from the service's stream —
/// never a computed property over external state (see the `@Observable` +
/// UserDefaults rule in `ARCHITECTURE.md`).
@MainActor
@Observable
final class EntitlementsModel {
    private(set) var entitlement: Entitlement = .free
    private let service: EntitlementsService

    init(service: EntitlementsService) {
        self.service = service
        self.entitlement = service.currentEntitlement()

        let stream = service.entitlementStream()
        Task { [weak self] in
            for await newEntitlement in stream {
                self?.entitlement = newEntitlement
            }
        }
    }

    /// The Pro product for the paywall, or `nil` if it can't be loaded yet.
    func proProduct() async throws -> ProProduct? {
        try await service.proProduct()
    }

    /// Starts the purchase flow. Reflects a completed entitlement immediately so
    /// gating updates without waiting on the stream to catch up.
    func purchase() async throws -> PurchaseOutcome {
        let outcome = try await service.purchase()
        if case .completed(let entitlement) = outcome {
            self.entitlement = entitlement
        }
        return outcome
    }

    /// Restores previous purchases. Restore only ever *grants* Pro — it never
    /// downgrades, so a restore that resolves `.free` (wrong Apple ID signed in,
    /// transient StoreKit emptiness) can't yank access from a real owner. Genuine
    /// loss (a refund) flips the entitlement through the stream instead.
    @discardableResult
    func restorePurchases() async throws -> Entitlement {
        let entitlement = try await service.restorePurchases()
        if entitlement == .pro {
            self.entitlement = entitlement
        }
        return entitlement
    }

    #if DEBUG
    /// The persisted developer override, or `nil` when resolving from StoreKit.
    var debugOverrideValue: Entitlement? {
        guard let raw = UserDefaults.standard.string(forKey: StoreKitEntitlementsService.debugOverrideKey) else {
            return nil
        }
        return Entitlement(rawValue: raw)
    }

    /// Developer testing only. Persists an override the service resolver honors
    /// first (so it survives relaunch and the stream can't clobber it); `nil`
    /// clears it and re-resolves the real entitlement.
    func debugSetOverride(_ entitlement: Entitlement?) {
        if let entitlement {
            UserDefaults.standard.set(entitlement.rawValue, forKey: StoreKitEntitlementsService.debugOverrideKey)
            EntitlementStore().save(entitlement)
            self.entitlement = entitlement
        } else {
            UserDefaults.standard.removeObject(forKey: StoreKitEntitlementsService.debugOverrideKey)
            Task { self.entitlement = await service.refreshEntitlement() }
        }
    }
    #endif
}
