//
//  SettingsKeys.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/4/26.
//

public nonisolated enum SettingsKeys {
    public static let autoPasteEnabled = "autoPasteEnabled"
    public static let saveHistoryEnabled = "saveHistoryEnabled"

    /// Whether the user has finished (or skipped) the first-launch onboarding.
    /// App-only: stored in `UserDefaults.standard`.
    public static let hasCompletedOnboarding = "hasCompletedOnboarding"

    /// Reference-date timestamp of the most recent successful action-extension
    /// run. Cross-process: written by the extension, read by the app's
    /// onboarding/guide "Try it" flow. Stored in the App Group suite.
    public static let lastActionExtensionRunAt = "lastActionExtensionRunAt"

    /// Stable anonymous identifier shared by the app and both action extensions
    /// so TelemetryDeck attributes their signals to one user (the activation
    /// funnel spans app + extension). Generated once, stored in the App Group
    /// suite. See `docs/plans/analytics.md` §4.
    public static let analyticsUserIdentifier = "analyticsUserIdentifier"

    /// The current cached entitlement (free/pro). Stored in the App Group suite
    /// so action extensions can read it.
    public static let currentEntitlement = "currentEntitlement"
}
