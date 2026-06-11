//
//  SettingsViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/8/26.
//

import Foundation
import LinkCleanCore
import LinkCleanAnalytics
import LinkCleanData
import Observation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    /// Mirrors `SettingsKeys.autoPasteEnabled` (`UserDefaults.standard`).
    private(set) var autoPasteEnabled: Bool
    /// Mirrors `SettingsKeys.saveHistoryEnabled` (App Group suite; shared with
    /// the action extensions and the Home/History screens).
    private(set) var saveHistoryEnabled: Bool
    private(set) var isRestoring = false

    // MARK: - Support links

    /// Address opened by the Settings → Support → Contact row; the channel App
    /// Review and users use to reach the developer. Force-unwrapped: a fixed,
    /// known-valid literal (cf. `PaywallView`'s policy URLs).
    let contactURL = URL(string: "mailto:linkclean@ken0nek.com")!

    /// App Store "write a review" deep link for the Rate row. An explicit tap
    /// opens the review composer directly, unlike Apple's rate-limited
    /// `requestReview()` — which backs the automatic Home review gate and can
    /// silently no-op on demand. `6758604043` is LinkClean's App Store ID.
    let reviewURL = URL(string: "https://apps.apple.com/app/id6758604043?action=write-review")!

    @ObservationIgnored private let analytics: AnalyticsService
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let history: HistoryStore

    /// Outcome of a Restore Purchases tap, for the result alert.
    enum RestoreResult: Equatable {
        case restored
        case nothingToRestore
        case failed
    }

    init(
        analytics: AnalyticsService = TelemetryDeckAnalytics(),
        settings: SettingsStore = SettingsStore(),
        history: HistoryStore = .inMemoryPreview
    ) {
        self.analytics = analytics
        self.settings = settings
        self.history = history
        self.autoPasteEnabled = settings.autoPasteEnabled
        self.saveHistoryEnabled = settings.saveHistoryEnabled
    }

    /// `@Observable` doesn't track external `UserDefaults`, so re-read the stored
    /// values whenever the screen reappears — another surface (the Home
    /// auto-paste path, the extensions) may have changed them.
    func onAppear() {
        autoPasteEnabled = settings.autoPasteEnabled
        saveHistoryEnabled = settings.saveHistoryEnabled
        analytics.capture(.settingsScreenShown)
    }

    func setAutoPaste(_ enabled: Bool) {
        guard enabled != autoPasteEnabled else { return }
        autoPasteEnabled = enabled
        settings.autoPasteEnabled = enabled
        analytics.capture(.settingsAutoPasteToggled(enabled: enabled))
    }

    func enableSaveHistory() {
        guard !saveHistoryEnabled else { return }
        saveHistoryEnabled = true
        settings.saveHistoryEnabled = true
        analytics.capture(.settingsSaveHistoryToggled(enabled: true))
    }

    /// Disables history and wipes existing entries (the toggle's destructive
    /// confirm path). Fires the toggle signal — not `History.All.cleared` — so a
    /// single user action maps to a single primary signal.
    func disableSaveHistory() {
        saveHistoryEnabled = false
        settings.saveHistoryEnabled = false
        history.clearAll()
        analytics.capture(.settingsSaveHistoryToggled(enabled: false))
    }

    func clearHistory() {
        history.clearAll()
        analytics.capture(.historyAllCleared)
    }

    /// Restores previous purchases (App Review requires this reachable without
    /// buying — §9-D). The `Pro.Purchase.restored` funnel fact and the entitlement
    /// flip are both owned by ``EntitlementsModel``; this only maps the outcome to
    /// the result alert.
    func restorePurchases(using entitlements: EntitlementsModel) async -> RestoreResult {
        isRestoring = true
        defer { isRestoring = false }
        do {
            let restored = try await entitlements.restorePurchases() == .pro
            return restored ? .restored : .nothingToRestore
        } catch {
            return .failed
        }
    }
}
