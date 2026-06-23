//
//  OnboardingView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/7/26.
//

import SwiftUI

/// First-launch flow that teaches the share-sheet extension — the app's core,
/// otherwise-invisible feature. The welcome and Pro steps advance via their own
/// primary actions (Continue / Not now); a top-right Skip is offered only on the
/// hands-on Try-It step, the one place a user might want out without acting. The
/// celebration is reached only after a real extension run is detected.
struct OnboardingView: View {
    @Environment(EntitlementsModel.self) private var entitlements
    @State private var viewModel: OnboardingViewModel
    private let deps: AppDependencies

    init(deps: AppDependencies, onFinished: @escaping () -> Void) {
        self.deps = deps
        let viewModel = OnboardingViewModel(deps: deps)
        viewModel.onFinished = onFinished
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content

            if viewModel.page == .tryIt {
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
        case .pro:
            OnboardingProPage(entitlements: entitlements, onContinue: viewModel.advance)
                .transition(.opacity)
        case .tryIt:
            OnboardingTryItPage(
                deps: deps,
                onSuccess: viewModel.handleGuideSuccess
            )
            .transition(.opacity)
        case .celebration:
            OnboardingCelebrationPage(onGetStarted: viewModel.getStarted)
                .transition(.opacity)
        }
    }
}

#Preview {
    OnboardingView(deps: .preview(), onFinished: {})
        .environment(EntitlementsModel.preview)
}
