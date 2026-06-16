import { raw } from "hono/html";
import type { Child } from "hono/jsx";
import {
  AUTHOR_NAME,
  AUTHOR_URL,
  CONTACT,
  LAST_UPDATED,
  PRIVACY_URL,
  SITE_NAME,
  SITE_URL,
  TELEMETRY_APP_ID,
  TERMS_URL,
} from "./brand";
import {
  DEFAULT_LOCALE,
  LOCALE_LIST,
  LOCALES,
  type Locale,
  type LocaleConfig,
  localePath,
  localeUrl,
} from "./i18n/locales";
import { css } from "./styles";

// TelemetryDeck Web shim. Empty TELEMETRY_APP_ID (Phase 3a.1) → no SDK load and
// `td()` no-ops. Phase 3a.4 will set the ID; the hostname check keeps non-prod
// traffic in TD test mode (mirrors whyzard's TELEMETRY_INIT verbatim, including
// the text/plain Blob CORS trick on the AppStoreTapped beacon).
export const TELEMETRY_INIT = `(() => {
  const APP_ID = "${TELEMETRY_APP_ID}";
  if (!APP_ID) { window.td = () => {}; return; }
  const ENDPOINT = "https://nom.telemetrydeck.com/v2/";
  const isTestMode = !/(^|\\.)linkclean\\.app$/i.test(location.hostname);
  const sessionID = Math.random().toString(36).slice(2);

  const sdk = document.createElement("script");
  sdk.src = "https://cdn.telemetrydeck.com/websdk/telemetrydeck.min.js";
  sdk.dataset.appId = APP_ID;
  if (isTestMode) sdk.dataset.isTestMode = "true";
  document.head.appendChild(sdk);

  window.td = (type) => {
    const body = [{
      appID: APP_ID,
      clientUser: "web",
      sessionID,
      type,
      telemetryClientVersion: "LinkCleanLanding 1.0",
      ...(isTestMode && { isTestMode: true }),
    }];
    const blob = new Blob([JSON.stringify(body)], { type: "text/plain" });
    if (!navigator.sendBeacon?.(ENDPOINT, blob)) {
      fetch(ENDPOINT, { method: "POST", body: blob, keepalive: true }).catch(() => {});
    }
  };
})();`;

const LocaleItem = ({
  l,
  currentLocale,
  hrefFor,
}: {
  l: LocaleConfig;
  currentLocale: Locale;
  hrefFor: (locale: Locale) => string;
}) =>
  l.locale === currentLocale ? (
    <span aria-current="page" lang={l.htmlLang}>
      {l.pickerLabel}
    </span>
  ) : (
    <a href={hrefFor(l.locale)} hreflang={l.htmlLang} lang={l.htmlLang}>
      {l.pickerLabel}
    </a>
  );

/** Shared document shell. Every template renders into this — home, trackers,
 *  guides, learn. `pathFor` returns the root-relative path of THIS page in a
 *  given locale; it drives the locale picker and (wrapped in SITE_URL) the
 *  canonical / hreflang / og:url SEO tags. `locales` is the set where the page
 *  actually exists, so hreflang never advertises a dangling alternate. */
export const Layout = ({
  locale,
  title,
  description,
  ogType,
  structuredData,
  locales,
  pathFor,
  children,
}: {
  locale: Locale;
  title: string;
  description: string;
  ogType: "website" | "article";
  /** Already-JSON-stringified structured-data graph. Empty string = omit. */
  structuredData?: string;
  locales: ReadonlyArray<LocaleConfig>;
  pathFor: (locale: Locale) => string;
  children: Child;
}) => {
  const config = LOCALES[locale];
  const canonical = `${SITE_URL}${pathFor(locale)}`;
  const xDefault = locales.some((l) => l.locale === DEFAULT_LOCALE)
    ? DEFAULT_LOCALE
    : locales[0].locale;
  const showPicker = LOCALE_LIST.length > 1 && locales.length > 1;

  return (
    <html lang={config.htmlLang}>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{title}</title>
        <meta name="description" content={description} />
        <meta name="author" content={AUTHOR_NAME} />
        <meta
          name="theme-color"
          content="#f5fbfb"
          media="(prefers-color-scheme: light)"
        />
        <meta
          name="theme-color"
          content="#0d1417"
          media="(prefers-color-scheme: dark)"
        />
        <link rel="canonical" href={canonical} />
        {locales.map((l) => (
          <link
            key={l.locale}
            rel="alternate"
            hreflang={l.htmlLang}
            href={`${SITE_URL}${pathFor(l.locale)}`}
          />
        ))}
        <link
          rel="alternate"
          hreflang="x-default"
          href={`${SITE_URL}${pathFor(xDefault)}`}
        />
        <link rel="icon" type="image/png" href="/linkclean-icon.png" />
        <meta property="og:type" content={ogType} />
        <meta property="og:site_name" content={SITE_NAME} />
        <meta property="og:title" content={title} />
        <meta property="og:description" content={description} />
        <meta property="og:url" content={canonical} />
        <meta property="og:image" content={`${SITE_URL}/linkclean-icon.png`} />
        <meta property="og:locale" content={config.ogLocale} />
        {locales
          .filter((l) => l.locale !== locale)
          .map((l) => (
            <meta
              key={l.locale}
              property="og:locale:alternate"
              content={l.ogLocale}
            />
          ))}
        <meta name="twitter:card" content="summary" />
        <meta name="twitter:title" content={title} />
        <meta name="twitter:description" content={description} />
        <meta name="twitter:image" content={`${SITE_URL}/linkclean-icon.png`} />
        <style>{raw(css)}</style>
        {structuredData ? (
          <script type="application/ld+json">{raw(structuredData)}</script>
        ) : null}
        <script>{raw(TELEMETRY_INIT)}</script>
      </head>
      <body>
        <header class="site">
          <div class="wrap-wide">
            <a class="wordmark" href={localePath(locale)}>
              <img
                class="wordmark-icon"
                src="/linkclean-icon.png"
                alt=""
                width="32"
                height="32"
              />
              {SITE_NAME}
            </a>
            {showPicker ? (
              <nav
                class="header-nav"
                aria-label={config.copy.localePicker.ariaLabel}
              >
                {locales.map((l) => (
                  <LocaleItem
                    key={l.locale}
                    l={l}
                    currentLocale={locale}
                    hrefFor={pathFor}
                  />
                ))}
              </nav>
            ) : null}
          </div>
        </header>

        <main>{children}</main>

        <hr class="rule" />

        <footer class="site">
          <div class="wrap-wide">
            <span>{config.copy.footer.tagline}</span>
            <span>
              {config.copy.footer.bylinePrefix}{" "}
              <a href={AUTHOR_URL} rel="author">
                {AUTHOR_NAME}
              </a>
              {" · © 2026 · "}
              <a href={`mailto:${CONTACT}`}>{CONTACT}</a>
              {" · "}
              <a href={PRIVACY_URL}>{config.copy.footer.privacyLabel}</a>
              {" · "}
              <a href={TERMS_URL}>{config.copy.footer.termsLabel}</a>
              {" · "}
              {config.copy.footer.lastUpdatedPrefix} {LAST_UPDATED}
            </span>
          </div>
        </footer>
      </body>
    </html>
  );
};
