import type { LearnArticle } from "./types";

/** Wave-1 learn pillars — the two conversion-shaped explainers seo-content-plan
 *  flags as load-bearing for both organic SEO and LLM citation. */
export const LEARN_ARTICLES: ReadonlyArray<LearnArticle> = [
  // ── /learn/do-cleaned-links-still-work ───────────────────────
  {
    slug: "do-cleaned-links-still-work",
    content: {
      en: {
        title: "Do cleaned links still work?",
        description:
          "Short answer: yes. Tracking parameters are read by analytics scripts after the page loads — the page itself doesn't need them. Here's why, with exceptions.",
        tldr: "Yes. Tracking parameters live on the URL only so analytics tools can read them after the page loads — the page itself routes on the path, not on the query string. You can strip the entire ?…&… tail and the same article, video, or product page will load. Two exceptions: timestamps (?t=42 on YouTube) and search/state parameters (?q=hello on Wikipedia) are functional and must be preserved.",
        sections: [
          {
            heading: "How a URL is actually used",
            paragraphs: [
              "A URL has two halves: the path (the part before the ?) and the query string (the part after). When you click a link, your browser asks a server for the path. The server returns a page based on the path. The query string is along for the ride — the server may or may not look at it.",
              "Tracking parameters live in the query string. They're not part of the path, they're not used for routing, they're not used to authenticate, and they're not used to choose what the server returns. They exist so that *after* the page has loaded, an analytics script in the page can read them and report back where the click came from. Stripping them changes nothing about what the page does.",
            ],
          },
          {
            heading: "The two-second test",
            paragraphs: [
              "Take any link with a long tail of utm_*-style parameters. Delete everything from the ? onward. Refresh. Did you land on the same page? Almost always yes — the tail was tracking. The few exceptions are obvious by behavior: a YouTube link without ?t= starts at zero instead of the time you wanted; a Wikipedia link without ?q= shows the search box empty.",
              "LinkClean is built around exactly this distinction. Vendor-specific tracker names (utm_source, fbclid, gclid, …) are stripped by default. Generic names that double as functional keys (t, q, ref, source) are off by default — and the ones that LinkClean does strip are host-scoped to the sites where they're trackers (e.g. si= on YouTube but not elsewhere).",
            ],
          },
          {
            heading: "The exceptions worth knowing",
            paragraphs: [
              "Some query parameters do matter. They're rare on shared links — usually they're added by you, on purpose, when you wanted a specific state. The big ones to recognize:",
            ],
            bullets: [
              "Timestamps. YouTube's ?t=120 (start at 2:00), Vimeo's #t=2m0s, Twitch's ?t=01h00m. Strip them and the video starts from the beginning.",
              "Search / filter state. Wikipedia's ?q=, Amazon's ?k=, Reddit's ?sort=. Strip them and the page loads in its default state.",
              "Anchors / deep-link tokens for SPAs. Some apps store routing state in the query string (e.g. ?view=details). Strip them and the page might land on the wrong tab.",
              "Embedded credentials. Rare but real — magic-link login URLs, password-reset URLs. Strip them and the link stops authenticating.",
            ],
          },
          {
            heading: "Why a hand-trim isn't a substitute for a catalog",
            paragraphs: [
              "“Delete everything after the ?” works for utm_* tags, but tracking links often mix functional and tracking parameters in one tail. Strip them all and you lose the timestamp. Strip none and you've leaked tracking metadata.",
              "LinkClean's catalog is curated for exactly this distinction. utm_source, fbclid, gclid — stripped everywhere. Generic words that are sometimes trackers (e.g. ref, source) — off by default, opt-in per site. Host-scoped rules (si= on YouTube, tag= on Amazon) — applied only where they're actually trackers, never on hosts where the same name is functional. The whole catalog is ~80 default-on entries plus more behind opt-in toggles.",
            ],
          },
          {
            heading: "What if I share a cleaned link and the recipient says it doesn't work?",
            paragraphs: [
              "Almost never happens, but when it does, paste the cleaned link into LinkClean — the History view will show the original alongside it. You can re-share the original if needed, then submit feedback so the rule can be tightened (host-scoped, or turned off by default for that vendor). That's the same iteration loop the iOS app's parameter-telemetry pipeline feeds — catalog gaps are the part of the product the user audits over time.",
            ],
          },
        ],
        faq: [
          {
            q: "What about login or magic-link URLs?",
            a: "Those carry credentials in the query string and should never be stripped. They're also extremely rare on the kinds of links you'd share publicly. If you're forwarding a login link, you probably shouldn't be — that's a separate problem from tracking parameters.",
          },
          {
            q: "Does LinkClean ever break a video timestamp?",
            a: "No. t=, t=1m20s, and #t= variants are preserved on every host. LinkClean's YouTube cleaning is host-scoped to youtube.com and youtu.be, and it strips si= (share identifier) while leaving t= (timestamp) intact.",
          },
          {
            q: "What about Amazon product links?",
            a: "Amazon-specific tracking keys (tag=, ref_=, pf_rd_*) are host-scoped to Amazon storefronts in LinkClean's catalog. The product ID, search query, and storefront language are preserved. The affiliate-credit and click-attribution tail is removed.",
          },
          {
            q: "Are there any sites where this strategy fails?",
            a: "A small number of SPAs (single-page apps) store deep-link state in the query string — strip it and you might land on the wrong tab. LinkClean errs toward preserving generic names by default and scopes the aggressive rules to hosts where they're known trackers. If you find a site where cleaning breaks something, the report flow inside the iOS app surfaces exactly which parameter was at fault.",
          },
        ],
        related: [
          {
            label: "What is utm_source, and why is it safe to remove?",
            href: "/trackers/utm-source/",
          },
          {
            label: "What's hidden in a share link?",
            href: "/learn/whats-hidden-in-a-share-link/",
          },
          {
            label: "How to remove UTM parameters from a link",
            href: "/guides/remove-utm-parameters/",
          },
        ],
      },
    },
  },

  // ── /learn/whats-hidden-in-a-share-link ──────────────────────
  {
    slug: "whats-hidden-in-a-share-link",
    content: {
      en: {
        title: "What's hidden in a share link?",
        description:
          "A phone-share link's tail of trackers reveals where you clicked from, which ad credited the click, and which campaign got the credit. Unpacked here.",
        tldr: "A modern share link is rarely just a URL. The tail after the ? is a mix of analytics campaign tags (utm_source, utm_medium, utm_campaign), ad-network click IDs (fbclid, gclid, msclkid, ttclid), and vendor-specific share identifiers (YouTube's si=, Spotify's si=, X's t= / s=). Together they say: where the click started, which ad it credited, and which session shared it forward.",
        sections: [
          {
            heading: "A real share link, unpacked",
            paragraphs: [
              "Here's a typical link you'd see in a newsletter and might forward to a friend:",
              "https://example.com/2026/spring-launch?utm_source=newsletter&utm_medium=email&utm_campaign=spring&utm_content=hero-cta&fbclid=IwAR0aBc&gclid=Cj0KCQ",
              "The path — /2026/spring-launch — is the only part the destination server cares about. Everything after the ? is metadata being broadcast to whoever's analytics, ad networks, and pixels happen to be on the destination page.",
            ],
            bullets: [
              "utm_source=newsletter — Google Analytics attribution: the click came from a newsletter.",
              "utm_medium=email — the channel was email (not social, not paid search).",
              "utm_campaign=spring — the campaign bucket inside Google Analytics.",
              "utm_content=hero-cta — which CTA on the page was clicked (publisher A/B tags it).",
              "fbclid=IwAR0aBc — Meta's click identifier, tying the click to a Facebook session.",
              "gclid=Cj0KCQ — Google Ads' click identifier, crediting the ad-account that paid for the click.",
            ],
          },
          {
            heading: "Who gets the data, and what they do with it",
            paragraphs: [
              "Three audiences read what's hidden in your share link:",
            ],
            bullets: [
              "The publisher's analytics tool (usually Google Analytics) reads utm_* tags and credits the visit to a campaign. It tells the publisher their newsletter is converting.",
              "The ad networks (Meta Pixel, Google Ads conversion tag, TikTok Pixel) read their respective click IDs and report a “conversion” back to the platform that served the ad. They tell the advertiser the spend worked.",
              "The destination site's own tools — and any third-party scripts on the page — get to see the tail too. A tag manager might fan the parameters out to a dozen downstream tools at once.",
            ],
          },
          {
            heading: "What it leaks about you when you forward it",
            paragraphs: [
              "Forwarding a link with this tail still attached has three effects:",
            ],
            bullets: [
              "Your forward gets credited to the original campaign. Whoever reads the analytics sees “one more click from the spring newsletter” — even though, from their reader's point of view, the click came from you.",
              "The ad-network click IDs follow your share into someone else's browser. If the recipient's browser runs Meta Pixel or Google's conversion tag, those scripts report a pageview tied to *your* click identifier. Quietly inflated bookkeeping; minor but real signal back to the platforms.",
              "Anyone snooping on the link (a logging proxy, a clipboard manager, a screenshot OCR) sees the tail too. utm_source=newsletter doesn't identify you, but it does reveal where you got the link.",
            ],
          },
          {
            heading: "Why per-app share buttons hide this from you",
            paragraphs: [
              "On the desktop, you'd see the URL bar and notice the tail. On a phone, the share sheet shows you an app icon, a thumbnail, and a button — the URL itself is hidden inside the share payload. That's the gap LinkClean fills: the share sheet runs the cleaning between the source app and whatever you forward to. The clean URL replaces the dirty one before the sheet closes.",
              "Browser-extension cleaners can't do this. They only see what passes through the browser tab. They can't see the link you're about to forward from Mail, Slack, Messages, X, or Reddit — the apps where most sharing happens on a phone. That's the architectural reason LinkClean is a native iOS app, not a Safari extension.",
            ],
          },
          {
            heading: "Recognizing the most common hidden parameters",
            paragraphs: [
              "Once you've seen the pattern, you start spotting these everywhere. The most common ones — all in LinkClean's default catalog, all stripped by default:",
            ],
            bullets: [
              "utm_source, utm_medium, utm_campaign, utm_term, utm_content — Google Analytics campaign tags.",
              "fbclid — Meta click identifier.",
              "gclid, gbraid, wbraid — Google Ads click identifiers.",
              "msclkid — Microsoft Ads.",
              "ttclid — TikTok Ads.",
              "yclid — Yandex Ads.",
              "mc_eid — Mailchimp email identifier (per-recipient unique).",
              "_fbp, _fbc — Meta cookie-mirroring URL parameters.",
              "si= on YouTube / Spotify — share-identifier tokens that credit who pressed Share.",
              "t= / s= on x.com — share-token equivalents (host-scoped — t= on YouTube is timestamp, NOT a tracker).",
            ],
          },
          {
            heading: "The simple rule",
            paragraphs: [
              "If you didn't put it there on purpose, it's tracking. Paths are functional. Query strings are mostly metadata. Strip the metadata before you share — LinkClean's job is to make that automatic, on every surface where sharing happens on iPhone.",
            ],
          },
        ],
        faq: [
          {
            q: "Is the URL the only thing that gets shared?",
            a: "On a share sheet, usually yes — the share payload is the URL plus maybe a title. The “hidden” we're talking about is *within* the URL itself: the tail of trackers after the ?. The fix is to clean that tail before the share happens.",
          },
          {
            q: "What about share links from Apple's apps?",
            a: "Apple's own share buttons usually emit clean URLs (no fbclid / gclid / etc., since they're not Meta or Google's apps). But the link you copied into Apple's share path might already be dirty from wherever you got it. LinkClean cleans whatever ends up in your share-sheet payload, regardless of the source app.",
          },
          {
            q: "If a link looks short, is it clean?",
            a: "Not necessarily. URL shorteners (bit.ly, t.co, lnkd.in) hide the destination URL — including any tracking tail — behind a redirect. The expanded URL after the redirect is still dirty. LinkClean's E1 redirect unwrapping resolves these locally and runs the same cleaning pipeline on the destination.",
          },
          {
            q: "Do all sites do this?",
            a: "Tracking parameters are added by publishers, ad networks, and email tools — they're attached on the way out, not by the destination site. So they appear on any link served through a campaign, an ad, or an email — which is most of the high-traffic web. A direct link you typed into the address bar is usually clean.",
          },
        ],
        related: [
          {
            label: "What is utm_source?",
            href: "/trackers/utm-source/",
          },
          {
            label: "What is fbclid?",
            href: "/trackers/fbclid/",
          },
          {
            label: "What is gclid?",
            href: "/trackers/gclid/",
          },
          {
            label: "Do cleaned links still work?",
            href: "/learn/do-cleaned-links-still-work/",
          },
          {
            label: "How to clean a YouTube share link",
            href: "/guides/clean-youtube-link/",
          },
        ],
      },
    },
  },
];
