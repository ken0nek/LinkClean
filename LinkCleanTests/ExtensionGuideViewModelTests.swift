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

    private func isWaiting(_ vm: ExtensionGuideViewModel) -> Bool {
        if case .waitingForExtension = vm.state { return true }
        return false
    }

    private let start = Date(timeIntervalSinceReferenceDate: 1000)

    private func runTimestamp(_ interval: Double, in suite: UserDefaults) {
        suite.set(interval, forKey: SettingsKeys.lastActionExtensionRunAt)
    }

    @Test func startsIdle() {
        let vm = ExtensionGuideViewModel(defaults: makeSuite(), now: { self.start })

        #expect(vm.state == .idle)
        #expect(vm.isIdleOrWaiting == true)
        #expect(vm.hasSucceeded == false)
    }

    @Test func tryItTappedMovesToWaiting() {
        let vm = ExtensionGuideViewModel(defaults: makeSuite(), now: { self.start })

        vm.tryItTapped()

        #expect(isWaiting(vm) == true)
        #expect(vm.isIdleOrWaiting == true)
        vm.reset()
    }

    @Test func staysWaitingWithNoTimestamp() {
        let vm = ExtensionGuideViewModel(defaults: makeSuite(), now: { self.start })

        vm.tryItTapped()
        vm.handleScenePhase(.active)

        #expect(isWaiting(vm) == true)
        vm.reset()
    }

    @Test func staysWaitingForStaleTimestamp() {
        let suite = makeSuite()
        // A run that happened before "Try it" was tapped must not count.
        runTimestamp(Date(timeIntervalSinceReferenceDate: 500).timeIntervalSinceReferenceDate, in: suite)
        let vm = ExtensionGuideViewModel(defaults: suite, now: { self.start })

        vm.tryItTapped()
        vm.handleScenePhase(.active)

        #expect(isWaiting(vm) == true)
        vm.reset()
    }

    @Test func succeedsForNewerTimestampOnSceneActive() {
        let suite = makeSuite()
        let vm = ExtensionGuideViewModel(defaults: suite, now: { self.start })

        vm.tryItTapped()
        runTimestamp(Date(timeIntervalSinceReferenceDate: 1001).timeIntervalSinceReferenceDate, in: suite)
        vm.handleScenePhase(.active)

        #expect(vm.state == .succeeded)
        #expect(vm.hasSucceeded == true)
        #expect(vm.isIdleOrWaiting == false)
    }

    @Test func succeedsWithoutTryItTapWhenArmedOnAppear() {
        // Detection is armed on appear, so a run is caught even if the
        // ShareLink tap gesture never fired.
        let suite = makeSuite()
        let vm = ExtensionGuideViewModel(defaults: suite, now: { self.start })

        vm.onAppear(source: .settings)
        runTimestamp(Date(timeIntervalSinceReferenceDate: 1001).timeIntervalSinceReferenceDate, in: suite)
        vm.handleScenePhase(.active)

        #expect(vm.hasSucceeded == true)
        vm.reset()
    }

    @Test func nonActiveScenePhaseIsNoOp() {
        let suite = makeSuite()
        let vm = ExtensionGuideViewModel(defaults: suite, now: { self.start })

        vm.tryItTapped()
        runTimestamp(Date(timeIntervalSinceReferenceDate: 1001).timeIntervalSinceReferenceDate, in: suite)

        vm.handleScenePhase(.background)
        #expect(isWaiting(vm) == true)

        vm.handleScenePhase(.inactive)
        #expect(isWaiting(vm) == true)

        vm.handleScenePhase(.active)
        #expect(vm.hasSucceeded == true)
    }

    @Test func resetReturnsToIdle() {
        let vm = ExtensionGuideViewModel(defaults: makeSuite(), now: { self.start })

        vm.tryItTapped()
        vm.reset()

        #expect(vm.state == .idle)
    }

    @Test func successIsIdempotentAcrossScenePhases() {
        let suite = makeSuite()
        let vm = ExtensionGuideViewModel(defaults: suite, now: { self.start })

        vm.tryItTapped()
        runTimestamp(Date(timeIntervalSinceReferenceDate: 1001).timeIntervalSinceReferenceDate, in: suite)
        vm.handleScenePhase(.active)
        vm.handleScenePhase(.active)

        #expect(vm.hasSucceeded == true)
    }

    @Test func onAppearFromSettingsEmitsGuideShownWithSource() {
        let spy = SpyAnalytics()
        let vm = ExtensionGuideViewModel(defaults: makeSuite(), now: { self.start }, analytics: spy)

        vm.onAppear(source: .settings)

        #expect(spy.events == [.onboardingExtensionGuideShown(source: .settings)])
        vm.reset()
    }

    @Test func onAppearFromOnboardingTagsSource() {
        let spy = SpyAnalytics()
        let vm = ExtensionGuideViewModel(defaults: makeSuite(), now: { self.start }, analytics: spy)

        vm.onAppear(source: .onboarding)

        #expect(spy.events == [.onboardingExtensionGuideShown(source: .onboarding)])
        vm.reset()
    }
}
