//
//  ReviewGateTests.swift
//  LinkCleanKitTests
//

import Foundation
import Testing
@testable import LinkCleanData

struct ReviewGateTests {
    private let day: TimeInterval = 86_400
    private let hour: TimeInterval = 3_600
    private let origin = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - Pure cadence (ReviewGateRules)

    @Test func doesNotPromptBelowSuccessThreshold() {
        // Even well past the span window, too few successes → no prompt.
        #expect(ReviewGateRules.shouldPrompt(
            successCount: ReviewGateRules.minimumSuccesses - 1,
            firstSuccessAt: origin.timeIntervalSince1970,
            lastPromptAt: 0,
            now: origin.addingTimeInterval(10 * day)
        ) == false)
    }

    @Test func doesNotPromptBeforeSpanElapses() {
        // Enough successes, but still within the first day → one burst, not repeat use.
        #expect(ReviewGateRules.shouldPrompt(
            successCount: ReviewGateRules.minimumSuccesses,
            firstSuccessAt: origin.timeIntervalSince1970,
            lastPromptAt: 0,
            now: origin.addingTimeInterval(23 * hour)
        ) == false)
    }

    @Test func promptsOnceThresholdAndSpanAreMet() {
        #expect(ReviewGateRules.shouldPrompt(
            successCount: ReviewGateRules.minimumSuccesses,
            firstSuccessAt: origin.timeIntervalSince1970,
            lastPromptAt: 0,
            now: origin.addingTimeInterval(2 * day)
        ))
    }

    @Test func cooldownSuppressesEvenWithFreshSuccesses() {
        let shownAt = origin.addingTimeInterval(2 * day)
        #expect(ReviewGateRules.shouldPrompt(
            successCount: ReviewGateRules.minimumSuccesses,
            firstSuccessAt: origin.timeIntervalSince1970,
            lastPromptAt: shownAt.timeIntervalSince1970,
            now: shownAt.addingTimeInterval(Double(ReviewGateRules.cooldownDays - 1) * day)
        ) == false)
    }

    @Test func promptsAgainOnceCooldownElapses() {
        let shownAt = origin.addingTimeInterval(2 * day)
        #expect(ReviewGateRules.shouldPrompt(
            successCount: ReviewGateRules.minimumSuccesses,
            firstSuccessAt: origin.timeIntervalSince1970,
            lastPromptAt: shownAt.timeIntervalSince1970,
            now: shownAt.addingTimeInterval(Double(ReviewGateRules.cooldownDays + 1) * day)
        ))
    }

    // MARK: - Persistence + integration (DefaultReviewService)

    /// A `Sendable` mutable clock so one service instance can advance time across
    /// record/prompt calls. Swift Testing runs tests in parallel, so each test
    /// owns its own clock and (via `makeService`) its own wiped suite. Explicitly
    /// `nonisolated` (the package defaults to MainActor isolation) so the service's
    /// `@Sendable` clock closure can read `now`; reads/writes are single-threaded
    /// per test, so the unchecked `Sendable` is sound.
    private nonisolated final class Clock: @unchecked Sendable {
        var now: Date
        init(_ now: Date) { self.now = now }
    }

    private func makeService(_ name: String, clock: Clock) -> DefaultReviewService {
        let suite = "ReviewGateTests.\(name)"
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        return DefaultReviewService(suiteName: suite, now: { clock.now })
    }

    private func recordSuccesses(_ count: Int, into service: DefaultReviewService) {
        for _ in 0..<count { service.recordSuccess() }
    }

    @Test func recordThenEligibleAfterSpan() {
        let clock = Clock(origin)
        let service = makeService("eligible", clock: clock)
        recordSuccesses(ReviewGateRules.minimumSuccesses, into: service)
        clock.now = origin.addingTimeInterval(2 * day)
        #expect(service.shouldRequestReview())
    }

    @Test func firstSuccessTimestampIsFirstWriteWins() {
        let clock = Clock(origin)
        let service = makeService("firstWriteWins", clock: clock)
        service.recordSuccess() // stamps firstSuccessAt at origin
        // Later successes must not push the span clock forward.
        clock.now = origin.addingTimeInterval(2 * day)
        recordSuccesses(ReviewGateRules.minimumSuccesses, into: service)
        // 25h after the *first* success the span is satisfied despite the later writes.
        clock.now = origin.addingTimeInterval(25 * hour)
        #expect(service.shouldRequestReview())
    }

    @Test func markPromptedStartsCooldownAndResetsCount() {
        let clock = Clock(origin)
        let service = makeService("cooldown", clock: clock)
        recordSuccesses(ReviewGateRules.minimumSuccesses, into: service)
        clock.now = origin.addingTimeInterval(2 * day)
        service.markPrompted()
        // A fresh batch of exports during the cooldown stays suppressed until it elapses.
        recordSuccesses(ReviewGateRules.minimumSuccesses, into: service)
        clock.now = origin.addingTimeInterval(2 * day + Double(ReviewGateRules.cooldownDays - 1) * day)
        #expect(service.shouldRequestReview() == false)
    }

    @Test func repromptRequiresNewSuccessesAfterCooldown() {
        let clock = Clock(origin)
        let service = makeService("reprompt", clock: clock)
        recordSuccesses(ReviewGateRules.minimumSuccesses, into: service)
        let shownAt = origin.addingTimeInterval(2 * day)
        clock.now = shownAt
        service.markPrompted()
        let afterCooldown = shownAt.addingTimeInterval(Double(ReviewGateRules.cooldownDays + 1) * day)
        clock.now = afterCooldown
        // markPrompted reset the counter: past the cooldown but with no new exports → not re-asked.
        #expect(service.shouldRequestReview() == false)
        // Fresh engagement after the cooldown → eligible again.
        recordSuccesses(ReviewGateRules.minimumSuccesses, into: service)
        #expect(service.shouldRequestReview())
    }
}
