//
//  ReviewGateTests.swift
//  LinkCleanKitTests
//

import Foundation
import Testing
@testable import LinkCleanKit

struct ReviewGateTests {
    private let day: TimeInterval = 86_400
    private let hour: TimeInterval = 3_600
    private let origin = Date(timeIntervalSince1970: 1_700_000_000)

    /// A fresh, isolated `UserDefaults` suite per test — Swift Testing runs tests
    /// in parallel, so each needs its own backing store. Wiped on creation.
    private func makeDefaults(_ name: String) -> UserDefaults {
        let suite = "ReviewGateTests.\(name)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    private func recordSuccesses(_ count: Int, at date: Date, in defaults: UserDefaults) {
        for _ in 0..<count {
            ReviewGate.recordSuccess(now: date, defaults: defaults)
        }
    }

    @Test func doesNotPromptBelowSuccessThreshold() {
        let defaults = makeDefaults("belowThreshold")
        recordSuccesses(ReviewGate.minimumSuccesses - 1, at: origin, in: defaults)
        // Even well past the span window, too few successes → no prompt.
        #expect(ReviewGate.shouldPrompt(now: origin.addingTimeInterval(10 * day), defaults: defaults) == false)
    }

    @Test func doesNotPromptBeforeSpanElapses() {
        let defaults = makeDefaults("span")
        recordSuccesses(ReviewGate.minimumSuccesses, at: origin, in: defaults)
        // Enough successes, but still within the first day → one burst, not repeat use.
        #expect(ReviewGate.shouldPrompt(now: origin.addingTimeInterval(23 * hour), defaults: defaults) == false)
    }

    @Test func promptsOnceThresholdAndSpanAreMet() {
        let defaults = makeDefaults("eligible")
        recordSuccesses(ReviewGate.minimumSuccesses, at: origin, in: defaults)
        #expect(ReviewGate.shouldPrompt(now: origin.addingTimeInterval(2 * day), defaults: defaults))
    }

    @Test func firstSuccessTimestampIsFirstWriteWins() {
        let defaults = makeDefaults("firstWriteWins")
        ReviewGate.recordSuccess(now: origin, defaults: defaults)
        // Later successes must not push the span clock forward.
        recordSuccesses(ReviewGate.minimumSuccesses, at: origin.addingTimeInterval(2 * day), in: defaults)
        // 25h after the *first* success the span is satisfied despite the later writes.
        #expect(ReviewGate.shouldPrompt(now: origin.addingTimeInterval(25 * hour), defaults: defaults))
    }

    @Test func cooldownSuppressesEvenWithFreshSuccesses() {
        let defaults = makeDefaults("cooldown")
        recordSuccesses(ReviewGate.minimumSuccesses, at: origin, in: defaults)
        let shownAt = origin.addingTimeInterval(2 * day)
        ReviewGate.markPrompted(now: shownAt, defaults: defaults)
        // A fresh batch of exports during the cooldown stays suppressed until it elapses.
        recordSuccesses(ReviewGate.minimumSuccesses, at: shownAt.addingTimeInterval(1 * day), in: defaults)
        #expect(ReviewGate.shouldPrompt(now: shownAt.addingTimeInterval(Double(ReviewGate.cooldownDays - 1) * day), defaults: defaults) == false)
    }

    @Test func repromptRequiresNewSuccessesAfterCooldown() {
        let defaults = makeDefaults("reprompt")
        recordSuccesses(ReviewGate.minimumSuccesses, at: origin, in: defaults)
        let shownAt = origin.addingTimeInterval(2 * day)
        ReviewGate.markPrompted(now: shownAt, defaults: defaults)
        let afterCooldown = shownAt.addingTimeInterval(Double(ReviewGate.cooldownDays + 1) * day)
        // markPrompted reset the counter: past the cooldown but with no new exports → not re-asked.
        #expect(ReviewGate.shouldPrompt(now: afterCooldown, defaults: defaults) == false)
        // Fresh engagement after the cooldown → eligible again.
        recordSuccesses(ReviewGate.minimumSuccesses, at: afterCooldown, in: defaults)
        #expect(ReviewGate.shouldPrompt(now: afterCooldown, defaults: defaults))
    }
}
