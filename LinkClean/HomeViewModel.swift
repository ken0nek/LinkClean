//
//  HomeViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class HomeViewModel {
    var inputText = "" {
        didSet {
            handleInputTextChange()
        }
    }
    private(set) var cleanedURL: CleanedURL?
    var didCopy = false
    var showClipboardToast = false
    var focusResetToken = UUID()
    @ObservationIgnored private let service: URLCleaningService
    @ObservationIgnored private var cleanTask: Task<Void, Never>?
    @ObservationIgnored private var copyTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var isHomeVisible = false
    @ObservationIgnored private var didRunInitialPaste = false

    init(service: URLCleaningService = DefaultURLCleaningService()) {
        self.service = service
    }

    private var isAutoPasteEnabled: Bool {
        UserDefaults.standard.object(forKey: SettingsKeys.autoPasteEnabled) as? Bool ?? true
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

    func copyCleanedURL() {
        guard !cleanedText.isEmpty else { return }
        UIPasteboard.general.string = cleanedText
        didCopy = true

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

        inputText = trimmed
        focusResetToken = UUID()
    }

    func showInvalidClipboardToast() {
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

    private func handleInputTextChange() {
        let sanitized = inputText.replacingOccurrences(of: "\n", with: "")
        if sanitized != inputText {
            inputText = sanitized
            focusResetToken = UUID()
            return
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
        cleanTask = Task { [service] in
            let result = try? await service.clean(inputSnapshot)
            await MainActor.run { [inputSnapshot] in
                guard inputSnapshot == self.trimmedInput else { return }
                self.cleanedURL = result
            }
        }
    }
}
