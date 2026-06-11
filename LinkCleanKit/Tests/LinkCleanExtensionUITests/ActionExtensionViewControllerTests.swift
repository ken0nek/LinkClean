//
//  ActionExtensionViewControllerTests.swift
//  LinkCleanExtensionUITests
//

// LinkCleanExtensionUI links UIKit, so these tests compile and run only on the
// simulator (the sim lane). On the macOS fast lane (`swift test`) the module is
// absent and this target builds to an empty test bundle — see Package.swift.
#if canImport(UIKit)
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
#endif
