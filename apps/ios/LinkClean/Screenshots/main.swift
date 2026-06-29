import AppKit
import Foundation
import SwiftUI

@MainActor
func runScreenshots() -> Int32 {
    _ = NSApplication.shared

    func logError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }

    let sourceDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    let repositoryRoot = sourceDirectory.deletingLastPathComponent()
    let rawInputRoot = repositoryRoot.appendingPathComponent("screenshots/raw")
    let outputRoot = repositoryRoot.appendingPathComponent("fastlane/screenshots")
    let captionsURL = sourceDirectory.appendingPathComponent("captions.json")

    // The reference locale always has committed raws, so a locale that hasn't
    // been recaptured yet still composites — its localized caption over the
    // en-US screen — until its own raws land under screenshots/raw/<locale>/.
    let fallbackLocale = "en-US"

    let captionsByLocale: CaptionsByLocale
    do {
        captionsByLocale = try Captions.load(from: captionsURL)
    } catch {
        logError("failed to load captions at \(captionsURL.path): \(error)")
        return 1
    }

    var written = 0
    var skipped = 0

    for locale in captionsByLocale.keys.sorted() {
        guard let captions = captionsByLocale[locale] else { continue }

        let localeOutputRoot = outputRoot.appendingPathComponent(locale)
        try? FileManager.default.createDirectory(
            at: localeOutputRoot,
            withIntermediateDirectories: true
        )

        for device in Device.allCases {
            for frame in ScreenshotFrame.allCases {
                guard let caption = captions[frame.rawValue]
                    ?? captionsByLocale[fallbackLocale]?[frame.rawValue]
                else {
                    logError("skip \(locale)/\(frame.rawValue): caption is missing")
                    skipped += 1
                    continue
                }

                // Prefer the locale's own raw; fall back to the en-US screen
                // when this frame hasn't been captured in this language yet.
                let localeRawURL = rawInputRoot
                    .appendingPathComponent(locale)
                    .appendingPathComponent(device.rawValue)
                    .appendingPathComponent("\(frame.rawValue).png")
                let fallbackRawURL = rawInputRoot
                    .appendingPathComponent(fallbackLocale)
                    .appendingPathComponent(device.rawValue)
                    .appendingPathComponent("\(frame.rawValue).png")

                let rawURL: URL
                if FileManager.default.fileExists(atPath: localeRawURL.path) {
                    rawURL = localeRawURL
                } else if locale != fallbackLocale,
                    FileManager.default.fileExists(atPath: fallbackRawURL.path) {
                    rawURL = fallbackRawURL
                    print("note \(locale)/\(device.rawValue)/\(frame.rawValue): no localized raw, using \(fallbackLocale) screen")
                } else {
                    logError("skip \(locale)/\(device.rawValue)/\(frame.rawValue): no raw input at \(localeRawURL.path)")
                    skipped += 1
                    continue
                }

                guard let rawScreen = NSImage(contentsOf: rawURL) else {
                    logError("skip \(locale)/\(device.rawValue)/\(frame.rawValue): unreadable raw at \(rawURL.path)")
                    skipped += 1
                    continue
                }

                let view = ScreenshotComposer(
                    caption: caption,
                    rawScreen: rawScreen,
                    device: device
                )
                guard let pngData = Renderer.renderPNG(view) else {
                    logError("failed to render \(locale)/\(device.rawValue)/\(frame.rawValue)")
                    return 2
                }

                let outputURL = localeOutputRoot
                    .appendingPathComponent("\(device.outputPrefix)\(frame.outputSuffix).png")
                do {
                    try pngData.write(to: outputURL)
                    print("wrote \(outputURL.path) (\(pngData.count) bytes)")
                    written += 1
                } catch {
                    logError("failed to write \(outputURL.path): \(error)")
                    return 2
                }
            }
        }
    }

    print("done: \(written) written, \(skipped) skipped")
    return 0
}

let status = MainActor.assumeIsolated { runScreenshots() }
exit(status)
