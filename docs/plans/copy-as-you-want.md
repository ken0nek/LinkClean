# Plan: "Copy as you want" — user-defined link formats

> **Status: IMPLEMENTED — 2026-06-14 (v1 + v2 in-extension picker built; action display name resolved to "Copy link as…").** Reframes the planned "Copy as HTML / Title+URL" Pro beat ([growth-roadmap.md](../product/growth-roadmap.md) §8 P1, [iap-strategy.md](../strategy/iap-strategy.md) §6) as a **template engine** instead of a fixed set of formats. **Locked 2026-06-13:** Option A (evolve `LinkCleanMarkdownAction`, no new target) · free line = Clean + Markdown free (rest + custom = Pro) · single-brace `{token}`. Scope: the template language + identifiers, the presets, the free/Pro publishing strategy (esp. how gating interacts with action extensions), and a technical-feasibility + implementation plan.
>
> **Built 2026-06-14 (v1):** Core `TemplateToken`/`LinkTemplate`/`TemplateContext`/`TemplateRenderer` (+ 8 presets, fast-lane tested); `LinkCleanData.TemplateStore` (App Group blob, `resolveSelected(tier:)` fail-closed fallback, tested); `LinkCleanExtensionUI.TemplateOutputStrategy` (folds `MarkdownLinkStrategy`, which is **retired**) wired into `LinkCleanMarkdownAction`; in-app **Copy Formats** editor (`CopyFormatsView`/`ViewModel` + `CopyFormatEditorView`, live preview + token chips + `formatPicker` paywall gate) reached from Settings → Cleaning; `TemplateStore` threaded through `AppDependencies`; en/ja/de strings added. Analytics: `Action.Markdown.*` → `Action.Format.succeeded(preset,changed)`/`failed`; the reserved `PaywallTrigger.formatPicker` is now fired (taxonomy review still deferred to `analytics-audit`; `docs/plans/analytics.md` §7 lists the old `Action.Markdown.*` names → drift to reconcile there). Verified: fast lane 254 green, iOS kit objects emitted, app target type-checks clean; **`actool`/app-icon thinning unrunnable locally (no iOS 26.5 sim runtime) and the ExtensionUI sim-lane `TemplateOutputStrategy` tests are written but unrun.**
> **Builds on:** the as-built extension architecture ([ARCHITECTURE.md](../../ARCHITECTURE.md) — `ActionPipeline` + `ActionOutputStrategy`), `EntitlementStore` (the App Group entitlement snapshot), `MarkdownFormatter` / `LinkMetadataService`, `CleanOutcome`. Honors the standing IAP rules (iap §6/§9/§11/§12): never gate the core action, never claw back, gate *addition* not *operation*, **no paywalls in extensions**.
> **Sources:** codebase audit 2026-06-13 — **confirmed** the reuse targets exist: `LinkCleanMarkdownAction/ActionViewController.swift` is a 2-line strategy config already carrying the App Group + signing + a `curlybraces-padded-1024.png` icon; `EntitlementStore` (Data, `nonisolated`, fail-closed to `.free`), `Entitlement` / `ProGate` / `PaywallTrigger` (Core), `AppGroup.identifier = "group.com.ken0nek.LinkClean"`, `MarkdownFormatter` / `LinkMetadataService`, and the `ActionOutputStrategy` seam (`CleanLinkStrategy` / `MarkdownLinkStrategy`).

---

## 1. Thesis — why a template engine, not "Copy as HTML"

Ken's instinct is right: **"Copy as HTML" doesn't scale.** Each fixed format is a new `ActionOutputStrategy` (and possibly a new extension target). Markdown, HTML, Title+URL, Slack, a citation style… is an open-ended list, and every addition is code + a target + a paywall decision.

A **template** subsumes all of them. The user writes a format string with swappable identifiers — `[{title}]({link})`, `<a href="{link}">{title}</a>`, `{title}: {link}` — and one engine renders any of them. The architecture already anticipated this: [ARCHITECTURE.md](../../ARCHITECTURE.md) (proposal P5) notes a new format should be "a ~20-line strategy"; we go one step further and make it **a ~0-line strategy** — a single `TemplateOutputStrategy` parameterized by the user's template. `CleanLinkStrategy` (plain URL) and `MarkdownLinkStrategy` become *presets* of that one strategy.

This is a strictly higher-altitude design: infinite formats, one code path, one test surface, one paywall decision.

---

## 2. The template language

### 2.1 Syntax — `{token}` (single brace — **decided**)

`{title}: {link}` over `{{title}}: {{link}}`. Rationale:

- **Friendlier to type and read** for a non-technical audience; the PKM/notes crowd already reads `{}` as a placeholder.
- **Unknown tokens stay literal.** `{foo}` (not a known identifier) renders as the literal text `{foo}` — forgiving, no error state, and it doubles as the escape story for the rare case someone wants literal braces (a recognized token is the only thing substituted).
- Double-brace's only advantage is avoiding collision with literal `{`, which is vanishingly rare in link formatting. If we later find collisions in practice, `{{` → literal `{` is a trivial additive escape.

Newlines: the template editor is a multi-line field, so a literal newline in the template is a newline in the output (no `\n` token needed). A `{newline}`/`{tab}` token is a cheap convenience if testing shows single-line editors are friendlier.

### 2.2 Identifier kinds

The full proposed set (Ken's title/link/date + more). **Sync** tokens are instant; **async** tokens require the `LinkMetadataService` (LPMetadata) fetch already used by the Markdown action — a latency and process-lifetime cost in the extension (§5).

| Token | Meaning | Source | Cost | Example |
|---|---|---|---|---|
| `{link}` | the **cleaned** URL | `CleanOutcome.cleaned` | sync | `https://youtube.com/watch?v=…` |
| `{title}` | page title | `LinkMetadataService` / Safari JS title | **async** | `Big Buck Bunny` |
| `{host}` | site host | `URLCleaner.ruleHost` / URL | sync | `youtube.com` |
| `{date}` | today's date (localized, configurable style) | injected clock | sync | `2026-06-13` |
| `{time}` | current time | injected clock | sync | `14:32` |
| `{originalLink}` | the **uncleaned** URL (provenance) | `CleanOutcome.input` | sync | `…?utm_source=…` |
| `{removedCount}` | trackers removed — **on-brand** | `CleanOutcome.telemetry.removedCount` | sync | `3` |
| `{scheme}` `{path}` `{query}` | URL components (power users) | URL parse | sync | `https` / `/watch` |
| `{markdown}` | shorthand for `[{title}]({link})` | composed | async (uses title) | `[Big Buck Bunny](https://…)` |
| `{newline}` `{tab}` | layout (optional, if editor is single-line) | literal | sync | — |

Open: `{description}`/`{siteName}` if LPMetadata reliably provides them; `{selection}` (surrounding shared text) if we extract more than the first URL (ties to E3 multi-link, roadmap §3). Deferred until a token has a clear use.

**Design rule:** the editor flags which tokens are "instant" vs "needs a title lookup," so a user who wants zero latency can build a title-free template (`{link}`, `{host} — {date}`) and a power user can opt into `{title}`.

---

## 3. Presets

Ship a curated set so users get value without authoring anything — and so we have obvious names to market ("Copy as HTML, Markdown, …"). Each preset is just a built-in `LinkTemplate`.

| Preset | Template | Tier |
|---|---|---|
| **Clean link** | `{link}` | Free (this *is* `CleanLinkStrategy`) |
| **Markdown** | `[{title}]({link})` | **Free** (already shipped free — never claw back, iap §6) |
| **Title + URL** | `{title}\n{link}` | Pro |
| **HTML** | `<a href="{link}">{title}</a>` | Pro |
| **Quote w/ source** | `> {title}\n{link}` | Pro |
| **Citation** | `{title} — {host} ({date})` | Pro |
| **Slack/Discord** | `<{link}\|{title}>` | Pro |
| **Plain title** | `{title}` | Pro |

**Decided (2026-06-13):** free baseline = **Clean link + Markdown** (both already free today). Everything else, plus **any custom template**, is Pro. This keeps the free → Pro line exactly on iap §6's "gate addition, not operation": free users still get a fully working format action; Pro adds *more* formats and *custom* ones.

---

## 4. Pro publishing strategy (the extension-gating problem)

This is the crux of Ken's questions. Short version: **you can't hide the extension per-tier (Q1), but you *can* detect the tier inside it (Q2) — so gate creation in the app and let the extension honor only what the user is entitled to (Q3).**

### 4.1 Q1 — Can we hide the action extension for free users? **No.**

An action/share extension's appearance in the share sheet is governed by its **`NSExtensionActivationRule`** (which *content types* it accepts) — not by purchase state. The list is static per install and OS-cached; there is no API to show/hide an extension based on an IAP entitlement. (The user can manually toggle extensions in the share sheet's *Edit Actions*, but that's user-controlled, not tier-controlled.) So a "Pro-only extension that doesn't appear for free users" is **not possible**.

### 4.2 Q2 — Can we detect free vs Pro *inside* the extension? **Yes — already built (verified: `LinkCleanData/EntitlementStore.swift`).**

`EntitlementStore` exists precisely for this. Its doc comment: *"Written by the app target… and read by both the app and the action extensions. This allows the extensions to gate features without the overhead or network requirement of the full SDK."* It reads an App Group snapshot and **fails closed to `.free`** if missing/unknown.

```swift
let tier = EntitlementStore().current()   // .free / .pro — synchronous, no SDK, no network
```

Two layers of detection, in order of preference:
1. **`EntitlementStore` App Group snapshot** — synchronous, zero-latency, no StoreKit call. The app writes it on purchase/restore/launch. Right for the extension's hot path. Fail-closed to `.free` is the safe default.
2. **StoreKit `Transaction.currentEntitlements`** (authoritative, async) — StoreKit 2 works in extensions. Use only if snapshot staleness ever becomes a real problem (it shouldn't: the entitlement is a non-consumable that can't lapse, and the app refreshes the snapshot every launch). Not needed for v1.

So Q2 is solved by infrastructure that already shipped for exactly this purpose.

### 4.3 Q3 — How to limit free users (the policy, since detection works)

Because detection works, Ken's "if we can't detect…" branch is the *safety net*, not the mechanism. The governing principle:

> **Gate *creation* in the app (a paywall is fine there); never gate *execution* in the extension (no paywall — iap §9). The share flow stays sacred.**

Concretely, ranked:

1. **★ Gate authoring in-app; extension just executes (recommended).** Creating/saving a custom template, or selecting a Pro *preset* as the action's default, triggers the in-app paywall (`PaywallTrigger.copyFormat`). A free user therefore only ever *has* free formats configured, so the extension usually has nothing to refuse — it simply renders whatever the user legitimately set. No extension-side gate needed in the common case.
2. **Tier-aware fallback in the extension (the safety net).** The extension still checks `EntitlementStore`. If the active template is Pro but the tier is `.free` (edge cases: a stale snapshot, a future shared-template import, family-sharing churn), it **falls back to the free default** (Markdown, or Clean link) and optionally shows a *non-blocking* toast — *"Custom formats are a LinkClean Pro feature — open the app"* — which is an informational nudge, **not** a paywall (iap §9 forbids paywalls, not pointers). This is the deepened version of Ken's draft ("pin to clean for free users").
3. **Free presets vs Pro presets** (§3) — the line is "Clean + Markdown free, the rest Pro," enforced at *selection* time in the app.

Other ideas considered:
- *Single free format only (Ken's draft, literal):* works, but stingier than needed — Markdown is already free, so pinning free users to bare Clean link would be a clawback (iap §6). Prefer "free users keep Clean + Markdown."
- *Watermark / "cleaned with LinkClean" suffix for free:* **rejected** — the brand forbids adding anything to a link (same decision as V3's share-card-instead-of-suffix, roadmap §5).
- *Usage cap (N custom copies/day) for free:* rejected — artificial scarcity on an on-device operation (the AI-Link-Cleaner anti-pattern, iap §2).

**Net:** the paywall lives in the app's template editor; the extension reads the entitlement snapshot only as a fail-closed safety net and degrades gracefully to a free format — never blocks, never shows a paywall.

---

## 5. Technical possibility (Q4) — high; mostly composition

Every building block exists (audit-confirmed 2026-06-13):

| Need | Existing piece |
|---|---|
| The output seam | `ActionOutputStrategy` — a target is a 3-line strategy pick (`ActionViewController`) |
| Formatting precedent | `MarkdownFormatter.markdownLink(title:url:)` in Core |
| Title resolution | `LinkMetadataService` (LPMetadata, `timeout: 5`) + Safari JS-title path — already in `MarkdownLinkStrategy` |
| Tier detection in-extension | `EntitlementStore.current()` (App Group, fail-closed) |
| Token data | `CleanOutcome` carries cleaned/original/host/removedCount; URL parse for components |
| Cross-process template storage | App Group `UserDefaults` JSON blob — same pattern as `StatsStore`/`TrackingParameterStore` |
| The paywall | `ProGate` + `PaywallTrigger` + the existing paywall sheet |

The **template engine itself is trivial**: scan for `{token}`, substitute known tokens, leave unknown ones literal — a pure, `nonisolated` function in Core, exhaustively unit-tested in the fast macOS lane. No third-party templating dependency.

Constraints to respect (not blockers):
- **Title latency in-extension.** `{title}` triggers the LPMetadata fetch (already capped at 5 s in `MarkdownLinkStrategy`). Title-free templates stay instant. The renderer should fetch a title **only if the active template contains `{title}`/`{markdown}`** — don't pay the cost otherwise.
- **Rich HTML paste (optional).** The HTML preset produces HTML *source text* (`<a …>`), which is just a `String` — `PasteboardPayload.string` already covers it. True rich/formatted paste (drop the literal tag, paste a live link) would need an additional `public.html` pasteboard representation — a v2 nicety, out of scope for v1.
- **Extension process limits.** Short-lived, memory-bounded — already handled by the existing pipeline; the template render adds negligible cost.
- **Clock injection.** `{date}`/`{time}` read an injected clock, never `Date()` inline, so the renderer stays deterministically testable (mirrors the project's testability conventions).

---

## 6. Technical implementation (Q5)

Layered, dependency-direction-clean (Core → Data → ExtensionUI → target/app):

### 6.1 `LinkCleanCore` — the engine (fast-lane tested)
```swift
public enum TemplateToken: String, CaseIterable, Sendable {   // link, title, host, date, …
    case link, title, host, date, time, originalLink, removedCount, scheme, path, query, markdown
}

public struct LinkTemplate: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var format: String          // "[{title}]({link})"
    public var isBuiltin: Bool
    public var requiresPro: Bool        // preset tier; custom ⇒ true
    public var usesTitle: Bool { format.contains("{title}") || format.contains("{markdown}") }
}

public struct TemplateContext: Sendable {   // built from CleanOutcome (+ optional title, + clock)
    public let cleaned: String; public let original: String
    public let host: String; public let removedCount: Int
    public let title: String?; public let date: Date
}

public enum TemplateRenderer {
    public static func render(_ template: LinkTemplate, _ ctx: TemplateContext,
                              dateStyle: …) -> String   // pure substitution; unknown {x} → literal
}

public extension LinkTemplate { static let builtins: [LinkTemplate] = [ … ] }   // §3 presets
```

### 6.2 `LinkCleanData` — storage
```swift
public nonisolated struct TemplateStore: Sendable {   // App Group JSON blob, like StatsStore
    public func customTemplates() -> [LinkTemplate]
    public func upsert(_ t: LinkTemplate); public func delete(_ id: UUID)
    public var selectedTemplateID: UUID?   // the extension's default; settable in-app
    public func resolveSelected(tier: Entitlement) -> LinkTemplate   // Pro template + .free ⇒ free fallback
}
```
`resolveSelected(tier:)` centralizes the §4.3 fallback so both app preview and extension agree.

### 6.3 `LinkCleanExtensionUI` — the strategy
```swift
public struct TemplateOutputStrategy: ActionOutputStrategy {
    let templates: TemplateStore
    let entitlements: EntitlementStore
    let metadata: LinkMetadataService            // reused, timeout 5

    public var surface: String { "copyAction" }
    public func extract(from:) async -> ExtractedURL?   // URL + JS title (as MarkdownLinkStrategy)
    public func result(for outcome:, extracted:) async -> StrategyResult {
        let template = templates.resolveSelected(tier: entitlements.current())   // §4.3
        let title = template.usesTitle ? await resolveTitle(outcome, extracted) : nil   // pay latency only if needed
        let text = TemplateRenderer.render(template, TemplateContext(outcome, title: title, date: clock.now))
        return StrategyResult(payload: .init(.string(text)), successEvents: [ /* §6.6 */ ])
    }
}
```
`CleanLinkStrategy`/`MarkdownLinkStrategy` collapse into builtin templates of this one strategy (keep them as thin shims for the dedicated Clean action, or retire — §7).

### 6.4 The action target — **Option A (decided): evolve `LinkCleanMarkdownAction`**
The target is a 2-line config today (`override var strategy { MarkdownLinkStrategy() }`). Swap the strategy and rename the display name; Markdown becomes the free default preset:
```swift
class ActionViewController: ActionHostViewController {
    override var strategy: any ActionOutputStrategy { TemplateOutputStrategy(…) }   // was MarkdownLinkStrategy()
}
```
The target **already carries everything** (audit-confirmed): the App Group `group.com.ken0nek.LinkClean` in its `.entitlements`, signing, the `NSExtensionActivationRule` (web URLs + text) + the `Action.js` title path, and — fittingly — a `curlybraces-padded-1024.png` icon that already suits a `{token}` engine. **So there is no new target and no Xcode-GUI / ASC handoff** (§8). `LinkCleanAction` (Clean URL) stays the sacred, instant, free core action, untouched.

*Option B (a new `LinkCleanCopyAction` target) was rejected: it keeps Markdown separate at the cost of a full new-target handoff (App Group, entitlement, signing, icon, plist) for no user benefit.*

### 6.5 App UI — the template editor (where the paywall lives)
- A "Copy formats" screen (Settings): list presets + custom templates, a **live preview** against a sample dirty link, token-insertion chips, set-as-default. Creating/saving a custom template or choosing a Pro preset as default → `ProGate` check → paywall (`PaywallTrigger.copyFormat`). Reuses the existing paywall sheet. Mirror the `ManageParametersView`/advisor gate patterns already in the app.

### 6.6 Analytics
- New events (e.g. `Copy.Format.used(tier, preset|custom)`, `copyAction` surface in the surface-mix) — **taxonomy owned by the `analytics-audit` skill** (same deferral as the V3 card and the advisor). Note the paywall-trigger `copyFormat` for the funnel (iap §11 / kpis §6).

### 6.7 Tests
- Fast lane (Core): `TemplateRenderer` token coverage, unknown-token-literal, title-absent fallback, each builtin preset, `resolveSelected(tier:)` free-fallback. Data: `TemplateStore` round-trip in an App Group test suite (mirrors `StatsStoreTests`). ExtensionUI (sim lane): `TemplateOutputStrategy` payload for free vs Pro tiers.

---

## 7. Decisions & sequencing

**Resolved (2026-06-13):**
1. ✅ **Brace syntax** — single `{token}`; unknown tokens stay literal (`{{` → literal `{` only if a collision ever surfaces).
2. ✅ **Target shape** — **Option A**: evolve `LinkCleanMarkdownAction`; no new target (§6.4).
3. ✅ **Free preset set** — **Clean + Markdown free**; all other presets + any custom template = Pro (no clawback, iap §6).
4. ✅ **Old strategies** — keep `LinkCleanAction` / `CleanLinkStrategy` standalone (the core Clean action); fold `MarkdownLinkStrategy` into the engine as the free `Markdown` preset.

**Still open:**
- **Display name** — "Copy link as…" (default) vs a static "Copy Link" / "Format & Copy". The "…" implies a chooser, but v1 copies the *configured default* silently (no in-extension picker yet), so a static name may read truer. **Lean: "Copy link as…"** — confirm before the plist edit. (Stays English even with ja/de shipping — project convention.)
- **In-extension template picker** — ✅ **BUILT (v2, 2026-06-14).** Replaced the single "default" with an **active set** (`TemplateStore.activeTemplateIDs`/`resolveActive(tier:)`): 0 active → Markdown floor, 1 → silent copy, 2+ → a native action-sheet picker (`ActionPipeline.prepare`/`complete` split + `ActionOutputStrategy.choices()`; host shows the menu, renders the chosen format on tap). Editor rows are now **Active** toggles (free users toggle only the free formats; Pro/custom rows show a lock → paywall). Preset names localized in the ExtensionUI catalog for the picker.
- **Rich HTML pasteboard** — v1 = HTML *source* as a string (`PasteboardPayload.string` covers it); v2 = a real `public.html` representation for live-link paste.
- **More tokens** — `{description}` / `{siteName}` (if LPMetadata is reliable), `{selection}` (with E3 multi-link). Deferred until a token earns its place.

**Sequencing.** v1 = engine + presets + gated editor + the evolved action rendering the default template with tier-aware fallback. v2 = in-extension picker, more tokens, rich HTML paste. This **replaces the "Copy as HTML / Title+URL" line** in iap §6 / growth-roadmap §8 (the 1.2 first-real-Pro beat) with a more durable engine — update those docs when this is scheduled.

---

## 8. Handoffs — **none required (Option A)**

With Option A there is **no Xcode-GUI and no App Store Connect work.** Verified:

- **No new target / App Group / entitlement / signing / icon** — `LinkCleanMarkdownAction` already carries all of them (§6.4).
- **No new IAP product** — Pro is the single non-consumable already shipping; this is one more gate behind the same unlock.
- **Source auto-included** — Core / Data / ExtensionUI are SPM targets that glob their sources; the app target uses synchronized file groups, so new editor files join the target automatically. (Lone possible click: target membership for a new app file if synchronization misses it.)
- **Analytics in code** — I add the `PaywallTrigger.copyFormat` case + `Copy.Format.*` events; taxonomy review is deferred to the `analytics-audit` skill (as with the V3 card and the advisor).

**The only input from Ken:** confirm the action's **display name** (§7). The edit itself is `INFOPLIST_KEY_CFBundleDisplayName` (I make it; it stays English per convention).

**New UI strings** (editor labels, preset names, paywall copy) go in `Localizable.xcstrings` as identifier keys + generated symbols (I add them); they'll need **ja/de translations** later, like any new app copy. The `LinkCleanExtensionUI` toast catalog (explicit-key style) changes only if the action's toast copy does.
