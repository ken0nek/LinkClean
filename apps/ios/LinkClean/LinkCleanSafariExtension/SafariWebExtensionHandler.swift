//
//  SafariWebExtensionHandler.swift
//  LinkCleanSafariExtension
//
//  Created by Ken Tominaga on 6/26/26.
//

import SafariServices
import LinkCleanCore

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        let message: Any?
        if #available(iOS 15.0, macOS 11.0, *) {
            message = request?.userInfo?[SFExtensionMessageKey]
        } else {
            message = request?.userInfo?["message"]
        }

        // The popup sends { "url": "<active tab URL>", "title"?: "<page title>" }.
        // Clean it with the same engine the app and the other extensions use, then
        // return { "cleaned": "<clean URL>", "markdown": "[title](link)" } — or
        // { "error": ... } when there's no web link to clean. The Markdown link text
        // falls back to the host when the page has no title, so it is never a broken
        // `[](url)` (plan 004). The URL is never logged: this handler mirrors the
        // engine's no-logging posture (plan 004, decision 5).
        let payload: [String: Any]
        if let dict = message as? [String: Any], let url = dict["url"] as? String {
            if URLCleaner.isValidURL(url) {
                let cleaned = URLCleaner.clean(url)
                let host = URLComponents(string: cleaned)?.host
                let pageTitle = (dict["title"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                let markdown = MarkdownFormatter.markdownLink(title: pageTitle ?? host, url: cleaned)
                payload = ["cleaned": cleaned, "markdown": markdown]
            } else {
                payload = ["error": "invalidInput"]
            }
        } else {
            payload = ["error": "invalidMessage"]
        }

        let response = NSExtensionItem()
        if #available(iOS 15.0, macOS 11.0, *) {
            response.userInfo = [SFExtensionMessageKey: payload]
        } else {
            response.userInfo = ["message": payload]
        }

        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

}
