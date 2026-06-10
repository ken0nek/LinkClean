//
//  AnalyticsEventTests.swift
//  LinkCleanKitTests
//

import Testing
@testable import LinkCleanKit

struct AnalyticsEventTests {

    // MARK: - Signal names

    @Test func signalNamesMatchTaxonomy() {
        let expected: [(AnalyticsEvent, String)] = [
            (.homeURLCleaned(source: .typed, changed: true, removedCount: 0, leftoverCount: 0, referenceMatchCount: 0, removedKinds: [], domain: "example.com"), "Home.URL.cleaned"),
            (.homeURLCopied(changed: true), "Home.URL.copied"),
            (.homeURLShared(changed: true), "Home.URL.shared"),
            (.homeClipboardInvalidPasted, "Home.Clipboard.invalidPasted"),
            (.historyScreenShown(entryCount: 0), "History.Screen.shown"),
            (.historyEntryActioned(.copy), "History.Entry.actioned"),
            (.historyEntryDeleted, "History.Entry.deleted"),
            (.historyAllCleared, "History.All.cleared"),
            (.historySearchUsed, "History.Search.used"),
            (.settingsAutoPasteToggled(enabled: true), "Settings.AutoPaste.toggled"),
            (.settingsSaveHistoryToggled(enabled: true), "Settings.SaveHistory.toggled"),
            (.settingsScreenShown, "Settings.Screen.shown"),
            (.parametersDefaultToggled(parameter: "utm_source", enabled: false), "Parameters.Default.toggled"),
            (.parametersCustomAdded(totalCount: 1), "Parameters.Custom.added"),
            (.parametersCustomDeleted(totalCount: 0), "Parameters.Custom.deleted"),
            (.parametersCustomShown, "Parameters.Custom.shown"),
            (.parametersReferenceObserved(parameter: "epik"), "Parameters.Reference.observed"),
            (.parametersLeftoverRemovedOnce, "Parameters.Leftover.removedOnce"),
            (.onboardingFlowCompleted, "Onboarding.Flow.completed"),
            (.onboardingFlowSkipped, "Onboarding.Flow.skipped"),
            (.onboardingExtensionGuideShown(source: .onboarding), "Onboarding.ExtensionGuide.shown"),
            (.actionCleanSucceeded(changed: true, removedCount: 1, leftoverCount: 0, referenceMatchCount: 0, removedKinds: [], domain: "example.com"), "Action.Clean.succeeded"),
            (.actionCleanFailed(reason: .noURL), "Action.Clean.failed"),
            (.actionMarkdownSucceeded(titleSource: .javascript, changed: true), "Action.Markdown.succeeded"),
            (.actionMarkdownFailed(reason: .invalidInput), "Action.Markdown.failed"),
            (.reviewPromptShown, "Review.Prompt.shown"),
            (.reviewStarsSelected(bucket: .high), "Review.Stars.selected"),
            (.reviewSystemPromptRequested, "Review.SystemPrompt.requested"),
            (.reviewPromptDismissed, "Review.Prompt.dismissed"),
            (.paywallShown(trigger: .settingsRow), "Paywall.Screen.shown"),
            (.purchaseStarted, "Pro.Purchase.started"),
            (.purchaseCompleted, "Pro.Purchase.completed"),
            (.purchaseFailed(reason: .cancelled), "Pro.Purchase.failed"),
            (.purchaseRestored(restored: true), "Pro.Purchase.restored"),
        ]
        for (event, name) in expected {
            #expect(event.signalName == name)
        }
    }

    // MARK: - Parameters

    @Test func cleanedCarriesSourceChangedAndBucketedRemovedCount() {
        let params = AnalyticsEvent.homeURLCleaned(
            source: .autoPaste, changed: true, removedCount: 3,
            leftoverCount: 2, referenceMatchCount: 1, removedKinds: ["utm", "ads"],
            domain: "youtube.com"
        ).parameters
        #expect(params == [
            "source": "autoPaste",
            "changed": "true",
            "removedCount": "3",
            "leftoverCount": "2",
            "referenceMatchCount": "1",
            "removedKinds": "ads,utm",
            "domain": "youtube.com",
        ])
    }

    @Test func cleanedCarriesCatalogGapSignals() {
        let params = AnalyticsEvent.actionCleanSucceeded(
            changed: true, removedCount: 1,
            leftoverCount: 6, referenceMatchCount: 0, removedKinds: [],
            domain: "x.com"
        ).parameters
        #expect(params["leftoverCount"] == "5+")
        #expect(params["referenceMatchCount"] == "0")
        #expect(params["removedKinds"] == "none")
        #expect(params["domain"] == "x.com")
    }

    @Test func removedKindsAreSortedAndJoined() {
        let params = AnalyticsEvent.homeURLCleaned(
            source: .typed, changed: true, removedCount: 4,
            leftoverCount: 0, referenceMatchCount: 0, removedKinds: ["social", "ads", "utm"],
            domain: "example.com"
        ).parameters
        #expect(params["removedKinds"] == "ads,social,utm")
    }

    @Test func cleanEventsCarryTheSiteDomainVerbatim() {
        // The disclosed site-popularity signal (analytics.md §3): the host is
        // already normalized by URLCleaner.analyticsDomain, so the event passes it
        // through unchanged on both clean events.
        let home = AnalyticsEvent.homeURLCleaned(
            source: .typed, changed: true, removedCount: 1,
            leftoverCount: 0, referenceMatchCount: 0, removedKinds: [], domain: "youtube.com"
        ).parameters
        let action = AnalyticsEvent.actionCleanSucceeded(
            changed: true, removedCount: 1,
            leftoverCount: 0, referenceMatchCount: 0, removedKinds: [], domain: "youtube.com"
        ).parameters
        #expect(home["domain"] == "youtube.com")
        #expect(action["domain"] == "youtube.com")
    }

    @Test func referenceObservedCarriesTheName() {
        // Tier 1: the name is a public reference-catalog entry, so it is sent.
        #expect(AnalyticsEvent.parametersReferenceObserved(parameter: "gbraid").parameters == ["parameter": "gbraid"])
    }

    @Test func cleanEventParameterSurfaceIsCountsAndEnumsOnly() {
        // Pins the clean event's parameter surface so a future change can't
        // silently add a name-bearing key: catalog-gap data rides as counts only,
        // never as leftover key names. `domain` is the one intentional URL-derived
        // key (the disclosed site-popularity signal, analytics.md §3); this pins
        // that *no other* name-bearing key joins it. (That referenceMatches itself
        // can only ever hold public reference names is guarded at the source in
        // CleanResultTests.novelLeftoverNamesNeverBecomeReferenceMatches.)
        let home = AnalyticsEvent.homeURLCleaned(
            source: .typed, changed: false, removedCount: 0,
            leftoverCount: 3, referenceMatchCount: 2, removedKinds: [],
            domain: "example.com"
        ).parameters
        #expect(Set(home.keys) == ["source", "changed", "removedCount", "leftoverCount", "referenceMatchCount", "removedKinds", "domain"])
    }

    @Test func copiedCarriesOnlyChanged() {
        #expect(AnalyticsEvent.homeURLCopied(changed: false).parameters == ["changed": "false"])
    }

    @Test func sharedCarriesOnlyChanged() {
        #expect(AnalyticsEvent.homeURLShared(changed: true).parameters == ["changed": "true"])
    }

    @Test func markdownSucceededCarriesTitleSourceAndChanged() {
        let params = AnalyticsEvent.actionMarkdownSucceeded(titleSource: .linkPresentation, changed: false).parameters
        #expect(params == ["titleSource": "linkPresentation", "changed": "false"])
    }

    @Test func defaultToggledPassesBuiltInNameThrough() {
        let params = AnalyticsEvent.parametersDefaultToggled(parameter: "fbclid", enabled: false).parameters
        #expect(params == ["parameter": "fbclid", "enabled": "false"])
    }

    @Test func entryActionedCarriesActionRawValue() {
        #expect(AnalyticsEvent.historyEntryActioned(.openInBrowser).parameters == ["action": "openInBrowser"])
    }

    @Test func parameterlessEventsHaveNoParameters() {
        let events: [AnalyticsEvent] = [
            .homeClipboardInvalidPasted, .historyEntryDeleted, .historyAllCleared,
            .historySearchUsed, .onboardingFlowCompleted, .onboardingFlowSkipped,
            .settingsScreenShown, .parametersCustomShown, .parametersLeftoverRemovedOnce,
            .reviewPromptShown, .reviewSystemPromptRequested, .reviewPromptDismissed,
            .purchaseStarted, .purchaseCompleted,
        ]
        for event in events {
            #expect(event.parameters.isEmpty)
        }
    }

    @Test func monetizationEventsCarryFixedEnumsOnly() {
        // Privacy (§9): the paywall trigger is a fixed low-cardinality enum, never
        // a URL or parameter name; purchase events carry no product or price.
        #expect(AnalyticsEvent.paywallShown(trigger: .customParamHome).parameters == ["trigger": "customParamHome"])
        #expect(AnalyticsEvent.paywallShown(trigger: .historyArchive).parameters == ["trigger": "historyArchive"])
        #expect(AnalyticsEvent.purchaseFailed(reason: .pending).parameters == ["reason": "pending"])
        #expect(AnalyticsEvent.purchaseFailed(reason: .storeError).parameters == ["reason": "storeError"])
        #expect(AnalyticsEvent.purchaseRestored(restored: true).parameters == ["restored": "true"])
        #expect(AnalyticsEvent.purchaseRestored(restored: false).parameters == ["restored": "false"])
    }

    // MARK: - Privacy

    @Test func customParameterEventsNeverCarryTheName() {
        // The taxonomy must make it impossible to leak the user-authored name:
        // only a bucketed total is exposed.
        let added = AnalyticsEvent.parametersCustomAdded(totalCount: 4).parameters
        let deleted = AnalyticsEvent.parametersCustomDeleted(totalCount: 2).parameters
        #expect(Array(added.keys) == ["totalCount"])
        #expect(Array(deleted.keys) == ["totalCount"])
    }

    @Test func reviewStarsSelectedCarriesOnlyTheBucket() {
        // Privacy: only the coarse high/low bucket ships, never the exact stars.
        #expect(AnalyticsEvent.reviewStarsSelected(bucket: .high).parameters == ["bucket": "high"])
        #expect(AnalyticsEvent.reviewStarsSelected(bucket: .low).parameters == ["bucket": "low"])
    }

    // MARK: - Bucketing

    @Test func removedCountBuckets() {
        func bucket(_ n: Int) -> String? {
            AnalyticsEvent.actionCleanSucceeded(
                changed: true, removedCount: n,
                leftoverCount: 0, referenceMatchCount: 0, removedKinds: [],
                domain: "example.com"
            ).parameters["removedCount"]
        }
        #expect(bucket(0) == "0")
        #expect(bucket(1) == "1")
        #expect(bucket(4) == "4")
        #expect(bucket(5) == "5+")
        #expect(bucket(42) == "5+")
    }

    @Test func historySizeBuckets() {
        func bucket(_ n: Int) -> String? {
            AnalyticsEvent.historyScreenShown(entryCount: n).parameters["entryCount"]
        }
        #expect(bucket(0) == "0")
        #expect(bucket(1) == "1-9")
        #expect(bucket(9) == "1-9")
        #expect(bucket(10) == "10-49")
        #expect(bucket(49) == "10-49")
        #expect(bucket(50) == "50+")
        #expect(bucket(9999) == "50+")
    }

    @Test func customCountBuckets() {
        func bucket(_ n: Int) -> String? {
            AnalyticsEvent.parametersCustomAdded(totalCount: n).parameters["totalCount"]
        }
        #expect(bucket(0) == "0")
        #expect(bucket(1) == "1")
        #expect(bucket(2) == "2")
        #expect(bucket(3) == "3-4")
        #expect(bucket(4) == "3-4")
        #expect(bucket(5) == "5-9")
        #expect(bucket(9) == "5-9")
        #expect(bucket(10) == "10+")
    }
}
