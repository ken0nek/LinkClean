//
//  HomeViewModelAdvisorTests.swift
//  LinkCleanTests
//

import Testing
import Foundation
@testable import LinkClean
import LinkCleanCore
import LinkCleanData

/// Polls until `condition` holds (10 ms × 200, ≈2 s cap) so the view model's
/// async clean → debounced-advisor pipeline can settle without fixed sleeps.
@MainActor
private func waitUntil(_ condition: () -> Bool) async {
    for _ in 0 ..< 200 where !condition() {
        try? await Task.sleep(for: .milliseconds(10))
    }
}

@MainActor
struct HomeViewModelAdvisorTests {

    private func suggestion(_ name: String, tier: AnalyticsEvent.AdvisorTier = .reference) -> ParameterSuggestion {
        ParameterSuggestion(name: name, reason: "Looks like a tracking parameter.", tier: tier)
    }

    /// A view model whose clean always leaves `leftoverNames` behind, wired to a
    /// stub advisor with a zero debounce so the suggestion resolves immediately.
    private func makeViewModel(
        leftoverNames: [String],
        advisor: StubParameterAdvisor,
        analytics: SpyAnalytics = SpyAnalytics(),
        store: TrackingParameterStore
    ) -> HomeViewModel {
        var mock = MockCleaningService()
        mock.cleanHandler = { input in
            .stub(input: input, cleaned: "https://clean.example", removedCount: 1, leftoverNames: leftoverNames)
        }
        return HomeViewModel(
            service: mock,
            analytics: analytics,
            store: store,
            advisor: advisor,
            advisorDebounce: .zero
        )
    }

    @Test func surfacesSuggestionAndSignalsAfterClean() async {
        let suiteName = "test.\(UUID().uuidString)"
        let store = TrackingParameterStore(suiteName: suiteName)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        let spy = SpyAnalytics()
        var advisor = StubParameterAdvisor()
        advisor.result = suggestion("cmpid", tier: .reference)
        let vm = makeViewModel(leftoverNames: ["cmpid", "foo"], advisor: advisor, analytics: spy, store: store)

        vm.inputText = "https://x.com/?cmpid=1&foo=2"
        await waitUntil { vm.suggestion != nil }

        #expect(vm.suggestion?.name == "cmpid")
        #expect(vm.suggestion?.tier == .reference)
        #expect(spy.events.contains(.parametersAdvisorSuggested(tier: .reference)))
    }

    @Test func excludesSuggestedNameFromLeftoverPills() async {
        let suiteName = "test.\(UUID().uuidString)"
        let store = TrackingParameterStore(suiteName: suiteName)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        var advisor = StubParameterAdvisor()
        advisor.result = suggestion("cmpid")
        let vm = makeViewModel(leftoverNames: ["cmpid", "foo"], advisor: advisor, store: store)

        vm.inputText = "https://x.com/?cmpid=1&foo=2"
        await waitUntil { vm.suggestion != nil }

        // The suggested name shows once, in the card — not also as a pill.
        #expect(!vm.leftoverParameters.contains("cmpid"))
        #expect(vm.leftoverParameters.contains("foo"))
    }

    @Test func acceptUnderAllowanceAddsRuleAndClears() async {
        let suiteName = "test.\(UUID().uuidString)"
        let store = TrackingParameterStore(suiteName: suiteName)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        let spy = SpyAnalytics()
        var advisor = StubParameterAdvisor()
        advisor.result = suggestion("cmpid", tier: .reference)
        let vm = makeViewModel(leftoverNames: ["cmpid", "foo"], advisor: advisor, analytics: spy, store: store)

        vm.inputText = "https://x.com/?cmpid=1&foo=2"
        await waitUntil { vm.suggestion != nil }

        let result = vm.acceptSuggestion(entitlement: .free)

        #expect(result == .allowed)
        #expect(store.customParameters().contains("cmpid"))
        #expect(vm.suggestion == nil)
        #expect(spy.events.contains(.parametersAdvisorAccepted(tier: .reference)))
        #expect(spy.events.contains(.parametersCustomAdded(totalCount: 1)))
    }

    @Test func acceptAtAllowanceGatesToAdvisorPaywall() async {
        let suiteName = "test.\(UUID().uuidString)"
        let store = TrackingParameterStore(suiteName: suiteName)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        store.addCustomParameter("existing") // consumes the one free rule
        let spy = SpyAnalytics()
        var advisor = StubParameterAdvisor()
        advisor.result = suggestion("cmpid", tier: .model)
        let vm = makeViewModel(leftoverNames: ["cmpid", "foo"], advisor: advisor, analytics: spy, store: store)

        vm.inputText = "https://x.com/?cmpid=1&foo=2"
        await waitUntil { vm.suggestion != nil }

        let result = vm.acceptSuggestion(entitlement: .free)

        // Gated to the advisor-tagged trigger; nothing added, suggestion kept for a retry.
        #expect(result == .gated(.advisorAccept))
        #expect(!store.customParameters().contains("cmpid"))
        #expect(vm.suggestion != nil)
        #expect(spy.events.contains(.parametersAdvisorAccepted(tier: .model)))
        #expect(!spy.events.contains { if case .parametersCustomAdded = $0 { return true }; return false })
    }

    @Test func gatedRetapsRecordAcceptIntentOnlyOnce() async {
        let suiteName = "test.\(UUID().uuidString)"
        let store = TrackingParameterStore(suiteName: suiteName)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        store.addCustomParameter("existing") // at the free allowance
        let spy = SpyAnalytics()
        var advisor = StubParameterAdvisor()
        advisor.result = suggestion("cmpid", tier: .heuristic)
        let vm = makeViewModel(leftoverNames: ["cmpid", "foo"], advisor: advisor, analytics: spy, store: store)

        vm.inputText = "https://x.com/?cmpid=1&foo=2"
        await waitUntil { vm.suggestion != nil }

        // A free user past their allowance taps Always Remove repeatedly; each tap
        // is gated and leaves the card up, but the accept intent must count once so
        // the accept-vs-dismiss read isn't inflated.
        _ = vm.acceptSuggestion(entitlement: .free)
        _ = vm.acceptSuggestion(entitlement: .free)
        _ = vm.acceptSuggestion(entitlement: .free)

        #expect(spy.events.filter { $0 == .parametersAdvisorAccepted(tier: .heuristic) }.count == 1)
        #expect(vm.suggestion != nil) // still gated, card retained for retry
    }

    @Test func gatedAcceptThenDismissCountsAsAcceptNotDismiss() async {
        // End-to-end of the audit fix: a free user past allowance taps Always
        // Remove (gated → accepted fires, card stays), then taps "Not now". That
        // is one accept, not accept + dismiss — dismissed must not fire.
        let suiteName = "test.\(UUID().uuidString)"
        let store = TrackingParameterStore(suiteName: suiteName)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        store.addCustomParameter("existing") // at the free allowance
        let spy = SpyAnalytics()
        var advisor = StubParameterAdvisor()
        advisor.result = suggestion("cmpid", tier: .model)
        let vm = makeViewModel(leftoverNames: ["cmpid", "foo"], advisor: advisor, analytics: spy, store: store)

        vm.inputText = "https://x.com/?cmpid=1&foo=2"
        await waitUntil { vm.suggestion != nil }

        _ = vm.acceptSuggestion(entitlement: .free) // gated → accepted fires, card kept
        vm.dismissSuggestion()                       // must NOT fire dismissed

        #expect(spy.events.filter { $0 == .parametersAdvisorAccepted(tier: .model) }.count == 1)
        #expect(!spy.events.contains(.parametersAdvisorDismissed(tier: .model)))
    }

    @Test func dismissRecordsAndReturnsNameToPills() async {
        let suiteName = "test.\(UUID().uuidString)"
        let store = TrackingParameterStore(suiteName: suiteName)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        let spy = SpyAnalytics()
        var advisor = StubParameterAdvisor()
        advisor.result = suggestion("cmpid", tier: .heuristic)
        let vm = makeViewModel(leftoverNames: ["cmpid", "foo"], advisor: advisor, analytics: spy, store: store)

        vm.inputText = "https://x.com/?cmpid=1&foo=2"
        await waitUntil { vm.suggestion != nil }
        #expect(!vm.leftoverParameters.contains("cmpid"))

        vm.dismissSuggestion()

        #expect(vm.suggestion == nil)
        #expect(vm.leftoverParameters.contains("cmpid")) // returns as a manual pill
        #expect(spy.events.contains(.parametersAdvisorDismissed(tier: .heuristic)))
    }

    @Test func noSuggestionWhenAdvisorDeclines() async {
        let suiteName = "test.\(UUID().uuidString)"
        let store = TrackingParameterStore(suiteName: suiteName)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        var advisor = StubParameterAdvisor()
        advisor.result = nil
        let vm = makeViewModel(leftoverNames: ["foo"], advisor: advisor, store: store)

        vm.inputText = "https://x.com/?foo=2"
        await waitUntil { !vm.cleanedText.isEmpty }
        await vm.waitForAdvisor()

        #expect(vm.suggestion == nil)
        #expect(advisor.recorder.callCount >= 1) // it was consulted, and declined
    }

    @Test func filtersManagedCatalogDefaultsFromCandidates() async {
        // A default-catalog tracker is owned by the Settings toggle, not the
        // advisor; only the novel leftover should reach the classifier.
        let suiteName = "test.\(UUID().uuidString)"
        let store = TrackingParameterStore(suiteName: suiteName)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
        var advisor = StubParameterAdvisor()
        advisor.result = nil
        let vm = makeViewModel(leftoverNames: ["utm_source", "novelparam"], advisor: advisor, store: store)

        vm.inputText = "https://x.com/?utm_source=a&novelparam=b"
        await waitUntil { !vm.cleanedText.isEmpty }
        await vm.waitForAdvisor()

        #expect(advisor.recorder.candidates.last == ["novelparam"])
    }
}
