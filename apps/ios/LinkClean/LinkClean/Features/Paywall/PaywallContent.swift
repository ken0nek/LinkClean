//
//  PaywallContent.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/23/26.
//

import LinkCleanCore
import LinkCleanAnalytics
import SwiftUI

/// The shared body of the LinkClean Pro paywall — a contextual header per trigger,
/// the constant benefits card, and the StoreKit purchase bar (price, Restore,
/// legal links). Rendered two ways: as a sheet by ``PaywallView`` and inline as
/// the first-launch Pro step by ``OnboardingProPage``. The wrapper owns the
/// ``PaywallViewModel`` and supplies the dismissal chrome (a close button or a
/// "Not now" footer) plus the `onUnlock` action run once Pro is unlocked.
struct PaywallContent<Footer: View>: View {
    let viewModel: PaywallViewModel
    /// Invoked once a purchase or restore unlocks Pro — the sheet dismisses, the
    /// onboarding step advances.
    let onUnlock: () -> Void
    /// Extra controls below the purchase bar (onboarding's "Not now"); `EmptyView`
    /// for the sheet, which dismisses via its top-trailing close button instead.
    @ViewBuilder let footer: () -> Footer

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
        .task { await viewModel.onAppear() }
        .onChange(of: viewModel.didUnlock) { _, unlocked in
            if unlocked { onUnlock() }
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
        case .formatPicker:
            Text(.paywallHeaderFormats)
        default:
            Text(.paywallHeaderGeneric)
        }
    }

    private var headerIcon: String {
        switch viewModel.trigger {
        case .historyArchive: "clock.arrow.circlepath"
        case .customParamHome, .customParamSettings: "shield.lefthalf.filled"
        case .formatPicker: "curlybraces"
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
                icon: "curlybraces",
                title: .paywallBenefitFormatsTitle,
                body: .paywallBenefitFormatsBody
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

            actionsRow

            footer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(.bar)
    }

    /// Restore + the two legal links on a single compact line, keeping the
    /// purchase bar short (it's pinned, and inline during onboarding).
    private var actionsRow: some View {
        HStack(spacing: 6) {
            Button {
                Task { await viewModel.restore() }
            } label: {
                Text(.paywallRestore)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isPurchasing)
            .accessibilityIdentifier("paywall-restore")

            Text(verbatim: "·").foregroundStyle(.tertiary)
            Link(destination: ProLegal.termsOfUse) { Text(.paywallTerms) }
            Text(verbatim: "·").foregroundStyle(.tertiary)
            Link(destination: ProLegal.privacyPolicy) { Text(.paywallPrivacy) }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
}
