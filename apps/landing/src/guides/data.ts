import type { GuideArticle } from "./types";

/** How-to guides — Template-B HowTo: TL;DR, optional intro, ordered steps
 *  (rendered as HowToStep in JSON-LD), optional outro, related links, App Store CTA. */
export const GUIDES: ReadonlyArray<GuideArticle> = [
  // ── /guides/remove-utm-parameters ────────────────────────────
  {
    slug: "remove-utm-parameters",
    content: {
      en: {
        title: "How to remove UTM parameters from a link on iPhone",
        description:
          "Step-by-step: strip utm_source, utm_medium, utm_campaign and the rest of the utm_* family from a URL on iPhone — no extension, no editing.",
        tldr: "On iPhone, the fastest way to strip utm_* tags from a link is the LinkClean share-sheet action: tap Share → Clean URL, and the cleaned link is on your clipboard. Manual edit works in a pinch — delete everything from the ? onward and refresh to confirm the page still loads.",
        intro: [
          "UTM parameters (utm_source, utm_medium, utm_campaign, and a handful of newer cousins) are Google Analytics campaign tags. They tell whoever runs the destination's analytics where the click came from. Sharing them carries that attribution forward into other people's analytics dashboards — and there's no good reason for it to do that, because the page itself doesn't need the tags to load.",
          "Three ways to remove them, fastest to slowest:",
        ],
        steps: [
          {
            title: "Use the LinkClean share-sheet action",
            body: "On any link you'd share, tap Share. Scroll the actions row and pick Clean URL. The cleaned URL replaces the dirty one on your clipboard before the sheet closes — paste it wherever you were going. Works from any app, not just Safari.",
          },
          {
            title: "Or run Clean Clipboard from a widget",
            body: "Copy the link the usual way, then tap the LinkClean widget on your home screen (or the Control Center toggle). It cleans whatever's on your clipboard in place. Useful for batches.",
          },
          {
            title: "Or paste it into the app",
            body: "Open LinkClean, paste, and you'll see the cleaned link with a list of exactly what was stripped. This is the slowest of the three but the best when you want to *see* what was hidden — useful before sharing something sensitive.",
          },
          {
            title: "Manual fallback (if you don't have LinkClean yet)",
            body: "In Safari's address bar, tap to edit the URL, find the ?, and delete everything from there to the end. Refresh — if the same page loads, the tail was tracking; you're safe. If it doesn't, paste back from clipboard and you've lost nothing.",
          },
        ],
        outro: [
          "Why not just trim the URL manually every time? Two reasons: (1) the modern share-sheet flow makes the cleaning automatic, so you never have to think about it; (2) UTM tags travel with non-UTM tracker friends — fbclid, gclid, msclkid, mc_eid, and a long tail of others — that you'd have to recognize and pick out by hand. LinkClean knows the full catalog and strips them in one pass.",
        ],
        related: [
          {
            label: "What is utm_source, and why is it safe to remove?",
            href: "/trackers/utm-source/",
          },
          {
            label: "What is utm_medium?",
            href: "/trackers/utm-medium/",
          },
          {
            label: "Do cleaned links still work? (the conversion blocker, answered)",
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

  // ── /guides/clean-youtube-link ───────────────────────────────
  {
    slug: "clean-youtube-link",
    content: {
      en: {
        title: "How to clean a YouTube share link",
        description:
          "YouTube share links carry a si= tracking parameter. Strip it before forwarding, but keep t= so the video still starts at the timestamp you wanted.",
        tldr: "YouTube's share button adds ?si=<token> to track who shared the link. Strip si= but keep t= (the timestamp) — LinkClean does this automatically, host-scoped to youtube.com / youtu.be so it doesn't touch t= or si= on other sites.",
        intro: [
          "YouTube's share dialog gives you a link that looks like https://youtu.be/dQw4w9WgXcQ?si=AbCdEf12345 (or a longer youtube.com URL with the same si=). That si parameter is a “share identifier” YouTube uses to credit the share and link the click back to whoever pressed Share.",
          "If the video has a start-at-N-seconds timestamp, you'll also see &t=42 (or just ?t=42 on its own). Critically, t= is functional — strip it and the video starts from the beginning, which is usually not what you wanted.",
        ],
        steps: [
          {
            title: "Use the share sheet, not the YouTube share button",
            body: "From the YouTube app, copy the link normally (or use the system share-sheet → LinkClean's Clean URL action). LinkClean strips si= and leaves t= intact. The cleaned link starts at the same timestamp, with no share token attached.",
          },
          {
            title: "Or paste into the LinkClean app",
            body: "Paste the YouTube URL. You'll see si= called out as “stripped” and t= preserved. Copy the result back.",
          },
          {
            title: "Verify the timestamp survived",
            body: "Open the cleaned link in a private tab. If you had a timestamp, the video should jump there. If it didn't, you can tell at a glance — and if it's wrong, the original is one undo away.",
          },
          {
            title: "Why this is harder than it sounds",
            body: "A naive cleaner that strips every parameter would also strip t= and break the timestamp. LinkClean's catalog scopes the YouTube cleaning rules to youtube.com / youtu.be hosts, so a parameter called si= on a different site (where it might be functional) is left alone, and t= is preserved everywhere.",
          },
        ],
        outro: [
          "If you've used a URL shortener to share a YouTube video and the shortener added its own parameters, paste the short link into LinkClean. It'll expand and clean in one step (E1 redirect unwrapping — short-link domains like t.co and bit.ly are followed locally, then the destination URL gets the same treatment).",
        ],
        related: [
          {
            label: "What is fbclid, and what does it leak?",
            href: "/trackers/fbclid/",
          },
          {
            label: "What's hidden in a share link?",
            href: "/learn/whats-hidden-in-a-share-link/",
          },
          {
            label: "How to remove UTM parameters from a link",
            href: "/guides/remove-utm-parameters/",
          },
          {
            label: "How to clean an X (Twitter) share link",
            href: "/guides/clean-x-twitter-link/",
          },
        ],
      },
    },
  },

  // ── /guides/clean-amazon-link ────────────────────────────────
  {
    slug: "clean-amazon-link",
    content: {
      en: {
        title: "How to clean an Amazon product link",
        description:
          "Amazon product URLs carry tag=, ref_, and pf_rd_* affiliate/tracking parameters. Strip them and keep the clean /dp/<ASIN> form — LinkClean does this with host-scoped rules.",
        tldr: "Amazon product URLs get bloated with tag= (affiliate ID), ref_ (referrer breadcrumb), and pf_rd_* (placement/recommendation tracking). The product is just /dp/<ASIN> — everything after is metadata. LinkClean's catalog is host-scoped to amazon.* TLDs so the same parameter names elsewhere are untouched.",
        intro: [
          "Amazon's URLs are some of the longest on the web because their internal tracking is unusually verbose. tag= identifies an affiliate (someone earns a commission when you buy), ref_ records which page sent you (the search results, a category page, a recommendation widget), and pf_rd_* annotates the specific placement (which slot on which page in which experiment cohort).",
          "None of this is needed to load the product. The canonical product URL is just `amazon.com/dp/<ASIN>` — that ASIN (Amazon Standard Identification Number) is the only thing the server uses to identify the product.",
        ],
        steps: [
          {
            title: "Copy the product link normally",
            body: "From the Amazon app or web, hit Share → Copy Link. You'll get a long URL with /ref=… in the path and ?tag=…&ref_=… in the query string.",
          },
          {
            title: "Run it through LinkClean",
            body: "Either use the LinkClean share-sheet action (Share → Clean URL) or paste into the app. LinkClean strips tag, ref_, pf_rd_*, and the Amazon-specific tail, leaving just the /dp/<ASIN> form (and sometimes the storefront language indicator, which is functional).",
          },
          {
            title: "Verify the product still resolves",
            body: "Open the cleaned link in a private tab. Same product page, no affiliate kicker. The price, reviews, and product details all load identically.",
          },
        ],
        outro: [
          "Why host-scoped? Because tag and ref are common functional query keys on other sites (a tag= filter on a blog's archive page, a ref= referer parameter on a forum). LinkClean's catalog limits the aggressive Amazon-cleaning rules to amazon.* hosts (`.com`, `.co.uk`, `.de`, `.co.jp`, and 14 other storefronts) — on any other site, tag= and ref= stay default-off.",
          "If you keep an affiliate link on purpose (you want to support someone's referral), use LinkClean's app to see the cleaned vs original side-by-side and pick whichever you want before sharing.",
        ],
        related: [
          {
            label: "Do cleaned links still work?",
            href: "/learn/do-cleaned-links-still-work/",
          },
          {
            label: "What's hidden in a share link?",
            href: "/learn/whats-hidden-in-a-share-link/",
          },
          {
            label: "How to clean a YouTube share link",
            href: "/guides/clean-youtube-link/",
          },
        ],
      },
    },
  },

  // ── /guides/clean-x-twitter-link ─────────────────────────────
  {
    slug: "clean-x-twitter-link",
    content: {
      en: {
        title: "How to clean an X (Twitter) share link",
        description:
          "X/Twitter share links carry t= and s= share-identifier tokens that tie the click back to your account. Strip them before forwarding — LinkClean does it host-scoped to x.com / twitter.com.",
        tldr: "X (formerly Twitter) adds ?t=<token>&s=<n> to outbound share links. Both identify the sharing session. Strip them before forwarding — LinkClean does this host-scoped to x.com and twitter.com, so t= on YouTube (the timestamp) stays intact.",
        intro: [
          "When you hit Share on a tweet, X gives you a URL like https://x.com/handle/status/1234567890?t=AbCdEf-12345_xyz&s=20. The t= and s= parameters are X's share-identifier tokens: t encodes the sharing session, s encodes which surface the share came from (the iOS app, the web client, a third-party tool).",
          "Critically, t= is a tracker here but it's the timestamp parameter on YouTube. That's the kind of name collision that breaks naive cleaners — strip t= everywhere and YouTube share links lose their start-at-N-seconds behavior. LinkClean handles this by host-scoping the t/s rules to x.com / twitter.com only.",
        ],
        steps: [
          {
            title: "Use the LinkClean share-sheet action",
            body: "From the X app, hit Share → choose Clean URL. The cleaned tweet URL — just the /handle/status/<id> form, no t/s tail — is on your clipboard.",
          },
          {
            title: "Or paste into the app to see what was stripped",
            body: "Open LinkClean, paste the X share link. You'll see t and s called out, both stripped. The tweet ID and handle are preserved (they're part of the path, not the query string).",
          },
          {
            title: "Confirm the tweet still loads",
            body: "Open the cleaned URL in a private tab. Same tweet, same thread, no share token tying the view back to you.",
          },
        ],
        outro: [
          "X also occasionally adds &cn= and &refsrc= on outbound clicks — both go through the same default-on stripping path. The cleaned URL is the canonical tweet permalink, identical to what you'd get by typing the URL yourself.",
        ],
        related: [
          {
            label: "What t= and s= mean in an X share URL (deep dive, with s=46 explained)",
            href: "/learn/x-twitter-share-url-explained/",
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
            label: "How to clean a YouTube share link",
            href: "/guides/clean-youtube-link/",
          },
        ],
      },
    },
  },

  // ── /guides/clean-instagram-link ─────────────────────────────
  {
    slug: "clean-instagram-link",
    content: {
      en: {
        title: "How to clean an Instagram share link",
        description:
          "Instagram share links carry an igshid= attribution token and often a utm_source=ig_web_copy_link tail. Strip them before forwarding — LinkClean does it in one tap.",
        tldr: "Instagram appends ?igshid=<token> to every link copied from its app — it identifies the sharing session back to Meta. Strip igshid before forwarding. LinkClean does this by default, and also strips the companion utm_source=ig_web_copy_link tail Instagram's web client adds.",
        intro: [
          "When you tap Share → Copy Link from Instagram — a Reel, a Story, a profile, even an external link from a bio — Meta appends ?igshid=<token> to the URL. The token ties the click back to your Instagram session for Meta's first-party analytics.",
          "Often igshid travels with utm_source=ig_web_copy_link or a similar attribution UTM. Both are tracking; both safely strippable.",
        ],
        steps: [
          {
            title: "Use the LinkClean share-sheet action",
            body: "From the Instagram app — or anywhere — tap Share, scroll the actions row, and pick Clean URL. The cleaned link replaces the original on your clipboard. The destination is identical; the attribution token is gone.",
          },
          {
            title: "Or paste into the app to see what was stripped",
            body: "Open LinkClean, paste the Instagram link. The display shows igshid called out as “stripped” and any utm_* tail next to it. Copy the cleaned form.",
          },
          {
            title: "Or run Clean Clipboard from the widget",
            body: "Copy the link the usual way, then tap LinkClean's home-screen widget (or the Control Center toggle). The cleaned link replaces what's on your clipboard.",
          },
          {
            title: "Confirm the post still loads",
            body: "Open the cleaned link in a private tab. Same Reel, same Story, same profile — Instagram routes purely on the path (`/p/<shortcode>/`, `/reel/<shortcode>/`, `/<handle>/`). The query string was Meta's bookkeeping.",
          },
        ],
        outro: [
          "Why this matters more than the utm_*: igshid carries the *sharing-session identity* back to your Instagram account; utm_* carries channel attribution. Strip both, but if you only knew one, igshid is the one to know — every Instagram share you forward broadcasts who you are.",
        ],
        related: [
          {
            label: "What is igshid?",
            href: "/trackers/igshid/",
          },
          {
            label: "What is mibextid (Facebook's mobile-share token)?",
            href: "/trackers/mibextid/",
          },
          {
            label: "What's hidden in a share link?",
            href: "/learn/whats-hidden-in-a-share-link/",
          },
          {
            label: "How to clean a YouTube share link",
            href: "/guides/clean-youtube-link/",
          },
        ],
      },
    },
  },

  // ── /guides/clean-tiktok-link ────────────────────────────────
  {
    slug: "clean-tiktok-link",
    content: {
      en: {
        title: "How to clean a TikTok share link",
        description:
          "TikTok share links carry tt_medium, _r, _t, and (from ads) ttclid + _ttp, plus utm_*. Strip them before forwarding — LinkClean does it in one tap.",
        tldr: "TikTok's Share → Copy Link adds a tail of tt_*, _r, _t, ttclid (on links from ads), and utm_* — all attribution. Strip them. The cleaned path (vm.tiktok.com/<id>/ or tiktok.com/@user/video/<id>) is the canonical form.",
        intro: [
          "TikTok's share dialog gives you links that look like https://vm.tiktok.com/ZMabc123/?_r=1&_t=AbC&tt_medium=ios_native or https://www.tiktok.com/@creator/video/7100000000000000000?_r=1&_t=… with a long tail of tracking. Some of it is share-session attribution (tt_*, _t, _r); some is the canonical TikTok Ads tail (ttclid + _ttp); some is utm_*.",
          "None of it routes the destination. The canonical path is the video / profile URL; everything after the ? is metadata.",
        ],
        steps: [
          {
            title: "Use the LinkClean share-sheet action",
            body: "From the TikTok app, tap Share → Clean URL. The cleaned link is on your clipboard. Same video, no share token.",
          },
          {
            title: "Or paste into the app to audit what was stripped",
            body: "Open LinkClean, paste the TikTok URL. You'll see tt_medium, _r, _t (and ttclid if present) listed as stripped. The path is preserved.",
          },
          {
            title: "If the link is a vm.tiktok.com short link",
            body: "LinkClean's E1 redirect-unwrapping resolves vm.tiktok.com locally to the full tiktok.com/@user/video/<id> form, then cleans the destination. One step, no third-party fetch.",
          },
          {
            title: "Confirm the video still plays",
            body: "Open the cleaned URL in a private tab. Same video, same creator. TikTok routes purely on the video ID.",
          },
        ],
        outro: [
          "The TikTok parameters worth recognizing: ttclid is the ad-click identifier (only on outbound TikTok Ads, paired with _ttp); tt_medium / _r / _t are the share-session triplet (on every organic share). LinkClean strips all four by default.",
        ],
        related: [
          {
            label: "What is ttclid?",
            href: "/trackers/ttclid/",
          },
          {
            label: "How to clean an X (Twitter) share link",
            href: "/guides/clean-x-twitter-link/",
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

  // ── /guides/clean-markdown-link ──────────────────────────────
  {
    slug: "clean-markdown-link",
    content: {
      en: {
        title: "How to save a clean Markdown link in Obsidian or Notion (iPhone)",
        description:
          "Save web links into Obsidian, Notion, Bear or Logseq as clean `[Title](URL)` Markdown — with the trackers stripped first — in one tap from the iPhone share sheet.",
        tldr: "When you clip a web link into a notes app, the share link usually drags trackers (`utm_*`, `si`, `fbclid`) straight into your permanent notes — and pastes as a naked URL with no title. LinkClean's **Copy link as… → Markdown** action cleans the link *and* formats it as `[Page Title](clean-url)` in one tap, so what lands in Obsidian or Notion is tidy and tracker-free.",
        intro: [
          "Personal-knowledge-management apps — Obsidian, Notion, Bear, Logseq, Craft — keep links forever. That makes them the worst place for a dirty link: a tracker you'd shrug off in a group chat becomes a permanent record in your notes, and it travels every time you re-share or publish that note.",
          "Raw links also look bad in Markdown. A YouTube or news share link dropped into a note renders as a long naked URL with a `?si=…` or `?utm_source=…` tail — no title, no context. The fix is to clean the link and wrap it in Markdown (`[Title](URL)`) at the same time. Here's the one-tap way on iPhone, plus the manual fallback.",
        ],
        steps: [
          {
            title: "Copy the link as clean Markdown from the share sheet",
            body: "On any page or link, tap Share → \"Copy link as…\" and pick Markdown (it's a free format). LinkClean strips the trackers, then formats the result as `[Page Title](https://clean-url)`. Switch to Obsidian or Notion and paste — you get a titled, tracker-free Markdown link, not a naked URL.",
          },
          {
            title: "Paste straight into your note",
            body: "In Obsidian, paste where you want the link — it renders the clickable title immediately because it's already Markdown. In Notion, pasting `[Title](URL)` converts to Notion's own link inline. No editing, no typing the title by hand.",
          },
          {
            title: "Prefer your own format? Make a template (Pro)",
            body: "If you want something other than `[Title](URL)` — a callout, a quote block, or `- [ ] Title — URL` for a task — LinkClean Pro's Copy Formats editor lets you define the template once. The cleaned link and the page title slot into your format every time.",
          },
          {
            title: "Manual fallback (without LinkClean)",
            body: "Clean the link first (delete everything from the `?` onward, refresh to confirm the page still loads), then in your note type `[`, paste the title, `](`, paste the URL, `)`. It works — but it's four fiddly steps per link, and you have to recognize the trackers yourself.",
          },
        ],
        outro: [
          "Two things make the one-tap flow worth it for note-taking specifically. First, the title: LinkClean fetches the real page title, so you don't paste a naked URL or type the title by hand. Second, the catalog: a link you clip might carry utm_*, fbclid, si, mc_eid or any of dozens of trackers — LinkClean knows the whole set and strips them in one pass, so your vault stays clean without you auditing each link.",
          "If you clip a lot from shortened links (t.co, bit.ly), turn on Short-Link Expansion in Settings — LinkClean follows the short link to the real page, then cleans and formats that, so you never archive a shortener that could rot or redirect later.",
        ],
        related: [
          {
            label: "What's hidden in a share link?",
            href: "/learn/whats-hidden-in-a-share-link/",
          },
          {
            label: "What is utm_source, and why is it safe to remove?",
            href: "/trackers/utm-source/",
          },
          {
            label: "How to remove UTM parameters from a link",
            href: "/guides/remove-utm-parameters/",
          },
          {
            label: "Do cleaned links still work?",
            href: "/learn/do-cleaned-links-still-work/",
          },
        ],
      },
    },
  },
];
