# Experiment: SwiftWASM + BridgeJS for the landing "try it" demo

**Status:** fun-note / shelved for later · **Date:** 2026-06-17

Loose exploration only — not a feature plan, not committed work. Captured so we
don't lose the shape of the idea.

## Idea

Compile `LinkCleanCore` to WebAssembly with [SwiftWASM][swiftwasm] and bridge it
to the landing page via [BridgeJS][bridgejs] (the JavaScriptKit plugin for
declarative `@JS` bindings). The landing "paste a URL → see it cleaned" widget
would call the actual `URLCleaner` running client-side in the browser instead of
a hand-ported TypeScript reimplementation.

[swiftwasm]: https://swiftwasm.org
[bridgejs]: https://github.com/swiftwasm/JavaScriptKit#bridgejs-plugin

## Why it's a near-ideal fit on paper

- `LinkCleanCore` is `nonisolated` default, no deps, no resources, no UIKit, no
  SwiftData — a pure URL/string kernel.
- Catalogs (`TrackingParameter` definitions, wrapper hosts) are pure Swift
  values; no codegen, no platform calls.
- Marketing line writes itself: *"the same engine the iOS app uses, running
  on-device in your browser — no server ever saw your URL."* Reinforces the
  privacy wedge instead of fighting it.
- Solves the **catalog drift** risk a hand-ported TS cleaner would introduce
  (already a recurring failure mode in the engine layer).

## The four concerns

1. **Bundle size.** SwiftWASM hello-world is ~300–500 KB Brotli'd; Core +
   catalogs likely 800 KB – 1.5 MB. Lazy-load-on-interaction territory, not
   above-the-fold.
2. **BridgeJS maturity.** Right primitive, but recent. Swift 6.2 ↔ WASM SDK
   matrix is a moving target. Expect toolchain churn.
3. **Client-side only.** Doesn't fit Cloudflare Workers' WASM runtime well; the
   demo would be a browser-side `<script type="module">`. Fine for a widget;
   means none of it runs at the edge (irrelevant for privacy framing, relevant
   if we ever wanted SSR of cleaned URLs).
4. **Build complexity.** Adds Swift toolchain + WASM SDK to the landing CI
   (currently bare Hono / Wrangler per `monorepo-and-landing.md`).

## Pragmatic path if we ever pick this up

- **v1 landing (now):** hand-port a tiny TS cleaner. ~5–10 KB gz, no toolchain
  dep, fits the Hono/Workers stack natively. Generate catalog JSON from Swift
  via a build script so drift is mechanical, not editorial.
- **Phase 2 (post-traffic):** prototype SwiftWASM + BridgeJS as a standalone
  "engine demo" widget. A/B whether the *"literally the same Swift"* framing
  actually lifts conversion vs. the TS port.
- **Before committing:** scope a thin BridgeJS spike under `plans/` to answer
  size, cold-start, and CI build-time with real numbers — not vibes.

## Open questions for a future spike

- Current SwiftWASM SDK support for Swift 6.2 + `nonisolated` default isolation?
- Real Brotli'd size of `LinkCleanCore` + full catalogs (vs. hello-world)?
- BridgeJS ergonomics for surfacing `CleanOutcome` / `Telemetry` shape to JS
  without hand-marshalling each field?
- Cold-start time on a mid-tier Android browser (the actual constraint, not
  M-series Safari)?

## Related

- `docs/strategy/monorepo-and-landing.md` — landing stack baseline (Hono/JSX
  on Workers).
- `docs/strategy/growth-marketing.md` — where a try-it widget would sit in the
  wedge mix.
- `plans/SEED.md` — checklist a real spike would graduate into.
