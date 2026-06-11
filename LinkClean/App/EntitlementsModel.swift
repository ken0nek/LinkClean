//
//  EntitlementsModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/9/26.
//

import Foundation
import LinkCleanCore
import LinkCleanAnalytics
import LinkCleanData
import Observation

/// A global, observable model of the user's current entitlement.
///
/// The source of truth for UI gating, injected into the environment at the app
/// root. Holds a **stored** `entitlement` updated from the service's stream —
/// never a computed property over external state (see the `@Observable` +
/// UserDefaults rule in `ARCHITECTURE.md`).
@MainActor
@Observable
final class EntitlementsModel: EntitlementsProviding {
    private(set) var entitlement: Entitlement = .free
    private let service: EntitlementsService
    private let analytics: AnalyticsService

    init(
        service: EntitlementsService,
        analytics: AnalyticsService = TelemetryDeckAnalytics()
    ) {
        self.service = service
        self.analytics = analytics
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

    /// Starts the purchase flow and emits the `Pro.Purchase.*` funnel facts from
    /// here — the layer that establishes each outcome — so ViewModels only render
    /// results and the funnel can't disagree across call sites. Reflects a
    /// completed entitlement immediately so gating updates without waiting on the
    /// stream to catch up.
    func purchase() async throws -> PurchaseOutcome {
        analytics.capture(.purchaseStarted)
        do {
            let outcome = try await service.purchase()
            switch outcome {
            case .completed(let entitlement):
                self.entitlement = entitlement
                // Synchronous completion only; an Ask-to-Buy/SCA approval arrives
                // later via the stream and is deliberately not re-counted here.
                analytics.capture(.purchaseCompleted)
            case .cancelled:
                analytics.capture(.purchaseFailed(reason: .cancelled))
            case .pending:
                analytics.capture(.purchaseFailed(reason: .pending))
            }
            return outcome
        } catch {
            analytics.capture(.purchaseFailed(reason: .storeError))
            throw error
        }
    }

    /// Restores previous purchases. Restore only ever *grants* Pro — it never
    /// downgrades, so a restore that resolves `.free` (wrong Apple ID signed in,
    /// transient StoreKit emptiness) can't yank access from a real owner. Genuine
    /// loss (a refund) flips the entitlement through the stream instead.
    ///
    /// Emits the single `Pro.Purchase.restored` funnel fact here — the layer that
    /// establishes the restore outcome — so the Paywall and Settings restore
    /// buttons render the result without each re-capturing (and risking drift). On
    /// a thrown StoreKit error the fact is recorded as `restored: false` before the
    /// error is rethrown for the caller's own alerting.
    @discardableResult
    func restorePurchases() async throws -> Entitlement {
        do {
            let entitlement = try await service.restorePurchases()
            if entitlement == .pro {
                self.entitlement = entitlement
            }
            analytics.capture(.purchaseRestored(restored: entitlement == .pro))
            return entitlement
        } catch {
            analytics.capture(.purchaseRestored(restored: false))
            throw error
        }
    }

    #if DEBUG
    private var debugOverrideStore: DebugEntitlementOverrideStore { DebugEntitlementOverrideStore() }

    /// The persisted developer override, or `nil` when resolving from StoreKit.
    var debugOverrideValue: Entitlement? {
        debugOverrideStore.override
    }

    /// Developer testing only. Persists an override the service resolver honors
    /// first (so it survives relaunch and the stream can't clobber it); `nil`
    /// clears it and re-resolves the real entitlement.
    func debugSetOverride(_ entitlement: Entitlement?) {
        debugOverrideStore.override = entitlement
        if let entitlement {
            EntitlementStore().save(entitlement)
            self.entitlement = entitlement
        } else {
            Task { self.entitlement = await service.refreshEntitlement() }
        }
    }
    #endif
}
