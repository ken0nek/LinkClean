# Plan 003: History before→after — surface the original link + search it

> **Executor instructions**: Follow this plan step by step. Run every verification
> command and confirm the expected result before moving on. Honor the STOP
> conditions — do not improvise. When done, update this plan's status row in
> `docs/plans/README.md`.
>
> **Read `docs/plans/SEED.md` first** — the eight standing LinkClean decisions. This
> plan records the before→after-specific answers; "SEED §N" points there for the
> shared rationale.
>
> **Drift check (run first)**:
> ```
> grep -n "var input\|var output" apps/ios/LinkClean/LinkCleanKit/Sources/LinkCleanData/HistoryEntry.swift
> grep -n "localizedStandardContains" apps/ios/LinkClean/LinkClean/Features/History/HistoryViewModel.swift
> ```
> Expect: `HistoryEntry` declares `public var input` **and** `public var output`;
> `HistoryViewModel.filteredEntries` matches `pageTitle` + `output` **only** (not
> `input`). If search already includes `input`, or `HistoryEntry` lacks `input`,
> STOP and report — this plan is already partly done or the model changed.

## Status

- **State**: ✅ **DONE (2026-06-25)** — built and verified; all done-criteria below met (fast lane 290 green, `build-for-testing` EXIT 0).
- **Priority**: P1
- **Effort**: S–M
- **Risk**: LOW (display + one pure Core diff; no schema/persistence change, no network, no Foundation Models)
- **Depends on**: none
- **Category**: direction (feature)
- **Target**: 1.2.2
- **Planned at**: commit `786beb3`, 2026-06-25

## Post-review revision (2026-06-26)

A max-effort `/code-review` of the built diff found **`expandedFromHost` was dead on
the dominant in-app path**: Home/QR record history from `outcome.input`, which
`CleaningService` already sets to the *unwrapped/expanded destination*, so an
input-vs-output host comparison was always `nil` — the "Expanded from bit.ly" banner
only ever rendered for share-extension / Shortcuts entries. The fix **reverses this
plan's "no schema migration" scoping** (with maintainer sign-off):

- `HistoryEntry` gains an optional `arrivedFromHost` (lightweight SwiftData
  auto-migration — the model has no version plan). `CleanOutcome` carries it,
  computed once in `CleaningService` via `URLCleaner.analyticsDomain`; **every** record
  site (Home/QR, action extension, App Intents) now persists the *destination* as
  `input` plus the arrival host separately. `HistoryDiff` surfaces the persisted host
  rather than re-deriving it — so the banner works on all surfaces and a redirect
  wrapper's payload is never mistaken for a removed tracker. Still on-device only:
  `arrivedFromHost` is outside `CleanOutcome.Telemetry`, so it can't reach analytics.

Other fixes in the same change: partial-fragment diff (a stripped `:~:text=` leaving a
surviving `#anchor` is now reported, not "nothing removed"); multiplicity-aware param
diff; `Text(verbatim:)` for the fragment row (was auto-extracting a junk `"#%@"`
catalog key); compute the diff once; row-tap scoped to the leading content; and
Core-Usage insight 23 now excludes the non-export `viewedBeforeAfter`. Fast lane 296
green; `build-for-testing` EXIT 0.

## Why this matters

`HistoryEntry` already persists **both** sides of every clean — `input` (the
original, dirty link) and `output` (the cleaned link)
(`LinkCleanData/HistoryEntry.swift:14-15`) — but the UI only ever renders
`output` (`HistoryCellView.swift:42-52`) and search matches only
`output` + `pageTitle` (`HistoryViewModel.swift:81-87`). The original is **dark
data**: already on device, paid for in storage, never shown.

Surfacing a before→after view is the **highest trust-per-effort** move available
for a privacy app — it lets the user *see exactly what came off each link*, which
is the product's entire promise, and it pays off **doubly** for E1 redirect
unwrapping and E4 short-link expansion, where `input` and `output` differ by
*host*, not just query string ("expanded from bit.ly", "unwrapped to youtube.com").
Strategy fit = the **history-depth wedge** (SEED §1) — the axis the free
competitor (Clean Links) does not match.

## The eight SEED decisions

1. **Strategy fit.** History-depth wedge. Deepens the one surface a free cleaner
   doesn't invest in; reinforces the privacy-authority position by *proving* what
   was stripped. North-star tie: a visible before→after is a reason to open the
   app (an export/active-session driver), and a screenshot-friendly trust artifact.
2. **Surfaces — app only.** The History feature (`LinkClean/Features/History/`).
   **Not** extensions or intents (SEED §2): History is an in-app surface; the
   action extension and App Intents have no history-detail UI and are time-budget
   constrained. No `CleaningService` change — the diff reads the two strings
   already stored.
3. **Free vs Pro — FREE.** This is **operation visibility**, not addition or
   accumulation (iap §6 rule 3) — exactly like the Stats dashboard and the leftover
   pills, which also ship free. It is a *trust* play, not a Pro lever; gating "see
   what we removed" would undercut the whole pitch. The existing **7-day History
   window** Pro gate is untouched: before→after applies to whatever rows are
   already visible to the user (Pro sees all; free sees the window). **No new
   paywall, no new `PaywallTrigger`, no benefit-row change.**

   | Capability | Free | Pro |
   |---|---|---|
   | See before→after for a visible history entry | ✅ | ✅ |
   | Search the original (`input`) text | ✅ (within the free window) | ✅ (full archive) |
   | History depth the detail applies to | last 7 days | full archive (existing gate) |

4. **Foundation Models — N/A.** No AI. (The diff is deterministic string parsing.)
5. **Privacy & determinism.** `input`/`output` are already persisted locally; the
   detail renders them on-device only. The diff is a **pure, offline,
   deterministic** function of the two stored strings — no network egress, no
   re-run of the live catalog (so it can't drift from what actually changed), and
   nothing new leaves the device. Analytics stays count-only (decision 6).
6. **Analytics.** One new typed case — `historyEntryActioned(.viewedBeforeAfter)`
   (extend the existing `HistoryEntryAction` enum so the new surface rides the
   established `History.Entry.actioned` signal with a new bucketed `action` value).
   Searching `input` reuses the existing `historySearchUsed` (no new event — it's
   the same search box). Add the enum case to **both** switches (`signalName` +
   `parameters`) and a test (analytics-audit pattern, SEED §6). No PII — the event
   carries only the closed-enum action name.
7. **Architecture fit.** The testable logic (the diff) goes in **`LinkCleanCore`**
   (pure, `nonisolated`, `Sendable`, no UIKit/SwiftData) so it runs the fast lane.
   The detail view is `@Observable`/`@State` (never `ObservableObject`); the
   ViewModel owns the present/diff call, the View calls a method; deps stay threaded
   via the composition root; labels are identifier keys → generated symbols
   (CLAUDE.md). New Core file → Core layer; no cross-layer leak.
8. **Verification.** `HistoryDiff` is pure → covered by `LinkCleanCoreTests` on the
   fast lane (`cd LinkCleanKit && swift test`, ~1s). Compile gate =
   `xcodebuild build-for-testing -scheme LinkCleanTests …` (the app-test sim runner
   is flaky — a "runner hung" is infra, not a failure). Machine-checkable done
   criteria below.

## Current state (excerpts — confirm during recon)

`HistoryEntry` (`LinkCleanData/HistoryEntry.swift:11-29`): `id, input, output,
createdAt, pageTitle?, thumbnailData?, metadataFetchAttempted`. `input` is the
original; `output` the cleaned link. Both `public`.

Search (`HistoryViewModel.swift:81-87`) — **the one-line change in Step 2**:

```swift
func filteredEntries(from entries: [HistoryEntry]) -> [HistoryEntry] {
    guard !searchText.isEmpty else { return entries }
    return entries.filter { entry in
        (entry.pageTitle?.localizedStandardContains(searchText) ?? false)
            || entry.output.localizedStandardContains(searchText)
    }
}
```

The cell (`HistoryCellView.swift:37-105`) renders `pageTitle ?? output`, the
domain, the relative date, a thumbnail, and a trailing copy/share button cluster
(borderless), plus a `.contextMenu`. **There is no detail view today** — the only
tap targets are the two borderless buttons and the context menu. `HistoryView.swift:167`
(`Text(entry.pageTitle ?? entry.output)`) is the *blurred archive-teaser* row for
aged-out free entries, **not** an interactive row — leave it alone.

## Scope

**In scope:**
- `LinkCleanKit/Sources/LinkCleanCore/HistoryDiff.swift` (create — the pure diff).
- `LinkCleanKit/Tests/LinkCleanCoreTests/HistoryDiffTests.swift` (create).
- `LinkClean/Features/History/HistoryDetailView.swift` (create — the before→after sheet).
- `LinkClean/Features/History/HistoryViewModel.swift` (search `input`; present + analytics).
- `LinkClean/Features/History/HistoryCellView.swift` (open the detail on content tap + a context-menu item).
- `LinkCleanKit/Sources/LinkCleanCore/AnalyticsEvent.swift` (add the `HistoryEntryAction.viewedBeforeAfter` case to both switches).
- `LinkClean/Localizable.xcstrings` (new `history.detail.*` keys, en/ja/de, with translator comments).
- `LinkCleanTests/HistoryViewModelTests.swift` + `…/AnalyticsEventTests.swift` (extend).

**Out of scope (do NOT touch):**
- `HistoryEntry`'s schema — `input`/`output` already exist; **no SwiftData migration**.
- Re-running `URLCleaner` with the *current* ruleset to compute the diff — compute
  it from the two stored strings only (accurate to what actually changed; avoids
  ruleset-drift dishonesty). STOP if tempted to import `URLCleaner` here.
- Any paywall / `ProGate` / `PaywallTrigger` change — this is free (decision 3).
- `LinkCleanExtensionUI` / `LinkCleanIntents` — app-only feature.
- `HistoryView.swift`'s archive-teaser row (`:160-181`).

## Steps

### Step 1 — `HistoryDiff` in Core (the pure, testable kernel)

Create `LinkCleanCore/HistoryDiff.swift`. A `nonisolated` value type that takes
`input` and `output` strings and reports what changed:

```swift
public struct HistoryDiff: Equatable, Sendable {
    public struct Param: Equatable, Sendable { public let name: String; public let value: String }
    /// Query items present in `input` but not in `output` (name+value).
    public let removedParameters: [Param]
    /// A fragment present on input and gone on output (e.g. "#:~:text=…"), if any.
    public let removedFragment: String?
    /// Set when the host changed (redirect unwrap / short-link expand): the
    /// original host the link arrived as, e.g. "bit.ly" → output host "youtube.com".
    public let expandedFromHost: String?
    public init(input: String, output: String) { … }
    public var isEmpty: Bool { removedParameters.isEmpty && removedFragment == nil && expandedFromHost == nil }
}
```

- Parse both via `URLComponents`. `removedParameters` = input query items minus
  output query items, compared by `name`+`value` (so a kept-but-reordered param
  isn't reported; a removed one is). Preserve input order.
- `removedFragment` = input fragment when output has none (or differs).
- `expandedFromHost` = input host when it differs from output host (the E1/E4
  case). Strip a leading `www.` for display parity with `HistoryCellView.domain`.
- No `URLCleaner` dependency, no I/O. Tolerate unparseable strings (return an empty
  diff rather than crashing).

**Verify**: `cd apps/ios/LinkClean/LinkCleanKit && swift test` → all suites pass.

### Step 2 — search the original

In `HistoryViewModel.filteredEntries`, add one disjunct:

```swift
|| entry.input.localizedStandardContains(searchText)
```

So a user can find an entry by the *original* link, not just the cleaned one
(highest-trust for the privacy persona; pairs with E4 where the original is the
short link they remember). No new analytics — it's the same search box
(`historySearchUsed` already fires).

**Verify**: `build-for-testing` → `EXIT: 0`.

### Step 3 — `HistoryDetailView` (the before→after sheet)

Create `LinkClean/Features/History/HistoryDetailView.swift`: a sheet showing, for
one entry —
- **Original** — `entry.input` in a mono, selectable block (label `history.detail.original`).
- **Cleaned** — `entry.output` (label `history.detail.cleaned`), with the same
  copy affordance the cell uses (reuse `viewModel.copyURL`).
- **Removed** — from `HistoryDiff(input:output:)`: an `expandedFromHost` banner
  ("Expanded from bit.ly") when present, then a list of `removedParameters`
  (`name=value`, mono) and the `removedFragment` if any. When `diff.isEmpty`, show
  a calm "Nothing needed removing" line (label `history.detail.nothingRemoved`).

`@Observable`/`@State`; no business logic in the view body. Match the app's Liquid
Glass / `Text(.symbol)` conventions.

**Verify**: `build-for-testing` → `EXIT: 0`.

### Step 4 — present it + analytics

- Add `HistoryEntryAction.viewedBeforeAfter` to the enum in `AnalyticsEvent.swift`
  and to **both** switch statements (`signalName` keeps `History.Entry.actioned`;
  `parameters` adds the `action` value, e.g. `"before_after"`). Add the case to
  `AnalyticsEventTests`.
- In `HistoryViewModel`, add `func showBeforeAfter(for:)` that captures
  `.historyEntryActioned(.viewedBeforeAfter)` and drives a presented-entry state
  (`var detailEntry: HistoryEntry?`), mirroring `copiedEntryID`'s pattern.
- In `HistoryCellView`, make the **leading content** (thumbnail + text `VStack`,
  i.e. everything *except* the trailing `GlassEffectContainer` button cluster)
  open the sheet via `viewModel.showBeforeAfter(for:)`, and add a context-menu
  item `Label(.historyMenuBeforeAfter, …)` for discoverability + VoiceOver. Keep
  the existing copy/share buttons borderless so row-content taps and button taps
  don't collide (STOP if they do and report — don't restructure the cell).
- Present `HistoryDetailView` from `HistoryView` via `.sheet(item:)` bound to the
  ViewModel's `detailEntry`.

**Verify**: `build-for-testing` → `EXIT: 0`.

### Step 5 — localization (en/ja/de + symbols)

Add to `LinkClean/Localizable.xcstrings` (identifier keys → generated symbols,
all three locales, with translator `comment`s; mirror in-app vocab —
`history.detail.cleaned` ≈ the app's existing "クリーンにしたリンク" / "Bereinigter
Link"):

| Key | en | ja | de |
|---|---|---|---|
| `history.detail.title` | Before → After | クリーン前後 | Vorher → Nachher |
| `history.detail.original` | Original | クリーン前 | Original |
| `history.detail.cleaned` | Cleaned | クリーン後 | Bereinigt |
| `history.detail.removed` | Removed | 削除した項目 | Entfernt |
| `history.detail.expandedFrom` | Expanded from %@ | %@ から展開 | Aufgelöst von %@ |
| `history.detail.nothingRemoved` | Nothing needed removing — this link was already clean. | 削除する項目はありませんでした。このリンクは元からクリーンです。 | Nichts zu entfernen – dieser Link war bereits sauber. |
| `history.menu.beforeAfter` | Show Before → After | クリーン前後を表示 | Vorher → Nachher anzeigen |

(Confirm the generated-symbol names: `history.detail.title` → `.historyDetailTitle`;
the `%@` key → `.historyDetailExpandedFrom(host)`.)

**Verify**: `build-for-testing` → `EXIT: 0`.

## Test plan

- `HistoryDiffTests` (Core, fast lane): removed query params (single/multi,
  name+value, order preserved); fragment removal (`#:~:text=`); `expandedFromHost`
  on a host change (`bit.ly` → `youtube.com`, with `www.` stripped); `isEmpty`
  when input == output; unparseable input → empty diff, no crash.
- `HistoryViewModelTests`: `filteredEntries` now matches on `input`
  (an entry whose `output` doesn't contain the term but whose `input` does is
  returned); `showBeforeAfter` sets `detailEntry` and captures the analytics case
  (assert via `SpyAnalytics`).
- `AnalyticsEventTests`: the new `HistoryEntryAction.viewedBeforeAfter` maps to the
  expected `signalName` + `parameters`.
- Gate: `cd LinkCleanKit && swift test` (fast) + `build-for-testing` (compile).

## Done criteria

ALL must hold:

- [ ] `cd apps/ios/LinkClean/LinkCleanKit && swift test` → all suites pass (incl. new `HistoryDiffTests`).
- [ ] `xcodebuild build-for-testing -project apps/ios/LinkClean/LinkClean.xcodeproj -scheme LinkCleanTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'` → `EXIT: 0`.
- [ ] `grep -n "entry.input" apps/ios/LinkClean/LinkClean/Features/History/HistoryViewModel.swift` → search now includes `input`.
- [ ] `grep -rn "import URLCleaner\|URLCleaner(" apps/ios/LinkClean/LinkCleanKit/Sources/LinkCleanCore/HistoryDiff.swift` → **no matches** (diff computed from the stored strings, not a re-clean).
- [ ] No `ProGate` / `PaywallTrigger` / `PaywallView` files modified (`git status`).
- [ ] New `history.detail.*` + `history.menu.beforeAfter` keys present in en/ja/de.
- [ ] `docs/plans/README.md` status row for 003 updated.

## STOP conditions

Stop and report (do not improvise) if:

- The drift check shows `HistoryEntry` lacks `input`, or search already matches `input`.
- Making the cell content tappable collides with the existing borderless copy/share
  buttons (don't restructure the cell — report and fall back to context-menu-only).
- Computing the diff appears to need `URLCleaner` or any catalog lookup — it must be
  a pure function of `input` + `output`.
- Wiring the sheet would require a `ProGate`/paywall change — this feature is free.

## Maintenance notes

- The diff is intentionally computed from the two stored strings, **not** by
  re-cleaning `input` with today's catalog: a rule added/removed since the entry was
  saved must not retroactively rewrite history ("we removed X" has to mean what
  actually happened). Note this in `HistoryDiff`'s doc comment.
- Reviewer scrutiny: (1) free output/behavior unchanged for users who never open the
  detail; (2) `HistoryDiff` is `nonisolated`/`Sendable` and UIKit-free; (3) the
  original link is shown only in the on-device detail and never enters analytics;
  (4) no schema migration (no new stored property on `HistoryEntry`).
- Natural follow-on (separate plan): a "re-clean with current rules" action in the
  detail for entries cleaned before a catalog update — but that's *addition*
  (recompute), so weigh it against the free/Pro line then.
