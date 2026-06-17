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
  /** Example dirty-URL section label (used on tracker spokes). */
  exampleDirtyLabel: string;
  /** Example clean-URL section label (used on tracker spokes). */
  exampleCleanLabel: string;
  /** Example label on a functional-parameter spoke (replaces "Looks like this"). */
  exampleFunctionalLabel: string;
  /** Caption rendered next to the example on a functional-parameter spoke
   *  (where there's no dirty→clean transformation to show). */
  preservedNote: string;
  /** Inline tag rendered next to the param name on a functional spoke. */
  functionalTag: string;
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
  hubTitle: "URL parameters glossary",
  hubIntro:
    "Every tracking parameter LinkClean strips by default — plus a few functional ones (like hl) everyone wonders about. One-line summary per entry; tap for the long version.",
  hubMeta:
    "Glossary of every tracking parameter LinkClean strips by default — utm_source, fbclid, gclid, mc_eid, and more — plus functional URL parameters like hl that everyone asks about.",
  trackersLabel: "Glossary",
  spokeTitleSuffix: " — what it does, in one line",
  tldrLabel: "TL;DR",
  exampleDirtyLabel: "Looks like this in a URL",
  exampleCleanLabel: "After LinkClean",
  exampleFunctionalLabel: "Example URL",
  preservedNote: "LinkClean preserves this parameter — no change.",
  functionalTag: "functional — preserved",
  faqHeading: "Frequently asked",
  relatedHeading: "Related",
  ctaHeading: "Clean tracking on iPhone, in one tap.",
  ctaBody:
    "LinkClean strips ~80 vendor-specific tracking parameters from any link, from any app's share sheet — and preserves functional ones like hl, t (YouTube timestamp), and q (search). No account, on-device.",
  kindLabel: {
    utm: "UTM campaign tags",
    referral: "Referral & source",
    ads: "Ad-click identifiers",
    analytics: "Analytics IDs",
    email: "Email marketing",
    social: "Social",
    affiliate: "Affiliate",
    session: "Session & misc",
    regional: "Region & language (preserved)",
  },
};

const CHROME: Record<Locale, TrackersChrome> = { en };

export function trackersChrome(locale: Locale): TrackersChrome {
  return CHROME[locale];
}
