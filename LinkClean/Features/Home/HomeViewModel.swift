//
//  HomeViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation
import LinkCleanKit
import Observation
import SwiftData
import UIKit

@MainActor
@Observable
final class HomeViewModel {
    var inputText = "" {
        didSet {
            handleInputTextChange(previous: oldValue)
        }
    }
    private(set) var cleanedURL: CleanedURL?
    var didCopy = false
    var showClipboardToast = false
    /// Drives the in-app review star sheet (``ReviewGateSheet``). Set by the view
    /// model at a value moment; the system clears it on dismiss.
    var showReviewGate = false
    var focusResetToken = UUID()
    @ObservationIgnored private let service: URLCleaningService
    @ObservationIgnored private let analytics: AnalyticsService
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let store: TrackingParameterStore
    @ObservationIgnored private let review: ReviewService
    @ObservationIgnored private var cleanTask: Task<Void, Never>?
    @ObservationIgnored private var copyTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var modelContext: ModelContext?
    @ObservationIgnored private var isHomeVisible = false
    @ObservationIgnored private var didRunInitialPaste = false
    // Source attribution for `Home.URL.cleaned`. SwiftUI can't tell a paste from
    // typing on a TextField binding, so we infer: a programmatic clipboard fill
    // is `autoPaste`; a single new character is `typed`; a larger jump is
    // `manualPaste`. `lastSignaledCleanInput` dedupes the once-per-input signal
    // across re-cleans (e.g. returning to the tab).
    @ObservationIgnored private var nextCleanSource: AnalyticsEvent.CleanSource = .typed
    @ObservationIgnored private var isApplyingAutoPaste = false
    @ObservationIgnored private var isSanitizing = false
    @ObservationIgnored private var lastSignaledCleanInput: String?
    // Dedupes the export signals per distinct cleaned *output*: repeated taps on
    // one result count once, but exporting again after a leftover-pill refine
    // (same input, cleaner output) correctly counts again. Copy and share track
    // separately (a user can do both), while `lastRecordedHistoryOutput` is
    // shared so copy-then-share writes one history row, not two.
    @ObservationIgnored private var lastCopiedOutput: String?
    @ObservationIgnored private var lastSharedOutput: String?
    @ObservationIgnored private var lastRecordedHistoryOutput: String?
    // Review-prompt state. `lastReviewCountedOutput` dedupes the success counter
    // per distinct exported output (copy-then-share of one URL counts once);
    // `didOfferReviewThisSession` caps the prompt at once per app run.
    @ObservationIgnored private var lastReviewCountedOutput: String?
    @ObservationIgnored private var didOfferReviewThisSession = false
    @ObservationIgnored private var reviewTask: Task<Void, Never>?
    // Per-presentation review-sheet state: whether the user rated at all (a
    // dismissal without a rating is a decline) and whether it was a high rating
    // (defers Apple's `requestReview()` until after the sheet dismisses).
    @ObservationIgnored private var reviewDidRate = false
    @ObservationIgnored private var reviewRatedHigh = false

    init(
        service: URLCleaningService = DefaultURLCleaningService(),
        analytics: AnalyticsService = TelemetryDeckAnalytics(),
        settings: SettingsStore = SettingsStore(),
        store: TrackingParameterStore = TrackingParameterStore(),
        review: ReviewService = DefaultReviewService()
    ) {
        self.service = service
        self.analytics = analytics
        self.settings = settings
        self.store = store
        self.review = review
    }

    private var isAutoPasteEnabled: Bool { settings.autoPasteEnabled }

    var isSaveHistoryEnabled: Bool { settings.saveHistoryEnabled }

    var isInputEmpty: Bool {
        trimmedInput.isEmpty
    }

    var isInputValidURL: Bool {
        service.isValidURL(trimmedInput)
    }

    var shouldShowInvalidInputMessage: Bool {
        !isInputEmpty && !isInputValidURL
    }

    var cleanedText: String {
        cleanedURL?.output ?? ""
    }

    /// Exact names removed in producing `cleanedText` — the calm proof-of-work
    /// list shown on Home. Display-only; never sent to analytics.
    var removedParameters: [String] {
        cleanedURL?.removedNames ?? []
    }

    /// Every parameter that survived cleaning — the actionable "remaining" pills.
    /// Display-only raw query keys (never sent to analytics); tapping one adds it
    /// to the always-remove custom set via ``addLeftoverParameter(_:)``.
    var leftoverParameters: [String] {
        cleanedURL?.leftoverNames ?? []
    }

    func clearInput() {
        inputText = ""
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func copyCleanedURL() {
        guard let cleanedURL, !cleanedURL.output.isEmpty else { return }
        UIPasteboard.general.string = cleanedURL.output
        didCopy = true

        if cleanedURL.output != lastCopiedOutput {
            lastCopiedOutput = cleanedURL.output
            analytics.capture(.homeURLCopied(changed: cleanedURL.changed))
            recordHistoryIfNeeded(for: cleanedURL)
            noteExportForReview(cleanedURL.output)
        }

        copyTask?.cancel()
        copyTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            didCopy = false
        }
    }

    /// Records a Home share via the system share sheet. Hooked to the ShareLink
    /// tap (best-effort, mirroring History) — deduped per distinct cleaned output,
    /// and writes the same single history row a copy would.
    func recordShare() {
        guard let cleanedURL, !cleanedURL.output.isEmpty else { return }
        guard cleanedURL.output != lastSharedOutput else { return }
        lastSharedOutput = cleanedURL.output
        analytics.capture(.homeURLShared(changed: cleanedURL.changed))
        recordHistoryIfNeeded(for: cleanedURL)
        noteExportForReview(cleanedURL.output)
    }

    /// Inserts a history row for `cleanedURL` once per distinct output — whether
    /// reached by copy or share — when history saving is enabled.
    private func recordHistoryIfNeeded(for cleanedURL: CleanedURL) {
        guard isSaveHistoryEnabled, cleanedURL.output != lastRecordedHistoryOutput else { return }
        lastRecordedHistoryOutput = cleanedURL.output
        let entry = HistoryEntry(input: cleanedURL.input, output: cleanedURL.output)
        modelContext?.insert(entry)
    }

    /// Counts a distinct exported output toward review eligibility (once per
    /// output, whether reached by copy or share), then offers the prompt — the
    /// copy/share is the realized-value moment, the natural place to ask.
    private func noteExportForReview(_ output: String) {
        if output != lastReviewCountedOutput {
            lastReviewCountedOutput = output
            review.recordSuccess()
        }
        maybeOfferReview()
    }

    /// Schedules ``ReviewGateSheet`` if the gate is eligible and we haven't asked
    /// this session. A short delay lets the copy's checkmark and success haptic
    /// land before the sheet rises, so the two moments don't collide. `reviewTask`
    /// is cancelled in ``onDisappear()`` so it can't fire off-screen.
    private func maybeOfferReview() {
        guard !didOfferReviewThisSession, review.shouldRequestReview() else { return }
        didOfferReviewThisSession = true
        reviewTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled, isHomeVisible else { return }
            presentReviewGate()
        }
    }

    /// Commits to showing the prompt: stamps the persistent cooldown and emits the
    /// shown signal at the same instant `showReviewGate` flips, so backgrounding
    /// or a crash can't leave the gate re-armed with no cooldown recorded.
    private func presentReviewGate() {
        review.markPrompted()
        analytics.capture(.reviewPromptShown)
        reviewDidRate = false
        reviewRatedHigh = false
        showReviewGate = true
    }

    /// Records the star rating (bucket-only) the user gave the sheet. The hop to
    /// Apple's `requestReview()` is deferred to ``reviewGateDidDismiss()`` so it
    /// fires after our sheet is gone, not over it.
    func handleReviewRating(_ outcome: ReviewGateOutcome) {
        reviewDidRate = true
        switch outcome {
        case .ratedHigh:
            reviewRatedHigh = true
            analytics.capture(.reviewStarsSelected(bucket: .high))
            analytics.capture(.reviewSystemPromptRequested)
        case .ratedLow:
            analytics.capture(.reviewStarsSelected(bucket: .low))
        }
    }

    /// Called when the sheet finishes dismissing. Counts a dismissal when the user
    /// left without rating (covers both "Not now" and an interactive swipe), and
    /// returns whether the host should now present Apple's system prompt.
    func reviewGateDidDismiss() -> Bool {
        if !reviewDidRate {
            analytics.capture(.reviewPromptDismissed)
        }
        let shouldRequestSystemPrompt = reviewRatedHigh
        reviewRatedHigh = false
        return shouldRequestSystemPrompt
    }

    /// Adds a surfaced leftover tracker to the user's custom parameters so it is
    /// stripped from now on, then re-cleans the current input — moving the
    /// tracker out of `leftoverTrackers` and into `removedParameters`. The
    /// re-clean reuses the same input, so the once-per-input `Home.URL.cleaned`
    /// signal is not re-emitted; only the custom-add is.
    func addLeftoverParameter(_ name: String) {
        store.addCustomParameter(name)
        analytics.capture(.parametersCustomAdded(totalCount: store.customParameters().count))
        refreshCleanedURL()
    }

    func onAppear() {
        isHomeVisible = true

        if !didRunInitialPaste, isAutoPasteEnabled {
            didRunInitialPaste = true
            tryPasteFromClipboard()
        }

        refreshCleanedURL()
    }

    func onDisappear() {
        isHomeVisible = false
        // Cancel a pending review offer so it can't surface over a backgrounded
        // or torn-down Home (the sheet content is unrelated to the current URL).
        reviewTask?.cancel()
    }

    func handleSceneBecameActive() {
        guard isHomeVisible, isAutoPasteEnabled else { return }
        tryPasteFromClipboard()
    }

    func tryPasteFromClipboard() {
        guard isAutoPasteEnabled else { return }
        guard isInputEmpty else { return }

        let pasteboard = UIPasteboard.general
        let candidate = pasteboard.url?.absoluteString ?? pasteboard.string ?? ""
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard service.isValidURL(trimmed) else {
            showInvalidClipboardToast()
            return
        }

        isApplyingAutoPaste = true
        inputText = trimmed
        focusResetToken = UUID()
    }

    func showInvalidClipboardToast() {
        analytics.capture(.homeClipboardInvalidPasted)
        showClipboardToast = true

        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            showClipboardToast = false
        }
    }

    private var trimmedInput: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func handleInputTextChange(previous: String) {
        // Re-entrant call triggered by the sanitizing reassignment below: the
        // original edit was already classified and dispatched, so skip it.
        guard !isSanitizing else { return }

        // A new edit supersedes the previous result's "Copied" confirmation, so
        // the freshly-revealed action bar never shows a stale checkmark for a URL
        // the user didn't copy. (Copy itself doesn't change inputText, so a real
        // copy is never undone here.)
        if didCopy {
            didCopy = false
            copyTask?.cancel()
        }

        let sanitized = inputText.replacingOccurrences(of: "\n", with: "")
        // A newline can only arrive by pasting (the field submits on Return), so
        // a strip is a reliable paste signal. Classify before reassigning, since
        // the reassignment would otherwise re-enter didSet with a shrunken delta.
        let strippedNewline = sanitized != inputText
        if strippedNewline {
            isSanitizing = true
            inputText = sanitized
            isSanitizing = false
            focusResetToken = UUID()
        }

        if isApplyingAutoPaste {
            nextCleanSource = .autoPaste
            isApplyingAutoPaste = false
        } else if strippedNewline {
            nextCleanSource = .manualPaste
        } else {
            // Best-effort: one new character reads as typing, a larger jump as a
            // paste. SwiftUI can't observe paste-vs-type on a TextField binding,
            // so multi-character inserts (IME/autocomplete) and select-all-paste
            // can still be misattributed — autoPaste, the funnel-critical case,
            // is the only fully reliable source.
            nextCleanSource = inputText.count > previous.count + 1 ? .manualPaste : .typed
        }

        if isInputEmpty {
            lastSignaledCleanInput = nil
            lastCopiedOutput = nil
            lastSharedOutput = nil
            lastRecordedHistoryOutput = nil
            // `lastReviewCountedOutput` is deliberately NOT reset here: clearing
            // and re-pasting the same URL is the same realized value, so it must
            // not count toward review eligibility a second time.
        }

        refreshCleanedURL()
    }

    private func refreshCleanedURL() {
        cleanTask?.cancel()

        guard !isInputEmpty, isInputValidURL else {
            cleanedURL = nil
            return
        }

        let inputSnapshot = trimmedInput
        let source = nextCleanSource
        cleanTask = Task { [service] in
            let result = try? await service.clean(inputSnapshot)
            await MainActor.run { [inputSnapshot] in
                guard inputSnapshot == self.trimmedInput else { return }
                self.cleanedURL = result
                self.signalCleanedIfNeeded(result, source: source)
            }
        }
    }

    /// Emits `Home.URL.cleaned` once per distinct input. Re-cleans of the same
    /// input (returning to the tab, re-focusing) are suppressed.
    private func signalCleanedIfNeeded(_ result: CleanedURL?, source: AnalyticsEvent.CleanSource) {
        guard let result, result.input != lastSignaledCleanInput else { return }
        lastSignaledCleanInput = result.input
        analytics.capture(.homeURLCleaned(
            source: source,
            changed: result.changed,
            removedCount: result.removedCount,
            leftoverCount: result.leftoverCount,
            referenceMatchCount: result.referenceMatches.count,
            removedKinds: result.removedKindIDs,
            domain: URLCleaner.analyticsDomain(from: result.input)
        ))
        // Tier 1: one signal per known-but-not-default tracker left behind, so
        // the default catalog can grow from real links. Names are public
        // reference-catalog entries (`parameter-telemetry.md`).
        for parameter in result.referenceMatches {
            analytics.capture(.parametersReferenceObserved(parameter: parameter))
        }
    }
}
