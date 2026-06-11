//
//  AppDependencies.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/11/26.
//

import LinkCleanCore
import LinkCleanData
import LinkCleanAnalytics

/// The app's composition root: the one place production dependencies are
/// constructed and wired together. `ARCHITECTURE.md` promised this; before it,
/// every ViewModel default-constructed its own production services (nine
/// independent wiring points) and the object graph was invisible at the root.
///
/// Now `live()` is the single wiring path — the graph is reviewable at a glance,
/// DEBUG/screenshot builds get one interception point (`preview()`), and the SDK
/// lifecycle lives next to the instance it configures. ViewModel initializers
/// keep no production defaults: a feature view builds its ViewModel from these
/// dependencies (`SomeViewModel(deps:)`), and tests pass explicit doubles.
@MainActor
struct AppDependencies {
    let cleaning: CleaningService
    let analytics: AnalyticsService
    let settings: SettingsStore
    let parameters: TrackingParameterStore
    let review: ReviewService
    let explanations: ParameterExplanationService
    let metadata: LinkMetadataService
    let entitlements: EntitlementsModel

    /// The production graph, built once in `LinkCleanApp.init`. The TelemetryDeck
    /// SDK lifecycle starts here — instance creation and `start(surface:)` finally
    /// live in the same place (and screenshot builds suppress it in one spot).
    static func live() -> AppDependencies {
        if !DebugMode.isScreenshotMode {
            TelemetryDeckAnalytics.start(surface: "app")
        }
        let analytics = TelemetryDeckAnalytics()
        // One store, shared by the cleaning service and the parameter ViewModels.
        let parameters = TrackingParameterStore()
        return AppDependencies(
            cleaning: DefaultCleaningService(store: parameters),
            analytics: analytics,
            settings: SettingsStore(),
            parameters: parameters,
            review: DefaultReviewService(),
            explanations: FoundationModelsParameterExplanationService(),
            metadata: DefaultLinkMetadataService(),
            entitlements: EntitlementsModel(
                service: StoreKitEntitlementsService(),
                analytics: analytics
            )
        )
    }

    /// Offline dependencies for `#Preview` and the environment default: no
    /// analytics network (the instance is never `start()`-ed, so `capture`
    /// no-ops) and no StoreKit (the preview entitlements service).
    static func preview(entitlement: Entitlement = .free) -> AppDependencies {
        AppDependencies(
            cleaning: DefaultCleaningService(),
            analytics: TelemetryDeckAnalytics(),
            settings: SettingsStore(),
            parameters: TrackingParameterStore(),
            review: DefaultReviewService(),
            explanations: FoundationModelsParameterExplanationService(),
            metadata: DefaultLinkMetadataService(),
            entitlements: EntitlementsModel(service: PreviewEntitlementsService(entitlement: entitlement))
        )
    }
}
