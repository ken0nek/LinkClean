import { AUTHOR_NAME, AUTHOR_URL, LAST_UPDATED, SITE_NAME } from "../brand";
import { LOCALE_LIST, LOCALES, type Locale, localePath } from "../i18n/locales";
import { Layout } from "../pageLayout";
import { learnPath, learnUrl } from "./paths";
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
    { label: "Learn" },
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
            <p>
              <strong>{content.tldr}</strong>
            </p>
          </aside>

          <div class="prose">
            {content.sections.map((s) => (
              <section key={s.heading}>
                <h2>{s.heading}</h2>
                {s.paragraphs.map((p) => (
                  <p key={p}>{p}</p>
                ))}
                {s.bullets && s.bullets.length > 0 ? (
                  <ul>
                    {s.bullets.map((b) => (
                      <li key={b}>{b}</li>
                    ))}
                  </ul>
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
                  <p>{a}</p>
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
