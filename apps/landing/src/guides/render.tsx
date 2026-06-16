import { AUTHOR_NAME, AUTHOR_URL, LAST_UPDATED, SITE_NAME } from "../brand";
import { LOCALE_LIST, LOCALES, type Locale, localePath } from "../i18n/locales";
import { Layout } from "../pageLayout";
import { guidePath, guideUrl } from "./paths";
import type { GuideArticle } from "./types";

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

export function renderGuide(locale: Locale, guide: GuideArticle): string {
  const content = guide.content[locale];
  if (!content) {
    throw new Error(`No ${locale} content for guide "${guide.slug}"`);
  }
  const config = LOCALES[locale];
  const { copy } = config;

  const crumbs: CrumbLink[] = [
    { label: SITE_NAME, href: localePath(locale) },
    { label: "Guides" },
    { label: content.title },
  ];
  const selfUrl = guideUrl(guidePath(locale, guide.slug));

  const localesPresent = LOCALE_LIST.filter((l) => guide.content[l.locale]);

  const structuredData = JSON.stringify([
    {
      "@context": "https://schema.org",
      "@type": "HowTo",
      name: content.title,
      description: content.description,
      inLanguage: LOCALES[locale].htmlLang,
      dateModified: LAST_UPDATED,
      author: { "@type": "Person", name: AUTHOR_NAME, url: AUTHOR_URL },
      mainEntityOfPage: { "@type": "WebPage", "@id": selfUrl },
      step: content.steps.map((s, i) => ({
        "@type": "HowToStep",
        position: i + 1,
        name: s.title,
        text: s.body,
      })),
    },
    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: crumbs.map((c, i) => ({
        "@type": "ListItem",
        position: i + 1,
        name: c.label,
        item: c.href ? guideUrl(c.href) : selfUrl,
      })),
    },
  ]).replace(/</g, "\\u003c");

  return `<!DOCTYPE html>${(
    <Layout
      locale={locale}
      title={`${content.title} · ${SITE_NAME}`}
      description={content.description}
      ogType="article"
      structuredData={structuredData}
      locales={localesPresent}
      pathFor={(l) => guidePath(l, guide.slug)}
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

          {content.intro && content.intro.length > 0 ? (
            <div class="prose">
              {content.intro.map((p) => (
                <p key={p}>{p}</p>
              ))}
            </div>
          ) : null}

          <ol class="howto-steps">
            {content.steps.map((s) => (
              <li key={s.title}>
                <h3>{s.title}</h3>
                <p>{s.body}</p>
              </li>
            ))}
          </ol>

          {content.outro && content.outro.length > 0 ? (
            <div class="prose">
              {content.outro.map((p) => (
                <p key={p}>{p}</p>
              ))}
            </div>
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
            <h2>Skip the steps — LinkClean does it.</h2>
            <p>
              LinkClean strips tracking parameters from any link in one tap,
              from any app's share sheet. No account, on-device.
            </p>
            <div class="cta-row">
              <a
                class="cta-app-store"
                href={copy.appStoreCampaign.replace(
                  /([?&])ct=[^&]*/,
                  "$1ct=landing-guide",
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
