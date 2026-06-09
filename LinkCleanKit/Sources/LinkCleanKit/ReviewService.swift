//
//  ReviewService.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 6/9/26.
//

/// The injectable seam the Home flow uses to count realized-value moments and
/// decide when to surface the in-app review prompt. Backed by ``ReviewGate``;
/// inject a spy in tests (mirrors ``AnalyticsService``). Kept separate from the
/// gate so ``ReviewGate`` stays a pure, statically-callable logic type while view
/// models depend only on this mockable protocol.
public protocol ReviewService: Sendable {
    /// One distinct cleaned URL was copied or shared.
    func recordSuccess()
    /// Whether the in-app review prompt is eligible to show right now.
    func shouldRequestReview() -> Bool
    /// Mark that the prompt was shown — starts the cooldown and resets the
    /// success counter so the next prompt requires fresh exports.
    func markPrompted()
}

/// ``ReviewGate``-backed ``ReviewService`` used by the app. Stateless — all state
/// lives in the shared App Group suite the gate reads and writes.
public nonisolated struct DefaultReviewService: ReviewService {
    public init() {}
    public func recordSuccess() { ReviewGate.recordSuccess() }
    public func shouldRequestReview() -> Bool { ReviewGate.shouldPrompt() }
    public func markPrompted() { ReviewGate.markPrompted() }
}
