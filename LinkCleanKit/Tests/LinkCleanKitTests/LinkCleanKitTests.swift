//
//  LinkCleanKitTests.swift
//  LinkCleanKitTests
//
//  Created by Ken Tominaga on 2/2/26.
//

import Testing
import Foundation
@testable import LinkCleanKit

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
        let result = URLCleaner.clean("https://example.com?SharedID=abc&aid=123")
        #expect(result == "https://example.com")
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
        let result = URLCleaner.clean("https://example.com?ref=x&ref_src=twsrc&ref_url=https://t.co")
        #expect(result == "https://example.com")
    }

    // MARK: - Social Parameters

    @Test func removesIgshid() {
        let result = URLCleaner.clean("https://example.com?igshid=abc123")
        #expect(result == "https://example.com")
    }

    @Test func removesSocialParams() {
        let result = URLCleaner.clean("https://example.com?share_source_type=copy&si=abc&feature=share&app=desktop")
        #expect(result == "https://example.com")
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

    @Test func realWorldAmazonStyleURL() {
        let result = URLCleaner.clean("https://www.example.com/dp/B08N5WRWNW?tag=mystore&utm_source=google&gclid=abc&ref=sr_1_1")
        #expect(result == "https://www.example.com/dp/B08N5WRWNW?tag=mystore")
    }
}

struct TrackingParameterStoreTests {

    @Test func normalizesAndEnablesCustomParameters() {
        let suiteName = "LinkCleanKitTests.custom.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }

        let store = TrackingParameterStore(suiteName: suiteName)
        store.addCustomParameter("  UTM_Source  ")

        #expect(store.customParameters() == ["utm_source"])
        #expect(store.enabledParameters().contains("utm_source"))
    }

    @Test func removesCustomParameters() {
        let suiteName = "LinkCleanKitTests.custom.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }

        let store = TrackingParameterStore(suiteName: suiteName)
        store.addCustomParameter("custom_param")
        store.removeCustomParameter("custom_param")

        #expect(store.customParameters().isEmpty)
        #expect(!store.enabledParameters().contains("custom_param"))
    }
}
