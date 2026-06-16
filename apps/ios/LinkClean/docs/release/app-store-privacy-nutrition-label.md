# App Store Privacy Nutrition Label — LinkClean 1.0.0

How to fill out **App Store Connect → your app → App Privacy** ("App Privacy Details").
Based on TelemetryDeck's official guidance ([Apple app privacy setup](https://telemetrydeck.com/docs/articles/apple-app-privacy/)) and an audit of exactly what LinkClean transmits (`AnalyticsEvent` taxonomy in `LinkCleanKit`).

LinkClean's only data egress is TelemetryDeck analytics. The Markdown/History title fetch goes **directly to the destination website** (not to us and not to a third-party SDK), so it is **not** a nutrition-label data collection by your app — no entry is needed for it.

## Step 1 — "Do you collect data from this app?"

**Yes, we collect data from this app.**

## Step 2 — Data types

Declare exactly three, all for **Analytics** purpose only:

| Apple data type | Category | Collected? | Linked to identity? | Used for tracking? | Purpose |
|---|---|---|---|---|---|
| **Device ID** | Identifiers | Yes | **No** | **No** | Analytics |
| **Product Interaction** | Usage Data | Yes | **No** | **No** | Analytics |
| **Browsing History** | Browsing History | Yes | **No** | **No** | Analytics |

**Browsing History** covers the **site domain of cleaned links** (host only, e.g. `youtube.com`) added to the clean events on 2026-06-09 (`docs/plans/analytics.md` §3 "Collected, with disclosure"). Only the host is sent — never the full URL, path, query string, or values — but because it is the domain of a site the user is acting on, Apple's **Browsing History** is the correct, conservative bucket (under-declaring risks an App Review rejection; over-declaring is safe). Still Not Linked, Not Tracking.

Everything else — Contact Info, Health, Financial, Location (precise *or* coarse), Contacts, User Content, Search History, Purchases, Diagnostics, etc. — **No, not collected.**

Notes on specific tempting-but-no entries:
- **Location:** No. LinkClean sends *locale/region* (e.g. `en_US`) as standard metadata; that is not "Location" in Apple's sense, and TelemetryDeck stores no IP address.
- **Diagnostics / Crash / Performance Data:** No. LinkClean sends no crash or performance telemetry.
- **Search History:** No. "History.Search.used" records only *that* a search happened, never the query.
- **Browsing History:** **Yes** (added 2026-06-09) — the **site domain** of cleaned links (host only, e.g. `youtube.com`); never the full link, path, query, or values, which still never leave the device. Declared in the table above.
- **Purchases:** No for 1.0.0 (no IAP). **When RevenueCat ships in 1.1.0, add `Purchase History` → Analytics.**

## Step 3 — Tracking

When asked whether you use data to track users: **No.** No ATT prompt, no advertising, no data shared with data brokers.

## Device ID vs. User ID — the one judgment call

LinkClean calls `TelemetryDeck.updateDefaultUserID(...)` with a **randomly generated per-install UUID** (salted + hashed on-device; not derived from any email, account, or personal info). TelemetryDeck's guidance reserves the **User ID** data type for *real* custom identifiers "like email/username." Because this UUID is an anonymous per-installation value, **Device ID is the correct and more accurate bucket** — declare Device ID, not User ID.

Either way the answers that matter are identical: **Linked = No, Tracking = No.** If you ever prefer maximum caution, declaring it additionally under User ID (still Not Linked / Not Tracking) is defensible and not wrong — but Device ID alone is the recommendation.

## Privacy Manifest (separate from this form)

TelemetryDeck's SwiftSDK 1.5.0+ bundles a **Privacy Manifest** that auto-declares these same labels and the required-reason API usage. LinkClean resolves the SDK at **2.14.1** (`LinkCleanKit/Package.resolved`), so the manifest is already present and shipping. It does **not** replace this App Store Connect form — keep the two consistent (they are, with the selections above).

## One-line summary for the submission

> LinkClean collects anonymous Device ID, Product Interaction, and the site domain of cleaned links (Browsing History) for Analytics only — not linked to identity, not used for tracking. Only a cleaned link's domain is ever sent; the full link, its path, query, and values never leave the device.
