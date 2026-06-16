//
//  TemplateRenderer.swift
//  LinkCleanCore
//
//  Created by Ken Tominaga on 6/14/26.
//

import Foundation

/// Fills a ``LinkTemplate`` from a ``TemplateContext`` — a pure, `nonisolated`
/// substitution that is the whole "template engine" (`copy-as-you-want` §5). One
/// left-to-right pass replaces each recognized `{token}` and leaves every unknown
/// `{x}` literal, so there is no error state and a stray brace is harmless. No
/// dependency, exhaustively unit-tested in the fast macOS lane.
public enum TemplateRenderer {
    /// Renders `template` against `context`. `{date}`/`{time}` are formatted with
    /// `calendar` (injected so tests pin a time zone); `.current` in production.
    public static func render(
        _ template: LinkTemplate,
        _ context: TemplateContext,
        calendar: Calendar = .current
    ) -> String {
        render(format: template.format, context, calendar: calendar)
    }

    /// Renders a raw format string — the path the live editor preview uses before a
    /// draft is saved into a ``LinkTemplate``.
    public static func render(
        format: String,
        _ context: TemplateContext,
        calendar: Calendar = .current
    ) -> String {
        var output = ""
        var rest = Substring(format)

        while let open = rest.firstIndex(of: "{") {
            output += rest[..<open]
            // An opening brace with no closing brace: the remainder is all literal.
            guard let close = rest[rest.index(after: open)...].firstIndex(of: "}") else {
                output += rest[open...]
                return output
            }
            let inner = rest[rest.index(after: open)..<close]
            if let token = TemplateToken(rawValue: String(inner)) {
                output += value(for: token, context, calendar)
            } else {
                // Unknown identifier — keep the braces and text verbatim.
                output += rest[open...close]
            }
            rest = rest[rest.index(after: close)...]
        }

        output += rest
        return output
    }

    // MARK: - Token values

    private static func value(for token: TemplateToken, _ context: TemplateContext, _ calendar: Calendar) -> String {
        switch token {
        case .link: context.cleaned
        case .title: context.title ?? ""
        case .host: context.host
        case .date: formattedDate(context.date, calendar)
        case .time: formattedTime(context.date, calendar)
        case .originalLink: context.original
        case .removedCount: String(context.removedCount)
        case .scheme: URLComponents(string: context.cleaned)?.scheme ?? ""
        // Percent-*encoded* components so reassembling a URL (e.g.
        // `{scheme}://{host}{path}?{query}`) round-trips: `.path`/`.query` decode,
        // turning `%20`→space and `%2B`→`+` and corrupting the link.
        case .path: URLComponents(string: context.cleaned)?.percentEncodedPath ?? ""
        case .query: URLComponents(string: context.cleaned)?.percentEncodedQuery ?? ""
        case .markdown: MarkdownFormatter.markdownLink(title: context.title, url: context.cleaned)
        case .newline: "\n"
        case .tab: "\t"
        }
    }

    // MARK: - Date / time

    // Fixed ISO-ish shapes (`2026-06-14`, `14:32`) built from explicit calendar
    // components, so output is locale-independent and deterministic given a
    // calendar's time zone. A localized/configurable style is a deferred nicety
    // (`copy-as-you-want` §7).

    private static func formattedDate(_ date: Date, _ calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private static func formattedTime(_ date: Date, _ calendar: Calendar) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }
}
