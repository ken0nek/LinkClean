# LinkClean — From Link Cleaner to Clipboard Hub

> **Status: proposal / draft — 2026-06-17.** A multi-release product-expansion plan: keep the URL-cleaner wedge intact, **own the moment between copy and paste**, and grow LinkClean into a privacy-first clipboard hub. This is a strategy memo, not a feature spec. Each concrete feature gets its own [`docs/plans/`](../plans/) entry against the 8-point [SEED.md](../plans/SEED.md) checklist.
> **Builds on:** [iap-strategy.md](iap-strategy.md), [competitor-clean-links.md](competitor-clean-links.md), [growth-marketing.md](growth-marketing.md), [seo-content-plan.md](seo-content-plan.md), and the as-built [ARCHITECTURE.md](../../apps/ios/LinkClean/ARCHITECTURE.md).
> **In scope:** the iOS app. macOS / Web are noted as horizon plays but not planned here.
> **Out of scope:** copy / ASO / landing-page implications (those land in growth + seo-content docs once the feature shape is agreed).

---

## 0. TL;DR

1. **Today.** LinkClean owns one moment: the user has a URL and wants it clean. The Action extension, the Home Copy/Share hero, the App Intents / widget, and History all converge on that one job.
2. **Opportunity.** Every share-extension invocation and every clean already routes through us. If we let users *organize, tag, find, and re-use* what flowed past — not just URLs, but anything copyable — we turn a single-purpose utility into a daily-driver **clipboard hub** without abandoning the wedge.
3. **The path.** Three releases (≈ 1.2 → 1.4) extend History into a clipboard archive, add organization (tag/pin/star/folder), and reframe templates as snippets. A fourth release (≈ 2.0) adds a keyboard extension. Sync (CloudKit, Pro) follows when the local product is proven.
4. **The Pro pitch sharpens.** Free still does the core verb (clean a link). Pro stops being "clean two parameters" and becomes "you live in your clipboard, and we make it intelligent and persistent." That's a $4.99 you can defend without raising it.
5. **The risk to manage.** Identity drift ("LinkClean" doesn't say "clipboard") and the iOS clipboard-permission UX. We address both — not by rebranding, but by sequencing.

The recommended next step is in [§14](#14-recommended-next-step-the-12-shape).

---

## 1. The pivot in one sentence

> **From: "the app you open when a URL is dirty." To: "the app that already has whatever you copied, in the shape you'll want it."**

The verb stays the same — *clean*. The object expands: from "a tracker-laden URL" to "anything that passed through your hands today." The wedge we already won (privacy-first, on-device, format-aware) is the wedge a clipboard hub needs. Competitors that *start* as clipboard managers can't easily add link intelligence; we already have it.

---

## 2. Why now

### 2.1 We already own the moment

Six surfaces feed the same engine today (see [ARCHITECTURE.md](../../apps/ios/LinkClean/ARCHITECTURE.md)):

| Surface | What lands here | Code |
|---|---|---|
| **Home** Copy/Share hero | Pasted URL (one tap) | `apps/ios/LinkClean/LinkClean/Features/Home/` |
| **Action extension** | Share-sheet "Clean URL" | `LinkCleanKit/Sources/LinkCleanExtensionUI/ActionPipeline.swift` |
| **App Intents** (S1) | `CleanClipboardIntent` from Shortcuts / Spotlight | `LinkCleanIntents/` |
| **Widget / Control Center** | Tap → clean clipboard | `LinkCleanWidget/` |
| **QR** (1.1.0) | Scanned / generated link | `apps/ios/LinkClean/LinkClean/Features/QR/` |
| **History** | Persisted result of any of the above | `LinkCleanKit/Sources/LinkCleanData/HistoryStore.swift` |

Every successful clean lands in `HistoryStore`. If a user has internalized "go to LinkClean before pasting," **the funnel is already built** — the History list is, in effect, "the things you cared about today." We're just not treating it that way.

### 2.2 We already have the infrastructure to extend it

- **Persistence.** `HistoryStore` (SwiftData, App Group, both `input` *and* `output`) already stores the raw + cleaned forms. The memory note [`history-before-after-backlog`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/history-before-after-backlog.md) flags this as "dark data we don't surface."
- **On-device intelligence.** Foundation Models is wired in production (`@Generable nonisolated` advisor on Home — see [`parameter-advisor-aiA`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/parameter-advisor-aiA.md)) and `TrackerHeuristic` in Core. Categorizing arbitrary clipboard content is a natural extension.
- **Templates.** `TemplateRenderer` + `LinkTemplate` (Core), `TemplateStore` (Data), `TemplateOutputStrategy` + in-extension picker (ExtensionUI) all shipped in 1.1.0 ([`copy-as-you-want-built`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/copy-as-you-want-built.md)). Snippets are templates with no URL substitution — almost free.
- **Analytics.** `AnalyticsEvent` already slices every clean by `surface` ([`s1-app-intents`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/s1-app-intents.md), [`analytics-architecture`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/analytics-architecture.md)) — surface mix and adoption are already legible.
- **Monetization.** StoreKit 2, one entitlement, `ProGate` (1 rule / 7-day window). No subscription mess. Adding new Pro lines is cheap ([`iap-storekit2`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/iap-storekit2.md)).

We can ship Phase 1 *almost entirely* by reshaping data we already write.

### 2.3 Competitive window

[`competitor-clean-links.md`](competitor-clean-links.md) §6 already flagged this: Clean Links (the free portfolio-halo rival) is broadening into QR safety, Safari auto-strip, lite sync, and a "clipboard watcher." They are moving in this direction too — but as a free side-project of *Private LLM*, not as a primary product. They will not ship a keyboard extension, deep tagging, or a snippet library. The window to claim **"the clipboard manager that understands what you're copying"** is open and ours to take.

---

## 3. The vision — clipboard hub, not clipboard manager

Three sentences that have to be simultaneously true at the end of the arc:

1. **Free still wins** the user's daily copy/clean job, no nags, no claw-back.
2. **Pro buys depth, not the core verb** — unlimited history, sync, AI organization, snippet library, advanced templates, keyboard ext.
3. **Nothing leaves the device** without an explicit user gesture, and the audit trail in [`analytics-architecture`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/analytics-architecture.md) §9 still holds: no clipboard *content* ever, no host without consent, ever.

The shape we're building toward:

```
┌─────────────── LinkClean ───────────────┐
│  HOME    HISTORY    SNIPPETS    STATS   │  ← Tab structure expands
│                                         │
│  History tab:                           │
│   ┌─────────────────────────────────┐   │
│   │  All  •  Links  •  Text  •  ⭐  │   │ ← faceted filtering
│   │  🔎 Search by host or content   │   │
│   └─────────────────────────────────┘   │
│   • https://nyt.com/… (cleaned)  ⭐ 📎  │
│   • Phone: +1 555 … (auto-detected)     │
│   • Snippet expanded: "address"         │
│   • https://t.co/… → nyt.com (E4)       │
└─────────────────────────────────────────┘
```

Plus a system-level **keyboard extension** that lets the user paste from this archive into any app.

---

## 4. The data flywheel

If the thesis is right and users deepen adoption, we collect a unique on-device dataset — *and a unique aggregate, in TelemetryDeck:*

| Signal (on-device) | What we learn (aggregate, no content) | Powers |
|---|---|---|
| Surface mix per clean | Where users *actually* live | Surface investment priorities (S1 already gave us a baseline) |
| Categories of copied items | Are users sharing links, addresses, codes, prose? | What to build next; defaults |
| Template usage by format | Which output shapes win | Defaults; AI title-format pairing ([001-ai-c-smart-titles.md](../plans/001-ai-c-smart-titles.md)) |
| Snippet expansion frequency | How sticky the snippet library is | Whether keyboard ext is justified |
| Pin / star rate | Which copies users return to | Smart suggestions; Recents |
| FM categorization confidence | When the model is unsure | Better prompts; targeted model fine-tunes |

Crucially, this is **all metadata, never content** — same posture as today's `host` + `surface` + `unwrapped` slices. The privacy story scales.

Two product opportunities this opens that we can't reach today:

1. **Smart defaults.** "We notice you copy GitHub PR URLs every day at 9am — want a quick action?"  Surfaced as a one-tap suggestion. App Intents donation is the carrier.
2. **Per-tracker / per-category glossary pages** on `linkclean.app/` (see [seo-content-plan.md](seo-content-plan.md)) get their **most popular** anchors directly from aggregate data — a virtuous SEO/LLMO loop.

---

## 5. Phased roadmap

Five phases, each releasable independently. Each row is a candidate `docs/plans/00N-*.md` entry.

| Phase | Approx release | Headline | Adds | Pro hook |
|---|---|---|---|---|
| **1** Capture | **1.2** | "History gets a memory" | All share-extension invocations → History (not just URLs); auto-type-detection; History becomes a real archive | Unlimited history (Free = 30 days / 100 items) |
| **2** Organize | **1.3** | Tag, pin, star, folder | Manual tagging + smart inbox via FM; pin/star at top; folders; faceted search | Unlimited tags + folders; FM auto-categorization |
| **3** Snippets | **1.4** | Reusable text, not just URL formats | Templates engine generalized to "Snippets" (text + variables) | Snippet library size; advanced variables; team snippets (deferred) |
| **4** Keyboard | **2.0** | LinkClean as a system keyboard | Keyboard extension: paste-from-history + snippet expand + clean-on-paste | Keyboard ext is Pro (it's the moat) |
| **5** Sync | **2.x** | Across-device clipboard hub | CloudKit, end-to-end, private database | Sync is Pro; one-tap restore on new device |

Order matters: each phase **proves the next** with TelemetryDeck signal. If Phase 1 shows users *don't* engage with non-URL items, Phase 2 retunes (or stops). The roadmap is staged, not committed.

---

## 6. Feature deep-dives

### 6.1 Phase 1 — Capture (the spine)

The cheapest, highest-information move. Reshape `HistoryStore` to be type-aware:

```swift
enum CapturedItemKind: String, Codable, Sendable {
    case link                 // cleaned URL (today's only kind)
    case shortLink            // unwrapped (E4)
    case plainText            // anything else from share extension
    case qr                   // scanned/generated
    case snippetExpansion     // (Phase 3)
}

// HistoryEntry already stores input + output; add kind + (optional) detectedTypes
```

Concrete changes:
- `ActionPipeline.complete` widens to accept non-URL payloads (text-only path already exists for the share extension). Today that path bails; we'd persist the text instead.
- `HistoryStore` schema migration: `kind: CapturedItemKind = .link` (default = back-fill).
- History UI gets a segmented control: `All | Links | Text | ⭐`. Search across `input` and `output` (closes the [`history-before-after-backlog`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/history-before-after-backlog.md) note in one shot — that backlog was the right idea waiting for the right framing).
- Free vs Pro: Free = **30 days / 100 items rolling**. Pro = unlimited. This honors [`iap-storekit2`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/iap-storekit2.md) rule 3 ("gate addition/accumulation, never the operation") — every capture still runs free.
- Analytics: `History.Item.captured(kind:)`, `History.Item.retrieved(kindFromCopy:)`, `History.Search.performed(hits:)`.

**Why this first.** It's the smallest move that *proves the thesis*. If user behavior says "I never look at non-link items," we know before investing in tagging or a keyboard. If they do — we have a flywheel.

### 6.2 Phase 2 — Tagging / categorization

The user's #1 feature. Two layers:

1. **Smart inbox.** FM (`@Generable` struct) categorizes new items on capture. Categories: `link`, `address`, `phone`, `email`, `code`, `note`, `credential-looking` (auto-redact preview, never persist content elsewhere). Confidence-thresholded — below threshold = `uncategorized` (visible to user).
2. **Manual tags.** Lightweight string set per item. Free-form. Top-N tag list lives in `TagStore` (App Group SwiftData).

UX:
- Long-press an item → "Add tag…"
- Tag chip strip below the segmented control; tap to filter.
- Tag rename / merge.

Where FM lives: app target only in v1 (extensions/widget/keyboard are too tight; same call we made on the Home advisor — see [`parameter-advisor-aiA`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/parameter-advisor-aiA.md) and [`plans-seed-guideline`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/plans-seed-guideline.md) for the FM-in-extensions verdict).

Free vs Pro: Free = manual tags, up to 3. Pro = unlimited tags + FM auto-categorization + smart inbox. Trigger: "Auto-organize my clipboard" on the paywall.

Analytics: `History.Tag.applied(source: manual|auto)`, `History.Tag.suggested(confidence:)`, `History.Tag.acceptedAuto(category:)`.

### 6.3 Phase 2 — Pin, star, folder

The user's #2. Simpler than tags:

- **Star** = boolean per item. ⭐ filter pin in the segmented control. Free.
- **Pin** = sticky-to-top boolean. Different from star: pin is "show me this at the top of the list always"; star is "I love this." Free, capped at 3 pinned (Pro = unlimited).
- **Folder** = optional one-to-many (an item belongs to zero or one folder). Why "one folder" not "many" → matches mental model and keeps the data model trivial. Heavy users can layer tags on top. Pro feature (free users get one default "Pinned" pseudo-folder).

Implementation: three nullable columns on `HistoryEntry`. No new tables. No schema acrobatics.

### 6.4 Phase 3 — Snippets (templates, generalized)

We already have a template engine ([`copy-as-you-want-built`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/copy-as-you-want-built.md)): `LinkTemplate` with `{link}`, `{title}`, `{host}`, `{path}`, `{query}`. The generalization:

```swift
// Core
public protocol Snippet: Sendable, Codable {
    var id: UUID { get }
    var name: String { get }
    var body: String { get }                // contains {variables}
    var variables: [SnippetVariable] { get }
}

public enum SnippetVariable: Sendable, Codable {
    case clipboard               // current pasteboard
    case link                    // last cleaned link (history.first(where: .link))
    case title                   // ai-C title for the link (if available)
    case selection               // (keyboard ext only; Phase 4)
    case date(format: String)
    case custom(prompt: String)  // ask at expansion time
}
```

Templates become a *kind* of snippet (URL-bound). Plain-text snippets ("my address", "my company tax ID format", a stock email response) are first-class.

UX:
- New Snippets tab (or section under Settings → Customize).
- Each snippet has a trigger string (e.g. `;addr`) — Phase 4 lights this up in the keyboard.
- In-app: "Copy snippet" button.
- In Action extension: snippet appears in the **Copy as…** picker (`TemplateOutputStrategy` already does this for URL templates).

Free vs Pro: Free = 3 snippets, no variables. Pro = unlimited + variables + trigger expansion.

### 6.5 Phase 4 — Keyboard extension (the moat)

The user's #3, and the bet that makes the platform sticky.

What it does:
- Tap LinkClean key → bottom strip surfaces (a) **recent history** (top 10, searchable), (b) **starred / pinned**, (c) **snippets** (triggerable by `;name`).
- Tap an item → it pastes.
- Snippet variables resolve at paste time (`{clipboard}`, `{date}`, etc.).
- **Bonus magic:** "Clean as you paste" — if the about-to-paste content is a URL, run `CleaningService` first. This is the single feature no competitor on iOS has.

iOS realities (these shape the design before any code):

- **Full Access prompt.** Required to access the App Group and pasteboard. Onboarding shows a clear "Why we need this" screen with the privacy claim (`docs/strategy/iap-strategy.md` style: same hardcoded honesty that worked for the IAP review-notes incident).
- **Memory.** Keyboard ext is ~50 MB. Same lifecycle profile as Action ext today. **No FM here.** Pre-categorized items only.
- **Network.** No. All ranking is local.
- **Latency.** Sub-100ms render. We can hit this; `HistoryStore` reads through App Group; pre-load top N on `viewDidLoad`.
- **Layout.** Floating strip above the system keyboard, *not* a replacement keyboard (avoids the "I have to switch to type a letter" friction).

Why Pro: keyboard extension is the daily-driver hook. If we gate it well — generous Free preview (top 3 items, no snippets) — it's the conversion event. See §7 for the full re-cut.

Risk: keyboard extensions are a long Apple-review path. Plan for one rejected build. The SEED.md §2 / §8 verification points apply with extra weight: real-device usage in 3+ apps (Notes, Safari address bar, Mail compose).

### 6.6 Phase 5 — CloudKit sync (Pro)

Defer until the local product is loved. When it ships:

- CloudKit private database, user's own iCloud. We never see content.
- Sync scope: history (opt-in), snippets, tags. **Not** the keyboard extension's local prefs.
- Conflict resolution: last-write-wins for tags / star / pin; never auto-delete cross-device.
- Pro-only. Trigger: "Your clipboard, on every device."

Why this order: sync is high-trust and high-stakes. We earn it by being indispensable locally first; we don't lead with it.

### 6.7 Phase 6 — Shortcuts / automation (ongoing)

App Intents we'd add as we go:
- `PasteAndCleanIntent` — read pasteboard, clean, write back.
- `ExpandSnippetIntent(name: String) -> String` — programmatic snippet expansion.
- `SearchHistoryIntent(query: String) -> [HistoryItem]`.
- Donations on every retrieval, so Siri / Spotlight surface frequent items.

No phase milestone — these accrete as each phase ships. The cost per intent is small once the operation exists.

---

## 7. Free vs Pro — re-cut

Following [iap-strategy.md](iap-strategy.md) §6 rule 3 (*"gate addition / accumulation, never the operation"*). Today's rule of "Pro after 1 catalog rule / 7-day window" stays — it's how Pro pays for *cleaning*. The new lines pay for *clipboard hub*.

| Capability | Free | Pro |
|---|---|---|
| Clean a link (any surface) | ✅ unlimited | ✅ unlimited |
| Capture to history | ✅ unlimited within window | ✅ unlimited |
| History retention | **30 days / 100 items rolling** | unlimited |
| Search history | ✅ | ✅ |
| Tag / star / pin (manual) | ✅ up to **3 tags · 3 pins** | unlimited |
| Folders | — | ✅ |
| FM auto-categorization / smart inbox | — | ✅ |
| Snippets | ✅ **3 snippets, no variables** | unlimited + variables |
| Keyboard extension | **preview**: top 3 recents only, no snippets | ✅ full |
| CloudKit sync | — | ✅ |
| Existing Pro: custom catalog params | unchanged | unchanged |
| Existing Pro: custom Copy Formats (3+) | unchanged | unchanged |

Pricing stays at **$4.99 base** (regional $2.99 / $1.99), one entitlement, Family Sharing OFF — per [`iap-storekit2`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/iap-storekit2.md). No raise needed; the *value* per dollar grows. **No subscription**, ever — keeps the LinkClean differentiation against Paste ($14.99/year), Pastebot, and the rest.

New paywall benefit rows (every locale, with translator comments — see [`copy-style.md`](../product/copy-style.md)):
- `paywall.benefit.history.unlimited` — "Your full clipboard history, forever."
- `paywall.benefit.organize` — "Tag, pin, star, and find anything."
- `paywall.benefit.snippets` — "Reusable text snippets with variables."
- `paywall.benefit.keyboard` — "Paste from your history anywhere." (Phase 4)
- `paywall.benefit.sync` — "Sync across your devices, end-to-end." (Phase 5)

New paywall triggers: `historyCap`, `tagCap`, `snippetCap`, `keyboardUnlock`, `syncEnable`.

---

## 8. Privacy posture — non-negotiables

This expansion *can* compromise the privacy claim if done wrong. The rules:

1. **Content never leaves the device.** Period. No analytics event ever carries clipboard text, snippet body, or tag content. (Today's host-tracking declaration stays as-is — it's metadata.)
2. **FM categorization runs on-device.** This is the entire reason FM is in the stack already ([`foundation-models-integration`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/foundation-models-integration.md)).
3. **CloudKit private database** for sync — encrypted, user's iCloud, opt-in per data type, never auto-on.
4. **Background clipboard monitoring is OFF.** (See §9 — iOS won't really let us anyway.)
5. **Credential-looking content auto-redacts** in previews and shows a one-tap "Don't keep this" button. Pattern from 1Password / Apple Passwords' on-paste UX. Detection heuristic = on-device regex + FM low-confidence vote.
6. **Keyboard ext "Full Access" onboarding is honest.** No dark patterns. We tell the user *exactly* what changes (pasteboard access; App Group reads; no network).
7. **Audit trail.** Every new analytics event ships with a `docs/plans/analytics.md` row. The nutrition label and privacy policy update in lockstep — same discipline as 1.0.0 (see the closing entries on the [`iap-storekit2`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/iap-storekit2.md) memory).

If a feature requires breaking one of these, **the feature doesn't ship.**

---

## 9. iOS clipboard reality check

A handful of iOS constraints to acknowledge up front — they shape what is possible:

| Constraint | Implication for the plan |
|---|---|
| iOS shows a banner on every pasteboard read since 14 | We never read silently. Every read is in response to a user gesture (open app, open share-ext, tap keyboard-ext key). |
| `PasteButton` since iOS 16 reads without a banner, but **only inside its own tap** | Use `PasteButton` for the Home Copy hero. Already aligned. |
| **Background clipboard monitoring is effectively impossible** | "Auto-capture every copy" is not on the table on iOS. The keyboard extension is the closest thing to a watcher, and even it only sees the clipboard when active. |
| Keyboard extensions need **Full Access** to reach App Group + pasteboard | Onboarding flow has to sell this. Plan a single "What changes" screen + a deep-link back to Settings. |
| Action extensions are short-lived (`ActionPipeline` already manages this) | Phase 1's "capture all share-ext text" is fine; Phase 4 keyboard runs at full freshness budget. |
| App Group storage already shared by app + extensions + widget + intents | No new infra to ship for Phase 1–3. Phase 4 keyboard joins the same group. |
| FM lifetime in extensions ≠ app — Tested in widget already | **Keep FM app-only** until proven otherwise. Phase 2 categorization runs on capture *in the app* (post-fact for items captured in extensions). |

None of these are dealbreakers. All shape the design.

---

## 10. Competitive landscape

| Product | Platform | Price | Strength | What we beat them on |
|---|---|---|---|---|
| **Paste** | iOS / macOS | $14.99 / year | Mature, cross-device, deep history | One-time, on-device AI, link-native cleaning + tags + snippets in one |
| **Pastebot** | macOS only | $14.99 one-time | macOS-native, scriptable | We ship iOS-first; we have a keyboard ext path |
| **Maccy** | macOS only | Free (OSS) | Free, simple | iOS-first; AI categorization |
| **Drafts** | iOS | $2/mo or $20/yr | Text-first power tool | We're not text-first; clipboard hub > scratchpad for our user |
| **Yoink** | iOS / macOS | $9 / $7 | Drag-and-drop staging | Different verb (stage) vs ours (clean + reuse) |
| **Clean Links** ([competitor](competitor-clean-links.md)) | iOS | Free | Broader URL cleaner, has a "clipboard watcher" feature | Tags, snippets, keyboard ext, depth of history — all the things they will not ship as a halo project |

The iOS clipboard-manager market is **not** mature. Paste leads but charges subscription. Pastebot is Mac-only. We have an opening — *and* we don't even have to rebrand to take it. The "Link" wedge stays the entry door; the hub is what users discover after they install.

---

## 11. Risks & counterarguments

| Risk | Mitigation |
|---|---|
| **Identity drift.** "LinkClean" doesn't say "clipboard manager." | Don't rebrand. Reposition copy gradually — Phase 1 says "Your cleaned links, organized." Phase 3 introduces "Snippets." Phase 4 (keyboard) is when ASC subtitle widens. The brand absorbs the surface; this is how Bear, Drafts, 1Password all expanded. |
| **Scope creep diluting the core verb.** | The core verb (clean a link) stays Free, present on Home, and is the only thing on the QR/widget/intent surfaces. The clipboard surfaces live in History / Snippets / Keyboard — additive, never blocking. |
| **Apple review on keyboard ext.** | Plan 2 weeks slack, real-device QA across 5+ apps, honest "Why Full Access" copy. Submit a TestFlight build well before the App Store submission. Have a privacy-policy update queued. |
| **FM categorization being wrong.** | Confidence threshold + user-correctable tag + every wrong category recorded (anonymous count, no content) as a signal to refine prompts. Pattern proven by [`parameter-advisor-aiA`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/parameter-advisor-aiA.md). |
| **CloudKit sync rabbit hole.** | Don't ship until Phase 1–4 prove demand. When we do, scope it: private DB only, no sharing, no public records, no schema versioning beyond `versionedSchema` we already use. |
| **Users get angry about a $4.99 app "becoming a subscription."** | We do not. Family Sharing stays OFF, one entitlement, every line above respects the no-claw-back rule from iap §6. The pitch is "you bought the cleaner, the cleaner grew." |
| **Clean Links shipping the same features for free.** | They likely won't (portfolio halo for *Private LLM*). If they do, we still have keyboard ext + snippet library + paid distribution muscle they decline to flex. Re-verify quarterly per [`competitor-clean-links`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/competitor-clean-links.md) §13.3. |
| **Telemetry expanding faster than user understanding.** | Every new event gets the §9 audit pass + a nutrition-label revisit. Privacy policy domain disclosure pattern from 1.0.0 (the Jun 10 update) is the template. |

---

## 12. Naming / brand question

**Do we rebrand?** No.

Reasons:
1. **"LinkClean" is now ranked** — ASO, organic search, and brand search from 1.0/1.1 are accruing. Throwing that away to be "Clipd" or "Pastry" is expensive and unnecessary.
2. **The category absorbs the brand** when the brand is strong. Bear is a notes app named after an animal. Drafts is a "scratchpad" that grew into automation. 1Password started as a password manager and now does passkeys, MFA, dev secrets, SSH keys — the name hasn't budged.
3. **"Link" is still the highest-volume verb on the home screen.** The clipboard surfaces are additive; cleaning is still the front door.
4. **ASC subtitle / keywords can widen** without renaming. Phase-by-phase ASO plan lives in [asc-metadata](../release/app-store-metadata.md) and the [app-store-optimization](../../.claude/skills/app-store-optimization/) skill. ja/de localization decisions ride along — translator comments document the widening intent.

What *does* shift over time:
- Subtitle. v1.x: "Clean tracking parameters." v1.3+: "Clean links · keep what matters." v2.0+: maybe "Your link & clipboard hub."
- Promotional text per release.
- App icon **does not change** without a real reason — that's a brand-recognition cost we don't need to pay.

---

## 13. Open questions for Ken

Worth aligning on before the Phase 1 plan is written:

1. **Phase 1 scope — does "non-URL captures from Action ext" feel on-brand?** Or do we want Phase 1 to stay URL-only and use the room to add tags/star to existing History first?
2. **Phase 2 ordering — tags before pin/star, or in parallel?** Pin/star is cheap; tags need FM + UI investment. Could split into 1.3a / 1.3b.
3. **Pro re-cut deltas — is "30 days / 100 items" the right Free retention?** Paste gives 7 days free; we can be more generous since we're not subscription. 100 items might be too few for active users.
4. **Keyboard ext as Pro? Or top-tier Free with sync gated?** Cleaner story for Pro = keyboard. Cleaner story for retention = free keyboard, Pro sync. Either works; depends on which is the bigger moat.
5. **CloudKit timing — 2.x or never?** If 5% of Pro buyers use sync, we're paying CloudKit cost for vanity. Look at install-on-multiple-devices ratio post-Phase 4 before committing.
6. **macOS Catalyst — defer or roadmap?** Phase 4's keyboard ext doesn't translate to macOS, but the rest does. Pastebot's exit (and Maccy being free OSS) leaves room — but it's a different distribution muscle.
7. **Telemetry coverage — when do we add `History.Item.captured`?** Right now we don't separate "URL captured" from "any item captured" — Phase 1 needs the event, but if we ship the event *first* (1.2 dot release) we get a baseline. Cheap.

These should be answered in conversation, not by me guessing.

---

## 14. Recommended next step — the 1.2 shape

The smallest thing that proves (or kills) the thesis:

**1.2 = History, but as an archive.** Concretely:

1. Extend `HistoryStore` with `kind: CapturedItemKind` (default `.link`). One SwiftData migration.
2. `ActionPipeline` widens to persist plain-text share-ext payloads under `kind = .plainText`. UI unchanged in the extension.
3. New History segmented control: `All | Links | Text | ⭐`. Search bar (over `input` + `output` + tag — the [`history-before-after-backlog`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/history-before-after-backlog.md) work folds in here).
4. Star (free, no cap) and Pin (free, capped at 3).
5. Pro: unlimited retention (Free = 30 days / 100 items, configurable via `RetentionPolicy` so we can A/B it).
6. Analytics: `History.Item.captured(kind:)`, `History.Item.starred`, `History.Item.pinned`, `History.Retention.trimmed(count:)`.
7. Paywall benefit row + trigger `historyCap`.
8. No FM yet. No tags yet. No snippets yet. **Just the spine.**

That is one `docs/plans/003-history-as-archive.md` against the [SEED.md](../plans/SEED.md) 8-point checklist. Ship it, watch the TelemetryDeck signal for 4–6 weeks, decide whether to lean into Phase 2 (tag) or pull a different lever.

If Phase 1 lands and the data says users *do* engage with non-link items — start Phase 2 (smart inbox + tags). If they don't — we still got "search History" and the [`history-before-after-backlog`](../../../../.claude/projects/-Users-ken0nek-Documents-projects-LinkClean/memory/history-before-after-backlog.md) closed, and we know the URL wedge is the only wedge. Either answer is product gold.

---

## Appendix A — Cross-document update list (if approved)

If this proposal is greenlit, the following docs need updates *before* the first feature plan is written:

- [`iap-strategy.md`](iap-strategy.md) §1–§3 — Pro story widens beyond cleaning.
- [`competitor-clean-links.md`](competitor-clean-links.md) §6 — confirm Clean Links has not added a keyboard ext or snippet library.
- [`growth-marketing.md`](growth-marketing.md) §3 — three wedges become four (productivity / privacy / polish / **hub**).
- [`seo-content-plan.md`](seo-content-plan.md) — add a "clipboard manager iOS" cluster as Wave-3+.
- [`kpis.md`](kpis.md) — north star unchanged (exports / WAU), add **captures / WAU** + **retention beyond Day-7** as Phase 1 success metrics.
- [`ARCHITECTURE.md`](../../apps/ios/LinkClean/ARCHITECTURE.md) — when Phase 1 ships, document `CapturedItemKind` and the widened `ActionPipeline`.

## Appendix B — Per-phase feature-plan checklist

Each phase needs its own `docs/plans/00N-*.md` following [SEED.md](../plans/SEED.md). Pre-filled headers below — for whichever phase we agree to start:

```
# 003 — History as Archive (Phase 1)

1. Strategy fit — *history-depth* wedge; foundation for hub.
2. Surfaces — app History tab; Action ext widens to persist text.
3. Free vs Pro — retention cap (Free 30d/100 items); paywall trigger `historyCap`.
4. Foundation Models — none in this phase.
5. Privacy — no content telemetry; nutrition label unchanged.
6. Analytics — History.Item.captured(kind:), …
7. Architecture — CapturedItemKind enum in Core; HistoryStore migration; ActionPipeline.complete widening.
8. Verification — kit-sim + app sim lanes; manual share-ext text capture in Notes/Mail/Safari.
```

---

*Draft for review. No code or app metadata changes until §13 questions are answered and a phase is committed.*
