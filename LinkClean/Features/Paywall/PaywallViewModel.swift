//
//  PaywallViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/10/26.
//

import Foundation
import LinkCleanKit
import Observation

/// Drives the custom paywall: loads the Pro product, runs purchase/restore, and
/// fires the §9 funnel (`Paywall.Screen.shown` → `Pro.Purchase.*`). The trigger
/// that raised the sheet is carried for the impression signal only.
@MainActor
@Observable
final class PaywallViewModel {
    enum LoadState: Equatable {
        case loading
        case ready(ProProduct)
        case unavailable
    }

    private(set) var loadState: LoadState = .loading
    private(set) var isPurchasing = false
    /// Drives the "purchase failed" alert.
    var showPurchaseError = false
    /// Drives the Ask-to-Buy / SCA "pending approval" alert.
    var showPendingApproval = false
    /// Drives the "nothing to restore" alert.
    var showNothingToRestore = false
    /// Flips true on a completed purchase or a successful restore — the view
    /// dismisses on it.
    private(set) var didUnlock = false

    let trigger: AnalyticsEvent.PaywallTrigger
    @ObservationIgnored private let entitlements: EntitlementsModel
    @ObservationIgnored private let analytics: AnalyticsService

    init(
        entitlements: EntitlementsModel,
        analytics: AnalyticsService = TelemetryDeckAnalytics(),
        trigger: AnalyticsEvent.PaywallTrigger
    ) {
        self.entitlements = entitlements
        self.analytics = analytics
        self.trigger = trigger
    }

    /// Records the impression and loads the product. Call once, from `.task`.
    func onAppear() async {
        analytics.capture(.paywallShown(trigger: trigger))
        await loadProduct()
    }

    func loadProduct() async {
        loadState = .loading
        do {
            if let product = try await entitlements.proProduct() {
                loadState = .ready(product)
            } else {
                loadState = .unavailable
            }
        } catch {
            loadState = .unavailable
        }
    }

    func purchase() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        analytics.capture(.purchaseStarted)
        do {
            switch try await entitlements.purchase() {
            case .completed:
                analytics.capture(.purchaseCompleted)
                didUnlock = true
            case .cancelled:
                analytics.capture(.purchaseFailed(reason: .cancelled))
            case .pending:
                // Ask-to-Buy / SCA: the entitlement may arrive later. Reassure,
                // don't error.
                analytics.capture(.purchaseFailed(reason: .pending))
                showPendingApproval = true
            }
        } catch {
            analytics.capture(.purchaseFailed(reason: .storeError))
            showPurchaseError = true
        }
    }

    func restore() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        // The `Pro.Purchase.restored` funnel fact is emitted once by
        // ``EntitlementsModel`` (the layer that establishes the outcome); this
        // only renders the result.
        do {
            let restored = try await entitlements.restorePurchases() == .pro
            if restored {
                didUnlock = true
            } else {
                showNothingToRestore = true
            }
        } catch {
            showNothingToRestore = true
        }
    }
}
