//
//  RedirectUnwrappingTests.swift
//  LinkCleanCoreTests
//
//  Created by Ken Tominaga on 6/12/26.
//

import Testing
import Foundation
@testable import LinkCleanCore

// MARK: - Catalog matching

struct RedirectWrapperCatalogTests {

    @Test func resolvesEachWrappersDestinationParameter() {
        #expect(RedirectWrapperCatalog.wrapper(forHost: "www.google.com", path: "/url")?.destinationParameter == "q")
        #expect(RedirectWrapperCatalog.wrapper(forHost: "www.youtube.com", path: "/redirect")?.destinationParameter == "q")
        #expect(RedirectWrapperCatalog.wrapper(forHost: "l.facebook.com", path: "/l.php")?.destinationParameter == "u")
        #expect(RedirectWrapperCatalog.wrapper(forHost: "l.instagram.com", path: "/")?.destinationParameter == "u")
        #expect(RedirectWrapperCatalog.wrapper(forHost: "nam12.safelinks.protection.outlook.com", path: "/")?.destinationParameter == "url")
        #expect(RedirectWrapperCatalog.wrapper(forHost: "steamcommunity.com", path: "/linkfilter/")?.destinationParameter == "url")
        #expect(RedirectWrapperCatalog.wrapper(forHost: "duckduckgo.com", path: "/l/")?.destinationParameter == "uddg")
        #expect(RedirectWrapperCatalog.wrapper(forHost: "vk.com", path: "/away.php")?.destinationParameter == "to")
    }

    @Test func pathScopeDistinguishesRedirectFromSearch() {
        // The load-bearing guard: same host, same parameter name, opposite
        // meaning. /url is a redirect; /search is a query for those characters.
        #expect(RedirectWrapperCatalog.wrapper(forHost: "www.google.com", path: "/url")?.destinationParameter == "q")
        #expect(RedirectWrapperCatalog.wrapper(forHost: "www.google.com", path: "/search") == nil)
    }

    @Test func matchesBareHostAndIsCaseInsensitive() {
        #expect(RedirectWrapperCatalog.wrapper(forHost: "google.com", path: "/url")?.destinationParameter == "q")
        #expect(RedirectWrapperCatalog.wrapper(forHost: "GOOGLE.COM", path: "/url")?.destinationParameter == "q")
        // A trailing root dot is normalized away (matches `ruleHost`).
        #expect(RedirectWrapperCatalog.wrapper(forHost: "www.google.com.", path: "/url")?.destinationParameter == "q")
    }

    @Test func dedicatedShimHostsMatchAnyPath() {
        #expect(RedirectWrapperCatalog.wrapper(forHost: "l.facebook.com", path: "/anything")?.destinationParameter == "u")
        #expect(RedirectWrapperCatalog.wrapper(forHost: "l.instagram.com", path: "")?.destinationParameter == "u")
    }

    @Test func toleratesTrailingSlashOnExactPaths() {
        #expect(RedirectWrapperCatalog.wrapper(forHost: "duckduckgo.com", path: "/l")?.destinationParameter == "uddg")
        #expect(RedirectWrapperCatalog.wrapper(forHost: "duckduckgo.com", path: "/l/")?.destinationParameter == "uddg")
    }

    @Test func ignoresNonWrapperHosts() {
        #expect(RedirectWrapperCatalog.wrapper(forHost: "example.com", path: "/url") == nil)
        // A look-alike host must not match by accident.
        #expect(RedirectWrapperCatalog.wrapper(forHost: "notgoogle.com", path: "/url") == nil)
        #expect(RedirectWrapperCatalog.wrapper(forHost: nil, path: "/url") == nil)
    }

    @Test func catalogInvariants() {
        #expect(!RedirectWrapperCatalog.wrappers.isEmpty)
        #expect(RedirectWrapperCatalog.wrappers.allSatisfy { $0.hostSuffix == $0.hostSuffix.lowercased() })
        #expect(RedirectWrapperCatalog.wrappers.allSatisfy { $0.destinationParameter == $0.destinationParameter.lowercased() })
    }
}

// MARK: - Unwrapping

struct URLUnwrapTests {

    @Test func unwrapsEveryWrapperToItsDestination() {
        let dest = "https://example.com/"
        let cases: [String] = [
            "https://www.google.com/url?q=https%3A%2F%2Fexample.com%2F&sa=D&usg=AOvVaw",
            "https://www.youtube.com/redirect?q=https%3A%2F%2Fexample.com%2F&v=abc",
            "https://l.facebook.com/l.php?u=https%3A%2F%2Fexample.com%2F&h=AT123",
            "https://l.instagram.com/?u=https%3A%2F%2Fexample.com%2F&e=ABC",
            "https://nam12.safelinks.protection.outlook.com/?url=https%3A%2F%2Fexample.com%2F&data=05",
            "https://steamcommunity.com/linkfilter/?url=https%3A%2F%2Fexample.com%2F",
            "https://duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.com%2F&rut=abc",
            "https://vk.com/away.php?to=https%3A%2F%2Fexample.com%2F&cc_key=",
        ]
        for wrapped in cases {
            #expect(URLCleaner.unwrap(wrapped).destination == dest, "failed to unwrap \(wrapped)")
        }
    }

    @Test func recordsThePeeledWrapperHost() {
        let result = URLCleaner.unwrap("https://www.google.com/url?q=https%3A%2F%2Fexample.com%2F&sa=D")
        #expect(result.destination == "https://example.com/")
        #expect(result.wrappers == ["google.com"])
    }

    @Test func decodesTrackersHiddenInsideTheWrappedDestination() {
        // The whole point: the destination's own trackers are percent-encoded
        // inside q=, invisible to a normal clean until the link is unwrapped.
        let wrapped = "https://www.google.com/url?q=https%3A%2F%2Fshop.example.com%2Fsneakers%3Futm_source%3Dnewsletter%26fbclid%3Dabc&sa=D"
        #expect(URLCleaner.unwrap(wrapped).destination == "https://shop.example.com/sneakers?utm_source=newsletter&fbclid=abc")
    }

    @Test func peelsNestedWrappersAndRecordsTheChain() throws {
        let inner = "https://example.com/"
        let facebook = try "https://l.facebook.com/l.php?u=" + #require(inner.addingPercentEncoding(withAllowedCharacters: .alphanumerics))
        let google = try "https://www.google.com/url?q=" + #require(facebook.addingPercentEncoding(withAllowedCharacters: .alphanumerics))

        let result = URLCleaner.unwrap(google)
        #expect(result.destination == inner)
        #expect(result.wrappers == ["google.com", "l.facebook.com"])
    }

    @Test func stopsAtMaxDepth() throws {
        let inner = "https://example.com/"
        let facebook = try "https://l.facebook.com/l.php?u=" + #require(inner.addingPercentEncoding(withAllowedCharacters: .alphanumerics))
        let google = try "https://www.google.com/url?q=" + #require(facebook.addingPercentEncoding(withAllowedCharacters: .alphanumerics))

        // One peel only: stops on the intermediate wrapper, doesn't reach inner.
        let result = URLCleaner.unwrap(google, maxDepth: 1)
        #expect(result.destination == facebook)
        #expect(result.wrappers == ["google.com"])
    }

    @Test func leavesLinkUntouchedWhenExtractedValueIsNotAWebURL() {
        // q is a relative path, not an absolute web URL — don't unwrap garbage.
        let wrapped = "https://www.google.com/url?q=%2Fsearch%3Fx%3D1"
        let result = URLCleaner.unwrap(wrapped)
        #expect(result.destination == wrapped)
        #expect(result.wrappers.isEmpty)
    }

    @Test func doesNotUnwrapUnknownHostsCarryingAUrlParameter() {
        // Allowlist proof: a random site with a ?url= that happens to hold a URL
        // is not a redirect and must be left alone.
        let wrapped = "https://example.com/redirect?url=https%3A%2F%2Fevil.com%2F"
        let result = URLCleaner.unwrap(wrapped)
        #expect(result.destination == wrapped)
        #expect(result.wrappers.isEmpty)
    }

    @Test func doesNotUnwrapAGoogleSearchForAURL() {
        // Path-scope proof at the unwrap level: /search?q=<a url> is a search,
        // not a redirect.
        let wrapped = "https://www.google.com/search?q=https%3A%2F%2Fexample.com%2F"
        let result = URLCleaner.unwrap(wrapped)
        #expect(result.destination == wrapped)
        #expect(result.wrappers.isEmpty)
    }

    @Test func isANoOpOnOrdinaryAndShortLinks() {
        // Ordinary link.
        #expect(URLCleaner.unwrap("https://example.com/article?id=5").destination == "https://example.com/article?id=5")
        // Short links are not wrappers — destination is server-side, not in the
        // string — so they pass through untouched (handled by network expansion).
        #expect(URLCleaner.unwrap("https://t.co/aBc123").destination == "https://t.co/aBc123")
        #expect(URLCleaner.unwrap("https://bit.ly/3xYz").destination == "https://bit.ly/3xYz")
        // Wrapper host but no destination parameter present.
        #expect(URLCleaner.unwrap("https://www.google.com/url").destination == "https://www.google.com/url")
    }

    // MARK: - Composition with cleaning

    @Test func unwrapThenCleanStripsTheRevealedTrackers() {
        let wrapped = "https://www.google.com/url?q=https%3A%2F%2Fshop.example.com%2Fsneakers%3Futm_source%3Dnewsletter%26fbclid%3Dabc&sa=D"
        let cleaned = URLCleaner.clean(URLCleaner.unwrap(wrapped).destination)
        #expect(cleaned == "https://shop.example.com/sneakers")
    }

    @Test func unwrapThenCleanResolvesRulesForTheDestinationHost() {
        // Destination is YouTube: t= (timestamp) survives, si= (share token) is
        // stripped — proving rules key off the unwrapped host, not google.com.
        let wrapped = "https://www.google.com/url?q=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3Dx%26t%3D120s%26si%3DAbC"
        let cleaned = URLCleaner.clean(URLCleaner.unwrap(wrapped).destination)
        #expect(cleaned == "https://www.youtube.com/watch?v=x&t=120s")
    }
}
