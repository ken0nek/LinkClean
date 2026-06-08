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
                // Attachments present but unparseable = host-compat gap; nothing
                // shared at all = noURL.
                analytics.capture(.actionCleanFailed(reason: hasInputAttachments ? .invalidInput : .noURL))
                playErrorHaptic()
                showNoLinkFoundToastThenDismiss()
                return
            }

            let result = URLCleaner.cleanResult(url, removing: parameterStore.enabledParameters())
            let cleaned = result.cleaned
            Log.action.debug("Input URL: \(url.absoluteString, privacy: .public)")
            Log.action.debug("Cleaned URL: \(cleaned.absoluteString, privacy: .public)")
            UIPasteboard.general.url = cleaned

            // Signal at clean-success (not dismissal) to maximize in-process
            // network time in the short-lived extension (analytics §8).
            analytics.capture(.actionCleanSucceeded(
                changed: result.removedCount > 0,
                removedCount: result.removedCount
            ))
            saveHistory(input: url.absoluteString, output: cleaned.absoluteString)
            recordSuccessfulRun()
            playSuccessHaptic()
            showToastThenDismiss()
        }
    }
}
