import type { LearnArticle } from "./types";

/** "Learn" pillar articles — long-form explainers. Template E. */
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
            label: "Click IDs vs UTM tags — what's the difference?",
            href: "/learn/click-ids-vs-utm-tags/",
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
              "[utm_source](/trackers/utm-source/), [utm_medium](/trackers/utm-medium/), [utm_campaign](/trackers/utm-campaign/), [utm_term](/trackers/utm-term/), [utm_content](/trackers/utm-content/), [utm_id](/trackers/utm-id/) — Google Analytics campaign tags.",
              "[fbclid](/trackers/fbclid/) — Meta click identifier.",
              "[gclid](/trackers/gclid/), [gbraid](/trackers/gbraid/), [wbraid](/trackers/wbraid/), [dclid](/trackers/dclid/) — Google Ads click identifiers (search + iOS-era replacements + display network).",
              "[gad_source](/trackers/gad-source/), [gad_campaignid](/trackers/gad-campaignid/), [srsltid](/trackers/srsltid/) — newer Google Ads first-party tags + Shopping result IDs.",
              "[msclkid](/trackers/msclkid/) — Microsoft Ads.",
              "[ttclid](/trackers/ttclid/) — TikTok Ads. [twclid](/trackers/twclid/) — X (Twitter) Ads.",
              "[yclid](/trackers/yclid/) — Yandex Ads. [epik](/trackers/epik/) — Pinterest. [sc_click_id](/trackers/sc-click-id/) — Snapchat. [rdt_cid](/trackers/rdt-cid/) — Reddit.",
              "[li_fat_id](/trackers/li-fat-id/) — LinkedIn Ads' email-bound click ID.",
              "[mc_eid](/trackers/mc-eid/), [mc_cid](/trackers/mc-cid/), [mc_tc](/trackers/mc-tc/) — Mailchimp's per-recipient + campaign + tap-target trio.",
              "[mkt_tok](/trackers/mkt-tok/) (Marketo, B2B), [_hsenc](/trackers/hsenc/) + [_hsmi](/trackers/hsmi/) (HubSpot), [_kx](/trackers/kx/) (Klaviyo) — per-recipient email tokens, identity-bound on the vendor's side.",
              "[spm](/trackers/spm/) — Alibaba's Super Position Model tracker (Tmall / Taobao / AliExpress).",
              "_fbp, _fbc — Meta cookie-mirroring URL parameters.",
              "si= on YouTube / Spotify — share-identifier tokens that credit who pressed Share.",
              "t= / s= on x.com — share-token equivalents (host-scoped — [t= on YouTube is timestamp](/trackers/t-youtube/), NOT a tracker).",
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
            label: "What is mc_eid?",
            href: "/trackers/mc-eid/",
          },
          {
            label: "Click IDs vs UTM tags — what's the difference?",
            href: "/learn/click-ids-vs-utm-tags/",
          },
          {
            label: "What t= and s= mean in an X (Twitter) share URL",
            href: "/learn/x-twitter-share-url-explained/",
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

  // ── /learn/x-twitter-share-url-explained ─────────────────────
  {
    slug: "x-twitter-share-url-explained",
    content: {
      en: {
        title: "What t= and s= mean in an X (Twitter) share URL",
        description:
          "X share URLs end with ?t=…&s=… — t is a per-device session token, s is a 2-digit code identifying which device + sharing method created the link (e.g. s=46 = iPhone Copy Link). Both are tracking; LinkClean strips both, host-scoped.",
        tldr: "Every X share URL ends with `?t=<token>&s=<2-digit-code>`. **`s` encodes the device + sharing method** (Android Copy Link, iPhone Copy Link, Twitter Web Email, etc. — 71 distinct codes have been catalogued from Twitter's own JavaScript). **`t` is a per-device session token** that lets X correlate multiple shares from the same source within a time window. Both are pure tracking; the tweet loads identically without them. LinkClean strips both, host-scoped to `x.com` / `twitter.com` so it doesn't touch `t=` on YouTube (where it's a timestamp).",
        sections: [
          {
            heading: "Anatomy of an X share URL",
            paragraphs: [
              "Pick any tweet, tap Share → Copy Link, and you get something like:",
              "https://x.com/handle/status/1234567890123456789?t=AbCdEf-12345_xyz&s=46",
              "The path — /handle/status/<tweet-id> — is the only part the server cares about. Open the URL with the path alone and you get the same tweet; the `?t=…&s=…` tail exists purely for X's attribution funnel.",
            ],
            bullets: [
              "`/handle/` — the account that posted the tweet (or any retweeter).",
              "`/status/<tweet-id>` — the unique tweet identifier; the only part X needs to render the page.",
              "`?t=<token>` — a per-device session token (more below).",
              "`&s=<2-digit code>` — which device + sharing method generated this share URL (the focus of this article).",
            ],
          },
          {
            heading: "The `s` parameter — device + sharing method",
            paragraphs: [
              "`s` is a two-digit code (always 2 digits — `s=09`, `s=19`, `s=46`, etc.) that X uses to record exactly which client + which button generated the share URL. Each code is a unique combination of:",
            ],
            bullets: [
              "**Device type** — Android phone, iPhone, iPad, Twitter Web (desktop), Twitter Web (mobile), or a third-party Twitter client like Gryphon.",
              "**Sharing method** — Copy Link, Email, SMS, WhatsApp, Telegram, Messenger, Facebook, Snapchat, Instagram, LinkedIn, Slack, Discord, Reddit, Line, Kakao, Viber, WeChat, Hangouts, Gmail, Twitter DM, and a few platform-specific options.",
              "**71 distinct codes** have been catalogued in total, by analysing Twitter's own front-end JavaScript (see Unfurl, the social-media URL parser).",
            ],
          },
          {
            heading: "Common `s` values you'll see in the wild",
            paragraphs: [
              "These are the ones that show up most often when you copy a tweet URL. The mapping is reverse-engineered from Twitter's JS by community researchers, not officially documented — but it's stable across years of observation:",
            ],
            table: {
              caption: "Common s-codes when copying a tweet URL",
              headers: ["Value", "Device", "Sharing method"],
              rows: [
                ["s=09", "iOS (older Twitter app)", "Native share menu"],
                ["s=12", "iOS", "iOS share sheet"],
                ["s=17", "Twitter Web (desktop)", "Email share"],
                ["s=18", "Twitter Web (desktop)", "Download / direct"],
                ["s=19", "Android", "Copy Link button"],
                ["s=20", "Twitter Web (desktop)", "Copy Link button (the most common in the wild)"],
                ["s=21", "Twitter Web (newer UI)", "Copy Link button"],
                ["s=41", "Gryphon (3rd-party iOS client)", "Copy Link"],
                ["s=46", "iPhone Twitter app", "Copy Link button"],
              ],
            },
          },
          {
            heading: "What does `s=46` specifically mean?",
            paragraphs: [
              "`s=46` means **the share URL was generated by tapping “Copy Link” in the Twitter (X) iPhone app**. If a friend forwards you a tweet and the URL ends in `?t=…&s=46`, they used the iPhone app's Copy Link button — not the share sheet, not the web, not Android.",
              "It's the iPhone-app counterpart to `s=20` (Twitter Web Copy Link) and `s=19` (Android Copy Link). Together with `t=`, X can tell that a particular tweet was copied from a particular iPhone session at a particular time, and whether subsequent shares of the same tweet came from the same source or different sources.",
              "The forensic-grade detail of this scheme is also why removing `s=` and `t=` before forwarding is the right default: they encode quite a bit more than the destination needs.",
            ],
          },
          {
            heading: "The `t` parameter",
            paragraphs: [
              "`t` is an opaque token that's not officially documented, but observation shows it's consistent per device for a time window — multiple shares from the same Twitter session tend to carry the same or related `t` values, while shares from different devices have different ones.",
              "That makes `t` useful to X as a join key: if two share URLs of the same tweet arrive at X's pixel with the same `t`, they almost certainly originate from the same device session — which lets X reason about virality (one tweet shared by a thousand different `t` values is genuinely spreading; one tweet shared a thousand times by a single `t` value looks like abuse).",
              "From your point of view, the privacy concern is that `t` ties any pageview through that URL back to your device session — even after the share has bounced through multiple recipients.",
            ],
          },
          {
            heading: "What does X actually learn from these?",
            paragraphs: [
              "Combined, `t` and `s` give X a fine-grained attribution signal every time someone clicks a share URL:",
            ],
            bullets: [
              "**Which device produced the share** — the `s` code identifies the device category and the surface (iPhone app, Android, web).",
              "**Which sharing button was used** — `s` also encodes the button (Copy Link, Email, Snapchat, SMS, …).",
              "**Approximate device fingerprint via session** — `t` correlates multiple shares from the same session, even across tweets.",
              "**Funnel analytics** — how often a tweet gets shared, on which surfaces, and how often those shares convert to engagement back on X.",
              "**Abuse signals** — repeated identical `t` across a tweet's share URLs suggests automation or coordinated sharing.",
            ],
          },
          {
            heading: "How LinkClean removes `t=` and `s=` (without breaking YouTube)",
            paragraphs: [
              "Naïvely stripping any `t=` parameter would break YouTube share links — YouTube's `t=42` is the start-at-N-seconds timestamp, not a tracker. LinkClean's catalog scopes the `t/s` cleaning rules to `x.com` and `twitter.com` only. On those hosts, `t` and `s` are stripped on every cleaning surface (share extension, widget, app, QR). On every other host they're left alone.",
              "Same goes for X's less-common share-tail parameters: `cn=` and `refsrc=` (X-specific) both ship default-on, host-scoped. The cleaned URL is `https://x.com/handle/status/<tweet-id>` — the canonical permalink you'd get by typing the URL into the address bar yourself.",
              "If you want to see this transformation explicitly, paste an X share URL into the LinkClean app — the History view shows the original alongside the cleaned version, with `t`, `s`, and any extras called out as stripped.",
            ],
          },
        ],
        faq: [
          {
            q: "If I keep `s=46`, what does X learn about me?",
            a: "X learns that whoever clicked the URL is engaging with a link generated from a specific session on a specific iPhone. Joined with `t=`, X can tell if this is the same session that produced the share, or someone else (a forward recipient).",
          },
          {
            q: "Are there 71 distinct s codes, really?",
            a: "Yes — 71 codes have been catalogued across five device categories (Android, iOS, iPhone, iPad, plus desktop web and special clients). The full list was extracted from Twitter's own front-end JavaScript by community researchers (Unfurl, the open-source social-media URL parser, is the canonical reference).",
          },
          {
            q: "Why does X bother encoding the sharing method?",
            a: "Attribution and abuse detection. Knowing which surface produced each share lets X measure which sharing buttons drive engagement, A/B-test new buttons, detect automation patterns (mass shares from a single session), and credit shares back to source-app metrics.",
          },
          {
            q: "Are `t` and `s` personal data?",
            a: "Not by themselves — they don't carry your username or email. But X can join them to your account on their side via the cookie or app session that produced the share. Functionally, yes: they identify the share's source to X.",
          },
          {
            q: "Will the tweet still load without `t=` and `s=`?",
            a: "Yes. The path — `/handle/status/<tweet-id>` — is all X needs. The tail is purely for X's attribution funnel. The cleaned URL renders the same tweet, same thread, same everything.",
          },
          {
            q: "Does LinkClean strip these on every site?",
            a: "No — they're host-scoped to `x.com` and `twitter.com` in the catalog. That's intentional: `t=` is a timestamp on YouTube, and `s=` is sometimes functional on other sites. LinkClean only strips them where they're known X trackers.",
          },
          {
            q: "What about retweets and quote-tweets?",
            a: "Same parameter scheme — the `s=` code identifies the share source the same way regardless of whether the underlying tweet is original, retweeted, or quoted. The `t=` token is bound to the device session, not the tweet.",
          },
        ],
        related: [
          {
            label: "How to clean an X (Twitter) share link",
            href: "/guides/clean-x-twitter-link/",
          },
          {
            label: "What is fbclid?",
            href: "/trackers/fbclid/",
          },
          {
            label: "What's hidden in a share link?",
            href: "/learn/whats-hidden-in-a-share-link/",
          },
          {
            label: "Click IDs vs UTM tags — what's the difference?",
            href: "/learn/click-ids-vs-utm-tags/",
          },
          {
            label: "Do cleaned links still work?",
            href: "/learn/do-cleaned-links-still-work/",
          },
        ],
      },
    },
  },

  // ── /learn/click-ids-vs-utm-tags ─────────────────────────────
  {
    slug: "click-ids-vs-utm-tags",
    content: {
      en: {
        title: "Click IDs vs UTM tags: what's the difference?",
        description:
          "Tracking parameters fall into two big families: anonymous campaign tags (utm_*) and per-click ad-network identifiers (fbclid, gclid, msclkid, ttclid). Here's how they differ and why LinkClean strips both.",
        tldr: "Two families of tracking parameters: **UTM tags** (utm_source, utm_medium, utm_campaign — Google Analytics campaign attribution, broadly anonymous) and **click IDs** (fbclid, gclid, msclkid, ttclid — per-click tokens that ad networks use to tie a click back to a specific ad impression and the cookie that saw it). UTM tags name the *campaign*; click IDs identify the *click*. LinkClean strips both by default, but the harm model is different.",
        sections: [
          {
            heading: "What UTM tags actually do",
            paragraphs: [
              "UTM (Urchin Tracking Module) parameters were invented in 1996 by Urchin Software Corporation and absorbed into Google Analytics in 2005. The five tags — utm_source, utm_medium, utm_campaign, utm_term, utm_content — are publisher-authored: whoever sets up a campaign decides the values. There's no central authority and no per-user uniqueness.",
              "Their job is to answer one question for the publisher's analytics: “which campaign did this click come from?”. utm_source names the origin, utm_medium names the channel, utm_campaign names the campaign bucket. The values are descriptive strings (“newsletter”, “email”, “spring-launch”) — readable in a dashboard, opaque to anyone else.",
              "Crucially, none of these values are unique to a person. utm_source=newsletter means “this click came from a newsletter” — it could be any subscriber, any forward, any forwarded forward. The publisher learns a count, not an identity.",
            ],
          },
          {
            heading: "What click IDs actually do",
            paragraphs: [
              "fbclid, gclid, msclkid, ttclid, yclid — each one is generated by an ad network at click time and is **unique per click**. The token encodes the ad-account, the campaign, the ad creative, the click event, and (where the network still has a cookie or IDFA) the user identifier on their side.",
              "When the destination page loads, the ad-network's pixel reads the click ID and reports it home. The network now knows: “the impression we served at 12:04:31 from campaign 7821-ad-3, attributed to user-cookie ABC123, did in fact convert into a pageview.” Down to the individual click.",
              "Click IDs aren't designed to identify *you* to the destination site — but they identify the click to the ad network, and the ad network usually has a cookie or other join key on you separately. So joined-up, they're identity-adjacent.",
            ],
          },
          {
            heading: "Why both exist on the same link",
            paragraphs: [
              "Different audiences. UTM tags serve the *publisher's* analytics (Google Analytics reading their own outbound links). Click IDs serve the *ad network's* attribution (Meta knows their ad worked).",
              "When you click a Facebook ad: Meta adds fbclid (for their pixel to read). The advertiser had also added utm_source=facebook&utm_medium=cpc&utm_campaign=… in the ad's destination URL (for their Google Analytics). Both ride along to your browser. Both get reported home to two different systems.",
            ],
          },
          {
            heading: "What the harm model is",
            paragraphs: [
              "UTM tags broadcast marketing metadata. The risk of forwarding them is that you carry the publisher's campaign attribution into someone else's analytics. Annoying for the publisher's bookkeeping (their forward gets counted as a newsletter click); not particularly harmful to you or the recipient.",
              "Click IDs are stronger. Forwarding fbclid carries Meta's click identifier into someone else's browser — if their browser runs Meta Pixel on the destination page, the Pixel reports a pageview tied to *your* click context. Meta now sees a Pixel hit they can join to your original ad impression. Quietly inflated bookkeeping plus an extra signal back to the ad network.",
              "Both are worth stripping. Click IDs are worth stripping more.",
            ],
          },
          {
            heading: "Why LinkClean strips both by default",
            paragraphs: [
              "LinkClean's catalog rule is “vendor-specific names get default-on”. utm_source / utm_medium / utm_campaign / fbclid / gclid / msclkid / ttclid / yclid all qualify — no legitimate URL uses these for anything but tracking attribution. They're stripped on every host with no opt-in needed.",
              "Generic words (ref, source, t, s, q) that double as functional keys on some sites — those stay default-off, with host-scoped exceptions where they're known trackers (si= on YouTube, t/s on x.com).",
            ],
          },
        ],
        faq: [
          {
            q: "If I keep utm_source, am I leaking my identity?",
            a: "No — utm_source names a campaign, not a person. The risk is broadcasting marketing metadata when you forward, not user identification.",
          },
          {
            q: "If I keep fbclid, am I leaking my identity?",
            a: "Closer to yes. fbclid is tied to your Facebook cookie on Meta's side. Forwarding it sends Meta a signal joined to your original ad impression. The recipient's Pixel hit is reported with *your* click context.",
          },
          {
            q: "What about email-marketing trackers — are those click IDs?",
            a: "Mailchimp's mc_eid is closer to a click ID in shape (per-recipient, identity-adjacent) than to a UTM tag (campaign-level). LinkClean strips it as default-on. See the mc_eid spoke for the full story.",
          },
          {
            q: "Why not just block one and not the other?",
            a: "Because nearly every advertised link has both. Stripping only UTM tags leaves the ad-network attribution intact; stripping only click IDs leaves the publisher's GA bucket intact. Default-on for both gives the cleanest privacy posture by default.",
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
            label: "What is msclkid?",
            href: "/trackers/msclkid/",
          },
          {
            label: "What's hidden in a share link?",
            href: "/learn/whats-hidden-in-a-share-link/",
          },
          {
            label: "Do cleaned links still work?",
            href: "/learn/do-cleaned-links-still-work/",
          },
        ],
      },
    },
  },

  // ── /learn/how-to-share-a-clean-link ─────────────────────────
  {
    slug: "how-to-share-a-clean-link",
    content: {
      en: {
        title: "How to share a clean link — the practice, by platform",
        description:
          "Why cleaning a link before sharing matters, and the per-platform workflow for X, Instagram, YouTube, TikTok, Spotify, Amazon, and email.",
        tldr: "Every modern share link from a major app carries an attribution token — Instagram's igshid, X's t / s, YouTube's si, TikTok's _r / _t, Facebook's mibextid. Stripping them before forwarding preserves the destination perfectly while breaking the attribution chain back to your account. The practice is the same across platforms; only the parameter names change.",
        sections: [
          {
            heading: "Why it matters",
            paragraphs: [
              "Share links are uniquely high-leverage data. They travel: you send one to a friend, they re-share to a group chat, the group chat re-shares to a feed. Every leg of that journey carries the attribution token forward unless someone strips it.",
              "Unlike a tracker on a page you visit (which only sees you), a tracker on a link you share sees everyone the link reaches. Cleaning before sharing is the one moment where one action helps many.",
            ],
          },
          {
            heading: "The pattern, abstracted",
            paragraphs: [
              "Every major platform uses the same architecture: the path identifies the content; the query string carries attribution. Strip the query string (or the known-tracker subset of it) and the destination loads identically.",
              "The few exceptions are functional parameters — timestamps, search queries, sort orders. A well-curated catalog (host-scoped, with explicit functional preservation) is what separates a usable cleaner from a naive one.",
            ],
          },
          {
            heading: "By platform — what to strip, what to keep",
            paragraphs: [
              "A reference table for the share links you'll actually encounter. Strip column = what LinkClean removes by default; keep column = what's preserved as functional or as the destination's canonical form.",
            ],
            table: {
              headers: ["Platform", "Share-link tracker(s)", "Preserved"],
              rows: [
                ["X (formerly Twitter)", "t=, s=", "/handle/status/<id> (path)"],
                ["Instagram", "igshid, utm_source=ig_web_copy_link", "/p/<shortcode>/ or /reel/<shortcode>/"],
                ["YouTube", "si=", "v=, t= (timestamp)"],
                ["Spotify", "si=", "/track/<id>, /album/<id>, /playlist/<id>"],
                ["TikTok", "tt_medium, _r, _t, ttclid (ads)", "/@user/video/<id>"],
                ["Facebook / Messenger", "mibextid, fbclid (ads)", "/<post-id>"],
                ["Amazon", "tag, ref_, pf_rd_*", "/dp/<ASIN>"],
                ["Email blast (Mailchimp, HubSpot, …)", "mc_eid, mc_cid, mkt_tok, _hsenc, _hsmi, utm_*", "the article URL"],
              ],
            },
          },
          {
            heading: "The three workflows",
            paragraphs: [
              "How you actually do this on a phone, fastest to slowest:",
            ],
            bullets: [
              "**Share-sheet action.** The fastest: tap Share, pick Clean URL, the cleaned link is on your clipboard before the sheet closes. Works from any app.",
              "**Widget / Control Center.** Copy the link, tap LinkClean's home-screen widget or the Control Center toggle, the clipboard updates in place. Useful for batches.",
              "**Paste into the app.** Open LinkClean, paste, see what was stripped (the educational mode — useful before sharing something sensitive).",
            ],
          },
          {
            heading: "When you specifically want to keep the tracker",
            paragraphs: [
              "Two cases: (1) a creator sharing their own affiliate link on purpose; (2) a marketer sharing a UTM'd link to measure a campaign.",
              "For (1), LinkClean's paste-into-app workflow shows the cleaned vs original side-by-side — pick whichever you want before sharing. For (2), the original is one undo away; the cleaning is reversible at the input.",
            ],
          },
          {
            heading: "The compounding effect",
            paragraphs: [
              "Per share, the saving is small — one attribution token doesn't change the world. But shares compound: a link cleaned once stays clean as it forwards. Over a year of group-chat sharing, that's hundreds of attribution tokens not propagated.",
              "The cleaning practice is one of the few privacy-hygiene habits where the per-action cost is near-zero and the downstream effect is meaningful.",
            ],
          },
        ],
        faq: [
          {
            q: "Why does every platform do this?",
            a: "Attribution. Knowing which shares produce clicks (and downstream conversions) is the most valued analytics signal a platform can collect. They all build it into share links because share is the channel they can't measure server-side otherwise.",
          },
          {
            q: "Are share-link trackers worse than ad-click trackers?",
            a: "Different. fbclid / gclid / ttclid attribute ad spend (the platform tracks back to whoever paid for the click). igshid / mibextid / si / t attribute organic shares (the platform tracks back to whoever shared the link). Both are attribution; both are safely strippable; share-link tokens propagate further because they're forwarded by hand.",
          },
          {
            q: "What about WhatsApp / Telegram / Signal?",
            a: "Those messengers don't add their own attribution tokens to forwarded links — they're message clients, not analytics platforms. But links forwarded *through* them carry the originating platform's tokens (the IG / X / YT tail). Clean once at the source; the recipient gets a clean link regardless of how many messengers it bounces through.",
          },
          {
            q: "Does cleaning prevent the destination site from tracking me?",
            a: "No. The destination's own analytics (its first-party cookie, its server logs, its IP-based geolocation) still operate. Cleaning a share link strips the *attribution back to the sharing platform*, not the destination's own measurement.",
          },
        ],
        related: [
          {
            label: "What's hidden in a share link?",
            href: "/learn/whats-hidden-in-a-share-link/",
          },
          {
            label: "Do cleaned links still work?",
            href: "/learn/do-cleaned-links-still-work/",
          },
          {
            label: "What is igshid (Instagram's share token)?",
            href: "/trackers/igshid/",
          },
          {
            label: "How to clean an Instagram share link",
            href: "/guides/clean-instagram-link/",
          },
        ],
      },
    },
  },

  // ── /learn/google-ad-click-parameters ────────────────────────
  {
    slug: "google-ad-click-parameters",
    content: {
      en: {
        title: "Google's ad-click URL parameters, explained (gclid, gad_source, gbraid…)",
        description:
          "Google Ads auto-tags clicks with gclid, gbraid, wbraid, dclid, gad_source and gad_campaignid. Here's what each one is, what the gad_source numbers mean, and why every one is safe to strip.",
        tldr: "Click a Google ad and Google's **auto-tagging** appends one or more parameters to the destination URL — **`gclid`** (the original click ID), **`gbraid`/`wbraid`** (the iOS-privacy-era click IDs), **`dclid`** (display), and since 2023 **`gad_source`** and **`gad_campaignid`**. None are read by the page you land on; they're attribution signals for Google Ads and GA4. All are safe to remove, and LinkClean strips the whole family by default. The one people ask about most — `gad_source` — is a numeric code for the ad surface (`=1` Search, `=2` Display, `=3` YouTube, `=5` Shopping), but Google publishes no official mapping, so higher values like `=7` aren't reliably documented.",
        sections: [
          {
            heading: "The family at a glance",
            paragraphs: [
              "A single Google ad click can land you on a URL with three or four of these stacked together — `?gclid=…&gad_source=1&gad_campaignid=…`. Each is added automatically by Google Ads' auto-tagging; you don't have to be the advertiser for them to appear. Here's the whole family:",
            ],
            table: {
              caption: "Google Ads auto-tagged URL parameters",
              headers: ["Parameter", "What it is", "Added since", "Read by"],
              rows: [
                ["gclid", "Google Click Identifier — the original; binds a click to its ad and conversion", "~2010s", "Google Ads + GA4"],
                ["gbraid", "Click ID for app→web journeys on iOS (the App Tracking Transparency era)", "2021", "Google Ads (aggregated)"],
                ["wbraid", "Click ID for web→web on iOS Safari (the Intelligent Tracking Prevention era)", "2021", "Google Ads (aggregated)"],
                ["dclid", "Display click ID — Display & Video 360 / Campaign Manager", "display stack", "Google's display tools"],
                ["gad_source", "Numeric code for which ad surface produced the click", "2023", "Google Ads + GA4"],
                ["gad_campaignid", "Numeric identifier for the campaign that drove the click", "2023", "Google Ads + GA4"],
                ["srsltid", "Shopping / Merchant Center product-listing token", "Shopping", "Merchant Center + GA4"],
              ],
            },
          },
          {
            heading: "gclid — the click ID everything else orbits",
            paragraphs: [
              "`gclid` (Google Click Identifier) is the oldest and most important member of the family. With auto-tagging on (the default for almost every Google Ads account), every paid click gets a unique `gclid` appended to the landing-page URL. Google Ads and GA4 read it back to credit the conversion: this exact click, from this ad, in this campaign, led to this purchase.",
              "Because it's per-click and unique, `gclid` is the most identifying parameter in the set — it ties your visit to a specific ad impression Google served you. It's also the hardest term to rank for and the one people most want gone. Full detail on its own page: [What is gclid?](/trackers/gclid/).",
            ],
          },
          {
            heading: "gbraid and wbraid — the privacy-era twins",
            paragraphs: [
              "When Apple's App Tracking Transparency (iOS 14.5, 2021) and Safari's Intelligent Tracking Prevention made the cookie-and-`gclid` plumbing unreliable on iPhones, Google introduced two replacements designed to measure conversions in aggregate rather than per person:",
            ],
            bullets: [
              "**`gbraid`** rides **app→web** journeys — you tap an ad inside an iOS app and land on a website.",
              "**`wbraid`** rides **web→web** journeys on iOS Safari — you click an ad on one page and land on another.",
            ],
          },
          {
            heading: "Why gbraid and wbraid are different from gclid",
            paragraphs: [
              "Both are engineered to be more privacy-preserving than `gclid` — they're meant to be joined in aggregate, not used to single you out — but they're still attribution tokens the destination page never reads, so LinkClean strips them too. Their own pages: [gbraid](/trackers/gbraid/) · [wbraid](/trackers/wbraid/).",
            ],
          },
          {
            heading: "gad_source — the source code Google won't explain",
            paragraphs: [
              "`gad_source` is the parameter people search for most in this family, because it shows up as a bare number — `gad_source=1`, `gad_source=2`, `gad_source=7` — with no obvious meaning. Google's own help page is blunt: the parameter \"is used to identify the source of ads URLs\" and \"isn't customizable,\" but Google **does not publish what the individual numbers mean**.",
              "Analysts have reverse-engineered the common values by correlating them with campaign types. The mapping below is community-observed and stable over time, but it is **not official** — treat it as a strong hint, not a guarantee:",
            ],
            table: {
              caption: "Community-observed gad_source values — reverse-engineered, not officially documented by Google",
              headers: ["Value", "Observed source"],
              rows: [
                ["gad_source=1", "Google Search ads"],
                ["gad_source=2", "Display Network"],
                ["gad_source=3", "YouTube"],
                ["gad_source=5", "Shopping"],
                ["gad_source=4, 6, 7, …", "Not reliably documented — no public consensus"],
              ],
            },
          },
          {
            heading: "So what does gad_source=7 mean?",
            paragraphs: [
              "If you landed here searching exactly that: the honest answer is that no one outside Google has confirmed it. The low values (1, 2, 3, 5) line up with Search, Display, YouTube and Shopping; everything above that is guesswork. Either way, the number is metadata for Google's analytics — the page you're visiting doesn't read it, and removing it changes nothing about what loads. Its own page: [What is gad_source?](/trackers/gad-source/).",
            ],
          },
          {
            heading: "gad_campaignid — the numeric campaign tag",
            paragraphs: [
              "`gad_campaignid` arrived in 2023 alongside `gad_source`. It's the numeric ID of the Google Ads campaign that produced the click — a machine-readable companion to the human-readable `utm_campaign` a marketer types. A single ad URL often carries all three campaign signals at once: `utm_campaign` for the GA4 dashboard, `gad_campaignid` for Google's first-party attribution, and `gclid` for the Ads conversion record. [What is gad_campaignid?](/trackers/gad-campaignid/)",
            ],
          },
          {
            heading: "Why Google needs so many",
            paragraphs: [
              "It looks redundant — why four or five tags for one click? The answer is the privacy transition. Universal Analytics leaned on third-party cookies and referrer headers to attribute traffic. Safari's ITP, Firefox's Total Cookie Protection and Chrome's Privacy Sandbox have eroded both. GA4's design moved the attribution signal **into the URL itself** as durable first-party tags — which is exactly why the `gad_*` family appeared in 2023 and why `gbraid`/`wbraid` appeared in 2021. They're the cookie's replacement, stapled to the link.",
              "For the difference between these click IDs and the `utm_*` tags marketers add by hand, see [Click IDs vs UTM tags](/learn/click-ids-vs-utm-tags/).",
            ],
          },
          {
            heading: "Are any of them safe to keep?",
            paragraphs: [
              "Functionally, none of them matter to you. Every parameter in this family is read by Google's ad and analytics systems, never by the destination server — strip them and the page loads byte-for-byte the same. (The general principle: [Do cleaned links still work?](/learn/do-cleaned-links-still-work/))",
              "The only party with a reason to keep them is the advertiser measuring their own campaign. If that's you, paste the link into LinkClean rather than cleaning blind — you'll see the original and cleaned versions side by side and can keep whichever you intend to share.",
            ],
          },
          {
            heading: "How LinkClean removes the whole family",
            paragraphs: [
              "All seven parameters ship in LinkClean's catalog as default-on, host-independent rules — there's no legitimate non-tracking use of `gclid`, `gad_source` and the rest, so they're stripped wherever they appear, on every surface (Share Sheet, widget, Shortcuts, the app, QR). A messy Google-ad URL like `https://shop.example.com/p?gad_source=1&gad_campaignid=12345678&gclid=Cj0KCQ&utm_campaign=spring` comes out as `https://shop.example.com/p`.",
              "Because these rules aren't host-scoped (unlike X's `t=`/`s=`, which only apply on `x.com`), you don't have to think about it — the family is gone the moment you clean.",
            ],
          },
        ],
        faq: [
          {
            q: "What does gad_source=7 mean?",
            a: "Google doesn't say. Its help documentation confirms gad_source identifies the ad source but never publishes the value mapping. Community observation has pinned the low values — 1 = Search, 2 = Display, 3 = YouTube, 5 = Shopping — but 7 (and 4, 6) have no public consensus. It's an internal source code either way; removing it changes nothing about the page.",
          },
          {
            q: "Is gad_source the same as gclid?",
            a: "No. gclid is a unique per-click token that identifies your specific click; gad_source is a small shared code for the type of ad surface (Search, Display, …). Many clicks share the same gad_source; every click has its own gclid. They travel together but do different jobs.",
          },
          {
            q: "Will removing these break the Google ad's destination?",
            a: "No. They're attribution metadata for Google Ads and GA4, not routing information. The destination URL works identically without them — the advertiser just loses the granular attribution for that one visit.",
          },
          {
            q: "I'm an advertiser — will cleaning my own links hurt my reporting?",
            a: "Only for links you clean and then share; your ads keep auto-tagging normally. If you specifically want to preserve a tagged link, paste it into LinkClean and copy the original side — cleaning is opt-in per link, never forced.",
          },
          {
            q: "Why did gbraid and wbraid suddenly appear on my iPhone?",
            a: "They're Google's answer to iOS privacy. After App Tracking Transparency (2021), Google could no longer rely on cookies and gclid to measure iPhone conversions, so it added gbraid (app→web) and wbraid (web→web) as aggregated, privacy-era click IDs. They only show up on iOS journeys.",
          },
        ],
        related: [
          {
            label: "What is gad_source?",
            href: "/trackers/gad-source/",
          },
          {
            label: "What is gclid?",
            href: "/trackers/gclid/",
          },
          {
            label: "Click IDs vs UTM tags — what's the difference?",
            href: "/learn/click-ids-vs-utm-tags/",
          },
          {
            label: "Do cleaned links still work?",
            href: "/learn/do-cleaned-links-still-work/",
          },
          {
            label: "What is gad_campaignid?",
            href: "/trackers/gad-campaignid/",
          },
        ],
      },
    },
  },
];
