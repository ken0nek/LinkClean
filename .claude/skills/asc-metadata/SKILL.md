---
name: asc-metadata
description: Research and update the App Store Connect listing copy for LinkClean — app name, subtitle, keywords, promotional text, and description (en-US only for now) — then upload via fastlane deliver. Use when the user asks to update App Store metadata, rewrite the app description / subtitle / keywords, run an ASO or keyword pass, or improve the listing. TRIGGER on "update App Store metadata", "rewrite the app description", "ASO keywords", "improve the subtitle", "app store listing copy", "fastlane metadata". Composes the app-store-optimization skill for keyword/ASO research and the copywriting skill for the prose.
---

# App Store Connect metadata

Update LinkClean's evergreen listing copy under `fastlane/metadata/`. Use `app-store-optimization` for keyword research / ASO strategy and `copywriting` for the actual prose — this skill's job is to apply them within LinkClean's hard constraints and stage them for upload. The rationale and constraints behind each field live in **`docs/release/app-store-metadata.md`** — read it first; it explains *why* each field reads the way it does. The actual copy is the canonical text under `fastlane/metadata/en-US/`.

## The fields (and their hard caps)

Under `fastlane/metadata/en-US/`:

| File | ASC cap | Current value / notes |
|---|---|---|
| `name.txt` | 30 | `LinkClean – URL Cleaner` (23). En-dash **U+2013**, not `-` or `—`. Fallback: plain `LinkClean` (9). |
| `subtitle.txt` | 30 | `Remove trackers from links` (26). Keyword-bearing tagline under the name. |
| `keywords.txt` | 100 | Comma-separated, **no spaces** between terms (spaces waste budget). Don't repeat words already in name/subtitle — Apple indexes those too. Apple stems plurals (`tracker`≈`trackers`). Current: `utm,fbclid,url,privacy,tracking,share,markdown,copy,paste,parameter,query,redirect,utm_source` (93). |
| `promotional_text.txt` | 170 | Editable **without** a new build — use it for the freshest hook (sales, new features). Current ≈157. |
| `description.txt` | 4000 | The long pitch. Current ≈1,300 — room to add an FAQ/testimonials later. |

Caps are enforced by App Store Connect — over-limit copy is rejected at upload, so count characters as you write. Root-level files rarely change: `primary_category.txt` = **Utilities**, `secondary_category.txt` = **Productivity**, `copyright.txt`, and the `en-US/*_url.txt` files.

## Locale

**en-US only.** LinkClean ships unlocalized for 1.0.0 — the `Deliverfile` pins `languages(["en-US"])`. Don't create other `metadata/{locale}/` folders until the *app itself* localizes its store-facing vocabulary. When that day comes, mirror the in-app terms from `Localizable.xcstrings` (whose keys are identifiers, not English) so the store and the app share wording — but that's a future task, not this skill's default.

## Constraints that aren't obvious from the files

- **Hold the privacy voice.** LinkClean's whole pitch is *on-device, private*. Market only what's literally true: cleaning happens on device, links never leave the device, and the app sends **only anonymous, aggregate analytics — never the contents of your links** (the typed `AnalyticsEvent` taxonomy provably never sends URLs/hosts/query strings/titles; see the `analytics-audit` skill). The description's "PRIVATE BY DESIGN" paragraph is load-bearing — keep its claims exact and in step with `docs/release/app-store-privacy-nutrition-label.md`. Never imply more or less data collection than the nutrition label declares.
- **Don't promise unshipped capability.** Describe what the current build delivers (clean, Share-sheet Clean Link + Copy as Markdown, leftover-parameter removal, History, custom parameters). Custom parameters / unlimited History are the *future* IAP candidate — don't advertise a paywall that doesn't exist yet.
- **`name.txt` would be in lockstep with a marketing site** *if one existed*. There's no `linkclean.app` landing page today (buying the domain is an open decision in `docs/TODO.md`). If one ships, keep the app name and the site's name/structured-data in sync in the same pass.
- **`release_notes.txt` is NOT this skill's territory** — that per-version "What's New" belongs to the **`release-notes`** skill. This skill owns the evergreen fields above.

## Current gaps to flag (verify, don't assume — state as of this writing)

- **Privacy Policy URL must be live before you can submit.** `en-US/privacy_url.txt` → `https://ken0nek.com/apps/linkclean/privacy-policy/` — confirm it resolves. The policy is published from the `ken0nek.github.io` repo (`apps/linkclean/privacy-policy/index.html`); `docs/release/privacy-policy.md` is a pointer/stub with internal notes, not the policy text.
- **Support URL** (`en-US/support_url.txt`) points at `https://github.com/ken0nek` — replace with a real support page when one exists.
- **Review info** under `fastlane/metadata/review_information/` — `demo_user`/`demo_password` are intentionally blank (no login); confirm email/name/notes/phone are filled.
- **Marketing URL** is intentionally omitted (optional in ASC).
- **Age rating 4+**, "Unrestricted Web Access" = **No** (LinkClean opens links in the system browser and reads page titles but embeds no in-app browser).

## Upload

Outward-facing — this pushes copy to the live (or pending) App Store listing. **Confirm with the user before running.** LinkClean's `Fastfile` defines `bump*` and `beta` lanes but **no metadata/release lane yet**, so push metadata-only with `deliver` directly (it reads `fastlane/Deliverfile`). fastlane runs under bundler + mise (`mise.toml` pins ruby; `Gemfile` provides fastlane):

```bash
bundle exec fastlane deliver --skip_binary_upload --skip_screenshots --force
```

`--force` skips the HTML preview prompt; drop it to review first. (If you'd rather have a named lane, add a `metadata` lane wrapping `deliver` to the `Fastfile` — but that's a code change to propose, not run silently.) Don't run the command or commit unless asked — this skill writes the files; shipping is a deliberate step.
