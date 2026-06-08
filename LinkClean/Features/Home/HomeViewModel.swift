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
    @ObservationIgnored private var lastSignaledCleanInput: String?

    init(
        service: URLCleaningService = DefaultURLCleaningService(),
        analytics: AnalyticsService = TelemetryDeckAnalytics()
    ) {
        self.service = service
        self.analytics = analytics
    }

    private var isAutoPasteEnabled: Bool {
        UserDefaults.standard.object(forKey: SettingsKeys.autoPasteEnabled) as? Bool ?? true
    }

    var isSaveHistoryEnabled: Bool {
        UserDefaults(suiteName: AppGroup.identifier)?
            .object(forKey: SettingsKeys.saveHistoryEnabled) as? Bool ?? true
    }

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

        if let cleanedURL {
            analytics.capture(.homeURLCopied(changed: cleanedURL.input != cleanedURL.output))
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
        let sanitized = inputText.replacingOccurrences(of: "\n", with: "")
        if sanitized != inputText {
            inputText = sanitized
            focusResetToken = UUID()
            return
        }

        if isApplyingAutoPaste {
            nextCleanSource = .autoPaste
            isApplyingAutoPaste = false
        } else {
            nextCleanSource = inputText.count > previous.count + 1 ? .manualPaste : .typed
        }

        if isInputEmpty {
            lastSignaledCleanInput = nil
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
            changed: result.input != result.output,
            removedCount: URLCleaner.removedParameterCount(from: result.input, to: result.output)
        ))
    }
}
