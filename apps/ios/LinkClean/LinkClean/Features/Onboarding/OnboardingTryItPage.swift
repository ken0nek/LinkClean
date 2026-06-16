//
//  OnboardingTryItPage.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/7/26.
//

import SwiftUI

/// Onboarding page 2: the hands-on step. Embeds the shared extension guide so
/// the user opens the real share sheet and runs "Clean URL" for real; a
/// detected run advances to the celebration page.
struct OnboardingTryItPage: View {
    let deps: AppDependencies
    let onSuccess: () -> Void
    let onMaybeLater: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(.onboardingTryItTitle)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.top, 56)
                .padding(.horizontal, 24)

            ExtensionGuideView(deps: deps, source: .onboarding, onSuccess: onSuccess)

            Button(action: onMaybeLater) {
                Text(.onboardingTryItMaybeLater)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            }
            .padding(.bottom, 8)
            .accessibilityIdentifier("onboarding-maybe-later")
        }
    }
}

#Preview {
    OnboardingTryItPage(deps: .preview(), onSuccess: {}, onMaybeLater: {})
        .screenBackground()
}
