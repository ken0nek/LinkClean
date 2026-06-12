//
//  MarkdownLinkStrategy.swift
//  LinkCleanExtensionUI
//
//  Created by Ken Tominaga on 6/11/26.
//

import Foundation
import UniformTypeIdentifiers
import OSLog
import LinkCleanCore
import LinkCleanData

/// "Copy as Markdown": resolve a title (Safari's JS preprocessing first, then a
/// `LinkMetadataService` fetch of the *cleaned* URL, else URL-only) and copy a
/// Markdown link. Shares the one ``LinkMetadataService`` with History enrichment
/// instead of wrapping `LPMetadataProvider` a second time.
public struct MarkdownLinkStrategy: ActionOutputStrategy {
    private let metadata: LinkMetadataService

    /// `timeout: 5` caps the LPMetadata title fetch: the action extension is a
    /// short-lived, memory-limited process, so a slow host must not stall it
    /// before the toast (restores the cap the standalone Markdown extension used
    /// before consolidating onto the shared fetcher).
    public init(metadata: LinkMetadataService = DefaultLinkMetadataService(timeout: 5)) {
        self.metadata = metadata
    }

    public var surface: String { "markdownAction" }

    public func extract(from items: [NSExtensionItem]) async -> ExtractedURL? {
        // Safari only provides the page URL via JS preprocessing; try it first.
        if let js = await extractFromJavaScript(items) {
            return ExtractedURL(url: js.url, jsTitle: js.title)
        }
        guard let url = await URLExtraction.firstWebURL(from: items) else { return nil }
        return ExtractedURL(url: url)
    }

    public func failureEvent(hasAttachments: Bool) -> AnalyticsEvent {
        .actionMarkdownFailed(reason: hasAttachments ? .invalidInput : .noURL)
    }

    public func result(for outcome: CleanOutcome, extracted: ExtractedURL) async -> StrategyResult {
        let cleaned = URL(string: outcome.cleaned) ?? extracted.url

        // Prefer the JS title; fall back to LPMetadata fetched against the
        // *cleaned* URL so tracking parameters never go over the wire.
        let title: String?
        let titleSource: AnalyticsEvent.TitleSource
        if let jsTitle = extracted.jsTitle {
            title = jsTitle
            titleSource = .javascript
        } else if let fetched = await metadata.fetchMetadata(for: cleaned).title {
            title = fetched
            titleSource = .linkPresentation
        } else {
            title = nil
            titleSource = .urlOnly
        }

        let markdown = MarkdownFormatter.markdownLink(title: title, url: cleaned.absoluteString)
        let event = AnalyticsEvent.actionMarkdownSucceeded(
            titleSource: titleSource,
            changed: outcome.telemetry.changed
        )
        return StrategyResult(payload: PasteboardPayload(.string(markdown)), successEvents: [event])
    }

    // MARK: - JavaScript preprocessing

    private func extractFromJavaScript(_ items: [NSExtensionItem]) async -> (title: String?, url: URL)? {
        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                guard provider.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) else {
                    continue
                }
                guard let plist = try? await provider.loadItem(
                    forTypeIdentifier: UTType.propertyList.identifier
                ) as? [String: Any],
                    let jsResults = plist[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any]
                else {
                    continue
                }
                let title = jsResults["pageTitle"] as? String
                let urlString = jsResults["pageURL"] as? String
                guard let urlString, let url = URL(string: urlString) else {
                    continue
                }
                return (title, url)
            }
        }
        Log.action.debug("MarkdownLinkStrategy: no JS data found")
        return nil
    }
}
