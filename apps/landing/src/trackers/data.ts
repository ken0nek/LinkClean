import type { TrackerSpoke } from "./types";

/** Wave-1 tracker spokes. Each spoke is structured to read as a self-contained
 *  explainer (TL;DR + sections + example + FAQ + related), so SEO + LLMO can
 *  cite a single page for one parameter. Cross-link via `related` slugs. */
export const TRACKERS: ReadonlyArray<TrackerSpoke> = [
  // ── utm_source ───────────────────────────────────────────────
  {
    slug: "utm-source",
    param: "utm_source",
    kind: "utm",
    vendor: "Google Analytics (originally Urchin)",
    related: ["fbclid", "gclid"],
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

  // ── fbclid ───────────────────────────────────────────────────
  {
    slug: "fbclid",
    param: "fbclid",
    kind: "ads",
    vendor: "Meta (Facebook)",
    related: ["gclid", "utm-source"],
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
    related: ["fbclid", "utm-source"],
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
];
