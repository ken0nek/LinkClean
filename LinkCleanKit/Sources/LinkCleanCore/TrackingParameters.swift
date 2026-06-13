//
//  TrackingParameters.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 2/4/26.
//

import Foundation

/// A catalog section's identity. Carries only the stable `id` (`"utm"`,
/// `"ads"`…) and a sort order — no display text. The localized section title
/// lives in the presenting layer (the app maps `id` to a generated string
/// symbol in `ManageParametersView`), so the domain ships identifiers, not UI
/// copy, and stays free of `Bundle.module` and main-actor isolation.
public struct TrackingParameterKind: Identifiable, Hashable, Sendable {
    public let id: String
    public let sortOrder: Int

    public init(id: String, sortOrder: Int) {
        self.id = id
        self.sortOrder = sortOrder
    }
}

public struct TrackingParameterDefinition: Identifiable, Hashable, Sendable {
    public var id: String { name }
    public let name: String
    public let displayName: String
    public let kind: TrackingParameterKind
    /// Whether the parameter is stripped without the user opting in.
    ///
    /// Curation policy (mirrors `ReferenceParameterCatalog`'s rule): a name is
    /// enabled by default only when it is vendor-specific enough that a benign
    /// collision is implausible (`fbclid`, `utm_source`). Generic tokens that
    /// legitimately appear as functional query keys (`url`, `title`, `s`) ship
    /// disabled — stripping them would break real links (YouTube `?t=`
    /// timestamps, WordPress `?s=` search, share-intent payloads). They stay in
    /// the catalog so the Manage Parameters toggles can opt in.
    public let enabledByDefault: Bool
    /// Host suffixes this rule is limited to, or `nil` to apply on every site.
    ///
    /// The escape hatch between "safe everywhere" and "off": a generic name
    /// that is a *known* tracker on specific sites (`t`/`s` share tokens on
    /// x.com) is stripped only there, so the same name stays functional
    /// elsewhere (`?t=120` on YouTube). Lowercased registrable domains;
    /// matching is by exact host or any subdomain (`mobile.twitter.com`
    /// matches `twitter.com`).
    public let hosts: Set<String>?

    public init(
        name: String,
        displayName: String? = nil,
        kind: TrackingParameterKind,
        enabledByDefault: Bool = true,
        hosts: Set<String>? = nil
    ) {
        let normalized = name.lowercased()
        self.name = normalized
        self.displayName = displayName ?? normalized
        self.kind = kind
        self.enabledByDefault = enabledByDefault
        self.hosts = hosts.map { Set($0.map { $0.lowercased() }) }
    }

    /// Whether this rule applies on `host` (already lowercased, no trailing
    /// root dot — see ``TrackingParameterCatalog/normalize(host:)``). A global
    /// rule (`hosts == nil`) applies everywhere; a scoped rule needs a host
    /// and matches by exact host or any subdomain.
    public func appliesTo(host: String?) -> Bool {
        guard let hosts else { return true }
        guard let host else { return false }
        return hosts.contains { host == $0 || host.hasSuffix("." + $0) }
    }
}

public struct TrackingParameterSection: Identifiable, Hashable, Sendable {
    public var id: String { kind.id }
    public let kind: TrackingParameterKind
    public let parameters: [TrackingParameterDefinition]

    public init(kind: TrackingParameterKind, parameters: [TrackingParameterDefinition]) {
        self.kind = kind
        self.parameters = parameters
    }
}

public enum TrackingParameterCatalog {
    private static let xTwitter: Set<String> = ["twitter.com", "x.com"]
    private static let youtube: Set<String> = ["youtube.com", "youtu.be"]
    /// Amazon storefronts. Amazon's tracking keys (`tag`, `ref_`, `pf_rd_*`…)
    /// collide with functional keys on other sites, so they're scoped here.
    private static let amazon: Set<String> = [
        "amazon.com", "amazon.co.uk", "amazon.de", "amazon.co.jp", "amazon.fr",
        "amazon.it", "amazon.es", "amazon.ca", "amazon.com.au", "amazon.in",
        "amazon.com.br", "amazon.com.mx", "amazon.nl", "amazon.se", "amazon.sg",
        "amazon.ae", "amazon.com.tr", "amazon.pl"
    ]

    public static let sections: [TrackingParameterSection] = {
        let utm = TrackingParameterKind(id: "utm", sortOrder: 0)
        let referral = TrackingParameterKind(id: "referral", sortOrder: 1)
        let ads = TrackingParameterKind(id: "ads", sortOrder: 2)
        let analytics = TrackingParameterKind(id: "analytics", sortOrder: 3)
        let email = TrackingParameterKind(id: "email", sortOrder: 4)
        let social = TrackingParameterKind(id: "social", sortOrder: 5)
        let affiliate = TrackingParameterKind(id: "affiliate", sortOrder: 6)

        return [
            TrackingParameterSection(
                kind: utm,
                parameters: makeDefinitions(
                    names: [
                        "utm_source",
                        "utm_medium",
                        "utm_campaign",
                        "utm_term",
                        "utm_content",
                        "utm_id",
                        "utm_source_platform",
                        "utm_creative_format",
                        "utm_marketing_tactic"
                    ],
                    kind: utm
                )
            ),
            TrackingParameterSection(
                kind: referral,
                parameters: dedup([
                    TrackingParameterDefinition(name: "ref", kind: referral, enabledByDefault: false),
                    TrackingParameterDefinition(name: "ref_src", kind: referral),
                    TrackingParameterDefinition(name: "ref_url", kind: referral),
                    // Play Store install-referrer payloads; functional
                    // redirect targets elsewhere.
                    TrackingParameterDefinition(name: "referrer", kind: referral, hosts: ["play.google.com"]),
                    TrackingParameterDefinition(name: "source", kind: referral, enabledByDefault: false),
                    TrackingParameterDefinition(name: "campaign", kind: referral, enabledByDefault: false),
                    TrackingParameterDefinition(name: "medium", kind: referral, enabledByDefault: false),
                    // Functional on Google Maps (place ID).
                    TrackingParameterDefinition(name: "cid", kind: referral, enabledByDefault: false),
                    TrackingParameterDefinition(name: "_cid", kind: referral, enabledByDefault: false),
                    // Generic campaign IDs — widespread but generic, so off by default.
                    TrackingParameterDefinition(name: "icid", kind: referral, enabledByDefault: false),
                    TrackingParameterDefinition(name: "ncid", kind: referral, enabledByDefault: false)
                ])
            ),
            TrackingParameterSection(
                kind: ads,
                parameters: dedup([
                    TrackingParameterDefinition(name: "fbclid", kind: ads),
                    TrackingParameterDefinition(name: "gclid", kind: ads),
                    TrackingParameterDefinition(name: "gclsrc", kind: ads),
                    TrackingParameterDefinition(name: "gbraid", kind: ads),
                    TrackingParameterDefinition(name: "wbraid", kind: ads),
                    TrackingParameterDefinition(name: "gad_source", kind: ads),
                    TrackingParameterDefinition(name: "gad_campaignid", kind: ads),
                    TrackingParameterDefinition(name: "srsltid", kind: ads),
                    TrackingParameterDefinition(name: "dclid", kind: ads),
                    TrackingParameterDefinition(name: "msclkid", kind: ads),
                    TrackingParameterDefinition(name: "twclid", kind: ads),
                    TrackingParameterDefinition(name: "ttclid", kind: ads),
                    TrackingParameterDefinition(name: "yclid", kind: ads),
                    TrackingParameterDefinition(name: "s_kwcid", kind: ads),
                    TrackingParameterDefinition(name: "ob_click_id", kind: ads),
                    // LinkedIn share/recommendation token.
                    TrackingParameterDefinition(name: "rcm", kind: ads, hosts: ["linkedin.com"]),
                    // Generic ad-report field names — functional on unrelated
                    // sites (doc_id, site, platform…), so off by default.
                    TrackingParameterDefinition(name: "account_id", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "account_name", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "campaign_group_id", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "campaign_group_name", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "campaign_id", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "campaign_name", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "creative_id", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "creative_name", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "campaign_item_id", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "custom_id", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "site", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "site_id", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "platform", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "cpc", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "ad_id", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "ad_name", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "doc_id", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "doc_title", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "doc_author", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "section_id", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "section_name", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "publisher_id", kind: ads, enabledByDefault: false),
                    TrackingParameterDefinition(name: "publisher_name", kind: ads, enabledByDefault: false),
                    // Vendor click IDs (default-on, vendor-specific).
                    TrackingParameterDefinition(name: "sc_click_id", kind: ads),
                    TrackingParameterDefinition(name: "oborigurl", kind: ads),
                    TrackingParameterDefinition(name: "tblci", kind: ads),
                    // Meta / TikTok ad pixels — grouped with their click IDs
                    // (fbclid, ttclid), not under social.
                    TrackingParameterDefinition(name: "_fbp", kind: ads),
                    TrackingParameterDefinition(name: "_fbc", kind: ads),
                    TrackingParameterDefinition(name: "_ttp", kind: ads)
                ])
            ),
            TrackingParameterSection(
                kind: analytics,
                parameters: dedup([
                    TrackingParameterDefinition(name: "_ga", kind: analytics),
                    TrackingParameterDefinition(name: "_gl", kind: analytics),
                    TrackingParameterDefinition(name: "ga", kind: analytics, enabledByDefault: false),
                    TrackingParameterDefinition(name: "ga_session", kind: analytics),
                    // HubSpot web-analytics cookies (the email-link trackers
                    // _hsenc/_hsmi stay under email).
                    TrackingParameterDefinition(name: "__hssc", kind: analytics),
                    TrackingParameterDefinition(name: "__hstc", kind: analytics),
                    TrackingParameterDefinition(name: "__hsfp", kind: analytics),
                    // Yandex Metrica / ComScore / Adobe (AT Internet).
                    TrackingParameterDefinition(name: "_openstat", kind: analytics),
                    TrackingParameterDefinition(name: "ns_campaign", kind: analytics),
                    TrackingParameterDefinition(name: "ns_source", kind: analytics),
                    TrackingParameterDefinition(name: "at_medium", kind: analytics),
                    TrackingParameterDefinition(name: "at_campaign", kind: analytics)
                ])
            ),
            TrackingParameterSection(
                kind: email,
                parameters: makeDefinitions(
                    names: [
                        "mc_eid",
                        "mc_cid",
                        "mc_tc",
                        "mkt_tok",
                        "vero_id",
                        "vero_conv",
                        "oly_enc_id",
                        "oly_anon_id",
                        "_hsenc",
                        "_hsmi",
                        "hsctatracking",
                        // Klaviyo.
                        "_kx"
                    ],
                    kind: email
                )
            ),
            TrackingParameterSection(
                kind: social,
                parameters: dedup([
                    TrackingParameterDefinition(name: "igshid", kind: social),
                    TrackingParameterDefinition(name: "igsh", kind: social),
                    TrackingParameterDefinition(name: "mibextid", kind: social),
                    // Branch deep-link attribution.
                    TrackingParameterDefinition(name: "_branch_match_id", kind: social),
                    TrackingParameterDefinition(name: "_branch_referrer", kind: social),
                    TrackingParameterDefinition(name: "share_source_type", kind: social),
                    // Google Maps share token.
                    TrackingParameterDefinition(name: "g_st", kind: social),
                    // Meta share token.
                    TrackingParameterDefinition(name: "xmt", kind: social, hosts: ["facebook.com", "threads.net"]),
                    // X share tokens; `t` is a YouTube timestamp and `s` a
                    // WordPress search elsewhere.
                    TrackingParameterDefinition(name: "t", kind: social, hosts: xTwitter),
                    TrackingParameterDefinition(name: "s", kind: social, hosts: xTwitter),
                    // Share session IDs on YouTube and Spotify; a generic
                    // session/item key elsewhere.
                    TrackingParameterDefinition(
                        name: "si",
                        kind: social,
                        hosts: youtube.union(["open.spotify.com", "spotify.link"])
                    ),
                    TrackingParameterDefinition(name: "feature", kind: social, hosts: youtube),
                    // Share-intent payloads and generic words — functional
                    // almost everywhere they appear, so off by default.
                    TrackingParameterDefinition(name: "text", kind: social, enabledByDefault: false),
                    TrackingParameterDefinition(name: "url", kind: social, enabledByDefault: false),
                    TrackingParameterDefinition(name: "title", kind: social, enabledByDefault: false),
                    TrackingParameterDefinition(name: "summary", kind: social, enabledByDefault: false),
                    TrackingParameterDefinition(name: "mini", kind: social, enabledByDefault: false),
                    TrackingParameterDefinition(name: "u", kind: social, enabledByDefault: false),
                    TrackingParameterDefinition(name: "username", kind: social, enabledByDefault: false),
                    TrackingParameterDefinition(name: "app", kind: social, enabledByDefault: false),
                    TrackingParameterDefinition(name: "pp", kind: social, enabledByDefault: false),
                    TrackingParameterDefinition(name: "tt", kind: social, enabledByDefault: false),
                    TrackingParameterDefinition(name: "refer", kind: social, enabledByDefault: false)
                ])
            ),
            TrackingParameterSection(
                kind: affiliate,
                parameters: dedup([
                    TrackingParameterDefinition(name: "affiliate", kind: affiliate),
                    TrackingParameterDefinition(name: "subid", kind: affiliate),
                    TrackingParameterDefinition(name: "sharedid", kind: affiliate),
                    // Generic "id" suffix — article/account IDs elsewhere.
                    TrackingParameterDefinition(name: "aid", kind: affiliate, enabledByDefault: false),
                    // Amazon affiliate + navigation tracking, host-scoped to Amazon
                    // storefronts. Functional search keys (qid, sr, keywords, psc,
                    // th) are deliberately left alone.
                    TrackingParameterDefinition(name: "tag", kind: affiliate, hosts: amazon),
                    TrackingParameterDefinition(name: "linkcode", kind: affiliate, hosts: amazon),
                    TrackingParameterDefinition(name: "ascsubtag", kind: affiliate, hosts: amazon),
                    TrackingParameterDefinition(name: "ref_", kind: affiliate, hosts: amazon),
                    TrackingParameterDefinition(name: "pd_rd_w", kind: affiliate, hosts: amazon),
                    TrackingParameterDefinition(name: "pd_rd_r", kind: affiliate, hosts: amazon),
                    TrackingParameterDefinition(name: "pd_rd_wg", kind: affiliate, hosts: amazon),
                    TrackingParameterDefinition(name: "pf_rd_p", kind: affiliate, hosts: amazon),
                    TrackingParameterDefinition(name: "pf_rd_r", kind: affiliate, hosts: amazon),
                    TrackingParameterDefinition(name: "pf_rd_s", kind: affiliate, hosts: amazon),
                    TrackingParameterDefinition(name: "pf_rd_t", kind: affiliate, hosts: amazon),
                    TrackingParameterDefinition(name: "pf_rd_i", kind: affiliate, hosts: amazon),
                    TrackingParameterDefinition(name: "pf_rd_m", kind: affiliate, hosts: amazon)
                ])
            )
        ]
    }()

    /// Every catalog name regardless of default state or host scope. The set
    /// custom-parameter shadow checks and `ReferenceParameterCatalog`
    /// disjointness are defined against.
    public static let allNames: Set<String> = {
        var result = Set<String>()
        for section in sections {
            for parameter in section.parameters {
                result.insert(parameter.name)
            }
        }
        return result
    }()

    /// The names the catalog strips on `host` before any user overrides:
    /// enabled-by-default definitions whose host scope matches. `nil` host
    /// (unparseable URL) applies global rules only.
    public static func defaultRemovalSet(forHost host: String?) -> Set<String> {
        names(forHost: host) { $0.enabledByDefault }
    }

    /// The single catalog walk every removal-set builder filters through —
    /// this and `TrackingParameterStore.enabledParameters(forHost:)` differ
    /// only in their `isOn` predicate, so host-scope semantics cannot drift
    /// between them. Normalizes `host` itself; `nil` admits global rules only.
    /// Public because ``TrackingParameterStore`` (in `LinkCleanData`) filters
    /// through it with its own override-aware predicate.
    public static func names(
        forHost host: String?,
        where isOn: (TrackingParameterDefinition) -> Bool
    ) -> Set<String> {
        let host = normalize(host: host)
        var result = Set<String>()
        for section in sections {
            for parameter in section.parameters where isOn(parameter) && parameter.appliesTo(host: host) {
                result.insert(parameter.name)
            }
        }
        return result
    }

    /// Lowercases `host` and strips a trailing root dot (`youtube.com.`), the
    /// form ``TrackingParameterDefinition/appliesTo(host:)`` expects. Pure
    /// host-string logic shared by ``names(forHost:where:)`` and
    /// `URLCleaner.ruleHost(of:)`, so every host-scope match keys off the same
    /// string. Lives in the domain catalog rather than a persistence store
    /// because nothing here touches storage — the cleaner needs it too.
    static func normalize(host: String?) -> String? {
        guard var host = host?.lowercased(), !host.isEmpty else { return nil }
        if host.hasSuffix(".") {
            host.removeLast()
        }
        return host.isEmpty ? nil : host
    }

    public static func definition(for name: String) -> TrackingParameterDefinition? {
        definitionsByName[name.lowercased()]
    }

    /// The catalog kind id a built-in parameter belongs to, or `nil` for names
    /// outside the catalog (e.g. user-authored custom parameters). Lets the
    /// cleaner report which categories fired in a clean without the call site
    /// re-deriving the mapping. Kind ids are a finite, known set — safe to send.
    public static func kindID(for name: String) -> String? {
        definitionsByName[name.lowercased()]?.kind.id
    }

    private static let definitionsByName: [String: TrackingParameterDefinition] = {
        var map: [String: TrackingParameterDefinition] = [:]
        for section in sections {
            for parameter in section.parameters {
                map[parameter.name] = parameter
            }
        }
        return map
    }()

    private static func makeDefinitions(
        names: [String],
        kind: TrackingParameterKind
    ) -> [TrackingParameterDefinition] {
        dedup(names.map { TrackingParameterDefinition(name: $0, kind: kind) })
    }

    private static func dedup(_ definitions: [TrackingParameterDefinition]) -> [TrackingParameterDefinition] {
        var seen = Set<String>()
        var result: [TrackingParameterDefinition] = []
        for definition in definitions {
            guard seen.insert(definition.name).inserted else { continue }
            result.append(definition)
        }
        return result
    }
}
