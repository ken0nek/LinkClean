//
//  CopyFormatEditorView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/14/26.
//

import SwiftUI
import LinkCleanCore

/// Authors or edits a custom link format. A multi-line format field over token
/// chips (tap to append a `{placeholder}`) and a **live preview** against a sample
/// dirty link, so the user sees what the format produces before saving
/// (`copy-as-you-want` §6.5). Pure editing — the Pro gate already happened at the
/// "New Format" entry, so reaching this screen means authoring is allowed.
struct CopyFormatEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let initialDraft: LinkTemplate
    private let onSave: (LinkTemplate) -> Void

    @State private var name: String
    @State private var format: String

    init(draft: LinkTemplate, onSave: @escaping (LinkTemplate) -> Void) {
        self.initialDraft = draft
        self.onSave = onSave
        _name = State(initialValue: draft.name)
        _format = State(initialValue: draft.format)
    }

    /// The placeholders offered as one-tap chips — the headline set; the rest
    /// (`{scheme}`, `{path}`, `{query}`, `{time}`, `{newline}`, `{tab}`) can be
    /// typed, and any unknown `{x}` is left literal by the renderer.
    private let tokens: [TemplateToken] = [.link, .title, .host, .date, .removedCount, .originalLink, .markdown]

    private var isNew: Bool { initialDraft.name.isEmpty }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !format.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var previewText: String {
        TemplateRenderer.render(format: format, .sample)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: .copyFormatEditorNamePlaceholder), text: $name)
                        .accessibilityIdentifier("copy-format-name")
                } header: {
                    Text(.copyFormatEditorNameHeader)
                }

                Section {
                    TextField(
                        text: $format,
                        prompt: Text(verbatim: "[{title}]({link})"),
                        axis: .vertical
                    ) { EmptyView() }
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .lineLimit(3...8)
                        .accessibilityIdentifier("copy-format-format")
                } header: {
                    Text(.copyFormatEditorFormatHeader)
                }

                Section {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(tokens, id: \.self) { token in
                                Button {
                                    format += "{\(token.rawValue)}"
                                } label: {
                                    Text(verbatim: "{\(token.rawValue)}")
                                        .font(.system(.footnote, design: .monospaced))
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .scrollIndicators(.hidden)
                } header: {
                    Text(.copyFormatEditorTokensHeader)
                } footer: {
                    Text(.copyFormatEditorTokensFooter)
                }

                Section {
                    Text(previewText.isEmpty ? " " : previewText)
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } header: {
                    Text(.copyFormatEditorPreviewHeader)
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle(isNew ? Text(.copyFormatEditorNewTitle) : Text(.copyFormatEditorEditTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text(.commonCancel) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave(LinkTemplate.custom(id: initialDraft.id, name: name, format: format))
                        dismiss()
                    } label: {
                        Text(.copyFormatEditorSave)
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier("copy-format-save")
                }
            }
        }
    }
}

#Preview {
    CopyFormatEditorView(draft: .custom(id: UUID(), name: "", format: "{title}\n{link}")) { _ in }
}
