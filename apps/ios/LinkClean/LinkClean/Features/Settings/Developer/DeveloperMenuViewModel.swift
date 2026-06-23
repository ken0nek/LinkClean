//
//  DeveloperMenuViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/7/26.
//

#if DEBUG
import Foundation
import LinkCleanCore
import LinkCleanData
import Observation
import SwiftData

/// Backs the DEBUG-only developer menu. Reads each persisted value for display
/// and removes them individually so the app's stored state can be reset while
/// testing (e.g. re-triggering onboarding by clearing `hasCompletedOnboarding`).
@MainActor
@Observable
final class DeveloperMenuViewModel {
    private(set) var autoPaste = "—"
    private(set) var onboardingCompleted = "—"
    private(set) var saveHistory = "—"
    private(set) var lastExtensionRun = "—"
    private(set) var disabledParameters = "—"
    private(set) var customParameters = "—"
    private(set) var historyCount = "—"
    /// DEBUG-only mirror of ``SettingsStore/expandShortLinksOutOfAppDebugEnabled`` —
    /// the developer switch that wires the network resolver into the App Intents
    /// (the action extension already expands in release).
    private(set) var expandShortLinksOutOfApp = false
    /// DEBUG-only mirror of ``SettingsStore/parameterAdvisorDebugEnabled`` — the
    /// developer switch that wires the Foundation Models parameter advisor so the
    /// Home suggestion card surfaces (hidden from users; Release never shows it).
    private(set) var parameterAdvisorEnabled = false

    @ObservationIgnored private let parameterStore = TrackingParameterStore()
    @ObservationIgnored private let settings = SettingsStore()
    @ObservationIgnored private var modelContext: ModelContext?

    private var standard: UserDefaults { .standard }
    private var appGroup: UserDefaults? { UserDefaults(suiteName: AppGroup.identifier) }

    func setModelContext(_ context: ModelContext) {
        modelContext = context
        refresh()
    }

    func refresh() {
        autoPaste = describeBool(standard.object(forKey: SettingsKeys.autoPasteEnabled))
        onboardingCompleted = describeBool(standard.object(forKey: SettingsKeys.hasCompletedOnboarding))
        saveHistory = describeBool(appGroup?.object(forKey: SettingsKeys.saveHistoryEnabled))
        lastExtensionRun = describeDate(appGroup?.object(forKey: SettingsKeys.lastActionExtensionRunAt))
        disabledParameters = "\(parameterStore.disabledParameterNames().count) disabled"
        customParameters = "\(parameterStore.customParameters().count) custom"
        historyCount = "\(fetchHistoryCount()) entries"
        expandShortLinksOutOfApp = settings.expandShortLinksOutOfAppDebugEnabled
        parameterAdvisorEnabled = settings.parameterAdvisorDebugEnabled
    }

    /// Toggles whether the App Intents also wire the network short-link resolver
    /// (DEBUG-only; the Settings → Expand Short Links opt-in must also be on for an
    /// actual expand to happen).
    func setExpandShortLinksOutOfApp(_ enabled: Bool) {
        settings.expandShortLinksOutOfAppDebugEnabled = enabled
        expandShortLinksOutOfApp = enabled
    }

    /// Toggles whether the Foundation Models parameter advisor is wired so the Home
    /// suggestion card surfaces (DEBUG-only; the card is hidden from users in a
    /// shipped build). Takes effect on the next launch, since the advisor is built
    /// once at the composition root.
    func setParameterAdvisorEnabled(_ enabled: Bool) {
        settings.parameterAdvisorDebugEnabled = enabled
        parameterAdvisorEnabled = enabled
    }

    // MARK: - Per-value resets

    func resetAutoPaste() {
        standard.removeObject(forKey: SettingsKeys.autoPasteEnabled)
        refresh()
    }

    func resetOnboarding() {
        standard.removeObject(forKey: SettingsKeys.hasCompletedOnboarding)
        refresh()
    }

    func resetSaveHistory() {
        appGroup?.removeObject(forKey: SettingsKeys.saveHistoryEnabled)
        refresh()
    }

    func resetLastExtensionRun() {
        appGroup?.removeObject(forKey: SettingsKeys.lastActionExtensionRunAt)
        refresh()
    }

    func resetDefaultParameters() {
        parameterStore.resetDefaultParameterOverrides()
        refresh()
    }

    func clearCustomParameters() {
        parameterStore.removeAllCustomParameters()
        refresh()
    }

    func clearHistory() {
        try? modelContext?.delete(model: HistoryEntry.self)
        refresh()
    }

    func resetEverything() {
        resetAutoPaste()
        resetSaveHistory()
        resetLastExtensionRun()
        resetDefaultParameters()
        clearCustomParameters()
        clearHistory()
        setExpandShortLinksOutOfApp(false)
        setParameterAdvisorEnabled(false)
        // Reset onboarding last — clearing it flips ContentView to the
        // onboarding flow, which tears this screen down.
        resetOnboarding()
    }

    // MARK: - Formatting

    private func describeBool(_ value: Any?) -> String {
        switch value {
        case nil: return "unset"
        case let bool as Bool: return bool ? "true" : "false"
        default: return String(describing: value!)
        }
    }

    private func describeDate(_ value: Any?) -> String {
        guard let interval = value as? Double else { return "unset" }
        return Date(timeIntervalSinceReferenceDate: interval)
            .formatted(date: .abbreviated, time: .standard)
    }

    private func fetchHistoryCount() -> Int {
        guard let modelContext else { return 0 }
        return (try? modelContext.fetchCount(FetchDescriptor<HistoryEntry>())) ?? 0
    }
}
#endif
