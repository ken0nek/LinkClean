import { LOCALE_LIST, type Locale, type LocaleConfig } from "../i18n/locales";
import { TRACKERS } from "./data";
import type {
  SearchDemand,
  TrackerKind,
  TrackerSpoke,
  VendorInfo,
} from "./types";

/** Rendering helper — accepts both the old freeform string form and the new
 *  VendorInfo struct, returns a display string for the sub-line under the H1. */
export function vendorName(v: TrackerSpoke["vendor"]): string {
  if (typeof v === "string") return v;
  return v.name;
}

/** VendorInfo with all fields, or null for legacy string vendors. */
export function vendorInfo(v: TrackerSpoke["vendor"]): VendorInfo | null {
  if (typeof v === "string") return null;
  return v;
}

/** Vendor-family label for hub sub-grouping. Legacy string vendors fall back
 *  to "Other" so the renderer doesn't crash on mixed-format spokes. */
export function vendorFamily(v: TrackerSpoke["vendor"]): string {
  if (typeof v === "string") return v;
  return v.family ?? v.name;
}

/** Sort key for SearchDemand within a kind. Higher demand wins. */
const DEMAND_ORDER: Record<SearchDemand, number> = {
  high: 0,
  medium: 1,
  low: 2,
};
export function demandSort(a: TrackerSpoke, b: TrackerSpoke): number {
  const da = DEMAND_ORDER[a.searchDemand ?? "medium"];
  const db = DEMAND_ORDER[b.searchDemand ?? "medium"];
  return da - db;
}

/** Sort order for hub grouping. Mirrors the iOS catalog's `sortOrder` for the
 *  tracker kinds; "regional" (functional, glossary-only) sorts last so the
 *  preserved-parameter section sits below the stripped-parameter sections. */
export const KIND_ORDER: ReadonlyArray<TrackerKind> = [
  "utm",
  "referral",
  "ads",
  "analytics",
  "email",
  "social",
  "affiliate",
  "session",
  "regional",
];

export function localesForSpoke(
  spoke: TrackerSpoke,
): ReadonlyArray<LocaleConfig> {
  return LOCALE_LIST.filter((l) => spoke.content[l.locale]);
}

export function spokesForLocale(locale: Locale): ReadonlyArray<TrackerSpoke> {
  return TRACKERS.filter((s) => s.content[locale]);
}

/** Spokes grouped by kind, in hub display order. Empty kinds are omitted. */
export interface KindGroup {
  kind: TrackerKind;
  spokes: ReadonlyArray<TrackerSpoke>;
}

export function spokesByKind(locale: Locale): ReadonlyArray<KindGroup> {
  const byKind = new Map<TrackerKind, TrackerSpoke[]>();
  for (const spoke of spokesForLocale(locale)) {
    const bucket = byKind.get(spoke.kind) ?? [];
    bucket.push(spoke);
    byKind.set(spoke.kind, bucket);
  }
  const groups: KindGroup[] = [];
  for (const kind of KIND_ORDER) {
    const spokes = byKind.get(kind);
    if (spokes && spokes.length > 0) {
      // Sort by search demand (high first), stable within demand bucket.
      const sorted = [...spokes].sort(demandSort);
      groups.push({ kind, spokes: sorted });
    }
  }
  return groups;
}

/** Spokes grouped by kind THEN by vendor family — used when a kind has enough
 *  spokes to merit sub-grouping (>=5 entries with at least two distinct
 *  families). Otherwise the caller should fall back to `spokesByKind`. */
export interface VendorSubGroup {
  family: string;
  spokes: ReadonlyArray<TrackerSpoke>;
}
export interface KindWithVendorGroups {
  kind: TrackerKind;
  vendorGroups: ReadonlyArray<VendorSubGroup>;
}

export function spokesByKindWithVendor(
  locale: Locale,
): ReadonlyArray<KindWithVendorGroups> {
  const byKind = spokesByKind(locale);
  return byKind.map(({ kind, spokes }) => {
    const byFamily = new Map<string, TrackerSpoke[]>();
    for (const s of spokes) {
      const f = vendorFamily(s.vendor);
      const b = byFamily.get(f) ?? [];
      b.push(s);
      byFamily.set(f, b);
    }
    // Sort families: families with more entries first, then alphabetical.
    const vendorGroups = [...byFamily.entries()]
      .sort((a, b) => b[1].length - a[1].length || a[0].localeCompare(b[0]))
      .map(([family, list]) => ({ family, spokes: [...list].sort(demandSort) }));
    return { kind, vendorGroups };
  });
}

export function spokeBySlug(slug: string): TrackerSpoke | undefined {
  return TRACKERS.find((s) => s.slug === slug);
}

export function localesWithTrackersHub(): ReadonlyArray<LocaleConfig> {
  return LOCALE_LIST.filter((l) => spokesForLocale(l.locale).length > 0);
}
