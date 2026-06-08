//
//  OnboardingViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
@testable import LinkClean
import LinkCleanKit

@MainActor
struct OnboardingViewModelTests {

    private func makeSuite() -> UserDefaults {
        UserDefaults(suiteName: "test.\(UUID().uuidString)")!
    }

    @Test func startsOnWelcome() {
        let vm = OnboardingViewModel(defaults: makeSuite())

        #expect(vm.page == .welcome)
    }

    @Test func advanceGoesWelcomeToTryIt() {
        let vm = OnboardingViewModel(defaults: makeSuite())

        vm.advance()

        #expect(vm.page == .tryIt)
    }

    @Test func advanceFromTryItDoesNotReachCelebration() {
        let vm = OnboardingViewModel(defaults: makeSuite())

        vm.advance() // welcome -> tryIt
        vm.advance() // tryIt -> stays (celebration only via success)

        #expect(vm.page == .tryIt)
    }

    @Test func guideSuccessAdvancesToCelebration() {
        let vm = OnboardingViewModel(defaults: makeSuite())

        vm.advance()
        vm.handleGuideSuccess()

        #expect(vm.page == .celebration)
    }

    @Test func getStartedPersistsFlagAndFinishes() {
        let suite = makeSuite()
        let vm = OnboardingViewModel(defaults: suite)
        var finished = false
        vm.onFinished = { finished = true }

        vm.getStarted()

        #expect(finished == true)
        #expect(suite.bool(forKey: SettingsKeys.hasCompletedOnboarding) == true)
    }

    @Test func skipPersistsFlagAndFinishes() {
        let suite = makeSuite()
        let vm = OnboardingViewModel(defaults: suite)
        var finished = false
        vm.onFinished = { finished = true }

        vm.skip()

        #expect(finished == true)
        #expect(suite.bool(forKey: SettingsKeys.hasCompletedOnboarding) == true)
    }

    @Test func skipFromWelcomeCompletes() {
        let suite = makeSuite()
        let vm = OnboardingViewModel(defaults: suite)

        // Skippable at every step, including the very first page.
        vm.skip()

        #expect(suite.bool(forKey: SettingsKeys.hasCompletedOnboarding) == true)
    }

    @Test func getStartedEmitsCompletedSignal() {
        let spy = SpyAnalytics()
        let vm = OnboardingViewModel(defaults: makeSuite(), analytics: spy)

        vm.getStarted()

        #expect(spy.events == [.onboardingFlowCompleted])
    }

    @Test func skipEmitsSkippedSignal() {
        let spy = SpyAnalytics()
        let vm = OnboardingViewModel(defaults: makeSuite(), analytics: spy)

        vm.skip()

        #expect(spy.events == [.onboardingFlowSkipped])
    }
}
