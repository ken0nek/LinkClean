import type { Locale } from "../i18n/locales";

/** Category — mirrors the iOS `TrackingParameterKind.id` values
 *  (LinkCleanCore/TrackingParameters.swift): "utm", "referral", "ads",
 *  "analytics", "email", "social", "affiliate". Keep these IDs in sync. */
export type TrackerKind =
  | "utm"
  | "referral"
  | "ads"
  | "analytics"
  | "email"
  | "social"
  | "affiliate"
  | "session";

export interface TrackerSection {
  heading: string;
  /** Lines rendered as <p> blocks. */
  paragraphs: ReadonlyArray<string>;
}

export interface TrackerFaq {
  q: string;
  a: string;
}

/** One tracker's spoke page (e.g. `/trackers/utm-source/`). */
export interface TrackerContent {
  /** Pre-page <title>; fallback is built from `param` and the locale chrome. */
  title?: string;
  /** <meta description>. */
  description: string;
  /** TL;DR — one or two sentences, rendered in the bolded callout. */
  tldr: string;
  /** Long-form sections — Template A: "What it does" / "What it leaks" /
   *  "How LinkClean removes it" / "Why it's safe to strip" / etc. */
  sections: ReadonlyArray<TrackerSection>;
  /** Example URL with the tracker — rendered verbatim in a mono block. */
  exampleDirty: string;
  /** Same URL after LinkClean strips. */
  exampleClean: string;
  /** Drives <FAQPage> JSON-LD + on-page Q&A items. */
  faq: ReadonlyArray<TrackerFaq>;
}

export interface TrackerSpoke {
  /** URL slug under `/trackers/`. */
  slug: string;
  /** The literal parameter name as it appears in URLs (e.g. "utm_source"). */
  param: string;
  /** Category for hub grouping — matches `TrackingParameterKind.id` on iOS. */
  kind: TrackerKind;
  /** Vendor / origin (e.g. "Google Analytics", "Meta", "Google Ads"). */
  vendor: string;
  /** Per-locale content. A locale absent here gets no page in that locale. */
  content: Partial<Record<Locale, TrackerContent>>;
  /** Other tracker slugs to surface as "related" — hand-curated. */
  related?: ReadonlyArray<string>;
}
