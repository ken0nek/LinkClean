#!/usr/bin/env bash
# Gather the raw signals for a LinkClean analytics audit in one shot: the declared
# event taxonomy (the AnalyticsEvent enum), the wire signal names, every capture()
# call site, per-event coverage, the SDK-boundary invariant, and a PII smell test.
# Read it, don't skim it — the call-site list + the coverage tally usually tell you
# 80% of the story.
#
# Usage:  bash .claude/skills/analytics-audit/scripts/gather-analytics-signals.sh
# No args. Reads current working-tree state (an audit, not a since-baseline diff).
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$ROOT" || exit 1

KIT="LinkCleanKit/Sources/LinkCleanKit"
TAXONOMY="$KIT/AnalyticsEvent.swift"   # the typed taxonomy — every signal is a case here
SERVICE="$KIT/AnalyticsService.swift"  # the capture(_:) protocol
SINK="$KIT/TelemetryDeckAnalytics.swift" # the ONLY type allowed to touch the SDK
PLAN="docs/plans/analytics.md"
GAP_PLAN="docs/plans/parameter-telemetry.md"
# App + extension + kit + test source roots. Missing dirs are harmless (grep finds nothing).
SRC=(LinkClean LinkCleanAction LinkCleanMarkdownAction "$KIT" LinkCleanKit/Tests LinkCleanTests)
GREP=(grep -rn --include='*.swift' --exclude-dir=.build --exclude-dir=DerivedData)

echo "========== TAXONOMY: $TAXONOMY =========="
if [[ ! -f "$TAXONOMY" ]]; then
  echo "  !! AnalyticsEvent.swift not found — has it moved? Adjust TAXONOMY in this script."
  exit 1
fi
echo "  (the single source of truth — every iOS signal is a case here)"

echo
echo "========== [1] DECLARED EVENT CASES (top-level enum members) =========="
# Event cases sit at 4-space indent inside the enum; nested param-enum cases sit deeper.
grep -nE '^    case [a-z]' "$TAXONOMY" | sed -E 's/\(.*$//'
decl_count=$(grep -cE '^    case [a-z]' "$TAXONOMY")
echo "  → $decl_count declared event cases"

echo
echo "========== [2] WIRE SIGNAL NAMES (the Feature.Subject.verb strings) =========="
# The canonical names from the signalName switch — these are what shows in TelemetryDeck.
grep -oE '"[A-Za-z]+\.[A-Za-z]+\.[A-Za-z]+"' "$TAXONOMY" | sort -u
sig_count=$(grep -oE '"[A-Za-z]+\.[A-Za-z]+\.[A-Za-z]+"' "$TAXONOMY" | sort -u | wc -l | tr -d ' ')
echo "  → $sig_count distinct signal names  (should match the $decl_count declared cases)"

echo
echo "========== [3] CALL SITES (every analytics.capture(.event(...)) outside the kit defn) =========="
"${GREP[@]}" '\.capture(\.' "${SRC[@]}" 2>/dev/null \
  || echo "  (none found — unexpected; the app should emit events)"
echo
echo "  --- call-site count per event (coverage: every declared case should have >=1) ---"
"${GREP[@]}" -oE '\.capture\(\.[a-zA-Z]+' "${SRC[@]}" 2>/dev/null \
  | sed -E 's/^.*\.capture\(\.//' | sort | uniq -c | sort -rn

echo
echo "========== [4] COVERAGE: declared cases with NO call site =========="
# Declared event identifiers...
grep -oE '^    case [a-z][a-zA-Z]*' "$TAXONOMY" | sed -E 's/^    case //' | sort -u > /tmp/lc_declared.$$
# ...vs identifiers actually captured somewhere.
"${GREP[@]}" -oE '\.capture\(\.[a-zA-Z]+' "${SRC[@]}" 2>/dev/null \
  | sed -E 's/^.*\.capture\(\.//' | sort -u > /tmp/lc_called.$$
missing=$(comm -23 /tmp/lc_declared.$$ /tmp/lc_called.$$)
if [[ -z "$missing" ]]; then
  echo "  ✓ every declared event has at least one call site."
else
  echo "  !! declared but never emitted (dead taxonomy, or wired via a path this grep missed):"
  echo "$missing" | sed 's/^/     - /'
fi
rm -f /tmp/lc_declared.$$ /tmp/lc_called.$$

echo
echo "========== [5] INVARIANT: SDK boundary — no raw TelemetryDeck SDK use outside the sink =========="
echo "  (referencing the TelemetryDeckAnalytics conformer is fine — only raw 'TelemetryDeck.' / 'import TelemetryDeck' is a violation)"
hits=$("${GREP[@]}" -E '(import TelemetryDeck$|TelemetryDeck\.)' "${SRC[@]}" 2>/dev/null \
  | grep -v "$SINK" | grep -vE 'Package\.swift' || true)
if [[ -z "$hits" ]]; then
  echo "  ✓ none — every signal routes through TelemetryDeckAnalytics.swift."
else
  echo "  !! VIOLATION — these touch the SDK directly (route them through AnalyticsService instead):"
  echo "$hits"
fi

echo
echo "========== [6] PII smell test (params that might carry user-authored / unbounded text) =========="
echo "  (heuristic — review each: any URL/host/query/title/search/name/path/content key is suspect)"
grep -inE '"(url|host|query|querystring|title|text|search|name|path|address|email|input|content|link)"[[:space:]]*:' "$TAXONOMY" \
  || echo "  ✓ no obviously user-authored param keys."
echo
echo "  --- String-typed associated values (only the finite-catalog 'parameter:' is allowed) ---"
grep -nE 'parameter:[[:space:]]*String|:[[:space:]]*String[,)]' "$TAXONOMY" | grep -iE 'String' \
  || echo "  (none)"
echo "  → confirm every String above is a finite catalog id (default catalog or ReferenceParameterCatalog),"
echo "    never a URL/host/query/title/search text or a user's custom-parameter name (analytics.md §3)."

echo
echo "========== [7] THE PLAN (audit against THIS, not generic best practice) =========="
for d in "$PLAN" "$GAP_PLAN"; do
  if [[ -f "$d" ]]; then
    echo "  $d — section headers:"
    grep -nE '^#{1,3} ' "$d" | head -40
  else
    echo "  (not found at $d — ask where the analytics/parameter-telemetry plan lives)"
  fi
  echo
done

echo "========== [8] OTHER DATA SOURCE (this script covers ONLY the iOS event layer) =========="
echo "  LinkClean has TWO sources total — TelemetryDeck (above) and App Store Connect."
echo "  There is NO server: no Langfuse, no Cloudflare, no LLM cost to track."
echo "    App Store Connect  →  installs / sessions / crashes today; conversion / proceeds once IAP ships (1.1.0)."
echo "                          Dashboard-only; route listing/ASO work to the app-store-optimization skill."
echo
echo "========== DONE =========="
echo "Next: read $PLAN + $GAP_PLAN, map each product question to a decision AND a source (step 2),"
echo "then walk the funnel for gaps (step 3). Lead any pre-IAP recommendation with the monetization funnel."
