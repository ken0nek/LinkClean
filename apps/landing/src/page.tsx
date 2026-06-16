import { raw } from "hono/html";
import { AUTHOR_NAME, AUTHOR_URL, LAST_UPDATED, SITE_NAME } from "./brand";
import { LOCALES, type Locale, localeUrl } from "./i18n/locales";

// Inlined in one <style> tag via raw() so the `>` child combinators and `&`
// nesting aren't HTML-escaped. Phase 1: privacy-teal accent on a light/dark
// surface, system fonts, no webfonts. Phase 3 will add the hero artwork.
const css = `
  *, *::before, *::after { box-sizing: border-box; }
  html { -webkit-text-size-adjust: 100%; }
  html, body { margin: 0; }

  :root {
    --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Inter, system-ui, sans-serif;
    --color-bg: oklch(98% 0.005 200);
    --color-ink: oklch(20% 0.01 220);
    --color-muted: oklch(45% 0.012 220);
    --color-rule: oklch(90% 0.01 210);
    --color-accent: oklch(55% 0.10 200);
    --color-accent-ink: oklch(99% 0.002 200);
  }

  @media (prefers-color-scheme: dark) {
    :root {
      --color-bg: oklch(16% 0.01 220);
      --color-ink: oklch(95% 0.005 200);
      --color-muted: oklch(70% 0.012 210);
      --color-rule: oklch(28% 0.01 220);
      --color-accent: oklch(70% 0.12 200);
      --color-accent-ink: oklch(15% 0.01 220);
    }
  }

  body {
    background: var(--color-bg);
    color: var(--color-ink);
    font-family: var(--font-sans);
    line-height: 1.5;
    -webkit-font-smoothing: antialiased;
  }

  main {
    max-width: 38rem;
    margin: 0 auto;
    padding: 6rem 1.5rem 4rem;
  }

  h1 {
    font-size: clamp(2rem, 6vw, 3rem);
    line-height: 1.1;
    letter-spacing: -0.02em;
    margin: 0 0 1rem;
  }

  .lede {
    font-size: 1.125rem;
    color: var(--color-muted);
    margin: 0 0 2rem;
  }

  .cta {
    display: inline-block;
    padding: 0.875rem 1.5rem;
    background: var(--color-accent);
    color: var(--color-accent-ink);
    border-radius: 0.75rem;
    font-weight: 600;
    text-decoration: none;
  }

  .cta:hover { filter: brightness(1.05); }

  footer {
    margin-top: 4rem;
    padding-top: 1.5rem;
    border-top: 1px solid var(--color-rule);
    color: var(--color-muted);
    font-size: 0.875rem;
  }

  footer a { color: inherit; }
`;

export function renderPage(locale: Locale): string {
  const config = LOCALES[locale];
  const { copy } = config;
  const canonical = localeUrl(locale);

  return `<!DOCTYPE html>
<html lang="${config.htmlLang}">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>${escape(copy.meta.title)}</title>
<meta name="description" content="${escape(copy.meta.description)}" />
<link rel="canonical" href="${canonical}" />
<style>${raw(css)}</style>
</head>
<body>
<main>
  <h1>${escape(copy.hero.h1)}</h1>
  <p class="lede">${escape(copy.hero.lede)}</p>
  <a class="cta" href="${copy.appStoreCampaign}" rel="noopener">${escape(copy.appStoreLabel)}</a>
  <footer>
    <p>${escape(copy.footer.tagline)}</p>
    <p>
      ${escape(copy.footer.bylinePrefix)}
      <a href="${AUTHOR_URL}">${escape(AUTHOR_NAME)}</a>
      · ${escape(copy.footer.lastUpdatedPrefix)} ${LAST_UPDATED}
      · ${escape(SITE_NAME)}
    </p>
  </footer>
</main>
</body>
</html>`;
}

function escape(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
