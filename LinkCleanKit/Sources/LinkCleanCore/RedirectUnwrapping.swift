//
//  RedirectUnwrapping.swift
//  LinkCleanCore
//
//  Created by Ken Tominaga on 6/12/26.
//

import Foundation

/// The path scope a ``RedirectWrapper`` requires before its destination
/// parameter is trusted.
public enum WrapperPath: Sendable, Equatable {
    /// Any path on the host — the host alone is a unique enough discriminator
    /// (a dedicated link-shim host like `l.facebook.com` or
    /// `*.safelinks.protection.outlook.com` serves nothing else).
    case any
    /// The request path must equal this value (trailing slashes and case
    /// ignored). Mandatory on multi-purpose hosts: it is what distinguishes
    /// `google.com/url?q=` (a redirect) from `google.com/search?q=` (a search
    /// query that merely shares the parameter name).
    case exact(String)
}

/// One known redirect wrapper: a host that carries its real destination URL
/// percent-encoded inside a named query parameter, so it can be extracted
/// **offline** — the destination is already in the string, no network.
///
/// Short links (`t.co`, `bit.ly`, `lnkd.in`) are deliberately **not** wrappers:
/// their destination lives server-side behind an opaque code and can only be
/// resolved with a network round-trip — a separate, opt-in feature, never this
/// offline path.
public struct RedirectWrapper: Sendable, Equatable {
    /// Host suffix, matched exactly as ``TrackingParameterDefinition/appliesTo(host:)``
    /// (`host == suffix || host.hasSuffix("." + suffix)`), so `www.google.com`
    /// matches `google.com` and `nam12.safelinks…` matches the bare suffix.
    public let hostSuffix: String
    /// The path scope that must match for ``destinationParameter`` to be trusted.
    public let path: WrapperPath
    /// The query-parameter name holding the percent-encoded destination URL.
    public let destinationParameter: String

    public init(hostSuffix: String, path: WrapperPath, destinationParameter: String) {
        self.hostSuffix = hostSuffix
        self.path = path
        self.destinationParameter = destinationParameter
    }

    /// Whether this wrapper governs `host` (already normalized: lowercased,
    /// trailing root dot stripped) at request `path`.
    func governs(host: String, path: String) -> Bool {
        guard host == hostSuffix || host.hasSuffix("." + hostSuffix) else { return false }
        switch self.path {
        case .any:
            return true
        case .exact(let expected):
            return Self.canonicalPath(path) == Self.canonicalPath(expected)
        }
    }

    /// Lowercased with any trailing slashes trimmed, so `/l/` and `/l` (and
    /// `/linkfilter/` vs `/linkfilter`) resolve to the same wrapper. Empty → `/`.
    private static func canonicalPath(_ path: String) -> String {
        var path = path.lowercased()
        while path.count > 1, path.hasSuffix("/") { path.removeLast() }
        return path.isEmpty ? "/" : path
    }
}

/// The bundled allowlist of offline-unwrappable redirect wrappers.
///
/// Allowlist, not heuristic, for two reasons the type makes structural: countless
/// legitimate URLs carry a `url=` / `u=` / `q=` parameter that is *not* a redirect
/// (OAuth returns, API callbacks, search queries), and the same host can mean
/// different things per path (`google.com/url` vs `google.com/search`). Only a
/// curated host + path + parameter triple is trusted.
public enum RedirectWrapperCatalog {

    /// Each entry's parameter and path scope is verified against a live example.
    /// Dedicated shim hosts use ``WrapperPath/any`` (the host is the
    /// discriminator); multi-purpose hosts pin the exact redirect path.
    public static let wrappers: [RedirectWrapper] = [
        RedirectWrapper(hostSuffix: "google.com", path: .exact("/url"), destinationParameter: "q"),
        RedirectWrapper(hostSuffix: "youtube.com", path: .exact("/redirect"), destinationParameter: "q"),
        RedirectWrapper(hostSuffix: "l.facebook.com", path: .any, destinationParameter: "u"),
        RedirectWrapper(hostSuffix: "l.instagram.com", path: .any, destinationParameter: "u"),
        RedirectWrapper(hostSuffix: "safelinks.protection.outlook.com", path: .any, destinationParameter: "url"),
        RedirectWrapper(hostSuffix: "steamcommunity.com", path: .exact("/linkfilter/"), destinationParameter: "url"),
        RedirectWrapper(hostSuffix: "duckduckgo.com", path: .exact("/l/"), destinationParameter: "uddg"),
        RedirectWrapper(hostSuffix: "vk.com", path: .exact("/away.php"), destinationParameter: "to"),
    ]

    /// The wrapper governing `host` + `path`, or `nil` when none does. First
    /// match wins; the list has no overlapping hosts.
    public static func wrapper(forHost host: String?, path: String) -> RedirectWrapper? {
        guard let host = TrackingParameterCatalog.normalize(host: host) else { return nil }
        return wrappers.first { $0.governs(host: host, path: path) }
    }
}

/// The result of ``URLCleaner/unwrap(_:maxDepth:)``.
public struct UnwrapResult: Sendable, Equatable {
    /// The innermost destination after peeling every known wrapper, or the
    /// original input when nothing matched.
    public let destination: String
    /// The wrapper host suffixes peeled, outermost first — empty when nothing
    /// was unwrapped. Canonical public wrapper domains only (e.g. `google.com`),
    /// safe for telemetry; the destination URL itself is never here.
    public let wrappers: [String]

    public init(destination: String, wrappers: [String]) {
        self.destination = destination
        self.wrappers = wrappers
    }
}

extension URLCleaner {
    /// Peels known redirect wrappers (`google.com/url?q=…`,
    /// `l.facebook.com/l.php?u=…`, Outlook safelinks, …) down to the real
    /// destination they carry percent-encoded in a query parameter — entirely
    /// offline. Recurses for a wrapper wrapping another wrapper, capped at
    /// `maxDepth`.
    ///
    /// Returns the input unchanged (with empty ``UnwrapResult/wrappers``) when no
    /// wrapper matches or the extracted value is not a valid web URL — so it is a
    /// safe no-op on ordinary links and on short links (`t.co`, `bit.ly`), whose
    /// destination is not in the string. The host of the *returned* destination
    /// is what callers must resolve removal rules against, not the input's.
    public static func unwrap(_ input: String, maxDepth: Int = 5) -> UnwrapResult {
        var current = input
        var peeled: [String] = []

        while peeled.count < maxDepth {
            guard let components = URLComponents(string: current),
                  let wrapper = RedirectWrapperCatalog.wrapper(forHost: components.host, path: components.path),
                  let item = components.queryItems?.first(where: { $0.name == wrapper.destinationParameter }),
                  let destination = item.value,
                  isValidURL(destination)
            else {
                break
            }
            peeled.append(wrapper.hostSuffix)
            current = destination
        }

        return UnwrapResult(destination: current, wrappers: peeled)
    }
}
