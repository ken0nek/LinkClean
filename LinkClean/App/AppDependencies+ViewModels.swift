//
//  AppDependencies+ViewModels.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/11/26.
//

import Foundation
import LinkCleanCore
import LinkCleanData

extension HistoryStore {
    /// A shared in-memory store for ViewModel default arguments and `#Preview`.
    /// One container, created lazily, instead of a fresh SwiftData
    /// `ModelContainer` per ViewModel construction — dozens of those under
    /// parallel tests exhausted resources and destabilized the simulator.
    ///
    /// Its settings have history saving **off** so `record` no-ops: the shared
    /// container is never written, so the parallel tests (which Swift Testing
    /// runs concurrently in one process) can't corrupt its `ModelContext`.
    /// Production always injects the real store through the composition root; a
    /// test that asserts on history passes its own isolated store.
    static let inMemoryPreview: HistoryStore = {
        let settings = SettingsStore(appGroupSuiteName: "linkclean.history.inMemoryPreview")
        settings.saveHistoryEnabled = false
        return HistoryStore(
            container: HistoryContainer.makeInMemory(),
            metadata: DefaultLinkMetadataService(),
            settings: settings
        )
    }()
}

// Each feature ViewModel gains one convenience init that pulls exactly the
// dependencies it needs from the composition root. Owning views build their
// ViewModel with `SomeViewModel(deps:)` instead of default-constructing it, so
// production services are wired in one place (`AppDependencies.live()`) rather
// than implicitly at nine independent call sites. The designated initializers
// keep their parameters for tests, which pass explicit doubles.

extension HomeViewModel {
    convenience init(deps: AppDependencies) {
        self.init(
            service: deps.cleaning,
            analytics: deps.analytics,
            settings: deps.settings,
            store: deps.parameters,
            review: deps.review,
            explanationService: deps.explanations,
            history: deps.history
        )
    }
}

extension HistoryViewModel {
    convenience init(deps: AppDependencies) {
        self.init(
            history: deps.history,
            analytics: deps.analytics,
            settings: deps.settings
        )
    }
}

extension SettingsViewModel {
    convenience init(deps: AppDependencies) {
        self.init(analytics: deps.analytics, settings: deps.settings, history: deps.history)
    }
}

extension ManageParametersViewModel {
    convenience init(deps: AppDependencies) {
        self.init(store: deps.parameters, analytics: deps.analytics)
    }
}

extension CustomParametersViewModel {
    convenience init(deps: AppDependencies) {
        self.init(store: deps.parameters, analytics: deps.analytics)
    }
}

extension ExtensionGuideViewModel {
    convenience init(deps: AppDependencies) {
        self.init(settings: deps.settings, analytics: deps.analytics)
    }
}

extension OnboardingViewModel {
    convenience init(deps: AppDependencies) {
        self.init(analytics: deps.analytics)
    }
}
