//
//  OnboardingViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/7/26.
//

import Foundation
import LinkCleanKit
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    enum Page: Int {
        case welcome
        case tryIt
        case celebration
    }

    private(set) var page: Page = .welcome

    /// Invoked once onboarding is finished or skipped, after the completion
    /// flag is persisted. ContentView uses this to swap in the main TabView.
    var onFinished: (() -> Void)?

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Manual forward navigation. Only the welcome → try-it step advances this
    /// way; the celebration page is reachable solely through a detected
    /// extension success (`handleGuideSuccess`), so we never congratulate a
    /// user who didn't actually run the extension.
    func advance() {
        switch page {
        case .welcome:
            page = .tryIt
        case .tryIt, .celebration:
            break
        }
    }

    func handleGuideSuccess() {
        page = .celebration
    }

    func skip() {
        // TODO(analytics): Onboarding.flow.skipped (see docs/plans/analytics.md §6)
        complete()
    }

    func getStarted() {
        // TODO(analytics): Onboarding.flow.completed (see docs/plans/analytics.md §6)
        complete()
    }

    private func complete() {
        defaults.set(true, forKey: SettingsKeys.hasCompletedOnboarding)
        onFinished?()
    }
}
