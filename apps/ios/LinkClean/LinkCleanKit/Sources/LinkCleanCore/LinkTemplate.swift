//
//  LinkTemplate.swift
//  LinkCleanCore
//
//  Created by Ken Tominaga on 6/14/26.
//

import Foundation

/// A swappable identifier inside a ``LinkTemplate`` format string — `{link}`,
/// `{title}`, `{date}`, … An unknown `{token}` is left literal by
/// ``TemplateRenderer`` (the forgiving, no-error-state design — `copy-as-you-want`
/// §2.1), so this enum only lists the identifiers the engine actually substitutes.
///
/// Most tokens are **sync** (a field of the clean or an injected clock); ``title``
/// and ``markdown`` are **async** — they need a page-title lookup, the one cost a
/// title-free template avoids (`LinkTemplate.usesTitle`).
public enum TemplateToken: String, CaseIterable, Sendable {
    /// The cleaned URL (`CleanOutcome.cleaned`).
    case link
    /// The page title — needs a metadata fetch unless Safari preprocessing
    /// already provided one. Empty string when unavailable.
    case title
    /// The link's host, `www.`-stripped (`youtube.com`).
    case host
    /// Today's date from the injected clock, ISO `yyyy-MM-dd`.
    case date
    /// The current time from the injected clock, 24-hour `HH:mm`.
    case time
    /// The uncleaned input URL (`CleanOutcome.input`) — provenance.
    case originalLink
    /// How many tracking parameters this clean removed — on-brand.
    case removedCount
    /// The URL scheme (`https`).
    case scheme
    /// The URL path (`/watch`).
    case path
    /// The URL query string, without the leading `?`.
    case query
    /// Shorthand for `[{title}]({link})`, via ``MarkdownFormatter`` (so it inherits
    /// the URL-as-link-text fallback when no title resolves).
    case markdown
    /// A literal newline — a convenience for single-line editors (the editor is
    /// multi-line, so a typed return works too).
    case newline
    /// A literal tab.
    case tab

    /// Whether producing this token's value requires a page-title lookup (the
    /// async cost the renderer pays only when a template actually needs it).
    public var needsTitle: Bool {
        self == .title || self == .markdown
    }
}

/// A named link format — either a built-in **preset** (`copy-as-you-want` §3) or a
/// user-authored **custom** template. One value type covers both so the store, the
/// extension strategy, and the editor all speak the same currency.
///
/// **`name` is an identifier for built-ins, copy for custom.** Domain types ship
/// identifiers, not localized copy (see `CLAUDE.md`): a built-in's `name` is a
/// stable kind id (`"markdown"`) the app maps to a localized symbol, exactly like
/// `TrackingParameterKind.id`. A custom template's `name` is the user's own text.
public struct LinkTemplate: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    /// Built-in: a stable kind identifier the app localizes (`"markdown"`).
    /// Custom: the user-entered display name.
    public var name: String
    /// The format string with `{token}` placeholders (`"[{title}]({link})"`).
    public var format: String
    /// Whether this is a shipped preset (vs. a user-authored template).
    public let isBuiltin: Bool
    /// Whether selecting this format as the action's default needs Pro. Every
    /// custom template requires Pro; presets follow `copy-as-you-want` §3 (Clean +
    /// Markdown free, the rest Pro).
    public let requiresPro: Bool

    public init(id: UUID, name: String, format: String, isBuiltin: Bool, requiresPro: Bool) {
        self.id = id
        self.name = name
        self.format = format
        self.isBuiltin = isBuiltin
        self.requiresPro = requiresPro
    }

    /// Whether rendering this template triggers the (async) page-title lookup — the
    /// renderer fetches a title only when this is true (`copy-as-you-want` §5).
    public var usesTitle: Bool {
        format.contains("{\(TemplateToken.title.rawValue)}")
            || format.contains("{\(TemplateToken.markdown.rawValue)}")
    }
}

public extension LinkTemplate {
    /// Creates a user-authored custom template (always non-builtin, always Pro).
    static func custom(id: UUID, name: String, format: String) -> LinkTemplate {
        LinkTemplate(id: id, name: name, format: format, isBuiltin: false, requiresPro: true)
    }

    // MARK: Built-in presets (`copy-as-you-want` §3)

    // Fixed, sequential UUIDs so the persisted active set keeps resolving to the
    // same presets across launches and app versions. Each literal is a
    // compile-time constant in valid UUID form, so `UUID(uuidString:)` never
    // returns nil — the force-unwrap's documented invariant.

    /// `{link}` — the cleaned URL, free. (The dedicated Clean action still owns the
    /// instant URL-only path; this is the same format offered as a copy preset.)
    static let cleanPreset = LinkTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "clean", format: "{link}", isBuiltin: true, requiresPro: false
    )

    /// `[{title}]({link})` via the `{markdown}` shorthand — Markdown, free (already
    /// shipped free; never clawed back, iap §6). The action's default when nothing
    /// else is selected. Uses `{markdown}` rather than a literal `[{title}]({link})`
    /// so it inherits ``MarkdownFormatter``'s behavior: bracket/paren escaping and
    /// the URL-as-link-text fallback when no title resolves (`[url](url)`, not a
    /// broken empty label) — preserving the former Markdown action's output.
    static let markdownPreset = LinkTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "markdown", format: "{markdown}", isBuiltin: true, requiresPro: false
    )

    /// `{title}` then the link on the next line — Pro.
    static let titleAndURLPreset = LinkTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "titleAndURL", format: "{title}\n{link}", isBuiltin: true, requiresPro: true
    )

    /// `<a href="{link}">{title}</a>` — HTML source, Pro.
    static let htmlPreset = LinkTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "html", format: "<a href=\"{link}\">{title}</a>", isBuiltin: true, requiresPro: true
    )

    /// `> {title}` then the link — a blockquote with its source, Pro.
    static let quotePreset = LinkTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        name: "quote", format: "> {title}\n{link}", isBuiltin: true, requiresPro: true
    )

    /// `{title} — {host} ({date})` — a lightweight citation, Pro.
    static let citationPreset = LinkTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
        name: "citation", format: "{title} — {host} ({date})", isBuiltin: true, requiresPro: true
    )

    /// `<{link}|{title}>` — the Slack/Discord angle-bracket link, Pro.
    static let slackPreset = LinkTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
        name: "slack", format: "<{link}|{title}>", isBuiltin: true, requiresPro: true
    )

    /// `{title}` alone — Pro.
    static let plainTitlePreset = LinkTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
        name: "plainTitle", format: "{title}", isBuiltin: true, requiresPro: true
    )

    /// Every shipped preset, in display order (free first).
    static let builtins: [LinkTemplate] = [
        .cleanPreset, .markdownPreset, .titleAndURLPreset, .htmlPreset,
        .quotePreset, .citationPreset, .slackPreset, .plainTitlePreset,
    ]

    /// The free default the action falls back to — Markdown, the free preset that
    /// preserves the action's shipped behavior (`copy-as-you-want` §4.3).
    static let freeFallback = markdownPreset
}

/// Everything ``TemplateRenderer`` needs to fill a template, assembled from a
/// ``CleanOutcome`` plus an optional resolved title and an **injected** clock
/// (never `Date()` inline, so rendering stays deterministically testable —
/// `copy-as-you-want` §5).
public struct TemplateContext: Sendable, Equatable {
    /// The cleaned URL (`{link}`, and the source of `{scheme}`/`{path}`/`{query}`).
    public let cleaned: String
    /// The uncleaned input URL (`{originalLink}`).
    public let original: String
    /// The `www.`-stripped host (`{host}`).
    public let host: String
    /// Tracking parameters removed (`{removedCount}`).
    public let removedCount: Int
    /// The page title (`{title}`), or `nil` when none resolved → renders empty.
    public let title: String?
    /// The clock reading for `{date}`/`{time}`.
    public let date: Date

    public init(cleaned: String, original: String, host: String, removedCount: Int, title: String?, date: Date) {
        self.cleaned = cleaned
        self.original = original
        self.host = host
        self.removedCount = removedCount
        self.title = title
        self.date = date
    }

    /// Builds a context from a clean, deriving `{host}` from the cleaned URL the
    /// same way the clean telemetry does (`www.`-stripped; an unparseable host
    /// renders empty rather than the `"unknown"` analytics sentinel).
    public init(outcome: CleanOutcome, title: String?, date: Date) {
        let derivedHost = URLCleaner.analyticsDomain(from: outcome.cleaned)
        self.init(
            cleaned: outcome.cleaned,
            original: outcome.input,
            host: derivedHost == "unknown" ? "" : derivedHost,
            removedCount: outcome.telemetry.removedCount,
            title: title,
            date: date
        )
    }

    /// A representative dirty-link clean for live previews in the editor — a
    /// YouTube watch link with two trackers stripped and a sample title.
    public static let sample = TemplateContext(
        cleaned: "https://youtube.com/watch?v=dQw4w9WgXcQ",
        original: "https://youtube.com/watch?v=dQw4w9WgXcQ&utm_source=share&si=AbCdEfGh",
        host: "youtube.com",
        removedCount: 2,
        title: "Big Buck Bunny",
        date: Date(timeIntervalSince1970: 1_750_000_000)
    )
}
