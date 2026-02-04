//
//  ActionViewController.swift
//  LinkCleanAction
//
//  Created by Ken Tominaga on 2/1/26.
//

import UIKit
import UniformTypeIdentifiers
import LinkCleanCommon

class ActionViewController: UIViewController {
    private let parameterStore = TrackingParameterStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        processInputItems()
    }

    private func processInputItems() {
        Task {
            guard let url = await extractURL() else {
                dismiss()
                return
            }

            let cleaned = URLCleaner.clean(url, removing: parameterStore.enabledParameters())
            UIPasteboard.general.url = cleaned

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            dismiss()
        }
    }

    private func extractURL() async -> URL? {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            return nil
        }

        for item in items {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let url = try? await provider.loadItem(
                        forTypeIdentifier: UTType.url.identifier
                    ) as? URL {
                        return url
                    }
                }

                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let text = try? await provider.loadItem(
                        forTypeIdentifier: UTType.plainText.identifier
                    ) as? String,
                        let url = URL(string: text),
                        url.scheme?.hasPrefix("http") == true
                    {
                        return url
                    }
                }
            }
        }

        return nil
    }

    private func dismiss() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
