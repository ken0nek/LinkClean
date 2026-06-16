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
      <section class="hero">
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

      <hr class="rule" />

      <section>
        <div class="wrap">
          <h2>{copy.demo.h2}</h2>
          <p class="section-intro">{copy.demo.intro}</p>
          <article class="demo">
            <span class="label">{copy.demo.dirtyLabel}</span>
            <div class="url-line dirty">
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
            <span class="label">{copy.demo.cleanLabel}</span>
            <div class="url-line clean">{copy.demo.cleanUrl}</div>
            <span class="label">{copy.demo.strippedLabel}</span>
            <p class="note">{copy.demo.strippedNote}</p>
          </article>
        </div>
      </section>

      <hr class="rule" />

      <section>
        <div class="wrap-wide">
          <h2>{copy.benefits.h2}</h2>
          <div class="benefits">
            {copy.benefits.items.map((item) => (
              <div key={item.num} class="benefit">
                <div class="num">{item.num}</div>
                <h3>{item.title}</h3>
                <p>{item.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <hr class="rule" />

      <section>
        <div class="wrap-wide">
          <h2>{copy.comparison.h2}</h2>
          <table class="comparison-table">
            <thead>
              <tr>
                <th scope="col" />
                <th scope="col">{copy.comparison.linkcleanHeader}</th>
                <th scope="col">{copy.comparison.otherHeader}</th>
              </tr>
            </thead>
            <tbody>
              {copy.comparison.rows.map((row) => (
                <tr key={row.feature}>
                  <th scope="row">{row.feature}</th>
                  <td data-label={copy.comparison.linkcleanHeader}>
                    {row.linkclean}
                  </td>
                  <td data-label={copy.comparison.otherHeader}>{row.other}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <hr class="rule" />

      <section>
        <div class="wrap">
          <h2>{copy.surfaces.h2}</h2>
          <div class="surfaces">
            {copy.surfaces.items.map((item) => (
              <div key={item.title} class="surface">
                <h3>{item.title}</h3>
                <p>{item.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {hubVisible ? (
        <>
          <hr class="rule" />
          <section>
            <div class="wrap">
              <h2>{copy.trackersCta.h2}</h2>
              <article class="trackers-cta">
                <p>
                  {copy.trackersCta.body}{" "}
                  <a href={trackersHubPath(locale)}>
                    {copy.trackersCta.linkLabel} →
                  </a>
                </p>
              </article>
            </div>
          </section>
        </>
      ) : null}

      <hr class="rule" />

      <section>
        <div class="wrap">
          <h2>{copy.faqSection.h2}</h2>
          <div class="faq">
            {copy.faq.map(({ q, a }) => (
              <div key={q} class="faq-item">
                <h3>{q}</h3>
                <p>{a}</p>
              </div>
            ))}
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
