# LinkClean Copy Style Guide

> **Status: house rules — 2026-06-13.** The standard for LinkClean's user-facing words: in-app strings, CTAs, App Store listing, and (later) the landing page. Synthesizes conversion-copy craft with Apple's Human Interface Guidelines, so copy stays consistent as the app adds locales and surfaces.
> **Grounded in:** Apple HIG [Writing](https://developer.apple.com/design/human-interface-guidelines/writing) and [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons); Apple [Localization](https://developer.apple.com/documentation/xcode/localization) (esp. [Preparing text for translation](https://developer.apple.com/documentation/xcode/preparing-your-apps-text-for-translation)); the `copywriting` skill. Aligns with [app-store-metadata.md](../release/app-store-metadata.md) (listing copy) and [string-catalog-symbols] (the identifier-key mechanism).

---

## 1. The two-lens model — which rules apply where

Conversion-copy craft and Apple's HIG conflict on tone (marketing voice vs. platform clarity). They don't compete — they govern **different surfaces**:

| Surface | Governing lens | In practice |
|---|---|---|
| **System UI** — buttons, toggles, alerts, settings, empty states, errors, field hints | **Apple HIG** | Concise, verb-first, title-style, no marketing voice. Clarity over cleverness. |
| **Conversion surfaces** — paywall headers/pitch, onboarding hero, App Store listing, landing page | **Copywriting craft**, inside HIG's honest tone | Benefit-led, specific, customer language. Never fabricated stats or hype. |

When in doubt, default to HIG: *“Prioritize clarity and avoid the temptation to be too cute or clever.”*

---

## 2. Voice

LinkClean's voice is **calm, plain, privacy-absolute, and personal**. It reassures (a privacy app must feel trustworthy), states benefits plainly, and never hypes. Concretely:

- **"link", not "URL"** in user-facing copy. The one kept exception is the share-sheet action name **“Clean URL”** (`INFOPLIST_KEY_CFBundleDisplayName`) — English in all locales.
- **Privacy claims are exact and load-bearing.** Keep them in lockstep with the nutrition label + `analytics.md` §3 (e.g. "your links never leave your phone"; only the cleaned link's *domain* is ever sent).
- **"clean" = the verb, "cleaned link" = the result.** Don't mix "clean link" / "cleaned link" for the noun.

---

## 3. Capitalization (the most common inconsistency)

HIG *Writing*: choose a case style **per element type** and apply it consistently. HIG *Buttons*: button labels use **title-style capitalization, verb-first**.

| Element | Case | Examples |
|---|---|---|
| Buttons, alert actions, menu items, toggle/row labels, nav titles, section headers | **Title Case** | Copy Cleaned Link · Always Remove · Restore Purchases · Turn On History · By Category |
| Headlines / hero titles | Sentence case | "Clean links, instantly" · "Works in any app's share sheet" |
| Body, footers, placeholders, full-sentence messages, errors | Sentence case | "Paste a link to clean" · "Keep every link you clean, searchable any time." |

> Capitalization is **English-only**. Japanese has no case; German capitalizes nouns by its own rules — don't force English title case onto translations.

---

## 4. Buttons & CTAs

- **Verb-first, title-style** (HIG *Buttons*): "Always Remove", "Unlock Pro", "Turn On History". Avoid bare nouns or "Click/Tap here."
- **One or two prominent buttons per view** (HIG): too many prominent buttons raise cognitive load.
- **Roles matter** (HIG): destructive actions use `Button(role: .destructive)` (red) and are **never** the primary/prominent button. ✅ LinkClean already does this everywhere (Clear History, Disable & Delete, deletes).
- **Conversion CTAs carry the value:** put the price/benefit in the label — "Unlock Pro — $4.99" beats "Buy".
- **Multi-step flows** (HIG): "Get Started" → "Continue"/"Next" → "Done". Be consistent.

---

## 5. Specific patterns

- **Empty states** (HIG): guide to a next step; give a button if one fits. *History disabled* offers a **Turn On History** button (not "go to Settings"); *History empty* tells you how rows get there.
- **Errors** (HIG): close to the problem, no blame, actionable, **no "oops/uh-oh".** "Choose a password with at least 8 characters", not "That password is too short." LinkClean's "Enter a valid link" (not "Invalid link") is the model. Keep the paywall's no-charge reassurance.
- **Possessives, sparingly** (HIG): "Share Privacy Card", not "Share Your Privacy Card." Keep "your" only where the warmth is deliberate and consistent (the privacy body claims).
- **Avoid "we"** (HIG): "Unable to load", not "We're having trouble loading." LinkClean already avoids it.
- **Settings labels** describe what ON does; the OFF behavior is inferred.

---

## 6. Localization checklist (every string, every locale)

From Apple's Localization guidance:

- **Add a translator comment** to any ambiguous key (a one-word label, anything with a `%@`/`%lld`, a term of art). The catalog's `comment` field is the place — it ships to translators, not users. *This is the single highest-leverage localization-quality habit.*
- **Never concatenate** sentence fragments in code — localize the whole sentence. (Watch `Text + Text` joins; they reorder differently per language.)
- **Plurals via the catalog's plural variations**, never `if count == 1`. Japanese has only `other`; German has `one`/`other`.
- **Preserve every format specifier** (`%@`, `%lld`); for multi-argument strings use positional args (`%1$@`) so translators can reorder.
- **Budget for text expansion (~35% for German):** verify constrained layouts (buttons, fixed-width columns, toggle rows) don't truncate.
- **Adding a language needs `knownRegions` in the pbxproj**, not just catalog values, or the app won't advertise the locale.
- **Action-extension display names stay English** (the "Clean URL" exception) — so guide text that references them is English in every locale.
- **Get a native review** before shipping a locale; QA on-device with `-AppleLanguages '(xx)'`.

---

## 7. Process

- Source strings live in `LinkClean/Localizable.xcstrings` (identifier keys, `extractionState: manual` → generated symbols). The ExtensionUI toast catalog is separate (explicit-key style).
- **Copy review belongs before localization** — editing English after translating ripples to every locale. When an English change does land, update all locales in the same commit (or mark them stale for re-review).
- Run the `copywriting` skill for new conversion surfaces; run `asc-metadata` for the App Store listing; this guide is the in-app standard both defer to.
