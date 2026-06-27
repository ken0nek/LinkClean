//
//  AnalyticsEventTests.swift
//  LinkCleanCoreTests
//

import Testing
@testable import LinkCleanCore

struct AnalyticsEventTests {

    /// Builds a ``CleanOutcome/Telemetry`` for the clean events, defaulting the
    /// fields a given test doesn't care about. `referenceMatchCount` is expressed
    /// as the `referenceMatches` array length, since the event buckets its count.
    private func telemetry(
        changed: Bool = true,
        removedCount: Int = 0,
        leftoverCount: Int = 0,
        referenceMatches: [String] = [],
        removedKindIDs: Set<String> = [],
        domain: String = "example.com",
        wrappers: [String] = [],
        expanded: Bool = false
    ) -> CleanOutcome.Telemetry {
        .init(
            changed: changed,
            removedCount: removedCount,
            leftoverCount: leftoverCount,
            removedKindIDs: removedKindIDs,
            referenceMatches: referenceMatches,
            domain: domain,
            wrappers: wrappers,
            expanded: expanded
        )
    }

    // MARK: - Signal names

    @Test func signalNamesMatchTaxonomy() {
        let expected: [(AnalyticsEvent, String)] = [
            (.homeURLCleaned(source: .typed, telemetry: telemetry()), "Home.URL.cleaned"),
            (.homeURLCopied(changed: true), "Home.URL.copied"),
            (.homeURLShared(changed: true), "Home.URL.shared"),
            (.homeClipboardInvalidPasted, "Home.Clipboard.invalidPasted"),
            (.historyScreenShown(entryCount: 0), "History.Screen.shown"),
            (.historyEntryActioned(.copy), "History.Entry.actioned"),
            (.historyEntryDeleted, "History.Entry.deleted"),
            (.historyAllCleared, "History.All.cleared"),
            (.historySearchUsed, "History.Search.used"),
            (.statsScreenShown(hasData: true), "Stats.Screen.shown"),
            (.statsCardShared(entryPoint: .toolbar), "Stats.Card.shared"),
            (.settingsAutoPasteToggled(enabled: true), "Settings.AutoPaste.toggled"),
            (.settingsSaveHistoryToggled(enabled: true), "Settings.SaveHistory.toggled"),
            (.settingsTextFragmentsToggled(enabled: true), "Settings.TextFragments.toggled"),
            (.settingsQRButtonToggled(enabled: true), "Settings.QRButton.toggled"),
            (.settingsExpandShortLinksToggled(enabled: true), "Settings.ExpandShortLinks.toggled"),
            (.settingsScreenShown, "Settings.Screen.shown"),
            (.parametersDefaultToggled(parameter: "utm_source", enabled: false), "Parameters.Default.toggled"),
            (.parametersCustomAdded(totalCount: 1), "Parameters.Custom.added"),
            (.parametersCustomDeleted(totalCount: 0), "Parameters.Custom.deleted"),
            (.parametersCustomShown, "Parameters.Custom.shown"),
            (.parametersReferenceObserved(parameter: "epik"), "Parameters.Reference.observed"),
            (.parametersLeftoverRemovedOnce, "Parameters.Leftover.removedOnce"),
            (.parametersAdvisorSuggested(tier: .reference), "Parameters.Advisor.suggested"),
            (.parametersAdvisorAccepted(tier: .heuristic), "Parameters.Advisor.accepted"),
            (.parametersAdvisorDismissed(tier: .model), "Parameters.Advisor.dismissed"),
            (.onboardingFlowCompleted, "Onboarding.Flow.completed"),
            (.onboardingFlowSkipped, "Onboarding.Flow.skipped"),
            (.onboardingExtensionGuideShown(source: .onboarding), "Onboarding.ExtensionGuide.shown"),
            (.actionCleanSucceeded(telemetry: telemetry(removedCount: 1)), "Action.Clean.succeeded"),
            (.actionCleanFailed(reason: .noURL), "Action.Clean.failed"),
            (.actionFormatSucceeded(preset: true, changed: true), "Action.Format.succeeded"),
            (.actionFormatFailed(reason: .invalidInput), "Action.Format.failed"),
            (.intentCleanSucceeded(surface: .clipboard, telemetry: telemetry(removedCount: 1)), "Intent.Clean.succeeded"),
            (.intentCleanFailed(surface: .clipboard, reason: .noURL), "Intent.Clean.failed"),
            (.qrScanSucceeded(telemetry: telemetry(removedCount: 1)), "QR.Scan.succeeded"),
            (.qrScanFailed(reason: .noLink), "QR.Scan.failed"),
            (.qrCodeGenerated(changed: true), "QR.Code.generated"),
            (.qrResultActioned(.copy), "QR.Result.actioned"),
            (.reviewPromptShown, "Review.Prompt.shown"),
            (.reviewStarsSelected(bucket: .high), "Review.Stars.selected"),
            (.reviewSystemPromptRequested, "Review.SystemPrompt.requested"),
            (.reviewPromptDismissed, "Review.Prompt.dismissed"),
            (.paywallShown(trigger: .settingsRow), "Paywall.Screen.shown"),
            (.purchaseStarted(trigger: .settingsRow), "Pro.Purchase.started"),
            (.purchaseCompleted(trigger: .settingsRow), "Pro.Purchase.completed"),
            (.purchaseFailed(reason: .cancelled, trigger: .settingsRow), "Pro.Purchase.failed"),
            (.purchaseRestored(restored: true), "Pro.Purchase.restored"),
        ]
        for (event, name) in expected {
            #expect(event.signalName == name)
        }
    }

    // MARK: - Parameters

    @Test func cleanedCarriesSourceChangedAndBucketedRemovedCount() {
        let params = AnalyticsEvent.homeURLCleaned(
            source: .autoPaste,
            telemetry: telemetry(
                changed: true, removedCount: 3, leftoverCount: 2,
                referenceMatches: ["epik"], removedKindIDs: ["utm", "ads"], domain: "youtube.com"
            )
        ).parameters
        #expect(params == [
            "source": "autoPaste",
            "changed": "true",
            "removedCount": "3",
            "leftoverCount": "2",
            "referenceMatchCount": "1",
            "removedKinds": "ads,utm",
            "domain": "youtube.com",
            "unwrapped": "false",
            "expanded": "false",
        ])
    }

    @Test func cleanedCarriesCatalogGapSignals() {
        let params = AnalyticsEvent.actionCleanSucceeded(
            telemetry: telemetry(changed: true, removedCount: 1, leftoverCount: 6, domain: "x.com")
        ).parameters
        #expect(params["leftoverCount"] == "5+")
        #expect(params["referenceMatchCount"] == "0")
        #expect(params["removedKinds"] == "none")
        #expect(params["domain"] == "x.com")
    }

    @Test func removedKindsAreSortedAndJoined() {
        let params = AnalyticsEvent.homeURLCleaned(
            source: .typed,
            telemetry: telemetry(removedCount: 4, removedKindIDs: ["social", "ads", "utm"])
        ).parameters
        #expect(params["removedKinds"] == "ads,social,utm")
    }

    @Test func cleanEventsCarryTheSiteDomainVerbatim() {
        // The disclosed site-popularity signal (analytics.md §3): the host is
        // already normalized by URLCleaner.analyticsDomain, so the event passes it
        // through unchanged on both clean events.
        let home = AnalyticsEvent.homeURLCleaned(
            source: .typed, telemetry: telemetry(removedCount: 1, domain: "youtube.com")
        ).parameters
        let action = AnalyticsEvent.actionCleanSucceeded(
            telemetry: telemetry(removedCount: 1, domain: "youtube.com")
        ).parameters
        #expect(home["domain"] == "youtube.com")
        #expect(action["domain"] == "youtube.com")
    }

    @Test func cleanEventsReportWhetherARedirectWasUnwrapped() {
        // Decision: how often do users paste redirect-wrapper links → whether to
        // expand the wrapper catalog. A bool only; the wrapper host is public but
        // deliberately not sent (no sharp decision rides on the distribution).
        let unwrapped = AnalyticsEvent.homeURLCleaned(
            source: .typed, telemetry: telemetry(removedCount: 1, wrappers: ["google.com"])
        ).parameters
        let direct = AnalyticsEvent.actionCleanSucceeded(
            telemetry: telemetry(removedCount: 1)
        ).parameters
        #expect(unwrapped["unwrapped"] == "true")
        #expect(direct["unwrapped"] == "false")
    }

    @Test func cleanEventsReportWhetherAShortLinkWasExpanded() {
        // Decision: E4 is the app's only network egress — does it earn its keep?
        // `expanded` is how we tell an expanded-then-cleaned short link apart from a
        // direct paste (after expansion `domain` is the destination, not the
        // shortener). A bool, never the resolved URL (§3). Fires on every clean
        // surface that wires a resolver — Home and the action extensions.
        let expanded = AnalyticsEvent.homeURLCleaned(
            source: .autoPaste, telemetry: telemetry(removedCount: 2, domain: "youtube.com", expanded: true)
        ).parameters
        let offline = AnalyticsEvent.actionCleanSucceeded(
            telemetry: telemetry(removedCount: 1)
        ).parameters
        #expect(expanded["expanded"] == "true")
        #expect(offline["expanded"] == "false")
        // Independent of `unwrapped` (E1 offline): an expanded short link that is
        // not itself a redirect wrapper reports expansion without unwrapping.
        #expect(expanded["unwrapped"] == "false")
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
        // CleanOutcomeTests.novelLeftoverNamesNeverBecomeReferenceMatches.)
        let home = AnalyticsEvent.homeURLCleaned(
            source: .typed,
            telemetry: telemetry(changed: false, leftoverCount: 3, referenceMatches: ["epik", "yclid"])
        ).parameters
        #expect(Set(home.keys) == ["source", "changed", "removedCount", "leftoverCount", "referenceMatchCount", "removedKinds", "domain", "unwrapped", "expanded"])
    }

    @Test func intentCleanCarriesSurfaceAndCleanTelemetry() {
        // Surface-mix slice (kpis §6) alongside the same analytics-safe telemetry
        // the other clean events carry.
        let shortcut = AnalyticsEvent.intentCleanSucceeded(
            surface: .shortcut,
            telemetry: telemetry(changed: true, removedCount: 2, domain: "youtube.com", wrappers: ["google.com"])
        ).parameters
        #expect(shortcut == [
            "intentSurface": "shortcut",
            "changed": "true",
            "removedCount": "2",
            "leftoverCount": "0",
            "referenceMatchCount": "0",
            "removedKinds": "none",
            "domain": "youtube.com",
            "unwrapped": "true",
            "expanded": "false",
        ])
        // The control and widget both run the clipboard intent → report `clipboard`.
        #expect(AnalyticsEvent.intentCleanSucceeded(
            surface: .clipboard, telemetry: telemetry(removedCount: 1)
        ).parameters["intentSurface"] == "clipboard")
    }

    @Test func intentCleanParameterSurfaceIsCountsAndEnumsOnly() {
        // Same privacy pin as the other clean events: surface + counts + the one
        // disclosed domain, never a leftover key name.
        let params = AnalyticsEvent.intentCleanSucceeded(
            surface: .clipboard,
            telemetry: telemetry(changed: false, leftoverCount: 3, referenceMatches: ["epik", "yclid"])
        ).parameters
        #expect(Set(params.keys) == ["intentSurface", "changed", "removedCount", "leftoverCount", "referenceMatchCount", "removedKinds", "domain", "unwrapped", "expanded"])
    }

    @Test func intentCleanFailedCarriesSurfaceAndReason() {
        // The failure half of the surface-mix read — a control / widget tap that found
        // nothing to clean. Surface + reason, both finite enums, never clipboard text.
        #expect(AnalyticsEvent.intentCleanFailed(surface: .clipboard, reason: .noURL).parameters
            == ["intentSurface": "clipboard", "reason": "noURL"])
        #expect(AnalyticsEvent.intentCleanFailed(surface: .shortcut, reason: .invalidInput).parameters
            == ["intentSurface": "shortcut", "reason": "invalidInput"])
    }

    @Test func qrScanCarriesCleanTelemetry() {
        // The QR surface's clean rides the same analytics-safe telemetry as the
        // other clean surfaces — counts + the one disclosed domain, no key names.
        let params = AnalyticsEvent.qrScanSucceeded(
            telemetry: telemetry(changed: true, removedCount: 2, domain: "youtube.com", wrappers: ["google.com"])
        ).parameters
        #expect(params == [
            "changed": "true",
            "removedCount": "2",
            "leftoverCount": "0",
            "referenceMatchCount": "0",
            "removedKinds": "none",
            "domain": "youtube.com",
            "unwrapped": "true",
            "expanded": "false",
        ])
    }

    @Test func qrScanParameterSurfaceIsCountsAndEnumsOnly() {
        // Same privacy pin as the other clean events: counts + the one disclosed
        // domain, never the decoded payload or a leftover key name.
        let params = AnalyticsEvent.qrScanSucceeded(
            telemetry: telemetry(changed: false, leftoverCount: 3, referenceMatches: ["epik", "yclid"])
        ).parameters
        #expect(Set(params.keys) == ["changed", "removedCount", "leftoverCount", "referenceMatchCount", "removedKinds", "domain", "unwrapped", "expanded"])
    }

    @Test func qrScanFailedAndGeneratedCarryFixedFields() {
        #expect(AnalyticsEvent.qrScanFailed(reason: .noLink).parameters == ["reason": "noLink"])
        #expect(AnalyticsEvent.qrScanFailed(reason: .unreadable).parameters == ["reason": "unreadable"])
        #expect(AnalyticsEvent.qrCodeGenerated(changed: true).parameters == ["changed": "true"])
        #expect(AnalyticsEvent.qrCodeGenerated(changed: false).parameters == ["changed": "false"])
    }

    @Test func qrResultActionCarriesTheActionPath() {
        // The QR result sheet's export leg (Copy / Share / Open), under the same
        // `action` key as `historyEntryActioned` — a fixed enum, never a URL.
        #expect(AnalyticsEvent.qrResultActioned(.copy).parameters == ["action": "copy"])
        #expect(AnalyticsEvent.qrResultActioned(.share).parameters == ["action": "share"])
        #expect(AnalyticsEvent.qrResultActioned(.open).parameters == ["action": "open"])
    }

    @Test func historyEntryBeforeAfterCarriesTheActionPath() {
        // Inspecting the before→after detail rides the same `History.Entry.actioned`
        // signal as the exports, distinguished by the `action` value.
        #expect(AnalyticsEvent.historyEntryActioned(.viewedBeforeAfter).parameters == ["action": "viewedBeforeAfter"])
    }

    @Test func referenceObservedEventsFanOutOnePerMatch() {
        // The shared catalog-gap fan-out: one `parametersReferenceObserved` per
        // match, in order, and nothing when there are no matches.
        let events = telemetry(referenceMatches: ["epik", "li_fat_id"]).referenceObservedEvents
        #expect(events == [
            .parametersReferenceObserved(parameter: "epik"),
            .parametersReferenceObserved(parameter: "li_fat_id"),
        ])
        #expect(telemetry(referenceMatches: []).referenceObservedEvents.isEmpty)
    }

    @Test func copiedCarriesOnlyChanged() {
        #expect(AnalyticsEvent.homeURLCopied(changed: false).parameters == ["changed": "false"])
    }

    @Test func sharedCarriesOnlyChanged() {
        #expect(AnalyticsEvent.homeURLShared(changed: true).parameters == ["changed": "true"])
    }

    @Test func statsScreenShownCarriesHasData() {
        #expect(AnalyticsEvent.statsScreenShown(hasData: true).parameters == ["hasData": "true"])
        #expect(AnalyticsEvent.statsScreenShown(hasData: false).parameters == ["hasData": "false"])
    }

    @Test func statsCardSharedCarriesEntryPoint() {
        // `entryPoint`, never `surface` (that key is the process-level default).
        #expect(AnalyticsEvent.statsCardShared(entryPoint: .toolbar).parameters == ["entryPoint": "toolbar"])
        #expect(AnalyticsEvent.statsCardShared(entryPoint: .cta).parameters == ["entryPoint": "cta"])
    }

    @Test func formatSucceededCarriesPresetAndChanged() {
        let preset = AnalyticsEvent.actionFormatSucceeded(preset: true, changed: false).parameters
        #expect(preset == ["preset": "true", "changed": "false"])
        let custom = AnalyticsEvent.actionFormatSucceeded(preset: false, changed: true).parameters
        #expect(custom == ["preset": "false", "changed": "true"])
    }

    @Test func defaultToggledPassesBuiltInNameThrough() {
        let params = AnalyticsEvent.parametersDefaultToggled(parameter: "fbclid", enabled: false).parameters
        #expect(params == ["parameter": "fbclid", "enabled": "false"])
    }

    @Test func expandShortLinksToggledCarriesEnabledFlag() {
        #expect(AnalyticsEvent.settingsExpandShortLinksToggled(enabled: true).parameters == ["enabled": "true"])
        #expect(AnalyticsEvent.settingsExpandShortLinksToggled(enabled: false).parameters == ["enabled": "false"])
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
        ]
        for event in events {
            #expect(event.parameters.isEmpty)
        }
    }

    @Test func monetizationEventsCarryFixedEnumsOnly() {
        // Privacy (§9): the paywall trigger is a fixed low-cardinality enum, never
        // a URL or parameter name; purchase events carry no product or price — only
        // the gate that raised the paywall, under the same `trigger` key as
        // `paywallShown`, so paywall→purchase conversion is sliceable per gate.
        #expect(AnalyticsEvent.paywallShown(trigger: .customParamHome).parameters == ["trigger": "customParamHome"])
        #expect(AnalyticsEvent.paywallShown(trigger: .historyArchive).parameters == ["trigger": "historyArchive"])
        #expect(AnalyticsEvent.purchaseStarted(trigger: .formatPicker).parameters == ["trigger": "formatPicker"])
        #expect(AnalyticsEvent.purchaseCompleted(trigger: .historyArchive).parameters == ["trigger": "historyArchive"])
        #expect(AnalyticsEvent.purchaseFailed(reason: .pending, trigger: .formatPicker).parameters == ["reason": "pending", "trigger": "formatPicker"])
        #expect(AnalyticsEvent.purchaseFailed(reason: .storeError, trigger: .settingsRow).parameters == ["reason": "storeError", "trigger": "settingsRow"])
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

    @Test func advisorEventsCarryOnlyTheTier() {
        // Privacy (§3): the advisor runs on raw leftover names on-device, but its
        // events expose only the finite reference/heuristic/model tier — never the
        // parameter name.
        #expect(AnalyticsEvent.parametersAdvisorSuggested(tier: .reference).parameters == ["tier": "reference"])
        #expect(AnalyticsEvent.parametersAdvisorAccepted(tier: .heuristic).parameters == ["tier": "heuristic"])
        #expect(AnalyticsEvent.parametersAdvisorDismissed(tier: .model).parameters == ["tier": "model"])
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
                telemetry: telemetry(removedCount: n)
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
