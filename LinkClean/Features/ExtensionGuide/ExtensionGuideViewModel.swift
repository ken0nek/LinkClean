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
        /// "Try it" was tapped at `startedAt` (reference-date interval); we're
        /// waiting for the extension to write a newer success timestamp.
        case waitingForExtension(startedAt: Double)
        case succeeded
    }

    private(set) var state: State = .idle

    /// The shared onboarding sample link. The action extension recognizes this
    /// exact link and skips saving it to History (see `OnboardingDemo`).
    let demoURL = OnboardingDemo.url

    @ObservationIgnored private let defaults: UserDefaults?
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    init(
        defaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier),
        now: @escaping () -> Date = { .now }
    ) {
        self.defaults = defaults
        self.now = now
    }

    /// True while idle or waiting — used to gate the share-sheet mock's pulse so
    /// it stops once the user has succeeded.
    var isIdleOrWaiting: Bool {
        state != .succeeded
    }

    var isWaiting: Bool {
        if case .waitingForExtension = state { return true }
        return false
    }

    var hasSucceeded: Bool {
        state == .succeeded
    }

    func onAppear(source: ExtensionGuideSource) {
        // TODO(analytics): Onboarding.ExtensionGuide.shown — source: \(source == .onboarding ? "onboarding" : "settings") (see docs/plans/analytics.md §6)
    }

    /// Records the moment the user opened the share sheet, so a subsequent
    /// extension run can be recognized as "theirs".
    func tryItTapped() {
        let startedAt = now().timeIntervalSinceReferenceDate
        state = .waitingForExtension(startedAt: startedAt)
        startPolling()
    }

    /// Re-checks for a completed run when the app returns to the foreground
    /// (the share sheet's dismissal drives the scene inactive → active).
    func handleScenePhase(_ phase: ScenePhase) {
        guard phase == .active else { return }
        checkForSuccess()
    }

    func reset() {
        state = .idle
        pollTask?.cancel()
        pollTask = nil
    }

    // MARK: - Private

    /// Belt-and-suspenders fallback for missed scene transitions — notably the
    /// iPad share-sheet popover, which may not toggle `scenePhase`.
    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { @MainActor in
            for _ in 0 ..< 40 { // ~20s budget while waiting
                try? await Task.sleep(for: .milliseconds(500))
                if Task.isCancelled { return }
                checkForSuccess()
                if case .succeeded = state { return }
            }
        }
    }

    private func checkForSuccess() {
        guard case let .waitingForExtension(startedAt) = state else { return }
        let lastRun = defaults?.double(forKey: SettingsKeys.lastActionExtensionRunAt) ?? 0
        guard lastRun > startedAt else { return }
        state = .succeeded
        pollTask?.cancel()
        pollTask = nil
    }
}
