//
//  ActionHostViewController.swift
//  LinkCleanExtensionUI
//
//  Created by Ken Tominaga on 6/11/26.
//

import OSLog
import UIKit
import LinkCleanCore
import LinkCleanData
import LinkCleanAnalytics

/// The one UIKit host every action extension shares: it gathers the extension
/// input, runs the ``ActionPipeline`` for its ``strategy``, and renders the
/// returned ``ActionPresentation`` (pasteboard write, haptic, toast, dismiss).
/// Each extension target is now a ~3-line subclass that names a strategy.
open class ActionHostViewController: UIViewController {
    /// The surface-specific output strategy. Subclasses override this.
    open var strategy: any ActionOutputStrategy { CleanLinkStrategy() }

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        // Initialize the SDK per extension process (each target has its own
        // signal cache, same App ID + shared default user). See analytics §8.
        TelemetryDeckAnalytics.start(surface: strategy.surface)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        let hasAttachments = items.contains { !($0.attachments ?? []).isEmpty }
        let pipeline = ActionPipeline(strategy: strategy)
        Task {
            let presentation = await pipeline.run(items: items, hasAttachments: hasAttachments)
            render(presentation)
        }
    }

    private func render(_ presentation: ActionPresentation) {
        if let payload = presentation.payload {
            write(payload)
        }
        playHaptic(presentation.haptic)
        showToast(presentation.toast)
    }

    private func write(_ payload: PasteboardPayload) {
        switch payload.content {
        case .url(let url):
            Log.action.debug("Pasteboard URL: \(url.absoluteString, privacy: .public)")
            UIPasteboard.general.url = url
        case .string(let string):
            Log.action.debug("Pasteboard string: \(string, privacy: .public)")
            UIPasteboard.general.string = string
        }
    }

    private func playHaptic(_ kind: HapticKind) {
        let generator = UINotificationFeedbackGenerator()
        switch kind {
        case .success: generator.notificationOccurred(.success)
        case .error: generator.notificationOccurred(.error)
        }
    }

    // MARK: - Toast & dismiss

    private func showToast(_ kind: ToastKind) {
        let message: String
        let systemImage: String
        switch kind {
        case .copied:
            message = String(
                localized: "toast.copied",
                defaultValue: "Copied",
                bundle: .module,
                comment: "Toast shown after copying cleaned URL"
            )
            systemImage = "checkmark"
        case .noLinkFound:
            message = String(
                localized: "toast.noLinkFound",
                defaultValue: "No link found",
                bundle: .module,
                comment: "Toast shown when the shared content contains no web link"
            )
            systemImage = "xmark"
        }
        showToast(message: message, systemImage: systemImage)
    }

    private func showToast(message: String, systemImage: String) {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blur.alpha = 0
        blur.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        let icon = UIImageView(image: UIImage(systemName: systemImage))
        icon.tintColor = .label
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = message
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
            .withSymbolicTraits(.traitBold) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        label.font = UIFont(descriptor: descriptor, size: 0)
        label.textColor = .label

        let stack = UIStackView(arrangedSubviews: [icon, label])
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

    private func dismissExtension() {
        Log.action.debug("dismissExtension")
        extensionContext?.completeRequest(returningItems: nil)
    }
}
