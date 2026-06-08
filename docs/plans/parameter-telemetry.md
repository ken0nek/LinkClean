# Parameter Telemetry & Catalog-Gap Detection

Status: **Tier 0 + Tier 1 implemented** (2026-06-08); novel-tail decision (§9) still open
Date: 2026-06-08
Builds on: [docs/plans/analytics.md](analytics.md) (especially §3 Privacy, §6 Taxonomy)
Question driving this doc: *Can we collect data that grows the tracking-parameter catalog and informs the product — without weakening LinkClean's privacy claim?*

---

## 0. What shipped (2026-06-08)

The catalog-gap engine — Tier 0 + Tier 1 — is implemented and tested. **No bright line was crossed**: every signal is a count, a finite category id, or a *public* reference-catalog name.

- `ReferenceParameterCatalog` (kit) — a bundled, curated set of known trackers (~90), guaranteed disjoint from the default catalog.
- `URLCleaner.cleanResult` now returns `leftoverCount`, `removedKindIDs`, and `referenceMatches` from its single existing pass — no re-parsing, no new line crossed.
- `Home.URL.cleaned` and `Action.Clean.succeeded` carry `leftoverCount`, `referenceMatchCount`, `removedKinds` (Tier 0).
- `Parameters.Reference.observed` fires once per known-but-not-default tracker left behind (Tier 1), from Home and the Clean extension.

**Deliberately deferred** (see §6 notes and §11): the Tier 0 *behavior* signals (`recleaned` is redundant with `changed=false`; manual-edit-before-copy has no UI; structural shape is marginal); catalog-gap params on the **Markdown** action (different event family, out of the original scope); and expanding the reference list from ClearURLs/AdGuard (license review).

## 1. Goal

LinkClean's quality is bounded by one thing: **does our parameter catalog match the trackers that appear in real URLs?** Today we have no signal for the gap — we don't know which trackers we miss, how often, or which built-ins are dead weight (`TrackingParameterCatalog`, 7 kinds: utm, common, ads, analytics, email, social, affiliate).

We want telemetry that answers:

- **What are we missing?** Trackers in real URLs that our defaults don't remove.
- **How badly?** Frequency / size of the gap, to prioritize catalog work.
- **What's dead weight?** Built-ins that never fire, or that users distrust and disable.
- **Is the custom-parameter feature a catalog signal?** A param a user adds by hand is, by definition, a tracker they want gone that we don't have.

The constraint: do it **without crossing the line that makes our privacy claim simple and defensible.**

## 2. The bright line (current contract)

Our privacy claim is airtight *because it's simple*: **nothing derived from URL content ever leaves the device.** `analytics.md` §3 states this concretely:

> **Never collect:** URLs, hosts/domains, query strings, or any clipboard content — not even hashed … Custom parameter *names* (free-text user input; could contain anything) — track counts only.

The supporting code was built to honor it: before this work, `URLCleaner.cleanResult` reported only a removed *count* and never inspected parameter names for telemetry; `AnalyticsEvent` carries only enums, bucketed counts, booleans, and built-in (never user-authored) parameter names. (Tier 1 below deliberately extends the cleaner to classify leftover names against the *public* reference catalog — see §0.)

Any new collection here is measured against that line.

## 3. What's already covered

Two of the three initial ideas touch already-decided ground:

| Idea | Status | Note |
|---|---|---|
| Disabled default keys | **Already collected** | `Parameters.Default.toggled` sends the built-in name. Safe — finite, known set. Only a full-set *snapshot* per user is missing; marginal. |
| Custom parameter names | **On the §3 "never" list** | Reversing this is allowed, but must be a *conscious* §3 rewrite, not drift. See §6/§7. |
| Arbitrary URL query keys | **New** | The riskiest. See §4. |

## 4. The core tension

To discover trackers we *don't already know*, we must collect query keys we *can't enumerate in advance* — which is exactly the unbounded-content risk §3 was built to avoid:

- **Key names can be sensitive on their own:** `reset_password_token`, `patient_id`, `account=…`, `email=…`.
- **A set of keys fingerprints the page even with values stripped:** `[listing_id, host_id, check_in, adults]` = an Airbnb listing. The *value* never left, but the *page* did.

So "keys not values" is **not** automatically safe. The safety depends entirely on *which* keys and *how* they're transmitted.

## 5. The insight that resolves most of it

We don't need novel keys to fix most gaps. **Bundle a broad public reference list on-device** (ClearURLs / AdGuard / Brave rulesets — thousands of *known* tracker keys we don't yet remove by default). Then split every leftover key after cleaning:

| Leftover key | Privacy status | Action |
|---|---|---|
| Matches the bundled reference list (known tracker, *public* name) | **Safe** — name is already public, same risk class as `utm_source` | Report the name → grow the default set from real usage |
| Truly novel (matches nothing) | Unbounded content | Report as a bucketed *count* only, or surface on-device (§8) |

**~90% of "we missed one" cases are known trackers simply not in our defaults** — and those names are public, so reporting them carries no more risk than reporting `utm_source` does today. Only the genuinely-novel tail forces the hard decision.

## 6. Proposed data points, by risk tier

Signal names follow the `analytics.md` §5 convention (`Feature.Subject.verbPast`, ≤3 levels, bucketed numerics). Exact `AnalyticsEvent` encodings to be drafted once the §9 fork is decided.

### Tier 0 — no new privacy cost, ship now

Pure structure and behavior; nothing derived from key/value content.

| Signal / param | Answers |
|---|---|
| `leftoverCount: <bucket>` added to `Home.URL.cleaned` + `Action.Clean.succeeded` (params remaining after removal) | Sizes the catalog gap without naming anything — the safe proxy for "we're missing params" |
| `referenceMatchCount: <bucket>` (leftovers matching the bundled reference list) | How often a *known* tracker slips through our defaults |
| `removedKinds` (which of the 7 catalog kinds fired — finite, public, low-entropy set) | Which categories earn their keep → curation + IAP gating |
| `changed=false` rate by source *(already have `changed`)* | High rate = gaps; already flagged in `analytics.md` §6 |
| `Home.URL.recleaned` — user cleaned an already-clean URL (no-op) | Confusion / annoyance signal |
| Manual edit of the cleaned URL before copy | Our cleaning was wrong/incomplete |
| Structural shape: had-fragment, had-query, input param-count bucket | Trackers hiding in `#`; input-complexity distribution |

### Tier 1 — known reference names (safe, high-value)

| Signal / param | Answers |
|---|---|
| `Parameters.Reference.observed` — a known-but-not-default reference key appears in a real URL; `parameter: <public reference name>` | Directly grows the default catalog from public, safe names. The workhorse signal. |

### Tier 2 — crosses the line; only if we want the novel tail (gated on §9)

| Signal / param | Answers | Why gated |
|---|---|---|
| `Parameters.Unknown.observed` — novel key; `key: <filtered>` | The genuinely-new trackers no list has yet | Unbounded free-text content |
| `name` added to `Parameters.Custom.added` | Highest signal-to-noise gap source (user already judged it a tracker) | Free-text; currently §3-forbidden |

### Tier 3 — never

Parameter **values**; host/domain; the **full key-set of one URL in one event** (reassembles the page fingerprint).

## 7. Mitigations for the novel tail (Tier 2)

If we transmit unbounded keys, these stack as *multipliers* — none is sufficient alone, together they make it defensible:

- **No host** — already guaranteed; keys arrive without `airbnb.com`.
- **One event per key**, never one event listing all keys. (Reduces, doesn't eliminate, set-reassembly via user+timestamp correlation; residual is low because unknown keys per URL are rare.)
- **Charset/length filter** — transmit only `^[a-z0-9_]{1,32}$`; drop encoded/odd keys (filters most malformed PII).
- **Sampling** — don't send every occurrence.
- **k-user threshold by policy** — treat an unknown key as actionable only once *many* distinct users report it. Note: TelemetryDeck surfaces raw strings in the dashboard, so this is **discipline, not a technical guarantee** — weak for a privacy brand, and the reason §8 is preferred.

## 8. The brand-preserving alternative (recommended for the novel tail)

Instead of silently shipping unknown keys: **aggregate them on-device** in a capped local frequency table and **surface them as a feature** rather than telemetry.

This already has a home on the roadmap — the **"Leftover-parameter pills on Home"** idea in [docs/TODO.md](../TODO.md):

> After a URL is cleaned, inspect what query parameters remain. Surface each as a tappable pill … tapping adds it to custom tracking parameters, so it's removed automatically from then on. Turns a one-off observation into a persistent rule … so the catalog grows from real user links.

The privacy win: novel params reach us only as **user-consented custom additions** flowing through the existing safe `Parameters.Custom.added` count path — the bright line stays intact, and "LinkClean learns, on your device" becomes a *selling point* rather than a caveat.

For custom-parameter *names* specifically, a one-time opt-in — *"Help improve LinkClean's defaults? Share the parameter names you add (never your URLs)."* — converts a §3 violation into a consented contribution.

## 9. Open decision

For the **genuinely-novel tail only**, two paths fork the implementation:

| Path | Pros | Cons |
|---|---|---|
| **A. Silent telemetry** (Tier 2 + §7 mitigations) | Faster, denser data; no user friction | Caveated privacy claim; §3 rewrite; heavier nutrition label; mitigations are partly policy-only |
| **B. On-device + consented** (§8) | Bright line intact; becomes a feature; flows through existing safe paths | Slower data; depends on user action; needs the leftover-pills UI |

### Costs specific to Path A

1. **Caveated claim.** "We never see your URLs" becomes "…except parameter keys, but not values, anonymized…" Caveated privacy claims are structurally weaker for a privacy brand, regardless of anonymization quality.
2. **Nutrition label.** URL-derived keys may push us from the cleanest label position into a heavier disclosure category (browsing-adjacent data). Verify before committing — §3 already commits us to updating the label, and for a privacy app that label *is* the proof point. Blocks on [docs/TODO.md](../TODO.md) item 6 (Metadata).

## 10. Recommendation

- **Ship Tier 0 + Tier 1 now.** `leftoverCount` + the bundled reference list alone answer "what are we missing and how badly" with **zero line-crossing**. This is most of the product value.
- **Take Path B (§8) for the novel tail** — route it through the leftover-pills feature, not silent telemetry. Keeps the one-sentence privacy claim.
- **Custom parameter names:** collect only via the §8 consent opt-in, not silently. Until then, keep the count-only `Parameters.Custom.added` as-is.
- **Disabled defaults:** already covered; optionally add a periodic full-set snapshot if the per-toggle stream proves awkward to aggregate.

If Path A is chosen instead, the prerequisites are explicit: rewrite `analytics.md` §3, apply all §7 mitigations, re-evaluate the nutrition label, and document the practice in the public privacy policy — the defense is only worth something if users can see it.

## 11. Next steps

1. ~~Draft the concrete `AnalyticsEvent` cases + `Bucket` helpers for the Tier 0/1 signals.~~ **Done** (§0).
2. ~~Update `analytics.md` §3/§6 to reflect the Tier 0/1 signals.~~ **Done.**
3. **Expand the reference catalog** beyond the curated starter set, importing from a vetted public source (ClearURLs / AdGuard / Brave) — pending a license review. The mechanism is in place; expansion is data-only (no code change).
4. **Validate in TelemetryDeck** that `referenceMatchCount`/`Parameters.Reference.observed` actually surface real catalog gaps before relying on them for default-set curation.
5. Decide the §9 fork (A vs B) for the **novel tail** — still open, and the only remaining bright-line question.
6. Consider catalog-gap params on the **Markdown** action if extension-surface data proves valuable.

> **Extension delivery note (§8 interaction):** in the Clean extension, `Action.Clean.succeeded` is captured *before* the per-match `Parameters.Reference.observed` signals, so the priority event uses the scarce in-process network window first. Reference-observed signals persist and converge in aggregate across runs — exactly the delivery model §8 documents, and all catalog-gap curation needs are aggregate.
