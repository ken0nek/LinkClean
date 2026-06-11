//
//  AppDependencies+ViewModels.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/11/26.
//

import Foundation
import LinkCleanCore
import LinkCleanData

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
            explanationService: deps.explanations
        )
    }
}

extension HistoryViewModel {
    convenience init(deps: AppDependencies) {
        self.init(
            metadataService: deps.metadata,
            analytics: deps.analytics,
            settings: deps.settings
        )
    }
}

extension SettingsViewModel {
    convenience init(deps: AppDependencies) {
        self.init(analytics: deps.analytics, settings: deps.settings)
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
