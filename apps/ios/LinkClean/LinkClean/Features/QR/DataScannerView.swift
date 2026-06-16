//
//  DataScannerView.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/14/26.
//

import SwiftUI
import Vision
import VisionKit

/// A thin SwiftUI host for VisionKit's `DataScannerViewController` — the native
/// live-camera scanner (no third-party library) — restricted to QR codes. UIKit is
/// unavoidable here: there is no SwiftUI equivalent for the live data scanner. The
/// owner gates duplicate handling; this forwards every recognition it sees.
struct DataScannerView: UIViewControllerRepresentable {
    /// When false (a result is on screen), scanning is paused so the camera and
    /// Vision pipeline idle instead of running behind the result sheet.
    var isActive: Bool = true
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        if isActive {
            try? scanner.startScanning()
        } else {
            scanner.stopScanning()
        }
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        scanner.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    @MainActor
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String) -> Void

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(
            _ scanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            forwardFirstBarcode(in: addedItems)
        }

        func dataScanner(_ scanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            forwardFirstBarcode(in: [item])
        }

        private func forwardFirstBarcode(in items: [RecognizedItem]) {
            for case let .barcode(barcode) in items {
                guard let payload = barcode.payloadStringValue else { continue }
                onScan(payload)
                return
            }
        }
    }
}
