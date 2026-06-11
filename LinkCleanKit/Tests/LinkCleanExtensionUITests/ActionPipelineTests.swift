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

    // MARK: - MarkdownLinkStrategy (pure values, stubbed metadata)

    @Test func markdownStrategyPrefersJSTitle() async {
        let outcome = URLCleaner.outcome(for: "https://x.com/?id=1", removing: [])
        let result = await MarkdownLinkStrategy(metadata: StubLinkMetadataService(title: "Fetched"))
            .result(for: outcome, extracted: ExtractedURL(url: URL(string: outcome.input)!, jsTitle: "JS Title"))

        #expect(result.payload == PasteboardPayload(.string("[JS Title](https://x.com/?id=1)")))
        #expect(result.successEvents == [.actionMarkdownSucceeded(titleSource: .javascript, changed: false)])
    }

    @Test func markdownStrategyFallsBackToLinkPresentation() async {
        let outcome = URLCleaner.outcome(for: "https://x.com/?utm_source=a&id=1", removing: ["utm_source"])
        let result = await MarkdownLinkStrategy(metadata: StubLinkMetadataService(title: "Fetched"))
            .result(for: outcome, extracted: ExtractedURL(url: URL(string: outcome.input)!))

        #expect(result.payload == PasteboardPayload(.string("[Fetched](https://x.com/?id=1)")))
        // `changed: true` because utm_source was removed.
        #expect(result.successEvents == [.actionMarkdownSucceeded(titleSource: .linkPresentation, changed: true)])
    }

    @Test func markdownStrategyFallsBackToURLOnly() async {
        let outcome = URLCleaner.outcome(for: "https://x.com/?id=1", removing: [])
        let result = await MarkdownLinkStrategy(metadata: StubLinkMetadataService(title: nil))
            .result(for: outcome, extracted: ExtractedURL(url: URL(string: outcome.input)!))

        // No title resolved → the URL is its own link text ([url](url)).
        #expect(result.payload == PasteboardPayload(.string("[https://x.com/?id=1](https://x.com/?id=1)")))
        #expect(result.successEvents == [.actionMarkdownSucceeded(titleSource: .urlOnly, changed: false)])
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
