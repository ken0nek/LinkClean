import { APP_STORE_ID } from "../brand";
import type { Copy } from "./types";

export const en: Copy = {
  meta: {
    title: "LinkClean — strip tracking parameters before you share",
    description:
      "Strip tracking parameters (utm_*, fbclid, gclid…) from links on iPhone — share sheet, app, Shortcuts, widget. On-device, no account.",
  },
  schema: {
    alternateName: "LinkClean — Tracker-free links",
    description:
      "LinkClean strips tracking parameters (utm_*, fbclid, gclid, and many more) from URLs before you share them. Works in the iOS share sheet, the app, Shortcuts, a home-screen widget, and via QR scan. Free to clean; LinkClean Pro unlocks custom Copy Formats and unlimited custom parameters.",
    featureList: [
      "Strips utm_*, fbclid, gclid, and 80+ more tracking parameters",
      "Works from any app's share sheet, not just browsers",
      "Shortcuts and Control Center integration",
      "Home-screen widget that cleans the clipboard with one tap",
      "Scan a QR to clean its link, or generate a QR from a cleaned link",
      "Copy as plain link, Markdown, or your own custom format (Pro)",
      "No account, no server — cleaning runs entirely on device",
    ],
  },
  appStoreBadge: {
    file: "/app-store-badge-en.svg",
    alt: "Download on the App Store",
    width: 120,
    height: 40,
  },
  appStoreCampaign: `https://apps.apple.com/app/apple-store/id${APP_STORE_ID}?pt=10674868&ct=landing&mt=8`,
  hero: {
    h1: "Share clean links.",
    lede: "LinkClean strips tracking parameters from any URL before you share it — on iPhone, in the share sheet, and from Shortcuts.",
    sub: "When you share a link from your phone, hidden tracking parameters usually ride along: utm_source, fbclid, gclid, and many more. They leak what you clicked, what you bought, who sent it. LinkClean removes them — locally, on your device, with no account.",
  },
  demo: {
    h2: "What it does, in one tap.",
    intro:
      "Paste a link from anywhere. LinkClean shows what's tracking, strips it, and hands back a clean URL ready to share.",
    dirtyLabel: "Dirty link",
    dirtyUrl:
      "https://example.com/article?utm_source=newsletter&utm_medium=email&utm_campaign=spring&fbclid=IwAR1AbCdEf",
    cleanLabel: "Clean link",
    cleanUrl: "https://example.com/article",
    strippedLabel: "What was stripped",
    strippedNote:
      "utm_source, utm_medium, utm_campaign (Google Analytics campaign tags) and fbclid (Meta's click identifier).",
  },
  benefits: {
    h2: "Three things make it work.",
    items: [
      {
        num: "01",
        title: "Anywhere you share",
        body: "Not a browser extension — LinkClean cleans whatever passes through your share sheet, clipboard, or QR. Native apps, messengers, anywhere.",
      },
      {
        num: "02",
        title: "Privacy-first by design",
        body: "Cleaning runs on-device. No account, no sign-up, no email. Your links never reach a server — there isn't one.",
      },
      {
        num: "03",
        title: "Catalog you can trust",
        body: "A curated list of vendor-specific parameters (utm_*, fbclid, gclid…), host-scoped so a tracker on one site doesn't break a functional key on another.",
      },
    ],
  },
  comparison: {
    h2: "How LinkClean differs from a browser extension.",
    linkcleanHeader: "LinkClean",
    otherHeader: "Browser extension",
    rows: [
      {
        feature: "Where it cleans",
        linkclean: "Anywhere on iPhone — share sheet, clipboard, QR, widget.",
        other: "Only links that pass through the browser tab.",
      },
      {
        feature: "Native apps",
        linkclean: "Cleans links from any native app (Messages, Mail, Slack, etc.).",
        other: "Can't see traffic outside the browser.",
      },
      {
        feature: "Account",
        linkclean: "None. Nothing to sign in to.",
        other: "Some extensions sync via account.",
      },
      {
        feature: "Where it runs",
        linkclean: "On-device. The URL never leaves your phone.",
        other: "On-device too — but the rule list often updates from a server.",
      },
      {
        feature: "Surfaces",
        linkclean:
          "Main app, share extension, Shortcuts, Control Center, home-screen widget, QR scan.",
        other: "Address bar / right-click menu.",
      },
    ],
  },
  surfaces: {
    h2: "Where cleaning happens.",
    items: [
      {
        title: "The app",
        body: "Paste a link, see what was stripped, copy or share the clean version.",
      },
      {
        title: "Share extension (Clean URL)",
        body: "Tap the share sheet from any app and pick Clean URL — the cleaned link is on your clipboard before the sheet closes.",
      },
      {
        title: "Shortcuts (App Intents)",
        body: "Clean Link and Clean Clipboard intents drop into any Shortcut or automation.",
      },
      {
        title: "Widget + Control Center",
        body: "One-tap “clean the clipboard” from the home screen or Control Center.",
      },
      {
        title: "QR scan + generate",
        body: "Scan a QR to clean its link, or generate a QR from a cleaned link.",
      },
    ],
  },
  trackersCta: {
    h2: "What's in a tracking link?",
    body: "Each parameter has a story: who put it there, what it leaks, why it's safe to remove. We keep a glossary of every parameter LinkClean strips by default — start with utm_source, fbclid, gclid.",
    linkLabel: "Browse the trackers glossary",
  },
  faqSection: {
    h2: "Frequently asked.",
  },
  faq: [
    {
      q: "Do cleaned links still work?",
      a: "Yes. Tracking parameters are added by analytics, ads, and email tools — the page itself doesn't need them to load. Stripping them takes you to the same article, video, or product page, just without the tail of trackers.",
    },
    {
      q: "What does LinkClean actually remove?",
      a: "By default: Google Analytics UTM tags (utm_source, utm_medium, utm_campaign, …), Meta's fbclid, Google Ads' gclid / gbraid / wbraid, Microsoft's msclkid, TikTok's ttclid, Yandex's yclid, and many more — about 80 vendor-specific parameters in the default catalog. Generic names that double as functional keys (like ref or source) are off by default; you can turn them on per site.",
    },
    {
      q: "Is this a browser extension?",
      a: "No. LinkClean is a native iOS app, so it cleans links from any app, not just the browser — Messages, Mail, Slack, X, Reddit, whatever you're sharing from. There's nothing to install in Safari.",
    },
    {
      q: "Where does my data go?",
      a: "Nowhere. Cleaning runs on your device. No account, no sign-up, no email. The catalog of trackers ships inside the app; we don't fetch rules from a server.",
    },
    {
      q: "Is it free?",
      a: "Yes. Cleaning is free and always will be. LinkClean Pro is a one-time in-app purchase that unlocks custom Copy Formats (e.g. Markdown, your own template) and unlimited custom tracking parameters.",
    },
    {
      q: "What languages does the app ship in?",
      a: "English, Japanese, and German. The marketing site launches in English; Japanese and German follow once Wave-1 content is live.",
    },
  ],
  footer: {
    tagline: "Privacy-first URL cleaning for iOS.",
    bylinePrefix: "Built by",
    privacyLabel: "Privacy",
    termsLabel: "Terms",
    lastUpdatedPrefix: "Updated",
  },
  localePicker: {
    ariaLabel: "Language",
  },
};
