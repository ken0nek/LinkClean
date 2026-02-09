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
import LinkCleanCommon

class ActionViewController: ActionExtensionViewController {
    override func processInputItems() {
        Task {
            Log.logger.debug("processInputItems started")

            // 1. Always try JS extraction first (Safari only provides URLs via JS)
            let jsResult = await extractFromJavaScript()
            Log.logger.debug("JS extraction: title = \(jsResult?.title ?? "nil", privacy: .public), url = \(jsResult?.url.absoluteString ?? "nil", privacy: .public)")

            // 2. Determine URL: prefer JS URL, fall back to extractURL
            let url: URL
            if let jsURL = jsResult?.url {
                url = jsURL
            } else if let fallbackURL = await extractURL() {
                url = fallbackURL
            } else {
                Log.logger.debug("No URL extracted from JS or fallback, dismissing")
                dismissExtension()
                return
            }

            // 3. Determine title: prefer JS title, fall back to LPMetadataProvider
            let title: String?
            if let jsTitle = jsResult?.title {
                title = jsTitle
                Log.logger.debug("Using JS title: \(jsTitle, privacy: .public)")
            } else {
                title = await fetchTitle(for: url)
                Log.logger.debug("Using LPMetadataProvider title: \(title ?? "nil", privacy: .public)")
            }

            let cleaned = URLCleaner.clean(url, removing: parameterStore.enabledParameters())
            let markdown = MarkdownFormatter.markdownLink(title: title, url: cleaned.absoluteString)
            Log.logger.debug("Markdown output: \(markdown, privacy: .public)")
            UIPasteboard.general.string = markdown

            saveHistory(input: url.absoluteString, output: cleaned.absoluteString)
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

        Log.logger.debug("extractFromJavaScript: no JS data found")
        return nil
    }

    // MARK: - LPMetadataProvider fallback

    private func fetchTitle(for url: URL) async -> String? {
        let provider = LPMetadataProvider()
        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            return metadata.title
        } catch {
            return nil
        }
    }
}
