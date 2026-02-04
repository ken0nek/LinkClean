//
//  HomeView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/4/26.
//

import SwiftUI
import UIKit
import LinkCleanCommon

struct HomeView: View {
    @State private var inputText = ""
    @State private var copyTask: Task<Void, Never>?
    @State private var didCopy = false
    @State private var showClipboardToast = false
    @State private var toastTask: Task<Void, Never>?
    @State private var isHomeVisible = false
    @State private var didRunInitialPaste = false
    @FocusState private var isInputFocused: Bool
    @Environment(\.scenePhase) private var scenePhase

    private var isInputEmpty: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isInputValidURL: Bool {
        URLCleaner.isValidURL(inputText)
    }

    private var shouldShowInvalidInputMessage: Bool {
        !isInputEmpty && !isInputValidURL
    }

    private var cleanedText: String {
        guard !isInputEmpty, isInputValidURL else {
            return ""
        }

        return URLCleaner.clean(inputText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

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

    var body: some View {
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
                            inputText = ""
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
                        .disabled(isInputEmpty)
                        .accessibilityLabel("Clear input")
                    }

                    TextField("Paste a URL to clean", text: $inputText, axis: .vertical)
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
                        .onChange(of: inputText) { _, newValue in
                            if newValue.contains("\n") {
                                inputText = newValue.replacingOccurrences(of: "\n", with: "")
                                isInputFocused = false
                            }
                        }
                        .padding(12)
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(.white.opacity(0.08))
                        )

                    if shouldShowInvalidInputMessage {
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
                            copyCleanedURL()
                        } label: {
                            Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(didCopy ? .green : .primary)
                                .frame(width: 34, height: 34)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(cleanedText.isEmpty)
                        .symbolEffect(.bounce, value: didCopy)
                        .accessibilityLabel(didCopy ? "Copied" : "Copy cleaned URL")
                    }

                    Group {
                        if cleanedText.isEmpty {
                            Text("Cleaned URL will appear here")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(cleanedText)
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
            if showClipboardToast {
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
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Home")
        .onAppear {
            isHomeVisible = true
            if !didRunInitialPaste {
                didRunInitialPaste = true
                tryPasteFromClipboard()
            }
        }
        .onDisappear {
            isHomeVisible = false
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active, isHomeVisible else { return }
            tryPasteFromClipboard()
        }
    }

    private func copyCleanedURL() {
        guard !cleanedText.isEmpty else { return }
        UIPasteboard.general.string = cleanedText

        withAnimation(.easeInOut(duration: 0.2)) {
            didCopy = true
        }

        copyTask?.cancel()
        copyTask = Task {
            try? await Task.sleep(for: .seconds(1.4))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    didCopy = false
                }
            }
        }
    }

    private func tryPasteFromClipboard() {
        guard isInputEmpty else { return }

        let pasteboard = UIPasteboard.general
        let candidate = pasteboard.url?.absoluteString ?? pasteboard.string ?? ""
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard URLCleaner.isValidURL(trimmed) else {
            showInvalidClipboardToast()
            return
        }

        inputText = trimmed
        isInputFocused = false
    }

    private func showInvalidClipboardToast() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showClipboardToast = true
        }

        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showClipboardToast = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
