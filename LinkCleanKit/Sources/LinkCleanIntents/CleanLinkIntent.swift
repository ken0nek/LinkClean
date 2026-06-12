//
//  CleanLinkIntent.swift
//  LinkCleanIntents
//
//  Created by Ken Tominaga on 6/12/26.
//

#if canImport(UIKit)
import AppIntents
import LinkCleanCore
import LinkCleanData
import LinkCleanAnalytics

/// Cleans a link passed in by value — the Shortcuts / Siri / Spotlight /
/// Action-button surface (S1). Takes the link as a `String` (Shortcuts and Siri
/// routinely pass prose, and `URL(string:)` percent-encodes it on iOS 17+), runs
/// the shared ``DefaultCleaningService`` — so it honors the user's enabled
/// parameters, per-host rules, redirect unwrapping, and the fragment toggle, all
/// read from the App Group — and returns the cleaned string so it chains into the
/// next Shortcuts action.
public struct CleanLinkIntent: AppIntent {
    public static let title: LocalizedStringResource = "Clean Link"
    public static let description = IntentDescription(
        "Removes tracking parameters and redirect wrappers from a link."
    )

    /// Cleaning is instant and needs no UI — run silently without foregrounding
    /// the app.
    public static let openAppWhenRun = false

    @Parameter(title: "Link", description: "The link to clean.", requestValueDialog: "Which link?")
    public var link: String

    public init() {}

    public init(link: String) {
        self.link = link
    }

    public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let settings = SettingsStore()
        let cleaning = DefaultCleaningService(settings: settings)
        guard let outcome = try await cleaning.clean(link) else {
            throw CleanLinkError.notALink
        }
        // Emit the signal before the slower history write (analytics §8).
        TelemetryDeckAnalytics.startIfNeeded(surface: "intent")
        TelemetryDeckAnalytics().capture(.intentCleanSucceeded(surface: .shortcut, telemetry: outcome.telemetry))
        await IntentHistory.record(input: link, output: outcome.cleaned, settings: settings)
        return .result(
            value: outcome.cleaned,
            dialog: outcome.telemetry.changed
                ? "Cleaned your link."
                : "Your link was already clean."
        )
    }
}

/// The one failure an intent surfaces to the user: input that isn't a web link.
enum CleanLinkError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case notALink

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notALink: "That doesn't look like a web link."
        }
    }
}
#endif
