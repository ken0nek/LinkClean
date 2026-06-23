//
//  OnboardingTryItPage.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/7/26.
//

import SwiftUI

/// Onboarding page 3: the hands-on step. Embeds the shared extension guide so
/// the user opens the real share sheet and runs "Clean URL" for real; a
/// detected run advances to the celebration page. Skippable via the top-right
/// Skip in ``OnboardingView`` — no separate bottom escape hatch.
struct OnboardingTryItPage: View {
    let deps: AppDependencies
    let onSuccess: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(.onboardingTryItTitle)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.top, 56)
                .padding(.horizontal, 24)

            ExtensionGuideView(deps: deps, source: .onboarding, onSuccess: onSuccess)
        }
    }
}

#Preview {
    OnboardingTryItPage(deps: .preview(), onSuccess: {})
        .screenBackground()
}
