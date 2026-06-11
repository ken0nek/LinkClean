//
//  SettingsStore.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 6/8/26.
//

import Foundation

/// The typed facade over every user-facing setting, centralizing which
/// `UserDefaults` suite owns each key and its default-when-unset. Previously
/// every ViewModel (and the action-extension base class) hand-rolled
/// `defaults.object(forKey:) as? Bool ?? true` against the right suite; this is
/// the single source of that truth, and every *write* of a setting goes through
/// it (views needing live reactivity still read via `@AppStorage` on the same
/// ``SettingsKeys`` constant).
///
/// `autoPaste`, `hasCompletedOnboarding` (and the DEBUG `screenshotFixturesPath`)
/// are app-local (`UserDefaults.standard`); `saveHistory` and
/// `lastActionExtensionRunAt` are shared with the action extensions via the App
/// Group suite. See ``SettingsKeys`` for the full key → suite → writer → reader
/// table. Stores suite *names* (not `UserDefaults`, which isn't `Sendable`) and
/// resolves them lazily, matching ``TrackingParameterStore``. Suite names are
/// injectable for tests.
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

    /// Whether first-launch onboarding is complete. Defaults to `false` when
    /// unset, matching `ContentView`'s `@AppStorage` read of the same key.
    public var hasCompletedOnboarding: Bool {
        get { standard.bool(forKey: SettingsKeys.hasCompletedOnboarding) }
        nonmutating set { standard.set(newValue, forKey: SettingsKeys.hasCompletedOnboarding) }
    }

    /// When the most recent action-extension clean succeeded — the signal the
    /// onboarding/guide "Try it" flow watches. Stored as a reference-date interval
    /// (the cross-process format readers compare against); `nil` when never run.
    public var lastActionExtensionRunAt: Date? {
        get {
            let interval = appGroup?.double(forKey: SettingsKeys.lastActionExtensionRunAt) ?? 0
            return interval == 0 ? nil : Date(timeIntervalSinceReferenceDate: interval)
        }
        nonmutating set {
            appGroup?.set(newValue?.timeIntervalSinceReferenceDate ?? 0, forKey: SettingsKeys.lastActionExtensionRunAt)
        }
    }

    #if DEBUG
    /// Directory of History thumbnail fixtures the screenshot capture script
    /// passes via `-screenshotFixtures`. Read-only; written externally as a
    /// launch-argument default. DEBUG-only.
    public var screenshotFixturesPath: String? {
        standard.string(forKey: SettingsKeys.screenshotFixtures)
    }
    #endif

    private var standard: UserDefaults {
        standardSuiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard
    }

    private var appGroup: UserDefaults? {
        appGroupSuiteName.flatMap { UserDefaults(suiteName: $0) }
    }
}
