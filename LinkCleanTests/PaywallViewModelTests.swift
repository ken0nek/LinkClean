//
//  PaywallViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
@testable import LinkClean
import LinkCleanKit

@MainActor
struct PaywallViewModelTests {

    /// Configurable ``EntitlementsService`` double — no StoreKit.
    @MainActor
    final class StubEntitlementsService: EntitlementsService {
        var entitlement: Entitlement = .free
        var product: ProProduct? = ProProduct(
            id: "linkclean_pro_lifetime", displayName: "LinkClean Pro",
            localizedPrice: "$4.99", price: 4.99
        )
        var purchaseOutcome: PurchaseOutcome = .completed(.pro)
        var purchaseError: Error?
        var restoreEntitlement: Entitlement = .pro
        var restoreError: Error?

        func currentEntitlement() -> Entitlement { entitlement }
        func entitlementStream() -> AsyncStream<Entitlement> { AsyncStream { $0.finish() } }
        func refreshEntitlement() async -> Entitlement { entitlement }
        func proProduct() async throws -> ProProduct? { product }
        func purchase() async throws -> PurchaseOutcome {
            if let purchaseError { throw purchaseError }
            return purchaseOutcome
        }
        func restorePurchases() async throws -> Entitlement {
            if let restoreError { throw restoreError }
            return restoreEntitlement
        }
    }

    private struct StubError: Error {}

    private func makeSUT(
        trigger: AnalyticsEvent.PaywallTrigger = .settingsRow,
        configure: (StubEntitlementsService) -> Void = { _ in }
    ) -> (PaywallViewModel, SpyAnalytics) {
        let stub = StubEntitlementsService()
        configure(stub)
        // One spy shared by both layers: the paywall VM emits the impression and
        // purchase funnel, the model emits the single `Pro.Purchase.restored` fact.
        let spy = SpyAnalytics()
        let model = EntitlementsModel(service: stub, analytics: spy)
        let vm = PaywallViewModel(entitlements: model, analytics: spy, trigger: trigger)
        return (vm, spy)
    }

    @Test func onAppearFiresImpressionAndLoadsProduct() async {
        let (vm, spy) = makeSUT(trigger: .historyArchive)
        await vm.onAppear()
        #expect(spy.events.contains(.paywallShown(trigger: .historyArchive)))
        guard case .ready(let product) = vm.loadState else {
            Issue.record("expected .ready, got \(vm.loadState)")
            return
        }
        #expect(product.localizedPrice == "$4.99")
    }

    @Test func unavailableWhenNoProduct() async {
        let (vm, _) = makeSUT { $0.product = nil }
        await vm.onAppear()
        #expect(vm.loadState == .unavailable)
    }

    @Test func purchaseSuccessFiresFunnelAndUnlocks() async {
        let (vm, spy) = makeSUT { $0.purchaseOutcome = .completed(.pro) }
        await vm.purchase()
        #expect(spy.signalNames.contains("Pro.Purchase.started"))
        #expect(spy.signalNames.contains("Pro.Purchase.completed"))
        #expect(vm.didUnlock)
    }

    @Test func purchaseCancelledReportsCancelled() async {
        let (vm, spy) = makeSUT { $0.purchaseOutcome = .cancelled }
        await vm.purchase()
        #expect(spy.events.contains(.purchaseFailed(reason: .cancelled)))
        #expect(vm.didUnlock == false)
    }

    @Test func purchasePendingShowsApproval() async {
        let (vm, spy) = makeSUT { $0.purchaseOutcome = .pending }
        await vm.purchase()
        #expect(spy.events.contains(.purchaseFailed(reason: .pending)))
        #expect(vm.showPendingApproval)
        #expect(vm.didUnlock == false)
    }

    @Test func purchaseErrorReportsStoreError() async {
        let (vm, spy) = makeSUT { $0.purchaseError = StubError() }
        await vm.purchase()
        #expect(spy.events.contains(.purchaseFailed(reason: .storeError)))
        #expect(vm.showPurchaseError)
        #expect(vm.didUnlock == false)
    }

    @Test func restoreSuccessUnlocks() async {
        let (vm, spy) = makeSUT { $0.restoreEntitlement = .pro }
        await vm.restore()
        #expect(spy.events.contains(.purchaseRestored(restored: true)))
        #expect(vm.didUnlock)
    }

    @Test func restoreNothingShowsAlert() async {
        let (vm, spy) = makeSUT { $0.restoreEntitlement = .free }
        await vm.restore()
        #expect(spy.events.contains(.purchaseRestored(restored: false)))
        #expect(vm.showNothingToRestore)
        #expect(vm.didUnlock == false)
    }
}
