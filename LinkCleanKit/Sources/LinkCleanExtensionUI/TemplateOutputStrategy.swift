//
//  TemplateOutputStrategy.swift
//  LinkCleanExtensionUI
//
//  Created by Ken Tominaga on 6/14/26.
//

import Foundation
import UniformTypeIdentifiers
import OSLog
import LinkCleanCore
import LinkCleanData

/// "Copy as you want": render the user's selected ``LinkTemplate`` for the cleaned
/// link and copy the result. The one strategy that subsumes Markdown / Title+URL /
/// HTML / Citation / … — each is just a template (`copy-as-you-want` §6.3), so a
/// new format is a new preset, not a new strategy or target.
///
/// Two costs are paid only when earned: it reads the ``EntitlementStore`` snapshot
/// to fail closed to a free format for a free user (§4.3, never a paywall in the
/// extension), and it triggers the LPMetadata title fetch **only** when the active
/// template actually contains `{title}`/`{markdown}` (§5) — a title-free template
/// stays instant.
public struct TemplateOutputStrategy: ActionOutputStrategy {
    private let templates: TemplateStore
    private let entitlements: EntitlementStore
    private let metadata: LinkMetadataService
    private let now: @Sendable () -> Date

    /// `timeout: 5` caps the LPMetadata fetch — the action extension is a
    /// short-lived, memory-limited process, so a slow host must not stall it before
    /// the toast (same cap the Markdown strategy used). `now` is injected so
    /// `{date}`/`{time}` rendering stays deterministically testable (§5).
    public init(
        templates: TemplateStore = TemplateStore(),
        entitlements: EntitlementStore = EntitlementStore(),
        metadata: LinkMetadataService = DefaultLinkMetadataService(timeout: 5),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.templates = templates
        self.entitlements = entitlements
        self.metadata = metadata
        self.now = now
    }

    public var surface: String { "copyAction" }

    public func extract(from items: [NSExtensionItem]) async -> ExtractedURL? {
        // Safari only provides the page URL via JS preprocessing; try it first.
        if let js = await extractFromJavaScript(items) {
            return ExtractedURL(url: js.url, jsTitle: js.title)
        }
        guard let url = await URLExtraction.firstWebURL(from: items) else { return nil }
        return ExtractedURL(url: url)
    }

    public func failureEvent(hasAttachments: Bool) -> AnalyticsEvent {
        .actionFormatFailed(reason: hasAttachments ? .invalidInput : .noURL)
    }

    /// The single / default output: render the first active format the user is
    /// entitled to. Used when at most one format is active (the host skips the picker).
    public func result(for outcome: CleanOutcome, extracted: ExtractedURL) async -> StrategyResult {
        await render(activeTemplates().first ?? .freeFallback, outcome: outcome, extracted: extracted)
    }

    /// The active formats, offered as picker choices when two or more are active.
    /// Fewer than two ⇒ no picker (the host calls ``result(for:extracted:)``).
    public func choices() -> [ActionChoice] {
        let active = activeTemplates()
        guard active.count >= 2 else { return [] }
        return active.map { ActionChoice(id: $0.id, title: displayName(for: $0)) }
    }

    /// Render the chosen format; falls back to the first active (then the free
    /// default) if the id no longer resolves — never refuses to produce output.
    public func result(for outcome: CleanOutcome, extracted: ExtractedURL, choiceID: UUID) async -> StrategyResult {
        let active = activeTemplates()
        let template = active.first { $0.id == choiceID } ?? active.first ?? .freeFallback
        return await render(template, outcome: outcome, extracted: extracted)
    }

    // MARK: - Rendering

    private func activeTemplates() -> [LinkTemplate] {
        templates.resolveActive(tier: entitlements.current())
    }

    private func render(_ template: LinkTemplate, outcome: CleanOutcome, extracted: ExtractedURL) async -> StrategyResult {
        let cleaned = URL(string: outcome.cleaned) ?? extracted.url

        // Pay the title-fetch latency only when the chosen template needs it (§5).
        let title: String? = template.usesTitle
            ? await resolveTitle(jsTitle: extracted.jsTitle, cleaned: cleaned)
            : nil

        let context = TemplateContext(outcome: outcome, title: title, date: now())
        let text = TemplateRenderer.render(template, context)
        let event = AnalyticsEvent.actionFormatSucceeded(
            preset: template.isBuiltin,
            changed: outcome.telemetry.changed
        )
        // A formatted copy is still a realized clean: fan out the Tier-1 catalog-gap
        // reference signals too, exactly as CleanLinkStrategy does (analytics §7).
        let events = [event] + outcome.telemetry.referenceObservedEvents
        return StrategyResult(payload: PasteboardPayload(.string(text)), successEvents: events)
    }

    /// Prefer Safari's JS-provided title; otherwise fetch LPMetadata against the
    /// **cleaned** URL so tracking parameters never go over the wire (the title
    /// path the Markdown strategy used before folding into the engine).
    private func resolveTitle(jsTitle: String?, cleaned: URL) async -> String? {
        if let jsTitle { return jsTitle }
        return await metadata.fetchMetadata(for: cleaned).title
    }

    // MARK: - Picker labels

    /// The label the picker shows: a localized name for a built-in preset, the
    /// user's own text for a custom template. The presets are localized in this
    /// target's own catalog (explicit keys, `Bundle.module`), since the app's
    /// generated symbols aren't visible from the extension.
    private func displayName(for template: LinkTemplate) -> String {
        template.isBuiltin ? Self.presetName(template.name) : template.name
    }

    private static func presetName(_ id: String) -> String {
        switch id {
        case "clean": String(localized: "format.clean", defaultValue: "Clean Link", bundle: .module, comment: "Copy-format picker: the cleaned link only")
        case "markdown": String(localized: "format.markdown", defaultValue: "Markdown", bundle: .module, comment: "Copy-format picker: a Markdown link")
        case "titleAndURL": String(localized: "format.titleAndURL", defaultValue: "Title + Link", bundle: .module, comment: "Copy-format picker: title then link")
        case "html": String(localized: "format.html", defaultValue: "HTML", bundle: .module, comment: "Copy-format picker: an HTML anchor")
        case "quote": String(localized: "format.quote", defaultValue: "Quote with Source", bundle: .module, comment: "Copy-format picker: a blockquote with the link")
        case "citation": String(localized: "format.citation", defaultValue: "Citation", bundle: .module, comment: "Copy-format picker: title — host (date)")
        case "slack": String(localized: "format.slack", defaultValue: "Slack & Discord", bundle: .module, comment: "Copy-format picker: the Slack/Discord link format")
        case "plainTitle": String(localized: "format.plainTitle", defaultValue: "Title Only", bundle: .module, comment: "Copy-format picker: the page title only")
        default: id
        }
    }

    // MARK: - JavaScript preprocessing

    private func extractFromJavaScript(_ items: [NSExtensionItem]) async -> (title: String?, url: URL)? {
        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                guard provider.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) else {
                    continue
                }
                guard let plist = try? await provider.loadItem(
                    forTypeIdentifier: UTType.propertyList.identifier
                ) as? [String: Any],
                    let jsResults = plist[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any]
                else {
                    continue
                }
                let title = jsResults["pageTitle"] as? String
                let urlString = jsResults["pageURL"] as? String
                guard let urlString, let url = URL(string: urlString) else {
                    continue
                }
                return (title, url)
            }
        }
        Log.action.debug("TemplateOutputStrategy: no JS data found")
        return nil
    }
}
