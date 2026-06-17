import { SITE_URL } from "../brand";
import { type Locale, localePath } from "../i18n/locales";

export function guidesIndexPath(locale: Locale): string {
  return `${localePath(locale)}guides/`;
}

export function guidePath(locale: Locale, slug: string): string {
  return `${localePath(locale)}guides/${slug}/`;
}

export function guideUrl(path: string): string {
  return `${SITE_URL}${path}`;
}
