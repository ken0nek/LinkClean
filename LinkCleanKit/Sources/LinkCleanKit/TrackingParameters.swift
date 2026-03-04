//
//  TrackingParameters.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation

public nonisolated struct TrackingParameterKind: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let sortOrder: Int

    public init(id: String, title: String, sortOrder: Int) {
        self.id = id
        self.title = title
        self.sortOrder = sortOrder
    }
}

public nonisolated struct TrackingParameterDefinition: Identifiable, Hashable, Sendable {
    public var id: String { name }
    public let name: String
    public let displayName: String
    public let kind: TrackingParameterKind

    public init(name: String, displayName: String? = nil, kind: TrackingParameterKind) {
        let normalized = name.lowercased()
        self.name = normalized
        self.displayName = displayName ?? normalized
        self.kind = kind
    }
}

public nonisolated struct TrackingParameterSection: Identifiable, Hashable, Sendable {
    public var id: String { kind.id }
    public let kind: TrackingParameterKind
    public let parameters: [TrackingParameterDefinition]

    public init(kind: TrackingParameterKind, parameters: [TrackingParameterDefinition]) {
        self.kind = kind
        self.parameters = parameters
    }
}

public nonisolated enum TrackingParameterCatalog {
    public static let sections: [TrackingParameterSection] = {
        let utm = TrackingParameterKind(id: "utm", title: "UTM Parameters", sortOrder: 0)
        let common = TrackingParameterKind(id: "common", title: "Common Tracking", sortOrder: 1)
        let ads = TrackingParameterKind(id: "ads", title: "Ads & Attribution", sortOrder: 2)
        let analytics = TrackingParameterKind(id: "analytics", title: "Analytics", sortOrder: 3)
        let email = TrackingParameterKind(id: "email", title: "Email/CRM", sortOrder: 4)
        let social = TrackingParameterKind(id: "social", title: "Social & Share", sortOrder: 5)
        let affiliate = TrackingParameterKind(id: "affiliate", title: "Affiliate", sortOrder: 6)

        return [
            TrackingParameterSection(
                kind: utm,
                parameters: makeDefinitions(
                    names: [
                        "utm_source",
                        "utm_medium",
                        "utm_campaign",
                        "utm_term",
                        "utm_content"
                    ],
                    kind: utm
                )
            ),
            TrackingParameterSection(
                kind: common,
                parameters: makeDefinitions(
                    names: [
                        "ref",
                        "ref_src",
                        "ref_url",
                        "referrer",
                        "source",
                        "campaign",
                        "medium",
                        "cid",
                        "_cid"
                    ],
                    kind: common
                )
            ),
            TrackingParameterSection(
                kind: ads,
                parameters: makeDefinitions(
                    names: [
                        "fbclid",
                        "gclid",
                        "gclsrc",
                        "dclid",
                        "msclkid",
                        "s_kwcid",
                        "rcm",
                        "account_id",
                        "account_name",
                        "campaign_group_id",
                        "campaign_group_name",
                        "campaign_id",
                        "campaign_name",
                        "creative_id",
                        "creative_name",
                        "campaign_item_id",
                        "custom_id",
                        "site",
                        "site_id",
                        "platform",
                        "cpc",
                        "ob_click_id",
                        "ad_id",
                        "ad_name",
                        "doc_id",
                        "doc_title",
                        "doc_author",
                        "section_id",
                        "section_name",
                        "publisher_id",
                        "publisher_name"
                    ],
                    kind: ads
                )
            ),
            TrackingParameterSection(
                kind: analytics,
                parameters: makeDefinitions(
                    names: [
                        "_ga",
                        "_gl",
                        "ga",
                        "ga_session"
                    ],
                    kind: analytics
                )
            ),
            TrackingParameterSection(
                kind: email,
                parameters: makeDefinitions(
                    names: [
                        "mc_eid",
                        "mc_cid",
                        "vero_id",
                        "vero_conv",
                        "oly_enc_id",
                        "oly_anon_id",
                        "__hssc",
                        "__hstc",
                        "__hsfp",
                        "hsctatracking"
                    ],
                    kind: email
                )
            ),
            TrackingParameterSection(
                kind: social,
                parameters: makeDefinitions(
                    names: [
                        "igshid",
                        "igsh",
                        "_fbp",
                        "_fbc",
                        "share_source_type",
                        "text",
                        "url",
                        "username",
                        "xmt",
                        "si",
                        "feature",
                        "app",
                        "s",
                        "t",
                        "u",
                        "mini",
                        "title",
                        "summary",
                        "_ttp",
                        "tt",
                        "refer",
                        "pp"
                    ],
                    kind: social
                )
            ),
            TrackingParameterSection(
                kind: affiliate,
                parameters: makeDefinitions(
                    names: [
                        "affiliate",
                        "subid",
                        "sharedid",
                        "aid"
                    ],
                    kind: affiliate
                )
            )
        ]
    }()

    public static let defaultEnabledSet: Set<String> = {
        var result = Set<String>()
        for section in sections {
            for parameter in section.parameters {
                result.insert(parameter.name)
            }
        }
        return result
    }()

    private static func makeDefinitions(
        names: [String],
        kind: TrackingParameterKind
    ) -> [TrackingParameterDefinition] {
        var seen = Set<String>()
        var result: [TrackingParameterDefinition] = []
        for name in names {
            let normalized = name.lowercased()
            guard seen.insert(normalized).inserted else { continue }
            result.append(TrackingParameterDefinition(name: normalized, kind: kind))
        }
        return result
    }
}
