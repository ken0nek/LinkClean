//
//  ShortenerCatalogTests.swift
//  LinkCleanCoreTests
//
//  Created by Ken Tominaga on 6/17/26.
//

import Testing
@testable import LinkCleanCore

struct ShortenerCatalogTests {

    @Test func recognizesKnownShorteners() {
        #expect(ShortenerCatalog.isShortener(host: "bit.ly"))
        #expect(ShortenerCatalog.isShortener(host: "t.co"))
        #expect(ShortenerCatalog.isShortener(host: "lnkd.in"))
        #expect(ShortenerCatalog.isShortener(host: "tinyurl.com"))
    }

    /// Branded / vanity shorteners (publisher-owned, redirect-only) — the
    /// `nyti.ms`-class hosts users routinely paste.
    @Test func recognizesBrandedShorteners() {
        #expect(ShortenerCatalog.isShortener(host: "nyti.ms"))
        #expect(ShortenerCatalog.isShortener(host: "amzn.to"))
        #expect(ShortenerCatalog.isShortener(host: "apple.co"))
    }

    @Test func normalizesHostBeforeMatching() {
        #expect(ShortenerCatalog.isShortener(host: "BIT.LY"))     // case-insensitive
        #expect(ShortenerCatalog.isShortener(host: "www.bit.ly")) // www. stripped
        #expect(ShortenerCatalog.isShortener(host: "bit.ly."))    // trailing root dot stripped
    }

    @Test func rejectsNonShorteners() {
        #expect(!ShortenerCatalog.isShortener(host: "example.com"))
        #expect(!ShortenerCatalog.isShortener(host: "youtube.com")) // an E1 wrapper host, not a shortener
        #expect(!ShortenerCatalog.isShortener(host: nil))
        #expect(!ShortenerCatalog.isShortener(host: ""))
        #expect(!ShortenerCatalog.isShortener(host: "notbit.ly"))   // exact match, not a suffix
    }

    /// A host that can be unwrapped offline (E1) must never also be a network
    /// shortener (E4), or a link would be both expanded and unwrapped. The two
    /// catalogs must stay disjoint as either one grows.
    @Test func isDisjointFromOfflineWrapperHosts() {
        let wrapperHosts = Set(RedirectWrapperCatalog.wrappers.map(\.hostSuffix))
        #expect(ShortenerCatalog.hosts.isDisjoint(with: wrapperHosts))
    }
}
