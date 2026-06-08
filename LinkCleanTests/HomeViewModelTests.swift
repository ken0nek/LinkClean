//
//  HomeViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
@testable import LinkClean
import LinkCleanKit

@MainActor
struct HomeViewModelTests {

    @Test func isInputEmptyWhenBlank() {
        let vm = HomeViewModel(service: MockURLCleaningService())
        vm.inputText = ""

        #expect(vm.isInputEmpty == true)
    }

    @Test func isInputEmptyWhenWhitespace() {
        let vm = HomeViewModel(service: MockURLCleaningService())
        vm.inputText = "   "

        #expect(vm.isInputEmpty == true)
    }

    @Test func isInputNotEmpty() {
        let vm = HomeViewModel(service: MockURLCleaningService())
        vm.inputText = "https://example.com"

        #expect(vm.isInputEmpty == false)
    }

    @Test func isInputValidURLDelegatesToService() {
        var mock = MockURLCleaningService()
        mock.isValidURLHandler = { $0.contains("valid") }
        let vm = HomeViewModel(service: mock)

        vm.inputText = "valid-url"
        #expect(vm.isInputValidURL == true)

        vm.inputText = "nope"
        #expect(vm.isInputValidURL == false)
    }

    @Test func shouldShowInvalidWhenNotEmptyAndInvalid() {
        var mock = MockURLCleaningService()
        mock.isValidURLHandler = { _ in false }
        let vm = HomeViewModel(service: mock)

        vm.inputText = "not-a-url"

        #expect(vm.shouldShowInvalidInputMessage == true)
    }

    @Test func shouldNotShowInvalidWhenEmpty() {
        var mock = MockURLCleaningService()
        mock.isValidURLHandler = { _ in false }
        let vm = HomeViewModel(service: mock)

        vm.inputText = ""

        #expect(vm.shouldShowInvalidInputMessage == false)
    }

    @Test func cleanedTextEmptyByDefault() {
        let vm = HomeViewModel(service: MockURLCleaningService())

        #expect(vm.cleanedText == "")
    }

    @Test func clearInputResets() {
        let vm = HomeViewModel(service: MockURLCleaningService())
        vm.inputText = "https://example.com"
        vm.clearInput()

        #expect(vm.inputText == "")
        #expect(vm.isInputEmpty == true)
    }

    @Test func inputSanitizesNewlines() {
        let vm = HomeViewModel(service: MockURLCleaningService())
        vm.inputText = "https://example\n.com"

        #expect(!vm.inputText.contains("\n"))
    }

    // MARK: - Analytics

    @Test func invalidClipboardPasteEmitsSignal() {
        let spy = SpyAnalytics()
        let vm = HomeViewModel(service: MockURLCleaningService(), analytics: spy)

        vm.showInvalidClipboardToast()

        #expect(spy.events == [.homeClipboardInvalidPasted])
    }

    @Test func cleanThenCopyEmitsBothSignals() async {
        let spy = SpyAnalytics()
        var mock = MockURLCleaningService()
        mock.cleanHandler = { input in CleanedURL(input: input, output: "https://clean.example", removedCount: 1) }
        let vm = HomeViewModel(service: mock, analytics: spy)

        // A full string arriving in one binding update reads as a manual paste.
        vm.inputText = "https://x.com?utm_source=a"

        for _ in 0 ..< 200 where spy.events.isEmpty {
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(spy.events == [.homeURLCleaned(
            source: .manualPaste, changed: true, removedCount: 1,
            leftoverCount: 0, referenceMatchCount: 0, removedKinds: []
        )])

        vm.copyCleanedURL()

        #expect(spy.events.last == .homeURLCopied(changed: true))
    }

    @Test func cleanedSignalIsDedupedPerDistinctInput() async {
        let spy = SpyAnalytics()
        var mock = MockURLCleaningService()
        mock.cleanHandler = { input in CleanedURL(input: input, output: "https://clean.example", removedCount: 1) }
        let vm = HomeViewModel(service: mock, analytics: spy)

        vm.inputText = "https://x.com?utm_source=a"
        for _ in 0 ..< 200 where spy.events.isEmpty {
            try? await Task.sleep(for: .milliseconds(10))
        }
        // Re-assigning the same input (e.g. re-focus / tab return) must not
        // re-emit the once-per-input signal.
        vm.inputText = "https://x.com?utm_source=a"
        try? await Task.sleep(for: .milliseconds(80))

        let expected = AnalyticsEvent.homeURLCleaned(
            source: .manualPaste, changed: true, removedCount: 1,
            leftoverCount: 0, referenceMatchCount: 0, removedKinds: []
        )
        #expect(spy.events.filter { $0 == expected }.count == 1)
    }

    @Test func referenceMatchesEmitOnePerMatch() async {
        let spy = SpyAnalytics()
        var mock = MockURLCleaningService()
        mock.cleanHandler = { input in
            CleanedURL(
                input: input, output: "https://clean.example",
                removedCount: 1, referenceMatches: ["gbraid", "yclid"]
            )
        }
        let vm = HomeViewModel(service: mock, analytics: spy)

        vm.inputText = "https://x.com?utm_source=a"
        for _ in 0 ..< 200 where spy.events.isEmpty {
            try? await Task.sleep(for: .milliseconds(10))
        }

        // The clean event plus exactly one Parameters.Reference.observed per match.
        let referenceEvents = spy.events.filter {
            if case .parametersReferenceObserved = $0 { return true }
            return false
        }
        #expect(referenceEvents.count == 2)
        #expect(referenceEvents.contains(.parametersReferenceObserved(parameter: "gbraid")))
        #expect(referenceEvents.contains(.parametersReferenceObserved(parameter: "yclid")))
    }

    @Test func referenceMatchesAreDedupedPerInput() async {
        let spy = SpyAnalytics()
        var mock = MockURLCleaningService()
        mock.cleanHandler = { input in
            CleanedURL(
                input: input, output: "https://clean.example",
                removedCount: 1, referenceMatches: ["yclid"]
            )
        }
        let vm = HomeViewModel(service: mock, analytics: spy)

        vm.inputText = "https://x.com?utm_source=a"
        for _ in 0 ..< 200 where spy.events.isEmpty {
            try? await Task.sleep(for: .milliseconds(10))
        }
        let countAfterFirstClean = spy.events.count

        // Re-cleaning the same input must not re-emit the clean signal or any of
        // its reference-observed signals (the per-input dedup guard covers both).
        vm.inputText = "https://x.com?utm_source=a"
        try? await Task.sleep(for: .milliseconds(80))

        #expect(spy.events.count == countAfterFirstClean)
    }
}
