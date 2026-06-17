import {
  APP_STORE_URL,
  APP_SUPPORTED_LANGUAGES,
  AUTHOR_NAME,
  AUTHOR_SAME_AS,
  AUTHOR_URL,
  LAST_UPDATED,
  SITE_NAME,
  SITE_URL,
} from "./brand";
import type { Copy } from "./copy/types";
import {
  LOCALE_LIST,
  LOCALES,
  type Locale,
  localePath,
  localeUrl,
} from "./i18n/locales";
import { Layout } from "./pageLayout";
import { trackersHubPath } from "./trackers/paths";
import { spokesForLocale } from "./trackers/select";

function buildStructuredData(copy: Copy, locale: Locale): string {
  const author = {
    "@type": "Person",
    name: AUTHOR_NAME,
    url: AUTHOR_URL,
    sameAs: AUTHOR_SAME_AS,
  };
  return JSON.stringify([
    {
      "@context": "https://schema.org",
      "@type": "SoftwareApplication",
      name: SITE_NAME,
      alternateName: copy.schema.alternateName,
      description: copy.schema.description,
      featureList: copy.schema.featureList,
      operatingSystem: "iOS 26",
      applicationCategory: "UtilitiesApplication",
      url: localeUrl(locale),
      image: `${SITE_URL}/linkclean-icon.png`,
      downloadUrl: APP_STORE_URL,
      installUrl: APP_STORE_URL,
      author,
      inLanguage: APP_SUPPORTED_LANGUAGES,
      dateModified: LAST_UPDATED,
      offers: [
        {
          "@type": "Offer",
          name: "LinkClean (free)",
          price: "0",
          priceCurrency: "USD",
          availability: "https://schema.org/InStock",
        },
        {
          "@type": "Offer",
          name: "LinkClean Pro (one-time in-app purchase)",
          price: "4.99",
          priceCurrency: "USD",
          availability: "https://schema.org/InStock",
        },
      ],
    },
    {
      "@context": "https://schema.org",
      "@type": "FAQPage",
      inLanguage: LOCALES[locale].htmlLang,
      dateModified: LAST_UPDATED,
      mainEntity: copy.faq.map(({ q, a }) => ({
        "@type": "Question",
        name: q,
        acceptedAnswer: { "@type": "Answer", text: a },
      })),
    },
  ]).replace(/</g, "\\u003c");
}

/** Split the dirty URL into the path + each tracking parameter so the strip
 *  styling lines up with the demo copy. */
function dirtyUrlParts(url: string): {
  base: string;
  params: ReadonlyArray<string>;
} {
  const q = url.indexOf("?");
  if (q < 0) return { base: url, params: [] };
  const base = url.slice(0, q);
  const params = url.slice(q + 1).split("&");
  return { base, params };
}

const Home = ({ locale }: { locale: Locale }) => {
  const config = LOCALES[locale];
  const { copy } = config;
  const dirty = dirtyUrlParts(copy.demo.dirtyUrl);
  const hubVisible = spokesForLocale(locale).length > 0;

  return (
    <>
      <section class="home-hero">
        <div class="wrap">
          <h1>{copy.hero.h1}</h1>
          <p class="lede">{copy.hero.lede}</p>
          <p class="sub">{copy.hero.sub}</p>
          <div class="cta-row">
            <a
              class="cta-app-store"
              href={copy.appStoreCampaign}
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
        </div>
      </section>

      <section class="declaration">
        <div class="wrap">
          <h2>{copy.demo.h2}</h2>
          <p class="section-intro">{copy.demo.intro}</p>
          <article class="proof">
            <div class="fixture dirty">
              <span class="fixture-label">{copy.demo.dirtyLabel}</span>
              <div class="fixture-url">
                {dirty.base}
                {dirty.params.length > 0 ? (
                  <>
                    <span>?</span>
                    {dirty.params.map((p, i) => (
                      <>
                        {i > 0 ? <span>&</span> : null}
                        <span class="strip">{p}</span>
                      </>
                    ))}
                  </>
                ) : null}
              </div>
            </div>
            <div class="fixture clean">
              <span class="fixture-label">{copy.demo.cleanLabel}</span>
              <div class="fixture-url">
                <span class="accent-dot" aria-hidden="true" />
                {copy.demo.cleanUrl}
              </div>
            </div>
            <p class="note">
              <strong>{copy.demo.strippedLabel}.</strong>{" "}
              {copy.demo.strippedNote}
            </p>
          </article>
        </div>
      </section>

      <section class="declaration">
        <div class="wrap">
          <h2>{copy.benefits.h2}</h2>
          <ol class="tenets">
            {copy.benefits.items.map((item) => (
              <li key={item.num}>
                <span class="num">{item.num}</span>
                <h3>{item.title}</h3>
                <p>{item.body}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section class="declaration">
        <div class="wrap">
          <h2>{copy.comparison.h2}</h2>
          <div class="distinction-heads" aria-hidden="true">
            <span class="hd-feature" />
            <span class="hd-linkclean">{copy.comparison.linkcleanHeader}</span>
            <span class="hd-other">{copy.comparison.otherHeader}</span>
          </div>
          <dl class="distinction-list">
            {copy.comparison.rows.map((row) => (
              <div key={row.feature} class="distinction-row">
                <dt class="feature">{row.feature}</dt>
                <dd
                  class="linkclean"
                  data-label={copy.comparison.linkcleanHeader}
                >
                  {row.linkclean}
                </dd>
                <dd class="other" data-label={copy.comparison.otherHeader}>
                  {row.other}
                </dd>
              </div>
            ))}
          </dl>
        </div>
      </section>

      <section class="declaration">
        <div class="wrap">
          <h2>{copy.surfaces.h2}</h2>
          <ol class="surfaces-list">
            {copy.surfaces.items.map((item, i) => (
              <li key={item.title}>
                <span class="num">
                  {(i + 1).toString().padStart(2, "0")}
                </span>
                <h3>{item.title}</h3>
                <p>{item.body}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      {hubVisible ? (
        <section class="declaration">
          <div class="wrap">
            <h2>{copy.trackersCta.h2}</h2>
            <div class="trackers-index">
              <p>{copy.trackersCta.body}</p>
              <a href={trackersHubPath(locale)}>
                {copy.trackersCta.linkLabel} →
              </a>
            </div>
          </div>
        </section>
      ) : null}

      <section class="declaration">
        <div class="wrap">
          <h2>{copy.faqSection.h2}</h2>
          <div class="questions">
            {copy.faq.map(({ q, a }) => (
              <div key={q} class="question">
                <h3>{q}</h3>
                <p>{a}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section class="final-call">
        <div class="wrap">
          <h2>{copy.hero.h1}</h2>
          <p>{copy.hero.lede}</p>
          <div class="cta-row">
            <a
              class="cta-app-store"
              href={copy.appStoreCampaign}
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
        </div>
      </section>
    </>
  );
};

export function renderPage(locale: Locale): string {
  const config = LOCALES[locale];
  const { copy } = config;
  const structuredData = buildStructuredData(copy, locale);
  return `<!DOCTYPE html>${(
    <Layout
      locale={locale}
      title={copy.meta.title}
      description={copy.meta.description}
      ogType="website"
      structuredData={structuredData}
      locales={LOCALE_LIST}
      pathFor={(l) => localePath(l)}
    >
      <Home locale={locale} />
    </Layout>
  ).toString()}`;
}
