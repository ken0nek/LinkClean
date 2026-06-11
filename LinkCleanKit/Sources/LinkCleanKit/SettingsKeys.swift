//
//  SettingsKeys.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/4/26.
//

/// The single registry of every `UserDefaults` key LinkClean persists. Defaults
/// are this app's IPC bus between three processes (app + two action extensions),
/// so the cross-process contract — *which key lives in which suite, who writes
/// it, who reads it* — is recorded here in one place rather than reconstructed by
/// grepping. Prefer the typed ``SettingsStore`` facade over raw access; the keys
/// stay public for the few stores that own their own slice (``TrackingParameterStore``,
/// ``EntitlementStore``, ``DefaultReviewService``) and for `@AppStorage` reads
/// that need live reactivity in a view.
///
/// | Key | Suite | Writer(s) | Reader(s) |
/// |-----|-------|-----------|-----------|
/// | `autoPasteEnabled` | standard | `SettingsStore` (Settings toggle, screenshot prep) | `SettingsStore` (Home/Settings) |
/// | `saveHistoryEnabled` | App Group | `SettingsStore` (Settings toggle, screenshot prep) | `SettingsStore` (Home/History/Settings, extensions) |
/// | `hasCompletedOnboarding` | standard | `SettingsStore` / `@AppStorage` (onboarding finish, debug config) | `ContentView` (`@AppStorage`), `DeveloperMenu` |
/// | `lastActionExtensionRunAt` | App Group | `SettingsStore` (extensions, on success) | `SettingsStore` (`ExtensionGuideViewModel`), `DeveloperMenu` |
/// | `analyticsUserIdentifier` | App Group | `TelemetryDeckAnalytics` | `TelemetryDeckAnalytics` |
/// | `currentEntitlement` | App Group | `EntitlementStore` | `EntitlementStore` (extensions) |
/// | `trackingParametersDisabled` | App Group | `TrackingParameterStore` | `TrackingParameterStore` |
/// | `trackingParametersEnabled` | App Group | `TrackingParameterStore` | `TrackingParameterStore` |
/// | `trackingParametersCustom` | App Group | `TrackingParameterStore` | `TrackingParameterStore` |
/// | `review.successCount` | App Group | `DefaultReviewService` | `DefaultReviewService` |
/// | `review.firstSuccessAt` | App Group | `DefaultReviewService` | `DefaultReviewService` |
/// | `review.lastPromptAt` | App Group | `DefaultReviewService` | `DefaultReviewService` |
/// | `review.debug.forceShow` (DEBUG) | App Group | `DefaultReviewService`, debug config | `DefaultReviewService` |
/// | `debug.entitlementOverride` (DEBUG) | standard | `DebugEntitlementOverrideStore` | `DebugEntitlementOverrideStore` (StoreKit service, `EntitlementsModel`) |
/// | `screenshotFixtures` (DEBUG) | standard | external (capture-script launch arg) | `SettingsStore` (`DebugLaunchConfigurator`) |
public nonisolated enum SettingsKeys {

    // MARK: App settings

    /// Whether Home auto-pastes a URL from the clipboard. App-only: stored in
    /// `UserDefaults.standard`.
    public static let autoPasteEnabled = "autoPasteEnabled"

    /// Whether cleaned links are recorded to History. Cross-process: written from
    /// Settings, read by the app and both action extensions. Stored in the App
    /// Group suite.
    public static let saveHistoryEnabled = "saveHistoryEnabled"

    /// Whether the user has finished (or skipped) the first-launch onboarding.
    /// App-only: stored in `UserDefaults.standard`.
    public static let hasCompletedOnboarding = "hasCompletedOnboarding"

    // MARK: Cross-process state

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

    // MARK: Tracking parameters (App Group suite, owned by `TrackingParameterStore`)

    /// User-disabled catalog parameter names (deviations from the shipped-on
    /// default). Kept disjoint from ``trackingParametersEnabled``.
    public static let trackingParametersDisabled = "trackingParametersDisabled"

    /// User opt-ins for catalog names that ship `enabledByDefault: false`.
    public static let trackingParametersEnabled = "trackingParametersEnabled"

    /// User-added custom parameter names (stripped on every site).
    public static let trackingParametersCustom = "trackingParametersCustom"

    // MARK: Review gate (App Group suite, owned by `DefaultReviewService`)

    /// Count of distinct cleaned URLs copied or shared since the last prompt.
    public static let reviewSuccessCount = "review.successCount"

    /// Epoch timestamp of the first-ever export (first-write-wins; the span clock).
    public static let reviewFirstSuccessAt = "review.firstSuccessAt"

    /// Epoch timestamp the in-app review prompt was last shown (the cooldown clock).
    public static let reviewLastPromptAt = "review.lastPromptAt"

    #if DEBUG
    /// Forces the review prompt eligible regardless of counters (QA / screenshots
    /// via `-forceReviewGate`). DEBUG-only.
    public static let reviewDebugForceShow = "review.debug.forceShow"

    /// Developer entitlement override (Developer menu); `nil`/absent resolves from
    /// StoreKit. App-only: stored in `UserDefaults.standard`. DEBUG-only.
    public static let debugEntitlementOverride = "debug.entitlementOverride"

    /// Directory of pre-fetched History thumbnail fixtures, passed by the
    /// screenshot capture script as a launch arg. App-only. DEBUG-only.
    public static let screenshotFixtures = "screenshotFixtures"
    #endif
}
