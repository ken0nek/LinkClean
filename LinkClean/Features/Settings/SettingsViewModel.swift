//
//  SettingsViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/8/26.
//

import Foundation
import LinkCleanKit
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

    @ObservationIgnored private let analytics: AnalyticsService
    @ObservationIgnored private let settings: SettingsStore

    /// Outcome of a Restore Purchases tap, for the result alert.
    enum RestoreResult: Equatable {
        case restored
        case nothingToRestore
        case failed
    }

    init(
        analytics: AnalyticsService = TelemetryDeckAnalytics(),
        settings: SettingsStore = SettingsStore()
    ) {
        self.analytics = analytics
        self.settings = settings
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
    func disableSaveHistory(in context: ModelContext) {
        saveHistoryEnabled = false
        settings.saveHistoryEnabled = false
        try? context.delete(model: HistoryEntry.self)
        analytics.capture(.settingsSaveHistoryToggled(enabled: false))
    }

    func clearHistory(in context: ModelContext) {
        try? context.delete(model: HistoryEntry.self)
        analytics.capture(.historyAllCleared)
    }

    /// Restores previous purchases (App Review requires this reachable without
    /// buying — §9-D). Fires `Pro.Purchase.restored`; the entitlement flip itself
    /// is published by ``EntitlementsModel``.
    func restorePurchases(using entitlements: EntitlementsModel) async -> RestoreResult {
        isRestoring = true
        defer { isRestoring = false }
        do {
            let restored = try await entitlements.restorePurchases() == .pro
            analytics.capture(.purchaseRestored(restored: restored))
            return restored ? .restored : .nothingToRestore
        } catch {
            analytics.capture(.purchaseRestored(restored: false))
            return .failed
        }
    }
}
