//
//  SettingsStoreTests.swift
//  LinkCleanDataTests
//
//  Created by Ken Tominaga on 6/17/26.
//

import Testing
import Foundation
@testable import LinkCleanData

struct SettingsStoreTests {

    /// E4 is the app's only network egress, so the toggle must ship **off**: an
    /// unset suite reads `false`.
    @Test func expandShortLinksDefaultsToFalseWhenUnset() {
        let suiteName = "LinkCleanKitTests.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }
        let settings = SettingsStore(appGroupSuiteName: suiteName)
        #expect(settings.expandShortLinksEnabled == false)
    }

    /// The toggle lives in the App Group suite so the extensions and App Intents
    /// read what the app wrote: a fresh store over the same suite sees the value.
    @Test func expandShortLinksPersistsThroughTheAppGroupSuite() {
        let suiteName = "LinkCleanKitTests.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }
        SettingsStore(appGroupSuiteName: suiteName).expandShortLinksEnabled = true
        #expect(SettingsStore(appGroupSuiteName: suiteName).expandShortLinksEnabled)
    }
}
