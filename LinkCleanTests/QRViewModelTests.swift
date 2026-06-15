//
//  QRViewModelTests.swift
//  LinkCleanTests
//

import Testing
@testable import LinkClean
import LinkCleanCore

@MainActor
struct QRViewModelTests {
    private func makeSUT() -> (QRViewModel, SpyAnalytics) {
        let spy = SpyAnalytics()
        let vm = QRViewModel(analytics: spy)
        return (vm, spy)
    }

    @Test func copyRecordsTheExport() {
        let (vm, spy) = makeSUT()
        vm.result = .stub(input: "https://x.com/?utm_source=a", cleaned: "https://x.com/")
        vm.copyCleanedURL()
        #expect(spy.events.contains(.qrResultActioned(.copy)))
    }

    @Test func shareRecordsTheExport() {
        let (vm, spy) = makeSUT()
        vm.result = .stub(input: "https://x.com/", cleaned: "https://x.com/")
        vm.recordShare()
        #expect(spy.events.contains(.qrResultActioned(.share)))
    }

    @Test func openRecordsTheExport() {
        let (vm, spy) = makeSUT()
        vm.result = .stub(input: "https://x.com/", cleaned: "https://x.com/")
        vm.recordOpen()
        #expect(spy.events.contains(.qrResultActioned(.open)))
    }

    /// The Share button lives on a result sheet, but guard the export signal so a
    /// stray call without a result can't emit a phantom export.
    @Test func shareWithoutAResultRecordsNothing() {
        let (vm, spy) = makeSUT()
        vm.recordShare()
        #expect(!spy.events.contains(.qrResultActioned(.share)))
    }
}
