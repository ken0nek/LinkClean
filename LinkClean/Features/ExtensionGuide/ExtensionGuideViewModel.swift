//
//  ExtensionGuideViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/7/26.
//

import Foundation
import LinkCleanKit
import Observation
import SwiftUI

/// Where the extension guide is being shown from. Drives analytics and a few
/// presentation choices (onboarding advances on success; Settings shows an
/// inline confirmation).
enum ExtensionGuideSource {
    case onboarding
    case settings
}

@MainActor
@Observable
final class ExtensionGuideViewModel {
    enum State: Equatable {
        case idle
        /// The user tapped "Share a sample link"; showing the waiting hint.
        case waitingForExtension
        case succeeded
    }

    private(set) var state: State = .idle

    /// The shared onboarding sample link. The action extension recognizes this
    /// exact link and skips saving it to History (see `OnboardingDemo`).
    let demoURL = OnboardingDemo.url

    @ObservationIgnored private let defaults: UserDefaults?
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let analytics: AnalyticsService
    /// Reference-date interval captured when the guide appears. Any extension
    /// run with a newer timestamp counts as success. Armed on appear (not on
    /// the ShareLink tap) so a swallowed tap gesture or an iPad popover that
    /// never toggles scenePhase can't strand the user.
    @ObservationIgnored private var watchStartedAt: Double?
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    init(
        defaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier),
        now: @escaping () -> Date = { .now },
        analytics: AnalyticsService = TelemetryDeckAnalytics()
    ) {
        self.defaults = defaults
        self.now = now
        self.analytics = analytics
    }

    /// True while idle or waiting — used to gate the share-sheet mock's pulse so
    /// it stops once the user has succeeded.
    var isIdleOrWaiting: Bool {
        state != .succeeded
    }

    var hasSucceeded: Bool {
        state == .succeeded
    }

    func onAppear(source: ExtensionGuideSource) {
        let guideSource: AnalyticsEvent.GuideSource = source == .onboarding ? .onboarding : .settings
        analytics.capture(.onboardingExtensionGuideShown(source: guideSource))
        startWatching()
    }

    /// Records the moment the user opened the share sheet, surfacing the waiting
    /// hint. Detection itself is already armed by `startWatching`, so success is
    /// found even if this gesture never fires.
    func tryItTapped() {
        guard state != .succeeded else { return }
        startWatching()
        state = .waitingForExtension
    }

    /// Re-checks for a completed run when the app returns to the foreground
    /// (on iPhone the extension dismissal drives the scene inactive → active).
    func handleScenePhase(_ phase: ScenePhase) {
        guard phase == .active else { return }
        checkForSuccess()
    }

    func reset() {
        state = .idle
        watchStartedAt = nil
        pollTask?.cancel()
        pollTask = nil
    }

    // MARK: - Private

    /// Arms detection: records the baseline timestamp and starts the poll.
    /// Idempotent — safe to call from both onAppear and tryItTapped.
    private func startWatching() {
        guard state != .succeeded else { return }
        if watchStartedAt == nil {
            watchStartedAt = now().timeIntervalSinceReferenceDate
        }
        startPolling()
    }

    /// Polls the shared timestamp while waiting. Cross-process `UserDefaults`
    /// writes aren't delivered by notification, so we re-read until we see the
    /// run rather than relying solely on scenePhase (which the iPad share-sheet
    /// popover may not toggle). Bounded generously as a safety net; cancelled on
    /// success or reset (view disappear).
    private func startPolling() {
        guard pollTask == nil else { return }
        pollTask = Task { @MainActor in
            for _ in 0 ..< 600 { // 600 × 500ms = 5 min cap
                try? await Task.sleep(for: .milliseconds(500))
                if Task.isCancelled { return }
                checkForSuccess()
                if state == .succeeded { return }
            }
            pollTask = nil
        }
    }

    private func checkForSuccess() {
        guard state != .succeeded, let watchStartedAt else { return }
        let lastRun = defaults?.double(forKey: SettingsKeys.lastActionExtensionRunAt) ?? 0
        guard lastRun > watchStartedAt else { return }
        state = .succeeded
        pollTask?.cancel()
        pollTask = nil
    }
}
