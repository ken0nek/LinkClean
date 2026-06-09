//
//  ReviewGate.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 6/9/26.
//

import Foundation

/// Persists the success counter and cooldown timestamp that decide when to
/// surface the in-app review prompt (`ReviewGateSheet`). Pure functions over the
/// shared App Group `UserDefaults` — no view state, no singleton instance, and no
/// server config: the cadence is hard-coded, so tuning means editing a constant
/// and shipping.
///
/// `shouldPrompt` returns `true` only when all hold:
/// - `successCount >= minimumSuccesses` distinct cleaned URLs were copied or
///   shared — realized value, not raw taps (the caller dedupes per distinct
///   output, so hammering Copy on one result counts once)
/// - the first such export was ≥ `minimumFirstSuccessAgeHours` ago, so usage
///   spans at least two days rather than a single burst
/// - ≥ `cooldownDays` since the prompt was last shown (or it never has been)
///
/// `markPrompted` resets `successCount`, so a re-prompt after the cooldown
/// requires fresh exports — a dormant user who once qualified is not re-asked
/// with no new activity.
///
/// Onboarding is intentionally not checked here: `shouldPrompt` is only ever
/// evaluated in-app, and the app gates all of Home behind completed onboarding
/// (`ContentView`), so reaching this code already implies it.
public nonisolated enum ReviewGate {
    private static let successCountKey = "review.successCount"
    private static let firstSuccessAtKey = "review.firstSuccessAt"
    private static let lastPromptAtKey = "review.lastPromptAt"
    #if DEBUG
    static let debugForceShowKey = "review.debug.forceShow"
    #endif

    // Hard-coded cadence. See the type doc for the rule each governs.
    static let minimumSuccesses = 5
    static let minimumFirstSuccessAgeHours = 24
    static let cooldownDays = 120

    /// Counts one realized-value moment: a distinct cleaned URL the user copied
    /// or shared. Stamps `firstSuccessAt` on the first ever call (first-write-wins,
    /// so the span clock starts at the genuine first export and never resets).
    public static func recordSuccess(
        now: Date = .now,
        defaults: UserDefaults? = AppGroup.userDefaults
    ) {
        guard let defaults else { return }
        defaults.set(defaults.integer(forKey: successCountKey) + 1, forKey: successCountKey)
        if defaults.double(forKey: firstSuccessAtKey) == 0 {
            defaults.set(now.timeIntervalSince1970, forKey: firstSuccessAtKey)
        }
    }

    /// Starts the cooldown clock and resets the success counter, so the next
    /// prompt requires a fresh batch of exports. Call the instant the prompt is
    /// committed to showing (not on the sheet's appearance), so a crash or
    /// backgrounding can't leave the gate re-armed with no cooldown stamped.
    public static func markPrompted(
        now: Date = .now,
        defaults: UserDefaults? = AppGroup.userDefaults
    ) {
        guard let defaults else { return }
        defaults.set(now.timeIntervalSince1970, forKey: lastPromptAtKey)
        defaults.set(0, forKey: successCountKey)
    }

    public static func shouldPrompt(
        now: Date = .now,
        defaults: UserDefaults? = AppGroup.userDefaults
    ) -> Bool {
        guard let defaults else { return false }

        #if DEBUG
        if defaults.bool(forKey: debugForceShowKey) { return true }
        #endif

        guard defaults.integer(forKey: successCountKey) >= minimumSuccesses else { return false }

        let nowEpoch = now.timeIntervalSince1970

        let firstSuccessAt = defaults.double(forKey: firstSuccessAtKey)
        guard firstSuccessAt > 0,
              nowEpoch - firstSuccessAt >= TimeInterval(minimumFirstSuccessAgeHours) * 3_600
        else { return false }

        let lastPromptAt = defaults.double(forKey: lastPromptAtKey)
        if lastPromptAt > 0, nowEpoch - lastPromptAt < TimeInterval(cooldownDays) * 86_400 { return false }

        return true
    }

    #if DEBUG
    /// Forces `shouldPrompt` to return `true` regardless of counters — for QA and
    /// screenshots via the `-forceReviewGate` launch arg. DEBUG-only.
    public static func setDebugForceShow(_ on: Bool, defaults: UserDefaults? = AppGroup.userDefaults) {
        defaults?.set(on, forKey: debugForceShowKey)
    }

    static func resetAllState(defaults: UserDefaults? = AppGroup.userDefaults) {
        for key in [successCountKey, firstSuccessAtKey, lastPromptAtKey, debugForceShowKey] {
            defaults?.removeObject(forKey: key)
        }
    }
    #endif
}
