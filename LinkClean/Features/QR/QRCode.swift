//
//  QRCode.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/14/26.
//

import CoreImage.CIFilterBuiltins
import ImageIO
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import Vision

/// QR-code primitives, all native (no third-party): Core Image for generation,
/// the Vision framework for decoding a QR in a still image. The live-camera path
/// is ``DataScannerView``; this file is the still-image + generation half, so it
/// is unit-testable and works in the Simulator (which has no camera).
enum QRCodeGenerator {
    /// Renders `string` as a crisp, opaque QR `UIImage`, or `nil` if it can't be
    /// encoded. Core Image emits a tiny image (one point per module); we scale it
    /// up with the default (nearest-neighbour) sampling so the modules stay
    /// hard-edged instead of blurring, then bake it into a `UIImage`.
    static func image(for string: String, scale: CGFloat = 12) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"   // 15% recovery — the QR default, ample for a link
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

enum QRImageScanner {
    /// The first QR payload decoded from still-image `data` (a picked photo or a
    /// screenshot), or `nil` if there is none. Uses Vision's Swift
    /// `DetectBarcodesRequest` (iOS 18+), restricted to QR — the same engine the
    /// live `DataScannerViewController` runs, but over a single image.
    static func firstPayload(in data: Data) async -> String? {
        var request = DetectBarcodesRequest()
        request.symbologies = [.qr]
        guard let observations = try? await request.perform(on: data, orientation: .up) else {
            return nil
        }
        return observations.compactMap(\.payloadString).first
    }
}

/// A generated QR packaged for sharing — PNG bytes for a real, named file plus the
/// `Image` for the share-sheet preview. Mirrors `SharePrivacyCard` (V3): some share
/// targets only accept a file, not a bare in-memory `Image`.
struct ShareableQRCode: Transferable {
    let image: Image
    let pngData: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { $0.pngData }
            .suggestedFileName("LinkClean-QR.png")
    }
}
