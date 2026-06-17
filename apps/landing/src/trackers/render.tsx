import {
  APP_STORE_URL,
  AUTHOR_NAME,
  AUTHOR_URL,
  LAST_UPDATED,
  SITE_NAME,
} from "../brand";
import { LOCALES, type Locale, localePath } from "../i18n/locales";
import { inline } from "../markdown";
import { Layout } from "../pageLayout";
import { trackersChrome } from "./chrome";
import {
  trackerSpokePath,
  trackersHubPath,
  trackersUrl,
} from "./paths";
import {
  KIND_ORDER,
  localesForSpoke,
  localesWithTrackersHub,
  spokeBySlug,
  spokesByKind,
  spokesForLocale,
} from "./select";
import type { TrackerSpoke } from "./types";

interface CrumbLink {
  label: string;
  href?: string;
}

const Breadcrumb = ({ crumbs }: { crumbs: ReadonlyArray<CrumbLink> }) => (
  <nav class="breadcrumb" aria-label="Breadcrumb">
    {crumbs.flatMap((c, i) => {
      const node = c.href ? (
        <a key={`c-${i}`} href={c.href}>
          {c.label}
        </a>
      ) : (
        <span key={`c-${i}`} aria-current="page">
          {c.label}
        </span>
      );
      return i > 0
        ? [
            <span key={`s-${i}`} aria-hidden="true">
              /
            </span>,
            node,
          ]
        : [node];
    })}
  </nav>
);

function breadcrumbLd(
  crumbs: ReadonlyArray<{ name: string; url: string }>,
): unknown {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: crumbs.map((c, i) => ({
      "@type": "ListItem",
      position: i + 1,
      name: c.name,
      item: c.url,
    })),
  };
}

function crumbItems(
  crumbs: ReadonlyArray<CrumbLink>,
  selfUrl: string,
): ReadonlyArray<{ name: string; url: string }> {
  return crumbs.map((c) => ({
    name: c.label,
    url: c.href ? trackersUrl(c.href) : selfUrl,
  }));
}

// ── /trackers/<param>/ spoke ─────────────────────────────────────
export function renderTrackerSpoke(
  locale: Locale,
  spoke: TrackerSpoke,
): string {
  const content = spoke.content[locale];
  if (!content) {
    throw new Error(
      `No ${locale} content for tracker spoke "${spoke.slug}" (${spoke.param})`,
    );
  }
  const chrome = trackersChrome(locale);
  const config = LOCALES[locale];
  const { copy } = config;
  const title =
    content.title ?? `${spoke.param}${chrome.spokeTitleSuffix} · ${SITE_NAME}`;

  const crumbs: CrumbLink[] = [
    { label: SITE_NAME, href: localePath(locale) },
    { label: chrome.trackersLabel, href: trackersHubPath(locale) },
    { label: spoke.param },
  ];
  const selfUrl = trackersUrl(trackerSpokePath(locale, spoke.slug));

  const related = (spoke.related ?? [])
    .map((slug) => spokeBySlug(slug))
    .filter((s): s is TrackerSpoke => !!s && !!s.content[locale]);

  const isFunctional = spoke.nature === "functional";

  const structuredData = JSON.stringify([
    {
      "@context": "https://schema.org",
      "@type": "Article",
      headline: spoke.param,
      description: content.description,
      author: { "@type": "Person", name: AUTHOR_NAME, url: AUTHOR_URL },
      inLanguage: LOCALES[locale].htmlLang,
      dateModified: LAST_UPDATED,
      mainEntityOfPage: { "@type": "WebPage", "@id": selfUrl },
      about: {
        "@type": "DefinedTerm",
        name: spoke.param,
        inDefinedTermSet: trackersUrl(trackersHubPath(locale)),
        termCode: spoke.param,
        identifier: spoke.kind,
      },
    },
    {
      "@context": "https://schema.org",
      "@type": "FAQPage",
      inLanguage: LOCALES[locale].htmlLang,
      mainEntity: content.faq.map(({ q, a }) => ({
        "@type": "Question",
        name: q,
        acceptedAnswer: { "@type": "Answer", text: a },
      })),
    },
    breadcrumbLd(crumbItems(crumbs, selfUrl)),
  ]).replace(/</g, "\\u003c");

  return `<!DOCTYPE html>${(
    <Layout
      locale={locale}
      title={title}
      description={content.description}
      ogType="article"
      structuredData={structuredData}
      locales={localesForSpoke(spoke)}
      pathFor={(l) => trackerSpokePath(l, spoke.slug)}
    >
      <section class="page-hero">
        <div class="wrap">
          <Breadcrumb crumbs={crumbs} />
          <h1>
            <code>{spoke.param}</code>
          </h1>
          <p class="sub">
            {chrome.kindLabel[spoke.kind]} · {spoke.vendor}
            {isFunctional ? ` · ${chrome.functionalTag}` : ""}
          </p>

          <aside class="tldr">
            <span class="label">{chrome.tldrLabel}</span>
            <p>{inline(content.tldr)}</p>
          </aside>

          <div class="prose">
            {content.sections.map((s) => (
              <section key={s.heading}>
                <h2>{s.heading}</h2>
                {s.paragraphs.map((p) => (
                  <p key={p}>{inline(p)}</p>
                ))}
              </section>
            ))}
          </div>

          {isFunctional ? (
            <article class="example">
              <span class="label">{chrome.exampleFunctionalLabel}</span>
              <div class="url-line clean">{content.exampleDirty}</div>
              <p class="note">{chrome.preservedNote}</p>
            </article>
          ) : (
            <article class="example">
              <span class="label">{chrome.exampleDirtyLabel}</span>
              <div class="url-line dirty">{content.exampleDirty}</div>
              <span class="label">{chrome.exampleCleanLabel}</span>
              <div class="url-line clean">{content.exampleClean}</div>
            </article>
          )}

          <section class="prose">
            <h2>{chrome.faqHeading}</h2>
            {content.faq.map(({ q, a }) => (
              <div key={q} class="faq-item">
                <h3>{q}</h3>
                <p>{inline(a)}</p>
              </div>
            ))}
          </section>

          {related.length > 0 ? (
            <aside class="related">
              <span class="label">{chrome.relatedHeading}</span>
              <ul>
                {related.map((r) => (
                  <li key={r.slug}>
                    <a href={trackerSpokePath(locale, r.slug)}>
                      <code>{r.param}</code> — {r.content[locale]?.tldr}
                    </a>
                  </li>
                ))}
              </ul>
            </aside>
          ) : null}

          <section class="page-cta">
            <h2>{chrome.ctaHeading}</h2>
            <p>{chrome.ctaBody}</p>
            <div class="cta-row">
              <a
                class="cta-app-store"
                href={copy.appStoreCampaign.replace(
                  /([?&])ct=[^&]*/,
                  "$1ct=landing-trackers",
                )}
                onclick="td && td('Landing.AppStoreTapped')"
                rel="noopener"
              >
                <img
                  src={copy.appStoreBadge.file}
                  alt={copy.appStoreBadge.alt}
                  width={copy.appStoreBadge.width}
                  height={copy.appStoreBadge.height}
                />
              </a>
            </div>
          </section>
        </div>
      </section>
    </Layout>
  ).toString()}`;
}

// ── /trackers/ hub ───────────────────────────────────────────────
export function renderTrackersHub(locale: Locale): string {
  const chrome = trackersChrome(locale);
  const config = LOCALES[locale];
  const { copy } = config;
  const groups = spokesByKind(locale);
  const allSpokes = spokesForLocale(locale);

  const crumbs: CrumbLink[] = [
    { label: SITE_NAME, href: localePath(locale) },
    { label: chrome.trackersLabel },
  ];
  const selfUrl = trackersUrl(trackersHubPath(locale));

  const structuredData = JSON.stringify([
    {
      "@context": "https://schema.org",
      "@type": "DefinedTermSet",
      name: chrome.hubTitle,
      description: chrome.hubMeta,
      inLanguage: LOCALES[locale].htmlLang,
      url: selfUrl,
      dateModified: LAST_UPDATED,
      hasDefinedTerm: allSpokes.map((s) => ({
        "@type": "DefinedTerm",
        name: s.param,
        termCode: s.param,
        url: trackersUrl(trackerSpokePath(locale, s.slug)),
        description: s.content[locale]?.tldr ?? "",
      })),
    },
    breadcrumbLd(crumbItems(crumbs, selfUrl)),
  ]).replace(/</g, "\\u003c");

  return `<!DOCTYPE html>${(
    <Layout
      locale={locale}
      title={`${chrome.hubTitle} · ${SITE_NAME}`}
      description={chrome.hubMeta}
      ogType="website"
      structuredData={structuredData}
      locales={localesWithTrackersHub()}
      pathFor={(l) => trackersHubPath(l)}
    >
      <section class="page-hero">
        <div class="wrap">
          <Breadcrumb crumbs={crumbs} />
          <h1>{chrome.hubTitle}</h1>
          <p class="sub">{chrome.hubIntro}</p>

          {groups.map((g) => (
            <div key={g.kind} class="tracker-section">
              <h2>{chrome.kindLabel[g.kind]}</h2>
              <ul class="tracker-list">
                {g.spokes.map((s) => (
                  <li key={s.slug}>
                    <a href={trackerSpokePath(locale, s.slug)}>
                      <span class="name">{s.param}</span>
                      <span class="desc">{s.content[locale]?.tldr}</span>
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}

          <section class="page-cta">
            <h2>{chrome.ctaHeading}</h2>
            <p>{chrome.ctaBody}</p>
            <div class="cta-row">
              <a
                class="cta-app-store"
                href={copy.appStoreCampaign.replace(
                  /([?&])ct=[^&]*/,
                  "$1ct=landing-trackers-hub",
                )}
                onclick="td && td('Landing.AppStoreTapped')"
                rel="noopener"
              >
                <img
                  src={copy.appStoreBadge.file}
                  alt={copy.appStoreBadge.alt}
                  width={copy.appStoreBadge.width}
                  height={copy.appStoreBadge.height}
                />
              </a>
            </div>
          </section>
        </div>
      </section>
    </Layout>
  ).toString()}`;
}
