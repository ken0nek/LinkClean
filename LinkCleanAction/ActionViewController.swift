//
//  ActionViewController.swift
//  LinkCleanAction
//
//  Created by Ken Tominaga on 2/1/26.
//

import OSLog
import UIKit
import LinkCleanKit

class ActionViewController: ActionExtensionViewController {
    override func processInputItems() {
        Task {
            guard let url = await extractURL() else {
                analytics.capture(.actionCleanFailed(reason: .noURL))
                playErrorHaptic()
                showNoLinkFoundToastThenDismiss()
                return
            }

            let cleaned = URLCleaner.clean(url, removing: parameterStore.enabledParameters())
            Log.action.debug("Input URL: \(url.absoluteString, privacy: .public)")
            Log.action.debug("Cleaned URL: \(cleaned.absoluteString, privacy: .public)")
            UIPasteboard.general.url = cleaned

            // Signal at clean-success (not dismissal) to maximize in-process
            // network time in the short-lived extension (analytics §8).
            analytics.capture(.actionCleanSucceeded(
                changed: cleaned.absoluteString != url.absoluteString,
                removedCount: URLCleaner.removedParameterCount(from: url.absoluteString, to: cleaned.absoluteString)
            ))
            saveHistory(input: url.absoluteString, output: cleaned.absoluteString)
            recordSuccessfulRun()
            playSuccessHaptic()
            showToastThenDismiss()
        }
    }
}
