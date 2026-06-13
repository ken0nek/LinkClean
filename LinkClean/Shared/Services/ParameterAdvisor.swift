//
//  ParameterAdvisor.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/13/26.
//

import Foundation
import FoundationModels
import LinkCleanCore
import OSLog

/// Classifies the parameters a clean leaves behind and proposes the single best
/// one to always-remove — the unknown-parameter advisor (growth-roadmap §5
/// "ai-A"). Two tiers, both on-device: a deterministic heuristic that runs on
/// every device (``TrackerHeuristic``), then Apple's on-device model for the
/// ambiguous middle on eligible hardware. Suggestion-only — it never mutates a
/// URL, a parameter list, or history; the Home flow acts on the user's tap.
///
/// Modelled on `LinkMetadataService`: async, failing soft to `nil` so a missing
/// or struggling model degrades to "no suggestion", never an error.
protocol ParameterAdvising: Sendable {
    /// Whether the model tier is usable. Deterministic suggestions surface
    /// regardless; this only gates the ambiguous-middle classification, so the
    /// advisor is progressive enhancement (ai-features §2), not all-or-nothing.
    var isModelAvailable: Bool { get }

    /// Eagerly load the model so the first classification doesn't pay load
    /// latency. No-op when the model is unavailable.
    func prewarm()

    /// The single best suggestion among `candidates` (leftover names, already
    /// filtered of managed catalog defaults and dismissed names), or `nil`.
    /// Deterministic matches win immediately; the model is consulted only for
    /// names the heuristic can't place, and only on eligible devices.
    func suggestion(among candidates: [String]) async -> ParameterSuggestion?
}

/// The no-op advisor: never available, never suggests. It's the `HomeViewModel`
/// init's test/preview-convenience default — analogous to
/// `HistoryStore.inMemoryPreview` — so a clean in a test or `#Preview` never
/// schedules model work or surfaces a suggestion the test didn't ask for.
/// Production injects ``FoundationModelsParameterAdvisor`` through the
/// composition root (`AppDependencies`).
struct DisabledParameterAdvisor: ParameterAdvising {
    var isModelAvailable: Bool { false }
    func prewarm() {}
    func suggestion(among candidates: [String]) async -> ParameterSuggestion? { nil }
}

struct FoundationModelsParameterAdvisor: ParameterAdvising {
    /// Longest name we'll ask the model about — bounds the prompt against a
    /// pathological query key (the catalog never produces names this long).
    private static let maxNameLength = 64
    /// Cap on model calls per clean: the advisor only needs the first confident
    /// tracker, so a long leftover list can't fan out into many inferences.
    private static let maxModelChecks = 4

    private static let instructions = """
        You classify a single URL query parameter for a privacy tool that removes trackers.
        Decide whether the parameter is used for tracking (identifying or measuring the user, \
        a click, or a marketing campaign — analytics, advertising, attribution), is functional \
        (the page needs it: a search term, page number, item id, language, sort order), or you \
        are unsure (not a widely documented parameter). Answer "tracking" only when you are \
        confident. Give one short, factual reason under 16 words. No advice, no warnings.
        """

    var isModelAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    func prewarm() {
        guard isModelAvailable else { return }
        // The model assets are process-shared, so warming a throwaway session
        // loads them for the real per-classification sessions too.
        LanguageModelSession(instructions: Self.instructions).prewarm()
    }

    func suggestion(among candidates: [String]) async -> ParameterSuggestion? {
        // Tier 1 — deterministic. The first candidate with a reference-catalog or
        // name-shape signal wins: certain and instant, on every device.
        var unknowns: [String] = []
        for name in candidates {
            switch TrackerHeuristic.assess(name) {
            case .likelyTracker(let signal):
                return ParameterSuggestion(name: name, reason: Self.reason(for: signal), tier: signal.tier)
            case .functional:
                continue
            case .unknown:
                unknowns.append(name)
            }
        }

        // Tier 2 — model. Classify the ambiguous middle on eligible devices,
        // stopping at the first confident tracker. Anything else → no suggestion.
        guard isModelAvailable else { return nil }
        for name in unknowns.prefix(Self.maxModelChecks) {
            guard let verdict = await classify(name), verdict.classification == .tracking else { continue }
            return ParameterSuggestion(name: name, reason: verdict.reason, tier: .model)
        }
        return nil
    }

    private func classify(_ name: String) async -> TrackerVerdict? {
        let bounded = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxNameLength))
        guard !bounded.isEmpty else { return nil }

        // A fresh session per call keeps each verdict independent — a prior
        // parameter must never bias the next, and one-word inputs can't exhaust
        // the context window.
        let session = LanguageModelSession(instructions: Self.instructions)
        do {
            let response = try await session.respond(
                to: "Parameter name: \(bounded)",
                generating: TrackerVerdict.self,
                options: GenerationOptions(temperature: 0.2)
            )
            return response.content
        } catch {
            Log.app.debug("Parameter classification failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// The localized reason for a deterministic signal. The kit ships the signal
    /// id; the app owns the copy (CLAUDE.md: domain types ship identifiers, not
    /// text). The model tier supplies its own runtime reason.
    private static func reason(for signal: TrackerHeuristic.Signal) -> String {
        switch signal {
        case .known: String(localized: .homeAdvisorReasonKnown)
        case .campaign: String(localized: .homeAdvisorReasonCampaign)
        case .clickID: String(localized: .homeAdvisorReasonClickId)
        case .affiliate: String(localized: .homeAdvisorReasonAffiliate)
        case .generic: String(localized: .homeAdvisorReasonGeneric)
        }
    }
}

private extension TrackerHeuristic.Signal {
    /// The analytics tier a deterministic signal reports: the reference catalog
    /// is its own tier; every name-shape rule is ``AnalyticsEvent/AdvisorTier/heuristic``.
    /// An exhaustive switch (not a `== .known` default) so a future ``Signal`` case
    /// can't silently mis-attribute the tier slice.
    var tier: AnalyticsEvent.AdvisorTier {
        switch self {
        case .known: .reference
        case .campaign, .clickID, .affiliate, .generic: .heuristic
        }
    }
}

/// The model's verdict on one parameter — guided generation guarantees the
/// shape, so there's no JSON parsing or malformed output to handle. `nonisolated`
/// is required, not cosmetic: `@Generable` conformance is `nonisolated`, so under
/// the app's MainActor default isolation the type must opt out for the framework
/// to decode it (mirrors the kit's domain types).
@Generable
nonisolated struct TrackerVerdict: Equatable, Sendable {
    @Guide(description: "Whether the parameter is used for tracking, is functional, or you are unsure.")
    let classification: TrackerClassification

    @Guide(description: "One short, factual sentence under 16 words on what the parameter is typically used for. No advice or warnings.")
    let reason: String
}

/// The constrained classification choice. An explicit `unsure` case gives the
/// small model an honest out instead of forcing a wrong binary — only `tracking`
/// ever surfaces a suggestion.
@Generable
nonisolated enum TrackerClassification {
    case tracking
    case functional
    case unsure
}
