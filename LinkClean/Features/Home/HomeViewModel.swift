//
//  HomeViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation
import LinkCleanCore
import LinkCleanAnalytics
import LinkCleanData
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
    /// The dedup ledger for this session — holds the current cleaned outcome and
    /// owns the export/signal dedup keys. Observed so `cleanedText` and the pills
    /// update when `setOutcome` runs.
    var session = CleanSession()
    /// The advisor's dedup/suppression ledger — owns the surfaced suggestion and
    /// the per-input dismissed/engaged state (the value-type sibling of
    /// ``CleanSession``). Observed so the suggestion card updates when the ledger
    /// mutates; the debounced task feeds it derived suggestions.
    var advisorSession = AdvisorSession()
    var didCopy = false
    var showClipboardToast = false
    var focusResetToken = UUID()
    /// The advisor's single proactive pick for the current clean, or `nil` —
    /// drives the Home suggestion card, read through the ledger.
    var suggestion: ParameterSuggestion? { advisorSession.suggestion }
    /// Owns the in-app review prompt (eligibility, grace delay, presentation,
    /// rated-high handoff). HomeView renders `reviewFlow.isPresenting`; this model
    /// only feeds it exports. Read through it observes its `isPresenting`.
    @ObservationIgnored let reviewFlow: ReviewPromptFlow
    @ObservationIgnored private let service: CleaningService
    @ObservationIgnored private let analytics: AnalyticsService
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let store: TrackingParameterStore
    @ObservationIgnored private let advisor: ParameterAdvising
    @ObservationIgnored private let history: HistoryStore
    @ObservationIgnored private let stats: StatsStore
    @ObservationIgnored private var cleanTask: Task<Void, Never>?
    @ObservationIgnored private var copyTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var isHomeVisible = false
    @ObservationIgnored private var didRunInitialPaste = false
    @ObservationIgnored private var didPrewarmAdvisor = false
    // Source attribution for `Home.URL.cleaned`. SwiftUI can't tell a paste from
    // typing on a TextField binding, so we infer: a programmatic clipboard fill
    // is `autoPaste`; a single new character is `typed`; a larger jump is
    // `manualPaste`. The once-per-input signal dedup lives in CleanSession.
    @ObservationIgnored private var nextCleanSource: AnalyticsEvent.CleanSource = .typed
    @ObservationIgnored private var isApplyingAutoPaste = false
    @ObservationIgnored private var isSanitizing = false
    // One-time removals from the leftover pills' "Remove Once" action: extra
    // parameters stripped from the *current* link only, never persisted. Any
    // input edit clears the set — it described the previous link.
    @ObservationIgnored private var oneTimeRemovals: Set<String> = []
    @ObservationIgnored private var advisorTask: Task<Void, Never>?

    init(
        service: CleaningService = DefaultCleaningService(),
        analytics: AnalyticsService = TelemetryDeckAnalytics(),
        settings: SettingsStore = SettingsStore(),
        store: TrackingParameterStore = TrackingParameterStore(),
        review: ReviewService = DefaultReviewService(),
        // Test/preview default is the no-op advisor (production injects the real
        // one via the composition root), so a clean in a test never schedules
        // model work — mirrors `HistoryStore.inMemoryPreview`.
        advisor: ParameterAdvising = DisabledParameterAdvisor(),
        history: HistoryStore = .inMemoryPreview,
        stats: StatsStore = StatsStore(),
        advisorDebounce: Duration = .milliseconds(350)
    ) {
        self.service = service
        self.analytics = analytics
        self.settings = settings
        self.store = store
        self.advisor = advisor
        self.history = history
        self.stats = stats
        self.advisorDebounce = advisorDebounce
        self.reviewFlow = ReviewPromptFlow(review: review, analytics: analytics)
    }

    // Debounce before the advisor runs after a clean, keeping the on-device model
    // off the per-keystroke path (a distinct input cleans on every change).
    // Injectable so tests run it without the wait.
    @ObservationIgnored private let advisorDebounce: Duration

    private var isAutoPasteEnabled: Bool { settings.autoPasteEnabled }

    var isSaveHistoryEnabled: Bool { settings.saveHistoryEnabled }

    /// Current custom-rule count, read live for the leftover-pill gate (T2). Not
    /// an observed property — checked at tap time, and the pill shows no lock at
    /// rest, so it needs no reactive refresh.
    var customParameterCount: Int { store.customParameters().count }

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
        session.outcome?.cleaned ?? ""
    }

    /// The outermost redirect wrapper peeled before cleaning — the host the user
    /// actually pasted (`google.com` for a `google.com/url?q=…` link) — driving
    /// the "redirect expanded" note. `nil` when the input was not a wrapper. Reads
    /// the analytics-safe ``CleanOutcome/Telemetry`` view (public wrapper domains,
    /// never raw URL data).
    var unwrappedFromHost: String? {
        session.outcome?.telemetry.wrappers.first
    }

    /// Exact names removed in producing `cleanedText` — the calm proof-of-work
    /// list shown on Home. The on-device ``CleanOutcome/Display`` view; the type
    /// system keeps these raw names out of analytics.
    var removedParameters: [String] {
        session.outcome?.display.removedNames ?? []
    }

    /// Every parameter that survived cleaning — the actionable "remaining" pills —
    /// minus the one currently surfaced as a ``suggestion`` (it's shown once, in
    /// the advisor card above). Dismissing the suggestion returns its name here so
    /// the user can still act on it manually. Display-only raw query keys (the
    /// ``CleanOutcome/Display`` view, never sent to analytics); tapping one offers
    /// "Remove Once" (``removeLeftoverParameterOnce(_:)``, this link only) or
    /// "Always Remove" (``addLeftoverParameter(_:)``, the custom set).
    var leftoverParameters: [String] {
        let all = session.outcome?.display.leftoverNames ?? []
        guard let suggested = suggestion?.name.lowercased() else { return all }
        return all.filter { $0.lowercased() != suggested }
    }

    func clearInput() {
        inputText = ""
    }

    func copyCleanedURL() {
        guard let outcome = session.outcome, !outcome.cleaned.isEmpty else { return }
        UIPasteboard.general.string = outcome.cleaned
        didCopy = true

        let effects = session.noteCopy(saveHistoryEnabled: isSaveHistoryEnabled)
        if effects.signalExport {
            analytics.capture(.homeURLCopied(changed: outcome.telemetry.changed))
            if effects.recordHistory { history.record(outcome) }
            reviewFlow.noteExport(counted: effects.countForReview)
        }

        copyTask?.cancel()
        copyTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            didCopy = false
        }
    }

    /// Records a Home share via the system share sheet. Hooked to the ShareLink
    /// tap (best-effort, mirroring History). The ``CleanSession`` ledger dedupes
    /// it per distinct output and shares the single history row with copy.
    func recordShare() {
        guard let outcome = session.outcome, !outcome.cleaned.isEmpty else { return }
        let effects = session.noteShare(saveHistoryEnabled: isSaveHistoryEnabled)
        guard effects.signalExport else { return }
        analytics.capture(.homeURLShared(changed: outcome.telemetry.changed))
        if effects.recordHistory { history.record(outcome) }
        reviewFlow.noteExport(counted: effects.countForReview)
    }

    /// The "Always Remove" gate decision (T2): a free user past their one custom
    /// rule must hit the paywall; otherwise the leftover is promoted to an
    /// always-remove rule right here. Composes entitlement + the live custom-rule
    /// count + ``ProGate`` policy in the model rather than a view closure (P10). On
    /// `.allowed` the add has already happened — the view only plays its haptic;
    /// on `.gated` the view raises the paywall (after the dialog's dismiss grace).
    func requestAlwaysRemove(_ name: String, entitlement: Entitlement) -> GateResult {
        promoteToAlwaysRemove(name, entitlement: entitlement, gatedBy: .customParamHome)
    }

    /// The shared Always-Remove gate (T2): promote `name` to a persisted custom
    /// rule when the free allowance permits (Pro is unlimited), else return the
    /// paywall `trigger`. Both the leftover-pill path and the advisor card route
    /// through here, so the gate policy and the add side effect live in one place.
    private func promoteToAlwaysRemove(
        _ name: String,
        entitlement: Entitlement,
        gatedBy trigger: AnalyticsEvent.PaywallTrigger
    ) -> GateResult {
        guard ProGate.canAddCustomRule(entitlement: entitlement, currentCount: customParameterCount) else {
            return .gated(trigger)
        }
        addLeftoverParameter(name)
        return .allowed
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

    /// Strips a surfaced leftover from the *current* link only — the pill's
    /// "Remove Once" action. Nothing is persisted, so the parameter survives the
    /// next link as usual (the YouTube-timestamp case: trim this `t` without
    /// breaking `t` everywhere). Same re-clean mechanics as
    /// ``addLeftoverParameter(_:)``, including the suppressed per-input signal.
    func removeLeftoverParameterOnce(_ name: String) {
        oneTimeRemovals.insert(name.lowercased())
        analytics.capture(.parametersLeftoverRemovedOnce)
        refreshCleanedURL()
    }

    /// Recomputes the at-most-one tracker suggestion for the current outcome.
    /// Candidates are the leftovers minus managed catalog defaults (handled by
    /// the Settings toggles, not the advisor) and names the user already
    /// dismissed. A still-valid suggestion is kept to avoid flicker as a typed
    /// URL grows; otherwise it's cleared and a debounced, cancellable task
    /// re-derives one — the debounce keeps the on-device model off the
    /// per-keystroke path, and once the user has engaged the advisor for this
    /// input nothing new auto-surfaces.
    private func updateAdvisor(for outcome: CleanOutcome?) {
        advisorTask?.cancel()

        guard let outcome else { advisorSession.surface(nil); return }

        let candidates = advisorSession.candidates(from: outcome.display.leftoverNames)

        // Keep a still-applicable suggestion — no flicker on re-cleans of a
        // growing URL — otherwise clear and re-derive below.
        if advisorSession.keepsCurrent(amongCandidates: candidates) { return }
        advisorSession.surface(nil)

        guard !candidates.isEmpty, !advisorSession.isEngaged(with: outcome.input) else { return }

        let input = outcome.input
        advisorTask = Task { @MainActor in
            try? await Task.sleep(for: advisorDebounce)
            guard !Task.isCancelled else { return }
            let proposed = await advisor.suggestion(among: candidates)
            // Bail if the input moved on while we were classifying, or the user
            // engaged the advisor in the meantime.
            guard !Task.isCancelled,
                  let proposed,
                  session.outcome?.input == input,
                  !advisorSession.isEngaged(with: input) else { return }
            if advisorSession.surface(proposed) {
                analytics.capture(.parametersAdvisorSuggested(tier: proposed.tier))
            }
        }
    }

    /// Accepts the current advisor suggestion (the card's "Always Remove"):
    /// records the funnel intent, then promotes it to an always-remove rule when
    /// the free allowance permits, or returns the gate. Mirrors
    /// ``requestAlwaysRemove(_:entitlement:)`` but tags the paywall as
    /// advisor-driven (``AnalyticsEvent/PaywallTrigger/advisorAccept``). On
    /// `.allowed` the add has happened and the suggestion is cleared; on `.gated`
    /// the suggestion stays so a returning non-buyer can retry.
    func acceptSuggestion(entitlement: Entitlement) -> GateResult {
        guard let suggestion = advisorSession.suggestion else { return .allowed }
        // Record the accept *intent* once per engaged input. The suggestion-quality
        // read (accept vs dismiss, ai-features §9-A) must stay entitlement-independent,
        // so it fires even when gated — but a gated card stays on screen and
        // re-tappable, so the ledger dedupes repeated taps against the engaged mark.
        if advisorSession.noteAccept(input: session.outcome?.input) {
            analytics.capture(.parametersAdvisorAccepted(tier: suggestion.tier))
        }
        let result = promoteToAlwaysRemove(suggestion.name, entitlement: entitlement, gatedBy: .advisorAccept)
        if case .allowed = result { advisorSession.surface(nil) }
        return result
    }

    /// Dismisses the current suggestion ("Not now"). The ledger remembers the name
    /// (not proposed again for this link), suppresses further auto-suggestion for
    /// the input, clears the card, and reports whether to fire `Advisor.dismissed`
    /// — once per engaged input, and **not** after an accept (a gated accept then
    /// "Not now" counts as the accept). The name returns to the leftover pills.
    func dismissSuggestion() {
        guard let suggestion = advisorSession.suggestion else { return }
        if advisorSession.noteDismiss(input: session.outcome?.input) {
            analytics.capture(.parametersAdvisorDismissed(tier: suggestion.tier))
        }
    }

    /// Awaits the in-flight advisor task. Test seam only — production reacts to
    /// `suggestion` via observation.
    func waitForAdvisor() async {
        await advisorTask?.value
    }

    func onAppear() {
        isHomeVisible = true
        reviewFlow.setVisible(true)
        // Warm the model once per session so the first suggestion after a paste
        // doesn't pay load latency; no-op on devices without Apple Intelligence.
        // Assets are process-shared, so re-warming on every tab return is wasted
        // churn — latch it like `didRunInitialPaste`.
        if !didPrewarmAdvisor {
            didPrewarmAdvisor = true
            advisor.prewarm()
        }

        if !didRunInitialPaste, isAutoPasteEnabled {
            didRunInitialPaste = true
            tryPasteFromClipboard()
        }

        refreshCleanedURL()
    }

    func onDisappear() {
        isHomeVisible = false
        // The flow cancels any pending review offer so it can't surface over a
        // backgrounded or torn-down Home.
        reviewFlow.setVisible(false)
        // Drop any in-flight advisor work so a suggestion can't resolve, set
        // state, fire `Advisor.suggested`, or run on-device inference while Home
        // is off-screen — it re-derives on the next appear via refreshCleanedURL.
        advisorTask?.cancel()
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

        // Any real edit means a new link state; one-time removals described the
        // previous link and must not silently carry into this one. The advisor
        // ledger likewise resets its per-link dismissals and "engaged" mark.
        oneTimeRemovals.removeAll()
        advisorSession.beginInput()

        // The session resets its per-input/per-output dedup keys when the input
        // becomes empty — deliberately keeping the review counter (clearing and
        // re-pasting the same URL is the same realized value). See CleanSession.
        session.beginInput(trimmedInput)

        refreshCleanedURL()
    }

    private func refreshCleanedURL() {
        cleanTask?.cancel()
        // Drop any pending suggestion work the instant the input changes; the
        // completion below re-derives it for the new outcome.
        advisorTask?.cancel()

        guard !isInputEmpty, isInputValidURL else {
            session.setOutcome(nil)
            updateAdvisor(for: nil)
            return
        }

        let inputSnapshot = trimmedInput
        let removalsSnapshot = oneTimeRemovals
        let source = nextCleanSource
        cleanTask = Task { [service] in
            let outcome = try? await service.clean(inputSnapshot, removingAlso: removalsSnapshot)
            await MainActor.run { [inputSnapshot] in
                guard inputSnapshot == self.trimmedInput,
                      removalsSnapshot == self.oneTimeRemovals else { return }
                // setOutcome records the outcome and decides the once-per-input
                // cleaned signal (suppressed on re-cleans and leftover refines).
                if self.session.setOutcome(outcome), let outcome {
                    self.signalCleaned(outcome, source: source)
                }
                // Re-derive the suggestion for the current outcome (debounced),
                // on every clean — including re-cleans, which may have removed the
                // suggested name and need it cleared.
                self.updateAdvisor(for: self.session.outcome)
            }
        }
    }

    /// Emits `Home.URL.cleaned` for a freshly-signaled outcome (the session
    /// already decided this is a new input). The event takes the outcome's
    /// ``CleanOutcome/Telemetry`` directly — the analytics-safe view, domain and
    /// catalog-gap signals included — so no field is re-plumbed or re-derived.
    private func signalCleaned(_ outcome: CleanOutcome, source: AnalyticsEvent.CleanSource) {
        analytics.capture(.homeURLCleaned(source: source, telemetry: outcome.telemetry))
        // Tier 1: one signal per known-but-not-default tracker left behind, so
        // the default catalog can grow from real links. These ride in the
        // privacy-safe Telemetry — public reference-catalog names only.
        for parameter in outcome.telemetry.referenceMatches {
            analytics.capture(.parametersReferenceObserved(parameter: parameter))
        }
        stats.record(outcome.telemetry)
    }
}
