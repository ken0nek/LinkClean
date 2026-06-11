//
//  ReviewPromptFlow.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/11/26.
//

import Foundation
import LinkCleanCore
import LinkCleanData
import Observation

/// Owns the in-app review prompt end to end: eligibility, the once-per-session
/// cap, the 0.6 s grace delay, presentation state, and the rated-high → system-
/// prompt handoff. Extracted from HomeViewModel so the review flow has one owner
/// (it previously spanned seven fields and five methods there). `HomeView` renders
/// ``isPresenting`` and forwards rating/dismissal; `HomeViewModel` only calls
/// ``noteExport(counted:)``.
@MainActor
@Observable
final class ReviewPromptFlow {
    /// Drives ``ReviewGateSheet``. Settable so the sheet's `isPresented` binding
    /// can clear it on dismiss.
    var isPresenting = false

    @ObservationIgnored private let review: ReviewService
    @ObservationIgnored private let analytics: AnalyticsService
    @ObservationIgnored private var didOfferThisSession = false
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var isVisible = false
    // Per-presentation state: whether the user rated at all (a dismissal without a
    // rating is a decline) and whether it was a high rating (defers Apple's
    // `requestReview()` until after the sheet dismisses).
    @ObservationIgnored private var didRate = false
    @ObservationIgnored private var ratedHigh = false

    init(review: ReviewService, analytics: AnalyticsService) {
        self.review = review
        self.analytics = analytics
    }

    /// Home appeared (`true`) or disappeared (`false`). A pending offer is
    /// cancelled when Home leaves so it can't surface over a backgrounded or
    /// torn-down screen.
    func setVisible(_ visible: Bool) {
        isVisible = visible
        if !visible { task?.cancel() }
    }

    /// A realized-value export. `counted` is whether this output is new (the
    /// ``CleanSession`` ledger deduped it); if so it advances the success counter.
    /// Either way, re-evaluate eligibility — the copy/share is the natural place
    /// to ask.
    func noteExport(counted: Bool) {
        if counted { review.recordSuccess() }
        maybeOffer()
    }

    /// Schedules the prompt if eligible and not yet offered this session. A short
    /// delay lets the copy's checkmark and success haptic land before the sheet
    /// rises, so the two moments don't collide.
    private func maybeOffer() {
        guard !didOfferThisSession, review.shouldRequestReview() else { return }
        didOfferThisSession = true
        task = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled, isVisible else { return }
            present()
        }
    }

    /// Commits to showing the prompt: stamps the persistent cooldown and emits the
    /// shown signal at the same instant `isPresenting` flips, so backgrounding or a
    /// crash can't leave the gate re-armed with no cooldown recorded.
    private func present() {
        review.markPrompted()
        analytics.capture(.reviewPromptShown)
        didRate = false
        ratedHigh = false
        isPresenting = true
    }

    /// Records the star rating (bucket-only). The hop to Apple's `requestReview()`
    /// is deferred to ``didDismiss()`` so it fires after our sheet is gone.
    func handle(_ outcome: ReviewGateOutcome) {
        didRate = true
        switch outcome {
        case .ratedHigh:
            ratedHigh = true
            analytics.capture(.reviewStarsSelected(bucket: .high))
            analytics.capture(.reviewSystemPromptRequested)
        case .ratedLow:
            analytics.capture(.reviewStarsSelected(bucket: .low))
        }
    }

    /// Called when the sheet finishes dismissing. Counts a dismissal when the user
    /// left without rating (covers "Not now" and an interactive swipe), and returns
    /// whether the host should now present Apple's system prompt.
    func didDismiss() -> Bool {
        if !didRate {
            analytics.capture(.reviewPromptDismissed)
        }
        let shouldRequestSystemPrompt = ratedHigh
        ratedHigh = false
        return shouldRequestSystemPrompt
    }
}
