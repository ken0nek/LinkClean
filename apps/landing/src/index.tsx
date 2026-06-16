import { Hono } from "hono";
import type { Context } from "hono";
import { SITE_URL } from "./brand";
import { buildRoutes, buildSitemap } from "./routes";

const app = new Hono();

const PAGE_CACHE =
  "public, max-age=300, s-maxage=86400, stale-while-revalidate=86400";
const REDIRECT_CACHE = "public, max-age=86400, s-maxage=604800";

function cachedRedirect(c: Context, target: string) {
  c.header("Cache-Control", REDIRECT_CACHE);
  return c.redirect(target, 301);
}

const ROUTES = buildRoutes();

// Pre-render every route once at boot; register a handler per entry. Trailing
// slash is canonical; the slashless form 301-redirects so internal links and
// crawlers converge on one URL.
for (const entry of ROUTES) {
  const html = entry.render();
  const handler = (c: Context) => {
    c.header("Cache-Control", PAGE_CACHE);
    return c.html(html);
  };
  app.get(entry.path, handler);
  if (entry.path !== "/" && entry.path.endsWith("/")) {
    const noTrailing = entry.path.slice(0, -1);
    app.get(noTrailing, (c) => cachedRedirect(c, entry.path));
  }
}

const SITEMAP = buildSitemap(ROUTES, SITE_URL);
app.get("/sitemap.xml", (c) => {
  c.header("Content-Type", "application/xml; charset=utf-8");
  c.header("Cache-Control", PAGE_CACHE);
  return c.body(SITEMAP);
});

app.get("/healthz", (c) => {
  c.header("Cache-Control", "no-store");
  return c.text("ok");
});

export default app;
