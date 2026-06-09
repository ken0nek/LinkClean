//
//  HomeView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import LinkCleanKit
import StoreKit
import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @FocusState private var isInputFocused: Bool
    @State private var isRemovedExpanded = false
    @State private var parameterPendingAdd: String?
    /// Bumped on a confirmed leftover-add so `.sensoryFeedback` fires a success tap.
    @State private var leftoverAddedHaptic = 0
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview

    init(viewModel: HomeViewModel = HomeViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                inputSection

                resultCard

                if !viewModel.cleanedText.isEmpty {
                    actionBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !viewModel.leftoverParameters.isEmpty {
                    leftoverSection
                        .transition(.opacity)
                }
            }
            .padding(20)
            .animation(.snappy(duration: 0.28), value: viewModel.cleanedText)
            .animation(.snappy(duration: 0.28), value: viewModel.leftoverParameters)
        }
        .scrollDismissesKeyboard(.interactively)
        .overlay(alignment: .top) { clipboardToast }
        .screenBackground()
        .navigationTitle(Text(.homeTitle))
        .task {
            viewModel.setModelContext(modelContext)
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            viewModel.handleSceneBecameActive()
        }
        .onChange(of: viewModel.focusResetToken) { _, _ in
            isInputFocused = false
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.showClipboardToast)
        .animation(.easeInOut(duration: 0.2), value: viewModel.didCopy)
        // Tactile feedback for the core moments: copy succeeded, a tracker was
        // promoted to always-remove, and the clipboard held something unusable.
        .sensoryFeedback(trigger: viewModel.didCopy) { _, didCopy in didCopy ? .success : nil }
        .sensoryFeedback(.success, trigger: leftoverAddedHaptic)
        .sensoryFeedback(trigger: viewModel.showClipboardToast) { _, shown in shown ? .warning : nil }
        .alert(
            Text(.homeLeftoverConfirmTitle),
            isPresented: Binding(
                get: { parameterPendingAdd != nil },
                set: { isPresented in
                    if !isPresented {
                        parameterPendingAdd = nil
                    }
                }
            )
        ) {
            Button {
                if let parameterPendingAdd {
                    viewModel.addLeftoverParameter(parameterPendingAdd)
                    leftoverAddedHaptic += 1
                }
                parameterPendingAdd = nil
            } label: {
                Text(.homeLeftoverConfirmAction)
            }
            Button(role: .cancel) {
                parameterPendingAdd = nil
            } label: {
                Text(.commonCancel)
            }
        } message: {
            if let parameterPendingAdd {
                Text(.homeLeftoverConfirmMessage(parameterPendingAdd))
            }
        }
        .sheet(
            isPresented: Binding(
                get: { viewModel.showReviewGate },
                set: { viewModel.showReviewGate = $0 }
            ),
            onDismiss: {
                // Fire Apple's prompt only after our sheet is fully gone — calling
                // requestReview() mid-dismiss makes iOS silently drop it.
                if viewModel.reviewGateDidDismiss() {
                    requestReview()
                }
            }
        ) {
            ReviewGateSheet { outcome in
                viewModel.handleReviewRating(outcome)
            }
        }
    }

    // MARK: - Input

    private var inputSection: some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 8) {
            sectionHeader(.homeInputHeader)

            HStack(alignment: .top, spacing: 4) {
                TextField(String(localized: .homeInputPlaceholder), text: $viewModel.inputText, axis: .vertical)
                    .lineLimit(1...6)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($isInputFocused)
                    .accessibilityIdentifier("input-url")
                    .onSubmit {
                        isInputFocused = false
                    }
                    .padding(.vertical, 10)

                if !viewModel.isInputEmpty {
                    Button {
                        viewModel.clearInput()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(.homeInputClear))
                    .accessibilityIdentifier("clear-input")
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, viewModel.isInputEmpty ? 16 : 6)
            .glassEffect(.regular, in: .rect(cornerRadius: 22))

            if viewModel.shouldShowInvalidInputMessage {
                Label {
                    Text(.homeInputInvalid)
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            }
        }
    }

    // MARK: - Result

    /// The cleaned link, presented calmly with a tappable proof-of-work badge.
    /// Actions live in ``actionBar`` below, so the card stays read-only.
    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                sectionHeader(.homeCleanedHeader)
                Spacer()
                if !viewModel.removedParameters.isEmpty {
                    removedBadge
                }
            }

            Group {
                if viewModel.cleanedText.isEmpty {
                    Text(.homeCleanedPlaceholder)
                        .foregroundStyle(.secondary)
                } else {
                    Text(viewModel.cleanedText)
                        .foregroundStyle(.tint)
                        .textSelection(.enabled)
                }
            }
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)

            if isRemovedExpanded, !viewModel.removedParameters.isEmpty {
                Text(viewModel.removedParameters.joined(separator: "   ·   "))
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 26)
    }

    /// Calm proof-of-work: "✓ N removed" as a tinted pill, tappable to reveal the
    /// exact names. Informational only — no undo (see `docs/TODO.md`).
    private var removedBadge: some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) {
                isRemovedExpanded.toggle()
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.tint)

                Text(verbatim: "\(viewModel.removedParameters.count)")
                    .monospacedDigit()

                Text(.homeRemovedHeader)
                    .textCase(.uppercase)
                    .tracking(0.6)

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .rotationEffect(.degrees(isRemovedExpanded ? 180 : 0))
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.tint.opacity(0.14), in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(.homeRemovedHeader))
        .accessibilityValue(Text(verbatim: "\(viewModel.removedParameters.count)"))
        .accessibilityHint(Text(.homeRemovedHint))
    }

    /// The hero: a prominent Copy CTA plus a Share action, floating on the
    /// background just below the result so the payoff is the obvious next step.
    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.copyCleanedURL()
            } label: {
                Label {
                    Text(viewModel.didCopy ? .commonCopied : .homeCopyAction)
                } icon: {
                    Image(systemName: viewModel.didCopy ? "checkmark" : "doc.on.doc")
                }
                .primaryButtonLabel()
            }
            .buttonStyle(.glassProminent)
            .symbolEffect(.bounce, value: viewModel.didCopy)
            .accessibilityIdentifier("copy-cleaned-url")

            ShareLink(item: viewModel.cleanedText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                    .frame(minWidth: 28)
            }
            .buttonStyle(.glass)
            .simultaneousGesture(TapGesture().onEnded { viewModel.recordShare() })
            .accessibilityLabel(Text(.historyCellShare))
            .accessibilityIdentifier("share-cleaned-url")
        }
        .controlSize(.large)
    }

    // MARK: - Remaining (leftover) trackers

    /// Actionable: parameters that survived cleaning. Tapping one opens a confirm
    /// dialog to always-remove it. Glass chips grouped in a container so they
    /// render and blend as one cohesive set.
    private var leftoverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                sectionHeader(.homeLeftoverHeader)

                Text(.homeLeftoverPrompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GlassEffectContainer(spacing: 10) {
                VStack(spacing: 10) {
                    ForEach(viewModel.leftoverParameters, id: \.self) { name in
                        leftoverRow(name)
                    }
                }
            }
        }
    }

    private func leftoverRow(_ name: String) -> some View {
        Button {
            parameterPendingAdd = name
        } label: {
            HStack(spacing: 12) {
                Text(name)
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 8)

                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(.rect)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(.homeLeftoverRemove(name)))
        .accessibilityIdentifier("leftover-tracker-\(name)")
    }

    // MARK: - Toast

    @ViewBuilder
    private var clipboardToast: some View {
        if viewModel.showClipboardToast {
            Label {
                Text(.homeClipboardToast)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .glassEffect(.regular, in: .capsule)
            .padding(.top, 12)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ key: LocalizedStringResource) -> some View {
        Text(key)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(1.1)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
