//
//  ActionExtensionViewController.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/9/26.
//

import OSLog
import UIKit
import UniformTypeIdentifiers

open class ActionExtensionViewController: UIViewController {
    public let parameterStore = TrackingParameterStore()

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        processInputItems()
    }

    /// Override point for subclasses. Called automatically in `viewDidAppear`.
    open func processInputItems() {}

    // MARK: - URL Extraction

    public func extractURL() async -> URL? {
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

        Log.action.debug("extractURL: no URL found in input items")
        return nil
    }

    // MARK: - History

    public func saveHistory(input: String, output: String) {
        let saveHistory = UserDefaults(suiteName: AppGroup.identifier)?
            .object(forKey: SettingsKeys.saveHistoryEnabled) as? Bool ?? true
        if saveHistory, let container = HistoryContainer.makeShared() {
            do {
                try HistoryRecorder.save(input: input, output: output, in: container)
            } catch {
                Log.action.debug("saveHistory failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Haptic

    public func playSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Toast & Dismiss

    public func showToastThenDismiss() {
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
                self?.dismissExtension()
            }
        }
    }

    public func dismissExtension() {
        Log.action.debug("dismissExtension")
        extensionContext?.completeRequest(returningItems: nil)
    }
}
