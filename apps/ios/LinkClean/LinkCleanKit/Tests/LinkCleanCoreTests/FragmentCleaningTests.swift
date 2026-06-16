//
//  FragmentCleaningTests.swift
//  LinkCleanCoreTests
//
//  Created by Ken Tominaga on 6/12/26.
//

import Testing
import Foundation
@testable import LinkCleanCore

// MARK: - Scroll-to-text directive (#:~:text=)

struct FragmentTextDirectiveTests {

    @Test func stripsAStandaloneTextDirective() {
        #expect(URLCleaner.clean("https://example.com/page#:~:text=hello%20world") == "https://example.com/page")
    }

    @Test func keepsTheAnchorButDropsTheDirective() {
        #expect(URLCleaner.clean("https://example.com/page#section:~:text=hello") == "https://example.com/page#section")
    }

    @Test func aDirectiveRemovalCountsAsChangedButNotAsAParam() {
        let outcome = URLCleaner.outcome(for: "https://example.com/page#:~:text=hello", removing: [])
        #expect(outcome.cleaned == "https://example.com/page")
        #expect(outcome.telemetry.changed == true)
        #expect(outcome.telemetry.removedCount == 0)        // a directive is not a tracking param
        #expect(outcome.display.removedNames.isEmpty)
    }

    @Test func leavesPlainAnchorsAndRoutesAlone() {
        #expect(URLCleaner.clean("https://example.com/page#section") == "https://example.com/page#section")
        // SPA route — load-bearing, must survive verbatim.
        #expect(URLCleaner.clean("https://example.com/app#/dashboard/settings") == "https://example.com/app#/dashboard/settings")
    }

    @Test func keepsTheDirectiveWhenStrippingIsDisabled() {
        // Toggle off: the directive is preserved (untouched link round-trips)…
        let kept = URLCleaner.outcome(for: "https://example.com/page#:~:text=hello", removing: [], stripTextFragment: false)
        #expect(kept.cleaned == "https://example.com/page#:~:text=hello")
        #expect(kept.telemetry.changed == false)

        // …but fragment tracking params are still removed, directive and all.
        let mixed = URLCleaner.outcome(for: "https://example.com/page#utm_source=a:~:text=hi", removing: ["utm_source"], stripTextFragment: false)
        #expect(mixed.cleaned == "https://example.com/page#:~:text=hi")
        #expect(mixed.telemetry.removedCount == 1)
    }
}

// MARK: - Tracking params in the fragment

struct FragmentParameterTests {

    @Test func stripsTrackingParamsFromTheFragment() {
        #expect(URLCleaner.clean("https://example.com/page#utm_source=newsletter") == "https://example.com/page")
        #expect(URLCleaner.clean("https://example.com/page#utm_source=a&utm_medium=b") == "https://example.com/page")
    }

    @Test func handlesAQuestionMarkPrefixedFragment() {
        #expect(URLCleaner.clean("https://example.com/page#?utm_source=a") == "https://example.com/page")
    }

    @Test func keepsNonTrackingFragmentParams() {
        // utm_source removed, the functional id kept.
        #expect(URLCleaner.clean("https://example.com/page#utm_source=a&id=42") == "https://example.com/page#id=42")
        // A wholly functional fragment param list is untouched (gid is not a tracker).
        #expect(URLCleaner.clean("https://docs.example.com/sheet#gid=0") == "https://docs.example.com/sheet#gid=0")
    }

    @Test func neverTreatsAnAnchorOrRouteAsParameters() {
        // A "="-less segment means it is not a pure param list — untouched.
        #expect(URLCleaner.clean("https://example.com/wiki#History_of_Rome") == "https://example.com/wiki#History_of_Rome")
        // A route whose own query carries a tracker is still left whole (the "/"
        // prefix marks it a route; client-side routing must not break).
        #expect(URLCleaner.clean("https://example.com/app#/route?id=1&utm_source=a") == "https://example.com/app#/route?id=1&utm_source=a")
    }

    @Test func foldsFragmentRemovalsIntoTelemetryAndDisplay() {
        let outcome = URLCleaner.outcome(
            for: "https://example.com/page#utm_source=a",
            removing: ["utm_source"]
        )
        #expect(outcome.telemetry.removedCount == 1)
        #expect(outcome.telemetry.removedKindIDs == ["utm"])
        #expect(outcome.display.removedNames == ["utm_source"])
        #expect(outcome.telemetry.changed == true)
    }
}

// MARK: - Query + fragment together

struct FragmentAndQueryTests {

    @Test func cleansBothQueryAndFragment() {
        let outcome = URLCleaner.outcome(
            for: "https://example.com/p?utm_source=q&id=1#utm_medium=f",
            removing: ["utm_source", "utm_medium"]
        )
        #expect(outcome.cleaned == "https://example.com/p?id=1")
        #expect(outcome.telemetry.removedCount == 2)
        #expect(Set(outcome.display.removedNames) == ["utm_source", "utm_medium"])
    }

    @Test func countsInstancesButDedupesDisplayNamesAcrossQueryAndFragment() {
        let outcome = URLCleaner.outcome(
            for: "https://example.com/p?utm_source=q#utm_source=f",
            removing: ["utm_source"]
        )
        #expect(outcome.telemetry.removedCount == 2)               // two instances removed
        #expect(outcome.display.removedNames == ["utm_source"])    // one display name
    }

    @Test func anUntouchedLinkWithAFragmentRoundTripsByteForByte() {
        let url = "https://example.com/page?id=1#section"
        #expect(URLCleaner.clean(url) == url)
        let outcome = URLCleaner.outcome(for: url, removing: [])
        #expect(outcome.cleaned == url)
        #expect(outcome.telemetry.changed == false)
    }
}
