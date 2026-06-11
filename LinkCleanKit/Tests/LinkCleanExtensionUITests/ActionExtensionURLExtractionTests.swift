//
//  ActionExtensionURLExtractionTests.swift
//  LinkCleanExtensionUITests
//
//  Created by Ken Tominaga on 2/2/26.
//

// LinkCleanExtensionUI links UIKit, so these tests compile and run only on the
// simulator (the sim lane). On the macOS fast lane (`swift test`) the module is
// absent and this target builds to an empty test bundle — see Package.swift.
#if canImport(UIKit)
import Testing
import Foundation
import UniformTypeIdentifiers
@testable import LinkCleanExtensionUI

struct ActionExtensionURLExtractionTests {

    @Test func extractsURLAttachment() async {
        let provider = NSItemProvider(object: NSURL(string: "https://example.com/page?utm_source=x")!)
        let result = await ActionExtensionViewController.extractURL(from: [provider])
        #expect(result == URL(string: "https://example.com/page?utm_source=x"))
    }

    @Test func extractsURLFromPlainText() async {
        // Item-backed plain text registers no URL representation, so this
        // exercises the text-scanning branch (LinkedIn-style bare link
        // string). NSItemProvider(object:) of a pure-URL NSString would
        // also register public.url and take the URL-attachment path.
        let provider = NSItemProvider(
            item: "https://www.linkedin.com/posts/example-123/?utm_source=social_share_send" as NSString,
            typeIdentifier: UTType.plainText.identifier
        )
        let result = await ActionExtensionViewController.extractURL(from: [provider])
        #expect(result == URL(string: "https://www.linkedin.com/posts/example-123/?utm_source=social_share_send"))
    }

    @Test func extractsItemBackedURL() async {
        // UIActivityViewController hosts register the object itself.
        let provider = NSItemProvider(
            item: NSURL(string: "https://example.com/item-backed"),
            typeIdentifier: UTType.url.identifier
        )
        let result = await ActionExtensionViewController.extractURL(from: [provider])
        #expect(result == URL(string: "https://example.com/item-backed"))
    }

    @Test func extractsItemBackedPlainText() async {
        let provider = NSItemProvider(
            item: "https://example.com/from-string" as NSString,
            typeIdentifier: UTType.plainText.identifier
        )
        let result = await ActionExtensionViewController.extractURL(from: [provider])
        #expect(result == URL(string: "https://example.com/from-string"))
    }

    @Test func trimsWhitespaceFromPlainText() async {
        let provider = NSItemProvider(object: "  https://example.com/page\n" as NSString)
        let result = await ActionExtensionViewController.extractURL(from: [provider])
        #expect(result == URL(string: "https://example.com/page"))
    }

    @Test func extractsLinkFromProseText() async {
        // Hosts often share "Title + link" as one string; the link must be
        // scanned out rather than the whole string parsed as a URL.
        let provider = NSItemProvider(
            item: "Check this out https://example.com/page?utm_source=x and more" as NSString,
            typeIdentifier: UTType.plainText.identifier
        )
        let result = await ActionExtensionViewController.extractURL(from: [provider])
        #expect(result == URL(string: "https://example.com/page?utm_source=x"))
    }

    @Test func ignoresProseAfterLink() async {
        // The lenient URL(string:) parser would percent-encode trailing
        // prose into the URL; scanning must cut the link at the whitespace.
        let provider = NSItemProvider(
            item: "https://example.com/x?utm_source=share extra words" as NSString,
            typeIdentifier: UTType.plainText.identifier
        )
        let result = await ActionExtensionViewController.extractURL(from: [provider])
        #expect(result == URL(string: "https://example.com/x?utm_source=share"))
    }

    @Test func extractsFirstLinkFromTextWithMultipleLinks() async {
        let provider = NSItemProvider(
            item: "https://first.example.com/a then https://second.example.com/b" as NSString,
            typeIdentifier: UTType.plainText.identifier
        )
        let result = await ActionExtensionViewController.extractURL(from: [provider])
        #expect(result == URL(string: "https://first.example.com/a"))
    }

    @Test func excludesTrailingPunctuationFromTextLink() async {
        let provider = NSItemProvider(
            item: "Read https://example.com/page." as NSString,
            typeIdentifier: UTType.plainText.identifier
        )
        let result = await ActionExtensionViewController.extractURL(from: [provider])
        #expect(result == URL(string: "https://example.com/page"))
    }

    @Test func returnsNilForNonURLText() async {
        let provider = NSItemProvider(object: "just some shared text" as NSString)
        let result = await ActionExtensionViewController.extractURL(from: [provider])
        #expect(result == nil)
    }

    @Test func returnsNilForFileURL() async {
        let provider = NSItemProvider(object: NSURL(fileURLWithPath: "/tmp/document.pdf"))
        let result = await ActionExtensionViewController.extractURL(from: [provider])
        #expect(result == nil)
    }

    @Test func returnsNilForNonWebSchemeURLs() async {
        let ftp = NSItemProvider(object: NSURL(string: "ftp://example.com/file")!)
        let custom = NSItemProvider(object: NSURL(string: "linkclean://settings")!)
        let result = await ActionExtensionViewController.extractURL(from: [ftp, custom])
        #expect(result == nil)
    }

    @Test func prefersURLAttachmentOverText() async {
        // The canonical URL attachment wins even when a text provider
        // carrying a different link comes first in the array.
        let textProvider = NSItemProvider(
            item: "https://example.com/from-text" as NSString,
            typeIdentifier: UTType.plainText.identifier
        )
        let urlProvider = NSItemProvider(object: NSURL(string: "https://example.com/from-url")!)
        let result = await ActionExtensionViewController.extractURL(from: [textProvider, urlProvider])
        #expect(result == URL(string: "https://example.com/from-url"))
    }

    @Test func prefersWebRepresentationOverFileURL() async {
        // A provider can register a file representation ahead of the web
        // URL; extraction must not stop at the file payload.
        let provider = NSItemProvider()
        provider.registerItem(forTypeIdentifier: UTType.fileURL.identifier) { @Sendable completion, _, _ in
            completion?(NSURL(fileURLWithPath: "/tmp/document.pdf"), nil)
        }
        provider.registerItem(forTypeIdentifier: UTType.url.identifier) { @Sendable completion, _, _ in
            completion?(NSURL(string: "https://example.com/canonical"), nil)
        }
        let result = await ActionExtensionViewController.extractURL(from: [provider])
        #expect(result == URL(string: "https://example.com/canonical"))
    }
}
#endif
