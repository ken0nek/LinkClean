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
            (.homeURLCleaned(source: .typed, changed: true, removedCount: 0), "Home.URL.cleaned"),
            (.homeURLCopied(changed: true), "Home.URL.copied"),
            (.homeClipboardInvalidPasted, "Home.Clipboard.invalidPasted"),
            (.historyScreenShown(entryCount: 0), "History.screen.shown"),
            (.historyEntryActioned(.copy), "History.Entry.actioned"),
            (.historyEntryDeleted, "History.Entry.deleted"),
            (.historyAllCleared, "History.All.cleared"),
            (.historySearchUsed, "History.Search.used"),
            (.settingsAutoPasteToggled(enabled: true), "Settings.AutoPaste.toggled"),
            (.settingsSaveHistoryToggled(enabled: true), "Settings.SaveHistory.toggled"),
            (.parametersDefaultToggled(parameter: "utm_source", enabled: false), "Parameters.Default.toggled"),
            (.parametersCustomAdded(totalCount: 1), "Parameters.Custom.added"),
            (.parametersCustomDeleted(totalCount: 0), "Parameters.Custom.deleted"),
            (.onboardingFlowCompleted, "Onboarding.flow.completed"),
            (.onboardingFlowSkipped, "Onboarding.flow.skipped"),
            (.onboardingExtensionGuideShown(source: .onboarding), "Onboarding.ExtensionGuide.shown"),
            (.actionCleanSucceeded(changed: true, removedCount: 1), "Action.Clean.succeeded"),
            (.actionCleanFailed(reason: .noURL), "Action.Clean.failed"),
            (.actionMarkdownSucceeded(titleSource: .javascript, changed: true), "Action.Markdown.succeeded"),
            (.actionMarkdownFailed(reason: .invalidInput), "Action.Markdown.failed"),
        ]
        for (event, name) in expected {
            #expect(event.signalName == name)
        }
    }

    // MARK: - Parameters

    @Test func cleanedCarriesSourceChangedAndBucketedRemovedCount() {
        let params = AnalyticsEvent.homeURLCleaned(source: .autoPaste, changed: true, removedCount: 3).parameters
        #expect(params == ["source": "autoPaste", "changed": "true", "removedCount": "3"])
    }

    @Test func copiedCarriesOnlyChanged() {
        #expect(AnalyticsEvent.homeURLCopied(changed: false).parameters == ["changed": "false"])
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
        ]
        for event in events {
            #expect(event.parameters.isEmpty)
        }
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

    // MARK: - Bucketing

    @Test func removedCountBuckets() {
        func bucket(_ n: Int) -> String? {
            AnalyticsEvent.actionCleanSucceeded(changed: true, removedCount: n).parameters["removedCount"]
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
