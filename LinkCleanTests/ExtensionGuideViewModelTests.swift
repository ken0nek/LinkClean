//
//  ExtensionGuideViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
import SwiftUI
@testable import LinkClean
import LinkCleanKit

@MainActor
struct ExtensionGuideViewModelTests {

    private func makeSuite() -> UserDefaults {
        UserDefaults(suiteName: "test.\(UUID().uuidString)")!
    }

    private let start = Date(timeIntervalSinceReferenceDate: 1000)

    @Test func startsIdle() {
        let vm = ExtensionGuideViewModel(defaults: makeSuite(), now: { self.start })

        #expect(vm.state == .idle)
        #expect(vm.isIdleOrWaiting == true)
        #expect(vm.hasSucceeded == false)
    }

    @Test func tryItTappedMovesToWaiting() {
        let vm = ExtensionGuideViewModel(defaults: makeSuite(), now: { self.start })

        vm.tryItTapped()

        #expect(vm.isWaiting == true)
        #expect(vm.isIdleOrWaiting == true)
        vm.reset()
    }

    @Test func staysWaitingWithNoTimestamp() {
        let vm = ExtensionGuideViewModel(defaults: makeSuite(), now: { self.start })

        vm.tryItTapped()
        vm.handleScenePhase(.active)

        #expect(vm.isWaiting == true)
        vm.reset()
    }

    @Test func staysWaitingForStaleTimestamp() {
        let suite = makeSuite()
        // A run that happened before "Try it" was tapped must not count.
        suite.set(Date(timeIntervalSinceReferenceDate: 500).timeIntervalSinceReferenceDate,
                  forKey: SettingsKeys.lastActionExtensionRunAt)
        let vm = ExtensionGuideViewModel(defaults: suite, now: { self.start })

        vm.tryItTapped()
        vm.handleScenePhase(.active)

        #expect(vm.isWaiting == true)
        vm.reset()
    }

    @Test func succeedsForNewerTimestampOnSceneActive() {
        let suite = makeSuite()
        let vm = ExtensionGuideViewModel(defaults: suite, now: { self.start })

        vm.tryItTapped()
        suite.set(Date(timeIntervalSinceReferenceDate: 1001).timeIntervalSinceReferenceDate,
                  forKey: SettingsKeys.lastActionExtensionRunAt)
        vm.handleScenePhase(.active)

        #expect(vm.state == .succeeded)
        #expect(vm.hasSucceeded == true)
        #expect(vm.isIdleOrWaiting == false)
    }

    @Test func nonActiveScenePhaseIsNoOp() {
        let suite = makeSuite()
        let vm = ExtensionGuideViewModel(defaults: suite, now: { self.start })

        vm.tryItTapped()
        suite.set(Date(timeIntervalSinceReferenceDate: 1001).timeIntervalSinceReferenceDate,
                  forKey: SettingsKeys.lastActionExtensionRunAt)

        vm.handleScenePhase(.background)
        #expect(vm.isWaiting == true)

        vm.handleScenePhase(.inactive)
        #expect(vm.isWaiting == true)

        vm.handleScenePhase(.active)
        #expect(vm.hasSucceeded == true)
    }

    @Test func resetReturnsToIdle() {
        let vm = ExtensionGuideViewModel(defaults: makeSuite(), now: { self.start })

        vm.tryItTapped()
        vm.reset()

        #expect(vm.state == .idle)
    }

    @Test func successDoesNotRequireScenePhaseWhenAlreadyChecked() {
        // Once succeeded, a later active phase keeps it succeeded (idempotent).
        let suite = makeSuite()
        let vm = ExtensionGuideViewModel(defaults: suite, now: { self.start })

        vm.tryItTapped()
        suite.set(Date(timeIntervalSinceReferenceDate: 1001).timeIntervalSinceReferenceDate,
                  forKey: SettingsKeys.lastActionExtensionRunAt)
        vm.handleScenePhase(.active)
        vm.handleScenePhase(.active)

        #expect(vm.hasSucceeded == true)
    }
}
