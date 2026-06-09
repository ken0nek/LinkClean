---
name: release-notes
description: Generate App Store and TestFlight release notes ("What's New" / "What to Test") for LinkClean from the git history since the previous tag (en-US only). Use whenever the user asks for release notes, a changelog, "what's new", or notes for a version bump / ship. TRIGGER on "write release notes", "changelog for 1.1.0", "what changed since the last release", "what's new", "TestFlight changelog", "notes for the next build", "release notes". Composes the copywriting skill for benefit-language tone.
allowed-tools:
  - Bash(git describe*)
  - Bash(git tag*)
  - Bash(git log*)
---

# Release notes

Turn the commits since the last release into people-facing notes. Two destinations, both fed from one draft:

- **App Store** — `fastlane/metadata/en-US/release_notes.txt`, uploaded by `fastlane deliver` (the future `release`/`metadata` path). Max 4000 chars (never a constraint in practice).
- **TestFlight** — a single "What to Test" string passed to the `beta` lane: `bundle exec fastlane ios beta changelog:"…"` (distributes to the `dogfooding` external group).

The audience is **everyday people who share links, not engineers.** A commit says `Fix analytics double-count, add discovery signals`; a release note says nothing about that — it's invisible to users. Translate each *user-visible* change into the benefit felt, and drop everything else. This mirrors LinkClean's commit style one level further: describe the *benefit*, not the change.

## Step 1 — Find the range

Tags are plain semver, no `v` prefix (`1.0.0`, `1.1.0`), set by the `bump` skill / fastlane.

```bash
PREV=$(git describe --tags --abbrev=0 2>/dev/null)   # empty on the first release
if [ -z "$PREV" ]; then
  echo "FIRST RELEASE — no prior tag. Write the 1.0 welcome note (see Step 3), not a diff."
else
  git log "$PREV"..HEAD --no-merges --pretty=format:'%s'              # candidate changes
  git log "$PREV"..HEAD --no-merges --stat | grep -E '^\s' | sort -u  # touched areas, to judge user impact
fi
```

**LinkClean is pre-1.0 today — there are no tags yet,** so for 1.0.0 skip the diff and write the welcome note. From the *next* release on, use `<prev-tag>..HEAD` (or `<prev>..<that-tag>` for an already-tagged version).

## Step 2 — Filter to what users feel

**Keep:** new tracker coverage, Share-sheet actions, the removed-summary / leftover-parameter UX, History, Settings & custom parameters, new onboarding, performance a person actually notices, accessibility wins.

**Drop:** the catalog-gap telemetry and `ReferenceParameterCatalog` internals, analytics plumbing, refactors, dependency bumps, CI/build, docs, tests. When unsure, ask: *would someone notice this without being told?* If no, cut it.

**Before you promise a capability, confirm it actually ships in this build:**
- LinkClean has **no tier gating** today (IAP is planned for 1.1.0, `docs/plans/iap-implementation-plan.md`), so this is simpler than a multi-tier app — but still don't promise a setting that's DEBUG-gated or not yet wired. Check the code, not the commit titles.
- **Keep privacy claims literally true.** "On-device" and "your links never leave your device" are true and on-brand. Do **not** write "we collect nothing" — LinkClean sends anonymous, aggregate analytics (never link contents), and the privacy nutrition label says so. Match the description's "PRIVATE BY DESIGN" wording (see the `asc-metadata` skill).

## Step 3 — Draft (en-US)

House style: a one-line lead, a blank line, then `•` bullets, concise — keep to ~3–5 bullets. Lean on the `copywriting` skill for warmth and concision. The shipped 1.0 "What's New" (from `fastlane/metadata/en-US/release_notes.txt`) is the style anchor:

```
Welcome to LinkClean 1.0!

• Clean tracking parameters from any link
• Clean Link and Copy-as-Markdown actions, right in the Share Sheet
• See exactly what was removed — and tap a leftover parameter to remove it for good
• A searchable History of everything you've cleaned
• 100% on-device cleaning — your links never leave your device

Thanks for trying LinkClean. Feedback is always welcome.
```

Hold the calm, privacy-first voice; plain language; no buzzwords or exclamation-spam (one welcoming `!` is fine). For a later release, lead with the single most noticeable change and let the bullets carry the rest.

## Step 4 — Localize

**en-US only today** — there's no locale fan-out (the `Deliverfile` pins `languages(["en-US"])`). If store locales are ever added, mirror the in-app vocabulary from `Localizable.xcstrings` rather than translating from scratch, and follow the locale policy in the `asc-metadata` skill. Until then, this step is a no-op.

## Step 5 — Write the outputs

- Overwrite `fastlane/metadata/en-US/release_notes.txt`, matching the format exactly: lead line, blank line, `•` bullets, single trailing newline.
- Produce the TestFlight "What to Test" string for the `beta` lane. The App Store notes are **benefit-framed** for shoppers; the TestFlight string is more useful **action-framed** for the dogfooding group — tell them what to exercise and what to check, e.g.:

  ```bash
  bundle exec fastlane ios beta changelog:"Clean a few links from the Share Sheet (Clean Link + Copy as Markdown); confirm the removed-parameter summary matches; check History saves and re-clean works; toggle a default parameter and add a custom one."
  ```

Uploading is the lane's job, not this skill's: `release_notes.txt` ships with the next `deliver` run, and the `beta` lane carries the changelog to TestFlight. Don't run those lanes or commit unless asked — this skill produces the copy. The evergreen listing fields (name/subtitle/keywords/description) belong to the **`asc-metadata`** skill; this one owns only the per-version notes.
