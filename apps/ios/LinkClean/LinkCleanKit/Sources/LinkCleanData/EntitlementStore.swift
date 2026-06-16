//
//  EntitlementStore.swift
//  LinkCleanKit
//
//  Created by Gemini CLI on 6/9/26.
//

import Foundation
import LinkCleanCore

/// A persistent, cross-process snapshot of the user's current entitlement.
///
/// Written by the app target (via the StoreKit entitlements service) and read by both
/// the app and the action extensions. This allows the extensions to gate
/// features without the overhead or network requirement of the full SDK.
public nonisolated struct EntitlementStore: Sendable {
    private let suiteName: String?

    public init(suiteName: String? = AppGroup.identifier) {
        self.suiteName = suiteName
    }

    /// The current cached entitlement.
    ///
    /// If the record is missing or contains an unknown value, this returns
    /// `.free` (fail-closed).
    public func current() -> Entitlement {
        guard let rawValue = defaults.string(forKey: SettingsKeys.currentEntitlement),
              let entitlement = Entitlement(rawValue: rawValue) else {
            return .free
        }
        return entitlement
    }

    /// Persists a new entitlement snapshot to the shared suite.
    public func save(_ entitlement: Entitlement) {
        defaults.set(entitlement.rawValue, forKey: SettingsKeys.currentEntitlement)
    }

    private var defaults: UserDefaults {
        guard let suiteName, let defaults = UserDefaults(suiteName: suiteName) else {
            return .standard
        }
        return defaults
    }
}
