//
//  OnboardingDemoTests.swift
//  LinkCleanKitTests
//

import Testing
import Foundation
@testable import LinkCleanKit

struct OnboardingDemoTests {

    @Test func matchesTheDemoURL() {
        #expect(OnboardingDemo.matches(OnboardingDemo.url))
    }

    @Test func matchesWhenQueryStripped() {
        // After cleaning, the link loses its query but is still the demo.
        let cleaned = URL(string: "https://www.example.com/products/sneakers")!
        #expect(OnboardingDemo.matches(cleaned))
    }

    @Test func matchesViaString() {
        #expect(OnboardingDemo.matches(urlString: OnboardingDemo.url.absoluteString))
    }

    @Test func rejectsDifferentPath() {
        let url = URL(string: "https://www.example.com/products/boots")!
        #expect(OnboardingDemo.matches(url) == false)
    }

    @Test func rejectsDifferentHost() {
        let url = URL(string: "https://shop.example.com/products/sneakers")!
        #expect(OnboardingDemo.matches(url) == false)
    }

    @Test func rejectsRealURL() {
        let url = URL(string: "https://store.nike.com/products/sneakers?utm_source=x")!
        #expect(OnboardingDemo.matches(url) == false)
    }
}
