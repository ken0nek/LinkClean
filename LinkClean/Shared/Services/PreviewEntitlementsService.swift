//
//  PreviewEntitlementsService.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/10/26.
//

import Foundation
import LinkCleanKit

/// An offline ``EntitlementsService`` for SwiftUI previews — no StoreKit, no
/// network. Resolves to a fixed entitlement and a canned product. Not
/// DEBUG-gated, matching the codebase's other preview helpers (e.g.
/// `HistoryContainer.makeInMemory()`) so non-DEBUG `#Preview` blocks can use it.
struct PreviewEntitlementsService: EntitlementsService {
    var entitlement: Entitlement = .free

    func currentEntitlement() -> Entitlement { entitlement }

    func entitlementStream() -> AsyncStream<Entitlement> {
        AsyncStream { $0.finish() }
    }

    func refreshEntitlement() async -> Entitlement { entitlement }

    func proProduct() async throws -> ProProduct? {
        ProProduct(
            id: StoreKitEntitlementsService.lifetimeProductID,
            displayName: "LinkClean Pro",
            localizedPrice: "$4.99",
            price: 4.99
        )
    }

    func purchase() async throws -> PurchaseOutcome { .completed(.pro) }

    func restorePurchases() async throws -> Entitlement { entitlement }
}

extension EntitlementsModel {
    /// A free-tier preview model.
    static var preview: EntitlementsModel {
        EntitlementsModel(service: PreviewEntitlementsService())
    }

    /// A Pro-tier preview model.
    static var previewPro: EntitlementsModel {
        EntitlementsModel(service: PreviewEntitlementsService(entitlement: .pro))
    }
}
