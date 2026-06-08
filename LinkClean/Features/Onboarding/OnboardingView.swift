//
//  OnboardingView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/7/26.
//

import SwiftUI

/// First-launch flow that teaches the share-sheet extension — the app's core,
/// otherwise-invisible feature. Skippable at every step except the celebration,
/// which is only reached after a real extension run is detected.
struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel

    init(onFinished: @escaping () -> Void, viewModel: OnboardingViewModel = OnboardingViewModel()) {
        viewModel.onFinished = onFinished
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content

            if viewModel.page != .celebration {
                Button { viewModel.skip() } label: {
                    Text(.onboardingSkip)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .padding(8)
                .accessibilityIdentifier("onboarding-skip")
            }
        }
        .screenBackground()
        .animation(.easeInOut(duration: 0.3), value: viewModel.page)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.page {
        case .welcome:
            OnboardingWelcomePage(onContinue: viewModel.advance)
                .transition(.opacity)
        case .tryIt:
            OnboardingTryItPage(
                onSuccess: viewModel.handleGuideSuccess,
                onMaybeLater: viewModel.skip
            )
            .transition(.opacity)
        case .celebration:
            OnboardingCelebrationPage(onGetStarted: viewModel.getStarted)
                .transition(.opacity)
        }
    }
}

#Preview {
    OnboardingView(onFinished: {})
}
