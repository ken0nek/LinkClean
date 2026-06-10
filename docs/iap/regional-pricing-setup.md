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

### Tier 3 → **US$1.99** (18 storefronts)

| # | Storefront | ASC name note |
|---|---|---|
| 1 | India | |
| 2 | Pakistan | |
| 3 | Bangladesh | |
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
3. (Optional) open the **Claude for Chrome** side panel, point it at this file, and say:
   *"Follow this exactly. Pause for my confirmation before Save."* Stay at the keyboard — this
   touches billing.

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
   (should be 40), and one Tier 2 + one Tier 3 sample price. Then Save.

**Never:** change a storefront outside the Override Table (Tier 1 stays at base); change any other
product; touch availability / Family Sharing (it's intentionally **OFF**) / offers; Save without a go.

---

## 4. Verification checklist

- [ ] United States = **$4.99** (unchanged base)
- [ ] Japan = **¥500**
- [ ] A Tier 2 sample (e.g. Poland) ≈ **$2.99**
- [ ] A Tier 3 sample (e.g. India) ≈ **$1.99**
- [ ] A random unlisted country (e.g. Germany) still at Tier 1 — confirms no over-edit
- [ ] Count of edited storefronts = **40** (22 Tier 2 + 18 Tier 3)

## 5. Notes / maintenance

- Overridden storefronts become **fixed** — Apple stops auto-adjusting them for FX. Glance once a
  year in case a currency drifts badly (high-inflation markets like Argentina/Turkey).
- Any **new country** Apple adds later defaults to **Tier 1** (the base), not a discount — move it
  into a tier manually if it belongs in 2 or 3.
- **Russia:** App Store purchases are suspended — can't sell there regardless; leave at default.
- To re-tier on real demand once data builds, pull installs-by-storefront (TelemetryDeck) and
  prune/extend Tier 3.
