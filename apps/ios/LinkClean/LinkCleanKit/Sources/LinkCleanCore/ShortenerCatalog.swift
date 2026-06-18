//
//  ShortenerCatalog.swift
//  LinkCleanCore
//
//  Created by Ken Tominaga on 6/17/26.
//

import Foundation

/// The bundled set of URL-shortener hosts whose destination lives **server-side**
/// behind an opaque code — `t.co`, `bit.ly`, `lnkd.in` — and so can only be reached
/// with a network round-trip (E4 short-link expansion), never the offline
/// ``RedirectWrapperCatalog`` path.
///
/// Pure data, like ``RedirectWrapperCatalog``: the host set lives here in
/// `LinkCleanCore`, but the network resolver that *uses* it does not — Core has no
/// network (see `ShortLinkResolving` in `LinkCleanData`). Membership is
/// deliberately **disjoint** from the offline wrapper hosts: a host that can be
/// unwrapped offline must never also be treated as a network shortener, or a link
/// would be both expanded *and* unwrapped. `ShortenerCatalogTests` asserts the
/// disjointness so a future addition to either set can't silently overlap.
public enum ShortenerCatalog {

    /// Known link-shortener hosts. Each hides its destination behind a redirect the
    /// server issues, so expanding one is opt-in and network-touching — the app's
    /// only egress.
    public static let hosts: Set<String> = [
        "t.co",          // X / Twitter
        "bit.ly",        // Bitly
        "tinyurl.com",
        "goo.gl",        // legacy Google (still resolves)
        "ow.ly",         // Hootsuite
        "is.gd",
        "buff.ly",       // Buffer
        "t.ly",
        "rebrand.ly",
        "cutt.ly",
        "shorturl.at",
        "lnkd.in",       // LinkedIn
        // Branded / vanity shorteners — a publisher-owned domain that still only
        // serves redirects (typically Bitly-powered). This category is open-ended
        // (most large publishers have one); add the common ones as they appear.
        "nyti.ms",       // New York Times
        "wapo.st",       // Washington Post
        "reut.rs",       // Reuters
        "apple.co",      // Apple
        "amzn.to",       // Amazon
        "spoti.fi",      // Spotify
        "fb.me",         // Facebook
    ]

    /// Whether `host` is a known shortener. Normalizes like the wrapper catalog
    /// (lowercased, trailing root dot stripped) and additionally strips a leading
    /// `www.`, so `www.bit.ly` matches `bit.ly`. Exact match — a shortener host is a
    /// precise discriminator, not a suffix to match against.
    public static func isShortener(host: String?) -> Bool {
        guard var host = TrackingParameterCatalog.normalize(host: host) else { return false }
        if host.hasPrefix("www."), host.count > 4 {
            host.removeFirst(4)
        }
        return hosts.contains(host)
    }
}
