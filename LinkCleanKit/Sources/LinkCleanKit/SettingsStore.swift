//
//  SettingsStore.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 6/8/26.
//

import Foundation

/// Typed access to user settings, centralizing which `UserDefaults` suite owns
/// each key and its default-when-unset. Previously every ViewModel (and the
/// action-extension base class) hand-rolled `defaults.object(forKey:) as? Bool
/// ?? true` against the right suite; this is the single source of that truth.
///
/// `autoPaste` is app-local (`UserDefaults.standard`); `saveHistory` is shared
/// with the action extensions via the App Group suite. Stores suite *names* (not
/// `UserDefaults`, which isn't `Sendable`) and resolves them lazily, matching
/// ``TrackingParameterStore``. Suite names are injectable for tests.
public nonisolated struct SettingsStore: Sendable {
    /// `nil` selects `UserDefaults.standard`.
    private let standardSuiteName: String?
    /// `nil` disables the App Group-backed settings.
    private let appGroupSuiteName: String?

    public init(
        standardSuiteName: String? = nil,
        appGroupSuiteName: String? = AppGroup.identifier
    ) {
        self.standardSuiteName = standardSuiteName
        self.appGroupSuiteName = appGroupSuiteName
    }

    public var autoPasteEnabled: Bool {
        get { standard.object(forKey: SettingsKeys.autoPasteEnabled) as? Bool ?? true }
        nonmutating set { standard.set(newValue, forKey: SettingsKeys.autoPasteEnabled) }
    }

    public var saveHistoryEnabled: Bool {
        get { appGroup?.object(forKey: SettingsKeys.saveHistoryEnabled) as? Bool ?? true }
        nonmutating set { appGroup?.set(newValue, forKey: SettingsKeys.saveHistoryEnabled) }
    }

    private var standard: UserDefaults {
        standardSuiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard
    }

    private var appGroup: UserDefaults? {
        appGroupSuiteName.flatMap { UserDefaults(suiteName: $0) }
    }
}
