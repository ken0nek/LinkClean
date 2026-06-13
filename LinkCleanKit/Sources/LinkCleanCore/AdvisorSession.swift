//
//  AdvisorSession.swift
//  LinkCleanCore
//
//  Created by Ken Tominaga on 6/13/26.
//

import Foundation

/// One advisor suggestion: a leftover query parameter the app judges a likely
/// tracker, with a one-line reason and the tier that produced it. `name` is a
/// raw, on-device key — display only; never routed to analytics, only the finite
/// ``AnalyticsEvent/AdvisorTier`` is. `reason` is plain text the app already
/// localized (or the model produced), so the type carries no app dependency and
/// can live in the domain layer beside the ledger that owns it.
public struct ParameterSuggestion: Equatable, Sendable {
    public let name: String
    public let reason: String
    public let tier: AnalyticsEvent.AdvisorTier

    public init(name: String, reason: String, tier: AnalyticsEvent.AdvisorTier) {
        self.name = name
        self.reason = reason
        self.tier = tier
    }
}

/// The dedup/suppression ledger for the unknown-parameter advisor on one Home
/// session — the value-type sibling of ``CleanSession``. It owns the surfaced
/// ``suggestion`` plus the per-input suppression state (dismissed names, the
/// "already engaged" mark) whose interactions used to live as loose fields and
/// guards in `HomeViewModel`.
///
/// Encoding them as a transition function makes the funnel invariants exhaustively
/// testable in the fast macOS suite instead of emergent from field interactions:
/// surface at most one, fire `Advisor.suggested`/`accepted`/`dismissed` once each,
/// treat a gated accept-then-"Not now" as one *accept* (not accept + dismiss),
/// keep a still-applicable pick (anti-flicker), and never re-propose a dismissed
/// name for the same input.
///
/// The async model call and the analytics side effects stay in the ViewModel;
/// this type decides *what* should happen (mirroring ``CleanSession`` /
/// ``CleanSession/ExportEffects``), the caller performs it.
public struct AdvisorSession: Equatable, Sendable {
    /// The suggestion currently on screen, or `nil`.
    public private(set) var suggestion: ParameterSuggestion?

    /// Lowercased names the user dismissed for the current input — never
    /// re-proposed until the input changes.
    private var dismissed: Set<String> = []
    /// The input the user has accepted or dismissed a suggestion on. Once set, no
    /// new suggestion auto-surfaces for it, and repeat accept/dismiss taps stop
    /// re-counting (a gated card stays on screen and re-tappable).
    private var engagedInput: String?

    public init() {}

    /// New link context (the input changed): clear per-input suppression. The
    /// suggestion is deliberately *not* cleared here — ``keepsCurrent(amongCandidates:)``
    /// re-validates it against the new candidates so a still-applicable pick
    /// doesn't flicker as a URL is edited.
    public mutating func beginInput() {
        dismissed.removeAll()
        engagedInput = nil
    }

    /// The leftover names eligible for advice: not dismissed this input, and not
    /// a catalog-managed default (those belong to the Settings toggles, not the
    /// advisor). The reference catalog the heuristic draws on is disjoint from
    /// ``TrackingParameterCatalog/allNames``, so vetted known trackers still pass.
    public func candidates(from leftoverNames: [String]) -> [String] {
        leftoverNames.filter { name in
            let key = name.lowercased()
            return !dismissed.contains(key) && !TrackingParameterCatalog.allNames.contains(key)
        }
    }

    /// Whether the current suggestion still applies among `candidates` — keep it
    /// (no recompute, no re-emit) to avoid flicker on re-cleans of a growing URL.
    public func keepsCurrent(amongCandidates candidates: [String]) -> Bool {
        guard let current = suggestion else { return false }
        return candidates.contains { $0.lowercased() == current.name.lowercased() }
    }

    /// Whether the advisor is suppressed for `input` (the user already engaged a
    /// suggestion on it — handle one, then the leftover pills cover the rest).
    public func isEngaged(with input: String) -> Bool {
        engagedInput == input
    }

    /// Surface a freshly-derived suggestion (replacing any prior), or clear with
    /// `nil`. Returns whether a suggestion is now shown — the caller fires
    /// `Advisor.suggested` on `true`.
    @discardableResult
    public mutating func surface(_ proposed: ParameterSuggestion?) -> Bool {
        suggestion = proposed
        return proposed != nil
    }

    /// Note an accept *intent* for `input`. Returns whether to fire
    /// `Advisor.accepted` — once per engaged input, so a free user's repeated taps
    /// on a gated card don't inflate the count. Marks the input engaged.
    public mutating func noteAccept(input: String?) -> Bool {
        let fire = engagedInput != input
        engagedInput = input
        return fire
    }

    /// Note a dismiss for `input`. Returns whether to fire `Advisor.dismissed` —
    /// once per engaged input, and **not** when the input was already accepted (a
    /// gated accept then "Not now" is one accept, not an accept + a dismiss).
    /// Remembers the name so it isn't re-proposed, and clears the card.
    public mutating func noteDismiss(input: String?) -> Bool {
        let fire = engagedInput != input
        if let name = suggestion?.name {
            dismissed.insert(name.lowercased())
        }
        engagedInput = input
        suggestion = nil
        return fire
    }
}
