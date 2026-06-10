// Fetches LinkPresentation thumbnails for the History screenshot seed.
//
// Mirrors LinkMetadataService's image-then-icon fallback so each fixture is
// exactly what the app would have stored after a real clean. Outputs square
// 256px PNGs named <name>.png into Screenshots/fixtures/history/.
//
// Usage:
//   swiftc scripts/fetch-history-thumbnails.swift -o /tmp/fetch-thumbs \
//     -framework LinkPresentation -framework AppKit
//   /tmp/fetch-thumbs youtube=https://www.youtube.com/watch?v=… medium=https://…
//
// Re-run with new name=url pairs whenever the seeded items change; names must
// match the `thumbnail:` fixture names in LinkCleanApp.seedSampleHistory.

import AppKit
import Foundation
import LinkPresentation
import UniformTypeIdentifiers

let outputDirectory: URL = {
    let scriptDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    return scriptDirectory
        .deletingLastPathComponent()
        .appendingPathComponent("Screenshots/fixtures/history")
}()

func loadImageData(from provider: NSItemProvider?) -> Data? {
    guard let provider else { return nil }
    var result: Data? = nil
    let semaphore = DispatchSemaphore(value: 0)
    provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
        result = data
        semaphore.signal()
    }
    semaphore.wait()
    return result
}

func squareCroppedPNG(from data: Data, side: CGFloat = 256) -> Data? {
    guard let image = NSImage(data: data) else { return nil }
    var proposedRect = CGRect(origin: .zero, size: image.size)
    guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
        return nil
    }

    let width = CGFloat(cgImage.width)
    let height = CGFloat(cgImage.height)
    let cropSide = min(width, height)
    let cropRect = CGRect(
        x: (width - cropSide) / 2,
        y: (height - cropSide) / 2,
        width: cropSide,
        height: cropSide
    )
    guard let cropped = cgImage.cropping(to: cropRect) else { return nil }

    let target = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(side),
        pixelsHigh: Int(side),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )
    guard let target else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: target)
    NSGraphicsContext.current?.imageInterpolation = .high
    NSGraphicsContext.current?.cgContext.draw(
        cropped,
        in: CGRect(x: 0, y: 0, width: side, height: side)
    )
    NSGraphicsContext.restoreGraphicsState()
    return target.representation(using: .png, properties: [:])
}

let pairs: [(name: String, url: URL)] = CommandLine.arguments.dropFirst().compactMap { argument in
    let parts = argument.split(separator: "=", maxSplits: 1)
    guard parts.count == 2, let url = URL(string: String(parts[1])) else {
        FileHandle.standardError.write(Data("skipping malformed pair: \(argument)\n".utf8))
        return nil
    }
    return (String(parts[0]), url)
}

guard !pairs.isEmpty else {
    FileHandle.standardError.write(Data("usage: fetch-thumbs name=url [name=url …]\n".utf8))
    exit(1)
}

try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

var failures = 0

for (name, url) in pairs {
    print("fetching \(name): \(url.absoluteString)")
    let provider = LPMetadataProvider()
    provider.timeout = 20

    var metadata: LPLinkMetadata?
    let semaphore = DispatchSemaphore(value: 0)
    provider.startFetchingMetadata(for: url) { result, error in
        if let error {
            FileHandle.standardError.write(Data("  fetch failed: \(error.localizedDescription)\n".utf8))
        }
        metadata = result
        semaphore.signal()
    }
    // LP completes on a background queue; pump the main runloop while waiting.
    while semaphore.wait(timeout: .now()) == .timedOut {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    }

    guard let metadata else {
        failures += 1
        continue
    }

    var imageData = loadImageData(from: metadata.imageProvider)
    if imageData == nil {
        print("  no og image; falling back to icon")
        imageData = loadImageData(from: metadata.iconProvider)
    }
    guard let imageData, let png = squareCroppedPNG(from: imageData) else {
        FileHandle.standardError.write(Data("  no usable image for \(name)\n".utf8))
        failures += 1
        continue
    }

    let destination = outputDirectory.appendingPathComponent("\(name).png")
    do {
        try png.write(to: destination)
        print("  wrote \(destination.path) (title: \(metadata.title ?? "—"))")
    } catch {
        FileHandle.standardError.write(Data("  write failed: \(error)\n".utf8))
        failures += 1
    }
}

exit(failures == 0 ? 0 : 2)
