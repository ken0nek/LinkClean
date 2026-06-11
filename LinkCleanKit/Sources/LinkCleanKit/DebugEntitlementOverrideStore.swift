//
//  DebugEntitlementOverrideStore.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 6/10/26.
//

#if DEBUG
import Foundation

/// Owns the developer entitlement-override key (Developer menu): a persisted
/// ``Entitlement`` the StoreKit resolver honors first, so it survives relaunch
/// and `Transaction.updates` can't clobber it. `nil`/absent means "resolve from
/// StoreKit" — the real path.
///
/// One owner of the key, consumed by both the StoreKit service (which reads it in
/// its resolver) and `EntitlementsModel` (which reads/writes it from the
/// Developer menu) — so neither has to know the other's storage. App-local
/// (`UserDefaults.standard`). DEBUG-only, like the menu that drives it.
public nonisolated struct DebugEntitlementOverrideStore: Sendable {
    private let suiteName: String?

    /// `nil` selects `UserDefaults.standard`.
    public init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    /// The persisted override, or `nil` when resolving from StoreKit. Setting
    /// `nil` clears the key.
    public var override: Entitlement? {
        get {
            defaults.string(forKey: SettingsKeys.debugEntitlementOverride)
                .flatMap(Entitlement.init(rawValue:))
        }
        nonmutating set {
            if let newValue {
                defaults.set(newValue.rawValue, forKey: SettingsKeys.debugEntitlementOverride)
            } else {
                defaults.removeObject(forKey: SettingsKeys.debugEntitlementOverride)
            }
        }
    }

    private var defaults: UserDefaults {
        suiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard
    }
}
#endif
