//
//  TelemetryDeckAnalytics.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 6/8/26.
//

import Foundation
import TelemetryDeck
import LinkCleanCore
import LinkCleanData

/// TelemetryDeck-backed ``AnalyticsService``. This is the only type in the
/// codebase that touches the TelemetryDeck SDK; the app and both action
/// extensions see only the typed ``AnalyticsEvent`` API. The SDK is a
/// transitive dependency of LinkCleanKit, never linked directly by an app
/// target — so no Xcode target configuration is required.
///
/// `TelemetryDeck.signal(_:parameters:)` is thread-safe, so this type is
/// `nonisolated` and can capture events from any context.
public nonisolated struct TelemetryDeckAnalytics: AnalyticsService {

    /// Client-side ingest key. Not a secret — it ships in the binary and is
    /// visible in network traffic. See `docs/plans/analytics.md` §11.
    private static let appID = "8A2AC88D-2092-43DC-BC71-CF675C33D01C"

    /// App-wide salt (not per-user) hashed into the default user identifier so
    /// even TelemetryDeck cannot reverse it (`docs/plans/analytics.md` §3).
    private static let salt = "6ebf7288576447f1994d4f1af12d7a88"

    public init() {}

    public func capture(_ event: AnalyticsEvent) {
        // The SDK's `TelemetryManager.shared` assertion-fails in DEBUG when
        // `start()` hasn't run — and `-screenshotMode` skips `start()` on
        // purpose, so the guard is what makes the no-op contract real.
        guard TelemetryManager.isInitialized else { return }
        TelemetryDeck.signal(event.signalName, parameters: event.parameters)
    }

    /// Initializes the TelemetryDeck SDK. Call once per process, as early as
    /// possible — `LinkCleanApp.init()` for the app, `viewDidLoad` for each
    /// action extension. `capture(_:)` is a no-op until this has run.
    ///
    /// - Parameter surface: The target identifier (`app` / `action` / `markdownAction`).
    ///
    /// Test mode is automatic: TelemetryDeck flags signals sent from a debug
    /// session, so DEBUG builds never pollute production insights (§3).
    public static func start(surface: String) {
        let config = TelemetryDeck.Config(appID: appID, salt: salt)
        // `defaultParameters` is evaluated per signal, so `tier` reflects the
        // entitlement live (it flips to `pro` the moment a purchase resolves).
        config.defaultParameters = {
            [
                "tier": EntitlementStore().current().rawValue,
                "surface": surface
            ]
        }
        TelemetryDeck.initialize(config: config)
        TelemetryDeck.updateDefaultUserID(to: sharedUserIdentifier())
    }

    /// Initializes the SDK only if it hasn't been already. The App Intents (S1)
    /// run either in the app process (where ``start(surface:)`` already ran) or in
    /// a fresh widget-extension process (where it did not), so an intent calls this
    /// before `capture(_:)`: a no-op when the SDK is up, an initialize otherwise.
    /// Without it, intent cleans from the control/widget would silently drop their
    /// signal, since `capture(_:)` no-ops until the SDK is initialized.
    public static func startIfNeeded(surface: String) {
        guard !TelemetryManager.isInitialized else { return }
        start(surface: surface)
    }

    /// Reads — or lazily creates — the cross-process anonymous user identifier
    /// from the App Group suite. Without a shared identifier the app and each
    /// extension would count as separate users and the activation funnel would
    /// be unmeasurable (`docs/plans/analytics.md` §4). The SDK hashes it
    /// client-side (with ``salt``) before transmission.
    static func sharedUserIdentifier(
        in defaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier)
    ) -> String {
        guard let defaults else { return UUID().uuidString }
        if let existing = defaults.string(forKey: SettingsKeys.analyticsUserIdentifier) {
            return existing
        }
        let generated = UUID().uuidString
        defaults.set(generated, forKey: SettingsKeys.analyticsUserIdentifier)
        return generated
    }
}
