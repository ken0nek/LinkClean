import { LOCALE_LIST, type Locale, type LocaleConfig } from "../i18n/locales";
import { TRACKERS } from "./data";
import type { TrackerKind, TrackerSpoke } from "./types";

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
    if (spokes && spokes.length > 0) groups.push({ kind, spokes });
  }
  return groups;
}

export function spokeBySlug(slug: string): TrackerSpoke | undefined {
  return TRACKERS.find((s) => s.slug === slug);
}

export function localesWithTrackersHub(): ReadonlyArray<LocaleConfig> {
  return LOCALE_LIST.filter((l) => spokesForLocale(l.locale).length > 0);
}
