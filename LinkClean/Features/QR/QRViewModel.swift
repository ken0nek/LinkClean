//
//  QRViewModel.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/14/26.
//

import Foundation
import LinkCleanAnalytics
import LinkCleanCore
import LinkCleanData
import Observation
import UIKit

/// Owns the QR scanner's logic: turn a decoded payload (from the live camera or a
/// picked image) into a cleaned link, then record the realized clean and emit the
/// surface signal. Mirrors the App Intents' "record at clean time" model — a scan
/// is high-intent, so its History + Stats are written on success, not on a later
/// export. Camera authorization and presentation are device/UI concerns the View
/// owns (as `StatsView` owns its `ImageRenderer`); this model is pure logic.
@MainActor
@Observable
final class QRViewModel {
    /// The cleaned result of the latest successful scan; drives the result sheet.
    var result: CleanOutcome?
    /// A transient failure to surface (no link in the code, unreadable image),
    /// cleared on the next scan or by ``dismissError()``.
    var scanError: AnalyticsEvent.QRFailureReason?
    var didCopy = false

    @ObservationIgnored private let service: CleaningService
    @ObservationIgnored private let analytics: AnalyticsService
    @ObservationIgnored private let history: HistoryStore
    @ObservationIgnored private let stats: StatsStore
    @ObservationIgnored private let recorder: RealizedCleanRecorder
    @ObservationIgnored private var copyTask: Task<Void, Never>?
    // Set synchronously on the first detection so the live scanner's repeated
    // frames don't enqueue duplicate cleans, and a result already on screen
    // suppresses new ones until it's dismissed.
    @ObservationIgnored private var isHandling = false
    // The last payload handled (success or failure). The live scanner re-fires
    // `didAdd` whenever a code leaves and re-enters frame — including right after
    // the result sheet is dismissed and scanning resumes — so without this an
    // unchanged code on screen would be cleaned/recorded twice (or a no-link code
    // would re-fire its failure every frame). A *different* payload resets the
    // gate, so scanning A → B → A still works.
    @ObservationIgnored private var lastHandledPayload: String?

    init(
        service: CleaningService = DefaultCleaningService(),
        analytics: AnalyticsService = TelemetryDeckAnalytics(),
        history: HistoryStore = .inMemoryPreview,
        stats: StatsStore = StatsStore()
    ) {
        self.service = service
        self.analytics = analytics
        self.history = history
        self.stats = stats
        self.recorder = RealizedCleanRecorder(analytics: analytics, stats: stats)
    }

    var hasResult: Bool { result != nil }
    var cleanedText: String { result?.cleaned ?? "" }
    var removedParameters: [String] { result?.display.removedNames ?? [] }

    /// The outermost redirect wrapper peeled before cleaning (e.g. the `google.com`
    /// of a `google.com/url?q=…` QR), or `nil` — drives the "redirect expanded"
    /// note, reading the analytics-safe ``CleanOutcome/Telemetry`` view.
    var unwrappedFromHost: String? { result?.telemetry.wrappers.first }

    /// The cleaned link as a `URL` for "Open", or `nil` if it won't parse.
    var cleanedURL: URL? {
        guard let cleaned = result?.cleaned else { return nil }
        return URL(string: cleaned)
    }

    /// Handles a decoded QR payload: pull the first web URL out of it (a QR may hold
    /// a bare URL or "label + link"), clean it through the shared engine, then
    /// record the realized clean (History + Stats) and emit ``AnalyticsEvent/qrScanSucceeded(telemetry:)``.
    /// A code with no web link surfaces ``AnalyticsEvent/QRFailureReason/noLink``.
    func handleScan(_ payload: String) {
        guard payload != lastHandledPayload else { return }
        guard result == nil, !isHandling else { return }
        lastHandledPayload = payload
        isHandling = true
        scanError = nil

        guard let url = URLCleaner.firstWebURL(in: payload) else {
            isHandling = false
            fail(.noLink)
            return
        }

        Task { [service, url] in
            let outcome = (try? await service.clean(url.absoluteString)) ?? nil
            isHandling = false
            guard let outcome else {
                fail(.noLink)
                return
            }
            result = outcome
            // Emit the success signal (and the catalog-gap fan-out) before the
            // slower Stats/History writes, matching the App Intents' ordering
            // (analytics §8) so the signal isn't delayed behind a SwiftData save.
            analytics.capture(.qrScanSucceeded(telemetry: outcome.telemetry))
            // The shared realized-clean tail (catalog-gap fan-out + lifetime Stats).
            // History is recorded here too, since a scan persists at clean time.
            recorder.record(outcome)
            history.record(outcome)
        }
    }

    /// Decodes a picked still image and routes its first QR through ``handleScan(_:)``.
    /// No QR at all in the image is ``AnalyticsEvent/QRFailureReason/unreadable`` —
    /// distinct from a QR that decoded but held no link.
    func handlePickedImage(_ data: Data) async {
        guard let payload = await QRImageScanner.firstPayload(in: data) else {
            fail(.unreadable)
            return
        }
        handleScan(payload)
    }

    func clearResult() {
        result = nil
        didCopy = false
        copyTask?.cancel()
    }

    func dismissError() {
        scanError = nil
    }

    func copyCleanedURL() {
        guard let cleaned = result?.cleaned, !cleaned.isEmpty else { return }
        UIPasteboard.general.string = cleaned
        analytics.capture(.qrResultActioned(.copy))
        didCopy = true
        copyTask?.cancel()
        copyTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            didCopy = false
        }
    }

    /// Records a Share of the scan result. The `ShareLink` fires this at
    /// initiation (it has no completion callback), like Home and History.
    func recordShare() {
        guard !cleanedText.isEmpty else { return }
        analytics.capture(.qrResultActioned(.share))
    }

    /// Records an Open-in-browser of the scan result; the View owns the actual
    /// `openURL`. Only reachable while ``cleanedURL`` is non-nil.
    func recordOpen() {
        analytics.capture(.qrResultActioned(.open))
    }

    private func fail(_ reason: AnalyticsEvent.QRFailureReason) {
        scanError = reason
        analytics.capture(.qrScanFailed(reason: reason))
    }
}
