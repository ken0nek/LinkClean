export const SITE_NAME = "LinkClean";
export const SITE_URL = "https://linkclean.app";
export const CONTACT = "linkclean@ken0nek.com";
export const APP_STORE_ID = "6758604043";
export const APP_STORE_URL = `https://apps.apple.com/us/app/linkclean/id${APP_STORE_ID}`;
export const PRIVACY_URL = "https://ken0nek.com/apps/linkclean/privacy-policy/";
export const TERMS_URL = "https://ken0nek.com/apps/linkclean/terms-of-use/";
export const AUTHOR_NAME = "Ken Tominaga";
export const AUTHOR_URL = "https://ken0nek.com";
export const AUTHOR_SAME_AS = ["https://github.com/ken0nek"];

// Languages the iOS *app* ships in (UI + content). Used by Phase-3 JSON-LD
// (SoftwareApplication.inLanguage); LP locales (see i18n/locales.ts) can diverge.
export const APP_SUPPORTED_LANGUAGES = ["en", "ja", "de"];

// Bump on every meaningful content change. Used in JSON-LD dateModified and the
// visible footer.
export const LAST_UPDATED = "2026-06-16";

// TelemetryDeck Web app ID for the `linkclean-landing` TD app. Empty disables
// the shim (window.td = noop, no SDK load); a set value loads the WebSDK and
// arms the AppStoreTapped beacon. The hostname check in pageLayout.tsx routes
// all non-linkclean.app traffic (localhost, *.workers.dev) to TD test mode so
// dev/preview signals don't pollute prod stats.
export const TELEMETRY_APP_ID = "8CAFBDA1-C8D6-44D8-BB9A-1930A4F30999";
