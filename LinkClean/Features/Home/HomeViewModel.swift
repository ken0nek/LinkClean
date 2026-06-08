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
    var focusResetToken = UUID()
    @ObservationIgnored private let service: URLCleaningService
    @ObservationIgnored private let analytics: AnalyticsService
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let store: TrackingParameterStore
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
    // Dedupes `Home.URL.copied` and the history-row insert per distinct cleaned
    // *output*: repeated taps on one result count once, but re-copying after a
    // leftover-pill refine (same input, cleaner output) correctly counts again.
    @ObservationIgnored private var lastCopiedOutput: String?

    init(
        service: URLCleaningService = DefaultURLCleaningService(),
        analytics: AnalyticsService = TelemetryDeckAnalytics(),
        settings: SettingsStore = SettingsStore(),
        store: TrackingParameterStore = TrackingParameterStore()
    ) {
        self.service = service
        self.analytics = analytics
        self.settings = settings
        self.store = store
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
        guard !cleanedText.isEmpty else { return }
        UIPasteboard.general.string = cleanedText
        didCopy = true

        if let cleanedURL, cleanedURL.output != lastCopiedOutput {
            lastCopiedOutput = cleanedURL.output
            analytics.capture(.homeURLCopied(changed: cleanedURL.changed))
            if isSaveHistoryEnabled {
                let entry = HistoryEntry(input: cleanedURL.input, output: cleanedURL.output)
                modelContext?.insert(entry)
            }
        }

        copyTask?.cancel()
        copyTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            didCopy = false
        }
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
            removedKinds: result.removedKindIDs
        ))
        // Tier 1: one signal per known-but-not-default tracker left behind, so
        // the default catalog can grow from real links. Names are public
        // reference-catalog entries (`parameter-telemetry.md`).
        for parameter in result.referenceMatches {
            analytics.capture(.parametersReferenceObserved(parameter: parameter))
        }
    }
}
