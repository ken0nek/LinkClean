//
//  ActionExtensionViewControllerTests.swift
//  LinkCleanKitTests
//

import Testing
import Foundation
@testable import LinkCleanKit

@MainActor
struct ActionExtensionViewControllerTests {

    @Test func recordSuccessfulRunWritesTimestampToProvidedSuite() {
        let suite = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        let controller = ActionExtensionViewController()
        let date = Date(timeIntervalSinceReferenceDate: 12_345)

        controller.recordSuccessfulRun(at: date, in: suite)

        #expect(suite.double(forKey: SettingsKeys.lastActionExtensionRunAt) == 12_345)
    }

    @Test func recordSuccessfulRunUsesReferenceDateInterval() {
        let suite = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        let controller = ActionExtensionViewController()
        let date = Date(timeIntervalSinceReferenceDate: 1000)

        controller.recordSuccessfulRun(at: date, in: suite)

        // Stored value must be comparable as a plain interval, not a bridged Date.
        let stored = suite.double(forKey: SettingsKeys.lastActionExtensionRunAt)
        #expect(stored == date.timeIntervalSinceReferenceDate)
    }
}
