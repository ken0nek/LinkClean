//
//  QRScannerScreen.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/14/26.
//

import AVFoundation
import LinkCleanCore
import PhotosUI
import SwiftUI
import VisionKit

/// The full-screen QR scanner (the QR surface): the native live camera scanner
/// when the device supports it and the camera is permitted, a still-image fallback
/// (Photos) that always works — including the Simulator — and the cleaned result
/// in a sheet. Camera authorization is transient device/presentation state, so the
/// View owns it (as `StatsView` owns its `ImageRenderer`); the model is pure logic.
struct QRScannerScreen: View {
    @State private var viewModel: QRViewModel
    @State private var cameraState: CameraState = .checking
    @State private var photoItem: PhotosPickerItem?
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    init(deps: AppDependencies) {
        _viewModel = State(initialValue: QRViewModel(deps: deps))
    }

    private enum CameraState {
        case checking    // resolving support + authorization
        case scanning    // live camera up
        case denied      // camera access refused — offer Settings + Photos
        case unsupported // no camera (Simulator / capability) — Photos only
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            cameraLayer
            overlay
        }
        .task { await prepareCamera() }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await viewModel.handlePickedImage(data)
                }
                photoItem = nil
            }
        }
        .sheet(
            isPresented: Binding(
                get: { viewModel.hasResult },
                set: { if !$0 { viewModel.clearResult() } }
            )
        ) {
            QRResultView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Camera

    @ViewBuilder
    private var cameraLayer: some View {
        if cameraState == .scanning {
            // Pause scanning while a result sheet is up: idles the camera, and on
            // dismiss + resume the re-detected code is deduped by the view model.
            DataScannerView(isActive: !viewModel.hasResult, onScan: viewModel.handleScan)
                .ignoresSafeArea()
        }
    }

    private func prepareCamera() async {
        guard DataScannerViewController.isSupported else {
            cameraState = .unsupported
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraState = .scanning
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraState = granted ? .scanning : .denied
        case .restricted:
            // Parental controls / MDM restrict the camera and the user can't lift
            // it in Settings, so an "Open Settings" CTA would dead-end — fall back
            // to the Photos path, like a device with no camera.
            cameraState = .unsupported
        default:
            cameraState = .denied
        }
    }

    // MARK: - Overlay

    private var overlay: some View {
        VStack(spacing: 0) {
            topBar
            Spacer()
            if cameraState == .denied || cameraState == .unsupported {
                statusContent
                Spacer()
            }
            footer
        }
        .padding(20)
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: .circle)
            }
            .accessibilityLabel(Text(.commonClose))

            Spacer()

            Text(.qrScanTitle)
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            // Balances the close button so the title stays centered.
            Color.clear.frame(width: 44, height: 44)
        }
    }

    /// Shown only when there's no live camera: why, plus the way forward.
    private var statusContent: some View {
        VStack(spacing: 14) {
            Image(systemName: cameraState == .denied ? "video.slash.fill" : "qrcode.viewfinder")
                .font(.system(size: 52))
                .foregroundStyle(.white.opacity(0.85))

            Text(cameraState == .denied ? .qrScanDeniedTitle : .qrScanUnavailableTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text(cameraState == .denied ? .qrScanDeniedMessage : .qrScanUnavailableMessage)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            if cameraState == .denied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Text(.qrScanSettings)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
    }

    private var footer: some View {
        VStack(spacing: 16) {
            if let scanError = viewModel.scanError {
                errorBanner(scanError)
            }
            if cameraState == .scanning {
                Text(.qrScanInstruction)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label {
                    Text(.qrScanPhotos)
                } icon: {
                    Image(systemName: "photo.on.rectangle")
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(.ultraThinMaterial, in: .capsule)
            }
        }
    }

    private func errorBanner(_ reason: AnalyticsEvent.QRFailureReason) -> some View {
        Label {
            Text(reason == .noLink ? .qrErrorNoLink : .qrErrorUnreadable)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: .capsule)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task(id: reason) {
            try? await Task.sleep(for: .seconds(2.5))
            viewModel.dismissError()
        }
    }
}
