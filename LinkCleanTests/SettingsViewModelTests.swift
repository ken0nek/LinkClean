//
//  SettingsViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
import SwiftData
@testable import LinkClean
import LinkCleanKit

@MainActor
struct SettingsViewModelTests {

    private func makeSuites() -> (standard: UserDefaults, appGroup: UserDefaults) {
        (UserDefaults(suiteName: "test.std.\(UUID().uuidString)")!,
         UserDefaults(suiteName: "test.grp.\(UUID().uuidString)")!)
    }

    private func makeContext() -> ModelContext {
        ModelContext(HistoryContainer.makeInMemory())
    }

    @Test func initReadsStoredValues() {
        let (std, grp) = makeSuites()
        std.set(false, forKey: SettingsKeys.autoPasteEnabled)
        grp.set(false, forKey: SettingsKeys.saveHistoryEnabled)

        let vm = SettingsViewModel(analytics: SpyAnalytics(), standardDefaults: std, appGroupDefaults: grp)

        #expect(vm.autoPasteEnabled == false)
        #expect(vm.saveHistoryEnabled == false)
    }

    @Test func defaultsAreEnabledWhenUnset() {
        let (std, grp) = makeSuites()
        let vm = SettingsViewModel(analytics: SpyAnalytics(), standardDefaults: std, appGroupDefaults: grp)

        #expect(vm.autoPasteEnabled == true)
        #expect(vm.saveHistoryEnabled == true)
    }

    @Test func setAutoPastePersistsAndSignals() {
        let (std, grp) = makeSuites()
        let spy = SpyAnalytics()
        let vm = SettingsViewModel(analytics: spy, standardDefaults: std, appGroupDefaults: grp)

        vm.setAutoPaste(false)

        #expect(vm.autoPasteEnabled == false)
        #expect(std.bool(forKey: SettingsKeys.autoPasteEnabled) == false)
        #expect(spy.events == [.settingsAutoPasteToggled(enabled: false)])
    }

    @Test func setAutoPasteIsNoOpWhenUnchanged() {
        let (std, grp) = makeSuites()
        let spy = SpyAnalytics()
        let vm = SettingsViewModel(analytics: spy, standardDefaults: std, appGroupDefaults: grp)

        vm.setAutoPaste(true) // already true

        #expect(spy.events.isEmpty)
    }

    @Test func enableSaveHistoryPersistsAndSignals() {
        let (std, grp) = makeSuites()
        grp.set(false, forKey: SettingsKeys.saveHistoryEnabled)
        let spy = SpyAnalytics()
        let vm = SettingsViewModel(analytics: spy, standardDefaults: std, appGroupDefaults: grp)

        vm.enableSaveHistory()

        #expect(vm.saveHistoryEnabled == true)
        #expect(grp.bool(forKey: SettingsKeys.saveHistoryEnabled) == true)
        #expect(spy.events == [.settingsSaveHistoryToggled(enabled: true)])
    }

    @Test func disableSaveHistoryWipesEntriesAndSignalsToggle() {
        let (std, grp) = makeSuites()
        let spy = SpyAnalytics()
        let vm = SettingsViewModel(analytics: spy, standardDefaults: std, appGroupDefaults: grp)
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

    @Test func clearHistoryWipesEntriesAndSignalsAllCleared() {
        let (std, grp) = makeSuites()
        let spy = SpyAnalytics()
        let vm = SettingsViewModel(analytics: spy, standardDefaults: std, appGroupDefaults: grp)
        let context = makeContext()
        context.insert(HistoryEntry(input: "https://x.com?a=1", output: "https://x.com"))
        try? context.save()

        vm.clearHistory(in: context)

        #expect(spy.events == [.historyAllCleared])
        let remaining = try? context.fetch(FetchDescriptor<HistoryEntry>())
        #expect(remaining?.isEmpty == true)
    }
}
