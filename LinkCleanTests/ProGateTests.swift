//
//  ProGateTests.swift
//  LinkCleanTests
//

import Testing
@testable import LinkClean
import LinkCleanKit

struct ProGateTests {
    @Test func proCanAlwaysAdd() {
        #expect(ProGate.canAddCustomRule(entitlement: .pro, currentCount: 0))
        #expect(ProGate.canAddCustomRule(entitlement: .pro, currentCount: 99))
    }

    @Test func freeCanAddWithinAllowance() {
        #expect(ProGate.canAddCustomRule(entitlement: .free, currentCount: 0))
    }

    @Test func freeBlockedAtAndPastAllowance() {
        #expect(ProGate.canAddCustomRule(entitlement: .free, currentCount: 1) == false)
        #expect(ProGate.canAddCustomRule(entitlement: .free, currentCount: 2) == false)
    }

    @Test func allowancesMatchStrategy() {
        #expect(ProGate.freeCustomRuleAllowance == 1)
        #expect(ProGate.freeHistoryWindowDays == 7)
    }
}
