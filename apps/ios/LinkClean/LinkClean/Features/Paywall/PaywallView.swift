//
//  PaywallView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/10/26.
//

import LinkCleanCore
import LinkCleanAnalytics
import SwiftUI

/// External Terms / Privacy destinations the paywall links to (Apple requires an
/// EULA/terms + privacy link once IAP ships). Update if the canonical URLs move.
enum ProLegal {
    static let termsOfUse = URL(string: "https://ken0nek.com/apps/linkclean/terms-of-use/")!
    static let privacyPolicy = URL(string: "https://ken0nek.com/apps/linkclean/privacy-policy/")!
}

/// The hand-rolled LinkClean Pro paywall, presented as a sheet. Thin chrome over
/// the shared ``PaywallContent`` (contextual header, benefits, StoreKit purchase
/// bar): a top-trailing close button and the sheet-dismissal wiring. The same
/// content renders inline during first-launch onboarding via ``OnboardingProPage``.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PaywallViewModel

    init(
        trigger: AnalyticsEvent.PaywallTrigger,
        entitlements: EntitlementsModel,
        analytics: AnalyticsService = TelemetryDeckAnalytics()
    ) {
        _viewModel = State(initialValue: PaywallViewModel(
            entitlements: entitlements,
            analytics: analytics,
            trigger: trigger
        ))
    }

    var body: some View {
        PaywallContent(viewModel: viewModel, onUnlock: { dismiss() }) {
            EmptyView()
        }
        .overlay(alignment: .topTrailing) { closeButton }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isPurchasing)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(10)
                .background(.thinMaterial, in: .circle)
        }
        .buttonStyle(.plain)
        .padding(16)
        .disabled(viewModel.isPurchasing)
        .accessibilityLabel(Text(.commonClose))
    }
}

extension View {
    /// Presents the Pro paywall while `trigger` is non-nil, seeded with the shared
    /// entitlements model. Each gate site owns a `@State` trigger and sets it on a
    /// gated tap; dismissal clears it.
    func paywallSheet(
        trigger: Binding<AnalyticsEvent.PaywallTrigger?>,
        entitlements: EntitlementsModel
    ) -> some View {
        sheet(item: trigger) { trigger in
            PaywallView(trigger: trigger, entitlements: entitlements)
        }
    }
}
