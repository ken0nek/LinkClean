//
//  ReviewService.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 6/9/26.
//

import Foundation

/// The injectable seam the Home flow uses to count realized-value moments and
/// decide when to surface the in-app review prompt. Inject a spy in tests
/// (mirrors ``AnalyticsService``).
public protocol ReviewService: Sendable {
    /// One distinct cleaned URL was copied or shared.
    func recordSuccess()
    /// Whether the in-app review prompt is eligible to show right now.
    func shouldRequestReview() -> Bool
    /// Mark that the prompt was shown — starts the cooldown and resets the
    /// success counter so the next prompt requires fresh exports.
    func markPrompted()
}

/// The pure cadence math behind the in-app review prompt — no view state, no
/// `UserDefaults`, no singleton: a decision over three already-read counters. The
/// cadence is hard-coded (no server config), so tuning means editing a constant
/// and shipping. ``DefaultReviewService`` owns the persistence; this owns the
/// rule, so it can be unit-tested directly by passing counters and a clock.
///
/// `shouldPrompt` returns `true` only when all hold:
/// - `successCount >= minimumSuccesses` distinct cleaned URLs were copied or
///   shared — realized value, not raw taps (the caller dedupes per distinct
///   output, so hammering Copy on one result counts once)
/// - the first such export was ≥ `minimumFirstSuccessAgeHours` ago, so usage
///   spans at least two days rather than a single burst
/// - ≥ `cooldownDays` since the prompt was last shown (or it never has been)
///
/// Onboarding is intentionally not checked here: eligibility is only ever
/// evaluated in-app, and the app gates all of Home behind completed onboarding
/// (`ContentView`), so reaching this code already implies it.
nonisolated enum ReviewGateRules {
    // Hard-coded cadence. See the type doc for the rule each governs.
    static let minimumSuccesses = 5
    static let minimumFirstSuccessAgeHours = 24
    static let cooldownDays = 120

    /// Pure decision over the persisted counters. Timestamps are epoch seconds
    /// (`timeIntervalSince1970`); `0` means unset/never.
    static func shouldPrompt(
        successCount: Int,
        firstSuccessAt: TimeInterval,
        lastPromptAt: TimeInterval,
        now: Date
    ) -> Bool {
        guard successCount >= minimumSuccesses else { return false }

        let nowEpoch = now.timeIntervalSince1970

        guard firstSuccessAt > 0,
              nowEpoch - firstSuccessAt >= TimeInterval(minimumFirstSuccessAgeHours) * 3_600
        else { return false }

        if lastPromptAt > 0, nowEpoch - lastPromptAt < TimeInterval(cooldownDays) * 86_400 { return false }

        return true
    }
}

/// The app's ``ReviewService``: persists the success counter and cooldown
/// timestamp in the shared App Group suite and evaluates ``ReviewGateRules``
/// against them. Constructed with its suite name (default: the App Group) and a
/// clock, both injectable for tests. One protocol, one implementation — no
/// statics threaded with `defaults:`/`now:` parameters.
public nonisolated struct DefaultReviewService: ReviewService {
    private let suiteName: String?
    private let now: @Sendable () -> Date

    public init(
        suiteName: String? = AppGroup.identifier,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.suiteName = suiteName
        self.now = now
    }

    /// Counts one realized-value moment: a distinct cleaned URL the user copied
    /// or shared. Stamps `firstSuccessAt` on the first ever call (first-write-wins,
    /// so the span clock starts at the genuine first export and never resets).
    public func recordSuccess() {
        guard let defaults else { return }
        defaults.set(defaults.integer(forKey: SettingsKeys.reviewSuccessCount) + 1, forKey: SettingsKeys.reviewSuccessCount)
        if defaults.double(forKey: SettingsKeys.reviewFirstSuccessAt) == 0 {
            defaults.set(now().timeIntervalSince1970, forKey: SettingsKeys.reviewFirstSuccessAt)
        }
    }

    public func shouldRequestReview() -> Bool {
        guard let defaults else { return false }

        #if DEBUG
        if defaults.bool(forKey: SettingsKeys.reviewDebugForceShow) { return true }
        #endif

        return ReviewGateRules.shouldPrompt(
            successCount: defaults.integer(forKey: SettingsKeys.reviewSuccessCount),
            firstSuccessAt: defaults.double(forKey: SettingsKeys.reviewFirstSuccessAt),
            lastPromptAt: defaults.double(forKey: SettingsKeys.reviewLastPromptAt),
            now: now()
        )
    }

    /// Starts the cooldown clock and resets the success counter, so the next
    /// prompt requires a fresh batch of exports. Call the instant the prompt is
    /// committed to showing (not on the sheet's appearance), so a crash or
    /// backgrounding can't leave the gate re-armed with no cooldown stamped.
    public func markPrompted() {
        guard let defaults else { return }
        defaults.set(now().timeIntervalSince1970, forKey: SettingsKeys.reviewLastPromptAt)
        defaults.set(0, forKey: SettingsKeys.reviewSuccessCount)
    }

    private var defaults: UserDefaults? {
        suiteName.flatMap { UserDefaults(suiteName: $0) }
    }

    #if DEBUG
    /// Forces ``shouldRequestReview()`` to return `true` regardless of counters —
    /// for QA and screenshots via the `-forceReviewGate` launch arg. DEBUG-only.
    public func setDebugForceShow(_ on: Bool) {
        defaults?.set(on, forKey: SettingsKeys.reviewDebugForceShow)
    }
    #endif
}
