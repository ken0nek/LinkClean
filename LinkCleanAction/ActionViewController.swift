//
//  ActionViewController.swift
//  LinkCleanAction
//
//  Created by Ken Tominaga on 2/1/26.
//

import OSLog
import UIKit
import LinkCleanCommon

class ActionViewController: ActionExtensionViewController {
    override func processInputItems() {
        Task {
            guard let url = await extractURL() else {
                dismissExtension()
                return
            }

            let cleaned = URLCleaner.clean(url, removing: parameterStore.enabledParameters())
            Log.logger.debug("Input URL: \(url.absoluteString, privacy: .public)")
            Log.logger.debug("Cleaned URL: \(cleaned.absoluteString, privacy: .public)")
            UIPasteboard.general.url = cleaned

            saveHistory(input: url.absoluteString, output: cleaned.absoluteString)
            playSuccessHaptic()
            showToastThenDismiss()
        }
    }
}
