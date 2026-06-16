import { SITE_URL } from "../brand";
import { type Locale, localePath } from "../i18n/locales";

export function learnPath(locale: Locale, slug: string): string {
  return `${localePath(locale)}learn/${slug}/`;
}

export function learnUrl(path: string): string {
  return `${SITE_URL}${path}`;
}
