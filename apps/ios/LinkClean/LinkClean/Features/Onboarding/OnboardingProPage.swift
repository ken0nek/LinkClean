//
//  OnboardingProPage.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/23/26.
//

import LinkCleanCore
import LinkCleanAnalytics
import SwiftUI

/// Onboarding page 2: the first-launch LinkClean Pro step. Renders the real
/// paywall inline — the same price / Buy / Restore / legal UI as the in-app sheet
/// — via ``PaywallContent`` driven by a shared ``PaywallViewModel`` (trigger
/// `.onboarding`). "Not now" continues to the hands-on Try It step; a completed
/// purchase advances the same way. Still skippable entirely via the top-right
/// Skip in ``OnboardingView``.
struct OnboardingProPage: View {
    private let onContinue: () -> Void
    @State private var viewModel: PaywallViewModel

    init(
        entitlements: EntitlementsModel,
        onContinue: @escaping () -> Void,
        analytics: AnalyticsService = TelemetryDeckAnalytics()
    ) {
        self.onContinue = onContinue
        _viewModel = State(initialValue: PaywallViewModel(
            entitlements: entitlements,
            analytics: analytics,
            trigger: .onboarding
        ))
    }

    var body: some View {
        PaywallContent(viewModel: viewModel, onUnlock: onContinue) {
            Button(action: onContinue) {
                Text(.onboardingProNotNow)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .accessibilityIdentifier("onboarding-pro-not-now")
        }
    }
}

#Preview {
    OnboardingProPage(entitlements: .preview, onContinue: {})
}
