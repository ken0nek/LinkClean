//
//  CleanResultTests.swift
//  LinkCleanKitTests
//

import Testing
import Foundation
@testable import LinkCleanKit

struct CleanResultTests {

    @Test func countsRemovedParameters() {
        let result = URLCleaner.cleanResult(
            "https://x.com/?utm_source=a&utm_medium=b&id=1",
            removing: ["utm_source", "utm_medium"]
        )

        #expect(result.removedCount == 2)
        #expect(result.changed == true)
        #expect(!result.cleaned.contains("utm_source"))
        #expect(!result.cleaned.contains("utm_medium"))
        #expect(result.cleaned.contains("id=1"))
    }

    @Test func zeroWhenNothingRemoved() {
        let result = URLCleaner.cleanResult("https://x.com/?id=1", removing: ["utm_source"])

        #expect(result.removedCount == 0)
        #expect(result.changed == false)
        #expect(result.cleaned == "https://x.com/?id=1")
    }

    @Test func zeroForNoQuery() {
        let result = URLCleaner.cleanResult("https://x.com/path", removing: ["utm_source"])

        #expect(result.removedCount == 0)
        #expect(result.cleaned == "https://x.com/path")
    }

    @Test func cleanDelegatesToCleanResult() {
        let input = "https://x.com/?fbclid=z&id=1"
        #expect(URLCleaner.clean(input, removing: ["fbclid"]) == URLCleaner.cleanResult(input, removing: ["fbclid"]).cleaned)
    }

    @Test func urlOverloadReturnsCleanedURLAndCount() {
        let result = URLCleaner.cleanResult(
            URL(string: "https://x.com/?fbclid=z&id=1")!,
            removing: ["fbclid"]
        )

        #expect(result.removedCount == 1)
        #expect(result.cleaned.absoluteString == "https://x.com/?id=1")
    }
}
