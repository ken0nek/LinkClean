//
//  QRCodeSheet.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/14/26.
//

import SwiftUI

/// The "generate" half of the QR feature, reached from Home: turns a cleaned link
/// into a QR big enough to scan off-screen, with a `ShareLink` to send it as a PNG.
/// `onShare` records the share (`ShareLink` has no completion callback), mirroring
/// the other share hooks (`HomeView`, `StatsView`).
struct QRCodeSheet: View {
    let link: String
    let onShare: () -> Void
    @Environment(\.dismiss) private var dismiss

    /// Rendered once per link in `.task(id:)`: the display `Image` and the
    /// shareable PNG package. `nil` if the link can't be encoded.
    @State private var rendered: Rendered?

    private struct Rendered {
        let display: Image
        let shareable: ShareableQRCode
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer(minLength: 0)
                code
                Spacer(minLength: 0)
                if let rendered {
                    ShareLink(
                        item: rendered.shareable,
                        preview: SharePreview(Text(.qrShareTitle), image: rendered.display)
                    ) {
                        Label {
                            Text(.historyCellShare)
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .primaryButtonLabel()
                    }
                    .simultaneousGesture(TapGesture().onEnded { onShare() })
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .screenBackground()
            .navigationTitle(Text(.qrShareTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Text(.commonClose) }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task(id: link) { rendered = Self.render(link) }
    }

    @ViewBuilder
    private var code: some View {
        if let rendered {
            VStack(spacing: 16) {
                rendered.display
                    .interpolation(.none)   // keep the modules hard-edged when scaled
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260, maxHeight: 260)
                    .padding(20)
                    .background(.white, in: .rect(cornerRadius: 24))
                    .accessibilityLabel(Text(.qrShareTitle))

                Text(link)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.center)
            }
        } else {
            ContentUnavailableView {
                Label { Text(.qrErrorUnreadable) } icon: { Image(systemName: "qrcode") }
            }
        }
    }

    private static func render(_ link: String) -> Rendered? {
        guard let uiImage = QRCodeGenerator.image(for: link, scale: 20),
              let pngData = uiImage.pngData() else { return nil }
        let image = Image(uiImage: uiImage)
        return Rendered(display: image, shareable: ShareableQRCode(image: image, pngData: pngData))
    }
}
