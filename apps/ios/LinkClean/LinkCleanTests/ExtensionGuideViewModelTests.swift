//
//  ExtensionGuideViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
import SwiftUI
@testable import LinkClean
import LinkCleanCore
import LinkCleanData

@MainActor
struct ExtensionGuideViewModelTests {

    /// A `SettingsStore` over a fresh isolated App Group suite, so each test's
    /// `lastActionExtensionRunAt` reads/writes can't collide under parallel runs.
    private func makeStore() -> SettingsStore {
        SettingsStore(appGroupSuiteName: "test.\(UUID().uuidString)")
    }

    private func isWaiting(_ vm: ExtensionGuideViewModel) -> Bool {
        if case .waitingForExtension = vm.state { return true }
        return false
    }

    private let start = Date(timeIntervalSinceReferenceDate: 1000)

    private func setRun(_ date: Date, in store: SettingsStore) {
        store.lastActionExtensionRunAt = date
    }

    @Test func startsIdle() {
        let vm = ExtensionGuideViewModel(settings: makeStore(), now: { self.start })

        #expect(vm.state == .idle)
        #expect(vm.isIdleOrWaiting == true)
        #expect(vm.hasSucceeded == false)
    }

    @Test func tryItTappedMovesToWaiting() {
        let vm = ExtensionGuideViewModel(settings: makeStore(), now: { self.start })

        vm.tryItTapped()

        #expect(isWaiting(vm) == true)
        #expect(vm.isIdleOrWaiting == true)
        vm.reset()
    }

    @Test func staysWaitingWithNoTimestamp() {
        let vm = ExtensionGuideViewModel(settings: makeStore(), now: { self.start })

        vm.tryItTapped()
        vm.handleScenePhase(.active)

        #expect(isWaiting(vm) == true)
        vm.reset()
    }

    @Test func staysWaitingForStaleTimestamp() {
        let store = makeStore()
        // A run that happened before "Try it" was tapped must not count.
        setRun(Date(timeIntervalSinceReferenceDate: 500), in: store)
        let vm = ExtensionGuideViewModel(settings: store, now: { self.start })

        vm.tryItTapped()
        vm.handleScenePhase(.active)

        #expect(isWaiting(vm) == true)
        vm.reset()
    }

    @Test func succeedsForNewerTimestampOnSceneActive() {
        let store = makeStore()
        let vm = ExtensionGuideViewModel(settings: store, now: { self.start })

        vm.tryItTapped()
        setRun(Date(timeIntervalSinceReferenceDate: 1001), in: store)
        vm.handleScenePhase(.active)

        #expect(vm.state == .succeeded)
        #expect(vm.hasSucceeded == true)
        #expect(vm.isIdleOrWaiting == false)
    }

    @Test func succeedsWithoutTryItTapWhenArmedOnAppear() {
        // Detection is armed on appear, so a run is caught even if the
        // ShareLink tap gesture never fired.
        let store = makeStore()
        let vm = ExtensionGuideViewModel(settings: store, now: { self.start })

        vm.onAppear(source: .settings)
        setRun(Date(timeIntervalSinceReferenceDate: 1001), in: store)
        vm.handleScenePhase(.active)

        #expect(vm.hasSucceeded == true)
        vm.reset()
    }

    @Test func nonActiveScenePhaseIsNoOp() {
        let store = makeStore()
        let vm = ExtensionGuideViewModel(settings: store, now: { self.start })

        vm.tryItTapped()
        setRun(Date(timeIntervalSinceReferenceDate: 1001), in: store)

        vm.handleScenePhase(.background)
        #expect(isWaiting(vm) == true)

        vm.handleScenePhase(.inactive)
        #expect(isWaiting(vm) == true)

        vm.handleScenePhase(.active)
        #expect(vm.hasSucceeded == true)
    }

    @Test func resetReturnsToIdle() {
        let vm = ExtensionGuideViewModel(settings: makeStore(), now: { self.start })

        vm.tryItTapped()
        vm.reset()

        #expect(vm.state == .idle)
    }

    @Test func successIsIdempotentAcrossScenePhases() {
        let store = makeStore()
        let vm = ExtensionGuideViewModel(settings: store, now: { self.start })

        vm.tryItTapped()
        setRun(Date(timeIntervalSinceReferenceDate: 1001), in: store)
        vm.handleScenePhase(.active)
        vm.handleScenePhase(.active)

        #expect(vm.hasSucceeded == true)
    }

    @Test func onAppearFromSettingsEmitsGuideShownWithSource() {
        let spy = SpyAnalytics()
        let vm = ExtensionGuideViewModel(settings: makeStore(), now: { self.start }, analytics: spy)

        vm.onAppear(source: .settings)

        #expect(spy.events == [.onboardingExtensionGuideShown(source: .settings)])
        vm.reset()
    }

    @Test func onAppearFromOnboardingTagsSource() {
        let spy = SpyAnalytics()
        let vm = ExtensionGuideViewModel(settings: makeStore(), now: { self.start }, analytics: spy)

        vm.onAppear(source: .onboarding)

        #expect(spy.events == [.onboardingExtensionGuideShown(source: .onboarding)])
        vm.reset()
    }
}
