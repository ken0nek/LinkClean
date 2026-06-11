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
    var didCopy = false
    var showClipboardToast = false
    var focusResetToken = UUID()
    /// The leftover parameter whose on-device explanation is being generated, or
    /// `nil` when idle. Drives the pill's progress spinner; observed.
    private(set) var explainingParameter: String?
    /// Owns the in-app review prompt (eligibility, grace delay, presentation,
    /// rated-high handoff). HomeView renders `reviewFlow.isPresenting`; this model
    /// only feeds it exports. Read through it observes its `isPresenting`.
    @ObservationIgnored let reviewFlow: ReviewPromptFlow
    @ObservationIgnored private let service: CleaningService
    @ObservationIgnored private let analytics: AnalyticsService
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let store: TrackingParameterStore
    @ObservationIgnored private let explanationService: ParameterExplanationService
    @ObservationIgnored private var cleanTask: Task<Void, Never>?
    @ObservationIgnored private var copyTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var modelContext: ModelContext?
    @ObservationIgnored private var isHomeVisible = false
    @ObservationIgnored private var didRunInitialPaste = false
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
    // On-device parameter explanations, keyed by lowercased name. Generated lazily
    // when a leftover pill is tapped and cached for the session — a name's
    // explanation is stable, so it's fetched at most once.
    @ObservationIgnored private var parameterExplanations: [String: ParameterExplanation] = [:]

    init(
        service: CleaningService = DefaultCleaningService(),
        analytics: AnalyticsService = TelemetryDeckAnalytics(),
        settings: SettingsStore = SettingsStore(),
        store: TrackingParameterStore = TrackingParameterStore(),
        review: ReviewService = DefaultReviewService(),
        explanationService: ParameterExplanationService = FoundationModelsParameterExplanationService()
    ) {
        self.service = service
        self.analytics = analytics
        self.settings = settings
        self.store = store
        self.explanationService = explanationService
        self.reviewFlow = ReviewPromptFlow(review: review, analytics: analytics)
    }

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

    /// Exact names removed in producing `cleanedText` — the calm proof-of-work
    /// list shown on Home. The on-device ``CleanOutcome/Display`` view; the type
    /// system keeps these raw names out of analytics.
    var removedParameters: [String] {
        session.outcome?.display.removedNames ?? []
    }

    /// Every parameter that survived cleaning — the actionable "remaining" pills.
    /// Display-only raw query keys (the ``CleanOutcome/Display`` view, never sent
    /// to analytics); tapping one offers "Remove Once"
    /// (``removeLeftoverParameterOnce(_:)``, this link only) or "Always Remove"
    /// (``addLeftoverParameter(_:)``, the custom set).
    var leftoverParameters: [String] {
        session.outcome?.display.leftoverNames ?? []
    }

    func clearInput() {
        inputText = ""
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func copyCleanedURL() {
        guard let outcome = session.outcome, !outcome.cleaned.isEmpty else { return }
        UIPasteboard.general.string = outcome.cleaned
        didCopy = true

        let effects = session.noteCopy(saveHistoryEnabled: isSaveHistoryEnabled)
        if effects.signalExport {
            analytics.capture(.homeURLCopied(changed: outcome.telemetry.changed))
            if effects.recordHistory { insertHistoryRow(for: outcome) }
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
        if effects.recordHistory { insertHistoryRow(for: outcome) }
        reviewFlow.noteExport(counted: effects.countForReview)
    }

    /// Writes a history row for `outcome`. Whether to write at all (per-output
    /// dedup + the save-history setting) is decided by the ``CleanSession`` ledger's
    /// `recordHistory` effect; this just performs the insert.
    private func insertHistoryRow(for outcome: CleanOutcome) {
        let entry = HistoryEntry(input: outcome.input, output: outcome.cleaned)
        modelContext?.insert(entry)
    }

    /// The "Always Remove" gate decision (T2): a free user past their one custom
    /// rule must hit the paywall; otherwise the leftover is promoted to an
    /// always-remove rule right here. Composes entitlement + the live custom-rule
    /// count + ``ProGate`` policy in the model rather than a view closure (P10). On
    /// `.allowed` the add has already happened — the view only plays its haptic;
    /// on `.gated` the view raises the paywall (after the dialog's dismiss grace).
    func requestAlwaysRemove(_ name: String, entitlement: Entitlement) -> GateResult {
        guard ProGate.canAddCustomRule(entitlement: entitlement, currentCount: customParameterCount) else {
            return .gated(.customParamHome)
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

    /// Whether the on-device model can explain a parameter. The view reads this to
    /// decide whether tapping a pill is worth a brief wait or should open the
    /// generic dialog immediately.
    var isParameterExplanationAvailable: Bool {
        explanationService.isAvailable
    }

    /// The cached one-line explanation for `parameter`, or `nil` if none was
    /// generated (model unavailable, generation failed, or not yet prepared). Read
    /// synchronously by the confirm dialog, so it must already be cached — see
    /// ``prepareExplanation(for:)``.
    func explanation(for parameter: String) -> String? {
        parameterExplanations[parameter.lowercased()]?.oneLiner
    }

    /// Generates and caches a leftover parameter's explanation *before* its confirm
    /// dialog opens — the dialog's message isn't reactive, so the text must be
    /// ready at present time. No-ops when the model is unavailable or the parameter
    /// is already cached, so those paths present instantly. Sets
    /// ``explainingParameter`` for the duration so the pill can show a spinner.
    func prepareExplanation(for parameter: String) async {
        let key = parameter.lowercased()
        guard explanationService.isAvailable else { return }
        guard parameterExplanations[key] == nil else { return }
        // One generation at a time; a second tap during the brief wait is ignored
        // (the alert blocks further taps once it opens).
        guard explainingParameter == nil else { return }

        explainingParameter = parameter
        defer { explainingParameter = nil }

        if let explanation = await explanationService.explain(parameter: parameter) {
            parameterExplanations[key] = explanation
        }
    }

    func onAppear() {
        isHomeVisible = true
        reviewFlow.setVisible(true)

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
        // previous link and must not silently carry into this one.
        oneTimeRemovals.removeAll()

        // The session resets its per-input/per-output dedup keys when the input
        // becomes empty — deliberately keeping the review counter (clearing and
        // re-pasting the same URL is the same realized value). See CleanSession.
        session.beginInput(trimmedInput)

        refreshCleanedURL()
    }

    private func refreshCleanedURL() {
        cleanTask?.cancel()

        guard !isInputEmpty, isInputValidURL else {
            session.setOutcome(nil)
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
    }
}
