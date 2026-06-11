//
//  ActionViewController.swift
//  LinkCleanAction
//
//  Created by Ken Tominaga on 2/1/26.
//

import OSLog
import UIKit
import LinkCleanCore
import LinkCleanData
import LinkCleanExtensionUI

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

            guard let outcome = try? await cleaningService.clean(url.absoluteString) else {
                // A validated web URL the service still couldn't clean — defensive.
                analytics.capture(.actionCleanFailed(reason: .invalidInput))
                playErrorHaptic()
                showNoLinkFoundToastThenDismiss()
                return
            }
            let cleaned = URL(string: outcome.cleaned) ?? url
            Log.action.debug("Input URL: \(url.absoluteString, privacy: .public)")
            Log.action.debug("Cleaned URL: \(cleaned.absoluteString, privacy: .public)")
            UIPasteboard.general.url = cleaned

            // Signal at clean-success (not dismissal) to maximize in-process
            // network time in the short-lived extension (analytics §8).
            analytics.capture(.actionCleanSucceeded(telemetry: outcome.telemetry))
            // Tier 1 catalog-gap names. Emitted after the success signal so the
            // priority event uses the scarce in-process network window first;
            // these persist + converge in aggregate across runs (analytics §8).
            for parameter in outcome.telemetry.referenceMatches {
                analytics.capture(.parametersReferenceObserved(parameter: parameter))
            }
            saveHistory(input: url.absoluteString, output: outcome.cleaned)
            recordSuccessfulRun()
            playSuccessHaptic()
            showToastThenDismiss()
        }
    }
}
