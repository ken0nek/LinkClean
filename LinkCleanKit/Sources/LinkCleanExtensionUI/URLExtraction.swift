//
//  URLExtraction.swift
//  LinkCleanExtensionUI
//
//  Created by Ken Tominaga on 6/11/26.
//

import Foundation
import UniformTypeIdentifiers
import OSLog
import LinkCleanCore

/// Pulls the first web URL out of share-sheet input. Pure of UIKit and of any
/// view controller — extraction is a value computation, so it (and the
/// strategies built on it) are testable directly.
public enum URLExtraction {

    /// First web URL across all attachments of the input items.
    public static func firstWebURL(from items: [NSExtensionItem]) async -> URL? {
        await firstWebURL(from: items.flatMap { $0.attachments ?? [] })
    }

    /// Returns the first web URL found in the providers. URL attachments from any
    /// provider are preferred over links parsed from plain text, so a host's
    /// canonical URL wins over a link embedded in caption text.
    public static func firstWebURL(from providers: [NSItemProvider]) async -> URL? {
        for provider in providers {
            if let url = await loadURL(from: provider), URLCleaner.isWebURL(url) {
                return url
            }
        }

        for provider in providers {
            if let text = await loadPlainText(from: provider),
                let url = URLCleaner.firstWebURL(in: text)
            {
                return url
            }
        }

        Log.action.debug("URLExtraction: no URL found in input items")
        return nil
    }

    /// `loadItem` returns whatever representation the host registered: an
    /// object (`NSURL`/`NSString`) for item-backed providers, raw URL bytes,
    /// or — for `init(object:)`-registered URLs — a plist payload that only
    /// `NSItemProviderReading` understands. Try each shape for every
    /// conforming identifier, then fall back to `loadObject`.
    private static func loadURL(from provider: NSItemProvider) async -> URL? {
        let conforming = registeredIdentifiers(conformingTo: .url, in: provider)
        guard !conforming.isEmpty else {
            return nil
        }

        // File-url identifiers go last: when a provider registers both, the
        // web representation is the one worth extracting.
        let identifiers = conforming.filter { UTType($0)?.conforms(to: .fileURL) != true }
            + conforming.filter { UTType($0)?.conforms(to: .fileURL) == true }

        for identifier in identifiers {
            switch try? await provider.loadItem(forTypeIdentifier: identifier) {
            case let url as URL:
                return url
            case let data as Data:
                if let url = URL(dataRepresentation: data, relativeTo: nil), url.scheme != nil {
                    return url
                }
            case let text as String:
                if let url = URL(string: text) {
                    return url
                }
            default:
                break
            }
        }

        return await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                continuation.resume(returning: url)
            }
        }
    }

    private static func loadPlainText(from provider: NSItemProvider) async -> String? {
        let identifiers = registeredIdentifiers(conformingTo: .plainText, in: provider)
        guard !identifiers.isEmpty else {
            return nil
        }

        for identifier in identifiers {
            switch try? await provider.loadItem(forTypeIdentifier: identifier) {
            case let text as String:
                return text
            case let data as Data:
                if let text = String(data: data, encoding: .utf8) {
                    return text
                }
            default:
                break
            }
        }

        return await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: String.self) { text, _ in
                continuation.resume(returning: text)
            }
        }
    }

    /// Hosts register concrete subtypes (`public.utf8-plain-text`,
    /// `public.file-url`), and `loadItem` wants a registered identifier,
    /// not a parent type.
    private static func registeredIdentifiers(conformingTo type: UTType, in provider: NSItemProvider) -> [String] {
        provider.registeredTypeIdentifiers.filter { identifier in
            UTType(identifier)?.conforms(to: type) == true
        }
    }
}
