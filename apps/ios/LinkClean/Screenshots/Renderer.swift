import AppKit
import SwiftUI

enum Renderer {
    @MainActor
    static func renderPNG(_ view: some View) -> Data? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        renderer.isOpaque = true
        guard let image = renderer.cgImage else { return nil }

        let bitmap = NSBitmapImageRep(cgImage: image)
        bitmap.size = NSSize(width: image.width, height: image.height)
        return bitmap.representation(using: .png, properties: [:])
    }
}
