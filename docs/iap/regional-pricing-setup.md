# LinkClean Pro — Regional Pricing Setup (3-tier) — App Store Connect runbook

> Copy-paste-ready instructions for applying **3-tier geographic pricing** to the LinkClean Pro
> in-app purchase in App Store Connect. Adapted from Whyzard's regional-pricing runbook — the
> **tier list is identical**; the difference is **LinkClean Pro is a single non-consumable
> (one-time purchase), not a subscription**, so:
>
> - **One product, one price point per storefront** — no monthly/annual columns; you do the
>   table **once**, not twice.
> - **No consent/notification machinery, ever.** A non-consumable price change only affects
>   **future** buyers (existing owners already paid once); there is no "preserve price for
>   existing subscribers" prompt and no auto-apply-to-subscribers concern. Increases and
>   decreases are equally safe to set anytime.
> - Decided 2026-06-10. Sibling doc: `app-store-connect-setup.md` (product creation + go-live).

## 1. The pricing plan (source of truth)

### Tier ladder (one-time price)

| Tier | LinkClean Pro (one-time) | vs. Tier 1 |
|---|---|---|
| **Tier 1** (base / default) | **US$4.99** | full |
| **Tier 2** | **US$2.99** | ~40% off |
| **Tier 3** | **US$1.99** | ~60% off |

Japan resolves to **¥500** via the Tier 2 USD point (¥500 = the $2.99 point) — so Japan is just
a Tier 2 storefront, no special case.

Net at Apple Small Business Program (15%): **$4.24** / **$2.54** / **$1.69**.

### Tier 1 — base / default (DO NOT override)

Set the base price once (this is the product's price field — already **$4.99** if you followed
`app-store-connect-setup.md` §1). Every storefront **not** in the override table below rides
Tier 1 automatically via Apple's FX mapping. Tier 1 anchors (sanity-check only — do not edit):
United States, Canada, United Kingdom, Ireland, Germany, France, Netherlands, Belgium, Austria,
Switzerland, Denmark, Sweden, Norway, Finland, Italy, Spain, Portugal, Australia, New Zealand,
Singapore, Hong Kong, South Korea, Taiwan, Israel, United Arab Emirates, Saudi Arabia, Qatar,
Kuwait + all other unlisted storefronts.

## 2. Override table — the ONLY storefronts you touch (40 total)

Set each storefront below to the listed **USD price point** for the LinkClean Pro product.

### Tier 2 → **US$2.99** (22 storefronts)

| # | Storefront | ASC name note |
|---|---|---|
| 1 | Japan | should display **¥500** — see note below |
| 2 | Mexico | |
| 3 | Chile | |
| 4 | Uruguay | |
| 5 | Costa Rica | |
| 6 | Panama | |
| 7 | Poland | |
| 8 | Czechia | may show as "Czech Republic" |
| 9 | Hungary | |
| 10 | Romania | |
| 11 | Croatia | |
| 12 | Slovakia | |
| 13 | Slovenia | |
| 14 | Bulgaria | |
| 15 | Estonia | |
| 16 | Latvia | |
| 17 | Lithuania | |
| 18 | Greece | |
| 19 | Malaysia | |
| 20 | Thailand | |
| 21 | China mainland | the storefront is literally "China mainland" |
| 22 | South Africa | |

> **Japan check:** after setting Japan to the $2.99 USD point, confirm it displays **¥500**. If
> ASC shows a different yen amount, pick the **¥500** price point for Japan directly — clean yen
> wins.

### Tier 3 → **US$1.99** (17 storefronts)

> **Bangladesh is not an App Store storefront** — ASC has no Bangladesh territory. The override table originally listed 18 Tier 3 countries; the actual count is 17.

| # | Storefront | ASC name note |
|---|---|---|
| 1 | India | |
| 2 | Pakistan | |
| 3 | ~~Bangladesh~~ | *not an App Store storefront — skip* |
| 4 | Sri Lanka | |
| 5 | Indonesia | |
| 6 | Philippines | |
| 7 | Vietnam | |
| 8 | Brazil | |
| 9 | Colombia | |
| 10 | Peru | |
| 11 | Argentina | |
| 12 | Ecuador | |
| 13 | Turkey | may show as "Türkiye" |
| 14 | Egypt | |
| 15 | Nigeria | |
| 16 | Kenya | |
| 17 | Morocco | |
| 18 | Ukraine | |

---

## 3. How to run it (by hand, or with Claude in Chrome)

1. **Chrome** → **appstoreconnect.apple.com** → sign in (Apple ID + 2FA). (An agent acts inside
   *your* logged-in session; it cannot do the 2FA for you.)
2. Go to **My Apps → LinkClean → Monetization → In-App Purchases → LinkClean Pro**.
3. (Optional) automate it with **Claude for Chrome** — open the side panel and paste the
   ready-made prompt under **"Claude for Chrome — paste-ready prompt"** below. It self-checks and
   only applies the overrides if none are set yet, and pauses before Save. Stay at the keyboard —
   this touches billing.

### Steps (do once — single product)

1. Open the **LinkClean Pro** IAP → its **Price Schedule / Pricing** section.
2. **Tier 1 base:** confirm the price is **US$4.99**. It should already be set from product
   creation. If not, set it. Do **not** touch any other Tier 1 storefront — they follow the base.
3. **Apply the overrides:** open the per-territory price editor. For **every storefront in the
   Override Table (§2)**, set its price point:
   - Tier 2 storefronts → **$2.99**
   - Tier 3 storefronts → **$1.99**
   Work down the table; check each off. Do **not** touch any storefront **not** in the table.
4. **Japan:** confirm it reads **¥500**; if not, pick the ¥500 point directly.
5. If ASC asks for a **start date**, choose **now / immediately**. (No "existing subscribers"
   prompt will appear — this is a non-consumable.)
6. **PAUSE** before the final **Save**: confirm which product, how many storefronts changed
   (should be 39 — 22 Tier 2 + 17 Tier 3; Bangladesh is not an App Store storefront), and one Tier 2 + one Tier 3 sample price. Then Save.

**Never:** change a storefront outside the Override Table (Tier 1 stays at base); change any other
product; touch availability / Family Sharing (it's intentionally **OFF**) / offers; Save without a go.

### Claude for Chrome — paste-ready prompt (applies overrides only if none exist yet)

Sign in to App Store Connect in Chrome first (the agent can't do your 2FA), open **My Apps →
LinkClean → Monetization → In-App Purchases → LinkClean Pro**, then open the **Claude for Chrome**
side panel and paste everything in the box below. It runs a **Step 0 idempotency check** — if the
overrides are already set, it stops without touching anything.

```text
You are applying regional price overrides to ONE App Store Connect in-app purchase, acting only
inside my already-logged-in ASC session in this browser tab. This touches billing — follow this
exactly and PAUSE before any Save.

PRODUCT
- "LinkClean Pro" — a non-consumable in-app purchase (product ID: linkclean_pro_lifetime).
- Base price (Tier 1) = US$4.99 and MUST stay unchanged. Every storefront not listed below rides
  the base automatically — do not touch it.

STEP 0 — IDEMPOTENCY CHECK (before changing anything):
- Open the LinkClean Pro IAP → its Pricing / price schedule and read the current per-storefront
  prices.
- If overrides already exist (e.g. United States $4.99 while Japan ≈ ¥500, India ≈ $1.99, Poland
  ≈ $2.99), STOP and report "overrides already applied — nothing to do." Do NOT re-apply.
- Only continue if every storefront currently derives from the $4.99 base (no manual overrides).

STEP 1 — Confirm the base price point is US$4.99. Do not change it.

STEP 2 — Set these 22 storefronts to the US$2.99 price point (Tier 2):
Japan, Mexico, Chile, Uruguay, Costa Rica, Panama, Poland, Czechia (may show "Czech Republic"),
Hungary, Romania, Croatia, Slovakia, Slovenia, Bulgaria, Estonia, Latvia, Lithuania, Greece,
Malaysia, Thailand, China mainland, South Africa.

STEP 3 — Set these 17 storefronts to the US$1.99 price point (Tier 3):
India, Pakistan, Sri Lanka, Indonesia, Philippines, Vietnam, Brazil, Colombia, Peru,
Argentina, Ecuador, Turkey (may show "Türkiye"), Egypt, Nigeria, Kenya, Morocco, Ukraine.
(Bangladesh is not an App Store storefront — it does not appear in ASC; do not search for it.)

STEP 4 — Japan: confirm it displays ¥500; if it shows a different yen amount, pick the ¥500 price
point for Japan directly.

STEP 5 — If asked for a start date, choose now / immediately. (No "existing subscribers" prompt
appears — this is a non-consumable.)

NEVER:
- Never change a storefront that is not in the Step 2 or Step 3 list (Tier 1 stays at the base).
- Never change the base price, product availability, Family Sharing (intentionally OFF), offers,
  or any other product.
- Never click the final Save without my explicit "go."

BEFORE SAVE — pause and report: the product name, the number of storefronts you changed (must be
exactly 39 = 22 Tier 2 + 17 Tier 3; Bangladesh is not an App Store storefront — skip it), and one
Tier 2 and one Tier 3 sample price. Wait for me to reply "go," then Save.

AFTER SAVE — verify and report: United States = $4.99, Japan = ¥500, Poland ≈ $2.99, India ≈
$1.99, Germany still at Tier 1 (≈ base), and edited-storefront count = 39.
```

---

## 4. Verification checklist

- [x] United States = **$4.99** (unchanged base)
- [x] Japan = **¥500**
- [x] A Tier 2 sample (e.g. Poland) ≈ **$2.99**
- [x] A Tier 3 sample (e.g. India) ≈ **$1.99**
- [x] A random unlisted country (e.g. Germany) still at Tier 1 — confirms no over-edit
- [x] Count of edited storefronts = **39** (22 Tier 2 + 17 Tier 3 — Bangladesh is not an App Store storefront)

## 5. Notes / maintenance

- Overridden storefronts become **fixed** — Apple stops auto-adjusting them for FX. Glance once a
  year in case a currency drifts badly (high-inflation markets like Argentina/Turkey).
- Any **new country** Apple adds later defaults to **Tier 1** (the base), not a discount — move it
  into a tier manually if it belongs in 2 or 3.
- **Russia:** App Store purchases are suspended — can't sell there regardless; leave at default.
- To re-tier on real demand once data builds, pull installs-by-storefront (TelemetryDeck) and
  prune/extend Tier 3.
