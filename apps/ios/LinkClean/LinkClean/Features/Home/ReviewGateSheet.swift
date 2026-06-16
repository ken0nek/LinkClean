//
//  ReviewGateSheet.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/9/26.
//

import SwiftUI

/// Which rating the user gave the in-app star prompt. Dismissals (a "Not now" tap
/// or an interactive swipe) aren't outcomes here — the host detects them via the
/// sheet's `onDismiss` plus the absence of a rating, so both routes are counted
/// uniformly and `requestReview()` can be deferred until the sheet is fully gone.
enum ReviewGateOutcome {
    /// ≥ 4 stars — route to Apple's system review prompt.
    case ratedHigh
    /// ≤ 3 stars — thank the user, no public rating.
    case ratedLow
}

/// In-app star sheet shown before Apple's system review prompt.
///
/// ≥ 4 stars: dismisses and reports `.ratedHigh`. ≤ 3 stars: shows a brief
/// "thanks" and auto-dismisses — no follow-up. "Not now" and swipe-away just
/// dismiss; the host treats any dismissal without a rating as a decline.
struct ReviewGateSheet: View {
    private static let thanksAutoDismissDelay: Duration = .milliseconds(1200)

    @Environment(\.dismiss) private var dismiss
    let onRating: (ReviewGateOutcome) -> Void

    @State private var selectedRating = 0
    @State private var showingThanks = false
    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        VStack {
            if showingThanks {
                thanksContent
            } else {
                gateContent
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
        .onDisappear {
            autoDismissTask?.cancel()
            autoDismissTask = nil
        }
    }

    private var gateContent: some View {
        VStack(spacing: 14) {
            Text(.reviewGateTitle)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)

            Text(.reviewGateSubtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 4)

            HStack(spacing: 16) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        select(rating: rating)
                    } label: {
                        Image(systemName: rating <= selectedRating ? "star.fill" : "star")
                            .font(.system(size: 30))
                            .foregroundStyle(.yellow)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(.reviewGateStarAccessibility(rating)))
                }
            }
            .padding(.vertical, 4)

            Button {
                dismiss()
            } label: {
                Text(.reviewGateDismiss)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var thanksContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 38))
                .foregroundStyle(.pink)
            Text(.reviewGateThanks)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
        }
    }

    private func select(rating: Int) {
        selectedRating = rating
        if rating >= 4 {
            onRating(.ratedHigh)
            dismiss()
        } else {
            onRating(.ratedLow)
            withAnimation(.easeInOut(duration: 0.25)) {
                showingThanks = true
            }
            autoDismissTask = Task { @MainActor in
                try? await Task.sleep(for: Self.thanksAutoDismissDelay)
                guard !Task.isCancelled else { return }
                dismiss()
            }
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ReviewGateSheet { _ in }
        }
}
