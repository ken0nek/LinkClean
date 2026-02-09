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

            let saveHistory = UserDefaults(suiteName: AppGroup.identifier)?
                .object(forKey: SettingsKeys.saveHistoryEnabled) as? Bool ?? true
            if saveHistory, let container = HistoryContainer.makeShared() {
                try? HistoryRecorder.save(input: url.absoluteString, output: cleaned.absoluteString, in: container)
            }

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            showToastThenDismiss()
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

    private func showToastThenDismiss() {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blur.alpha = 0
        blur.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
        checkmark.tintColor = .label
        checkmark.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = String(localized: "Copied", bundle: .main, comment: "Toast shown after copying cleaned URL")
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
            .withSymbolicTraits(.traitBold) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        label.font = UIFont(descriptor: descriptor, size: 0)
        label.textColor = .label

        let stack = UIStackView(arrangedSubviews: [checkmark, label])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center

        stack.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: blur.contentView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor, constant: -10),
            stack.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor, constant: -16),
        ])

        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)
        NSLayoutConstraint.activate([
            blur.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            blur.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        view.layoutIfNeeded()
        blur.layer.cornerRadius = blur.bounds.height / 2
        blur.clipsToBounds = true

        UIView.animate(withDuration: 0.2) {
            blur.alpha = 1
            blur.transform = .identity
        } completion: { _ in
            UIView.animate(withDuration: 0.15, delay: 0.6) {
                blur.alpha = 0
            } completion: { [weak self] _ in
                self?.dismiss()
            }
        }
    }

    private func dismiss() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
