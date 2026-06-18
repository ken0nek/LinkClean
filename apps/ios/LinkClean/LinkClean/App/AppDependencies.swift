//
//  AppDependencies.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/11/26.
//

import LinkCleanCore
import LinkCleanData
import LinkCleanAnalytics
import SwiftData

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
    let advisor: ParameterAdvising
    let history: HistoryStore
    let stats: StatsStore
    let templates: TemplateStore
    let entitlements: EntitlementsModel

    /// The production graph, built once in `LinkCleanApp.init` with the app's
    /// `ModelContainer`. The TelemetryDeck SDK lifecycle starts here — instance
    /// creation and `start(surface:)` finally live in the same place (and
    /// screenshot builds suppress it in one spot).
    static func live(container: ModelContainer) -> AppDependencies {
        if !DebugMode.isScreenshotMode {
            TelemetryDeckAnalytics.start(surface: "app")
        }
        let analytics = TelemetryDeckAnalytics()
        // One store, shared by the cleaning service and the parameter ViewModels.
        let parameters = TrackingParameterStore()
        let settings = SettingsStore()
        return AppDependencies(
            // The app is the one surface that always carries the network resolver:
            // short-link expansion is reachable here for every tier (gated by the
            // user's `expandShortLinksEnabled` opt-in, default off). The extensions
            // and intents wire a resolver only in DEBUG (`OutOfAppShortLinkExpansion`).
            cleaning: DefaultCleaningService(
                store: parameters,
                settings: settings,
                resolver: URLSessionShortLinkResolver()
            ),
            analytics: analytics,
            settings: settings,
            parameters: parameters,
            review: DefaultReviewService(),
            advisor: FoundationModelsParameterAdvisor(),
            history: HistoryStore(container: container, metadata: DefaultLinkMetadataService(), settings: settings),
            stats: StatsStore(),
            templates: TemplateStore(),
            entitlements: EntitlementsModel(
                service: StoreKitEntitlementsService(),
                analytics: analytics
            )
        )
    }

    /// Offline dependencies for `#Preview`: no analytics network (the instance is
    /// never `start()`-ed, so `capture` no-ops), no StoreKit (the preview
    /// entitlements service), and an in-memory history container.
    static func preview(entitlement: Entitlement = .free) -> AppDependencies {
        let settings = SettingsStore()
        return AppDependencies(
            cleaning: DefaultCleaningService(settings: settings),
            analytics: TelemetryDeckAnalytics(),
            settings: settings,
            parameters: TrackingParameterStore(),
            review: DefaultReviewService(),
            advisor: FoundationModelsParameterAdvisor(),
            history: HistoryStore(container: HistoryContainer.makeInMemory(), metadata: DefaultLinkMetadataService(), settings: settings),
            stats: StatsStore(),
            templates: TemplateStore(),
            entitlements: EntitlementsModel(service: PreviewEntitlementsService(entitlement: entitlement))
        )
    }
}
