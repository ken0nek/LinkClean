import { AUTHOR_NAME, AUTHOR_URL, LAST_UPDATED, SITE_NAME } from "../brand";
import { LOCALE_LIST, LOCALES, type Locale, localePath } from "../i18n/locales";
import { inline } from "../markdown";
import { Layout } from "../pageLayout";
import { LEARN_ARTICLES } from "./data";
import { learnIndexPath, learnPath, learnUrl } from "./paths";
import type { LearnArticle } from "./types";

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

// ── /learn/ index hub ─────────────────────────────────────────
export function renderLearnHub(locale: Locale): string {
  const config = LOCALES[locale];
  const { copy } = config;
  const articles = LEARN_ARTICLES.filter((a) => a.content[locale]);

  const crumbs: CrumbLink[] = [
    { label: SITE_NAME, href: localePath(locale) },
    { label: "Learn" },
  ];
  const selfUrl = learnUrl(learnIndexPath(locale));
  const localesPresent = LOCALE_LIST.filter((l) =>
    LEARN_ARTICLES.some((a) => a.content[l.locale]),
  );

  const structuredData = JSON.stringify([
    {
      "@context": "https://schema.org",
      "@type": "CollectionPage",
      name: "Learn",
      description:
        "Long-form explainers on how URL tracking parameters work — what they leak, who reads them, and why LinkClean handles them the way it does.",
      inLanguage: LOCALES[locale].htmlLang,
      url: selfUrl,
      dateModified: LAST_UPDATED,
      hasPart: articles.map((a) => ({
        "@type": "Article",
        name: a.content[locale]?.title,
        url: learnUrl(learnPath(locale, a.slug)),
        description: a.content[locale]?.description,
      })),
    },
    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: crumbs.map((c, i) => ({
        "@type": "ListItem",
        position: i + 1,
        name: c.label,
        item: c.href ? learnUrl(c.href) : selfUrl,
      })),
    },
  ]).replace(/</g, "\\u003c");

  return `<!DOCTYPE html>${(
    <Layout
      locale={locale}
      title={`Learn — how tracking parameters work · ${SITE_NAME}`}
      description="Long-form explainers on how URL tracking parameters work — what they leak, who reads them, and why LinkClean handles them the way it does."
      ogType="website"
      structuredData={structuredData}
      locales={localesPresent}
      pathFor={(l) => learnIndexPath(l)}
    >
      <section class="page-hero">
        <div class="wrap">
          <Breadcrumb crumbs={crumbs} />
          <h1>Learn</h1>
          <p class="sub">
            Long-form explainers on how URL tracking parameters work — what
            they leak, who reads them, and why LinkClean handles them the way
            it does.
          </p>

          <ul class="tracker-list">
            {articles.map((a) => (
              <li key={a.slug}>
                <a href={learnPath(locale, a.slug)}>
                  <span class="name">{a.content[locale]?.title}</span>
                  <span class="desc">{a.content[locale]?.description}</span>
                </a>
              </li>
            ))}
          </ul>

          <section class="page-cta">
            <h2>Get LinkClean.</h2>
            <p>
              On-device URL cleaning for iPhone — from the share sheet, the
              app, Shortcuts, or a widget.
            </p>
            <div class="cta-row">
              <a
                class="cta-app-store"
                href={copy.appStoreCampaign.replace(
                  /([?&])ct=[^&]*/,
                  "$1ct=landing-learn-hub",
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

export function renderLearnArticle(
  locale: Locale,
  article: LearnArticle,
): string {
  const content = article.content[locale];
  if (!content) {
    throw new Error(`No ${locale} content for learn article "${article.slug}"`);
  }
  const config = LOCALES[locale];
  const { copy } = config;

  const crumbs: CrumbLink[] = [
    { label: SITE_NAME, href: localePath(locale) },
    { label: "Learn", href: learnIndexPath(locale) },
    { label: content.title },
  ];
  const selfUrl = learnUrl(learnPath(locale, article.slug));
  const localesPresent = LOCALE_LIST.filter((l) => article.content[l.locale]);

  const graph: unknown[] = [
    {
      "@context": "https://schema.org",
      "@type": "Article",
      headline: content.title,
      description: content.description,
      inLanguage: LOCALES[locale].htmlLang,
      dateModified: LAST_UPDATED,
      author: { "@type": "Person", name: AUTHOR_NAME, url: AUTHOR_URL },
      mainEntityOfPage: { "@type": "WebPage", "@id": selfUrl },
    },
    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: crumbs.map((c, i) => ({
        "@type": "ListItem",
        position: i + 1,
        name: c.label,
        item: c.href ? learnUrl(c.href) : selfUrl,
      })),
    },
  ];
  if (content.faq && content.faq.length > 0) {
    graph.push({
      "@context": "https://schema.org",
      "@type": "FAQPage",
      inLanguage: LOCALES[locale].htmlLang,
      mainEntity: content.faq.map(({ q, a }) => ({
        "@type": "Question",
        name: q,
        acceptedAnswer: { "@type": "Answer", text: a },
      })),
    });
  }
  const structuredData = JSON.stringify(graph).replace(/</g, "\\u003c");

  return `<!DOCTYPE html>${(
    <Layout
      locale={locale}
      title={`${content.title} · ${SITE_NAME}`}
      description={content.description}
      ogType="article"
      structuredData={structuredData}
      locales={localesPresent}
      pathFor={(l) => learnPath(l, article.slug)}
    >
      <section class="page-hero">
        <div class="wrap">
          <Breadcrumb crumbs={crumbs} />
          <h1>{content.title}</h1>
          <p class="sub">{content.description}</p>

          <aside class="tldr">
            <span class="label">TL;DR</span>
            <p>{inline(content.tldr)}</p>
          </aside>

          <div class="prose">
            {content.sections.map((s) => (
              <section key={s.heading}>
                <h2>{s.heading}</h2>
                {s.paragraphs.map((p) => (
                  <p key={p}>{inline(p)}</p>
                ))}
                {s.bullets && s.bullets.length > 0 ? (
                  <ul>
                    {s.bullets.map((b) => (
                      <li key={b}>{inline(b)}</li>
                    ))}
                  </ul>
                ) : null}
                {s.table ? (
                  <table class="ref-table">
                    {s.table.caption ? (
                      <caption>{s.table.caption}</caption>
                    ) : null}
                    <thead>
                      <tr>
                        {s.table.headers.map((h) => (
                          <th key={h} scope="col">
                            {h}
                          </th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {s.table.rows.map((row, i) => (
                        <tr key={`r${i}`}>
                          {row.map((cell, j) => (
                            <td key={`r${i}c${j}`}>{cell}</td>
                          ))}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                ) : null}
              </section>
            ))}
          </div>

          {content.faq && content.faq.length > 0 ? (
            <section class="prose">
              <h2>Frequently asked</h2>
              {content.faq.map(({ q, a }) => (
                <div key={q} class="faq-item">
                  <h3>{q}</h3>
                  <p>{inline(a)}</p>
                </div>
              ))}
            </section>
          ) : null}

          {content.related && content.related.length > 0 ? (
            <aside class="related">
              <span class="label">Related</span>
              <ul>
                {content.related.map((r) => (
                  <li key={r.href}>
                    <a href={r.href}>{r.label}</a>
                  </li>
                ))}
              </ul>
            </aside>
          ) : null}

          <section class="page-cta">
            <h2>Get LinkClean.</h2>
            <p>
              On-device URL cleaning for iPhone — from the share sheet, the
              app, Shortcuts, or a widget.
            </p>
            <div class="cta-row">
              <a
                class="cta-app-store"
                href={copy.appStoreCampaign.replace(
                  /([?&])ct=[^&]*/,
                  "$1ct=landing-learn",
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
