//
//  URLCleanerTests.swift
//  LinkCleanCoreTests
//
//  Created by Ken Tominaga on 2/2/26.
//

import Testing
import Foundation
@testable import LinkCleanCore

struct URLCleanerTests {

    // MARK: - UTM Parameters

    @Test func removesUtmSource() {
        let result = URLCleaner.clean("https://example.com?utm_source=twitter")
        #expect(result == "https://example.com")
    }

    @Test func removesUtmMedium() {
        let result = URLCleaner.clean("https://example.com?utm_medium=social")
        #expect(result == "https://example.com")
    }

    @Test func removesUtmCampaign() {
        let result = URLCleaner.clean("https://example.com?utm_campaign=spring")
        #expect(result == "https://example.com")
    }

    @Test func removesUtmTerm() {
        let result = URLCleaner.clean("https://example.com?utm_term=keyword")
        #expect(result == "https://example.com")
    }

    @Test func removesUtmContent() {
        let result = URLCleaner.clean("https://example.com?utm_content=banner")
        #expect(result == "https://example.com")
    }

    // MARK: - Custom Removal Sets

    @Test func removesOnlyEnabledParameters() {
        let removing: Set<String> = ["utm_source"]
        let result = URLCleaner.clean(
            "https://example.com?utm_source=twitter&gclid=abc&ref=home",
            removing: removing
        )
        #expect(result == "https://example.com?gclid=abc&ref=home")
    }

    @Test func lowercasesAndRemovesSharedID() {
        // `aid` ships disabled — a generic "article/account id" on unrelated
        // sites — so only the affiliate sharedid matches, case-insensitively.
        let result = URLCleaner.clean("https://example.com?SharedID=abc&aid=123")
        #expect(result == "https://example.com?aid=123")
    }

    // MARK: - Ad Platform Parameters

    @Test func removesFbclid() {
        let result = URLCleaner.clean("https://example.com?fbclid=abc123")
        #expect(result == "https://example.com")
    }

    @Test func removesGclid() {
        let result = URLCleaner.clean("https://example.com?gclid=abc123&gclsrc=aw.ds")
        #expect(result == "https://example.com")
    }

    @Test func removesMsclkid() {
        let result = URLCleaner.clean("https://example.com?msclkid=abc123&s_kwcid=AL!1234")
        #expect(result == "https://example.com")
    }

    // MARK: - Email / Marketing Parameters

    @Test func removesMailchimpParams() {
        let result = URLCleaner.clean("https://example.com?mc_eid=abc&mc_cid=def")
        #expect(result == "https://example.com")
    }

    @Test func removesVeroParams() {
        let result = URLCleaner.clean("https://example.com?vero_id=abc&vero_conv=def")
        #expect(result == "https://example.com")
    }

    @Test func removesOlyParams() {
        let result = URLCleaner.clean("https://example.com?oly_enc_id=abc&oly_anon_id=def")
        #expect(result == "https://example.com")
    }

    @Test func removesHubSpotParams() {
        let result = URLCleaner.clean("https://example.com?__hssc=a&__hstc=b&__hsfp=c&hsCtaTracking=d")
        #expect(result == "https://example.com")
    }

    // MARK: - Analytics Parameters

    @Test func removesGoogleAnalyticsParams() {
        let result = URLCleaner.clean("https://example.com?_ga=abc&_gl=def")
        #expect(result == "https://example.com")
    }

    @Test func removesRefParams() {
        // Bare `ref` ships disabled (functional on GitHub API links and invite
        // codes); the vendor-pattern ref_src/ref_url stay default-on.
        let result = URLCleaner.clean("https://example.com?ref=x&ref_src=twsrc&ref_url=https://t.co")
        #expect(result == "https://example.com?ref=x")
    }

    // MARK: - Social Parameters

    @Test func removesIgshid() {
        let result = URLCleaner.clean("https://example.com?igshid=abc123")
        #expect(result == "https://example.com")
    }

    @Test func removesSocialParams() {
        // Only the vendor-specific share_source_type strips globally; si and
        // feature are host-scoped (YouTube/Spotify) and `app` ships disabled.
        let result = URLCleaner.clean("https://example.com?share_source_type=copy&si=abc&feature=share&app=desktop")
        #expect(result == "https://example.com?si=abc&feature=share&app=desktop")
    }

    // MARK: - Mixed Parameters (keep functional, strip tracking)

    @Test func keepsFunctionalParamsWhileStrippingTracking() {
        let result = URLCleaner.clean("https://example.com/page?q=test&utm_source=twitter&page=2")
        #expect(result == "https://example.com/page?q=test&page=2")
    }

    @Test func keepsSingleFunctionalParam() {
        let result = URLCleaner.clean("https://example.com/search?q=swift&fbclid=abc123&gclid=def456")
        #expect(result == "https://example.com/search?q=swift")
    }

    // MARK: - Edge Cases

    @Test func returnsURLWithNoQueryUnchanged() {
        let result = URLCleaner.clean("https://example.com/page")
        #expect(result == "https://example.com/page")
    }

    @Test func returnsEmptyStringUnchanged() {
        let result = URLCleaner.clean("")
        #expect(result == "")
    }

    @Test func returnsInvalidURLUnchanged() {
        let result = URLCleaner.clean("not a url at all")
        #expect(result == "not a url at all")
    }

    @Test func preservesFragment() {
        let result = URLCleaner.clean("https://example.com/page?utm_source=twitter#section")
        #expect(result == "https://example.com/page#section")
    }

    @Test func preservesFragmentWithFunctionalParams() {
        let result = URLCleaner.clean("https://example.com/page?q=test&utm_source=twitter#section")
        #expect(result == "https://example.com/page?q=test#section")
    }

    // MARK: - Kept-Parameter Encoding Fidelity

    @Test func preservesPercentEncodedPlusInKeptParameter() {
        // `%2B` (a literal `+`) must survive verbatim. If it round-tripped to a
        // bare `+`, a form-decoding server would read it as a space, silently
        // changing the kept value. See URLCleaner's percent-encoded write path.
        let result = URLCleaner.clean("https://example.com/p?utm_source=x&a=1%2B2")
        #expect(result == "https://example.com/p?a=1%2B2")
    }

    @Test func preservesPercentEncodedValueEvenWhenNothingRemoved() {
        // The kept value must not change on a URL we don't actually clean — we
        // still rewrite the query items, so re-encoding would corrupt a value we
        // had no reason to touch.
        let result = URLCleaner.clean("https://example.com/p?a=1%2B2")
        #expect(result == "https://example.com/p?a=1%2B2")
    }

    @Test func preservesPercentEncodedBase64TokenInKeptParameter() {
        // base64 values carry `+` and `/` (as `%2B`/`%2F`); both must survive so
        // the token isn't mangled.
        let result = URLCleaner.clean("https://example.com/p?utm_source=x&token=ab%2Bcd%2F")
        #expect(result == "https://example.com/p?token=ab%2Bcd%2F")
    }

    @Test func cleansTrackingParametersInsideFragment() {
        // E2: tracking params embedded in the fragment (`#utm_source=…`) are now
        // stripped alongside the query in one pass (full coverage in
        // FragmentCleaningTests). A bare anchor would still pass through untouched.
        let result = URLCleaner.clean("https://example.com/p?a=1#utm_source=x&utm_medium=y")
        #expect(result == "https://example.com/p?a=1")
    }

    @Test func caseInsensitiveMatching() {
        let result = URLCleaner.clean("https://example.com?UTM_SOURCE=twitter&UTM_MEDIUM=social")
        #expect(result == "https://example.com")
    }

    @Test func returnsURLWithEmptyQueryUnchanged() {
        let result = URLCleaner.clean("https://example.com/page?")
        #expect(result == "https://example.com/page?")
    }

    @Test func handlesURLWithPathOnly() {
        let result = URLCleaner.clean("https://example.com/a/b/c")
        #expect(result == "https://example.com/a/b/c")
    }

    // MARK: - URL Validation

    @Test func validatesHttpsURL() {
        #expect(URLCleaner.isValidURL("https://example.com"))
    }

    @Test func validatesHttpURL() {
        #expect(URLCleaner.isValidURL("http://example.com"))
    }

    @Test func rejectsEmptyURL() {
        #expect(!URLCleaner.isValidURL("   "))
    }

    @Test func rejectsInvalidURL() {
        #expect(!URLCleaner.isValidURL("not a url"))
    }

    @Test func rejectsMissingScheme() {
        #expect(!URLCleaner.isValidURL("example.com"))
    }

    // MARK: - URL Overload

    @Test func cleanURLOverload() {
        let url = URL(string: "https://example.com?utm_source=twitter&q=test")!
        let result = URLCleaner.clean(url)
        #expect(result == URL(string: "https://example.com?q=test")!)
    }

    // MARK: - Real-World URLs

    @Test func realWorldYouTubeURL() {
        let result = URLCleaner.clean("https://www.youtube.com/watch?v=dQw4w9WgXcQ&si=abc123&feature=share")
        #expect(result == "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    }

    @Test func realWorldXURL() {
        let result = URLCleaner.clean("https://x.com/user/status/123456789?s=46&t=abc123")
        #expect(result == "https://x.com/user/status/123456789")
    }

    @Test func realWorldGoogleMapsURL() {
        let result = URLCleaner.clean("https://maps.app.goo.gl/5FURCEXrGa9CEEMHA?g_st=ic")
        #expect(result == "https://maps.app.goo.gl/5FURCEXrGa9CEEMHA")
    }

    @Test func realWorldLinkedInURL() {
        let result = URLCleaner.clean("https://www.linkedin.com/posts/joseortezjr_two-weeks-in-at-cardless-and-i-couldnt-share-7466134834122334208-Ry01/?utm_source=social_share_send&utm_medium=ios_app&rcm=ACoAABQZm6cBBc5sxUju5I_QnhL4dRrMz48tMmA&utm_campaign=copy_link")
        #expect(result == "https://www.linkedin.com/posts/joseortezjr_two-weeks-in-at-cardless-and-i-couldnt-share-7466134834122334208-Ry01/")
    }

    @Test func realWorldAmazonStyleURL() {
        // Bare `ref` survives by default — generic enough to be functional on
        // other sites; opting in remains one toggle (or pill tap) away.
        let result = URLCleaner.clean("https://www.example.com/dp/B08N5WRWNW?tag=mystore&utm_source=google&gclid=abc&ref=sr_1_1")
        #expect(result == "https://www.example.com/dp/B08N5WRWNW?tag=mystore&ref=sr_1_1")
    }

    @Test func firstWebURLPullsTheLinkOutOfProse() {
        // A "label + link" payload (QR codes, shared captions) — the detector finds
        // the embedded web URL where `URL(string:)` would mangle the whole string.
        #expect(URLCleaner.firstWebURL(in: "see https://x.com/a?utm_source=n now")?.absoluteString
            == "https://x.com/a?utm_source=n")
        #expect(URLCleaner.firstWebURL(in: "no link in this text") == nil)
    }
}
