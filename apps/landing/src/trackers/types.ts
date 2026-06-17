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

/** Rough search-demand signal for curation. "high" = "what is X" queries get
 *  thousands/month (utm_source, fbclid, gclid); "medium" = solid demand
 *  (msclkid, gbraid, mkt_tok); "low" = niche but worth covering for completeness
 *  (epik, spm). Drives the hub sort order within a kind and surfaces
 *  highest-demand entries first. */
export type SearchDemand = "high" | "medium" | "low";

/** Structured vendor metadata. Replaces the freeform `vendor: string` so the
 *  page chrome ("Google Ads · 2018") and JSON-LD can render coherently. */
export interface VendorInfo {
  /** Display name, e.g. "Google Ads" or "Meta (Facebook)". */
  name: string;
  /** Year the parameter was introduced (best estimate). */
  year?: number;
  /** Short context phrase, e.g. "iOS app-install attribution" or "B2B email". */
  platform?: string;
  /** Slug of the parameter this one replaces or supersedes (e.g. gbraid replaces gclid for iOS). */
  replacedBy?: string;
  /** Vendor-family label for hub sub-grouping ("Google", "Meta", "Microsoft", "TikTok", "Yandex", "HubSpot", …). */
  family?: string;
}

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
  /** Pre-page <title>; fallback is built from `param` and the locale chrome.
   *  Prefer the explainer voice ("utm_source — what it leaks and how to strip
   *  it"). Use `searchTitle` for the "what is X"-shaped variant. */
  title?: string;
  /** Search-intent title — the question pattern that matches how the param is
   *  actually Googled ("What is utm_source?"). Renders as a secondary H2
   *  inside the page and feeds the SoftwareApplication JSON-LD's name. */
  searchTitle?: string;
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
  /** Rough search-demand bucket — drives the hub sort order so highest-demand
   *  entries appear first within a kind. Defaults to "medium". */
  searchDemand?: SearchDemand;
  /** Structured vendor metadata. Backward-compatible with the old freeform
   *  `vendor: string` via the helper `vendorName()` in select.ts. */
  vendor: string | VendorInfo;
  /** Per-locale content. A locale absent here gets no page in that locale. */
  content: Partial<Record<Locale, TrackerContent>>;
  /** Other tracker slugs to surface as "related" — hand-curated. */
  related?: ReadonlyArray<string>;
}
