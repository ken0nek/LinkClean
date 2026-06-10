import AppKit
import SwiftUI

struct ScreenshotComposer: View {
    let caption: CaptionContent
    let rawScreen: NSImage
    let device: Device

    struct Layout {
        let topPadding: CGFloat
        let bottomPadding: CGFloat
        let captionHorizontalPadding: CGFloat
        let captionMaxWidth: CGFloat
        let captionToScreenGap: CGFloat
        let headlineSize: CGFloat
        let screenWidth: CGFloat
        let screenHeight: CGFloat
        let screenCornerRadius: CGFloat

        static let iphone69 = Layout(
            topPadding: 170,
            bottomPadding: 90,
            captionHorizontalPadding: 80,
            captionMaxWidth: 1120,
            captionToScreenGap: 64,
            headlineSize: 94,
            screenWidth: 1058,
            screenHeight: 2298,
            screenCornerRadius: 56
        )

        static let ipad13 = Layout(
            topPadding: 90,
            bottomPadding: 45,
            captionHorizontalPadding: 180,
            captionMaxWidth: 1700,
            captionToScreenGap: 72,
            headlineSize: 116,
            screenWidth: 1650,
            screenHeight: 2200,
            screenCornerRadius: 56
        )
    }

    private static let brandBackground = Color(red: 0.035, green: 0.36, blue: 0.32)

    var body: some View {
        let layout = device.layout

        ZStack {
            Self.brandBackground

            VStack(spacing: 0) {
                Spacer(minLength: layout.topPadding)

                Text(caption.headline)
                    .font(.system(size: layout.headlineSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: layout.captionMaxWidth)
                    .padding(.horizontal, layout.captionHorizontalPadding)

                Color.clear.frame(height: layout.captionToScreenGap)

                Image(nsImage: rawScreen)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: layout.screenWidth, height: layout.screenHeight)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: layout.screenCornerRadius,
                            style: .continuous
                        )
                    )
                    .shadow(color: .black.opacity(0.22), radius: 34, y: 16)

                Spacer(minLength: layout.bottomPadding)
            }
        }
        .frame(width: device.canvasSize.width, height: device.canvasSize.height)
    }
}
