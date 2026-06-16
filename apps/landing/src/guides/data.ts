import type { GuideArticle } from "./types";

/** Wave-1 how-to guides. Each authored as a Template-B HowTo: TL;DR, optional
 *  intro, ordered steps (each step gets rendered as an HowToStep in JSON-LD),
 *  optional outro, related links, App Store CTA. */
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
        ],
      },
    },
  },
];
