//
//  ProGate.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 6/10/26.
//

/// The free-tier limits and the gate decisions that read them (strategy §6).
/// Centralized so the Home leftover gate (T2), the Custom Parameters gate (T3),
/// and the History window (T1) all agree on the same allowances. Lives in the kit
/// beside ``Entitlement`` so the policy — "what may a free user do" — travels with
/// the tier it gates and is ready for extension-side gates. Pure value logic in
/// `LinkCleanCore`, callable from any context.
public enum ProGate {
    /// Free users may keep up to this many custom rules; the gate opens past it.
    public static let freeCustomRuleAllowance = 1

    /// Free users see history within this many days; older entries gate (T1).
    public static let freeHistoryWindowDays = 7

    /// Whether a user with `entitlement` and `currentCount` custom rules can add
    /// another without hitting the paywall. Pro is unlimited; free is capped at
    /// ``freeCustomRuleAllowance`` — existing rules over the cap keep applying
    /// (the gate is on *adding*, never on what a user already has).
    public static func canAddCustomRule(entitlement: Entitlement, currentCount: Int) -> Bool {
        entitlement == .pro || currentCount < freeCustomRuleAllowance
    }
}
