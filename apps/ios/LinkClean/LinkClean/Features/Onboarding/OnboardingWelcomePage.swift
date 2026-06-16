//
//  OnboardingWelcomePage.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/7/26.
//

import SwiftUI

/// Onboarding page 1: the value proposition — a before/after of a link being
/// stripped of tracking junk, plus the on-device privacy promise.
struct OnboardingWelcomePage: View {
    let onContinue: () -> Void

    private var dirtyURL: AttributedString {
        let clean = AttributedString("www.example.com/products/sneakers")
        var junk = AttributedString("?utm_source=newsletter&fbclid=abc123")
        junk.foregroundColor = .red
        junk.strikethroughStyle = .single
        return clean + junk
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

            Image(systemName: "scissors")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 96, height: 96)
                .glassEffect(in: .circle)

            VStack(spacing: 10) {
                Text(.onboardingWelcomeTitle)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(.onboardingWelcomeSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            beforeAfterCard

            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.tint)
                Text(.onboardingWelcomePrivacy)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer(minLength: 20)

            Button(action: onContinue) {
                Text(.onboardingWelcomeContinue).primaryButtonLabel()
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .accessibilityIdentifier("onboarding-continue")
        }
        .padding(24)
    }

    private var beforeAfterCard: some View {
        VStack(spacing: 12) {
            labeledRow(label: Text(.onboardingWelcomeBeforeLabel), content: Text(dirtyURL))

            Image(systemName: "arrow.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)

            labeledRow(
                label: Text(.onboardingWelcomeAfterLabel),
                content: Text(verbatim: "www.example.com/products/sneakers").foregroundStyle(.tint)
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func labeledRow<Content: View>(label: Text, content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            label
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.1)
            content
                .font(.system(.subheadline, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    OnboardingWelcomePage(onContinue: {})
        .screenBackground()
}
