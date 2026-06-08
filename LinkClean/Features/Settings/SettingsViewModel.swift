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

    @ObservationIgnored private let analytics: AnalyticsService
    @ObservationIgnored private let standardDefaults: UserDefaults
    @ObservationIgnored private let appGroupDefaults: UserDefaults?

    init(
        analytics: AnalyticsService = TelemetryDeckAnalytics(),
        standardDefaults: UserDefaults = .standard,
        appGroupDefaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier)
    ) {
        self.analytics = analytics
        self.standardDefaults = standardDefaults
        self.appGroupDefaults = appGroupDefaults
        self.autoPasteEnabled = standardDefaults.object(forKey: SettingsKeys.autoPasteEnabled) as? Bool ?? true
        self.saveHistoryEnabled = appGroupDefaults?.object(forKey: SettingsKeys.saveHistoryEnabled) as? Bool ?? true
    }

    /// `@Observable` doesn't track external `UserDefaults`, so re-read the stored
    /// values whenever the screen reappears — another surface (the Home
    /// auto-paste path, the extensions) may have changed them.
    func onAppear() {
        autoPasteEnabled = standardDefaults.object(forKey: SettingsKeys.autoPasteEnabled) as? Bool ?? true
        saveHistoryEnabled = appGroupDefaults?.object(forKey: SettingsKeys.saveHistoryEnabled) as? Bool ?? true
    }

    func setAutoPaste(_ enabled: Bool) {
        guard enabled != autoPasteEnabled else { return }
        autoPasteEnabled = enabled
        standardDefaults.set(enabled, forKey: SettingsKeys.autoPasteEnabled)
        analytics.capture(.settingsAutoPasteToggled(enabled: enabled))
    }

    func enableSaveHistory() {
        guard !saveHistoryEnabled else { return }
        saveHistoryEnabled = true
        appGroupDefaults?.set(true, forKey: SettingsKeys.saveHistoryEnabled)
        analytics.capture(.settingsSaveHistoryToggled(enabled: true))
    }

    /// Disables history and wipes existing entries (the toggle's destructive
    /// confirm path). Fires the toggle signal — not `History.All.cleared` — so a
    /// single user action maps to a single primary signal.
    func disableSaveHistory(in context: ModelContext) {
        saveHistoryEnabled = false
        appGroupDefaults?.set(false, forKey: SettingsKeys.saveHistoryEnabled)
        try? context.delete(model: HistoryEntry.self)
        analytics.capture(.settingsSaveHistoryToggled(enabled: false))
    }

    func clearHistory(in context: ModelContext) {
        try? context.delete(model: HistoryEntry.self)
        analytics.capture(.historyAllCleared)
    }
}
