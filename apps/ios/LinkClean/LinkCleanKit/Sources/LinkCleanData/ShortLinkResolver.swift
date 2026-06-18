//
//  ShortLinkResolver.swift
//  LinkCleanData
//
//  Created by Ken Tominaga on 6/17/26.
//

import Foundation
import OSLog
import LinkCleanCore

/// Resolves a short link (`t.co`, `bit.ly`, …) to its final destination over the
/// network — the one capability the otherwise-offline engine cannot perform
/// locally, because a shortener's destination lives server-side behind an opaque
/// code. Surfaces that opt into the network inject a live resolver; surfaces that
/// stay offline (previews, and — outside DEBUG — the extensions and App Intents)
/// inject `nil`, and short links simply pass through unexpanded.
public protocol ShortLinkResolving: Sendable {
    /// The link's final destination, or `nil` on any failure — timeout, network
    /// error, a non-web result, or too many redirects. Fail-soft by contract: the
    /// caller cleans the original link when this returns `nil`, so expansion can
    /// never make a clean fail.
    ///
    /// `nonisolated`: the resolve runs off the main actor (it is awaited by the
    /// `nonisolated` ``DefaultCleaningService`` and by the App Intents, which run
    /// off the main thread) — network work must never block the main actor.
    nonisolated func resolve(_ url: URL) async -> URL?
}

/// A ``ShortLinkResolving`` backed by `URLSession`: it follows the shortener's
/// redirect chain to the destination and hands the final URL back for the normal
/// offline clean.
///
/// Privacy — this is the app's only network egress, so every choice is deliberate:
/// an **ephemeral** session (no cookie jar, no on-disk cache, nothing about the
/// request persisted), the link is **never logged**, a short timeout bounds how
/// long the app talks to the shortener, and only a *web* destination is returned
/// (never a custom-scheme or non-HTTP redirect target).
public nonisolated struct URLSessionShortLinkResolver: ShortLinkResolving {
    private let timeout: TimeInterval

    /// - Parameter timeout: per-request ceiling in seconds. 5 s keeps the app
    ///   responsive — Home shows a spinner during the await — while tolerating a
    ///   slow shortener.
    public init(timeout: TimeInterval = 5) {
        self.timeout = timeout
    }

    public func resolve(_ url: URL) async -> URL? {
        // One ephemeral session (no cookie jar, no cache) reused for both methods, so
        // a HEAD-hostile shortener doesn't build two sessions. `timeoutIntervalForRequest`
        // is only an inactivity timer that resets each hop; `timeoutIntervalForResource`
        // is the hard wall-clock bound per request (a HEAD→GET fallback can take up to 2×).
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration)
        defer { session.finishTasksAndInvalidate() }

        // HEAD follows the redirects without downloading the destination body; some
        // servers answer HEAD with 405, so fall back to GET on the same session.
        if let resolved = await resolvedDestination(of: url, method: "HEAD", on: session) {
            return resolved
        }
        return await resolvedDestination(of: url, method: "GET", on: session)
    }

    private func resolvedDestination(of url: URL, method: String, on session: URLSession) async -> URL? {
        var request = URLRequest(url: url)
        request.httpMethod = method
        do {
            let (_, response) = try await session.data(for: request)
            // Trust the result only on a 2xx final response — URLSession has already
            // followed (and bounded, via `NSURLErrorHTTPTooManyRedirects`) the redirect
            // chain. A bare 405 (HEAD rejected) or a 4xx/5xx error page leaves
            // `response.url` at the shortener / an error page, not the destination, so
            // anything but success returns nil: a failed HEAD then falls through to the
            // GET retry, and a failed GET fails soft (the caller cleans the original).
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let destination = response.url,
                  URLCleaner.isWebURL(destination)
            else {
                return nil
            }
            return destination
        } catch {
            // Never log the link itself (privacy); the method + failure is enough.
            Log.app.debug("short-link resolve failed (\(method, privacy: .public))")
            return nil
        }
    }
}

/// The short-link resolver for the **App Intents** — Shortcuts / Siri, the Control
/// Center control, and the Home-screen widget button. Always `nil` in Release: the
/// widget / Control-Center button runs ``CleanClipboardIntent`` in a time-budgeted
/// interactive-widget process where a multi-second network resolve can't reliably
/// complete, so intents stay offline in production. In DEBUG it honors the developer
/// flag (``SettingsStore/expandShortLinksOutOfAppDebugEnabled``) so the path can be
/// exercised on-device.
///
/// The **action extension is not gated this way** — it is a full foreground process
/// that can complete the resolve, so it wires a live ``URLSessionShortLinkResolver``
/// directly (see `ActionHostViewController`), gated only by the user's opt-in.
public enum OutOfAppShortLinkExpansion {
    public nonisolated static func resolver(settings: SettingsStore = SettingsStore()) -> (any ShortLinkResolving)? {
        #if DEBUG
        return settings.expandShortLinksOutOfAppDebugEnabled ? URLSessionShortLinkResolver() : nil
        #else
        return nil
        #endif
    }
}
