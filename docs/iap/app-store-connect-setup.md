# LinkClean Pro — App Store Connect setup (hand-off)

> What **Ken** must do in App Store Connect (and on a device) to make the 1.1 in-app purchase real. Everything on the **code** side is done and verified locally — see `../plans/iap-implementation-plan.md`. There is **no RevenueCat** and **no server**: this is a single StoreKit 2 non-consumable.
> Modelled on Whyzard's IAP go-live runbook, trimmed to a one-product, no-server, no-subscription app.

## The one fact that must match everywhere

**Product ID: `linkclean_pro_lifetime`** (non-consumable). It is hard-coded in the app (`StoreKitEntitlementsService.lifetimeProductID`) and in `LinkClean/LinkClean.storekit`. The ASC product ID must be **exactly** this string, or the app loads no product and the paywall shows "store unavailable."

---

## 0. Prerequisites (longest lead time — start first)

- [x] **Paid Applications Agreement** active (App Store Connect → Business → Agreements). Without it you cannot create or sell IAPs, and **sandbox purchases won't work**.
- [x] **Banking + Tax** forms complete (same Agreements area).
- [x] **Small Business Program** enrolled (15% commission instead of 30%). The strategy's net-revenue math assumes this. Apply at developer.apple.com → Account → Small Business Program. *(Enrollment can lag; not a blocker for testing, but enroll before you have meaningful sales.)*

---

## 1. Create the in-app purchase

App Store Connect → **My Apps → LinkClean → Monetization → In-App Purchases → ➕**

| Field | Value |
|---|---|
| **Type** | **Non-Consumable** |
| **Reference Name** | `LinkClean Pro` (internal only) |
| **Product ID** | **`linkclean_pro_lifetime`** ← must match the code exactly |
| **Price** | **$4.99** (USD base / Tier 1) — then apply 3-tier regional pricing (see note below) |
| **Family Sharing** | **OFF** — leave unchecked; a one-time unlock isn't family-shared (strategy §4) |
| **Availability** | All territories (set regional price points later if desired, strategy §5) |

**Localization (en-US)** — App Store Localization → add English (U.S.):
- **Display Name:** `LinkClean Pro`
- **Description:** `Everything unlocked, forever — one purchase.` *(44 chars — the field caps around 45; the full detail lives in the review notes below)*

**Review information:**
- **Screenshot (required):** a screenshot of the **paywall**. Capture it with the **`LinkClean (StoreKit)`** scheme (Xcode → scheme picker → `LinkClean (StoreKit)` → Run; the local `.storekit` makes the product load), open the paywall (Settings → "Unlock Pro", or the DEBUG Developer menu → "Preview Paywall · settingsRow"), and screenshot the simulator. Any valid screenshot size is accepted for IAP review.
- **Review notes (suggested):**
  > One-time purchase ("LinkClean Pro"). Unlocks: unlimited custom tracking-parameter rules, full history beyond the free 7-day window, and future Pro features. Reachable from **Settings → LinkClean Pro**, and from gated taps (History "Earlier" archive; Custom Parameters → Add after the 1 free rule; a Home "Remaining" pill after the 1 free rule). **Restore Purchases** is in Settings and on the paywall. No account or login.

> ℹ️ **Regional pricing:** after creating the product at the **$4.99 base**, apply the 3-tier geographic pricing (Tier 2 $2.99 / Tier 3 $1.99, 40 storefronts) with the runbook in **`regional-pricing-setup.md`**. Do it anytime — a non-consumable price change affects only *future* buyers (no consent/notification machinery).

---

## 2. App Privacy (nutrition label) — keep "Purchases: No"

The 1.0 label declared **Purchases: No** (no IAP). **That stays true for 1.1.**

- **The purchase itself** (StoreKit, on Apple's servers) is **not** "data your app collects" — no change needed for StoreKit alone.
- **Revenue analytics was dropped** — decision 2026-06-10, superseding the earlier same-day "keep it + declare." The app no longer calls `TelemetryDeck.purchaseCompleted(transaction:)`, so **no transaction, product, price, or amount** is sent anywhere. Dollars come from **App Store Connect sales reports**, not TelemetryDeck. *(Why: TelemetryDeck revenue is "live, not correct" — no dedup — so it double-counts cross-device/reinstall restores; ASC is the source of truth for revenue.)*
- The remaining purchase **funnel events** — `Pro.Purchase.started / completed / failed / restored` and `Paywall.Screen.shown` — carry **no amount, price, or transaction ID**. They're conversion/usage signals → **Product Interaction**, which the label **already declares**. So they need **no new data type**. (Apple's "Purchases" type means purchase *history* — what was bought and the amount; a no-amount conversion event is an interaction, not a purchase record.)

**Action (Ken):**
- [x] **Removed** the **Purchases → Analytics** declaration in the App Privacy questionnaire → reverted to **Purchases: No** (done 2026-06-10). Nothing else on the label changed.
- The `tier: free/pro` analytics dimension stays under the existing **Product Interaction** (a coarse feature-access flag, not a transaction record).

---

## 3. Terms of Use (EULA) — required before submission

App Review requires the paywall's **Terms of Use** + **Privacy Policy** links to resolve. The paywall links to:
- Terms: `https://ken0nek.com/apps/linkclean/terms-of-use/`
- Privacy: `https://ken0nek.com/apps/linkclean/privacy-policy/`

- [x] **Terms of Use page published** and live — the paywall's Terms + Privacy links both resolve.
- [ ] In ASC → App Information → **License Agreement**, the standard Apple EULA is fine unless you have a custom one; the in-app Terms link is what reviewers check.

---

## 4. Submit (first review couples the IAP to the build)

For the **first** review, the IAP and the app version are reviewed together:

- [ ] Attach **`linkclean_pro_lifetime`** to the **1.1 build** in the version's "In-App Purchases" section before submitting.
- [ ] The IAP status should move to **"Ready to Submit"** (green) — needs the localization + screenshot + review notes above.
- [ ] Submit the 1.1 version for review with the IAP attached.

**App Review Information → Notes (Optional) — suggested text** (paste into the version's *Review Notes* field; it points the reviewer straight at the IAP + Restore):

> LinkClean 1.1 adds one in-app purchase: **LinkClean Pro** (`linkclean_pro_lifetime`), a non-consumable **one-time purchase** — no subscription, no account, no login, no server. The core link-cleaning is free and fully functional without it.
>
> **Pro unlocks:** unlimited custom tracking-parameter rules, full cleaning history (the free tier keeps the last 7 days), and future Pro features.
>
> **Reach the paywall:** Settings → "LinkClean Pro" → "Unlock Pro". It also appears on gated taps — the History "Earlier" archive, Custom Parameters → Add (after the 1 free rule), and the Home "Remaining" pill (after the 1 free rule).
>
> **Restore Purchases** is in Settings and on the paywall, reachable without buying.
>
> **Privacy:** all cleaning happens on-device — full links, clipboard, and typed text never leave. The only datum derived from a link is its **bare site domain** (host only, e.g. `youtube.com`), sent anonymously and in aggregate (TelemetryDeck) and declared under **App Privacy → Browsing History** (Analytics; not linked to identity, not used for tracking). **No purchase, transaction, or price data is collected** — purchase processing is entirely Apple's, and revenue is read from App Store Connect.

---

## 5. Test before submitting (device + sandbox)

- [ ] **Simulator (no ASC needed):** run the **`LinkClean (StoreKit)`** scheme → buy / cancel / restore / request-a-refund all work against the local `.storekit`. Toggle the **Developer menu → Entitlement Override** (Off / Free / Pro) to exercise the gates without purchasing.
- [ ] **Device + Sandbox Apple Account** (after the Paid Apps Agreement is active): create a Sandbox tester in ASC → Users and Access → Sandbox, sign in on the device (Settings → Developer → Sandbox Apple Account), and run a real sandbox purchase + restore. Confirm the entitlement persists after a relaunch and after deleting/reinstalling + Restore.

---

## Quick checklist

```
[x] Paid Apps Agreement + Banking/Tax active
[x] Small Business Program enrolled (15%)
[x] IAP created: Non-Consumable, linkclean_pro_lifetime, $4.99 base, Family Sharing OFF
[ ] Regional 3-tier pricing applied — regional-pricing-setup.md (40 storefronts: 22×$2.99, 18×$1.99)
[x] en-US localization (display name + description)
[ ] Paywall review screenshot + review notes
[x] App Privacy: Purchases → Analytics declaration removed → "Purchases: No" (revenue tracking dropped 2026-06-10; funnel events are Product Interaction, already declared)
[x] Terms of Use page published (links resolve)
[ ] IAP attached to the 1.1 build, status Ready to Submit
[ ] Sandbox purchase + restore verified on device
```

## What is NOT needed (because it's StoreKit 2, not RevenueCat)

- ❌ No RevenueCat account, dashboard, entitlement, offering, or API key.
- ❌ No App Store Server Notifications URL / server endpoint (a non-consumable's refund arrives on-device via `Transaction.updates`).
- ❌ No server-side receipt validation.
- ❌ fastlane `deliver` does **not** manage IAP products — all of section 1 is done by hand in the ASC UI.
