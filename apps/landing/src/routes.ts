import { LAST_UPDATED } from "./brand";
import { GUIDES } from "./guides/data";
import { renderGuide } from "./guides/render";
import { guidePath } from "./guides/paths";
import {
  DEFAULT_LOCALE,
  LOCALE_LIST,
  type Locale,
  localePath,
} from "./i18n/locales";
import { LEARN_ARTICLES } from "./learn/data";
import { renderLearnArticle } from "./learn/render";
import { learnPath } from "./learn/paths";
import { renderPage } from "./page";
import { TRACKERS } from "./trackers/data";
import { renderTrackerSpoke, renderTrackersHub } from "./trackers/render";
import { trackerSpokePath, trackersHubPath } from "./trackers/paths";
import { spokesForLocale } from "./trackers/select";

/** One pre-rendered route entry. `pathFor` lets the sitemap emit hreflang
 *  alternates per locale; `localesPresent` is which locales the page exists in.
 *  `render` is invoked once at boot per route entry. */
export interface RouteEntry {
  path: string;
  locale: Locale;
  /** Renders the full HTML at boot. */
  render: () => string;
  /** Locales where this *logical* page exists (drives hreflang). */
  localesPresent: ReadonlyArray<Locale>;
  /** Pure function: locale → root-relative path for the logical page. */
  pathFor: (l: Locale) => string;
  /** Override the sitemap lastmod. Defaults to LAST_UPDATED. */
  lastmod?: string;
  /** Sitemap priority hint (0.0–1.0). Defaults vary by kind. */
  priority?: number;
}

function present<T>(
  source: ReadonlyArray<{ content: Partial<Record<Locale, T>> }>,
  pick: (item: (typeof source)[number]) => boolean,
): ReadonlyArray<Locale> {
  void pick;
  return LOCALE_LIST.map((l) => l.locale).filter((l) =>
    source.some((s) => s.content[l]),
  );
}

export function buildRoutes(): ReadonlyArray<RouteEntry> {
  const routes: RouteEntry[] = [];

  // ── Home (every locale) ──────────────────────────────────────
  const homeLocales = LOCALE_LIST.map((l) => l.locale);
  for (const locale of homeLocales) {
    routes.push({
      path: localePath(locale),
      locale,
      render: () => renderPage(locale),
      localesPresent: homeLocales,
      pathFor: (l) => localePath(l),
      priority: 1.0,
    });
  }

  // ── Trackers hub (locales with ≥1 spoke) ─────────────────────
  for (const locale of LOCALE_LIST.map((l) => l.locale)) {
    if (spokesForLocale(locale).length === 0) continue;
    routes.push({
      path: trackersHubPath(locale),
      locale,
      render: () => renderTrackersHub(locale),
      localesPresent: LOCALE_LIST.map((l) => l.locale).filter(
        (l) => spokesForLocale(l).length > 0,
      ),
      pathFor: (l) => trackersHubPath(l),
      priority: 0.9,
    });
  }

  // ── Tracker spokes ───────────────────────────────────────────
  for (const spoke of TRACKERS) {
    const present = LOCALE_LIST.map((l) => l.locale).filter(
      (l) => spoke.content[l],
    );
    for (const locale of present) {
      routes.push({
        path: trackerSpokePath(locale, spoke.slug),
        locale,
        render: () => renderTrackerSpoke(locale, spoke),
        localesPresent: present,
        pathFor: (l) => trackerSpokePath(l, spoke.slug),
        priority: 0.7,
      });
    }
  }

  // ── Guides ───────────────────────────────────────────────────
  for (const guide of GUIDES) {
    const present = LOCALE_LIST.map((l) => l.locale).filter(
      (l) => guide.content[l],
    );
    for (const locale of present) {
      routes.push({
        path: guidePath(locale, guide.slug),
        locale,
        render: () => renderGuide(locale, guide),
        localesPresent: present,
        pathFor: (l) => guidePath(l, guide.slug),
        priority: 0.7,
      });
    }
  }

  // ── Learn ────────────────────────────────────────────────────
  for (const article of LEARN_ARTICLES) {
    const present = LOCALE_LIST.map((l) => l.locale).filter(
      (l) => article.content[l],
    );
    for (const locale of present) {
      routes.push({
        path: learnPath(locale, article.slug),
        locale,
        render: () => renderLearnArticle(locale, article),
        localesPresent: present,
        pathFor: (l) => learnPath(l, article.slug),
        priority: 0.8,
      });
    }
  }

  return routes;
}

// One <url> block per route, with hreflang alternates per locale-present
// variant plus an x-default. Quietly de-dupes if buildRoutes ever returns the
// same path twice (which would also be a routing collision).
export function buildSitemap(
  routes: ReadonlyArray<RouteEntry>,
  siteUrl: string,
): string {
  // Group routes by logical page (each variant points at the same pathFor).
  const seen = new Set<string>();
  const blocks: string[] = [];
  for (const r of routes) {
    if (seen.has(r.path)) continue;
    seen.add(r.path);

    const variants = r.localesPresent.map((l) => {
      const config = LOCALE_LIST.find((x) => x.locale === l);
      return {
        locale: l,
        htmlLang: config?.htmlLang ?? l,
        loc: `${siteUrl}${r.pathFor(l)}`,
      };
    });
    const xDefault =
      variants.find((v) => v.locale === DEFAULT_LOCALE)?.loc ??
      variants[0].loc;

    // Mark all variants as seen so the per-locale duplicates collapse.
    for (const v of variants) seen.add(r.pathFor(v.locale));

    const lastmod = r.lastmod ?? LAST_UPDATED;
    const priority = r.priority ?? 0.5;

    blocks.push(
      variants
        .map((v) => {
          const alternates = variants
            .map(
              (a) =>
                `    <xhtml:link rel="alternate" hreflang="${a.htmlLang}" href="${a.loc}" />`,
            )
            .join("\n");
          return `  <url>
    <loc>${v.loc}</loc>
    <lastmod>${lastmod}</lastmod>
    <priority>${priority.toFixed(1)}</priority>
${alternates}
    <xhtml:link rel="alternate" hreflang="x-default" href="${xDefault}" />
  </url>`;
        })
        .join("\n"),
    );
  }
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
${blocks.join("\n")}
</urlset>
`;
}
