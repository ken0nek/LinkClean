//
//  HomeView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import LinkCleanCommon
import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @FocusState private var isInputFocused: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    private var cardBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(.secondarySystemBackground),
                Color(.tertiarySystemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    init(viewModel: HomeViewModel = HomeViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Input URL")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.1)

                        Spacer()

                        Button {
                            viewModel.clearInput()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 34, height: 34)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isInputEmpty)
                        .accessibilityLabel("Clear input")
                    }

                    TextField("Paste a URL to clean", text: $viewModel.inputText, axis: .vertical)
                        .lineLimit(1...8)
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
                        .padding(12)
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(.white.opacity(0.08))
                        )

                    if viewModel.shouldShowInvalidInputMessage {
                        Text("Enter a valid URL")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Clean URL")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.1)

                        Spacer()

                        Button {
                            viewModel.copyCleanedURL()
                            if viewModel.isSaveHistoryEnabled, let cleanedURL = viewModel.cleanedURL {
                                let entry = HistoryEntry(input: cleanedURL.input, output: cleanedURL.output)
                                modelContext.insert(entry)
                            }
                        } label: {
                            Image(systemName: viewModel.didCopy ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(viewModel.didCopy ? .green : .primary)
                                .frame(width: 34, height: 34)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.cleanedText.isEmpty)
                        .symbolEffect(.bounce, value: viewModel.didCopy)
                        .accessibilityLabel(viewModel.didCopy ? "Copied" : "Copy cleaned URL")
                    }

                    Group {
                        if viewModel.cleanedText.isEmpty {
                            Text("Cleaned URL will appear here")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(viewModel.cleanedText)
                                .foregroundStyle(.tint)
                                .textSelection(.enabled)
                        }
                    }
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
            }
            .padding(20)
            .background(cardBackground, in: .rect(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.08))
            )
            .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 12)
            .padding()
        }
        .overlay(alignment: .top) {
            if viewModel.showClipboardToast {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Clipboard doesn’t contain a valid URL")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.12))
                )
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .screenBackground()
        .navigationTitle("Home")
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
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
