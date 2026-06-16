import { Hono } from "hono";
import { LOCALE_LIST, localePath } from "./i18n/locales";
import { renderPage } from "./page";

const app = new Hono();

const PAGE_CACHE =
  "public, max-age=300, s-maxage=86400, stale-while-revalidate=86400";

// Pre-render each locale's Home at worker boot — Phase 1 is en-only but the
// loop is the Phase-3 expansion seam.
for (const l of LOCALE_LIST) {
  const html = renderPage(l.locale);
  app.get(localePath(l.locale), (c) => {
    c.header("Cache-Control", PAGE_CACHE);
    return c.html(html);
  });
}

app.get("/healthz", (c) => {
  c.header("Cache-Control", "no-store");
  return c.text("ok");
});

export default app;
