# Competitive Analysis: Clean Links (Numen)

> **Status: research — 2026-06-13.** Deep-dive on the market-leading rival, closing the "re-verify the Feb 2026 competitive snapshot" action ([iap-strategy.md](iap-strategy.md) §13.3 / [growth-roadmap.md](../product/growth-roadmap.md) §10.7). **Supersedes the one-line Clean Links entries in [iap-strategy.md](iap-strategy.md) §1–§2 where they differ** (notably the "5.0 rating" figure). Re-verify before relying on it: all data is June 2026, app **v1.0.17**.
> **Scope:** one competitor — *Clean Links: URL Privacy* (App Store `id6747395062`, Numen Technologies Limited). Monetization, full feature set, platform/positioning, reception, developer, and the read for LinkClean. The other Feb-2026-snapshot apps (Trackless Links, CleanSend) are **not** re-verified here and still need §13.3.
> **Method:** multi-source deep research — Apple App Store across US/AU/TN/IE storefronts + Apple developer page + iTunes lookup API, developer sites `cleanlinks.app` and `numen.ie`, Irish company registry, App Store reviews, and third-party coverage — with adversarial verification (25 claims checked, 23 confirmed). Confidence flags inline; **vendor-asserted, un-audited figures are marked**.

---

## 0. TL;DR for LinkClean

**Clean Links is completely free with zero monetization, and it is *broader* than a URL cleaner** (QR-code safety + cross-device link-sending). It has **already shipped, for free, several capabilities LinkClean scoped as Pro or future** (short-link expansion, Safari auto-strip, lite iCloud sync). It can afford to be free because it is a **portfolio halo play**: the developer's real revenue app is the paid *Private LLM*.

This **confirms LinkClean's core thesis** ([iap-strategy.md](iap-strategy.md) §1: "cannot win as a cheaper tracker-stripper; wins as a link-productivity tool"). The strategic consequences are in §6: lean Pro on **formats / on-device AI / history depth**, not on expansion/sync; and treat price as justified by differentiated value, not by competitor anchoring (the main rival is **$0**).

---

## 1. Monetization / IAP

**100% free. No in-app purchases, no subscription, no Pro tier, no trial, no feature-gating of any kind.** (Confidence: **high** — verified across US/AU/TN/IE storefronts, the developer site, and the app's own copy; an "In-App Purchases" section is absent on every storefront checked.)

- Base price **Free**; Apple privacy label **"Data Not Collected."**
- FAQ verbatim: *"There are no accounts, subscriptions, or in-app purchases."*
- It **weaponizes free against paid rivals**: *"Unlike other link cleaners, Clean Links has no ads, no subscriptions, and no data collection… all for free."*
- No Family Sharing question applies — there is nothing to purchase.

**Disambiguation (resolved):** the *"$100 lifetime + usage-cap backlash"* app is a **different product** — **"AI Link Cleaner – linkfy"** (`id6749719091`, developer *Kerem ORSDEMR*, brand firtina.co/linkfy): **$99.99 one-time "lifetime"** plus subscriptions, a **free tier capped at "Clean up to 10 URLs/day,"** and it **does** collect tracking data. It is unrelated to Clean Links. LinkClean's cautionary reference to "AI Link Cleaner" ([ai-features.md](../product/ai-features.md) §2) is therefore accurate and points at a real, separate app. *(The exact subscription sub-tiers — ~$1.99/wk · $4.99/mo · $29.99/yr — are lower-confidence; the $99.99-lifetime + 10/day-cap attribution is solidly confirmed.)*

### 1.1 Why is it free? (the business model)

Free *and* "Data Not Collected" reads as too-good-to-be-true, but it resolves cleanly: **Clean Links doesn't *need* to monetize, and it *can* be free-with-no-tracking because it has no servers to pay for or collect data to.** Two pillars:

1. **It's subsidized — a portfolio halo / funnel play.** Clean Links is not the business; **Private LLM is** (the studio's paid breadwinner, $4.99 × 674 ratings — see §5). A free, privacy-first utility is the ideal top-of-funnel for Numen's audience: the privacy-conscious user who installs a free tracker-cleaner is exactly who later buys a paid *on-device, private* LLM. So Clean Links earns its keep as **brand + cross-promo + App Store search real-estate**, not as direct revenue.
2. **It costs them almost nothing to run.** The architecture is **on-device with no backend** — the developer states even short-link expansion goes *"directly from your device to the destination, not through our servers, and we do not log the links you clean."* No servers ⇒ no per-user cost **and no data-collection apparatus in the first place**. A server-backed free app bleeds money (hence so many "free" apps monetize via data/ads); Clean Links has neither that cost nor that pressure, so "free forever, no tracking" is *cheap* for them in a way it is not for a backend app.

In other words, the no-tracking stance isn't a heroic sacrifice — **there is simply no data pipeline**, because the app needs none to work *or* to earn (Private LLM does that).

**Is the no-tracking claim trustworthy?** Credibly yes, with caveats. It's an **Apple-enforced declaration** (a false "Data Not Collected" label gets apps pulled) and is **architecturally consistent** (no account, no history, on-device). **But:** it is self-declared (Apple does not deep-audit), the no-cookies / no-logging *internals* of its network requests are **vendor-asserted and un-audited**, and "no IAP / no tracking *today*" is a **current state, not a permanent vow** — the aggressive web/PWA/Mac/iPad expansion (§2–§3) implies an expected return (halo for Private LLM and/or later monetization of the install base). One minor unverified angle: the **website** could carry ads/affiliate even though the app does not.

**Consequence for LinkClean:** you cannot out-free a competitor whose freeness is **subsidized by an unrelated revenue app**. Numen runs Clean Links at $0 indefinitely because Private LLM funds the studio; LinkClean *is* the product, so its free tier is unsubsidized and must convert. This is the structural reason the [iap-strategy.md](iap-strategy.md) §1 thesis holds — compete on the **productivity layer a free funnel won't build** (formats, AI advisor, history depth = *work*), not on cheaper/free cleaning (= *operation*, which subsidized-free wins). See §6.2–§6.3 and §7.

---

## 2. Feature set

Marketed as **"Link Cleaner & QR Code Scanner"** — substantially broader than tracker stripping. ⭐ = capability LinkClean does not have.

| Capability | Detail | Confidence |
|---|---|---|
| **Tracker stripping** | "71+ services"; named params `utm_source/medium/campaign`, `fbclid`, `gclid`, `igshid`, `si`; per-site cleaners for FB/X/YouTube/TikTok/IG/LinkedIn/Reddit/Amazon. The dev separately cites **"hundreds of tracking parameters, domains and redirects"** (r/CleanLinks) — the real rule count is larger than the "71+ services" unit | high; counts **vendor-asserted, un-audited** |
| **Redirect unwrapping + transparency** ⭐ | Resolves the full chain (`t.co`, `l.facebook.com`, `lnkd.in`, newsletter/ad redirectors) and **displays every redirect followed + every tracker stripped** (v1.0.17) — a marketed differentiator | high (changelog + third-party MacStories confirmation of networked redirect resolution) |
| **Short-link expansion** | Networked, **device → destination** (no third-party API / no developer servers); claims sandboxed sessions, randomized user-agent, no cookies | high it exists; **internals self-asserted, un-audited** |
| **— Opt-out** | **"Disable Network Requests" / "Offline Privacy Mode"** toggle, in-app **and** via Shortcuts; leaves short links unexpanded while local-rule stripping continues. Added **reactively in v1.0.13** after a user review | high |
| **Safari extension** | **Auto-strips supported params during navigation (DNR), before the page opens**; also one-tap cleans all links on a page; iPhone/iPad + Mac | high; **but reportedly requires iOS 18+/macOS Sequoia+** (host app is 17.6) — *one non-unanimous (2-1) claim, verify live* |
| **QR Code Reader** ⭐ | Preview a QR code's **real destination before opening** ("phishing/quishing protection") | high |
| **QR Generator** ⭐ | Create "clean" QR codes from trusted links | high |
| **Send-to-Mac** ⭐ | Opens cleaned links on Mac **even when offline**; multi-Mac; can trigger Mac Shortcuts — pitched as a free **Hyperduck alternative** ("faster than AirDrop" — *vendor framing*) | high |
| **Clipboard watcher** ⭐ | Auto-monitors the clipboard and cleans — reviewers call it *"your killer feature"* | high |
| **iCloud sync** | Syncs the **5 most-recent** cleaned links across devices (opt-in, device-side, not server-retained) | high |
| OS integration | Handoff, Share Extension, Control Center widget, Siri & Shortcuts, **x-callback-url** spec | high |
| **Clean Links Web + PWA** ⭐ | An online cleaner "for any browser, **plus PWA install on Android and desktop**" — reach beyond Apple platforms (dev announcement, r/CleanLinks) | high |
| **Mac = menu-bar app** ⭐ | The Mac app is a **menu-bar utility** that cleans links + unmasks QR codes — already occupying LinkClean's stated **2.0 menu-bar horizon** | high |
| **Not found** ⚠️ | **No Markdown/format export and no confirmed in-app batch/multi-link cleaning** — no evidence on any surface | medium (absence of evidence; verify on a live install — **this is LinkClean's clearest wedge**) |

---

## 3. Platform & positioning

- **iOS/iPadOS 17.6+ and macOS 14.6+** (no visionOS). The iOS 17.6 floor was added in v1.0.12 (was iOS 18+).
- **Reach beyond Apple:** a **web cleaner + installable PWA (Android and desktop)** and a **Mac menu-bar** app — so actual platform reach is wider than the iOS/macOS App Store listing implies, and not Apple-locked the way LinkClean (iOS-only) is.
- Subtitle/tagline **"Link Cleaner & QR Code Scanner"** (subtitle field: *"Remove tracking from links, QR"*).
- **Privacy stance:** *"100% Private — No ads, no tracking, no data collection,"* on-device, **no account, no link history** — note they frame *no history* as a privacy *feature* (the opposite of LinkClean's searchable-history depth).
- Apple **A/B-tests three display titles for the same app** (`id6747395062`): *"Clean Links: URL Privacy,"* *"…QR Code Reader,"* *"…QR & Link Safety."* Don't mistake the slugs for different apps.

---

## 4. Reception

- **4.9★ / 49 US ratings.** (Some global aggregators cite ~148; the page-verified US count is 49.) The app is young — first released **Aug 2025**.
- **Top praise:** the clipboard auto-clean feature (*"This is your killer feature"*).
- **Top complaints — both already addressed:**
  1. Default short-link expansion *"can still attribute a click to you if the original URL was targeted/shared only to you"* → **opt-out toggle added v1.0.13.**
  2. Cleaned links **forced open in Safari**, no browser choice → **Chrome support added v1.0.11.**
- **Cadence:** ~monthly (1.0.12 → 1.0.17 across ~3 months), visibly **review-driven** — the developer ships fixes in the same cycle as the feedback.
- **Official channels (checked 2026-06-13):** the X bio `@CleanLinksApp` confirms positioning — *"Free QR & Link Cleaner for iOS & macOS."* The official **r/CleanLinks** subreddit is a **thin dev-announcement channel** (4 posts, all by the developer `u/__trb__`, single-digit upvotes, ≤11 comments) — not an active community. Combined with 49 ratings, this signals a **low brand/community moat** — beatable on ASO and volume.

---

## 5. Developer

**Numen Technologies Limited** — a small Irish indie studio (numen.ie; Dublin; company #677823; incorporated 2020; Apple dev `id1683507194`). Its **entire** App Store portfolio is three apps, and the asymmetry is the strategic point:

| App | Released | Price | Ratings | Role |
|---|---|---|---|---|
| **Private LLM – Local AI Chat** | Jun 2023 | **$4.99 paid** | 4.18★ × **674** | The breadwinner |
| **Clean Links: URL Privacy** | Aug 2025 | **Free** | 4.9★ × 49 | Halo / brand play |
| Slop Or Not – AI Detector | Sep 2025 | Free | 5★ × 3 | Experiment |

**Implication:** Numen can keep Clean Links free *indefinitely* because *Private LLM* funds the studio. LinkClean has no such subsidy — it *is* the product — so it cannot match "free + funded" and must monetize on differentiated value. *(Specific team headcount/names are unverified; "small indie studio" is all that's established.)*

---

## 6. Competitive read for LinkClean

### 6.1 Feature overlap vs. LinkClean's roadmap

Clean Links has already shipped, **for free**, things LinkClean scoped as Pro or future:

| Capability | LinkClean | Clean Links |
|---|---|---|
| Param stripping | ✅ 85-param / 7-category | ✅ "71+ services" |
| Redirect unwrap (E1) | ✅ shipped | ✅ + transparency UI |
| **Short-link expansion (E4)** | 🔜 planned **Pro** (1.4+) | ✅ **free** |
| **Safari auto-strip (S2)** | 🔜 planned (1.3/1.4) | ✅ **free** |
| **iCloud sync** | 🔜 planned **Pro** (1.3 headline) | ✅ lite (5 links) **free** |
| App Intents / Control Center (S1) | ✅ shipped | ✅ |
| **Markdown / format export** | ✅ + 🔜 HTML/Title (Pro) | ❌ **(wedge)** |
| **On-device AI advisor (ai-A)** | ✅ shipped | ❌ |
| **Searchable history depth** | ✅ | ❌ (markets "no history") |
| QR reader / generator / phishing | ❌ | ✅ |
| Send-to-Mac / cross-device | ❌ (Mac = 2.0 horizon) | ✅ |
| Clipboard watcher | ❌ (deliberately rejected, roadmap §4 S3) | ✅ (their "killer feature") |

### 6.2 Where LinkClean can win

- **PKM / productivity** — Markdown + planned HTML/Title formats. **Clean Links has no format export** — this is LinkClean's stated positioning ([iap-strategy.md](iap-strategy.md) §1) sitting on an unguarded flank.
- **On-device AI advisor (ai-A)** — genuinely novel; Clean Links keeps AI in a *separate* app (Private LLM).
- **Auditable trust** — "71+ services," the no-cookies/randomized-UA internals, and "faster than AirDrop" are all **un-audited vendor claims**. A published/auditable catalog (or open engine) is a credibility wedge against a closed competitor.
- **Offline-first determinism** — Clean Links' loudest complaint was network-expansion click-leakage. LinkClean's default-offline cleaning is a privacy-purity story.
- **Design / polish** — LinkClean's Liquid-Glass UI vs. a utility-first competitor.

### 6.3 Threats to take seriously

- **Gating erosion.** LinkClean planned to charge for **E4 (short-link expansion)** and **iCloud sync**; Clean Links gives both away. Charging for what the *primary free competitor* includes is a weak paywall — **re-examine [iap-strategy.md](iap-strategy.md) §6 gating**; lean Pro on formats/AI/history-depth instead.
- **Price-anchor collapse.** The "$4.99, with $5.99 headroom" case ([iap-strategy.md](iap-strategy.md) §3/§12) leaned on Trackless Links anchoring $5.99. The *leading* competitor is **$0** and the only expensive one ($99 AI Link Cleaner) is disliked — so price must be justified purely by differentiated value, not by a competitor ceiling.
- **The clipboard watcher is their most-loved feature**, and LinkClean rejected the category (roadmap §4 S3). The privacy-optics rationale was sound, but users explicitly *asked for it* — worth a deliberate re-look.
- **Breadth + QR + free** gives Clean Links a larger ASO footprint and a "link safety" narrative LinkClean doesn't compete in.
- **Wider platform reach + the 2.0 flank.** Clean Links already ships a **Mac menu-bar app** — the exact "menu-bar clipboard cleaner" LinkClean parks at its 2.0 horizon (roadmap §8) — plus a **web cleaner and Android/desktop PWA**. So LinkClean's eventual Mac/desktop expansion lands on already-occupied ground, and Clean Links isn't Apple-locked.

---

## 7. Reconciliation — what this changes upstream

Deltas to propagate into the strategy docs (not yet applied):

1. **[iap-strategy.md](iap-strategy.md) §1 + §2:** "5.0 rating" → **4.9★ / 49 US ratings**. Expand the one-line Clean Links row with §1–§6 here.
2. **[iap-strategy.md](iap-strategy.md) §6 gating + [growth-roadmap.md](../product/growth-roadmap.md) §3/§8:** reconsider gating **E4** and **sync** as Pro now that the free leader ships them.
3. **[ai-features.md](../product/ai-features.md) §2:** confirm "AI Link Cleaner" is the separate `id6749719091` (linkfy / Kerem ORSDEMR), distinct from Clean Links.
4. **Still open from §13.3:** Trackless Links and CleanSend were **not** re-verified here.

---

## 8. Open questions (verify on a live install)

1. Does Clean Links support **in-app batch/multi-link** cleaning or **any format/Markdown export**? (No evidence found — likely *not*, which would confirm LinkClean's wedge.)
2. Does the Safari auto-strip extension **truly hard-require iOS 18+/macOS Sequoia+**, degrading the stated 17.6 floor?
3. Real **catalog depth** behind "71+ services / thousands of trackers" — any auditable rule list?
4. Non-US reception and the **49 (US) vs ~148 (global)** ratings discrepancy; any sentiment difference outside the US.
5. **Long-term monetization intent** — permanent free/halo play, or could a paid tier appear later?

---

## 9. Sources

Primary: App Store listing `id6747395062` (US/AU/TN/IE) · `cleanlinks.app` + `/guides/*` + `/compare/*` · Apple developer page `id1683507194` · `numen.ie` · iTunes lookup API · `id6749719091` (the disambiguated *AI Link Cleaner – linkfy*) · **`x.com/cleanlinksapp`** (bio only — login-walled) · **`reddit.com/r/CleanLinks`** (dev announcements: Web/PWA, Mac menu-bar, "hundreds" of rules). Secondary/third-party: App Store reviews, MacStories (redirect resolution), Hacker News, Irish company registry, `github.com/aloth/trackless-links`.

**Caveats:** June 2026 / v1.0.17 snapshot — *"free, no IAP"* is a current-state fact, not a permanent guarantee; the "71+ services," network-request internals, and "faster than AirDrop" are the app's **positioning, not independently proven behavior**; the extension's iOS-18 floor and the 49-vs-148 ratings count are the two soft spots to confirm on a live install.
