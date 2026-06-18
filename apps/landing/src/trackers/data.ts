import type { TrackerSpoke } from "./types";

/** Tracker glossary spokes. Each spoke is structured to read as a self-contained
 *  explainer (TL;DR + sections + example + FAQ + related), so SEO + LLMO can
 *  cite a single page for one parameter. Cross-link via `related` slugs. */
export const TRACKERS: ReadonlyArray<TrackerSpoke> = [
  // ── utm_source ───────────────────────────────────────────────
  {
    slug: "utm-source",
    param: "utm_source",
    kind: "utm",
    searchDemand: "high",
    vendor: { name: "Google Analytics (originally Urchin)", year: 1996, family: "Google" },
    related: ["utm-medium", "utm-campaign", "utm-term", "utm-content", "utm-id", "fbclid", "gclid", "srsltid", "gad-source", "mc-cid", "mc-eid", "mkt-tok", "hsenc"],
    content: {
      en: {
        title:
          "utm_source — what it leaks and how to strip it · LinkClean",
        description:
          "utm_source is a Google Analytics campaign tag that names where a click came from. It's marketing attribution metadata — strip it before sharing.",
        tldr: "utm_source names where a click came from — “newsletter”, “twitter”, “google”. It's a Google Analytics campaign tag, not part of the page. Removing it never breaks the link.",
        sections: [
          {
            heading: "What utm_source actually does",
            paragraphs: [
              "utm_source is one of five campaign-tracking parameters Google Analytics watches for: utm_source, utm_medium, utm_campaign, utm_term, and utm_content. Of those, utm_source is the most common — it names the place a visitor was coming from when they clicked your link.",
              "The receiving website's analytics tool sees the parameter, records it against the page view, and attributes that visit to the named source. None of that uses anything on the page itself; the tag is purely a back-channel from the link to the analytics tool.",
            ],
          },
          {
            heading: "Where the name comes from",
            paragraphs: [
              "UTM stands for Urchin Tracking Module. Urchin Software Corporation built one of the first commercial web-analytics products in San Diego in the late 1990s (founders Paul Muret and Jack Ancone). The “utm_” prefix is theirs.",
              "Google acquired Urchin in April 2005 and relaunched the product as Google Analytics in November 2005. The “utm_” prefix stuck — by then so many links already carried utm_source / utm_medium / utm_campaign tags that renaming them would have broken billions of analytics reports overnight. It's been a de facto industry standard ever since.",
            ],
          },
          {
            heading: "What it leaks when you share the link",
            paragraphs: [
              "If someone sends you a link with utm_source=newsletter and you forward it on, every analytics tool downstream sees that the click originated from a newsletter — your forward is attributed to the original campaign, not to you. That's usually fine, but it also means the analytics audit log is broadcasting the campaign tag to everyone the link reaches.",
              "It's not a personal identifier. utm_source doesn't carry your IP, your account, or anything that points back at you. It identifies the *campaign*, not the person. Still, sharing a link with utm tags reveals where you got it (a newsletter, an ad, a partner site), which is often more information than the sender intended you to pass along.",
            ],
          },
          {
            heading: "Why it's safe to remove",
            paragraphs: [
              "The page doesn't read utm_source. It's not used to load anything, not used to authenticate, not used to choose what to show you. Web servers route on the path; only analytics scripts look at utm_* parameters, and they do that *after* the page has already loaded.",
              "Drop it, refresh, and you'll land on the same page. The only thing that changes is what shows up in someone else's analytics dashboard — and that's not your problem to solve.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "utm_source is in LinkClean's default catalog, alongside the rest of the utm_* family (utm_medium, utm_campaign, utm_term, utm_content, utm_id, utm_source_platform, and a few newer variants). They're all stripped by default — no toggle, no per-site exception. They're vendor-specific enough that a benign collision is implausible: no legitimate URL uses utm_source for anything but analytics.",
              "Paste a link in the app, hit Share → Clean URL, fire the Clean Clipboard intent from Shortcuts or the widget, or scan a QR code with utm tags — all of these run the same stripping pipeline, on-device.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/blog/launch?utm_source=newsletter&utm_medium=email&utm_campaign=spring",
        exampleClean: "https://example.com/blog/launch",
        faq: [
          {
            q: "Does removing utm_source break the link?",
            a: "No. The page itself never reads it. Web servers route on the URL path; utm_* parameters are read only by analytics scripts after the page has loaded. Drop them and the same page loads.",
          },
          {
            q: "Why do publishers add utm_source in the first place?",
            a: "To answer the question “where did our traffic come from?” without having to trust the HTTP Referer header (which browsers increasingly strip for privacy). It's a tag a publisher embeds in their own outbound links so they can recognize the same campaign across email, social, and partner sites.",
          },
          {
            q: "Is utm_source personal data?",
            a: "Not directly. It names a marketing channel, not a person. But shared links carry it forward — so passing one along reveals to every downstream tool that the click came from (say) a newsletter, which can quietly profile your sources.",
          },
          {
            q: "Why does LinkClean strip utm_source but not “source”?",
            a: "“source” is a common functional query key — it's used by many sites for non-tracking purposes (sort order, view mode, deep links into apps). utm_source is unambiguous: nothing legitimately uses it for anything but Google Analytics attribution. LinkClean's curation rule is “vendor-specific names get default-on, generic tokens stay default-off”.",
          },
          {
            q: "Is this the same as fbclid or gclid?",
            a: "Same idea (tracking parameters attached to a link), different vendor and different blast radius. utm_source is an analytics campaign tag — anonymous-ish, broadly used. fbclid and gclid are click identifiers Meta and Google Ads use to tie the click back to a specific ad impression and the cookie that saw it. LinkClean strips all three by default.",
          },
        ],
      },
    },
  },

  // ── utm_medium ───────────────────────────────────────────────
  {
    slug: "utm-medium",
    param: "utm_medium",
    kind: "utm",
    searchDemand: "high",
    vendor: { name: "Google Analytics (originally Urchin)", year: 1996, family: "Google" },
    related: ["utm-source", "utm-campaign", "utm-term", "utm-content", "utm-id", "fbclid"],
    // (utm-medium related stays compact — utm-term/utm-content/utm-id reciprocate via utm-source)
    content: {
      en: {
        title: "utm_medium — what it names and how to strip it · LinkClean",
        description:
          "utm_medium names the channel a click came through — email, social, cpc. It pairs with utm_source on every campaign link. Safe to strip.",
        tldr: "utm_medium names the marketing **channel** — “email”, “social”, “cpc” (paid search), “organic”. Pairs with utm_source to answer “which channel?”. Removing it never breaks the link.",
        sections: [
          {
            heading: "Pairing utm_medium with utm_source",
            paragraphs: [
              "utm_source names *where* the click came from (the specific publisher, list, or vendor); utm_medium names *how* — the channel class. Together they answer the analyst's first question: “did this campaign land via email, via social, via paid search, or via something else?”.",
              "Standard utm_medium values are conventional but not enforced: email, social, cpc (cost-per-click paid search), display, affiliate, organic, referral. The values are whatever the publisher decides; Google Analytics treats them as opaque strings.",
            ],
          },
          {
            heading: "Channel-level attribution, and what forwarding leaks",
            paragraphs: [
              "Same blast radius as utm_source. Forwarding a link with utm_medium=email attached tells every analytics tool downstream that the click came in via email — even if your friend clicked it from a chat app. The publisher's report counts your forward as another email-channel click.",
              "Not personally identifying on its own. Like utm_source, utm_medium describes the *channel*, not the person. Still, the privacy-safe default is to forward the destination, not the marketing metadata.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "utm_medium ships default-on in LinkClean alongside the rest of the utm_* family. Stripped on every host; no toggle, no per-site exception. Like the other utm_* tags, it's vendor-specific enough that a legitimate URL never uses it for anything but Google Analytics attribution.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/article?utm_source=twitter&utm_medium=social&utm_campaign=spring-launch",
        exampleClean: "https://example.com/article",
        faq: [
          {
            q: "What's the difference between utm_source and utm_medium?",
            a: "utm_source is the specific origin (“newsletter”, “acme-blog”, “twitter”); utm_medium is the channel class (“email”, “social”, “referral”). One says “who”, the other says “how”.",
          },
          {
            q: "Does removing utm_medium break the link?",
            a: "No. Like the rest of the utm_* family, the destination page never reads it — only analytics scripts running on the page after it loads.",
          },
          {
            q: "Are there standard values for utm_medium?",
            a: "By convention: email, social, cpc, display, affiliate, organic, referral. Google Analytics treats them as opaque strings, so publishers can use anything they like — which is also why the values you see in the wild are a mess.",
          },
          {
            q: "Why strip utm_medium if it doesn't identify me?",
            a: "Because it broadcasts marketing metadata your sender embedded for their own analytics — it shouldn't ride along when you share the link onward. Same reasoning as stripping utm_source.",
          },
        ],
      },
    },
  },

  // ── utm_campaign ─────────────────────────────────────────────
  {
    slug: "utm-campaign",
    param: "utm_campaign",
    kind: "utm",
    searchDemand: "high",
    vendor: { name: "Google Analytics (originally Urchin)", year: 1996, family: "Google" },
    related: ["utm-source", "utm-medium", "utm-term", "utm-content", "utm-id", "gad-campaignid", "fbclid", "hsmi"],
    content: {
      en: {
        title: "utm_campaign — what publishers learn from it · LinkClean",
        description:
          "utm_campaign labels the campaign — “spring-launch”, “black-friday-2026”. Buckets clicks inside Google Analytics for the publisher. Safe to strip.",
        tldr: "utm_campaign labels the marketing campaign — “spring-launch”, “black-friday-2026”. It buckets clicks inside Google Analytics so the publisher can compare campaigns. The page renders identically without it.",
        sections: [
          {
            heading: "Campaign labels and what they reveal",
            paragraphs: [
              "Every utm_source + utm_medium combination can roll up under a named campaign. utm_campaign is that label — a free-form string the publisher picks, usually descriptive enough for a human to read in an analytics dashboard. “summer-sale-2026”, “onboarding-week-2”, “launch-day-tweet”.",
              "Google Analytics groups all clicks sharing the same utm_campaign value into one bucket, regardless of source or medium. That bucket is how marketers answer “how did this campaign do?” across email + social + paid search at once.",
            ],
          },
          {
            heading: "When a campaign name leaks strategy",
            paragraphs: [
              "utm_campaign tells everyone downstream which specific campaign is being measured — and sometimes the value is more revealing than the publisher intended. Internal campaign names sometimes telegraph product launches, A/B test cohorts, or strategy details the publisher would not voluntarily share with the public. Forwarding the URL with utm_campaign attached passes that label forward.",
              "Not personally identifying. The risk is signaling-to-third-parties, not user-identification.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "utm_campaign ships default-on with the rest of the utm_* family — stripped on every host, no exceptions. The catalog also covers the less-common utm_term (paid-keyword), utm_content (creative variant), utm_id (newer Google Analytics 4 campaign ID), utm_source_platform, and a few others.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/landing?utm_source=newsletter&utm_medium=email&utm_campaign=fall-launch-2026&utm_content=hero-cta",
        exampleClean: "https://example.com/landing",
        faq: [
          {
            q: "Can a utm_campaign value leak business info?",
            a: "Sometimes. An internal name like “q3-pricing-test” or “competitor-x-comparison” telegraphs the publisher's marketing strategy when forwarded — usually unintentionally. Stripping the tag avoids that signal travel.",
          },
          {
            q: "What about utm_term and utm_content?",
            a: "utm_term names a paid-search keyword (rare on shared links — usually appears in paid-ad URLs). utm_content names a creative variant (which ad creative was clicked, which hero CTA on the page). LinkClean strips both.",
          },
          {
            q: "Does removing utm_campaign break the link?",
            a: "No. The page never reads it. Strip and refresh — same content loads.",
          },
        ],
      },
    },
  },

  // ── fbclid ───────────────────────────────────────────────────
  {
    slug: "fbclid",
    param: "fbclid",
    kind: "ads",
    searchDemand: "high",
    vendor: { name: "Meta (Facebook)", year: 2018, family: "Meta" },
    related: ["gclid", "gbraid", "wbraid", "dclid", "msclkid", "ttclid", "twclid", "yclid", "li-fat-id", "epik", "sc-click-id", "rdt-cid", "spm", "utm-source", "utm-medium", "utm-campaign", "mibextid", "igshid"],
    content: {
      en: {
        title:
          "fbclid — Meta's click ID, and how to remove it · LinkClean",
        description:
          "fbclid is Meta's per-click identifier — added to outbound links from Facebook and Instagram. Strip it before forwarding. LinkClean does it on-device.",
        tldr: "fbclid is a per-click token Meta attaches to outbound links from Facebook and Instagram. It ties that click back to your Facebook session for ad attribution. Strip it before you share — sharing it carries the identifier into someone else's browser.",
        sections: [
          {
            heading: "What fbclid actually is",
            paragraphs: [
              "Meta calls it the Facebook Click Identifier. When you click a link inside Facebook, Instagram, or Messenger, Meta rewrites the URL on the fly to append ?fbclid=<long opaque token>. The token is unique per click, embeds the ad-impression context, and is bound to the cookie Meta has on your browser.",
              "When the destination site loads, if it runs Meta Pixel (a tiny snippet that pings Meta back), the Pixel reads fbclid from the URL and sends it home. Meta now knows the same person who saw the ad clicked through and reached the page. That's how conversion attribution works — and why fbclid is on virtually every link Facebook serves.",
            ],
          },
          {
            heading: "What it leaks when you forward the link",
            paragraphs: [
              "Forward a link with fbclid still attached and you hand someone else a token that was tied to *your* click. If their browser visits a site with Meta Pixel installed, the Pixel will dutifully send the token back to Meta — and Meta now has a tiny extra signal linking your share to their session.",
              "Meta increasingly hashes and rotates fbclid so it expires quickly, but the underlying attribution intent is the same: a per-click identifier that follows your click off Meta's platform. The privacy-safe default is to strip it.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "fbclid is in LinkClean's default ad-identifier catalog, alongside Google's gclid / gbraid / wbraid, Microsoft's msclkid, TikTok's ttclid, Yandex's yclid, and a few more. They're stripped on every site (no per-site scoping needed — these names don't legitimately appear as functional keys anywhere).",
              "LinkClean also strips Meta's _fbp and _fbc cookie-mirroring URL parameters when they appear in a link.",
            ],
          },
          {
            heading: "Why it's safe to strip",
            paragraphs: [
              "fbclid is attribution metadata — Meta uses it on its end to credit an ad. The destination page never needs it; the server-side product, article, or video loads identically without it. Refresh a page with fbclid removed and nothing changes about what loads.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/product?fbclid=IwAR0aBcDeFgHiJk1234567890XyZ",
        exampleClean: "https://example.com/product",
        faq: [
          {
            q: "Does removing fbclid break Facebook links?",
            a: "No. The link still goes to the same destination. The only thing that breaks is Meta's ad attribution — but that's Meta's bookkeeping, not your problem.",
          },
          {
            q: "Will the page still load?",
            a: "Yes. fbclid is only read by Meta Pixel scripts on the destination site (if they're there at all). Servers route on the path; the parameter is ignored by every part of the stack except an explicit Pixel call.",
          },
          {
            q: "Why does Facebook add fbclid even to links I share manually?",
            a: "Facebook injects it when *anyone* clicks an outbound link from the platform — including when you click a link to copy it. That's why outbound links to your friends so often arrive with fbclid attached. Strip it before forwarding.",
          },
          {
            q: "Is fbclid personal data?",
            a: "It's tied to your browser's Facebook cookie, so it can be joined back to your account on Meta's side. By itself the URL doesn't say “Ken Tominaga clicked this”, but Meta knows exactly which click it was.",
          },
        ],
      },
    },
  },

  // ── gclid ────────────────────────────────────────────────────
  {
    slug: "gclid",
    param: "gclid",
    kind: "ads",
    searchDemand: "high",
    vendor: { name: "Google Ads", year: 2010, family: "Google" },
    related: ["gbraid", "wbraid", "dclid", "srsltid", "gad-source", "gad-campaignid", "fbclid", "msclkid", "ttclid", "twclid", "yclid", "spm", "utm-source", "utm-term"],
    content: {
      en: {
        title:
          "gclid — Google Ads' click ID, and how to remove · LinkClean",
        description:
          "gclid is Google Ads' per-click identifier — added to every ad click to credit the ad-account that paid for it. LinkClean strips it by default.",
        tldr: "gclid is Google Ads' per-click identifier — added to every outbound click from Google Search ads, YouTube ads, and the Display Network. It exists to credit ad spend. Removing it never breaks the link.",
        sections: [
          {
            heading: "What gclid actually is",
            paragraphs: [
              "gclid stands for Google Click Identifier. When you click a Google Ads link — on Search, Shopping, YouTube, or the Display Network — Google appends ?gclid=<opaque token> to the destination URL. The token encodes the ad-account, the campaign, the ad-group, the ad itself, and the click event.",
              "On the destination, Google Ads' conversion tag (or Google Analytics' linker, or the Ads landing-page experience script) reads gclid and uses it to credit the click to that ad. It's the bridge between “ad served” and “customer arrived” in Google's bookkeeping.",
            ],
          },
          {
            heading: "Newer variants: gbraid and wbraid",
            paragraphs: [
              "Apple's App Tracking Transparency and Safari's restrictions on third-party cookies broke parts of Google Ads' classic gclid model. Google introduced gbraid (for iOS app-install attribution) and wbraid (for web on iOS) as more privacy-conscious replacements that work without a cross-site cookie.",
              "All three are in LinkClean's default catalog. Stripping them keeps marketing analytics out of the URL on share — and out of someone else's browser when they open the link.",
            ],
          },
          {
            heading: "What it leaks when you share the link",
            paragraphs: [
              "Forwarding a link with gclid attached carries the click-credit token into another person's session. If they land on a page running Google Ads conversion tracking, that tracking fires using *your* gclid — quietly inflating someone else's bookkeeping and tying their pageview to your ad-click context.",
              "It's not personally identifying on its own, but the privacy-safe default is to share a link, not metadata about how you found it.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "gclid, gbraid, and wbraid all ship in LinkClean's default ads catalog and are stripped on every host. Same pipeline as fbclid, msclkid, ttclid, yclid — vendor-specific tokens that have no legitimate non-tracking use.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/sale?gclid=Cj0KCQjwxOnFBhCFARIsABf-9QyMaQwerty",
        exampleClean: "https://example.com/sale",
        faq: [
          {
            q: "Will removing gclid break the page?",
            a: "No. The page loads identically. gclid is only read by Google's conversion tracking scripts on the destination; the page server doesn't use it for anything.",
          },
          {
            q: "Does this affect prices I see?",
            a: "Not in any common case. gclid drives advertiser-side reporting (who paid for the click, which campaign worked) — it isn't a coupon code or a session ID for the merchant.",
          },
          {
            q: "Is gclid the same as fbclid?",
            a: "Same kind of thing, different platform. fbclid is Meta's click ID; gclid is Google Ads'. msclkid is Microsoft's, ttclid is TikTok's, yclid is Yandex's. LinkClean strips all of them by default.",
          },
          {
            q: "Why also strip gbraid and wbraid?",
            a: "They're the iOS-era replacements Google rolled out after ATT and Safari ITP closed the loopholes the classic gclid model relied on. Same job, same default-on treatment in LinkClean.",
          },
        ],
      },
    },
  },

  // ── msclkid ──────────────────────────────────────────────────
  {
    slug: "msclkid",
    param: "msclkid",
    kind: "ads",
    searchDemand: "medium",
    vendor: { name: "Microsoft Advertising (Bing Ads)", year: 2018, family: "Microsoft" },
    related: ["gclid", "fbclid", "ttclid", "twclid", "yclid", "li-fat-id"],
    content: {
      en: {
        title: "msclkid — Microsoft Ads' click ID, explained · LinkClean",
        description:
          "msclkid is the Microsoft Click ID — Bing/Microsoft Ads' per-click identifier, the equivalent of Google's gclid. LinkClean strips it by default.",
        tldr: "msclkid is the Microsoft Click ID — Bing/Microsoft Ads' equivalent of gclid. It ties the click to the ad-account that paid for it. Strip it before sharing.",
        sections: [
          {
            heading: "What msclkid does",
            paragraphs: [
              "Click any ad on Bing search, Microsoft's content network, or LinkedIn Sponsored Content, and Microsoft's ad system appends ?msclkid=<opaque token> to the destination URL. The token encodes the advertiser account, the campaign, the ad group, and the click — same job as gclid for Google Ads.",
              "On the destination, the Microsoft UET tag (the Microsoft equivalent of Meta Pixel) reads msclkid and reports the conversion back to Microsoft Advertising. That's how Bing Ads tracks which ad delivered the customer.",
            ],
          },
          {
            heading: "Why it shows up more often than you'd expect",
            paragraphs: [
              "Bing's share of US search is small (~6%) but its ads syndicate to Yahoo, DuckDuckGo (for some queries), and parts of Microsoft's content network. So msclkid lands on outbound URLs from a broader surface than just Bing.com itself.",
              "It's also on ad-driven LinkedIn clicks. LinkedIn's ad platform shares plumbing with Microsoft Advertising, so Sponsored Content clicks frequently carry msclkid alongside LinkedIn's own rcm parameter.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "msclkid is in LinkClean's default ads catalog alongside the other vendor-specific click IDs (gclid, gbraid, wbraid, fbclid, ttclid, yclid). All stripped on every host — these names don't legitimately appear as functional keys anywhere.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/landing?msclkid=8e2a1b3c4d5f6789a0b1c2d3e4f5a6b7",
        exampleClean: "https://example.com/landing",
        faq: [
          {
            q: "Will removing msclkid break the link?",
            a: "No. The page loads identically. msclkid is only read by Microsoft's UET conversion-tracking script (if it's installed); the destination page server doesn't use it for anything.",
          },
          {
            q: "Is msclkid the same as gclid?",
            a: "Same role on a different ad network. gclid is Google Ads', msclkid is Microsoft Advertising's. LinkClean strips both by default.",
          },
          {
            q: "Does msclkid affect prices or offers I see?",
            a: "Not in any common case. It's an attribution token for the advertiser's bookkeeping, not a coupon or merchant-side session ID.",
          },
        ],
      },
    },
  },

  // ── ttclid ───────────────────────────────────────────────────
  {
    slug: "ttclid",
    param: "ttclid",
    kind: "ads",
    searchDemand: "medium",
    vendor: { name: "TikTok Ads", year: 2020, family: "TikTok" },
    related: ["fbclid", "gclid", "msclkid", "twclid", "sc-click-id", "rdt-cid", "epik", "spm"],
    content: {
      en: {
        title: "ttclid — TikTok's click ID, explained · LinkClean",
        description:
          "ttclid is TikTok Ads' per-click identifier — added to outbound links from TikTok ads. The TikTok equivalent of fbclid. LinkClean strips it by default.",
        tldr: "ttclid is TikTok Ads' per-click identifier — added to outbound links from TikTok ads to credit ad spend. Forwarding it carries TikTok's attribution token into someone else's browser. Strip it.",
        sections: [
          {
            heading: "What ttclid does",
            paragraphs: [
              "When you click a link inside TikTok or an outbound TikTok Ad, TikTok appends ?ttclid=<opaque token> to the destination URL. The token ties that click back to the ad impression, the advertiser, and (where TikTok still has a cookie / IDFA) your TikTok identity.",
              "On the destination, the TikTok Pixel (or the server-side Events API) reads ttclid and reports the click back to TikTok for conversion attribution. Same architecture as Meta Pixel + fbclid.",
            ],
          },
          {
            heading: "Plus _ttp",
            paragraphs: [
              "TikTok also drops a _ttp parameter alongside ttclid in some flows — it mirrors a cookie the TikTok Pixel reads to bridge browsers that don't accept third-party cookies. LinkClean strips _ttp too.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "ttclid and _ttp both ship default-on in LinkClean's ads catalog. Same pipeline as fbclid, gclid, msclkid, yclid — vendor-specific tokens with no legitimate non-tracking use anywhere on the web.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/product?ttclid=E.C.P.aabbccddeeff112233445566778899",
        exampleClean: "https://example.com/product",
        faq: [
          {
            q: "Does removing ttclid break the link?",
            a: "No. The destination page never reads it — only the TikTok Pixel does, and that's TikTok's bookkeeping, not yours.",
          },
          {
            q: "Is ttclid personal data?",
            a: "It can be joined back to your TikTok session on TikTok's side, so for them, yes — they know which click it was. The URL itself doesn't name you.",
          },
          {
            q: "What about _ttp?",
            a: "_ttp is TikTok's cookie-mirroring URL parameter — it carries the Pixel's first-party cookie ID across browsers that block third-party cookies. LinkClean strips it too.",
          },
        ],
      },
    },
  },

  // ── gbraid ───────────────────────────────────────────────────
  {
    slug: "gbraid",
    param: "gbraid",
    kind: "ads",
    searchDemand: "high",
    vendor: {
      name: "Google Ads",
      year: 2021,
      platform: "iOS app-install attribution after ATT",
      family: "Google",
    },
    related: ["wbraid", "gclid", "dclid", "fbclid"],
    content: {
      en: {
        title: "gbraid — Google Ads' iOS app-attribution ID · LinkClean",
        searchTitle: "What is gbraid?",
        description:
          "gbraid is Google Ads' iOS app-install attribution ID — rolled out 2021 after Apple's ATT broke gclid on iOS. Strip it before sharing.",
        tldr: "gbraid is the **post-ATT replacement for gclid in iOS app-install flows**. Google Ads added it in 2021 after Apple's App Tracking Transparency made the classic cookie-based gclid unusable on iOS. It attributes ad clicks → app installs without needing a cross-app identifier.",
        sections: [
          {
            heading: "Why gbraid exists (the ATT story)",
            paragraphs: [
              "When Apple rolled out App Tracking Transparency with iOS 14.5 (April 2021), every app had to ask permission to track users across apps and websites. Most users said no. That broke Google Ads' classic gclid model on iOS, which relied on a cross-app cookie/IDFA join to attribute an ad click to an eventual app install or web conversion.",
              "Google's response was gbraid: an aggregated, privacy-respecting click identifier that doesn't need cross-app tracking permission. It attributes click → install at a campaign / ad-group level rather than at a per-user level, and works whether or not the user gave ATT permission.",
            ],
          },
          {
            heading: "Where you'll see it",
            paragraphs: [
              "gbraid lands on iOS Google Ads links headed to App Store or web destinations. If you tap a Google Search ad on iPhone Safari and the destination is an App Store page, the URL usually has `?gbraid=<token>` attached.",
              "It pairs with wbraid (web-only, iOS) and the classic gclid (everything else). All three coexist in Google Ads, used depending on platform context.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "gbraid is in LinkClean's default ads catalog, stripped on every host. Same default-on treatment as gclid, wbraid, fbclid, msclkid, ttclid, yclid. Reverse-engineering by Branch and other attribution vendors documented gbraid's role; Google's own developer docs confirm it as the ATT-compatible replacement.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/app-landing?gbraid=0AAAAAo123_4567abc-defghij",
        exampleClean: "https://example.com/app-landing",
        faq: [
          {
            q: "Is gbraid the same as gclid?",
            a: "Same role (ad-click attribution for Google Ads), different mechanism. gclid is per-click and cookie-bound; gbraid is aggregated at a campaign level and works without cross-app tracking permission. Both are stripped by LinkClean.",
          },
          {
            q: "What changed with iOS 14 ATT that made gbraid necessary?",
            a: "Apple's App Tracking Transparency, introduced in iOS 14.5 (April 2021), forced apps to request explicit permission to track users across apps and websites. Most users said no, breaking gclid's cross-cookie model. Google introduced gbraid as the aggregated, privacy-respecting iOS replacement.",
          },
          {
            q: "Does gbraid follow me as an individual?",
            a: "Less than gclid did. It attributes at campaign/ad-group level, not per-individual. From a privacy standpoint it's a smaller leak than gclid — but still attribution metadata you don't need to forward.",
          },
          {
            q: "Will the page load without gbraid?",
            a: "Yes. The destination server doesn't read it — only Google's conversion-tracking script does, post-load.",
          },
        ],
      },
    },
  },

  // ── wbraid ───────────────────────────────────────────────────
  {
    slug: "wbraid",
    param: "wbraid",
    kind: "ads",
    searchDemand: "medium",
    vendor: {
      name: "Google Ads",
      year: 2021,
      platform: "iOS web attribution after ATT",
      family: "Google",
    },
    related: ["gbraid", "gclid", "fbclid", "dclid"],
    content: {
      en: {
        title: "wbraid — Google Ads' iOS web-attribution ID · LinkClean",
        searchTitle: "What is wbraid?",
        description:
          "wbraid is Google Ads' iOS web-attribution ID — the post-ATT replacement for gclid on iOS web flows. Strip it before sharing.",
        tldr: "wbraid is the **post-ATT replacement for gclid on iOS web destinations**. Same era and motivation as gbraid (rolled out 2021), but used when the destination is a website rather than an app. Aggregates attribution at a campaign level instead of per-user.",
        sections: [
          {
            heading: "What wbraid does (and how it differs from gbraid)",
            paragraphs: [
              "wbraid and gbraid are sibling iOS-era replacements for gclid. The difference is the destination: gbraid is for iOS app-install attribution (clicks that end up at the App Store), wbraid is for iOS web attribution (clicks that end up on a normal website). Both work without needing App Tracking Transparency permission.",
              "If you tap a Google Search ad on iPhone and the destination is a web page, the URL usually has `?wbraid=<token>`. Tap one that links to App Store, and the URL has gbraid instead. The two never coexist on the same URL.",
            ],
          },
          {
            heading: "Why both exist",
            paragraphs: [
              "Apple treats web destinations and App Store destinations differently for privacy bookkeeping, so Google needed two parallel mechanisms — one for each side. Both aggregate clicks rather than identify users individually, both work without ATT consent, and both feed into Google Ads' same conversion-attribution dashboard on the advertiser's side.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "wbraid ships default-on in the ads catalog. Same pipeline as gbraid + gclid + every other vendor-specific click identifier — stripped on every host.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/landing?wbraid=ABw-xyz0123_4abcdefgh",
        exampleClean: "https://example.com/landing",
        faq: [
          {
            q: "When do I see wbraid vs gbraid?",
            a: "wbraid on iOS clicks heading to web destinations; gbraid on iOS clicks heading to the App Store. The two never coexist on the same URL.",
          },
          {
            q: "Is wbraid still tracking me individually?",
            a: "Not the way gclid did. It aggregates at campaign level. But it still records that a click happened from your iOS device toward a specific ad, and Google can join it back to broader signals on their side.",
          },
          {
            q: "Will removing wbraid hurt the page?",
            a: "No. The destination web server doesn't read it. Only Google Ads' conversion-tracking script does, on the destination, after load.",
          },
        ],
      },
    },
  },

  // ── dclid ────────────────────────────────────────────────────
  {
    slug: "dclid",
    param: "dclid",
    kind: "ads",
    searchDemand: "medium",
    vendor: {
      name: "Google Display & Video 360 (formerly DoubleClick)",
      year: 2008,
      platform: "display + video network",
      family: "Google",
    },
    related: ["gclid", "gbraid", "wbraid", "fbclid", "srsltid"],
    content: {
      en: {
        title: "dclid — Google's DoubleClick / DV360 click ID · LinkClean",
        searchTitle: "What is dclid?",
        description:
          "dclid is the DoubleClick click identifier — used by Google's display + video ad network (DV360). The display-network analog of gclid. Strip it.",
        tldr: "dclid is Google's **display-and-video click identifier** — the DoubleClick / Display & Video 360 (DV360) analog of gclid. Where gclid is for Search Ads, dclid is for display-network and YouTube video ads.",
        sections: [
          {
            heading: "What dclid actually identifies",
            paragraphs: [
              "Google's Display & Video 360 (formerly DoubleClick Campaign Manager — the “dc” in dclid) runs the display-banner and YouTube-pre-roll side of Google's ad business. Where Search Ads use gclid, DV360 uses dclid: same role (tie the click to the impression, campaign, ad creative), different ad network.",
              "DoubleClick was acquired by Google in 2008 and folded into the Marketing Platform; dclid has carried the “dc” prefix from that era forward.",
            ],
          },
          {
            heading: "Where you'll see it",
            paragraphs: [
              "On display banners served via Google's Display Network, on pre-roll ads served on YouTube and DV360's video supply, and on outbound clicks from those surfaces. Often shows up *alongside* gclid on links that pass through multiple Google ad systems.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on in the ads catalog. Same pipeline as gclid, gbraid, wbraid, msclkid, fbclid.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/landing?dclid=CKjK8q-abcde12345fghij&utm_source=display&utm_campaign=spring",
        exampleClean: "https://example.com/landing",
        faq: [
          {
            q: "Why is dclid sometimes alongside gclid?",
            a: "When a click passes through more than one Google ad system (e.g. a Display Network banner that's also tied to a Search campaign), both ad networks tag the URL. Both belong to the same advertiser's Google Ads account but feed different attribution reports.",
          },
          {
            q: "Is dclid still in use after the DoubleClick rebrand?",
            a: "Yes. Display & Video 360 (DV360) inherited the dclid scheme from DoubleClick Campaign Manager. The brand changed; the URL parameter didn't.",
          },
          {
            q: "Does dclid carry per-user identity?",
            a: "Less than gclid did pre-iOS-14. Today it's largely aggregated for attribution — but still ad-tracking metadata you don't need to forward.",
          },
        ],
      },
    },
  },

  // ── srsltid ──────────────────────────────────────────────────
  {
    slug: "srsltid",
    param: "srsltid",
    kind: "ads",
    searchDemand: "medium",
    vendor: {
      name: "Google Shopping",
      year: 2019,
      platform: "Free + paid Shopping listings",
      family: "Google",
    },
    related: ["gclid", "dclid", "utm-source"],
    content: {
      en: {
        title: "srsltid — Google Shopping result-listing ID · LinkClean",
        searchTitle: "What is srsltid?",
        description:
          "srsltid is Google Shopping's search-result listing ID — added to clicks from the Shopping tab and free product listings. Strip it.",
        tldr: "srsltid is Google Shopping's **search-result listing ID** — added to every outbound click from the Shopping tab (paid and free Product Listings alike). Identifies which result panel was clicked, useful only for Google's conversion bookkeeping.",
        sections: [
          {
            heading: "What srsltid actually does",
            paragraphs: [
              "Google Shopping (the Shopping tab on Search, plus free Product Listings rolled out in 2020) uses srsltid to identify which specific listing on the results page got the click. The value encodes the result-position, the merchant feed entry, and the campaign/free-listing context.",
              "On the destination — typically the merchant's product page — srsltid is read by Google's conversion-tracking script (or by the merchant's analytics if they wire it up) to credit the visit to the Shopping result.",
            ],
          },
          {
            heading: "Why it shows up on links you didn't expect",
            paragraphs: [
              "Shopping listings can syndicate widely — into Google's universal search results, into category pages on partner sites, into Google Lens product searches. Any of those click paths can carry srsltid. So forwarded product links sometimes have it attached even when neither sender nor recipient went through the Shopping tab directly.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "srsltid is in LinkClean's default ads catalog, stripped on every host. The merchant's product page doesn't need it — the path resolves the product on its own.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/products/widget?srsltid=AfmBOoq0123abc_456_def-789",
        exampleClean: "https://example.com/products/widget",
        faq: [
          {
            q: "Is srsltid on free Shopping listings, or only paid?",
            a: "Both. Google Shopping went freemium in 2020 — most product listings are now free, with paid ads mixed in. srsltid lands on both flavours.",
          },
          {
            q: "Does the merchant see srsltid?",
            a: "Only if they've wired conversion tracking. The URL routes on the path; srsltid is metadata for whoever is reading it (Google's conversion-tag is the primary reader).",
          },
          {
            q: "Will the product page still load?",
            a: "Yes. srsltid is purely attribution metadata.",
          },
        ],
      },
    },
  },

  // ── gad_source ───────────────────────────────────────────────
  {
    slug: "gad-source",
    param: "gad_source",
    kind: "ads",
    searchDemand: "high",
    vendor: {
      name: "Google Ads",
      year: 2023,
      platform: "GA4 enhanced-conversion era",
      family: "Google",
    },
    related: ["gclid", "gad-campaignid", "utm-source", "utm-id"],
    content: {
      en: {
        title: "gad_source — Google Ads' new source identifier · LinkClean",
        searchTitle: "What is gad_source?",
        description:
          "gad_source is a new Google Ads parameter rolled out in 2023 alongside the GA4 + enhanced-conversions stack. It encodes the source of the click. Strip it.",
        tldr: "gad_source is one of Google Ads' **newer auto-tagged URL parameters** (rolled out late 2023 alongside GA4's enhanced conversions). Encodes a numeric source identifier (`gad_source=1` = Search Ads, etc.). Strip it like the rest of the Google Ads tail.",
        sections: [
          {
            heading: "What gad_source encodes",
            paragraphs: [
              "Google's auto-tagging system gained a series of `gad_*` parameters in 2023 as part of the GA4 migration. gad_source is a small numeric code — typically a single digit — that identifies which Google Ads surface generated the click. Community-observed values include 1 (Search Ads), 2 (Display Network), 3 (YouTube), 4 (Discovery / Performance Max), 5 (Shopping).",
              "On its own gad_source carries less attribution power than gclid — but it's used in combination with gad_campaignid and the older gclid to disambiguate where a click came from when Google's downstream analytics joins the data.",
            ],
          },
          {
            heading: "Why it appeared recently",
            paragraphs: [
              "GA4 deprecated some of the older referrer-driven source attribution that Universal Analytics relied on. To keep the source/medium dimension populated reliably in GA4, Google started adding gad_source + gad_campaignid to outbound clicks as supplementary first-party tags. They sit alongside the classic utm_* and gclid rather than replacing them.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on. Same default-on treatment as the rest of the gad_* family. No legitimate non-tracking use of this exact name.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/landing?gad_source=1&gad_campaignid=12345678&gclid=Cj0KCQ",
        exampleClean: "https://example.com/landing",
        faq: [
          {
            q: "Why did Google add gad_source if gclid already existed?",
            a: "Because GA4 needed first-party source/medium signals that don't rely on the cookie or referrer plumbing Universal Analytics had used. gad_source + gad_campaignid are durable first-party tags that survive cookie restrictions.",
          },
          {
            q: "What do the gad_source numeric values mean?",
            a: "Community observation: 1 = Search Ads, 2 = Display Network, 3 = YouTube, 4 = Discovery / Performance Max, 5 = Shopping. Google has not formally documented the mapping.",
          },
          {
            q: "Will removing gad_source affect what I see?",
            a: "No. It's read by analytics scripts, not by the destination page.",
          },
        ],
      },
    },
  },

  // ── gad_campaignid ───────────────────────────────────────────
  {
    slug: "gad-campaignid",
    param: "gad_campaignid",
    kind: "ads",
    searchDemand: "medium",
    vendor: {
      name: "Google Ads",
      year: 2023,
      platform: "GA4 enhanced-conversion era",
      family: "Google",
    },
    related: ["gad-source", "gclid", "utm-campaign"],
    content: {
      en: {
        title: "gad_campaignid — Google Ads' campaign ID · LinkClean",
        searchTitle: "What is gad_campaignid?",
        description:
          "gad_campaignid is Google Ads' newer first-party campaign identifier — added 2023 alongside gad_source for GA4's enhanced conversions. Strip it.",
        tldr: "gad_campaignid is **Google Ads' newer first-party campaign identifier**, rolled out 2023 alongside gad_source. It's a numeric campaign ID added directly to outbound URLs so GA4 can attribute clicks without relying on the cookie/referrer plumbing Universal Analytics used.",
        sections: [
          {
            heading: "Why a campaign ID needed to live in the URL",
            paragraphs: [
              "Universal Analytics depended on the GA cookie and on referrer headers to attribute campaigns. Both have become unreliable under modern browser-privacy regimes (Safari Intelligent Tracking Prevention, Firefox Total Cookie Protection, Chrome Privacy Sandbox). GA4's design moved more of the attribution signal into first-party URL tags — the gad_* family is part of that shift.",
              "gad_campaignid sits alongside the human-readable utm_campaign and the legacy gclid, giving Google Ads three different ways to bind a click to a campaign: utm_campaign for the GA dashboard, gad_campaignid for first-party numeric attribution, gclid for the Ads-side conversion record.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on. Same default-on treatment as gclid, gad_source, gbraid, wbraid.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/sale?gad_source=1&gad_campaignid=12345678&gclid=Cj0KCQ&utm_campaign=spring",
        exampleClean: "https://example.com/sale",
        faq: [
          {
            q: "Does gad_campaignid duplicate utm_campaign?",
            a: "Almost — but utm_campaign is the human-readable string the marketer typed, gad_campaignid is the numeric identifier Google generates. Two views of the same campaign, both meant for different downstream tools.",
          },
          {
            q: "Why three campaign identifiers on one URL?",
            a: "Different audiences read different tags. utm_campaign for the publisher's GA4 dashboard, gad_campaignid for Google Ads' first-party attribution, gclid for the Ads conversion record.",
          },
        ],
      },
    },
  },

  // ── yclid ────────────────────────────────────────────────────
  {
    slug: "yclid",
    param: "yclid",
    kind: "ads",
    searchDemand: "medium",
    vendor: { name: "Yandex Direct", year: 2010, family: "Yandex" },
    related: ["gclid", "fbclid", "msclkid"],
    content: {
      en: {
        title: "yclid — Yandex Ads' click ID, explained · LinkClean",
        searchTitle: "What is yclid?",
        description:
          "yclid is Yandex Direct's per-click identifier — the Russian equivalent of gclid for Yandex's search-ads network. LinkClean strips it by default.",
        tldr: "yclid is **Yandex's click identifier** — same role as gclid (Google) or msclkid (Microsoft) but for Yandex Direct, the dominant ad network on Russian-speaking search. Strip it before sharing.",
        sections: [
          {
            heading: "What yclid does",
            paragraphs: [
              "Yandex Direct (Yandex's ad platform) appends `?yclid=<token>` to outbound paid-search clicks the same way Google appends gclid and Microsoft appends msclkid. The token encodes the advertiser, the campaign, the ad-group, and the click — used by Yandex's Metrica analytics on the destination to credit the conversion.",
              "Yandex is the second-largest search engine in Russia and significant in a handful of post-Soviet markets. yclid shows up on outbound ad clicks from yandex.ru (and historically from go.mail.ru when that partnership was active).",
            ],
          },
          {
            heading: "Why it's worth stripping anyway",
            paragraphs: [
              "Even if you're not in a Yandex-heavy market, yclid lands on links you might receive from people who are. Forwarding it follows the same logic as fbclid: the click ID is bound to a Yandex session on their side, and propagating it leaks attribution metadata into your forward.",
              "Yandex also runs `ymclid` (a related Yandex.Metrica click ID), which LinkClean's reference catalog covers in the opt-in set.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "yclid ships default-on in the ads catalog alongside gclid, fbclid, msclkid, ttclid.",
            ],
          },
        ],
        exampleDirty: "https://example.com/landing?yclid=14123456789012345",
        exampleClean: "https://example.com/landing",
        faq: [
          {
            q: "Where do most yclid-tagged links come from?",
            a: "Yandex Direct (paid-search ads on yandex.ru and the Yandex ad network). Most common on Russian-language pages; you'll see it less often outside that ecosystem.",
          },
          {
            q: "Does Yandex have a Pixel-equivalent that reads yclid?",
            a: "Yes — Yandex.Metrica. Functionally similar to Google Analytics + Meta Pixel: a script on the destination page reads yclid and reports the conversion to Yandex.",
          },
          {
            q: "Is yclid in LinkClean by default?",
            a: "Yes. Default-on, stripped on every host.",
          },
        ],
      },
    },
  },

  // ── twclid ───────────────────────────────────────────────────
  {
    slug: "twclid",
    param: "twclid",
    kind: "ads",
    searchDemand: "high",
    vendor: { name: "X Ads (formerly Twitter Ads)", year: 2021, family: "X (Twitter)" },
    related: ["fbclid", "gclid", "ttclid", "msclkid", "epik", "sc-click-id", "li-fat-id", "rdt-cid", "s-twitter"],
    content: {
      en: {
        title: "twclid — X (Twitter) Ads' click ID, explained · LinkClean",
        searchTitle: "What is twclid?",
        description:
          "twclid is X (Twitter) Ads' per-click identifier — the X equivalent of fbclid. Added to outbound ad clicks. LinkClean strips it.",
        tldr: "twclid is **X / Twitter Ads' click identifier**, rolled out in 2021. The X equivalent of fbclid for Meta or gclid for Google Ads. Attaches to outbound clicks from sponsored tweets and Twitter Ads creatives.",
        sections: [
          {
            heading: "What twclid does",
            paragraphs: [
              "When you click a promoted tweet or any Twitter Ads creative, X appends `?twclid=<token>` to the destination URL. The token ties the click to the ad impression on X's side and lets X's Pixel-equivalent (Twitter Pixel / Universal Website Tag) report the conversion back on the destination.",
              "twclid replaced an older system X used pre-2021 that depended on referrer headers. Like Meta and Google before it, X moved attribution from cross-site cookies into the URL itself as browsers tightened privacy plumbing.",
            ],
          },
          {
            heading: "How it differs from `t=` and `s=` on tweet links",
            paragraphs: [
              "twclid is on **ad** outbound URLs. The `t=` / `s=` parameters covered in the X share-URL deep dive are on **organic** tweet share URLs — different system, different purpose. A single click rarely carries both, since you're either clicking an ad or sharing a tweet, not both at once.",
              "LinkClean strips twclid globally and strips `t=` / `s=` host-scoped to x.com and twitter.com (since `t=` is the timestamp on YouTube).",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on in the ads catalog. Same pipeline as fbclid + gclid + msclkid + ttclid + yclid.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/product?twclid=2-1abcde1234567890fghijklmnop",
        exampleClean: "https://example.com/product",
        faq: [
          {
            q: "Is twclid the same as the t= on a shared tweet URL?",
            a: "No. twclid is X Ads' click identifier — only on outbound ad clicks. t= and s= on tweet share URLs are organic-share trackers. Different systems, different jobs.",
          },
          {
            q: "Did X have a click ID before twclid?",
            a: "Not in URL form. Pre-2021 X relied on referrer headers and cookies. Browser-privacy changes made that unreliable; twclid moved attribution into the URL itself, the same pattern Meta and Google followed earlier.",
          },
          {
            q: "Does LinkClean strip twclid on every site?",
            a: "Yes — global, default-on. (twclid is unambiguous; no legitimate use of this name on the web besides X Ads.)",
          },
        ],
      },
    },
  },

  // ── epik ─────────────────────────────────────────────────────
  {
    slug: "epik",
    param: "epik",
    kind: "ads",
    searchDemand: "medium",
    vendor: { name: "Pinterest Ads", year: 2018, family: "Pinterest" },
    related: ["fbclid", "ttclid", "twclid"],
    content: {
      en: {
        title: "epik — Pinterest's click identifier, explained · LinkClean",
        searchTitle: "What is epik?",
        description:
          "epik is Pinterest's per-click identifier — added to outbound clicks from Pinterest pins and ads. The Pinterest equivalent of fbclid. LinkClean strips it.",
        tldr: "epik is **Pinterest's per-click identifier** — added to outbound clicks from both organic pins and paid Pinterest Ads. The Pinterest equivalent of fbclid. Strip it before forwarding.",
        sections: [
          {
            heading: "What epik does",
            paragraphs: [
              "Pinterest's tracking pixel (Pinterest Tag) reads epik on destination pages to attribute the click back to the pin and (where applicable) the ad-account. The token encodes the click context and is bound to the Pinterest session that produced it.",
              "Unlike fbclid (which is mainly on Meta-served ad clicks), epik shows up on a wider range of Pinterest outbound URLs — organic-pin clicks carry it too, since Pinterest's growth model leans heavily on tracking which pins drive off-platform engagement.",
            ],
          },
          {
            heading: "Privacy posture",
            paragraphs: [
              "epik is tied to your Pinterest session on Pinterest's side. Forwarding it sends Pinterest a click signal joined to your account context, the same way forwarding fbclid does to Meta.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on, every host. In LinkClean's reference catalog (Pinterest family).",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/article?epik=dj0yJnU9aDhpeXh1V0RPRjlXVDVNYTBzMDdwUkc",
        exampleClean: "https://example.com/article",
        faq: [
          {
            q: "Does epik appear on free (non-ad) Pinterest clicks?",
            a: "Yes. Pinterest tracks outbound traffic from organic pins as well as paid ads — epik is on both.",
          },
          {
            q: "What's the Pinterest equivalent of Meta Pixel?",
            a: "Pinterest Tag — the script that reads epik on destination pages and reports conversions back to Pinterest Ads.",
          },
          {
            q: "Is epik personal data?",
            a: "It's tied to your Pinterest session on Pinterest's side. The URL doesn't say “you”, but Pinterest can join it to your account.",
          },
        ],
      },
    },
  },

  // ── sc_click_id ──────────────────────────────────────────────
  {
    slug: "sc-click-id",
    param: "sc_click_id",
    kind: "ads",
    searchDemand: "medium",
    vendor: { name: "Snap Ads (Snapchat)", year: 2018, family: "Snapchat" },
    related: ["fbclid", "ttclid", "twclid"],
    content: {
      en: {
        title: "sc_click_id — Snapchat Ads' click identifier · LinkClean",
        searchTitle: "What is sc_click_id?",
        description:
          "sc_click_id is Snap Ads' per-click identifier — added to outbound clicks from Snapchat ads. The Snapchat equivalent of fbclid. LinkClean strips it.",
        tldr: "sc_click_id is **Snap Ads' per-click identifier**. The Snapchat equivalent of fbclid (Meta) or ttclid (TikTok). Added to outbound clicks from sponsored snaps and Snap Ads creatives.",
        sections: [
          {
            heading: "What sc_click_id does",
            paragraphs: [
              "Snap Pixel (Snap's destination-tag) reads sc_click_id and reports the click back to Snap Ads' attribution. Same job as fbclid for Meta — tie the click to the ad impression and the Snapchat session that saw it.",
              "Snap Ads were launched in 2016; the URL-based click ID became the dominant attribution mechanism after Apple's App Tracking Transparency (iOS 14.5, 2021) made cross-app identifiers unreliable. Like Meta and Google, Snap moved attribution into the URL.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on. Same pipeline as the other vendor click IDs.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/app-page?sc_click_id=a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        exampleClean: "https://example.com/app-page",
        faq: [
          {
            q: "Is sc_click_id mainly mobile-app or web?",
            a: "Both. Most Snap Ads link to an App Store install or a web destination from iOS / Android, so sc_click_id lands on whichever flavour the campaign targets.",
          },
          {
            q: "Did Snap have a different click ID before sc_click_id?",
            a: "Pre-iOS-14 Snap relied more heavily on the IDFA + Snap-Pixel cookie. After ATT broke that, sc_click_id became the primary attribution surface.",
          },
        ],
      },
    },
  },

  // ── li_fat_id ────────────────────────────────────────────────
  {
    slug: "li-fat-id",
    param: "li_fat_id",
    kind: "ads",
    searchDemand: "high",
    vendor: { name: "LinkedIn Ads", year: 2017, family: "LinkedIn" },
    related: ["msclkid", "fbclid", "twclid"],
    content: {
      en: {
        title: "li_fat_id — LinkedIn Ads' email-based click ID · LinkClean",
        searchTitle: "What is li_fat_id?",
        description:
          "li_fat_id is LinkedIn's First-party Ad Tracking ID — joins LinkedIn ad clicks to the member's email-keyed identity. Strip it.",
        tldr: "li_fat_id is **LinkedIn's First-party Ad Tracking identifier** — “fat” = First-party Ad Tracking. Tied to the LinkedIn member who clicked, via the email address they registered with. Higher privacy stakes than most ad-click IDs.",
        sections: [
          {
            heading: "Why li_fat_id is different",
            paragraphs: [
              "Most ad-network click IDs (fbclid, gclid, msclkid, ttclid) are tied to a *session* on the ad network's side — joinable to your account on their books, but not literally your email address.",
              "li_fat_id is unusual: it's tied to LinkedIn's first-party identity record for the member, which is keyed to their email address. LinkedIn pioneered this so it could keep attribution working across browsers that block third-party cookies — but the result is an ad-click ID more tightly bound to a named-individual identity than the rest.",
              "Forwarding li_fat_id leaks an identifier joined directly to the original member's LinkedIn email. The blast radius is closer to Mailchimp's mc_eid than to fbclid.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "li_fat_id is in LinkedIn's reference catalog and ships on by default for LinkedIn ad-link cleaning. LinkClean also strips `rcm` (LinkedIn's share/recommendation token) host-scoped to linkedin.com.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/landing?li_fat_id=2a1b3c4d-5e6f-7890-abcd-ef1234567890",
        exampleClean: "https://example.com/landing",
        faq: [
          {
            q: "What does “FAT” stand for in li_fat_id?",
            a: "First-party Ad Tracking. LinkedIn's name for their cookie-independent click-attribution system, introduced to keep conversion measurement working under Safari's Intelligent Tracking Prevention and Firefox's tracking protections.",
          },
          {
            q: "Is li_fat_id more personal than fbclid?",
            a: "Yes. It's bound to the LinkedIn member's email-address identity on LinkedIn's side, not just a session cookie. Forwarding it leaks an identifier closer to an email address than to a fbclid-style click session.",
          },
          {
            q: "Does LinkedIn also use rcm?",
            a: "Yes — rcm is LinkedIn's share/recommendation token (a different identifier from li_fat_id). LinkClean strips it too, host-scoped to linkedin.com.",
          },
        ],
      },
    },
  },

  // ── spm ──────────────────────────────────────────────────────
  {
    slug: "spm",
    param: "spm",
    kind: "ads",
    searchDemand: "medium",
    vendor: { name: "Alibaba", year: 2013, platform: "Tmall / Taobao / Aliexpress", family: "Alibaba" },
    related: ["gclid", "fbclid", "ttclid"],
    content: {
      en: {
        title: "spm — Alibaba's “Super Position Model” tracker · LinkClean",
        searchTitle: "What is spm?",
        description:
          "spm is Alibaba's Super Position Model tracker — used across Tmall, Taobao, AliExpress, and 1688 to record where on the page a click came from. Strip it.",
        tldr: "spm is **Alibaba's Super Position Model tracker** — a dotted-path identifier added to outbound clicks from Tmall, Taobao, AliExpress, and 1688. Encodes the exact pixel-position where a user clicked. Used at scale across the Alibaba ecosystem.",
        sections: [
          {
            heading: "What spm encodes",
            paragraphs: [
              "Alibaba's Super Position Model (SPM) breaks every page into a hierarchy of positions: site → page → module → click-position. spm values are dotted strings encoding that hierarchy — e.g. `spm=a2e0r.13076974.shop.1.5c4f1d4eXyz`. Each segment names a level in the click context.",
              "Useful to Alibaba for understanding which surface, module, and position on the page drive conversions across an enormous catalogue. Adopted across Tmall (天猫), Taobao (淘宝), AliExpress, 1688, and several other Alibaba properties.",
            ],
          },
          {
            heading: "Why strip it",
            paragraphs: [
              "spm doesn't carry personal identity on its own, but it does telegraph the exact UI surface the share came from — which can be more revealing than the sender intended. Forwarding it tells Alibaba's analytics where the click chain started.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "spm is in LinkClean's reference catalog (Alibaba family).",
            ],
          },
        ],
        exampleDirty:
          "https://item.example.com/i/123456?spm=a2e0r.13076974.shop.1.5c4f1d4eABC",
        exampleClean: "https://item.example.com/i/123456",
        faq: [
          {
            q: "Does spm appear outside Alibaba sites?",
            a: "Rarely. It's tightly bound to Alibaba's UI-position model, and the dotted-path format isn't a convention other platforms have adopted.",
          },
          {
            q: "Is it personal data?",
            a: "Not in the URL itself. But Alibaba can join spm to the session that produced it on their side.",
          },
        ],
      },
    },
  },

  // ── rdt_cid ──────────────────────────────────────────────────
  {
    slug: "rdt-cid",
    param: "rdt_cid",
    kind: "ads",
    searchDemand: "low",
    vendor: { name: "Reddit Ads", year: 2019, family: "Reddit" },
    related: ["fbclid", "twclid", "ttclid"],
    content: {
      en: {
        title: "rdt_cid — Reddit Ads' click identifier · LinkClean",
        searchTitle: "What is rdt_cid?",
        description:
          "rdt_cid is Reddit Ads' per-click identifier — added to outbound clicks from sponsored posts and ads. LinkClean strips it by default.",
        tldr: "rdt_cid is **Reddit Ads' per-click identifier** — the Reddit equivalent of fbclid. Attached to outbound clicks from Promoted Posts and other Reddit Ads surfaces.",
        sections: [
          {
            heading: "What rdt_cid does",
            paragraphs: [
              "Reddit Pixel reads rdt_cid on destination pages and attributes the click back to the Reddit Ads campaign. Same architecture as Meta Pixel + fbclid.",
              "Reddit Ads matured later than its competitors (the modern ad-targeting platform launched around 2019). rdt_cid is therefore relatively recent — most Reddit-Ads-attributed click tracking pre-2019 ran via the older promoted-post mechanism without URL-based identifiers.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on in the ads catalog.",
            ],
          },
        ],
        exampleDirty: "https://example.com/landing?rdt_cid=4567890abcdef1234",
        exampleClean: "https://example.com/landing",
        faq: [
          {
            q: "Is rdt_cid the same as fbclid?",
            a: "Same shape (per-click identifier added to outbound URLs), different ad network. fbclid for Meta; rdt_cid for Reddit.",
          },
          {
            q: "Did Reddit Ads always have rdt_cid?",
            a: "No. It came in with Reddit's modernised ads platform around 2019. Earlier sponsored-content systems didn't use URL-based click IDs.",
          },
        ],
      },
    },
  },

  // ── mc_cid ───────────────────────────────────────────────────
  {
    slug: "mc-cid",
    param: "mc_cid",
    kind: "email",
    searchDemand: "high",
    vendor: { name: "Mailchimp", year: 2007, family: "Mailchimp" },
    related: ["mc-eid", "mc-tc", "mkt-tok", "utm-source", "hsmi"],
    content: {
      en: {
        title: "mc_cid — Mailchimp's campaign identifier · LinkClean",
        searchTitle: "What is mc_cid?",
        description:
          "mc_cid is Mailchimp's campaign identifier — names which campaign the link belongs to. Companion to mc_eid (per-recipient). Strip both.",
        tldr: "mc_cid is **Mailchimp's campaign identifier** — names which Mailchimp campaign the link belongs to (the campaign-level identifier; mc_eid is the per-recipient one). Stripping mc_cid is less sensitive than mc_eid but pairs with it on every Mailchimp link.",
        sections: [
          {
            heading: "mc_cid vs mc_eid",
            paragraphs: [
              "Every Mailchimp campaign URL carries two identifiers: mc_cid identifies the campaign (which newsletter blast); mc_eid identifies the recipient (who specifically clicked). Together they tell Mailchimp's tracking: “subscriber X clicked the link in campaign Y”.",
              "mc_cid alone is roughly equivalent to utm_campaign in risk profile — names the campaign, not the person. mc_eid is the one that's identity-adjacent. LinkClean strips both, but mc_eid is the one that matters most for privacy.",
            ],
          },
          {
            heading: "Why Mailchimp puts both on every link",
            paragraphs: [
              "Mailchimp's analytics ties opens, clicks, and conversions back to per-campaign and per-subscriber engagement scores. The two-token model lets Mailchimp compute campaign-level click rates and per-subscriber engagement profiles from the same URL-tag plumbing.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on in the email-marketing catalog. Companion to mc_eid and mc_tc.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/article?mc_cid=abc123def4&mc_eid=78fa90ce21",
        exampleClean: "https://example.com/article",
        faq: [
          {
            q: "Is mc_cid the same as utm_campaign?",
            a: "Functionally similar (names the campaign), but mc_cid is Mailchimp's own ID; utm_campaign is the Google Analytics campaign tag. Mailchimp adds both. LinkClean strips both.",
          },
          {
            q: "Will the email link still work without mc_cid?",
            a: "Yes. The destination page never reads it; only Mailchimp's tracking pixel does.",
          },
          {
            q: "Which is more sensitive — mc_cid or mc_eid?",
            a: "mc_eid is far more sensitive. mc_eid identifies the *recipient* (per-subscriber 1-to-1 token tied to email address). mc_cid identifies the *campaign*. Strip both.",
          },
        ],
      },
    },
  },

  // ── mkt_tok ──────────────────────────────────────────────────
  {
    slug: "mkt-tok",
    param: "mkt_tok",
    kind: "email",
    searchDemand: "high",
    vendor: { name: "Marketo (Adobe)", year: 2006, platform: "B2B email + lead automation", family: "Marketo" },
    related: ["mc-eid", "mc-cid", "hsenc", "kx", "utm-source"],
    content: {
      en: {
        title: "mkt_tok — Marketo's per-recipient email token · LinkClean",
        searchTitle: "What is mkt_tok?",
        description:
          "mkt_tok is Marketo's per-recipient email token — base64-encoded, tied to a specific lead record in Marketo's CRM. Strip it before forwarding.",
        tldr: "mkt_tok is **Marketo's per-recipient email tracking token** — a long base64 string that joins an email click to a specific lead record in Marketo's CRM. Behaves like Mailchimp's mc_eid but in the B2B / enterprise-marketing world. High-stakes when forwarded.",
        sections: [
          {
            heading: "What mkt_tok encodes",
            paragraphs: [
              "Marketo (acquired by Adobe in 2018) is the dominant marketing-automation platform for B2B email. Every link in a Marketo-sent email carries `?mkt_tok=<long-base64-string>`. The token is per-recipient and per-email — Marketo joins it on the destination to identify which lead in their CRM clicked.",
              "If you forward a Marketo email and the recipient clicks the link, Marketo records a click against *your* lead record. Engagement scores get polluted, your sales rep gets a misleading signal, and the recipient's browser hands Marketo a fingerprint join key back to your email address.",
            ],
          },
          {
            heading: "Why this matters in B2B",
            paragraphs: [
              "B2B sales teams use Marketo engagement signals to prioritise outreach. A misattributed forward shows up as the *original* recipient (you) clicking, which can trigger sales follow-up calls or move you into a different nurture sequence. From a privacy angle, mkt_tok is the B2B equivalent of mc_eid.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on in the email-marketing catalog.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/whitepaper?mkt_tok=ODg5LU9PTi0xMjMAAAGRabcdefg1234567890XYZ",
        exampleClean: "https://example.com/whitepaper",
        faq: [
          {
            q: "Is mkt_tok personal data?",
            a: "Yes — it's per-recipient, base64-encoded, and joins back to a specific lead record in Marketo's CRM (which is keyed to the email address). Functionally identity-linked.",
          },
          {
            q: "How is mkt_tok different from utm_source?",
            a: "utm_source names a marketing channel. mkt_tok identifies *the specific person* the email was sent to. Different blast radius entirely.",
          },
          {
            q: "Will the article still load if I strip mkt_tok?",
            a: "Yes. Marketo's tracking pixel reads it; the destination page itself never uses it.",
          },
        ],
      },
    },
  },

  // ── _hsenc ───────────────────────────────────────────────────
  {
    slug: "hsenc",
    param: "_hsenc",
    kind: "email",
    searchDemand: "high",
    vendor: { name: "HubSpot", year: 2011, platform: "Marketing email + CRM", family: "HubSpot" },
    related: ["hsmi", "mkt-tok", "mc-eid", "utm-source", "kx", "mc-tc"],
    content: {
      en: {
        title: "_hsenc — HubSpot's encoded engagement parameter · LinkClean",
        searchTitle: "What is _hsenc?",
        description:
          "_hsenc is HubSpot's encoded engagement parameter — joins email clicks to specific contact records in HubSpot's CRM. Strip it before forwarding.",
        tldr: "_hsenc is **HubSpot's encoded engagement parameter** — joins email clicks back to a specific contact record in HubSpot's CRM. Companion to _hsmi (the email's message ID). Same identity-bound risk as Mailchimp's mc_eid or Marketo's mkt_tok.",
        sections: [
          {
            heading: "What _hsenc and _hsmi do together",
            paragraphs: [
              "HubSpot tags every outbound link in a HubSpot-sent email with two parameters: _hsenc (the encoded engagement token — per-recipient, identity-bound on HubSpot's side) and _hsmi (the message ID — names which specific email send the link came from). Both feed HubSpot's contact-engagement scoring.",
              "_hsenc joins a click back to your contact record in HubSpot's CRM. Forwarding it has the same blast radius as forwarding mkt_tok: another person's click gets attributed to you, and HubSpot picks up a join key tying that pageview back to your email address.",
            ],
          },
          {
            heading: "How LinkClean removes them",
            paragraphs: [
              "Both _hsenc and _hsmi ship default-on in LinkClean's email-marketing catalog.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/article?_hsenc=p2ANqtz-_aB_cD_eF_gH_iJ_kL_mN&_hsmi=89123456",
        exampleClean: "https://example.com/article",
        faq: [
          {
            q: "Is _hsenc the same as _hsmi?",
            a: "No. _hsenc is per-recipient (identity-bound, like mc_eid); _hsmi is per-message (names which email send). Both ride along on HubSpot links.",
          },
          {
            q: "Why is _hsenc on every HubSpot link?",
            a: "HubSpot uses it to score contact engagement — which contacts opened, which clicked, which converted. _hsenc is the join key.",
          },
          {
            q: "Is _hsenc personal data?",
            a: "Yes. It identifies the specific HubSpot contact the email was sent to. Functionally identity-linked.",
          },
        ],
      },
    },
  },

  // ── _hsmi ────────────────────────────────────────────────────
  {
    slug: "hsmi",
    param: "_hsmi",
    kind: "email",
    searchDemand: "medium",
    vendor: { name: "HubSpot", year: 2011, platform: "Marketing email + CRM", family: "HubSpot" },
    related: ["hsenc", "mc-cid", "utm-campaign"],
    content: {
      en: {
        title: "_hsmi — HubSpot's email message ID · LinkClean",
        searchTitle: "What is _hsmi?",
        description:
          "_hsmi is HubSpot's per-email-send message ID — names which specific HubSpot email a link came from. Companion to _hsenc. LinkClean strips both.",
        tldr: "_hsmi is **HubSpot's email message identifier** — names the specific email send the link came from. Less sensitive than _hsenc (campaign-level vs per-recipient), but always paired with it on HubSpot links.",
        sections: [
          {
            heading: "Why _hsmi exists separately",
            paragraphs: [
              "HubSpot's tracking pipeline distinguishes “which campaign” (close to utm_campaign in risk profile) from “which contact” (per-person, identity-bound). _hsmi covers the campaign side; _hsenc covers the per-contact side. The two-token design mirrors Mailchimp's mc_cid / mc_eid split.",
              "_hsmi alone tells HubSpot's analytics how a specific email send is performing. It rarely appears without _hsenc — but the two are conceptually distinct.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on. Same path as _hsenc, mc_cid, mkt_tok.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/article?_hsenc=p2ANqtz-_aBcDeF&_hsmi=89123456",
        exampleClean: "https://example.com/article",
        faq: [
          {
            q: "Is _hsmi sensitive on its own?",
            a: "Less than _hsenc. _hsmi names the campaign-send (like utm_campaign); _hsenc names the recipient. Strip both.",
          },
          {
            q: "Do all HubSpot emails have _hsmi?",
            a: "Effectively yes — HubSpot's outbound-email tracking enables it by default for any tracked send.",
          },
        ],
      },
    },
  },

  // ── _kx (Klaviyo) ────────────────────────────────────────────
  {
    slug: "kx",
    param: "_kx",
    kind: "email",
    searchDemand: "medium",
    vendor: { name: "Klaviyo", year: 2012, platform: "DTC e-commerce email + SMS", family: "Klaviyo" },
    related: ["mc-eid", "mkt-tok", "hsenc"],
    content: {
      en: {
        title: "_kx — Klaviyo's per-recipient engagement token · LinkClean",
        searchTitle: "What is _kx?",
        description:
          "_kx is Klaviyo's per-recipient engagement token — DTC e-commerce email tracking, tied to the specific subscriber. Strip it before forwarding.",
        tldr: "_kx is **Klaviyo's per-recipient engagement token** — Klaviyo is the dominant marketing-automation platform for direct-to-consumer e-commerce. _kx is tied to the specific subscriber. Behaves like mc_eid, mkt_tok, or _hsenc in privacy terms.",
        sections: [
          {
            heading: "What _kx ties together",
            paragraphs: [
              "Klaviyo pairs email and SMS marketing with Shopify, BigCommerce, and other DTC commerce stacks. _kx is the URL-side token Klaviyo uses to bind a click back to the specific subscriber it sent the email to — the join lets Klaviyo's tracking attribute the eventual purchase to a particular subscriber-record.",
              "Same identity-bound shape as the other per-recipient email IDs (mc_eid for Mailchimp, mkt_tok for Marketo, _hsenc for HubSpot). Different vendor, same risk profile.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on in the email-marketing catalog.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/product?_kx=Ab1Cd2Ef3Gh4Ij5Kl6Mn7Op8Qr9St0",
        exampleClean: "https://example.com/product",
        faq: [
          {
            q: "Is _kx identity-bound?",
            a: "Yes — per-recipient. Joins back to Klaviyo's subscriber record, keyed to the subscriber's email or phone.",
          },
          {
            q: "Where does _kx show up most?",
            a: "On outbound links from DTC e-commerce email and SMS sends — Klaviyo dominates that segment. If a Shopify store emails you a promo, _kx is the token tying your click back to your subscriber profile.",
          },
        ],
      },
    },
  },

  // ── mc_tc ────────────────────────────────────────────────────
  {
    slug: "mc-tc",
    param: "mc_tc",
    kind: "email",
    searchDemand: "low",
    vendor: { name: "Mailchimp", year: 2007, family: "Mailchimp" },
    related: ["mc-eid", "mc-cid", "hsenc"],
    content: {
      en: {
        title: "mc_tc — Mailchimp's tap-target click ID · LinkClean",
        searchTitle: "What is mc_tc?",
        description:
          "mc_tc is Mailchimp's tap-target click identifier — names which specific link in an email was clicked. Companion to mc_cid / mc_eid. LinkClean strips it.",
        tldr: "mc_tc is **Mailchimp's tap-target identifier** — names which specific link inside an email was clicked. The third in Mailchimp's standard tracking trio with mc_cid (campaign) and mc_eid (recipient). Strip it with the rest.",
        sections: [
          {
            heading: "What mc_tc adds on top of mc_cid + mc_eid",
            paragraphs: [
              "Mailchimp's tracking can record three things per click: which campaign (mc_cid), which subscriber (mc_eid), and which specific link inside the email was clicked (mc_tc). The third dimension lets Mailchimp's analytics measure CTAs separately — e.g. how many people clicked the hero button vs the footer link in the same email.",
              "mc_tc carries no personal identity on its own (it identifies the link, not the person). But it always rides alongside mc_eid, which does.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on. Stripped with the rest of the Mailchimp trio.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/article?mc_cid=abc123&mc_eid=78fa90&mc_tc=link-hero-1",
        exampleClean: "https://example.com/article",
        faq: [
          {
            q: "Is mc_tc personal data?",
            a: "Not on its own — it names the link, not the recipient. But it ships alongside mc_eid (which is identity-bound).",
          },
          {
            q: "Why does Mailchimp need a per-link ID?",
            a: "Different CTAs inside the same email need separate click-counts for A/B testing and per-CTA conversion attribution.",
          },
        ],
      },
    },
  },

  // ── hl (functional — preserved, not stripped) ────────────────
  {
    slug: "hl",
    param: "hl",
    kind: "regional",
    nature: "functional",
    searchDemand: "high",
    vendor: { name: "Google (Search, YouTube, Maps, Translate, …)", family: "Google (Search & YouTube)" },
    related: ["gl", "lang", "q", "t-youtube", "v-youtube"],
    content: {
      en: {
        title: "hl — what Google's host-language parameter does · LinkClean",
        description:
          "hl is Google's host-language parameter — sets the interface language on Search, YouTube, Maps. Functional, not tracking; LinkClean preserves it.",
        tldr: "`hl` stands for “host language” — it tells Google services which language to render the interface in (`hl=ja` → Japanese UI, `hl=fr` → French). **It's functional, not tracking.** LinkClean preserves it on every host. The page is in this glossary because everyone asks what it is, not because we strip it.",
        sections: [
          {
            heading: "What hl actually does",
            paragraphs: [
              "hl is short for “host language” (sometimes glossed “human language”). When you visit a Google service — Search, YouTube, Maps, Translate, Image Search — the `hl=` parameter on the URL tells Google which language to render the interface in. `hl=ja` gives you Japanese UI; `hl=fr` gives you French; `hl=en` gives you English; `hl=zh-CN` Simplified Chinese, etc. The values are IETF BCP 47 language tags (close cousins of HTML's `lang` attribute).",
              "It's the URL-equivalent of clicking the language picker in the footer of a Google page. Google sets it when you change languages, and includes it in outbound share links so the recipient sees the same UI language you did. If you don't include hl, Google falls back to your browser's Accept-Language header (or guesses from your IP region).",
            ],
          },
          {
            heading: "Where you'll see it",
            paragraphs: [
              "Most commonly: Google Search share links (https://www.google.com/search?q=…&hl=…), YouTube video URLs (https://www.youtube.com/watch?v=…&hl=…), and Google Maps shares. Google's apps add it on Share; manual URL bar typing usually doesn't.",
              "Some non-Google services also use `hl` as a language indicator since the convention is well-known. Wikipedia uses `uselang`; Wikimedia projects use `lang` or `setlang`; YouTube ALSO accepts `gl` (geolocation, see below).",
            ],
          },
          {
            heading: "Why it's NOT tracking",
            paragraphs: [
              "hl doesn't identify you, doesn't follow your click anywhere, and isn't tied to a cookie. It's a preference (“render this page in Japanese”) that Google passes along via the URL because some users share links across language preferences. Forwarding it doesn't leak anything about who you are.",
              "Compare to utm_source: utm_source is marketing attribution metadata that exists only to credit a campaign — stripping it changes nothing about what the page shows the user. hl is the opposite — it shapes what the page shows. Strip it and the recipient gets whatever language Google decides for their browser, which may not be what you intended when you shared the link.",
            ],
          },
          {
            heading: "How LinkClean handles it (and the rest of the language/region family)",
            paragraphs: [
              "LinkClean preserves hl on every host. It's in the catalog's explicit exemption set — even on hosts where similar single- or two-letter parameter names (`t` on x.com, `s` on x.com) ARE trackers, `hl` is recognized as functional and never stripped.",
              "Same treatment for the small family of language/region parameters that frequently come up next: `gl` (Google country/geolocation — picks results relevant to that country); `lang` and `language` (generic language indicators used by many sites); `setlang` or `uselang` (Wikipedia / Wikimedia projects). LinkClean documents them in the glossary because users ask, but never removes them.",
            ],
          },
        ],
        // For a functional spoke, exampleDirty is rendered as the “Example URL”
        // and exampleClean is unused (the renderer skips it). Set both equal
        // to be safe.
        exampleDirty: "https://www.google.com/search?q=hello&hl=ja",
        exampleClean: "https://www.google.com/search?q=hello&hl=ja",
        faq: [
          {
            q: "What does hl stand for?",
            a: "“Host language” — sometimes glossed “human language”. It's a Google convention dating back to the early Google Search interface: the language the host page should render in.",
          },
          {
            q: "Is hl personal data?",
            a: "No. It's a preference (which language to render) — the same value would be sent by anyone choosing that language. It doesn't identify you, doesn't connect to a cookie, doesn't follow your click.",
          },
          {
            q: "Does LinkClean strip hl?",
            a: "No. hl is in the explicit exemption list — even on hosts where similar single- or two-letter parameter names are trackers, hl is preserved.",
          },
          {
            q: "What's the difference between hl and gl?",
            a: "hl sets the interface language (“render the page in Japanese”); gl sets the geographic region (“return results relevant to Japan”). gl can change which results come back; hl just changes the UI text around them. Both are functional, not tracking — LinkClean preserves both.",
          },
          {
            q: "Why do Google share links have hl on them?",
            a: "Google's apps add it on Share so the recipient sees the same UI language. It's a convenience for cross-language sharing — if you're showing a Japanese friend a YouTube video and the URL preserves hl=ja, they get the same Japanese UI you had.",
          },
          {
            q: "Can I add hl manually to a Google URL?",
            a: "Yes. Append `?hl=<lang>` (or `&hl=<lang>` if other params already exist). Common values: hl=en, hl=ja, hl=fr, hl=de, hl=es, hl=zh-CN, hl=zh-TW. The full list is the IETF BCP 47 language-tag registry, but Google only renders UI for languages it supports.",
          },
        ],
      },
    },
  },

  // ── utm_term ─────────────────────────────────────────────────
  {
    slug: "utm-term",
    param: "utm_term",
    kind: "utm",
    searchDemand: "medium",
    vendor: { name: "Google Analytics (originally Urchin)", year: 1996, family: "Google" },
    related: ["utm-source", "utm-medium", "utm-campaign", "utm-content", "gclid"],
    content: {
      en: {
        title: "utm_term — the paid-keyword UTM tag · LinkClean",
        searchTitle: "What is utm_term?",
        description:
          "utm_term names the paid-search keyword behind a click — appears almost exclusively on paid-search ads. Safe to strip; the page never reads it.",
        tldr: "utm_term names the **paid-search keyword** that triggered an ad click — “running shoes”, “privacy app ios”, etc. Only appears on paid-search URLs (Google Ads, Bing Ads). LinkClean strips it everywhere; the destination page never reads it.",
        sections: [
          {
            heading: "Paid-search attribution explained",
            paragraphs: [
              "utm_term is the fourth of Google's five UTM campaign tags. It's almost exclusively used on paid-search ads — the value is the keyword the searcher typed that matched the ad's targeting. `utm_term=privacy+ios+app` says the click came from someone searching that exact phrase.",
              "On organic clicks (a click from an unpaid Google search result), utm_term is virtually never present — Google has stripped the referring keyword from organic referrer data since 2011. The tag is therefore a strong signal that the click was paid.",
            ],
          },
          {
            heading: "When keyword data is more revealing than utm_source",
            paragraphs: [
              "Forwarding a link with utm_term still attached tells anyone downstream which keyword the advertiser was bidding on. That can be revealing — the keyword is often a competitor's name, a specific product configuration the publisher is targeting, or an internal A/B-test cohort label.",
              "Like the rest of the UTM family it's not personally identifying — it identifies the *campaign*, not the visitor. But it does telegraph the advertiser's paid-search playbook to whoever receives the forwarded URL.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "utm_term ships default-on with the entire utm_* family. Stripped on every host — there's no legitimate non-Google-Analytics use of this name on the web.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/sale?utm_source=google&utm_medium=cpc&utm_campaign=spring&utm_term=privacy+ios+app&gclid=Cj0KCQ",
        exampleClean: "https://example.com/sale",
        faq: [
          {
            q: "Why is utm_term almost always paired with gclid?",
            a: "Because both are added by Google Ads on outbound paid-search clicks. utm_term names the keyword for Google Analytics; gclid names the click for Google Ads conversion tracking. Same campaign, two different systems each writing their own tag.",
          },
          {
            q: "Does utm_term ever appear on organic Google traffic?",
            a: "Almost never. Google has stripped keyword referrer data from organic searches since 2011 (the famous “not provided” transition). If utm_term is on a URL, the click was almost certainly paid.",
          },
          {
            q: "Can utm_term contain my actual search query?",
            a: "Yes — that's exactly what it encodes. The keyword you typed (or close to it) shows up verbatim. That makes utm_term one of the more revealing UTM tags when shared onward.",
          },
          {
            q: "What's the difference between utm_term and utm_content?",
            a: "utm_term names the keyword; utm_content names the creative variant (which version of the ad was clicked). One is about the search query, the other is about the ad copy. LinkClean strips both by default.",
          },
        ],
      },
    },
  },

  // ── utm_content ──────────────────────────────────────────────
  {
    slug: "utm-content",
    param: "utm_content",
    kind: "utm",
    searchDemand: "medium",
    vendor: { name: "Google Analytics (originally Urchin)", year: 1996, family: "Google" },
    related: ["utm-source", "utm-medium", "utm-campaign", "utm-term"],
    content: {
      en: {
        title: "utm_content — the creative-variant UTM tag · LinkClean",
        searchTitle: "What is utm_content?",
        description:
          "utm_content is a Google Analytics campaign tag that names which creative variant or CTA was clicked. Used for A/B-testing ads and email layouts. Safe to strip.",
        tldr: "utm_content names the **creative variant or CTA** that was clicked — “hero-button”, “v2-banner”, “footer-link”. Publishers use it to A/B-test which version of an ad or email works. The destination page never reads it.",
        sections: [
          {
            heading: "Creative-variant tracking and A/B testing",
            paragraphs: [
              "utm_content is the fifth UTM tag, and the one publishers reach for when they want to split-test elements *inside* a single ad or email. utm_source/medium/campaign locate the click in the campaign hierarchy; utm_content tells the publisher which specific variant or button was clicked.",
              "Common values look like `hero-cta`, `v2-button`, `image-top`, `text-link-1`, or arbitrary cohort IDs from an A/B-test platform. The value is meaningful only to the publisher's analytics dashboard.",
            ],
          },
          {
            heading: "Why it ends up on shared links",
            paragraphs: [
              "When a publisher embeds utm_content into the destination URL of a button or image inside an email, the value rides along on every share of that link. Forward the email → forward the URL → forward the variant tag. The recipient's analytics tools see the tag as if they'd received the email and clicked the same variant.",
              "Like the other UTM tags it doesn't identify a person, but it does reveal an A/B-test cohort label — which can occasionally leak product-experiment details a publisher would prefer to keep private.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on, every host. Same pipeline as the rest of utm_*. No legitimate non-analytics use of this exact name.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/page?utm_source=newsletter&utm_medium=email&utm_campaign=spring&utm_content=v2-hero-cta",
        exampleClean: "https://example.com/page",
        faq: [
          {
            q: "Can utm_content reveal an A/B test?",
            a: "Sometimes. Values like `cohort-a` or `variant-control` telegraph the publisher's experiment design when forwarded. Most A/B-test platforms use opaque IDs, but plenty of marketing teams use descriptive names.",
          },
          {
            q: "Is utm_content the same as utm_term?",
            a: "No. utm_term names the paid-search keyword (only on paid-search ads). utm_content names the creative variant (any campaign with multiple versions of the same creative). LinkClean strips both.",
          },
          {
            q: "Does removing utm_content break anything?",
            a: "No. The destination page never reads it — only the publisher's analytics tool does, after the page has loaded.",
          },
        ],
      },
    },
  },

  // ── utm_id ───────────────────────────────────────────────────
  {
    slug: "utm-id",
    param: "utm_id",
    kind: "utm",
    searchDemand: "medium",
    vendor: { name: "Google Analytics 4 (GA4)", year: 2020, family: "Google" },
    related: ["utm-source", "utm-medium", "utm-campaign", "gad-source"],
    content: {
      en: {
        title: "utm_id — GA4's campaign-ID UTM tag · LinkClean",
        searchTitle: "What is utm_id?",
        description:
          "utm_id is GA4's numeric campaign identifier — joins a click to a specific campaign row in Google Analytics 4. Safe to strip.",
        tldr: "utm_id is **GA4's campaign-ID UTM tag** — a numeric identifier added by Google Analytics 4 to join clicks to a specific campaign row. Newer than utm_source / utm_medium / utm_campaign; same safe-to-strip property.",
        sections: [
          {
            heading: "Universal Analytics → GA4 transition",
            paragraphs: [
              "Google Analytics 4 (rolled out 2020–2023 as a Universal Analytics replacement) added utm_id as a way to bind a click to a campaign entity inside GA4 without depending on the free-form utm_campaign string. utm_campaign=“spring-launch” is human-readable but easily duplicated; utm_id=`8421` is a stable numeric ID that GA4 generates and tracks against its internal campaign table.",
              "Both are added together: `utm_campaign=spring-launch&utm_id=8421` is the common pattern in GA4-driven campaigns. Older Universal Analytics campaigns rarely had utm_id; you'll see it most on links generated by GA4's Campaign URL Builder or by marketing tools updated for the GA4 era.",
            ],
          },
          {
            heading: "Why it's safe to strip",
            paragraphs: [
              "Like every other UTM tag, utm_id is only read by analytics scripts after the page loads — the destination server doesn't use it. Strip it and the same article, sale page, or video loads.",
              "Forwarding utm_id mainly inflates the publisher's GA4 campaign counts. Not personally identifying, but no reason to broadcast it.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/launch?utm_source=newsletter&utm_medium=email&utm_campaign=spring&utm_id=8421",
        exampleClean: "https://example.com/launch",
        faq: [
          {
            q: "Why does GA4 add utm_id when utm_campaign already exists?",
            a: "Stable IDs are easier to deduplicate. utm_campaign is a free-form string the publisher types; utm_id is a numeric reference to a campaign object inside GA4. Duplicates and typos in utm_campaign get folded into the right bucket via utm_id.",
          },
          {
            q: "Does utm_id ever appear on its own (without utm_campaign)?",
            a: "Occasionally — when a publisher copies a GA4 Campaign Builder URL but trims the human-readable tags. Stripping utm_id alone doesn't break anything; the destination still routes on the path.",
          },
          {
            q: "Is utm_id personal data?",
            a: "No. It's a campaign-row identifier on the publisher's GA4 side — names the campaign, not the visitor.",
          },
        ],
      },
    },
  },

  // ── gl (functional — preserved) ──────────────────────────────
  {
    slug: "gl",
    param: "gl",
    kind: "regional",
    nature: "functional",
    searchDemand: "high",
    vendor: { name: "Google (Search, Maps, Shopping)", family: "Google (Search & YouTube)" },
    related: ["hl", "lang", "q"],
    content: {
      en: {
        title: "gl — Google's country / geolocation parameter · LinkClean",
        searchTitle: "What is gl?",
        description:
          "gl is Google's country / region parameter — tells Google services which country's results to return. Functional, not tracking; LinkClean preserves it.",
        tldr: "`gl` stands for “geolocation” — it tells Google services (Search, Maps, Shopping) which country to scope results to. `gl=us` returns US-relevant results; `gl=jp` returns Japan-relevant results. **Functional, not tracking.** LinkClean preserves it.",
        sections: [
          {
            heading: "What gl actually does",
            paragraphs: [
              "Where `hl` controls *interface language* (which language Google's UI is rendered in), `gl` controls *result region* (which country the results are localised to). They can be set independently — `hl=ja&gl=us` gives you Japanese UI but US-localised results.",
              "gl values are ISO 3166-1 alpha-2 country codes: `us`, `gb`, `jp`, `de`, `fr`, etc. They affect Search results' ranking (Google biases toward sources from that country), Maps' default region, and Shopping's currency / merchant pool.",
            ],
          },
          {
            heading: "Why it's not tracking",
            paragraphs: [
              "gl is a preference state, like hl. It doesn't carry identity, doesn't follow your click anywhere, and isn't tied to a cookie. Forwarding `gl=jp` tells the recipient's Google session to localise to Japan — that may or may not be what you intended, but it doesn't leak who you are.",
            ],
          },
          {
            heading: "How LinkClean handles it",
            paragraphs: [
              "Preserved on every host. Paired with hl in the language/region exemption set — both are documented in the glossary but never stripped.",
            ],
          },
        ],
        exampleDirty: "https://www.google.com/search?q=ramen&gl=jp&hl=ja",
        exampleClean: "https://www.google.com/search?q=ramen&gl=jp&hl=ja",
        faq: [
          {
            q: "What's the difference between gl and hl?",
            a: "gl is the country (which region's results to return); hl is the language (which language to render the UI in). They can be set independently.",
          },
          {
            q: "What values does gl take?",
            a: "ISO 3166-1 alpha-2 country codes: `us`, `gb`, `jp`, `de`, `fr`, `br`, etc.",
          },
          {
            q: "Does LinkClean strip gl?",
            a: "No. gl is in the same explicit exemption set as hl, lang, setlang, and `v` (YouTube video ID).",
          },
          {
            q: "Will the results change if I keep gl?",
            a: "Yes — Google biases ranking and merchant pools toward the named country. That's the point of the parameter.",
          },
        ],
      },
    },
  },

  // ── t-youtube (functional — preserved, YouTube timestamp) ────
  {
    slug: "t-youtube",
    param: "t",
    kind: "regional",
    nature: "functional",
    searchDemand: "high",
    vendor: { name: "YouTube", platform: "video timestamp (not a tracker)", family: "Google (Search & YouTube)" },
    related: ["hl", "v-youtube", "q"],
    content: {
      en: {
        title: "t= on YouTube — the video start-timestamp · LinkClean",
        searchTitle: "What does t= mean on a YouTube URL?",
        description:
          "t= on a YouTube URL is the video start-timestamp — “start playing at N seconds”. Functional, not tracking. LinkClean preserves it on youtube.com / youtu.be.",
        tldr: "`t=` on a YouTube URL means **start playing at that many seconds in** — `?t=42` jumps to the 42-second mark, `?t=1m20s` jumps to one minute twenty. **Functional, not tracking.** LinkClean preserves it host-scoped to youtube.com / youtu.be.",
        sections: [
          {
            heading: "What t= does on YouTube",
            paragraphs: [
              "YouTube's player reads `t=` from the URL and seeks the video to that point on load. Values can be raw seconds (`t=42`), human-readable durations (`t=1m20s`, `t=01h30m`), or even hour-minute-second combinations. The player normalises all three into the same seek position.",
              "It's set by YouTube's “Share at current time” checkbox in the share dialog, and you can add it manually too. The conventional shareable form is `https://youtu.be/<id>?t=<seconds>`.",
            ],
          },
          {
            heading: "Why this matters for URL-cleaning tools",
            paragraphs: [
              "Naïvely stripping all single-letter query parameters would break YouTube share links — `t=` would vanish along with x.com's `t=` (which IS a tracker). LinkClean's catalog host-scopes the t/s rules: on x.com / twitter.com, t= and s= are stripped as tracking tokens; on youtube.com / youtu.be, t= is preserved as functional and `si=` is stripped instead.",
              "Same logic applies to Vimeo (`#t=2m`), Twitch (`?t=01h00m`), and other video sites that use t= for the same purpose.",
            ],
          },
          {
            heading: "How LinkClean handles it",
            paragraphs: [
              "Preserved on youtube.com, youtu.be, and other video hosts. The cleaned URL keeps the timestamp; the share-identifier `si=` is stripped.",
            ],
          },
        ],
        exampleDirty:
          "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s&si=AbCdEf12345",
        exampleClean: "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s",
        faq: [
          {
            q: "Why is t= a tracker on X but not on YouTube?",
            a: "Same parameter name, completely different meaning. On x.com, t= is a per-session share token X uses for share-source attribution. On youtube.com, t= is the video timestamp. LinkClean's catalog host-scopes both: stripped on x.com, preserved on youtube.com.",
          },
          {
            q: "What formats does YouTube's t= accept?",
            a: "Raw seconds (`t=42`), human-readable durations (`t=1m20s`, `t=01h30m`), and combinations. YouTube's player normalises all three.",
          },
          {
            q: "Does YouTube's share dialog add t= automatically?",
            a: "Only when you tick “Start at <time>”. Otherwise the share link starts at 0:00.",
          },
        ],
      },
    },
  },

  // ── v-youtube (functional — preserved, YouTube video ID) ─────
  {
    slug: "v-youtube",
    param: "v",
    kind: "regional",
    nature: "functional",
    searchDemand: "medium",
    vendor: { name: "YouTube", platform: "video identifier (not a tracker)", family: "Google (Search & YouTube)" },
    related: ["t-youtube", "hl", "q"],
    content: {
      en: {
        title: "v= on YouTube — the video identifier · LinkClean",
        searchTitle: "What does v= mean on a YouTube URL?",
        description:
          "v= on a YouTube URL is the video identifier — the unique 11-character ID for that video. Functional, not tracking. LinkClean preserves it.",
        tldr: "`v=` on a YouTube URL is the **video identifier** — the unique 11-character base64 ID that names the specific video. Strip it and the URL doesn't resolve to any video at all. **Functional, not tracking.** Always preserved.",
        sections: [
          {
            heading: "What v= is",
            paragraphs: [
              "Every YouTube video has an 11-character identifier built from base64-url characters (e.g. `dQw4w9WgXcQ`). On the `www.youtube.com/watch` URL, that ID lives in the `v=` query parameter; on the shortener form `youtu.be/<id>`, it's the path itself.",
              "Strip `v=` from a youtube.com/watch URL and you land on YouTube's home page instead of the video. It's the only mandatory part of a YouTube video URL.",
            ],
          },
          {
            heading: "Why it's documented here",
            paragraphs: [
              "Because users sometimes ask. The naming confuses people — `v=` looks like a tracking parameter at first glance, but it's the most functional parameter on YouTube. LinkClean never strips it.",
            ],
          },
        ],
        exampleDirty: "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s",
        exampleClean: "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s",
        faq: [
          {
            q: "Why are YouTube video IDs 11 characters long?",
            a: "It's base64url over a fixed-width integer, designed to give YouTube a virtually inexhaustible namespace (~73 quintillion possible IDs) while staying short enough to type and share.",
          },
          {
            q: "Is youtu.be/<id> the same as youtube.com/watch?v=<id>?",
            a: "Yes — youtu.be is YouTube's URL shortener; the path after the slash IS the video ID, equivalent to `v=` on the longer form.",
          },
          {
            q: "Does LinkClean ever touch v=?",
            a: "Never. v= is the video ID — strip it and the URL doesn't resolve to a video.",
          },
        ],
      },
    },
  },

  // ── q (functional — preserved, search query) ─────────────────
  {
    slug: "q",
    param: "q",
    kind: "regional",
    nature: "functional",
    searchDemand: "medium",
    vendor: { name: "Standard search-query convention", platform: "used by Google, Wikipedia, GitHub, and many more", family: "Multi-vendor" },
    related: ["hl", "gl", "lang", "t-youtube", "v-youtube"],
    content: {
      en: {
        title: "q= — the standard search-query URL parameter · LinkClean",
        searchTitle: "What is q= in a URL?",
        description:
          "q= is the standard URL parameter for a search query — used by Google, Wikipedia, GitHub, and many sites. Functional, not tracking. LinkClean preserves it.",
        tldr: "`q=` is the **search-query parameter** — a near-universal convention for naming the search term in a URL. Used by Google (`google.com/search?q=…`), Wikipedia, GitHub, Bing, DuckDuckGo, Stack Overflow, and many more. **Functional, not tracking.** LinkClean preserves it.",
        sections: [
          {
            heading: "What q= does",
            paragraphs: [
              "On any site that has a search box, the query you typed often ends up as `?q=<your-search-text>` in the URL. The server reads it, looks up matching results, and renders the page. Strip q= and you get the search page with no results — the search box is empty.",
              "The convention is old — it dates to early HTML forms where `name=\"q\"` was the natural shorthand for the query input. It's a convention, not a standard, but it's so widespread that the major search engines all use it.",
            ],
          },
          {
            heading: "Why it's preserved",
            paragraphs: [
              "q= shapes what the user sees — strip it from a `google.com/search?q=ramen` URL and the user lands on a blank search page instead of seeing ramen results. The opposite of what tracking parameters do (which never affect what loads).",
              "LinkClean's curation rule keeps generic words like `q`, `t`, `s`, `ref`, `source` default-off precisely because they can be functional. Host-scoped tracker rules apply only where the parameter is a known tracker on that specific site.",
            ],
          },
          {
            heading: "How LinkClean handles it",
            paragraphs: [
              "Preserved on every host. q= is in LinkClean's reference functional set alongside hl, gl, lang, t (on YouTube), v (on YouTube).",
            ],
          },
        ],
        exampleDirty: "https://www.google.com/search?q=ramen+tokyo&hl=ja",
        exampleClean: "https://www.google.com/search?q=ramen+tokyo&hl=ja",
        faq: [
          {
            q: "Is q= always functional?",
            a: "Almost always. The exception would be a site that uses `q` for non-query purposes — extremely rare. LinkClean defaults to preserving it.",
          },
          {
            q: "What sites use q=?",
            a: "Google, Bing, DuckDuckGo, Wikipedia, GitHub, Stack Overflow, Hacker News, npm, PyPI, and many more. It's a de-facto convention from the early HTML era.",
          },
          {
            q: "Does q= leak my search history?",
            a: "Only to the site you searched on — which is what searching does. Forwarding a `?q=ramen` URL is sharing your search results page with someone, intentionally.",
          },
        ],
      },
    },
  },

  // ── lang (functional — preserved, generic language) ──────────
  {
    slug: "lang",
    param: "lang",
    kind: "regional",
    nature: "functional",
    searchDemand: "medium",
    vendor: { name: "Generic language convention", platform: "used by many sites for language selection", family: "Multi-vendor" },
    related: ["hl", "gl", "q"],
    content: {
      en: {
        title: "lang= — the generic language URL parameter · LinkClean",
        searchTitle: "What is lang= in a URL?",
        description:
          "lang= is the generic language URL parameter — used by many sites to select interface language. Functional, not tracking. LinkClean preserves it.",
        tldr: "`lang=` is the **generic language parameter** — a convention many non-Google sites adopt to select the interface or content language. Wikipedia uses `setlang`/`uselang`; many CMSes use `lang` directly. **Functional, not tracking.** LinkClean preserves it.",
        sections: [
          {
            heading: "What lang= does",
            paragraphs: [
              "On sites that support multiple languages, `lang=en`, `lang=fr`, `lang=ja` etc. usually selects which translation of the page (or which language of the UI chrome) gets rendered. Variants: `language=`, `locale=`, `setlang`, `uselang` — all serve the same purpose at different vendors.",
              "Where Google uses `hl` (host language) and `gl` (geolocation), the rest of the web mostly uses some variant of `lang`. It's a recognised convention in many CMSes (WordPress with multilingual plugins, Drupal, MediaWiki).",
            ],
          },
          {
            heading: "Why it's preserved",
            paragraphs: [
              "lang= shapes content (which translation loads). Stripping it can drop the user back to the site's default language — usually English — which can be the opposite of what the sender intended when sharing the link.",
            ],
          },
          {
            heading: "How LinkClean handles it",
            paragraphs: [
              "Preserved on every host. Companion to hl, gl, setlang, uselang in the language/region exemption set.",
            ],
          },
        ],
        exampleDirty: "https://example.com/article?lang=ja",
        exampleClean: "https://example.com/article?lang=ja",
        faq: [
          {
            q: "Is lang= a standard?",
            a: "More of a convention than a standard. Different vendors use `lang`, `language`, `locale`, `setlang`, `uselang` — all to mean roughly the same thing.",
          },
          {
            q: "Does Google use lang= too?",
            a: "Google uses `hl` (host language) instead — same idea, different name. lang= shows up more on non-Google sites.",
          },
          {
            q: "Is lang= ever a tracker?",
            a: "Effectively never. LinkClean preserves it on every host.",
          },
        ],
      },
    },
  },

  // ── mc_eid ───────────────────────────────────────────────────
  {
    slug: "mc-eid",
    param: "mc_eid",
    kind: "email",
    searchDemand: "high",
    vendor: { name: "Mailchimp", year: 2007, family: "Mailchimp" },
    related: ["mc-cid", "mc-tc", "mkt-tok", "hsenc", "utm-source", "kx"],
    content: {
      en: {
        title: "mc_eid — Mailchimp's per-recipient email ID · LinkClean",
        description:
          "mc_eid is Mailchimp's per-subscriber email identifier — tied to your email address. Forwarding it leaks an identity-bound token. LinkClean strips it.",
        tldr: "mc_eid is Mailchimp's per-**recipient** identifier — a token tied to the specific email address the newsletter was sent to. Forwarding it tells Mailchimp that someone else opened your email. Of all the trackers LinkClean strips, this is the one that most directly leaks identity.",
        sections: [
          {
            heading: "What mc_eid actually identifies",
            paragraphs: [
              "Mailchimp generates a unique mc_eid per subscriber per list — it's their internal “email ID”. When that subscriber clicks a link in a Mailchimp newsletter, mc_eid rides along on every outbound URL. Mailchimp's tracking pixel then ties the click to *the exact subscriber* it was sent to.",
              "That's different from utm_source / fbclid / gclid. utm_source identifies the campaign; mc_eid identifies *the person*. It's the subscriber's surrogate identifier — a 1-to-1 token bound to an email address.",
            ],
          },
          {
            heading: "What forwarding mc_eid actually leaks",
            paragraphs: [
              "If you forward a Mailchimp newsletter link to a friend with mc_eid still attached and they click, Mailchimp records a click tied to *your* subscriber ID — from your friend's browser. Now Mailchimp has noise in your engagement profile (someone-other-than-you clicked “your” email), and on their side, they may be cookied or pixel-tagged in a way that joins back to your email-address record on Mailchimp's books.",
              "Same shape applies to mc_cid (Mailchimp's campaign ID, which is less sensitive — names the campaign, not the recipient) and the older `_mc_*` family.",
            ],
          },
          {
            heading: "Why this is more aggressive than stripping utm tags",
            paragraphs: [
              "utm_source broadcasts marketing context. mc_eid is a per-person token. The harm model is different and stronger: forwarding mc_eid leaks a token that joins back to your email address, which is one short step away from your real-world identity.",
              "LinkClean strips mc_eid as default-on, same as utm_source and fbclid — but if you're forwarding newsletter links a lot, this is the parameter that's most worth knowing about.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "mc_eid + mc_cid + mc_tc (Mailchimp's tap-target ID) all ship default-on in LinkClean's email-marketing catalog. Same pipeline as the ads catalog — stripped on every host. The Drip equivalent (__s), Klaviyo's _kx, and HubSpot's _hsenc / _hsmi are also in the email-marketing catalog by default or on opt-in.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/article?utm_source=mailchimp&utm_medium=email&mc_cid=abc123def4&mc_eid=78fa90ce21",
        exampleClean: "https://example.com/article",
        faq: [
          {
            q: "Is mc_eid personal data?",
            a: "It's tied to your email address on Mailchimp's side — a 1-to-1 token. From their perspective, yes; it identifies the subscriber the newsletter was sent to.",
          },
          {
            q: "Will the article still load?",
            a: "Yes. The destination site doesn't read mc_eid. Only Mailchimp's tracking pixel does, and that's their analytics — not part of the page.",
          },
          {
            q: "Why is mc_eid worth stripping more than utm_source?",
            a: "utm_source describes the campaign. mc_eid identifies the specific subscriber the email was sent to. The blast radius if you forward it is bigger.",
          },
          {
            q: "Does LinkClean strip other newsletter trackers too?",
            a: "Yes — mc_cid, mc_tc (Mailchimp), __s (Drip), _kx (Klaviyo), and HubSpot's _hsenc / _hsmi are in the default or opt-in catalogs depending on how vendor-specific the name is.",
          },
        ],
      },
    },
  },

  // ── igshid ───────────────────────────────────────────────────
  {
    slug: "igshid",
    param: "igshid",
    kind: "social",
    searchDemand: "high",
    vendor: {
      name: "Instagram",
      year: 2019,
      platform: "share-link attribution",
      family: "Meta",
    },
    related: ["mibextid", "si", "s-twitter", "fbclid"],
    content: {
      en: {
        title: "igshid — Instagram's share-link tracking ID · LinkClean",
        searchTitle: "What is igshid?",
        description:
          "igshid is Instagram's share-link identifier — Meta appends it to every link copied from the Instagram app. Strip it before forwarding.",
        tldr: "igshid is the share-link identifier Instagram appends when you copy a link from the app — it ties the click back to your Instagram session for Meta's first-party analytics. Stripping it preserves the destination perfectly while breaking the attribution chain back to your account.",
        sections: [
          {
            heading: "What igshid does",
            paragraphs: [
              "Instagram's Share → Copy Link adds ?igshid=<token> to every outbound URL — Reels, Stories, posts, profiles, and even the external links you tap through from someone's bio. The token encodes the sharing session; Meta joins it back to your Instagram account server-side when the recipient clicks.",
              "Same architecture as Facebook's mibextid, X's t / s, YouTube's si: a per-share token used for Meta's first-party analytics, never for routing the page.",
            ],
          },
          {
            heading: "Where you'll see it",
            paragraphs: [
              "Any link copied from Instagram, on any device. Often paired with utm_source=ig_web_copy_link (or a similar source UTM) when Meta's web client did the copying. The pair travels together — strip both.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "igshid ships default-on in LinkClean's social catalog. No legitimate non-tracking use anywhere on the web — the destination URL never reads it. The companion utm_source / utm_medium tail is stripped by the standard UTM rules.",
            ],
          },
          {
            heading: "Why it's worth knowing about",
            paragraphs: [
              "Instagram links are some of the most-forwarded URLs on the modern web. Every share you don't clean carries an attribution token onward to whoever you sent it to. They click → Meta records the click against your sharing session, then against theirs when they re-share.",
            ],
          },
        ],
        exampleDirty:
          "https://example.com/article?igshid=YmMyMTA2M2Y%3D&utm_source=ig_web_copy_link",
        exampleClean: "https://example.com/article",
        faq: [
          {
            q: "Does removing igshid break the link?",
            a: "No. The destination only routes on the path; igshid lives in the query string and is read by Meta's analytics, not by the page you're visiting.",
          },
          {
            q: "Is igshid personal data?",
            a: "On Meta's side, yes — it ties back to your Instagram session and from there to your account. The URL itself doesn't name you.",
          },
          {
            q: "Why does Instagram add it to every shared link?",
            a: "Attribution. Meta wants to know which shares produce clicks and downstream conversions on partner sites — share is the channel they can't measure server-side otherwise.",
          },
          {
            q: "What if I want to share an Instagram post itself?",
            a: "The clean form `instagram.com/p/<shortcode>/` or `instagram.com/reel/<shortcode>/` survives stripping. Same post, same content, no share token attached.",
          },
        ],
      },
    },
  },

  // ── mibextid ─────────────────────────────────────────────────
  {
    slug: "mibextid",
    param: "mibextid",
    kind: "social",
    searchDemand: "high",
    vendor: {
      name: "Meta (Facebook)",
      year: 2022,
      platform: "mobile-app share attribution",
      family: "Meta",
    },
    related: ["igshid", "si", "fbclid", "s-twitter"],
    content: {
      en: {
        title: "mibextid — Facebook's mobile-share tracker · LinkClean",
        searchTitle: "What is mibextid?",
        description:
          "mibextid is Meta's mobile-app share identifier — added when you tap Share on Facebook's mobile apps or Messenger. Strip it before forwarding.",
        tldr: "mibextid is the share-identifier Facebook's mobile apps add to every link you share — separate from fbclid (which is for paid-ad clicks). It identifies the *sharing* session, not an ad click. Strip it before forwarding.",
        sections: [
          {
            heading: "What mibextid does",
            paragraphs: [
              "When you Share a link from the Facebook app (or Messenger, sometimes WhatsApp depending on the version), Meta appends ?mibextid=<token>. The token encodes which app, which session, and is joined server-side to your Meta account.",
            ],
          },
          {
            heading: "mibextid vs fbclid",
            paragraphs: [
              "Two tokens, two pipelines, both safe to strip: fbclid lands on links *clicked from Facebook ads* (paid-attribution; the destination's Meta Pixel reads it). mibextid lands on links *shared via Meta apps* (share-attribution; Meta reports the click back from the share-graph).",
              "The same destination URL can carry both — fbclid because someone clicked an ad, mibextid because they re-shared it. Strip both as a pair.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on in LinkClean's social catalog. Same vendor-specific-token-no-functional-use logic as fbclid / ttclid / yclid.",
            ],
          },
          {
            heading: "Why it shows up everywhere",
            paragraphs: [
              "Anyone sharing news, recipes, products, or videos via Facebook or Messenger adds mibextid to the link without knowing. Most people forwarding “look at this” links via Messenger or SMS are unknowingly amplifying Meta's measurement graph.",
            ],
          },
        ],
        exampleDirty: "https://example.com/article?mibextid=Zbwa3y",
        exampleClean: "https://example.com/article",
        faq: [
          {
            q: "What does mibextid stand for?",
            a: "Best guess from Meta's app code: a “Mobile Internal Browser EXTension ID” or similar internal abbreviation; Meta has never published an official expansion. The behavior is the documented part.",
          },
          {
            q: "Does removing it break anything?",
            a: "No. The destination doesn't read it — only Meta's analytics infrastructure does, after the page has loaded.",
          },
          {
            q: "Why is mibextid different from fbclid?",
            a: "They serve different purposes. Per-click identifiers (fbclid, gclid) credit ad spend. Per-share identifiers (mibextid, igshid) measure organic sharing. Meta cares about both — strip both.",
          },
          {
            q: "Does any destination site ever use mibextid?",
            a: "No (verified across every site in our catalog). It exists for Meta's measurement only.",
          },
        ],
      },
    },
  },

  // ── si (YouTube + Spotify) ───────────────────────────────────
  {
    slug: "si",
    param: "si",
    kind: "referral",
    searchDemand: "high",
    vendor: {
      name: "YouTube + Spotify",
      year: 2020,
      platform: "share-link attribution (host-scoped)",
      family: "Google (Search & YouTube)",
    },
    related: ["igshid", "mibextid", "s-twitter"],
    content: {
      en: {
        title: "si — YouTube and Spotify's share-identifier · LinkClean",
        searchTitle: "What is si in a YouTube or Spotify link?",
        description:
          "si is the share-identifier YouTube and Spotify append to copied links. Strip it before forwarding — LinkClean does this host-scoped so si elsewhere isn't affected.",
        tldr: "si is a share-identifier token both YouTube and Spotify add to links copied from their apps. It ties the click back to the sharing session. LinkClean strips it host-scoped to youtube.com / youtu.be / spotify.com so a parameter called si on an unrelated site is left alone.",
        sections: [
          {
            heading: "Where you'll see it",
            paragraphs: [
              "YouTube: every share from the iOS or Android app adds ?si=AbCdEf12345. Spotify: same parameter name, same behavior — every Spotify share carries it. The two platforms happened to pick the same letter; the tokens themselves are completely separate (YouTube's is Google's; Spotify's is Spotify's).",
            ],
          },
          {
            heading: "Why it's host-scoped",
            paragraphs: [
              "`si` is a short, generic-looking parameter name. Some sites use it functionally (sort indicator, session indicator, store ID). LinkClean's catalog scopes the strip rule to youtube.com / youtu.be / open.spotify.com / spotify.link — so the same parameter on an unrelated site isn't touched.",
            ],
          },
          {
            heading: "What gets preserved",
            paragraphs: [
              "Critically, YouTube's t= (start-at-N-seconds timestamp) is functional and preserved on every host. The youtu.be cleaning rule strips si but leaves t, so a shared video starts at the moment you intended.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Host-scoped default in LinkClean's referral catalog. Mirrors the t / s X rule (host-scoped strip on x.com / twitter.com).",
            ],
          },
        ],
        exampleDirty:
          "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=43&si=AbCdEf12345",
        exampleClean: "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=43",
        faq: [
          {
            q: "Are YouTube's si and Spotify's si the same token?",
            a: "No. Same parameter name, different tokens. They're separate attribution systems that happen to use the same letter.",
          },
          {
            q: "Does removing si break the video or track?",
            a: "No. The destination only reads the path and the v= / track ID. si is purely Google's / Spotify's bookkeeping.",
          },
          {
            q: "What about si on Reddit or Twitch?",
            a: "LinkClean's si rule is host-scoped to youtube.com / youtu.be / open.spotify.com / spotify.link. Reddit and Twitch use si= for different purposes — LinkClean leaves them alone.",
          },
          {
            q: "Why is si different from t= on YouTube?",
            a: "Both are added by YouTube, but t= is functional (the start timestamp). The catalog preserves t= and strips si= — exactly the distinction this site is built around.",
          },
        ],
      },
    },
  },

  // ── s-twitter (X share-source) ───────────────────────────────
  {
    slug: "s-twitter",
    param: "s",
    kind: "referral",
    searchDemand: "medium",
    vendor: {
      name: "X (formerly Twitter)",
      year: 2018,
      platform: "share-source identifier (host-scoped)",
      family: "X",
    },
    related: ["si", "igshid", "mibextid", "twclid"],
    content: {
      en: {
        title: "s= on X (Twitter) — the share-source identifier · LinkClean",
        searchTitle: "What is s in an X / Twitter share link?",
        description:
          "On X (formerly Twitter), s= is the share-source identifier — paired with t= (the per-share session). Strip both before forwarding — LinkClean does it host-scoped.",
        tldr: "X (formerly Twitter) adds two share-tracking parameters to outbound links: t= (the per-share session token) and s= (which surface the share came from — iOS app = 20, web client = 19, third-party = 46, etc). Both are host-scoped to x.com / twitter.com in LinkClean and stripped by default.",
        sections: [
          {
            heading: "What s= encodes",
            paragraphs: [
              "A numeric code identifying *where* the share originated. Known values include s=20 (iOS app), s=19 (web client), s=46 (third-party / API context). X uses it to slice share volume by surface in their internal dashboards. It doesn't identify you directly, but it narrows the cohort.",
            ],
          },
          {
            heading: "s= vs t=",
            paragraphs: [
              "t= is the per-share session token — closer to a unique fingerprint of the share. s= is the categorical surface code. Together they say “this share, from this surface.” LinkClean strips both as a pair; one without the other still leaks attribution.",
            ],
          },
          {
            heading: "Why host-scoped",
            paragraphs: [
              "`s` is a very short, generic parameter name. A blog might use ?s= for search. LinkClean's catalog scopes the strip to x.com / twitter.com — s= elsewhere is preserved.",
            ],
          },
          {
            heading: "How LinkClean removes it",
            paragraphs: [
              "Default-on in the referral catalog, paired with the same host-scoped t rule. Same architecture as the YouTube si cleanup.",
            ],
          },
        ],
        exampleDirty:
          "https://x.com/handle/status/1234567890?t=AbCdEf-12345_xyz&s=20",
        exampleClean: "https://x.com/handle/status/1234567890",
        faq: [
          {
            q: "Does removing s= break the tweet?",
            a: "No. The path (/handle/status/<id>) is the only part X needs to resolve the tweet.",
          },
          {
            q: "What's the difference between t= and s= on X?",
            a: "t= is per-share (a session-bound token, ~20 characters). s= is per-surface (which app or surface initiated the share, a small integer). Strip both.",
          },
          {
            q: "Why is this host-scoped?",
            a: "Because s= is a common functional parameter name on other sites (search queries on many blogs). LinkClean limits the X strip rule to x.com / twitter.com only.",
          },
          {
            q: "Does X use s= elsewhere on its site?",
            a: "No — it only appears on outbound share URLs. Internal X navigation doesn't carry it.",
          },
        ],
      },
    },
  },
];
