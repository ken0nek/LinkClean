//
//  ReferenceParameterCatalog.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 6/8/26.
//

import Foundation

/// A bundled, on-device dictionary of *known* tracking-parameter names that are
/// **not** in the default removal catalog (`TrackingParameterCatalog`).
///
/// Its only job is catalog-gap detection: when a clean leaves a parameter behind
/// that matches this set, we have a known tracker missing from our defaults. The
/// names here are public knowledge (the same names privacy tools publish), so
/// reporting a match is safe to send — the same risk class as the built-in names
/// `Parameters.Default.toggled` already transmits (see `analytics.md` §3 and
/// `parameter-telemetry.md` §5, Tier 1). This catalog never drives *removal*;
/// over-inclusion only inflates a telemetry count, it can't strip a user's link.
///
/// This is a curated starter set. Expanding it from a vetted public source
/// (ClearURLs / AdGuard / Brave rulesets) is a follow-up pending a license
/// review — see `parameter-telemetry.md` §11.
public nonisolated enum ReferenceParameterCatalog {

    /// Lowercased known-tracker names, guaranteed disjoint from the default
    /// catalog (a leftover that *is* a default survived only because the user
    /// disabled it — a different signal, already covered by
    /// `Parameters.Default.toggled`).
    public static let names: Set<String> = {
        curated.subtracting(TrackingParameterCatalog.defaultEnabledSet)
    }()

    /// Hand-curated tracker names, grouped by vendor for maintenance. All
    /// lowercased; `names` removes any that overlap the default catalog.
    ///
    /// Curation rule: prefer vendor-specific names. Avoid short, generic tokens
    /// (e.g. `trk`, `scm`) that legitimately appear as non-tracking query keys —
    /// since a match here drives "promote into defaults" curation, a benign
    /// collision would pollute that signal.
    private static let curated: Set<String> = [
        // Google
        "gbraid", "wbraid", "gad_source", "gad_campaignid", "srsltid",
        // Yandex
        "yclid", "ymclid", "_openstat", "frommarket",
        // Twitter / X
        "twclid",
        // TikTok
        "ttclid",
        // Pinterest
        "epik",
        // LinkedIn
        "li_fat_id", "trkcampaign",
        // HubSpot
        "_hsenc", "_hsmi",
        "hsa_acc", "hsa_ad", "hsa_cam", "hsa_grp", "hsa_kw", "hsa_la",
        "hsa_mt", "hsa_net", "hsa_ol", "hsa_src", "hsa_tgt", "hsa_ver",
        // Marketo
        "mkt_tok",
        // Matomo / Piwik
        "mtm_source", "mtm_medium", "mtm_campaign", "mtm_keyword",
        "mtm_content", "mtm_cid", "mtm_group", "mtm_placement",
        "pk_source", "pk_medium", "pk_campaign", "pk_keyword", "pk_kwd",
        "pk_content", "pk_cid",
        "piwik_campaign", "piwik_keyword", "piwik_kwd",
        // Klaviyo
        "_kx",
        // Branch
        "_branch_match_id", "_branch_referrer",
        // Mailchimp
        "mc_tc",
        // Oracle Eloqua
        "elqtrackid", "elq", "elqcampaignid", "elqaid", "elqat",
        // Adobe / AT Internet
        "at_medium", "at_campaign", "at_custom",
        "at_recipient_id", "at_recipient_list",
        // Outbrain / Taboola
        "oborigurl", "tblci",
        // Alibaba
        "spm",
        // Yahoo
        "guccounter", "guce_referrer", "guce_referrer_sig",
        "soc_src", "soc_trk", "ncid",
        // ComScore
        "ns_campaign", "ns_mchannel", "ns_source", "ns_linkname", "ns_fee",
        // Webtrekk
        "wt_mc", "wt_zmc",
        // Reddit
        "rdt_cid",
        // Snapchat
        "sc_click_id",
        // Salesforce Pardot
        "pi_ad_id", "pi_campaign_id",
        // Drip
        "__s",
        // Generic campaign identifiers
        "icid", "cmpid", "vgo_ee",
    ]
}
