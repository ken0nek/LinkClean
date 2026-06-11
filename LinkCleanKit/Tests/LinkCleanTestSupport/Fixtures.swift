//
//  Fixtures.swift
//  LinkCleanTestSupport
//

import Foundation

/// Shared sample links for the package test suites, so the same representative
/// URLs don't get re-typed (and drift) across Core/Data/ExtensionUI tests.
public enum Fixtures {
    /// A YouTube watch link carrying a host-scoped `si` tracker plus a generic
    /// `feature` — the canonical "clean removes trackers, keeps `v`" case.
    public static let youTubeTracked = "https://www.youtube.com/watch?v=dQw4w9WgXcQ&si=abc123&feature=share"
    public static let youTubeClean = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

    /// A URL with mixed tracking + functional params (utm_source strip, q/page keep).
    public static let mixedTracked = "https://example.com/page?q=test&utm_source=twitter&page=2"
    public static let mixedClean = "https://example.com/page?q=test&page=2"

    /// A plain link with no query — cleaning is a no-op.
    public static let plain = "https://example.com/path"
}
