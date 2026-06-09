//
//  HomeViewModelTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
import SwiftData
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

    @Test func copyIsDedupedForRepeatedTapsOnTheSameResult() async {
        let spy = SpyAnalytics()
        var mock = MockURLCleaningService()
        mock.cleanHandler = { input in CleanedURL(input: input, output: "https://clean.example", removedCount: 1) }
        // Isolated suites so save-history is deterministically on (default unset = on).
        let settings = SettingsStore(
            standardSuiteName: "test.std.\(UUID().uuidString)",
            appGroupSuiteName: "test.grp.\(UUID().uuidString)"
        )
        let vm = HomeViewModel(service: mock, analytics: spy, settings: settings)
        let context = ModelContext(HistoryContainer.makeInMemory())
        vm.setModelContext(context)

        vm.inputText = "https://x.com?utm_source=a"
        for _ in 0 ..< 200 where spy.events.isEmpty {
            try? await Task.sleep(for: .milliseconds(10))
        }

        vm.copyCleanedURL()
        vm.copyCleanedURL()
        vm.copyCleanedURL()

        // Repeated taps on one cleaned output export once...
        #expect(spy.events.filter { $0 == .homeURLCopied(changed: true) }.count == 1)
        // ...and write exactly one history row, not one per tap.
        let rows = try? context.fetch(FetchDescriptor<HistoryEntry>())
        #expect(rows?.count == 1)
    }

    @Test func copyEmitsAgainAfterTheCleanedResultChanges() async {
        let spy = SpyAnalytics()
        var mock = MockURLCleaningService()
        // Output varies with input length, so the two distinct inputs clean differently.
        mock.cleanHandler = { input in CleanedURL(input: input, output: "https://clean.example/\(input.count)", removedCount: 1) }
        let vm = HomeViewModel(service: mock, analytics: spy)

        vm.inputText = "https://x.com?utm_source=a"
        for _ in 0 ..< 200 where spy.events.isEmpty {
            try? await Task.sleep(for: .milliseconds(10))
        }
        vm.copyCleanedURL()

        let afterFirstCopy = spy.events.count
        vm.inputText = "https://much-longer-host.example.com?utm_source=b"
        for _ in 0 ..< 200 where spy.events.count == afterFirstCopy {
            try? await Task.sleep(for: .milliseconds(10))
        }
        vm.copyCleanedURL()

        // A genuinely different cleaned output (e.g. after a leftover-pill refine)
        // is a new export, not a duplicate tap.
        let copies = spy.events.filter {
            if case .homeURLCopied = $0 { return true }
            return false
        }
        #expect(copies.count == 2)
    }

    // MARK: - Share

    @Test func shareEmitsSignalAndIsDedupedPerResult() async {
        let spy = SpyAnalytics()
        var mock = MockURLCleaningService()
        mock.cleanHandler = { input in CleanedURL(input: input, output: "https://clean.example", removedCount: 1) }
        let settings = SettingsStore(
            standardSuiteName: "test.std.\(UUID().uuidString)",
            appGroupSuiteName: "test.grp.\(UUID().uuidString)"
        )
        let vm = HomeViewModel(service: mock, analytics: spy, settings: settings)
        let context = ModelContext(HistoryContainer.makeInMemory())
        vm.setModelContext(context)

        vm.inputText = "https://x.com?utm_source=a"
        for _ in 0 ..< 200 where spy.events.isEmpty {
            try? await Task.sleep(for: .milliseconds(10))
        }

        vm.recordShare()
        vm.recordShare()

        // Repeated shares of one result export once, and write one history row.
        #expect(spy.events.filter { $0 == .homeURLShared(changed: true) }.count == 1)
        let rows = try? context.fetch(FetchDescriptor<HistoryEntry>())
        #expect(rows?.count == 1)
    }

    @Test func copyThenShareCountsBothButWritesOneHistoryRow() async {
        let spy = SpyAnalytics()
        var mock = MockURLCleaningService()
        mock.cleanHandler = { input in CleanedURL(input: input, output: "https://clean.example", removedCount: 1) }
        let settings = SettingsStore(
            standardSuiteName: "test.std.\(UUID().uuidString)",
            appGroupSuiteName: "test.grp.\(UUID().uuidString)"
        )
        let vm = HomeViewModel(service: mock, analytics: spy, settings: settings)
        let context = ModelContext(HistoryContainer.makeInMemory())
        vm.setModelContext(context)

        vm.inputText = "https://x.com?utm_source=a"
        for _ in 0 ..< 200 where spy.events.isEmpty {
            try? await Task.sleep(for: .milliseconds(10))
        }

        vm.copyCleanedURL()
        vm.recordShare()

        // Copy and share are distinct exports, but the same output is one history row.
        #expect(spy.events.contains(.homeURLCopied(changed: true)))
        #expect(spy.events.contains(.homeURLShared(changed: true)))
        let rows = try? context.fetch(FetchDescriptor<HistoryEntry>())
        #expect(rows?.count == 1)
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

    // MARK: - Leftover trackers (Home cleaning transparency)

    @Test func addLeftoverParameterAddsToStoreAndEmitsSignal() {
        let spy = SpyAnalytics()
        let store = TrackingParameterStore(suiteName: "test.\(UUID().uuidString)")
        let vm = HomeViewModel(service: MockURLCleaningService(), analytics: spy, store: store)

        vm.addLeftoverParameter("yclid")

        #expect(store.customParameters().contains("yclid"))
        #expect(spy.events == [.parametersCustomAdded(totalCount: 1)])
    }

    @Test func addingLeftoverTrackerStripsItOnReclean() async {
        // Real service + a shared store, so adding a custom parameter actually
        // changes what the re-clean removes — the full "still tracking → removed"
        // loop the feature promises.
        let store = TrackingParameterStore(suiteName: "test.\(UUID().uuidString)")
        let vm = HomeViewModel(
            service: DefaultURLCleaningService(store: store),
            analytics: SpyAnalytics(),
            store: store
        )

        vm.inputText = "https://x.com/?yclid=abc&id=1"
        for _ in 0 ..< 200 where vm.leftoverParameters.isEmpty {
            try? await Task.sleep(for: .milliseconds(10))
        }
        // yclid is a known tracker that is not in the defaults → surfaced as leftover.
        #expect(vm.leftoverParameters.contains("yclid"))

        vm.addLeftoverParameter("yclid")
        for _ in 0 ..< 200 where vm.leftoverParameters.contains("yclid") {
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(!vm.leftoverParameters.contains("yclid")) // no longer leftover
        #expect(vm.removedParameters.contains("yclid")) // moved into removed
        #expect(!vm.cleanedText.contains("yclid"))       // and gone from the URL
    }

    @Test func arbitraryLeftoverParameterSurfaces() async {
        // The reference-only gate was lifted: any surviving key — even an
        // arbitrary one that is not a known tracker — is offered as a pill.
        let store = TrackingParameterStore(suiteName: "test.\(UUID().uuidString)")
        let vm = HomeViewModel(
            service: DefaultURLCleaningService(store: store),
            analytics: SpyAnalytics(),
            store: store
        )

        vm.inputText = "https://x.com/?utm_source=a&test=xxx"
        for _ in 0 ..< 200 where vm.leftoverParameters.isEmpty {
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(vm.leftoverParameters.contains("test"))   // arbitrary key surfaces
        #expect(!vm.removedParameters.contains("test"))   // it was not removed
        #expect(vm.removedParameters.contains("utm_source"))
    }
}
