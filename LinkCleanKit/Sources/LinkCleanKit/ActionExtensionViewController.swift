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
    public let analytics: AnalyticsService = TelemetryDeckAnalytics()

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        // Initialize the SDK per extension process (each target has its own
        // signal cache, same App ID + shared default user). See analytics §8.
        TelemetryDeckAnalytics.start()
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

        let providers = items.flatMap { $0.attachments ?? [] }
        if let url = await Self.extractURL(from: providers) {
            return url
        }

        Log.action.debug("extractURL: no URL found in input items")
        return nil
    }

    /// Returns the first web URL found in the providers. URL attachments
    /// from any provider are preferred over links parsed from plain text,
    /// so a host's canonical URL wins over a link embedded in caption text.
    public static func extractURL(from providers: [NSItemProvider]) async -> URL? {
        for provider in providers {
            if let url = await loadURL(from: provider), URLCleaner.isWebURL(url) {
                return url
            }
        }

        for provider in providers {
            if let text = await loadPlainText(from: provider),
                let url = firstWebURL(in: text)
            {
                return url
            }
        }

        return nil
    }

    /// Finds the first web link in text. Hosts share links as bare strings
    /// (LinkedIn) or as "Title + link" prose; parsing the whole string with
    /// `URL(string:)` would percent-encode the prose into a mangled URL.
    static func firstWebURL(in text: String) -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        return detector.matches(in: text, options: [], range: range)
            .compactMap(\.url)
            .first(where: URLCleaner.isWebURL)
    }

    /// `loadItem` returns whatever representation the host registered: an
    /// object (`NSURL`/`NSString`) for item-backed providers, raw URL bytes,
    /// or — for `init(object:)`-registered URLs — a plist payload that only
    /// `NSItemProviderReading` understands. Try each shape for every
    /// conforming identifier, then fall back to `loadObject`.
    private static func loadURL(from provider: NSItemProvider) async -> URL? {
        let conforming = registeredIdentifiers(conformingTo: .url, in: provider)
        guard !conforming.isEmpty else {
            return nil
        }

        // File-url identifiers go last: when a provider registers both, the
        // web representation is the one worth extracting.
        let identifiers = conforming.filter { UTType($0)?.conforms(to: .fileURL) != true }
            + conforming.filter { UTType($0)?.conforms(to: .fileURL) == true }

        for identifier in identifiers {
            switch try? await provider.loadItem(forTypeIdentifier: identifier) {
            case let url as URL:
                return url
            case let data as Data:
                if let url = URL(dataRepresentation: data, relativeTo: nil), url.scheme != nil {
                    return url
                }
            case let text as String:
                if let url = URL(string: text) {
                    return url
                }
            default:
                break
            }
        }

        return await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                continuation.resume(returning: url)
            }
        }
    }

    private static func loadPlainText(from provider: NSItemProvider) async -> String? {
        let identifiers = registeredIdentifiers(conformingTo: .plainText, in: provider)
        guard !identifiers.isEmpty else {
            return nil
        }

        for identifier in identifiers {
            switch try? await provider.loadItem(forTypeIdentifier: identifier) {
            case let text as String:
                return text
            case let data as Data:
                if let text = String(data: data, encoding: .utf8) {
                    return text
                }
            default:
                break
            }
        }

        return await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: String.self) { text, _ in
                continuation.resume(returning: text)
            }
        }
    }

    /// Hosts register concrete subtypes (`public.utf8-plain-text`,
    /// `public.file-url`), and `loadItem` wants a registered identifier,
    /// not a parent type.
    private static func registeredIdentifiers(conformingTo type: UTType, in provider: NSItemProvider) -> [String] {
        provider.registeredTypeIdentifiers.filter { identifier in
            UTType(identifier)?.conforms(to: type) == true
        }
    }

    // MARK: - History

    public func saveHistory(input: String, output: String) {
        // The onboarding "Try it" run is a practice clean, not a real one —
        // never persist it. `recordSuccessfulRun` still fires so the guide can
        // detect success.
        guard !OnboardingDemo.matches(urlString: input) else {
            Log.action.debug("saveHistory: skipping onboarding demo link")
            return
        }

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

    // MARK: - Onboarding success signal

    /// Records that an action extension completed successfully, so the app's
    /// onboarding/guide "Try it now" flow can auto-detect the run. Written to
    /// the App Group suite because the app process reads it on scene activation.
    /// Independent of `saveHistoryEnabled`. The `defaults` parameter is
    /// injectable so tests can run without the App Group container.
    public func recordSuccessfulRun(
        at date: Date = .now,
        in defaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier)
    ) {
        defaults?.set(date.timeIntervalSinceReferenceDate, forKey: SettingsKeys.lastActionExtensionRunAt)
    }

    // MARK: - Haptic

    public func playSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    public func playErrorHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Toast & Dismiss

    public func showToastThenDismiss() {
        showToastThenDismiss(
            message: String(
                localized: "toast.copied",
                defaultValue: "Copied",
                bundle: .module,
                comment: "Toast shown after copying cleaned URL"
            ),
            systemImage: "checkmark"
        )
    }

    public func showNoLinkFoundToastThenDismiss() {
        showToastThenDismiss(
            message: String(
                localized: "toast.noLinkFound",
                defaultValue: "No link found",
                bundle: .module,
                comment: "Toast shown when the shared content contains no web link"
            ),
            systemImage: "xmark"
        )
    }

    public func showToastThenDismiss(message: String, systemImage: String) {
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

    public func dismissExtension() {
        Log.action.debug("dismissExtension")
        extensionContext?.completeRequest(returningItems: nil)
    }
}
