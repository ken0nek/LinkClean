import { SITE_URL } from "../brand";
import { en } from "../copy/en";
import type { Copy } from "../copy/types";

export interface LocaleConfig {
  locale: Locale;
  copy: Copy;
  htmlLang: string;
  ogLocale: string;
  pathPrefix: string;
  pickerLabel: string;
}

// en-only at launch per the Phase-1 plan. ja / de drop in here without
// rearchitecting (mirrors whyzard's multi-locale path).
export const LOCALES = {
  en: {
    locale: "en",
    copy: en,
    htmlLang: "en",
    ogLocale: "en_US",
    pathPrefix: "",
    pickerLabel: "English",
  },
} as const satisfies Record<
  string,
  Omit<LocaleConfig, "locale"> & { locale: string }
>;

export type Locale = keyof typeof LOCALES;

export const DEFAULT_LOCALE: Locale = "en";

export const LOCALE_LIST: ReadonlyArray<LocaleConfig> = Object.values(LOCALES);

export function localePath(locale: Locale): string {
  const { pathPrefix } = LOCALES[locale];
  return pathPrefix === "" ? "/" : `${pathPrefix}/`;
}

export function localeUrl(locale: Locale): string {
  return `${SITE_URL}${localePath(locale)}`;
}
