# App Store Connect Metadata — LinkClean (decisions & constraints)

The **canonical copy** lives in `fastlane/metadata/en-US/` — that's what `fastlane deliver` uploads. This file holds only the *rationale, caps, and decisions* behind each field, not a second copy of the text. en-US only for 1.0.0 (pinned in `fastlane/Deliverfile`).

| Field | File (canonical) | Cap | Decision / rationale |
|---|---|---|---|
| App name | `name.txt` | 30 | Brand + tagline house style (cf. `Whyzard – Learn Together`); the tagline adds "URL"/"Cleaner" search terms the subtitle doesn't cover. **En-dash U+2013**, never `-` or `—`. Fallback: plain `LinkClean`. |
| Subtitle | `subtitle.txt` | 30 | Keyword-bearing tagline under the name. Alternatives considered: `Clean tracking junk from URLs`, `Strip trackers from your links`. |
| Keywords | `keywords.txt` | 100 | Comma-separated, **no spaces** (spaces waste budget). Don't repeat words already in name/subtitle — Apple indexes those and stems plurals (`tracker`≈`trackers`). `gclid`/`fbclid`/`utm_source` are literally-removed default trackers, so high-intent and true. |
| Promotional text | `promotional_text.txt` | 170 | Editable **without** a new build — use for timely hooks (sales, new features). |
| Description | `description.txt` | 4000 | Sectioned pitch (CLEAN AS YOU SHARE / SEE WHAT YOU'RE REMOVING / MAKE IT YOURS / PRIVATE BY DESIGN). The **PRIVATE BY DESIGN** paragraph is load-bearing — keep its claims exact and in step with `app-store-privacy-nutrition-label.md` and `docs/plans/analytics.md` §3 (it discloses that only the site *domain* of a cleaned link is sent, never the full link). |
| What's New | `release_notes.txt` | 4000 | Per-version; owned by the **`release-notes`** skill, not this doc. |

## Root-level fastlane fields
- **Categories** (`primary_category.txt` / `secondary_category.txt`): **Utilities** / **Productivity**.
- **URLs:** Support → `support_url.txt` (currently `https://github.com/ken0nek` — replace with a real support page when one exists). Privacy Policy → `privacy_url.txt` → `https://ken0nek.com/apps/linkclean/privacy-policy/` (must be live before submit).
- **Marketing URL** intentionally omitted (optional in ASC). Open decision: buy `linkclean.app`? — tracked in `docs/TODO.md`.

## Age rating
**4+.** Questionnaire: "Unrestricted Web Access" = **No** (opens links in the system browser and reads page titles, but embeds no in-app browser). No other descriptors apply.

## Still needed (your tasks, not copy)
- **Screenshots** — iPhone 6.9" and iPad 13" required sizes (`docs/TODO.md` #5). I can generate raw simulator captures of the key flows on request.
- **App icon** — done (1024² from the asset catalog).
- **Build** — archive & upload via Xcode, then attach in ASC.
