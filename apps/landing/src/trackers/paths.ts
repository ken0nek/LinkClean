import { SITE_URL } from "../brand";
import { type Locale, localePath } from "../i18n/locales";

// Root-relative paths so links work on localhost, *.workers.dev, and
// linkclean.app alike. Wrap with `trackersUrl` only for canonical / hreflang
// / og:url / JSON-LD URLs that must point at SITE_URL.
export function trackersHubPath(locale: Locale): string {
  return `${localePath(locale)}trackers/`;
}

export function trackerSpokePath(locale: Locale, slug: string): string {
  return `${localePath(locale)}trackers/${slug}/`;
}

export function trackersUrl(path: string): string {
  return `${SITE_URL}${path}`;
}
