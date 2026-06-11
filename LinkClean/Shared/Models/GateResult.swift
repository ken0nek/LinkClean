//
//  GateResult.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/10/26.
//

import LinkCleanCore

/// The decision a Pro-gated action hands back to its view: proceed, or raise the
/// paywall with a specific trigger. Lets the entitlement + count + ``ProGate``
/// policy composition live in a ViewModel intent instead of a view closure (P10);
/// the view only maps the result to a haptic/dismiss or the sheet trigger.
enum GateResult: Equatable {
    case allowed
    case gated(AnalyticsEvent.PaywallTrigger)
}

/// ``GateResult`` for the Custom Parameters Add flow, whose proceed path also
/// carries any validation message to surface (duplicate / already-default).
enum CustomParameterAddResult: Equatable {
    /// The add was attempted; `error` is a validation message to show, or `nil`
    /// on success.
    case attempted(error: String?)
    /// Blocked by the free-tier allowance — raise the paywall with this trigger.
    case gated(AnalyticsEvent.PaywallTrigger)
}
