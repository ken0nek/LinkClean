import type { Locale } from "../i18n/locales";
import type { TrackerKind } from "./types";

/** Per-locale UI strings for the trackers cluster (hub + spoke pages). The
 *  homepage `Copy` covers the global chrome (header, footer); the strings here
 *  are spoke-specific (TL;DR label, "What it looks like in a URL", FAQ, etc.). */
export interface TrackersChrome {
  /** /trackers/ hub title — used in <title> and <h1>. */
  hubTitle: string;
  /** /trackers/ hub intro line. */
  hubIntro: string;
  /** <meta description> for the hub. */
  hubMeta: string;
  /** Breadcrumb root ("Trackers"). */
  trackersLabel: string;
  /** Spoke <title> suffix wrapping the param name (when no authored title). */
  spokeTitleSuffix: string;
  /** TL;DR callout label above the bolded summary. */
  tldrLabel: string;
  /** Example dirty-URL section label. */
  exampleDirtyLabel: string;
  /** Example clean-URL section label. */
  exampleCleanLabel: string;
  /** Heading above the FAQ. */
  faqHeading: string;
  /** Heading above the "Related trackers" list. */
  relatedHeading: string;
  /** Heading above the spoke CTA section. */
  ctaHeading: string;
  /** Body line above the App Store badge on a spoke page. */
  ctaBody: string;
  /** Display label per kind, in hub grouping order. */
  kindLabel: Record<TrackerKind, string>;
}

const en: TrackersChrome = {
  hubTitle: "Tracking parameters glossary",
  hubIntro:
    "Every parameter LinkClean strips by default, with a one-line summary of what it leaks and where it came from. Tap one for the longer explanation.",
  hubMeta:
    "Glossary of every tracking parameter LinkClean strips by default — utm_source, fbclid, gclid, and 80+ more — grouped by category with a one-line summary.",
  trackersLabel: "Trackers",
  spokeTitleSuffix: " — what it leaks and how to remove it",
  tldrLabel: "TL;DR",
  exampleDirtyLabel: "Looks like this in a URL",
  exampleCleanLabel: "After LinkClean",
  faqHeading: "Frequently asked",
  relatedHeading: "Related trackers",
  ctaHeading: "Clean it on iPhone, in one tap.",
  ctaBody:
    "LinkClean strips this parameter — and 80+ others — from any link, from any app's share sheet. No account, on-device.",
  kindLabel: {
    utm: "UTM campaign tags",
    referral: "Referral & source",
    ads: "Ad-click identifiers",
    analytics: "Analytics IDs",
    email: "Email marketing",
    social: "Social",
    affiliate: "Affiliate",
    session: "Session & misc",
  },
};

const CHROME: Record<Locale, TrackersChrome> = { en };

export function trackersChrome(locale: Locale): TrackersChrome {
  return CHROME[locale];
}
