import { Hono } from "hono";
import type { Context } from "hono";
import { SITE_URL } from "./brand";
import { buildRoutes, buildSitemap } from "./routes";

const app = new Hono();

const PAGE_CACHE =
  "public, max-age=300, s-maxage=86400, stale-while-revalidate=86400";
const REDIRECT_CACHE = "public, max-age=86400, s-maxage=604800";

// Keep `*.workers.dev` (and localhost) out of search indexes — every page
// already declares `linkclean.app` as canonical via <link rel="canonical">, but
// belt-and-suspenders with X-Robots-Tag covers HTML, /sitemap.xml, and
// /healthz at the HTTP layer (static assets are served by wrangler before the
// worker runs, so robots.txt / llms.txt / images aren't touched — fine, they
// reference linkclean.app URLs and don't hurt to leak).
app.use("*", async (c, next) => {
  await next();
  const host = c.req.header("host") ?? "";
  if (!/(?:^|\.)linkclean\.app$/i.test(host)) {
    c.res.headers.set("X-Robots-Tag", "noindex, nofollow");
  }
});

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
