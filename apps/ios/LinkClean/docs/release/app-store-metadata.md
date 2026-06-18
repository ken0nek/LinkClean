# App Store Connect Metadata — LinkClean (decisions & constraints)

The **canonical copy** lives in `fastlane/metadata/en-US/` — that's what `fastlane deliver` uploads. This file holds only the *rationale, caps, and decisions* behind each field, not a second copy of the text. **ASC metadata pinned to en-US through 1.0.0 and 1.1.0** (`languages(["en-US"])` in `fastlane/Deliverfile`) — note this is the *marketing listing* (description / keywords / screenshots), not the binary, which started shipping ja + de strings with 1.1.0 (LIVE 2026-06-16). Adding `ja-JP/` and `de-DE/` metadata folders is the natural next ASO move and is lighter-weight than a binary release.

| Field | File (canonical) | Cap | Decision / rationale |
|---|---|---|---|
| App name | `name.txt` | 30 | Brand + tagline house style (cf. `Whyzard – Learn Together`); the tagline adds "URL"/"Cleaner" search terms the subtitle doesn't cover. **En-dash U+2013**, never `-` or `—`. Fallback: plain `LinkClean`. |
| Subtitle | `subtitle.txt` | 30 | Keyword-bearing tagline under the name. Alternatives considered: `Clean tracking junk from URLs`, `Strip trackers from your links`. |
| Keywords | `keywords.txt` | 100 | Comma-separated, **no spaces** (spaces waste budget). Don't repeat words already in name/subtitle — Apple indexes those and stems plurals (`tracker`≈`trackers`); `url` was dropped (Jun 2026) because the name's "URL Cleaner" already indexes it. `gclid`/`fbclid`/`utm_source` are literally-removed default trackers, so high-intent and true. |
| Promotional text | `promotional_text.txt` | 170 | Editable **without** a new build — use for timely hooks (sales, new features). |
| Description | `description.txt` | 4000 | Sectioned pitch (CLEAN AS YOU SHARE / SEE WHAT YOU'RE REMOVING / MAKE IT YOURS / ONE PURCHASE, YOURS FOREVER / PRIVATE BY DESIGN). The **ONE PURCHASE, YOURS FOREVER** section states the tiers (free: unlimited cleaning, both Share-sheet actions, 1 custom rule, 7-day History; Pro: unlimited rules + full archive, one-time purchase) — keep it in lockstep with `ProGate`. The **PRIVATE BY DESIGN** paragraph is load-bearing — keep its claims exact and in step with `app-store-privacy-nutrition-label.md` and `docs/plans/analytics.md` §3 (it discloses that only the site *domain* of a cleaned link is sent, never the full link). |
| What's New | `release_notes.txt` | 4000 | Per-version; owned by the **`release-notes`** skill, not this doc. |

## Root-level fastlane fields
- **Categories** (`primary_category.txt` / `secondary_category.txt`): **Utilities** / **Productivity**.
- **URLs:** Support → `support_url.txt` → `https://linkclean.app` (the live marketing site; no dedicated `/support` route yet, so it lands on the home page — the footer carries the contact email `linkclean@ken0nek.com`). Privacy Policy → `privacy_url.txt` → `https://ken0nek.com/apps/linkclean/privacy-policy/` (must be live before submit).
- **Marketing URL** → `marketing_url.txt` → `https://linkclean.app` (set 2026-06-17; the "buy `linkclean.app`?" decision is resolved — the site is LIVE since 2026-06-16). Both URLs use the bare canonical form (no trailing slash) to match `apps/landing/src/brand.ts` `SITE_URL`.

## Age rating
**4+.** Questionnaire: "Unrestricted Web Access" = **No** (opens links in the system browser and reads page titles, but embeds no in-app browser). No other descriptors apply.

## Screenshots

The English-only pipeline has three states across the two required device sizes. Raw simulator captures are committed under `screenshots/raw/en-US/`; the `LinkCleanScreenshots` macOS target composites the teal caption frame and writes App Store-ready PNGs to `fastlane/screenshots/en-US/` (gitignored).

| # | Shot (story) | Raw capture | iPhone 17 Pro Max → 1320×2868 | iPad Pro 13" (M5) → 2064×2752 |
|---|---|---|---|---|
| 1 | Home hero — auto-pasted dirty URL, "4 REMOVED", clean link, leftover pills | `01_home.png` | `iPhone69-1-home.png` | `iPad13-1-home.png` |
| 2 | History — 4 seeded rows with fetched titles + search | `02_history.png` | `iPhone69-2-history.png` | `iPad13-2-history.png` |
| 3 | Default Parameters catalog — sectioned toggles, host-scoped rules | `03_parameters.png` | `iPhone69-3-parameters.png` | `iPad13-3-parameters.png` |

Build and install the DEBUG app on each booted simulator, then capture:

```bash
DEVICE_PROFILE=iphone69 bash scripts/capture-raw-screenshots.sh
DEVICE_PROFILE=ipad13 bash scripts/capture-raw-screenshots.sh
```

The script launches with `-screenshotMode`, which bypasses onboarding, restores default cleaning rules, suppresses analytics startup and DEBUG-only UI, and makes seeded History replacement deterministic. Run the `LinkCleanScreenshots` scheme afterward to generate the final PNGs.

History rows render real thumbnails from committed fixtures in `Screenshots/fixtures/history/` — actual LinkPresentation fetches (image-then-icon, square-cropped 256px), generated once per item with `scripts/fetch-history-thumbnails.swift` (usage in its header; fixture names must match the `thumbnail:` field in `LinkCleanApp.seedSampleHistory`). The capture script passes `-screenshotFixtures <dir>`; without that arg (e.g. a plain `-seedHistory` dev launch) rows fall back to domain monograms. X and the example-shop row have no fixture on purpose — LinkPresentation gets nothing useful from x.com's login wall, so monograms there are honest; the Spotify row awaits a real episode URL (an episode page's og-image is its cover art; the homepage's is an illegible player collage).

## Still needed (your tasks, not copy)
- **App icon** — done (1024² from the asset catalog).
- **Build** — archive & upload via Xcode, then attach in ASC.
