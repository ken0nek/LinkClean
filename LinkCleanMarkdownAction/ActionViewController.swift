//
//  ActionViewController.swift
//  LinkCleanMarkdownAction
//
//  Created by Ken Tominaga on 2/6/26.
//

import UIKit
import UniformTypeIdentifiers
import LinkPresentation
import OSLog
import LinkCleanKit

class ActionViewController: ActionExtensionViewController {
    override func processInputItems() {
        Task {
            Log.action.debug("processInputItems started")

            // 1. Always try JS extraction first (Safari only provides URLs via JS)
            let jsResult = await extractFromJavaScript()
            Log.action.debug("JS extraction: title = \(jsResult?.title ?? "nil", privacy: .public), url = \(jsResult?.url.absoluteString ?? "nil", privacy: .public)")

            // 2. Determine URL: prefer JS URL, fall back to extractURL
            let url: URL
            if let jsURL = jsResult?.url {
                url = jsURL
            } else if let fallbackURL = await extractURL() {
                url = fallbackURL
            } else {
                Log.action.debug("No URL extracted from JS or fallback, dismissing")
                analytics.capture(.actionMarkdownFailed(reason: .noURL))
                playErrorHaptic()
                showNoLinkFoundToastThenDismiss()
                return
            }

            let cleaned = URLCleaner.clean(url, removing: parameterStore.enabledParameters())

            // 3. Determine title: prefer JS title, fall back to LPMetadataProvider
            // (fetch the cleaned URL so tracking parameters never go over the wire)
            let title: String?
            let titleSource: AnalyticsEvent.TitleSource
            if let jsTitle = jsResult?.title {
                title = jsTitle
                titleSource = .javascript
                Log.action.debug("Using JS title: \(jsTitle, privacy: .public)")
            } else if let fetched = await fetchTitle(for: cleaned) {
                title = fetched
                titleSource = .linkPresentation
                Log.action.debug("Using LPMetadataProvider title: \(fetched, privacy: .public)")
            } else {
                title = nil
                titleSource = .urlOnly
                Log.action.debug("No title resolved; emitting URL only")
            }

            let markdown = MarkdownFormatter.markdownLink(title: title, url: cleaned.absoluteString)
            Log.action.debug("Markdown output: \(markdown, privacy: .public)")
            UIPasteboard.general.string = markdown

            // Signal at clean-success (not dismissal) to maximize in-process
            // network time in the short-lived extension (analytics §8).
            analytics.capture(.actionMarkdownSucceeded(
                titleSource: titleSource,
                changed: cleaned.absoluteString != url.absoluteString
            ))
            saveHistory(input: url.absoluteString, output: cleaned.absoluteString)
            recordSuccessfulRun()
            playSuccessHaptic()
            showToastThenDismiss()
        }
    }

    // MARK: - JavaScript preprocessing

    private func extractFromJavaScript() async -> (title: String?, url: URL)? {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            return nil
        }

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

        Log.action.debug("extractFromJavaScript: no JS data found")
        return nil
    }

    // MARK: - LPMetadataProvider fallback

    private func fetchTitle(for url: URL) async -> String? {
        let provider = LPMetadataProvider()
        provider.timeout = 5
        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            return metadata.title
        } catch {
            return nil
        }
    }
}
