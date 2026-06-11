//
//  ActionExtensionViewControllerTests.swift
//  LinkCleanKitTests
//

import Testing
import Foundation
@testable import LinkCleanCore
@testable import LinkCleanData
@testable import LinkCleanExtensionUI

@MainActor
struct ActionExtensionViewControllerTests {

    @Test func recordSuccessfulRunWritesTimestampToProvidedSuite() {
        let suiteName = "test.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        let controller = ActionExtensionViewController()
        let date = Date(timeIntervalSinceReferenceDate: 12_345)

        controller.recordSuccessfulRun(at: date, settings: SettingsStore(appGroupSuiteName: suiteName))

        #expect(suite.double(forKey: SettingsKeys.lastActionExtensionRunAt) == 12_345)
    }

    @Test func recordSuccessfulRunUsesReferenceDateInterval() {
        let suiteName = "test.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        let controller = ActionExtensionViewController()
        let date = Date(timeIntervalSinceReferenceDate: 1000)

        controller.recordSuccessfulRun(at: date, settings: SettingsStore(appGroupSuiteName: suiteName))

        // Stored value must be comparable as a plain interval, not a bridged Date.
        let stored = suite.double(forKey: SettingsKeys.lastActionExtensionRunAt)
        #expect(stored == date.timeIntervalSinceReferenceDate)
    }
}
