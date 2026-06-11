//
//  SettingsViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
import SwiftData
@testable import LinkClean
import LinkCleanCore
import LinkCleanData

@MainActor
struct SettingsViewModelTests {

    /// A `SettingsStore` over fresh isolated suites, plus handles to those suites
    /// so tests can seed/assert the underlying values.
    private func makeStore() -> (store: SettingsStore, standard: UserDefaults, appGroup: UserDefaults) {
        let stdName = "test.std.\(UUID().uuidString)"
        let grpName = "test.grp.\(UUID().uuidString)"
        let store = SettingsStore(standardSuiteName: stdName, appGroupSuiteName: grpName)
        return (store, UserDefaults(suiteName: stdName)!, UserDefaults(suiteName: grpName)!)
    }

    private func makeContext() -> ModelContext {
        ModelContext(HistoryContainer.makeInMemory())
    }

    @Test func initReadsStoredValues() {
        let (store, std, grp) = makeStore()
        std.set(false, forKey: SettingsKeys.autoPasteEnabled)
        grp.set(false, forKey: SettingsKeys.saveHistoryEnabled)

        let vm = SettingsViewModel(analytics: SpyAnalytics(), settings: store)

        #expect(vm.autoPasteEnabled == false)
        #expect(vm.saveHistoryEnabled == false)
    }

    @Test func defaultsAreEnabledWhenUnset() {
        let (store, _, _) = makeStore()
        let vm = SettingsViewModel(analytics: SpyAnalytics(), settings: store)

        #expect(vm.autoPasteEnabled == true)
        #expect(vm.saveHistoryEnabled == true)
    }

    @Test func setAutoPastePersistsAndSignals() {
        let (store, std, _) = makeStore()
        let spy = SpyAnalytics()
        let vm = SettingsViewModel(analytics: spy, settings: store)

        vm.setAutoPaste(false)

        #expect(vm.autoPasteEnabled == false)
        #expect(std.bool(forKey: SettingsKeys.autoPasteEnabled) == false)
        #expect(spy.events == [.settingsAutoPasteToggled(enabled: false)])
    }

    @Test func setAutoPasteIsNoOpWhenUnchanged() {
        let (store, _, _) = makeStore()
        let spy = SpyAnalytics()
        let vm = SettingsViewModel(analytics: spy, settings: store)

        vm.setAutoPaste(true) // already true

        #expect(spy.events.isEmpty)
    }

    @Test func enableSaveHistoryPersistsAndSignals() {
        let (store, _, grp) = makeStore()
        grp.set(false, forKey: SettingsKeys.saveHistoryEnabled)
        let spy = SpyAnalytics()
        let vm = SettingsViewModel(analytics: spy, settings: store)

        vm.enableSaveHistory()

        #expect(vm.saveHistoryEnabled == true)
        #expect(grp.bool(forKey: SettingsKeys.saveHistoryEnabled) == true)
        #expect(spy.events == [.settingsSaveHistoryToggled(enabled: true)])
    }

    @Test func disableSaveHistoryWipesEntriesAndSignalsToggle() {
        let (store, _, grp) = makeStore()
        let spy = SpyAnalytics()
        let vm = SettingsViewModel(analytics: spy, settings: store)
        let context = makeContext()
        context.insert(HistoryEntry(input: "https://x.com?a=1", output: "https://x.com"))
        try? context.save()

        vm.disableSaveHistory(in: context)

        #expect(vm.saveHistoryEnabled == false)
        #expect(grp.bool(forKey: SettingsKeys.saveHistoryEnabled) == false)
        // A single user action emits the toggle, not History.All.cleared.
        #expect(spy.events == [.settingsSaveHistoryToggled(enabled: false)])
        let remaining = try? context.fetch(FetchDescriptor<HistoryEntry>())
        #expect(remaining?.isEmpty == true)
    }

    @Test func onAppearSignalsScreenShown() {
        let (store, _, _) = makeStore()
        let spy = SpyAnalytics()
        let vm = SettingsViewModel(analytics: spy, settings: store)

        vm.onAppear()

        #expect(spy.events == [.settingsScreenShown])
    }

    @Test func clearHistoryWipesEntriesAndSignalsAllCleared() {
        let (store, _, _) = makeStore()
        let spy = SpyAnalytics()
        let vm = SettingsViewModel(analytics: spy, settings: store)
        let context = makeContext()
        context.insert(HistoryEntry(input: "https://x.com?a=1", output: "https://x.com"))
        try? context.save()

        vm.clearHistory(in: context)

        #expect(spy.events == [.historyAllCleared])
        let remaining = try? context.fetch(FetchDescriptor<HistoryEntry>())
        #expect(remaining?.isEmpty == true)
    }
}
