//
//  HistoryDiff.swift
//  LinkCleanCore
//
//  Created by Ken Tominaga on 6/25/26.
//

import Foundation

/// The structural difference between a History entry's original `input` link and
/// its cleaned `output` — computed **purely from the two stored strings** (plus
/// the persisted ``HistoryDiff/init(input:output:arrivedFromHost:)`` arrival host),
/// never by re-running the live catalog. That keeps the before→after view honest:
/// a rule added or removed since the entry was saved must not retroactively rewrite
/// what actually happened to this link ("Removed X" has to mean what really
/// happened).
///
/// `input`/`output` are both the *destination* link (the entry stores the cleaned
/// link and the link it was cleaned from), so the removed query/fragment is always
/// the destination's own — a redirect wrapper's payload is never mistaken for a
/// tracker. The host the link *arrived* as (a `bit.ly` short link, a `google.com`
/// redirect) is carried separately as `arrivedFromHost`, resolved upstream where
/// the original is still known.
///
/// On-device display only, like ``CleanOutcome/Display``: the values here are raw
/// query keys/values from the user's own link, so nothing in ``AnalyticsEvent``
/// accepts a `HistoryDiff`.
public struct HistoryDiff: Equatable, Sendable {
    /// A query parameter present on the input but gone from the output.
    public struct Param: Equatable, Sendable {
        public let name: String
        public let value: String

        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }

    /// Query items in `input` not present in `output`, compared by name+value and
    /// multiplicity-aware (a removed duplicate still shows when an identical copy
    /// survived), in their original input order.
    public let removedParameters: [Param]

    /// The fragment content `input` carried that `output` dropped — e.g. a
    /// `:~:text=…` scroll-to-text directive or fragment-borne trackers (E2). The
    /// literal difference of the two fragments, so a *partial* fragment clean (a
    /// stripped directive that leaves a surviving `#anchor`) is still reported.
    /// `nil` when the fragment was unchanged or absent.
    public let removedFragment: String?

    /// The host the link *arrived* as, when it differs from the output host — a
    /// redirect was unwrapped (E1) or a short link expanded (E4), so the user
    /// landed on a different domain than they pasted (e.g. `"bit.ly"`). Persisted
    /// on the entry at clean time (already normalized for display); `nil` when
    /// input and output share a host. Not re-derived here — the stored `output` is
    /// the resolved destination, so an input-vs-output host comparison would always
    /// be `nil`.
    public let expandedFromHost: String?

    public init(input: String, output: String, arrivedFromHost: String? = nil) {
        let inComponents = URLComponents(string: input)
        let outComponents = URLComponents(string: output)

        // Removed query parameters (by name+value; multiplicity-aware; input order).
        // Count surviving output items so a removed duplicate isn't masked by an
        // identical copy that stayed (and a fully-removed duplicate lists once each).
        let inItems = inComponents?.queryItems ?? []
        var survivingCounts: [String: Int] = [:]
        for item in outComponents?.queryItems ?? [] {
            survivingCounts[Self.key(item), default: 0] += 1
        }
        removedParameters = inItems.compactMap { item in
            let key = Self.key(item)
            if let count = survivingCounts[key], count > 0 {
                survivingCounts[key] = count - 1
                return nil
            }
            return Param(name: item.name, value: item.value ?? "")
        }

        // Removed fragment: the segments the input fragment carried that the
        // output's no longer does (directive and/or fragment params).
        removedFragment = Self.removedFragment(from: inComponents?.fragment, to: outComponents?.fragment)

        // Host change: the persisted arrival host, surfaced as-is.
        expandedFromHost = arrivedFromHost
    }

    /// Nothing changed between input and output — the link was already clean.
    public var isEmpty: Bool {
        removedParameters.isEmpty && removedFragment == nil && expandedFromHost == nil
    }

    private static func key(_ item: URLQueryItem) -> String {
        "\(item.name)\u{0}\(item.value ?? "")"
    }

    /// The fragment segments `input` carried that `output` no longer does — the
    /// literal set difference of the two stored fragments, split on `&` with the
    /// `:~:` scroll-to-text directive kept whole. Independent of the live cleaner,
    /// so it stays honest to what the two strings actually differ by. `nil` when
    /// the fragment was unchanged or absent.
    private static func removedFragment(from rawInput: String?, to rawOutput: String?) -> String? {
        guard let rawInput, !rawInput.isEmpty else { return nil }
        let rawOutput = rawOutput ?? ""
        guard rawInput != rawOutput else { return nil }
        let survived = Set(fragmentSegments(rawOutput))
        let removed = fragmentSegments(rawInput).filter { !survived.contains($0) }
        return removed.isEmpty ? rawInput : removed.joined(separator: "&")
    }

    private static func fragmentSegments(_ fragment: String) -> [String] {
        guard !fragment.isEmpty else { return [] }
        var anchor = fragment
        var directive: String?
        if let range = fragment.range(of: ":~:") {
            directive = String(fragment[range.lowerBound...])
            anchor = String(fragment[..<range.lowerBound])
        }
        var segments = anchor.isEmpty ? [] : anchor.components(separatedBy: "&")
        if let directive { segments.append(directive) }
        return segments
    }
}
