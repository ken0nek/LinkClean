// One <style> block, passed through hono/html's raw() so `&` nesting and `>`
// child combinators aren't escaped. Privacy-teal accent on light/dark surface,
// system fonts, no webfonts. Shared by every template via pageLayout.tsx.
export const css = `
  /* Hallmark · genre: editorial · macrostructure: Manifesto · theme: custom (system-serif Almanac · paper oklch(98% 0.005 200) · accent oklch(55% 0.10 200) cool · system-serif body + display + mono fixtures) · enrichment: none · nav: shared shell (N1a — out of scope) · footer: shared shell (Ft2 — out of scope)
   * Hallmark · pre-emit critique: P5 H5 E5 S4 R5 V5
   * Hallmark · contrast: pass (40–41) · honest: pass (46) · chrome: pass (47) · tokens: pass (48) · responsive: pass (49) · icons: pass (30) · mobile: pass (34, 49, 50–57)
   * Hallmark · note: project bans webfonts — system serif is the deliberate theme floor, not a default attractor. Home-page sections only; shared chrome + /trackers/ /guides/ /learn/ selectors below are untouched. */

  *, *::before, *::after { box-sizing: border-box; }
  html { -webkit-text-size-adjust: 100%; }
  html, body { margin: 0; overflow-x: clip; }

  :root {
    --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Inter, system-ui, sans-serif;
    --font-mono: ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace;
    --font-serif: ui-serif, "New York", "Iowan Old Style", "Apple Garamond", Georgia, Cambria, "Times New Roman", Times, serif;
    --font-display: var(--font-serif);

    --text-display: clamp(2.5rem, 7vw + 0.5rem, 5rem);
    --text-display-s: clamp(1.85rem, 4vw + 0.5rem, 2.75rem);
    --text-h2: clamp(1.85rem, 3.5vw + 0.5rem, 2.5rem);
    --track-display: -0.025em;
    --track-caps: 0.16em;

    --color-bg: oklch(98% 0.005 200);
    --color-surface: oklch(100% 0 0);
    --color-ink: oklch(20% 0.01 220);
    --color-muted: oklch(45% 0.012 220);
    --color-rule: oklch(90% 0.01 210);
    --color-accent: oklch(55% 0.10 200);
    --color-accent-soft: oklch(94% 0.02 200);
    --color-accent-ink: oklch(99% 0.002 200);
    --color-warn: oklch(60% 0.13 30);
    --color-slab-bg: var(--color-ink);
    --color-slab-fg: var(--color-bg);
    --color-slab-muted: oklch(82% 0.012 200);

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
      --color-slab-muted: oklch(35% 0.012 210);
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

  /* Hero — manifesto declaration, no card, no centred-everything.
   * Padding pulls bottom > top (gate 44a) so the slab seats into the next section. */
  .home-hero {
    padding: clamp(3rem, 7vw, 4.5rem) 0 clamp(4rem, 11vw, 6.5rem);
    border-bottom: 6px solid var(--color-ink);
  }
  .home-hero h1 {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: var(--text-display);
    line-height: 1.02;
    letter-spacing: var(--track-display);
    max-width: 14ch;
    color: var(--color-ink);
    /* honest copy: Hallmark anti-pattern bans italic headers (gate 38a) — roman only */
    font-style: normal;
  }
  .home-hero p.lede {
    font-family: var(--font-serif);
    font-size: clamp(1.2rem, 1.6vw + 0.5rem, 1.55rem);
    line-height: 1.4;
    color: var(--color-ink);
    margin-top: var(--space-lg);
    max-width: 32rem;
  }
  .home-hero p.sub {
    font-family: var(--font-serif);
    font-size: 1.05rem;
    line-height: 1.6;
    margin-top: var(--space-md);
    color: var(--color-muted);
    max-width: 34rem;
  }

  /* CTA row — kept simple; the App Store badge is the brand-mandated CTA */
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

  /* Section rhythm — declarative heads, hairline tops, asymmetric padding */
  section.declaration {
    padding: clamp(3rem, 7vw, 5rem) 0;
    border-top: 1px solid var(--color-rule);
  }
  section.declaration > .wrap > h2,
  section.declaration > .wrap-wide > h2 {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: var(--text-h2);
    line-height: 1.1;
    letter-spacing: -0.02em;
    max-width: 22ch;
    color: var(--color-ink);
    font-style: normal;
  }
  section.declaration > .wrap > .section-intro {
    font-family: var(--font-serif);
    font-size: 1.1rem;
    line-height: 1.55;
    margin-top: var(--space-md);
    color: var(--color-muted);
    max-width: 32rem;
  }

  /* Proof — typographic URL fixtures, no card, no shadow */
  .proof { margin-top: var(--space-xl); }
  .proof .fixture {
    padding: var(--space-md) 0;
    border-top: 1px solid var(--color-rule);
  }
  .proof .fixture + .fixture { border-top: 1px solid var(--color-rule); }
  .proof .fixture.clean { border-bottom: 1px solid var(--color-rule); }
  .proof .fixture-label {
    display: block;
    font-family: var(--font-mono);
    font-size: 0.72rem;
    text-transform: uppercase;
    letter-spacing: var(--track-caps);
    color: var(--color-muted);
    margin-bottom: var(--space-xs);
  }
  .proof .fixture.clean .fixture-label { color: var(--color-accent); }
  .proof .fixture-url {
    font-family: var(--font-mono);
    font-size: clamp(0.88rem, 1vw + 0.35rem, 1rem);
    line-height: 1.6;
    word-break: break-all;
  }
  .proof .fixture.dirty .fixture-url { color: var(--color-muted); }
  .proof .fixture.dirty .strip {
    color: var(--color-warn);
    text-decoration: line-through;
    text-decoration-thickness: 1.5px;
    text-decoration-color: var(--color-warn);
  }
  .proof .fixture.clean .fixture-url { color: var(--color-ink); font-weight: 500; }
  .proof .fixture.clean .accent-dot {
    display: inline-block;
    width: 0.5em;
    height: 0.5em;
    background: var(--color-accent);
    border-radius: 50%;
    margin-right: 0.5em;
    vertical-align: middle;
  }
  .proof .note {
    font-family: var(--font-serif);
    font-size: 1rem;
    line-height: 1.55;
    color: var(--color-muted);
    margin-top: var(--space-lg);
    max-width: 34rem;
  }
  .proof .note strong { color: var(--color-ink); font-weight: 600; }

  /* Tenets — numbered declarations, hairline-divided, no cards.
   * Vertical stack: num kicker above heading, same column (gate 54). */
  .tenets {
    margin: var(--space-xl) 0 0;
    padding: 0;
    list-style: none;
  }
  .tenets > li {
    padding: var(--space-lg) 0;
    border-top: 1px solid var(--color-rule);
  }
  .tenets > li:last-child { border-bottom: 1px solid var(--color-rule); }
  .tenets .num {
    display: block;
    font-family: var(--font-mono);
    font-size: 0.78rem;
    letter-spacing: var(--track-caps);
    text-transform: uppercase;
    color: var(--color-accent);
    font-feature-settings: "tnum" 1;
    margin-bottom: var(--space-2xs);
  }
  .tenets h3 {
    font-family: var(--font-display);
    font-size: clamp(1.25rem, 1.6vw + 0.4rem, 1.6rem);
    font-weight: 600;
    line-height: 1.2;
    letter-spacing: -0.015em;
    color: var(--color-ink);
    font-style: normal;
    max-width: 24ch;
  }
  .tenets p {
    font-family: var(--font-serif);
    font-size: 1rem;
    line-height: 1.55;
    color: var(--color-muted);
    margin-top: var(--space-sm);
    max-width: 36rem;
  }

  /* Distinction — declarative diff (replaces the comparison table) */
  .distinction-list {
    margin: var(--space-xl) 0 0;
    padding: 0;
  }
  .distinction-row {
    padding: var(--space-md) 0;
    border-top: 1px solid var(--color-rule);
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: var(--space-2xs);
  }
  .distinction-row:last-child { border-bottom: 1px solid var(--color-rule); }
  .distinction-row .feature {
    font-family: var(--font-mono);
    font-size: 0.72rem;
    letter-spacing: var(--track-caps);
    text-transform: uppercase;
    color: var(--color-muted);
    margin: 0;
  }
  .distinction-row dd {
    margin: 0;
    font-family: var(--font-serif);
    font-size: 1rem;
    line-height: 1.5;
  }
  .distinction-row dd.linkclean { color: var(--color-ink); font-weight: 500; }
  .distinction-row dd.other { color: var(--color-muted); }
  .distinction-row dd::before {
    content: attr(data-label) " — ";
    font-family: var(--font-mono);
    font-size: 0.65rem;
    letter-spacing: var(--track-caps);
    text-transform: uppercase;
    margin-right: 0.35em;
    display: inline-block;
    vertical-align: 0.12em;
  }
  .distinction-row dd.linkclean::before { color: var(--color-accent); }
  .distinction-row dd.other::before { color: var(--color-muted); }
  .distinction-heads { display: none; }
  @media (min-width: 720px) {
    .distinction-heads {
      display: grid;
      grid-template-columns: 12em minmax(0, 1fr) minmax(0, 1fr);
      gap: var(--space-lg);
      margin-top: var(--space-xl);
      padding-bottom: var(--space-sm);
      font-family: var(--font-mono);
      font-size: 0.7rem;
      letter-spacing: var(--track-caps);
      text-transform: uppercase;
    }
    .distinction-heads .hd-linkclean { color: var(--color-accent); }
    .distinction-heads .hd-other { color: var(--color-muted); }
    .distinction-list { margin-top: 0; }
    .distinction-row {
      grid-template-columns: 12em minmax(0, 1fr) minmax(0, 1fr);
      gap: var(--space-lg);
      align-items: baseline;
    }
    .distinction-row .feature { font-size: 0.75rem; }
    .distinction-row dd::before { display: none; }
  }

  /* Surfaces — enumerated 01..05, vertical-stack (gate 54), hairline-divided.
   * Side-stripe card (was: 3px accent border-left) was a gate-fail tell — removed. */
  .surfaces-list {
    margin: var(--space-xl) 0 0;
    padding: 0;
    list-style: none;
  }
  .surfaces-list > li {
    padding: var(--space-md) 0;
    border-top: 1px solid var(--color-rule);
  }
  .surfaces-list > li:last-child { border-bottom: 1px solid var(--color-rule); }
  .surfaces-list .num {
    display: block;
    font-family: var(--font-mono);
    font-size: 0.72rem;
    letter-spacing: var(--track-caps);
    text-transform: uppercase;
    color: var(--color-accent);
    font-feature-settings: "tnum" 1;
    margin-bottom: var(--space-2xs);
  }
  .surfaces-list h3 {
    font-family: var(--font-display);
    font-size: 1.2rem;
    font-weight: 600;
    line-height: 1.25;
    letter-spacing: -0.01em;
    color: var(--color-ink);
    font-style: normal;
  }
  .surfaces-list p {
    font-family: var(--font-serif);
    font-size: 0.98rem;
    line-height: 1.55;
    color: var(--color-muted);
    margin-top: var(--space-xs);
    max-width: 38rem;
  }

  /* Questions — hairline-divided declarations, no card-in-card */
  .questions {
    margin-top: var(--space-xl);
  }
  .question {
    padding: var(--space-lg) 0;
    border-top: 1px solid var(--color-rule);
  }
  .question:last-child { border-bottom: 1px solid var(--color-rule); }
  .question h3 {
    font-family: var(--font-display);
    font-size: 1.2rem;
    font-weight: 600;
    line-height: 1.3;
    letter-spacing: -0.01em;
    color: var(--color-ink);
    font-style: normal;
    max-width: 38rem;
  }
  .question p {
    font-family: var(--font-serif);
    font-size: 1rem;
    line-height: 1.6;
    margin-top: var(--space-sm);
    color: var(--color-muted);
    max-width: 38rem;
  }

  /* Trackers index — declarative line, no card */
  .trackers-index {
    margin-top: var(--space-xl);
    padding-top: var(--space-md);
    border-top: 1px solid var(--color-rule);
  }
  .trackers-index p {
    font-family: var(--font-serif);
    font-size: 1.05rem;
    line-height: 1.6;
    color: var(--color-ink);
    max-width: 34rem;
  }
  .trackers-index a {
    display: inline-block;
    margin-top: var(--space-md);
    font-family: var(--font-mono);
    font-size: 0.8rem;
    letter-spacing: var(--track-caps);
    text-transform: uppercase;
    color: var(--color-accent);
    font-weight: 600;
    text-decoration: none;
  }
  .trackers-index a:hover {
    text-decoration: underline;
    text-underline-offset: 0.35em;
    text-decoration-thickness: 1.5px;
  }

  /* Final call — manifesto's oversized solid block. The slab inverts ink/paper in both
   * modes so the contrast reads as "the page's last word" regardless of scheme. */
  .final-call {
    padding: clamp(3.5rem, 8vw, 5.5rem) 0;
    background: var(--color-slab-bg);
    color: var(--color-slab-fg);
    border-top: 6px solid var(--color-accent);
  }
  .final-call h2 {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: clamp(2rem, 4vw + 0.5rem, 3rem);
    line-height: 1.05;
    letter-spacing: var(--track-display);
    color: var(--color-slab-fg);
    max-width: 16ch;
    font-style: normal;
  }
  .final-call p {
    font-family: var(--font-serif);
    font-size: 1.1rem;
    line-height: 1.5;
    margin-top: var(--space-md);
    color: var(--color-slab-muted);
    max-width: 30rem;
  }
  .final-call .cta-row { margin-top: var(--space-xl); }
  .final-call .cta-app-store:focus-visible {
    outline-color: var(--color-slab-fg);
  }

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

  .tracker-subsection { margin-top: var(--space-md); }
  .tracker-subsection:first-child { margin-top: var(--space-sm); }
  .vendor-family {
    font-size: 0.85rem;
    font-family: var(--font-mono);
    text-transform: uppercase;
    letter-spacing: 0.1em;
    color: var(--color-accent);
    margin-bottom: var(--space-2xs);
    font-weight: 600;
  }
  .search-title {
    margin-top: var(--space-sm);
    font-size: 1.05rem;
    color: var(--color-muted);
    font-style: italic;
  }

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
    .cta-app-store { transition: none; }
  }
`;
