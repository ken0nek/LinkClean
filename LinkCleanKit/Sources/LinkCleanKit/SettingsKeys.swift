//
//  SettingsKeys.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/4/26.
//

public enum SettingsKeys {
    public static let autoPasteEnabled = "autoPasteEnabled"
    public static let saveHistoryEnabled = "saveHistoryEnabled"

    /// Whether the user has finished (or skipped) the first-launch onboarding.
    /// App-only: stored in `UserDefaults.standard`.
    public static let hasCompletedOnboarding = "hasCompletedOnboarding"

    /// Reference-date timestamp of the most recent successful action-extension
    /// run. Cross-process: written by the extension, read by the app's
    /// onboarding/guide "Try it" flow. Stored in the App Group suite.
    public static let lastActionExtensionRunAt = "lastActionExtensionRunAt"
}
