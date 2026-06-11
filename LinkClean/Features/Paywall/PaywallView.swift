//
//  PaywallView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/10/26.
//

import LinkCleanKit
import SwiftUI

/// External Terms / Privacy destinations the paywall links to (Apple requires an
/// EULA/terms + privacy link once IAP ships). Update if the canonical URLs move.
enum ProLegal {
    static let termsOfUse = URL(string: "https://ken0nek.com/apps/linkclean/terms-of-use/")!
    static let privacyPolicy = URL(string: "https://ken0nek.com/apps/linkclean/privacy-policy/")!
}

/// The hand-rolled LinkClean Pro paywall. One sheet, a contextual header per
/// trigger over a constant body, fed by a StoreKit product through
/// ``EntitlementsModel`` — no third-party paywall SDK.
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
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(spacing: 28) {
                header
                benefits
            }
            .padding(.horizontal, 24)
            .padding(.top, 36)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) { purchaseBar }
        .screenBackground()
        .overlay(alignment: .topTrailing) { closeButton }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isPurchasing)
        .task { await viewModel.onAppear() }
        .onChange(of: viewModel.didUnlock) { _, unlocked in
            if unlocked { dismiss() }
        }
        .alert(Text(.paywallPendingTitle), isPresented: $viewModel.showPendingApproval) {
            Button { } label: { Text(.commonOk) }
        } message: {
            Text(.paywallPendingMessage)
        }
        .alert(Text(.paywallErrorTitle), isPresented: $viewModel.showPurchaseError) {
            Button { } label: { Text(.commonOk) }
        } message: {
            Text(.paywallErrorMessage)
        }
        .alert(Text(.paywallRestoreNoneTitle), isPresented: $viewModel.showNothingToRestore) {
            Button { } label: { Text(.commonOk) }
        } message: {
            Text(.paywallRestoreNoneMessage)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: headerIcon)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 88, height: 88)
                .glassEffect(in: .circle)

            VStack(spacing: 8) {
                headerTitle
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                Text(.paywallPitch)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var headerTitle: Text {
        switch viewModel.trigger {
        case .historyArchive:
            Text(.paywallHeaderHistory)
        case .customParamHome, .customParamSettings:
            Text(.paywallHeaderTrackers)
        default:
            Text(.paywallHeaderGeneric)
        }
    }

    private var headerIcon: String {
        switch viewModel.trigger {
        case .historyArchive: "clock.arrow.circlepath"
        case .customParamHome, .customParamSettings: "shield.lefthalf.filled"
        default: "sparkles"
        }
    }

    // MARK: - Benefits

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 18) {
            benefitRow(
                icon: "clock.arrow.circlepath",
                title: .paywallBenefitHistoryTitle,
                body: .paywallBenefitHistoryBody
            )
            benefitRow(
                icon: "slider.horizontal.3",
                title: .paywallBenefitRulesTitle,
                body: .paywallBenefitRulesBody
            )
            benefitRow(
                icon: "sparkles",
                title: .paywallBenefitFutureTitle,
                body: .paywallBenefitFutureBody
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func benefitRow(
        icon: String,
        title: LocalizedStringResource,
        body: LocalizedStringResource
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Purchase bar

    private var purchaseBar: some View {
        VStack(spacing: 12) {
            switch viewModel.loadState {
            case .loading:
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            case .ready(let product):
                Button {
                    Task { await viewModel.purchase() }
                } label: {
                    if viewModel.isPurchasing {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(.paywallUnlock(product.localizedPrice)).primaryButtonLabel()
                    }
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(viewModel.isPurchasing)
                .accessibilityIdentifier("paywall-purchase")

                Text(.paywallPriceNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            case .unavailable:
                Text(.paywallUnavailable)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    Task { await viewModel.loadProduct() }
                } label: {
                    Text(.paywallRetry).primaryButtonLabel()
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
            }

            Button {
                Task { await viewModel.restore() }
            } label: {
                Text(.paywallRestore)
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isPurchasing)
            .accessibilityIdentifier("paywall-restore")

            legalLinks
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(.bar)
    }

    private var legalLinks: some View {
        HStack(spacing: 6) {
            Link(destination: ProLegal.termsOfUse) { Text(.paywallTerms) }
            Text(verbatim: "·").foregroundStyle(.tertiary)
            Link(destination: ProLegal.privacyPolicy) { Text(.paywallPrivacy) }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
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
