# Onboarding & Extension Guide Plan

Status: Draft
Scope: 1.0.0 TODO item 3 — "Initial onboarding" + "Instruction to add action extension (how to enable it in the share sheet) — part of onboarding, also reachable from Settings"
Targets: `LinkClean` (main app), `LinkCleanKit` (success signal), both action extensions (one-line call each)

---

## 1. Why onboarding, and what kind

**Do we need it? Yes — one specific job.** LinkClean's core value (cleaning links from any app's share sheet) is invisible: action extensions sit buried in the share sheet's action list, below the fold, and nothing in the app surfaces them. The analytics plan calls extension enablement "the riskiest step in the funnel" (§1). First launch is the only guaranteed moment to teach it. Everything else in the app (paste → clean → copy) is self-explanatory and needs no tutorial.

**What kind: a short interactive try-it flow, not a static carousel.** Three screens, skippable at every step:

```
Welcome ──Continue──▶ Try it ──extension run detected──▶ Celebration ──Get started──▶ TabView
   │                    │
  Skip ─────────────── Skip / "Maybe later" ──────────────────────────────────────▶ TabView
```

1. **Welcome** — value prop: before/after URL visual (demo URL with `utm_*`/`fbclid` junk → clean URL), one-line privacy note ("everything on-device").
2. **Try it** — embeds the shared extension guide (§2): share-sheet mock + steps + a live **"Share a sample link"** `ShareLink`. The user opens the *real* share sheet and taps the *real* "Clean URL" action. The app auto-detects the successful run (§3) and advances.
3. **Celebration** — "the cleaned link is on your clipboard, ready to paste." The demo run is deliberately **excluded** from History (see §3), so onboarding never pollutes the user's real history.

Practice beats reading: the user performs the share-sheet gesture once for real, which is the activation behavior we need to stick.

## 2. Explaining the extension: one shared guide screen

The current Settings "How to Use" section (4 static `Label` rows, `SettingsView.swift:79-86`) assumes "Clean URL" is already visible and never mentions finding/favoriting it. Replace it with a `NavigationLink` to a new **`ExtensionGuideView`** — the same view embedded in onboarding page 2 (single source of truth, single analytics emission point, `source: onboarding|settings`).

The guide contains, top to bottom:

1. **SwiftUI-drawn share-sheet mock** (`ShareSheetMockView`, Shared/UI): a grouped action-list replica — rows for "Copy", **"Clean URL"** (scissors), **"Copy as Markdown"** (curlybraces), "Add to Reading List", "Edit Actions…". The two LinkClean rows pulse (icon-tile scale + glow). Drawn in SwiftUI so it adapts to dark mode/Dynamic Type/localization with zero screenshot-asset maintenance.
   - Share-sheet action rows render **label left, icon right** — mock must match.
   - Row titles are **`Text(verbatim:)`**, not localized keys: "Clean URL" / "Copy as Markdown" must match the hardcoded `CFBundleDisplayName`s exactly (project.pbxproj), and the system rows match iOS UI.
   - Icons: SF Symbols `scissors` / `curlybraces` — the glyphs the real extension icons derive from.
   - `pulseActive: Bool` parameter gates the animation; respect `accessibilityReduceMotion` (static highlight instead).
2. **Numbered steps** fixing the current content gap:
   1. Tap Share in any app
   2. Scroll down to the actions list
   3. Choose **Clean URL** (tracker-free link) or **Copy as Markdown** (titled Markdown link)
   4. Can't find it? Tap **Edit Actions…** → green **+** to pin both to Favorites
3. **Try it now card** — `ShareLink(item: demoURL)` (a `URL` value, *not* String — String shares as plain text and would not surface the WebURL-activated extensions). Status line cycles idle → "Waiting for you to tap Clean URL…" → "Nice! The cleaned link is on your clipboard."

Demo URL (all four params are in `TrackingParameterCatalog.defaultEnabledSet`):

```
https://www.example.com/products/sneakers?utm_source=newsletter&utm_medium=email&utm_campaign=spring_sale&fbclid=abc123
```

## 3. Success detection (cross-process signal)

The extension runs in a separate process; the app needs to know "the user just ran it". Mechanism:

- `ActionExtensionViewController` (LinkCleanKit) gains `recordSuccessfulRun(at:)` which writes `Date.now.timeIntervalSinceReferenceDate` (a `Double` — trivially comparable, no `Date` bridging) to **App Group** `UserDefaults` under a new `SettingsKeys.lastActionExtensionRunAt`. Called on the success path of **both** extension subclasses, right after `saveHistory(...)` and *before* the ~0.95 s toast/dismiss animation, so the value is committed before the app re-foregrounds. Independent of the `saveHistoryEnabled` setting.
- **Demo excluded from History.** The sample link is a shared constant (`OnboardingDemo.url`, on the reserved `example.com` domain). `saveHistory(input:output:)` early-returns when `OnboardingDemo.matches(input)` (host + path), so a practice run is never persisted — but `recordSuccessfulRun` still fires, so success detection is unaffected. No time-bounded flag needed; the match is stateless and a real link can't collide.
- `ExtensionGuideViewModel` state machine:

```
        tryItTapped()              lastRunAt > startedAt
idle ───────────────▶ waitingForExtension ──────────────▶ succeeded
 ▲                       │  checked on scenePhase → .active
 └── reset() ◀───────────┘  + 500 ms poll (~20 s budget, iPad fallback)
```

- `tryItTapped()` (via `.simultaneousGesture(TapGesture())` on the ShareLink — ShareLink has no completion handler) records the start time.
- Success = `lastActionExtensionRunAt > startedAt` (strict — a run from last week never false-triggers).
- Share-sheet cancel: scene returns `.active`, timestamp unchanged → stays waiting; user can re-tap. Poll stops after budget; re-tap restarts.
- iPad presents the share sheet as a popover and may not drive scenePhase transitions — the poll is the fallback there.
- Either extension counts (both call `recordSuccessfulRun`) — tapping "Copy as Markdown" instead of "Clean URL" is still a success.

## 4. Implementation steps

Synchronized file groups: new files under `LinkClean/` and `LinkCleanKit/Sources/` auto-join their targets — no Xcode handoff needed.

### LinkCleanKit

1. **`SettingsKeys.swift`** — add:
   - `hasCompletedOnboarding` (lives in `UserDefaults.standard`; app-only, like `autoPasteEnabled`)
   - `lastActionExtensionRunAt` (App Group suite; cross-process)
2. **`ActionExtensionViewController.swift`** — add after `saveHistory` (~line 166):

   ```swift
   /// Records a successful run so the app's onboarding/guide "Try it" flow
   /// can auto-detect it. App Group suite: the app process reads it.
   public func recordSuccessfulRun(at date: Date = .now, in defaults: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier)) {
       defaults?.set(date.timeIntervalSinceReferenceDate, forKey: SettingsKeys.lastActionExtensionRunAt)
   }
   ```

   (Injectable `defaults` keeps the kit test hermetic — App Group may be unavailable in the test host.)
3. **`LinkCleanAction/ActionViewController.swift`** (after `saveHistory`, line 26) and **`LinkCleanMarkdownAction/ActionViewController.swift`** (after `saveHistory`, line 53) — insert `recordSuccessfulRun()`.

### App — new files

4. **`LinkClean/Shared/UI/ShareSheetMockView.swift`** — the mock component (§2 item 1). Container: grouped rows + dividers, `.ultraThinMaterial` + stroke, `.rect(cornerRadius:)` — match the existing glass-card styling in `HomeView`.
5. **`LinkClean/Features/ExtensionGuide/ExtensionGuideViewModel.swift`** — `@MainActor @Observable final class`; state machine (§3); injected `UserDefaults?` (App Group suite) + `now: () -> Date` clock; `pollTask` cancelled in `reset()`; `isIdleOrWaiting` drives `pulseActive`.
6. **`LinkClean/Features/ExtensionGuide/ExtensionGuideView.swift`** — `ScrollView` with mock + steps card + try-it card; `.screenBackground()`; params: `source: ExtensionGuideSource` (`.onboarding | .settings`), optional `onSuccess` closure (onboarding advances; Settings just shows the inline success line). Wires `scenePhase` via `.onChange`, `viewModel.reset()` in `.onDisappear`.
7. **`LinkClean/Features/Onboarding/OnboardingViewModel.swift`** — `page: Page` (`welcome | tryIt | celebration`); `advance()` (welcome→tryIt only); `handleGuideSuccess()` → celebration; `skip()` / `getStarted()` both persist `hasCompletedOnboarding = true` (injected `UserDefaults.standard`) and call `onFinished`. **Celebration is reachable only via detected success** — "Maybe later" on the try-it page calls `skip()`; never show "You did it!" to someone who didn't.
8. **`LinkClean/Features/Onboarding/OnboardingView.swift`** — `ZStack` switching on `viewModel.page` with `.animation`; persistent top-trailing Skip (hidden on celebration); `accessibilityIdentifier("onboarding-skip")`.
9. **`LinkClean/Features/Onboarding/OnboardingWelcomePage.swift`** — before/after URL cards (junk params red/struck-through → clean URL tinted), privacy line, Continue.
10. **`LinkClean/Features/Onboarding/OnboardingTryItPage.swift`** — header copy + embedded `ExtensionGuideView(source: .onboarding, onSuccess:)` + "Maybe later" secondary button.
11. **`LinkClean/Features/Onboarding/OnboardingCelebrationPage.swift`** — checkmark with `.symbolEffect(.bounce)`, clipboard copy, Get started.

### App — edits

12. **`LinkClean/App/ContentView.swift`** — `@AppStorage(SettingsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false`; `if hasCompletedOnboarding { TabView … } else { OnboardingView(onFinished: { hasCompletedOnboarding = true }) }` + `.animation(_, value:)`. Add `import LinkCleanKit`. Swapping at the root (not a `fullScreenCover`) means `HomeView` never mounts during onboarding → no auto-paste / paste-permission banner mid-flow.
13. **`LinkClean/App/LinkCleanApp.swift`** — in the `-uiTesting` branch, **after** `removePersistentDomain`: `UserDefaults.standard.set(true, forKey: SettingsKeys.hasCompletedOnboarding)` — otherwise every existing UI test lands on onboarding and fails. Order matters.
14. **`LinkClean/Features/Settings/SettingsView.swift`** — replace the How-to-Use Section (lines 79-86) with:

    ```swift
    Section {
        NavigationLink {
            ExtensionGuideView(source: .settings)
                .navigationTitle(Text(.guideTitle))
        } label: {
            Label { Text(.settingsHowToUseHeader) } icon: { Image(systemName: "wand.and.stars") }
        }
    }
    ```

### Localization

15. **`LinkClean/Localizable.xcstrings`** — add `extractionState: "manual"` entries (build once after adding so symbols generate). Remove the superseded `settings.howToUse.step1…4`; keep `settings.howToUse.header` as the link label.

| Key | English |
|---|---|
| `onboarding.skip` | Skip |
| `onboarding.welcome.title` | Clean links, instantly |
| `onboarding.welcome.subtitle` | LinkClean strips tracking junk from any URL so you share the real link, not who sent it. |
| `onboarding.welcome.beforeLabel` | Before |
| `onboarding.welcome.afterLabel` | After |
| `onboarding.welcome.privacy` | Everything happens on your device. Your links are never uploaded. |
| `onboarding.welcome.continue` | Continue |
| `onboarding.tryIt.title` | Works in any app's share sheet |
| `onboarding.tryIt.maybeLater` | Maybe later |
| `onboarding.celebration.title` | Done! Your link is clean |
| `onboarding.celebration.subtitle` | The cleaned link is on your clipboard, ready to paste anywhere. |
| `onboarding.celebration.getStarted` | Get started |
| `guide.title` | Using the Share Sheet |
| `guide.intro` | LinkClean adds two actions to the share sheet of Safari and any app that can share a link. |
| `guide.step1` | Tap the Share button on a link or page. |
| `guide.step2` | Scroll down to the list of actions below the app row. |
| `guide.step3` | Tap **Clean URL** for a tracker-free link, or **Copy as Markdown** for a titled Markdown link. |
| `guide.step4` | Can't find them? Tap **Edit Actions…** at the bottom, then the green **+** to pin both to Favorites. |
| `guide.tryItHeader` | Try it now |
| `guide.tryItButton` | Share a sample link |
| `guide.tryItWaiting` | Waiting for you to tap Clean URL… |
| `guide.tryItSuccess` | Nice! The cleaned link is on your clipboard. |

Notes: "Clean URL" / "Copy as Markdown" / "Edit Actions…" stay verbatim inside localized strings (proper nouns matching system UI). Step copy is plain text (markdown bold is unreliable through `Text(.symbol)` / `LocalizedStringResource`). Both the guide success line and the onboarding celebration mention only the clipboard — the demo run is excluded from History (§3).

### Analytics stubs (no TelemetryDeck yet — wire when analytics lands)

Names from [analytics.md](analytics.md) §6:

| Stub location | Comment |
|---|---|
| `ExtensionGuideViewModel.onAppear(source:)` | `// TODO(analytics): Onboarding.ExtensionGuide.shown — source: onboarding\|settings` |
| `OnboardingViewModel.skip()` | `// TODO(analytics): Onboarding.flow.skipped` |
| `OnboardingViewModel.getStarted()` | `// TODO(analytics): Onboarding.flow.completed` |
| Both `recordSuccessfulRun()` call sites | `// TODO(analytics): Action.*.succeeded fires here (see analytics.md §7)` |

## 5. Testing

**Unit (Swift Testing, mirror `HomeViewModelTests` style — `@MainActor struct`, `@Test`, `#expect`):**

- `LinkCleanTests/ExtensionGuideViewModelTests.swift` — throwaway `UserDefaults(suiteName: "test.<UUID>")` + fixed `now`:
  idle→waiting on `tryItTapped`; no timestamp ⇒ stays waiting; **older** timestamp ⇒ stays waiting (stale guard); **newer** timestamp + `handleScenePhase(.active)` ⇒ succeeded; `.inactive`/`.background` no-op; `reset()` ⇒ idle; `isIdleOrWaiting` matrix.
- `LinkCleanTests/OnboardingViewModelTests.swift` — initial page; `advance()` welcome→tryIt; `handleGuideSuccess()` ⇒ celebration; `skip()`/`getStarted()` persist flag + fire `onFinished`; skip works from every page.
- Kit: `recordSuccessfulRun(at:in:)` writes the expected interval into an injected suite. Run via `xcodebuild test -scheme LinkCleanKit -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4'` from `LinkCleanKit/` (`swift test` fails — kit imports UIKit).

**UI:** existing `LinkCleanUITests` must pass unchanged (guaranteed by step 13). Optional later: `-uiTestingOnboarding` launch argument that clears defaults *without* setting the flag, asserting Skip lands on the TabView.

## 6. Verification (manual, simulator)

1. Build & run `LinkClean` scheme (iPhone 17 / OS 26.4 sim). Delete app first → fresh launch shows Welcome; **no paste-permission banner**.
2. Try it → real share sheet shows "Clean URL" + "Copy as Markdown" → tap "Clean URL" → toast → celebration auto-appears.
3. Get started → TabView. History tab does **not** contain the demo (excluded via `OnboardingDemo`); clipboard holds the cleaned URL.
4. Relaunch → straight to TabView.
5. Settings → How to Use → guide pushes; Try-it works there too; success line appears inline.
6. Skip paths: Skip on Welcome, "Maybe later" on Try-it → both land on TabView, no celebration.
7. iPad sim: repeat step 2 — popover dismissal must still detect success (poll fallback).
8. Reduce Motion on → mock rows statically highlighted, no pulse.

## 7. Risks / open questions

- **Mock vs reality drift** — users' action lists vary (customization, OS reordering). Mitigated: mock framed as illustrative; steps explicitly cover scroll + Edit Actions…; the two LinkClean labels are load-bearing and match `CFBundleDisplayName` exactly.
- **Clipboard overwrite on first run** — the try-it flow puts the demo link on the user's real clipboard. Celebration copy explains it; confirm product comfort.
- **`example.com` demo URL** — never resolves, so "Copy as Markdown" gets no page title (URL-only markdown). Fine for the demo ("Clean URL" is the highlighted path); swap to a real URL if titled Markdown should demo well.
- **iPad scenePhase** — verify the poll fallback on an iPad sim (risk: popover doesn't toggle scenePhase).
- **Analytics ordering** — TODO says TelemetryDeck lands first; this plan is independent either way (stubs only).
