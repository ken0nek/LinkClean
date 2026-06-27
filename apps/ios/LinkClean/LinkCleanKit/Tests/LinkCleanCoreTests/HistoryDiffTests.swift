//
//  HistoryDiffTests.swift
//  LinkCleanCoreTests
//

import Testing
import Foundation
@testable import LinkCleanCore

struct HistoryDiffTests {

    @Test func reportsRemovedParametersInInputOrder() {
        let diff = HistoryDiff(
            input: "https://x.com/?utm_source=a&utm_medium=b&id=1",
            output: "https://x.com/?id=1"
        )

        #expect(diff.removedParameters == [
            .init(name: "utm_source", value: "a"),
            .init(name: "utm_medium", value: "b"),
        ])
        #expect(diff.removedFragment == nil)
        #expect(diff.expandedFromHost == nil)
        #expect(diff.isEmpty == false)
    }

    @Test func keepsParametersThatSurvived() {
        let diff = HistoryDiff(
            input: "https://x.com/?id=1&utm_source=a",
            output: "https://x.com/?id=1"
        )
        // `id=1` survived, so only `utm_source=a` is reported removed.
        #expect(diff.removedParameters == [.init(name: "utm_source", value: "a")])
    }

    @Test func reportsRemovedFragment() {
        let diff = HistoryDiff(
            input: "https://example.com/page#:~:text=highlighted",
            output: "https://example.com/page"
        )

        #expect(diff.removedFragment == ":~:text=highlighted")
        #expect(diff.removedParameters.isEmpty)
        #expect(diff.isEmpty == false)
    }

    @Test func reportsRemovedDirectiveWhenAnchorSurvives() {
        // The cleaner strips the `:~:text=` scroll-to-text directive but keeps the
        // `#Behavior` anchor — the output fragment is non-empty, so the diff must
        // still report what came off (not "nothing removed").
        let diff = HistoryDiff(
            input: "https://en.wikipedia.org/wiki/Cat#Behavior:~:text=secret",
            output: "https://en.wikipedia.org/wiki/Cat#Behavior"
        )

        #expect(diff.removedFragment == ":~:text=secret")
        #expect(diff.isEmpty == false)
    }

    @Test func reportsRemovedFragmentParamWhenOthersSurvive() {
        let diff = HistoryDiff(
            input: "https://x.com/p#utm_source=ad&id=1",
            output: "https://x.com/p#id=1"
        )

        #expect(diff.removedFragment == "utm_source=ad")
        #expect(diff.isEmpty == false)
    }

    @Test func surfacesPersistedArrivalHostAsExpansion() {
        // The arrival host is resolved + normalized upstream (CleaningService) and
        // persisted; HistoryDiff surfaces it as-is and never re-derives it from the
        // stored strings (which are both the destination). The destination's own
        // surviving param is what gets diffed — never a redirect wrapper's payload.
        let diff = HistoryDiff(
            input: "https://youtube.com/watch?v=dQw4&feature=share",
            output: "https://youtube.com/watch?v=dQw4",
            arrivedFromHost: "bit.ly"
        )

        #expect(diff.expandedFromHost == "bit.ly")
        #expect(diff.removedParameters == [.init(name: "feature", value: "share")])
        #expect(diff.isEmpty == false)
    }

    @Test func reportsRemovedDuplicateWhenIdenticalCopySurvived() {
        // Multiplicity-aware: one of two identical params was removed, so exactly
        // one row is reported (the surviving copy masks only one).
        let diff = HistoryDiff(
            input: "https://x.com/?a=1&a=1",
            output: "https://x.com/?a=1"
        )

        #expect(diff.removedParameters == [.init(name: "a", value: "1")])
    }

    @Test func listsFullyRemovedDuplicates() {
        let diff = HistoryDiff(
            input: "https://x.com/?utm=x&utm=x",
            output: "https://x.com/"
        )

        #expect(diff.removedParameters == [
            .init(name: "utm", value: "x"),
            .init(name: "utm", value: "x"),
        ])
    }

    @Test func isEmptyWhenAlreadyClean() {
        let diff = HistoryDiff(
            input: "https://x.com/?id=1",
            output: "https://x.com/?id=1"
        )

        #expect(diff.isEmpty)
        #expect(diff.removedParameters.isEmpty)
        #expect(diff.removedFragment == nil)
        #expect(diff.expandedFromHost == nil)
    }

    @Test func noExpansionWhenNoArrivalHostPersisted() {
        // No arrival host persisted → no banner, even though only the query changed.
        let diff = HistoryDiff(
            input: "https://shop.com/p?ref=email",
            output: "https://shop.com/p"
        )

        #expect(diff.expandedFromHost == nil)
        #expect(diff.removedParameters == [.init(name: "ref", value: "email")])
    }

    @Test func toleratesUnparseableStrings() {
        let diff = HistoryDiff(input: "not a url at all", output: "")
        #expect(diff.isEmpty)
    }

    @Test func capturesEmptyValuedParameter() {
        let diff = HistoryDiff(
            input: "https://x.com/?flag&id=1",
            output: "https://x.com/?id=1"
        )
        #expect(diff.removedParameters == [.init(name: "flag", value: "")])
    }
}
