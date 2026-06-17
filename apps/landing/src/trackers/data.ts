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
    vendor: "Google Analytics (originally Urchin)",
    related: ["utm-medium", "utm-campaign", "fbclid", "gclid"],
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
    vendor: "Google Analytics (originally Urchin)",
    related: ["utm-source", "utm-campaign", "fbclid"],
    content: {
      en: {
        title: "utm_medium — what it names and why it's safe to strip · LinkClean",
        description:
          "utm_medium names the marketing channel a click came through — email, social, cpc. It pairs with utm_source on every Google Analytics campaign link. Strip it before sharing.",
        tldr: "utm_medium names the marketing **channel** — “email”, “social”, “cpc” (paid search), “organic”. Pairs with utm_source to answer “which channel?”. Removing it never breaks the link.",
        sections: [
          {
            heading: "What utm_medium adds on top of utm_source",
            paragraphs: [
              "utm_source names *where* the click came from (the specific publisher, list, or vendor); utm_medium names *how* — the channel class. Together they answer the analyst's first question: “did this campaign land via email, via social, via paid search, or via something else?”.",
              "Standard utm_medium values are conventional but not enforced: email, social, cpc (cost-per-click paid search), display, affiliate, organic, referral. The values are whatever the publisher decides; Google Analytics treats them as opaque strings.",
            ],
          },
          {
            heading: "What it leaks when you forward the link",
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
    vendor: "Google Analytics (originally Urchin)",
    related: ["utm-source", "utm-medium", "fbclid"],
    content: {
      en: {
        title: "utm_campaign — what publishers learn from it · LinkClean",
        description:
          "utm_campaign labels the marketing campaign — “spring-launch”, “black-friday-2026”. It buckets clicks inside Google Analytics so publishers can compare campaigns. Safe to strip.",
        tldr: "utm_campaign labels the marketing campaign — “spring-launch”, “black-friday-2026”. It buckets clicks inside Google Analytics so the publisher can compare campaigns. The page renders identically without it.",
        sections: [
          {
            heading: "What utm_campaign actually does",
            paragraphs: [
              "Every utm_source + utm_medium combination can roll up under a named campaign. utm_campaign is that label — a free-form string the publisher picks, usually descriptive enough for a human to read in an analytics dashboard. “summer-sale-2026”, “onboarding-week-2”, “launch-day-tweet”.",
              "Google Analytics groups all clicks sharing the same utm_campaign value into one bucket, regardless of source or medium. That bucket is how marketers answer “how did this campaign do?” across email + social + paid search at once.",
            ],
          },
          {
            heading: "What it leaks when you forward",
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
    vendor: "Meta (Facebook)",
    related: ["gclid", "msclkid", "ttclid", "utm-source"],
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
    vendor: "Google Ads",
    related: ["fbclid", "msclkid", "ttclid", "utm-source"],
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
    vendor: "Microsoft Advertising (Bing Ads)",
    related: ["gclid", "fbclid", "ttclid"],
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
    vendor: "TikTok Ads",
    related: ["fbclid", "gclid", "msclkid"],
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

  // ── hl (functional — preserved, not stripped) ────────────────
  {
    slug: "hl",
    param: "hl",
    kind: "regional",
    nature: "functional",
    vendor: "Google (Search, YouTube, Maps, Translate, …)",
    related: ["utm-source", "fbclid"],
    content: {
      en: {
        title: "hl — what Google's host-language parameter does · LinkClean",
        description:
          "hl is Google's host-language parameter — it sets the interface language on Search, YouTube, Maps, and other Google services. It's functional, not tracking; LinkClean preserves it.",
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

  // ── mc_eid ───────────────────────────────────────────────────
  {
    slug: "mc-eid",
    param: "mc_eid",
    kind: "email",
    vendor: "Mailchimp",
    related: ["utm-source", "fbclid"],
    content: {
      en: {
        title: "mc_eid — Mailchimp's per-recipient email ID · LinkClean",
        description:
          "mc_eid is Mailchimp's email recipient identifier — a per-subscriber token added to outbound newsletter links. It's tied to your email address. LinkClean strips it by default.",
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
];
