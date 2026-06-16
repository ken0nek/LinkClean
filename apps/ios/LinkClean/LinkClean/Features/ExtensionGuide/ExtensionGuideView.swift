//
//  ExtensionGuideView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/7/26.
//

import SwiftUI

/// Explains how to find and use LinkClean's share-sheet actions, with a live
/// "Try it now" button that opens the real share sheet. Reused by onboarding
/// page 2 and the Settings "How to Use" entry via the `source` parameter.
struct ExtensionGuideView: View {
    @State private var viewModel: ExtensionGuideViewModel
    @Environment(\.scenePhase) private var scenePhase

    let source: ExtensionGuideSource
    /// Called when a successful extension run is detected. Onboarding uses this
    /// to advance to its celebration page; Settings leaves it nil and shows an
    /// inline confirmation instead.
    var onSuccess: (() -> Void)?

    init(
        deps: AppDependencies,
        source: ExtensionGuideSource,
        onSuccess: (() -> Void)? = nil
    ) {
        self.source = source
        self.onSuccess = onSuccess
        _viewModel = State(initialValue: ExtensionGuideViewModel(deps: deps))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(.guideIntro)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ShareSheetMockView(pulseActive: viewModel.isIdleOrWaiting)

                stepsCard

                tryItCard
            }
            .padding(20)
        }
        .screenBackground()
        .onAppear { viewModel.onAppear(source: source) }
        .onDisappear { viewModel.reset() }
        .onChange(of: scenePhase) { _, newValue in
            viewModel.handleScenePhase(newValue)
        }
        .onChange(of: viewModel.hasSucceeded) { _, succeeded in
            if succeeded { onSuccess?() }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.state)
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            GuideStep(number: 1, text: .guideStep1)
            GuideStep(number: 2, text: .guideStep2)
            GuideStep(number: 3, text: .guideStep3)
            GuideStep(number: 4, text: .guideStep4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard()
    }

    private var tryItCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.guideTryItHeader)
                .font(.headline)

            ShareLink(item: viewModel.demoURL) {
                Label { Text(.guideTryItButton) } icon: { Image(systemName: "square.and.arrow.up") }
                    .primaryButtonLabel()
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .simultaneousGesture(TapGesture().onEnded { viewModel.tryItTapped() })
            .accessibilityIdentifier("guide-try-it")

            statusLine
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard()
    }

    @ViewBuilder
    private var statusLine: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .waitingForExtension:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text(.guideTryItWaiting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .succeeded:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(.guideTryItSuccess)
                    .font(.subheadline.weight(.semibold))
            }
            .transition(.opacity)
        }
    }
}

private struct GuideStep: View {
    let number: Int
    let text: LocalizedStringResource

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(verbatim: "\(number)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(.tint, in: Circle())

            Text(text)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        ExtensionGuideView(deps: .preview(), source: .settings)
            .navigationTitle(Text(.guideTitle))
    }
}
