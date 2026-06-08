//
//  OnboardingCelebrationPage.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/7/26.
//

import SwiftUI

/// Onboarding page 3: confirmation after a real extension run. Mentions both
/// the clipboard and History, so the demo entry doubles as the History intro.
struct OnboardingCelebrationPage: View {
    let onGetStarted: () -> Void

    @State private var celebrate = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 92, weight: .bold))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: celebrate)

            VStack(spacing: 10) {
                Text(.onboardingCelebrationTitle)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(.onboardingCelebrationSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()

            Button(action: onGetStarted) {
                Text(.onboardingCelebrationGetStarted).primaryButtonLabel()
            }
            .accessibilityIdentifier("onboarding-get-started")
        }
        .padding(24)
        .onAppear { celebrate = true }
    }
}

#Preview {
    OnboardingCelebrationPage(onGetStarted: {})
        .screenBackground()
}
