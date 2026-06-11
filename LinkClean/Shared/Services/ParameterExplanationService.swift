//
//  ParameterExplanationService.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/10/26.
//

import Foundation
import FoundationModels
import LinkCleanKit
import OSLog

/// A one-line, plain-language description of a single URL query parameter,
/// produced on-device by Foundation Models for the leftover-parameter confirm
/// dialog.
///
/// `nonisolated` is required, not cosmetic: `@Generable` conformance is
/// `nonisolated`, so under the app's MainActor default isolation the type must
/// opt out for the framework to decode it. It mirrors how `LinkCleanKit`'s
/// domain types (`TrackingParameterKind`) are declared.
@Generable
nonisolated struct ParameterExplanation: Equatable, Sendable {
    @Guide(description: "One short, factual sentence under 20 words. No advice, no warnings, no marketing.")
    let oneLiner: String

    init(oneLiner: String) {
        self.oneLiner = oneLiner
    }
}

/// Explains a single tracking parameter in plain language. App-only — the action
/// extension never surfaces this — and modelled on `LinkMetadataService`: async,
/// and failing softly to `nil` so the caller always falls back to the generic
/// copy rather than blocking the dialog.
protocol ParameterExplanationService: Sendable {
    /// Whether the on-device model is ready. Read before offering an explanation
    /// so the UI can go straight to the generic dialog when it isn't (no spinner,
    /// no wait).
    var isAvailable: Bool { get }

    /// A one-line explanation of `parameter`, or `nil` when the model is
    /// unavailable or generation fails. Never throws — the dialog must always open.
    func explain(parameter: String) async -> ParameterExplanation?
}

struct FoundationModelsParameterExplanationService: ParameterExplanationService {
    /// Longest parameter name we will ask about — bounds the prompt against a
    /// pathological query key (the catalog never produces names this long).
    private static let maxNameLength = 64

    private static let instructions = """
        You explain what a single URL query parameter does, for a privacy-minded reader.
        Given one parameter name, describe in one short, factual sentence what it is \
        typically used for and, when relevant, who adds it. Use plain language. Do not \
        give advice, warnings, or marketing. If the name is not a widely documented \
        parameter, say plainly that its purpose is not well known rather than guessing.
        """

    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    func explain(parameter: String) async -> ParameterExplanation? {
        // Belt-and-suspenders: the caller gates on `isAvailable`, but a session
        // built against an unavailable model would only throw below anyway.
        guard isAvailable else { return nil }

        let name = parameter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let bounded = String(name.prefix(Self.maxNameLength))

        // A fresh session per call keeps each explanation independent — we never
        // want a prior parameter in context, and one-liners can't exhaust it.
        let session = LanguageModelSession(instructions: Self.instructions)
        do {
            let response = try await session.respond(
                to: "Parameter name: \(bounded)",
                generating: ParameterExplanation.self
            )
            return response.content
        } catch {
            Log.app.debug("Parameter explanation failed: \(error.localizedDescription)")
            return nil
        }
    }
}
