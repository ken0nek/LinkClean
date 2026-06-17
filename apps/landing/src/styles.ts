// One <style> block, passed through hono/html's raw() so `&` nesting and `>`
// child combinators aren't escaped. Privacy-teal accent on light/dark surface,
// system fonts, no webfonts. Shared by every template via pageLayout.tsx.
export const css = `
  *, *::before, *::after { box-sizing: border-box; }
  html { -webkit-text-size-adjust: 100%; }
  html, body { margin: 0; overflow-x: clip; }

  :root {
    --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Inter, system-ui, sans-serif;
    --font-mono: ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace;

    --color-bg: oklch(98% 0.005 200);
    --color-surface: oklch(100% 0 0);
    --color-ink: oklch(20% 0.01 220);
    --color-muted: oklch(45% 0.012 220);
    --color-rule: oklch(90% 0.01 210);
    --color-accent: oklch(55% 0.10 200);
    --color-accent-soft: oklch(94% 0.02 200);
    --color-accent-ink: oklch(99% 0.002 200);
    --color-warn: oklch(60% 0.13 30);

    --space-2xs: 0.5rem;
    --space-xs: 0.75rem;
    --space-sm: 1rem;
    --space-md: 1.5rem;
    --space-lg: 2rem;
    --space-xl: 3rem;
    --space-2xl: 4rem;

    --radius-sm: 8px;
    --radius-md: 12px;
    --radius-lg: 16px;

    --shadow-card: 0 6px 24px -16px oklch(20% 0.05 220 / 0.25);

    --ease-out: cubic-bezier(0.22, 1, 0.36, 1);
    --dur-base: 240ms;
  }

  @media (prefers-color-scheme: dark) {
    :root {
      --color-bg: oklch(16% 0.01 220);
      --color-surface: oklch(20% 0.012 220);
      --color-ink: oklch(95% 0.005 200);
      --color-muted: oklch(70% 0.012 210);
      --color-rule: oklch(28% 0.01 220);
      --color-accent: oklch(70% 0.12 200);
      --color-accent-soft: oklch(26% 0.04 200);
      --color-accent-ink: oklch(15% 0.01 220);
      --color-warn: oklch(72% 0.13 35);
      --shadow-card: 0 6px 24px -16px oklch(0% 0 0 / 0.55);
    }
  }

  body {
    background: var(--color-bg);
    color: var(--color-ink);
    font-family: var(--font-sans);
    font-size: 17px;
    line-height: 1.55;
    -webkit-font-smoothing: antialiased;
    text-rendering: optimizeLegibility;
  }

  h1, h2, h3 {
    margin: 0;
    letter-spacing: -0.015em;
    overflow-wrap: anywhere;
  }
  h1 { font-size: clamp(2rem, 6vw, 3.25rem); line-height: 1.05; letter-spacing: -0.025em; }
  h2 { font-size: clamp(1.5rem, 3.2vw, 2.1rem); line-height: 1.15; }
  h3 { font-size: 1.15rem; line-height: 1.3; }
  p { margin: 0; }

  a { color: var(--color-accent); text-decoration: none; }
  a:hover { text-decoration: underline; text-underline-offset: 0.2em; }
  a:focus-visible,
  button:focus-visible,
  summary:focus-visible {
    outline: 2px solid var(--color-accent);
    outline-offset: 3px;
    border-radius: var(--radius-sm);
  }

  .wrap { max-width: 720px; margin: 0 auto; padding: 0 var(--space-md); }
  .wrap-wide { max-width: 1040px; margin: 0 auto; padding: 0 var(--space-md); }

  /* Site header */
  header.site {
    padding: var(--space-lg) 0;
    border-bottom: 1px solid var(--color-rule);
  }
  header.site .wrap-wide {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: var(--space-sm);
  }
  .wordmark {
    display: inline-flex;
    align-items: center;
    gap: 0.55em;
    font-size: 1.1rem;
    font-weight: 600;
    color: var(--color-ink);
    letter-spacing: -0.01em;
  }
  .wordmark-icon {
    width: 1.75em;
    height: 1.75em;
    border-radius: 22%;
    box-shadow: 0 0 0 1px var(--color-rule);
  }
  .header-nav {
    display: flex;
    gap: var(--space-md);
    font-size: 0.95rem;
  }
  .header-nav a { color: var(--color-muted); }
  .header-nav a:hover { color: var(--color-accent); text-decoration: none; }

  /* Section rhythm */
  main > section { padding: clamp(2.5rem, 7vw, 4.5rem) 0; }
  hr.rule { border: 0; border-top: 1px solid var(--color-rule); margin: 0; }
  .section-intro { margin-top: var(--space-sm); color: var(--color-muted); max-width: 38rem; }

  /* Hero */
  .hero { padding: clamp(3.5rem, 9vw, 6rem) 0 clamp(2.5rem, 6vw, 4.5rem); }
  .hero h1 { max-width: 18ch; }
  .hero p.lede {
    font-size: clamp(1.15rem, 2.2vw, 1.4rem);
    line-height: 1.4;
    color: var(--color-ink);
    margin-top: var(--space-md);
    max-width: 38rem;
  }
  .hero p.sub {
    margin-top: var(--space-md);
    color: var(--color-muted);
    max-width: 36rem;
  }
  .cta-row {
    margin-top: var(--space-xl);
    display: flex;
    gap: var(--space-md);
    flex-wrap: wrap;
    align-items: center;
  }
  .cta-app-store {
    display: inline-block;
    transition: opacity var(--dur-base) var(--ease-out);
    border-radius: var(--radius-sm);
  }
  .cta-app-store:hover { opacity: 0.85; text-decoration: none; }
  .cta-app-store img { display: block; height: 44px; width: auto; }

  /* Demo card — dirty URL → clean URL */
  .demo {
    margin-top: var(--space-lg);
    background: var(--color-surface);
    border: 1px solid var(--color-rule);
    border-radius: var(--radius-lg);
    padding: clamp(1.25rem, 3vw, 1.75rem);
    box-shadow: var(--shadow-card);
  }
  .demo .label {
    display: block;
    font-family: var(--font-mono);
    font-size: 0.68rem;
    text-transform: uppercase;
    letter-spacing: 0.12em;
    color: var(--color-muted);
    margin: var(--space-md) 0 var(--space-2xs);
  }
  .demo .label:first-child { margin-top: 0; }
  .url-line {
    font-family: var(--font-mono);
    font-size: 0.9rem;
    line-height: 1.45;
    word-break: break-all;
    padding: var(--space-xs) var(--space-sm);
    border-radius: var(--radius-sm);
    border: 1px solid var(--color-rule);
  }
  .url-line.dirty { color: var(--color-muted); }
  .url-line.dirty .strip { color: var(--color-warn); text-decoration: line-through; }
  .url-line.clean { color: var(--color-ink); background: var(--color-accent-soft); border-color: transparent; }
  .demo .note { color: var(--color-muted); font-size: 0.95rem; margin-top: var(--space-2xs); }

  /* Benefits grid */
  .benefits {
    display: grid;
    gap: var(--space-md);
    grid-template-columns: minmax(0, 1fr);
    margin-top: var(--space-lg);
  }
  @media (min-width: 760px) {
    .benefits { grid-template-columns: repeat(3, minmax(0, 1fr)); }
  }
  .benefit {
    background: var(--color-surface);
    border: 1px solid var(--color-rule);
    border-radius: var(--radius-lg);
    padding: var(--space-md);
  }
  .benefit .num {
    font-family: var(--font-mono);
    font-size: 0.8rem;
    letter-spacing: 0.04em;
    color: var(--color-accent);
    font-feature-settings: "tnum" 1;
    margin-bottom: var(--space-2xs);
  }
  .benefit h3 { margin-bottom: var(--space-2xs); }
  .benefit p { color: var(--color-muted); font-size: 0.95rem; }

  /* Comparison table */
  .comparison-table {
    width: 100%;
    border-collapse: collapse;
    margin-top: var(--space-lg);
  }
  .comparison-table thead th {
    font-family: var(--font-mono);
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 0.12em;
    color: var(--color-muted);
    font-weight: 600;
    text-align: left;
    padding: 0 var(--space-md) var(--space-sm);
    border-bottom: 1px solid var(--color-rule);
  }
  .comparison-table thead th:first-child { padding-left: 0; }
  .comparison-table thead th:nth-of-type(2) { color: var(--color-accent); }
  .comparison-table tbody th,
  .comparison-table tbody td {
    text-align: left;
    vertical-align: top;
    padding: var(--space-sm) var(--space-md);
    border-bottom: 1px solid var(--color-rule);
    font-size: 0.95rem;
    line-height: 1.5;
  }
  .comparison-table tbody th {
    font-weight: 600;
    color: var(--color-ink);
    width: 26%;
    padding-left: 0;
  }
  .comparison-table tbody td:nth-of-type(2) { color: var(--color-muted); }
  .comparison-table tbody tr:last-child th,
  .comparison-table tbody tr:last-child td { border-bottom: 0; }
  @media (max-width: 600px) {
    .comparison-table thead { display: none; }
    .comparison-table, .comparison-table tbody, .comparison-table tbody tr { display: block; }
    .comparison-table tbody tr {
      padding: var(--space-md) 0;
      border-bottom: 1px solid var(--color-rule);
    }
    .comparison-table tbody tr:last-child { border-bottom: 0; padding-bottom: 0; }
    .comparison-table tbody th,
    .comparison-table tbody td {
      display: block;
      width: auto;
      padding: 0;
      border: 0;
      margin: 0;
    }
    .comparison-table tbody th { margin-bottom: var(--space-xs); }
    .comparison-table tbody td {
      margin-top: var(--space-xs);
      padding-left: var(--space-sm);
      border-left: 2px solid var(--color-rule);
    }
    .comparison-table tbody td::before {
      content: attr(data-label);
      display: block;
      font-family: var(--font-mono);
      font-size: 0.65rem;
      text-transform: uppercase;
      letter-spacing: 0.12em;
      color: var(--color-muted);
      margin-bottom: var(--space-2xs);
    }
    .comparison-table tbody td:nth-of-type(1)::before { color: var(--color-accent); }
  }

  /* Surfaces list */
  .surfaces {
    display: grid;
    gap: var(--space-md);
    grid-template-columns: minmax(0, 1fr);
    margin-top: var(--space-lg);
  }
  @media (min-width: 760px) {
    .surfaces { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  }
  .surface {
    border-left: 3px solid var(--color-accent);
    padding: var(--space-2xs) var(--space-md);
  }
  .surface h3 { margin-bottom: var(--space-2xs); }
  .surface p { color: var(--color-muted); font-size: 0.95rem; }

  /* FAQ */
  .faq-item { margin-top: var(--space-lg); }
  .faq-item:first-child { margin-top: var(--space-md); }
  .faq-item h3 { font-size: 1.1rem; line-height: 1.3; }
  .faq-item p { margin-top: var(--space-2xs); color: var(--color-muted); }

  /* Trackers CTA card */
  .trackers-cta {
    margin-top: var(--space-lg);
    background: var(--color-accent-soft);
    border-radius: var(--radius-lg);
    padding: clamp(1.5rem, 3vw, 2rem);
  }
  .trackers-cta p { color: var(--color-ink); }
  .trackers-cta a { font-weight: 600; }

  /* Site footer */
  footer.site {
    padding: var(--space-xl) 0 var(--space-2xl);
    color: var(--color-muted);
    font-size: 0.9rem;
  }
  footer.site .wrap-wide {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-xs) var(--space-md);
    justify-content: space-between;
  }
  footer.site a { color: var(--color-muted); }
  footer.site a:hover { color: var(--color-accent); }

  /* ── Non-home pages ────────────────────────────────────────────── */

  .breadcrumb {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    gap: 0.4em;
    font-family: var(--font-mono);
    font-size: 0.78rem;
    letter-spacing: 0.04em;
    color: var(--color-muted);
    margin-bottom: var(--space-md);
  }
  .breadcrumb a { color: var(--color-muted); }
  .breadcrumb a:hover { color: var(--color-accent); }
  .breadcrumb [aria-current="page"] { color: var(--color-ink); }

  .page-hero { padding: clamp(2rem, 6vw, 3.5rem) 0 0; }
  .page-hero h1 { font-size: clamp(1.85rem, 4.8vw, 2.8rem); max-width: 24ch; }
  .page-hero p.sub {
    margin-top: var(--space-sm);
    font-size: clamp(1.05rem, 2vw, 1.2rem);
    line-height: 1.45;
    color: var(--color-muted);
    max-width: 38rem;
  }

  /* TL;DR callout */
  .tldr {
    margin-top: var(--space-lg);
    background: var(--color-accent-soft);
    border-radius: var(--radius-md);
    padding: var(--space-md) var(--space-md);
    border-left: 3px solid var(--color-accent);
  }
  .tldr .label {
    display: block;
    font-family: var(--font-mono);
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 0.12em;
    color: var(--color-accent);
    margin-bottom: var(--space-2xs);
    font-weight: 600;
  }
  .tldr p { font-size: 1.05rem; line-height: 1.5; font-weight: 600; color: var(--color-ink); }
  .tldr p strong { font-weight: 800; }
  .tldr p code { background: oklch(98% 0.005 200 / 0.6); }

  /* Article prose blocks (used by trackers/guides/learn) */
  .prose { margin-top: var(--space-lg); max-width: 38rem; }
  .prose section { margin-top: var(--space-lg); }
  .prose section:first-child { margin-top: 0; }
  .prose h2 { margin-bottom: var(--space-sm); }
  .prose p { margin-top: var(--space-sm); color: var(--color-ink); }
  .prose p:first-child { margin-top: 0; }
  .prose ul, .prose ol { margin-top: var(--space-sm); padding-left: 1.4em; color: var(--color-ink); }
  .prose li { margin: var(--space-2xs) 0; }
  .prose code {
    font-family: var(--font-mono);
    font-size: 0.92em;
    background: var(--color-accent-soft);
    padding: 0.12em 0.35em;
    border-radius: 4px;
  }

  /* Reference tables inside long-form prose (e.g. parameter-value tables). */
  .ref-table {
    width: 100%;
    border-collapse: collapse;
    margin-top: var(--space-md);
    font-size: 0.95rem;
  }
  .ref-table caption {
    text-align: left;
    font-family: var(--font-mono);
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 0.12em;
    color: var(--color-muted);
    margin-bottom: var(--space-xs);
  }
  .ref-table thead th {
    font-family: var(--font-mono);
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 0.12em;
    color: var(--color-muted);
    font-weight: 600;
    text-align: left;
    padding: var(--space-xs) var(--space-sm);
    border-bottom: 1px solid var(--color-rule);
  }
  .ref-table thead th:first-child { padding-left: 0; color: var(--color-accent); }
  .ref-table tbody td {
    padding: var(--space-xs) var(--space-sm);
    border-bottom: 1px solid var(--color-rule);
    vertical-align: top;
    line-height: 1.45;
  }
  .ref-table tbody td:first-child { padding-left: 0; }
  .ref-table tbody td:first-child code {
    font-weight: 600;
    background: var(--color-accent-soft);
  }
  .ref-table tbody tr:last-child td { border-bottom: 0; }
  @media (max-width: 600px) {
    .ref-table thead { display: none; }
    .ref-table, .ref-table tbody, .ref-table tbody tr { display: block; }
    .ref-table tbody tr {
      padding: var(--space-sm) 0;
      border-bottom: 1px solid var(--color-rule);
    }
    .ref-table tbody tr:last-child { border-bottom: 0; }
    .ref-table tbody td {
      display: block;
      padding: 0;
      border: 0;
    }
    .ref-table tbody td:first-child { margin-bottom: var(--space-2xs); }
  }

  /* Example (dirty → clean) on tracker spokes */
  .example {
    margin-top: var(--space-lg);
    background: var(--color-surface);
    border: 1px solid var(--color-rule);
    border-radius: var(--radius-lg);
    padding: var(--space-md);
  }
  .example .label {
    display: block;
    font-family: var(--font-mono);
    font-size: 0.68rem;
    text-transform: uppercase;
    letter-spacing: 0.12em;
    color: var(--color-muted);
    margin: var(--space-md) 0 var(--space-2xs);
  }
  .example .label:first-child { margin-top: 0; }

  /* HowTo step list */
  .howto-steps { margin-top: var(--space-lg); padding: 0; list-style: none; counter-reset: step; }
  .howto-steps > li {
    counter-increment: step;
    background: var(--color-surface);
    border: 1px solid var(--color-rule);
    border-radius: var(--radius-md);
    padding: var(--space-md);
    margin-top: var(--space-md);
    position: relative;
    padding-left: calc(var(--space-md) + 2.5em);
  }
  .howto-steps > li::before {
    content: counter(step);
    position: absolute;
    left: var(--space-md);
    top: var(--space-md);
    width: 2em;
    height: 2em;
    border-radius: 50%;
    background: var(--color-accent);
    color: var(--color-accent-ink);
    font-weight: 700;
    font-family: var(--font-mono);
    display: inline-flex;
    align-items: center;
    justify-content: center;
    font-size: 0.95rem;
  }
  .howto-steps h3 { margin-bottom: var(--space-2xs); font-size: 1.05rem; }
  .howto-steps p { color: var(--color-muted); font-size: 0.95rem; margin-top: var(--space-2xs); }

  /* Tracker hub grid */
  .tracker-section { margin-top: var(--space-xl); }
  .tracker-section h2 { font-size: 1.35rem; }
  .tracker-list { margin: var(--space-md) 0 0; padding: 0; list-style: none; }
  .tracker-list li { border-top: 1px solid var(--color-rule); }
  .tracker-list li:last-child { border-bottom: 1px solid var(--color-rule); }
  .tracker-list a {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: 2px;
    padding: var(--space-sm) 0;
    color: var(--color-ink);
  }
  @media (min-width: 600px) {
    .tracker-list a { grid-template-columns: 10em minmax(0, 1fr); gap: var(--space-sm); align-items: baseline; }
  }
  .tracker-list a:hover { color: var(--color-accent); text-decoration: none; }
  .tracker-list .name { font-family: var(--font-mono); font-weight: 600; }
  .tracker-list .desc { color: var(--color-muted); font-size: 0.95rem; }

  /* Related links list at the bottom of a spoke / learn / guide page */
  .related {
    margin-top: var(--space-xl);
    padding-top: var(--space-md);
    border-top: 1px solid var(--color-rule);
  }
  .related .label {
    display: block;
    font-family: var(--font-mono);
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 0.12em;
    color: var(--color-muted);
    margin-bottom: var(--space-sm);
  }
  .related ul { margin: 0; padding: 0; list-style: none; }
  .related li { margin: var(--space-2xs) 0; }

  /* Page CTA card (drop the App Store badge anywhere) */
  .page-cta {
    margin-top: var(--space-xl);
    padding-top: var(--space-lg);
    border-top: 1px solid var(--color-rule);
  }
  .page-cta p { color: var(--color-muted); margin-bottom: var(--space-md); max-width: 36rem; }

  @media (prefers-reduced-motion: reduce) {
    .cta-app-store, .demo { transition: none; }
  }
`;
