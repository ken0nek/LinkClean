# LinkClean Privacy Policy — pointer (not the policy itself)

The **canonical, published** privacy policy is a standalone HTML page, not this file:

- **Live:** https://ken0nek.com/apps/linkclean/privacy-policy/ (wired into `fastlane/metadata/en-US/privacy_url.txt`)
- **Source:** `ken0nek.github.io` repo → `apps/linkclean/privacy-policy/index.html` — **edit the policy there.**

This file previously held a full second draft of the policy; it was reduced to a pointer so the same prose isn't maintained in two places. Keep the live page consistent in substance with `app-store-privacy-nutrition-label.md` and `docs/plans/analytics.md` §3.

## Internal notes the public page deliberately omits

The published page uses a genericized house style that names no vendors or tech. The internal, named-complete picture:

- The "privacy-focused analytics provider" is **TelemetryDeck** (`docs/plans/analytics.md`).
- Analytics sends: an anonymized, salted + hashed per-install identifier; bucketed counts; finite/public tracker *category* and *name* ids; standard device metadata; and — since **2026-06-09** — the **site domain (host only)** of a cleaned link (e.g. `youtube.com`). It never sends the full link, path, query string, or any values, nor clipboard, search text, custom-parameter names, page titles, or previews.
- When analytics collection changes, update these together: the live page, `app-store-privacy-nutrition-label.md` (→ App Store Connect → App Privacy), and `docs/plans/analytics.md` §3.
