//
//  ActionPipelineTests.swift
//  LinkCleanExtensionUITests
//

// The pipeline + strategies are UIKit-free in spirit but live in the
// UIKit-linking ExtensionUI module, so these run on the simulator (sim lane).
#if canImport(UIKit)
import Testing
import Foundation
@testable import LinkCleanCore
@testable import LinkCleanData
@testable import LinkCleanExtensionUI
import LinkCleanTestSupport

@MainActor
struct ActionPipelineTests {

    // MARK: - CleanLinkStrategy (pure values)

    @Test func cleanStrategyProducesURLPayloadAndSuccessEvents() async {
        let outcome = URLCleaner.outcome(
            for: "https://x.com/?utm_source=a&epik=b&id=1",
            removing: ["utm_source"]
        )
        let result = await CleanLinkStrategy().result(
            for: outcome,
            extracted: ExtractedURL(url: URL(string: outcome.input)!)
        )

        #expect(result.payload == PasteboardPayload(.url(URL(string: outcome.cleaned)!)))
        // Success signal, then one reference-observed per catalog-gap tracker.
        #expect(result.successEvents.first == .actionCleanSucceeded(telemetry: outcome.telemetry))
        #expect(result.successEvents.contains(.parametersReferenceObserved(parameter: "epik")))
    }

    @Test func cleanStrategyFailureReasonReflectsAttachments() {
        #expect(CleanLinkStrategy().failureEvent(hasAttachments: false) == .actionCleanFailed(reason: .noURL))
        #expect(CleanLinkStrategy().failureEvent(hasAttachments: true) == .actionCleanFailed(reason: .invalidInput))
    }

    // MARK: - TemplateOutputStrategy (pure values; stubbed metadata, throwaway suites)

    /// A strategy over a throwaway App Group suite so a test controls the selected
    /// template and the entitlement snapshot in isolation. The injected clock keeps
    /// `{date}`/`{time}` deterministic.
    private func templateStrategy(
        suite: String,
        title: String? = nil,
        date: Date = Date(timeIntervalSince1970: 1_750_000_000)
    ) -> TemplateOutputStrategy {
        TemplateOutputStrategy(
            templates: TemplateStore(suiteName: suite),
            entitlements: EntitlementStore(suiteName: suite),
            metadata: StubLinkMetadataService(title: title),
            now: { date }
        )
    }

    @Test func templateStrategyDefaultsToFreeMarkdownAndPrefersJSTitle() async {
        let suite = "test.\(UUID().uuidString)"
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        let outcome = URLCleaner.outcome(for: "https://x.com/?id=1", removing: [])
        let result = await templateStrategy(suite: suite, title: "Fetched")
            .result(for: outcome, extracted: ExtractedURL(url: URL(string: outcome.input)!, jsTitle: "JS Title"))

        // Nothing selected → the free Markdown preset (behavior-preserving). JS
        // title is preferred over the fetch.
        #expect(result.payload == PasteboardPayload(.string("[JS Title](https://x.com/?id=1)")))
        #expect(result.successEvents == [.actionFormatSucceeded(preset: true, changed: false)])
    }

    @Test func templateStrategyFetchesTitleWhenJSAbsent() async {
        let suite = "test.\(UUID().uuidString)"
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        let outcome = URLCleaner.outcome(for: "https://x.com/?utm_source=a&id=1", removing: ["utm_source"])
        let result = await templateStrategy(suite: suite, title: "Fetched")
            .result(for: outcome, extracted: ExtractedURL(url: URL(string: outcome.input)!))

        #expect(result.payload == PasteboardPayload(.string("[Fetched](https://x.com/?id=1)")))
        // `changed: true` because utm_source was removed.
        #expect(result.successEvents == [.actionFormatSucceeded(preset: true, changed: true)])
    }

    @Test func templateStrategyFallsBackToURLOnlyMarkdownWhenNoTitle() async {
        let suite = "test.\(UUID().uuidString)"
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        let outcome = URLCleaner.outcome(for: "https://x.com/?id=1", removing: [])
        let result = await templateStrategy(suite: suite, title: nil)
            .result(for: outcome, extracted: ExtractedURL(url: URL(string: outcome.input)!))

        // No title resolved → the {markdown} shorthand uses the URL as link text.
        #expect(result.payload == PasteboardPayload(.string("[https://x.com/?id=1](https://x.com/?id=1)")))
        #expect(result.successEvents == [.actionFormatSucceeded(preset: true, changed: false)])
    }

    @Test func templateStrategySkipsTitleFetchForTitleFreeTemplate() async {
        let suite = "test.\(UUID().uuidString)"
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        let store = TemplateStore(suiteName: suite)
        store.setActive(LinkTemplate.cleanPreset.id, true)        // {link}, free, title-free
        store.setActive(LinkTemplate.markdownPreset.id, false)    // only Clean active
        let outcome = URLCleaner.outcome(for: "https://x.com/?id=1", removing: [])
        // A non-nil stub title that must NOT appear: a title-free template never fetches.
        let result = await templateStrategy(suite: suite, title: "SHOULD NOT APPEAR")
            .result(for: outcome, extracted: ExtractedURL(url: URL(string: outcome.input)!))

        #expect(result.payload == PasteboardPayload(.string("https://x.com/?id=1")))
        #expect(result.successEvents == [.actionFormatSucceeded(preset: true, changed: false)])
    }

    @Test func templateStrategyFailsClosedForProActiveOnFreeTier() async {
        let suite = "test.\(UUID().uuidString)"
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        let store = TemplateStore(suiteName: suite)
        store.setActive(LinkTemplate.htmlPreset.id, true)         // Pro preset active
        store.setActive(LinkTemplate.markdownPreset.id, false)
        EntitlementStore(suiteName: suite).save(.free)
        let outcome = URLCleaner.outcome(for: "https://x.com/?id=1", removing: [])
        let result = await templateStrategy(suite: suite, title: "T")
            .result(for: outcome, extracted: ExtractedURL(url: URL(string: outcome.input)!))

        // Free user whose only active format is Pro → floors to free Markdown, not HTML.
        #expect(result.payload == PasteboardPayload(.string("[T](https://x.com/?id=1)")))
        #expect(result.successEvents == [.actionFormatSucceeded(preset: true, changed: false)])
    }

    @Test func templateStrategyRendersProCustomTemplateForProTier() async {
        let suite = "test.\(UUID().uuidString)"
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        let store = TemplateStore(suiteName: suite)
        let mine = LinkTemplate.custom(id: UUID(), name: "Mine", format: "{host}: {removedCount} removed")
        store.upsert(mine)
        store.setActive(mine.id, true)
        store.setActive(LinkTemplate.markdownPreset.id, false)    // only the custom active
        EntitlementStore(suiteName: suite).save(.pro)
        let outcome = URLCleaner.outcome(for: "https://www.youtube.com/watch?v=x&utm_source=a", removing: ["utm_source"])
        let result = await templateStrategy(suite: suite)
            .result(for: outcome, extracted: ExtractedURL(url: URL(string: outcome.input)!))

        // Custom template renders for a Pro user; host is www-stripped; preset:false.
        #expect(result.payload == PasteboardPayload(.string("youtube.com: 1 removed")))
        #expect(result.successEvents == [.actionFormatSucceeded(preset: false, changed: true)])
    }

    // MARK: - In-extension picker (active set → choices)

    @Test func templateStrategyOffersNoPickerForSingleActive() {
        let suite = "test.\(UUID().uuidString)"
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        // Default = Markdown only → one active → no picker.
        #expect(templateStrategy(suite: suite).choices().isEmpty)
    }

    @Test func templateStrategyOffersOrderedLabeledChoicesForMultipleActive() {
        let suite = "test.\(UUID().uuidString)"
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        TemplateStore(suiteName: suite).setActive(LinkTemplate.cleanPreset.id, true) // active: {markdown, clean}
        let choices = templateStrategy(suite: suite).choices()
        // Two active → a picker, in display order (Clean precedes Markdown), each labeled.
        #expect(choices.map(\.id) == [LinkTemplate.cleanPreset.id, LinkTemplate.markdownPreset.id])
        #expect(choices.allSatisfy { !$0.title.isEmpty })
    }

    @Test func templateStrategyRendersTheChosenFormatNotTheDefault() async {
        let suite = "test.\(UUID().uuidString)"
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        TemplateStore(suiteName: suite).setActive(LinkTemplate.cleanPreset.id, true) // active: {markdown, clean}
        let outcome = URLCleaner.outcome(for: "https://x.com/?id=1", removing: [])
        // Choosing Clean renders {link}, not the default Markdown.
        let result = await templateStrategy(suite: suite, title: "T")
            .result(for: outcome, extracted: ExtractedURL(url: URL(string: outcome.input)!),
                    choiceID: LinkTemplate.cleanPreset.id)
        #expect(result.payload == PasteboardPayload(.string("https://x.com/?id=1")))
        #expect(result.successEvents == [.actionFormatSucceeded(preset: true, changed: false)])
    }

    @Test func pipelinePrepareOffersChoicesThenCompleteRecordsChosenFormat() async {
        let suite = "test.\(UUID().uuidString)"
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        TemplateStore(suiteName: suite).setActive(LinkTemplate.cleanPreset.id, true) // {markdown, clean} → picker
        let spy = SpyAnalytics()
        let settings = SettingsStore(appGroupSuiteName: suite)
        let pipeline = ActionPipeline(
            strategy: templateStrategy(suite: suite),
            cleaning: DefaultCleaningService(store: TrackingParameterStore(suiteName: suite)),
            settings: settings,
            analytics: spy,
            stats: StatsStore(suiteName: suite)
        )
        let item = NSExtensionItem()
        item.attachments = [NSItemProvider(object: NSURL(string: "https://x.com/?utm_source=a&id=1")!)]

        // prepare → ready with two choices, and NOTHING recorded (a cancelled picker
        // must leave no trace).
        guard case .ready(let prepared, let choices) = await pipeline.prepare(items: [item], hasAttachments: true) else {
            Issue.record("expected .ready"); return
        }
        #expect(choices.count == 2)
        #expect(spy.events.isEmpty)
        #expect(settings.lastActionExtensionRunAt == nil)

        // complete(Clean) → renders the cleaned URL and records success + stats + run.
        let presentation = await pipeline.complete(prepared, choiceID: LinkTemplate.cleanPreset.id)
        #expect(presentation.toast == .copied)
        if case .string(let text) = presentation.payload?.content {
            #expect(!text.contains("utm_source"))
        } else {
            Issue.record("expected a string payload")
        }
        #expect(spy.signalNames.contains("Action.Format.succeeded"))
        #expect(settings.lastActionExtensionRunAt != nil)
        #expect(StatsStore(suiteName: suite).current().totalCleans == 1)
    }

    @Test func templateStrategyFailureReasonReflectsAttachments() {
        let suite = "test.\(UUID().uuidString)"
        defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
        #expect(templateStrategy(suite: suite).failureEvent(hasAttachments: false) == .actionFormatFailed(reason: .noURL))
        #expect(templateStrategy(suite: suite).failureEvent(hasAttachments: true) == .actionFormatFailed(reason: .invalidInput))
    }

    // MARK: - Pipeline orchestration

    @Test func runCleanSuccessWritesPayloadEventsAndSuccessSignal() async {
        let suiteName = "test.\(UUID().uuidString)"
        let spy = SpyAnalytics()
        let settings = SettingsStore(appGroupSuiteName: suiteName)
        let pipeline = ActionPipeline(
            strategy: CleanLinkStrategy(),
            cleaning: DefaultCleaningService(store: TrackingParameterStore(suiteName: suiteName)),
            settings: settings,
            analytics: spy
        )
        let item = NSExtensionItem()
        item.attachments = [NSItemProvider(object: NSURL(string: "https://x.com/?utm_source=a&id=1")!)]

        let presentation = await pipeline.run(items: [item], hasAttachments: true)

        #expect(presentation.toast == .copied)
        #expect(presentation.haptic == .success)
        if case .url(let url) = presentation.payload?.content {
            #expect(!url.absoluteString.contains("utm_source")) // utm_source is default-on
            #expect(url.absoluteString.contains("id=1"))
        } else {
            Issue.record("expected a URL payload")
        }
        #expect(spy.signalNames.contains("Action.Clean.succeeded"))
        #expect(settings.lastActionExtensionRunAt != nil) // success signal recorded
    }

    @Test func runFailsWhenNoURLPresent() async {
        let spy = SpyAnalytics()
        let pipeline = ActionPipeline(
            strategy: CleanLinkStrategy(),
            settings: SettingsStore(appGroupSuiteName: "test.\(UUID().uuidString)"),
            analytics: spy
        )
        let item = NSExtensionItem()
        item.attachments = [NSItemProvider(object: "just some text, no link" as NSString)]

        let presentation = await pipeline.run(items: [item], hasAttachments: true)

        #expect(presentation.payload == nil)
        #expect(presentation.toast == .noLinkFound)
        #expect(presentation.haptic == .error)
        // Attachments present but unparseable → invalidInput.
        #expect(spy.events == [.actionCleanFailed(reason: .invalidInput)])
    }
}
#endif
