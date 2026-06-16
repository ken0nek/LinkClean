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
    let rawInputRoot = repositoryRoot
        .appendingPathComponent("screenshots/raw/en-US")
    let outputRoot = repositoryRoot
        .appendingPathComponent("fastlane/screenshots/en-US")
    let captionsURL = sourceDirectory.appendingPathComponent("captions.json")

    let captions: CaptionsByFrame
    do {
        captions = try Captions.load(from: captionsURL)
    } catch {
        logError("failed to load captions at \(captionsURL.path): \(error)")
        return 1
    }

    try? FileManager.default.createDirectory(
        at: outputRoot,
        withIntermediateDirectories: true
    )

    var written = 0
    var skipped = 0

    for device in Device.allCases {
        for frame in ScreenshotFrame.allCases {
            guard let caption = captions[frame.rawValue] else {
                logError("skip \(frame.rawValue): caption is missing")
                skipped += 1
                continue
            }

            let rawURL = rawInputRoot
                .appendingPathComponent(device.rawValue)
                .appendingPathComponent("\(frame.rawValue).png")
            guard let rawScreen = NSImage(contentsOf: rawURL) else {
                logError("skip \(device.rawValue)/\(frame.rawValue): no raw input at \(rawURL.path)")
                skipped += 1
                continue
            }

            let view = ScreenshotComposer(
                caption: caption,
                rawScreen: rawScreen,
                device: device
            )
            guard let pngData = Renderer.renderPNG(view) else {
                logError("failed to render \(device.rawValue)/\(frame.rawValue)")
                return 2
            }

            let outputURL = outputRoot
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

    print("done: \(written) written, \(skipped) skipped")
    return 0
}

let status = MainActor.assumeIsolated { runScreenshots() }
exit(status)
