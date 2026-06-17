import type { Locale } from "../i18n/locales";

/** Category — mirrors the iOS `TrackingParameterKind.id` values
 *  (LinkCleanCore/TrackingParameters.swift): "utm", "referral", "ads",
 *  "analytics", "email", "social", "affiliate". Keep these IDs in sync.
 *  `"regional"` is a glossary-only category for functional language/region
 *  parameters (hl, gl, lang) — the iOS catalog never strips these, but the
 *  glossary documents them because users ask about them. */
export type TrackerKind =
  | "utm"
  | "referral"
  | "ads"
  | "analytics"
  | "email"
  | "social"
  | "affiliate"
  | "session"
  | "regional";

/** Whether the parameter is something LinkClean strips ("tracker") or something
 *  the glossary documents because users ask, but LinkClean preserves
 *  ("functional"). Default is "tracker"; set "functional" on hl, gl, etc. */
export type ParameterNature = "tracker" | "functional";

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
  /** Tracker (LinkClean strips) vs functional (LinkClean preserves). Defaults
   *  to "tracker"; set to "functional" for params like hl that users ask about
   *  but LinkClean never removes. Drives the spoke template (the example block
   *  swaps "before / after" labels for "example URL / preserved unchanged"). */
  nature?: ParameterNature;
  /** Vendor / origin (e.g. "Google Analytics", "Meta", "Google Ads"). */
  vendor: string;
  /** Per-locale content. A locale absent here gets no page in that locale. */
  content: Partial<Record<Locale, TrackerContent>>;
  /** Other tracker slugs to surface as "related" — hand-curated. */
  related?: ReadonlyArray<string>;
}
