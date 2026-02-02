//
//  URLCleaner.swift
//  LinkClean
//
//  Created by Ken Tominaga on 2/1/26.
//

import Foundation

nonisolated enum URLCleaner {

    private static let trackingParameters: Set<String> = [
        // UTM
        "utm_source",
        "utm_medium",
        "utm_campaign",
        "utm_term",
        "utm_content",
        // Facebook
        "fbclid",
        // Google Ads
        "gclid",
        "gclsrc",
        // Mailchimp
        "mc_eid",
        "mc_cid",
        // Vero
        "vero_id",
        "vero_conv",
        // Oly
        "oly_enc_id",
        "oly_anon_id",
        // HubSpot
        "__hssc",
        "__hstc",
        "__hsfp",
        "hsctatracking",
        // Google Analytics
        "_ga",
        "_gl",
        // Referral
        "ref",
        "ref_src",
        "ref_url",
        // Microsoft / Bing Ads
        "s_kwcid",
        "msclkid",
        // LinkedIn
        "rcm",
        // Social
        "igshid",
        "share_source_type",
        "si",
        "feature",
        "app",
        // X (formerly Twitter)
        "s",
        "t",
        // TikTok Extended
        "_ttp",
        // YouTube
        "si",
        "pp",
        // Native Advertising - Taboola
        "campaign_id",
        "campaign_item_id",
        "creative_name",
        "custom_id",
        "site",
        "site_id",
        "platform",
        "cpc",
        // Native Advertising - Outbrain
        "ob_click_id",
        "ad_id",
        "ad_name",
        "doc_id",
        "doc_title",
        "doc_author",
        "section_id",
        "section_name",
        "publisher_id",
        "publisher_name",
        // Affiliate Marketing
        "subid",
        "SharedID",
        "aid",
        // GA4
        "ga",
        "ga_session",
    ]

    static func clean(_ urlString: String) -> String {
        guard var components = URLComponents(string: urlString) else {
            return urlString
        }

        guard let queryItems = components.queryItems, !queryItems.isEmpty else {
            return urlString
        }

        let filtered = queryItems.filter { item in
            !trackingParameters.contains(item.name.lowercased())
        }

        components.queryItems = filtered.isEmpty ? nil : filtered

        return components.string ?? urlString
    }

    static func clean(_ url: URL) -> URL {
        let cleaned = clean(url.absoluteString)
        return URL(string: cleaned) ?? url
    }
}
