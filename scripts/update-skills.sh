#!/usr/bin/env bash
# Re-install / refresh every skill pinned in skills-lock.json by calling
# `npx skills add` with the FULL repo subpath reconstructed from each lock
# entry. Use this instead of `npx skills experimental_install` whenever the
# lock contains nested skills (e.g. openai/plugins keeps theirs under
# plugins/build-ios-apps/skills/<name>/SKILL.md).
#
# Why: experimental_install drops the lockfile skillPath and skill discovery
# stops at the first root-level SKILL.md it finds — nested entries silently
# fail with "No matching skills found". `skills add <repo>/<subpath>` accepts
# the deep path directly. Tracked upstream as vercel-labs/skills#1376; delete
# this script once that's fixed.
#
# Borrowed from whyzard/scripts/update-skills.sh (same bug, same fix).
# Requires: jq, network (npx resolves the skills CLI + shallow-clones per skill)
set -euo pipefail
cd "$(dirname "$0")/.."

pairs="$(jq -r '
  .skills | to_entries[] |
  "\(.key) \(.value.source)/\(.value.skillPath | sub("(^|/)SKILL\\.md$"; ""))\(if .value.ref then "#\(.value.ref)" else "" end)"
' skills-lock.json)"

failed=""
while read -r name source; do
  [[ -n "$name" ]] || continue
  echo "=== ${name}"
  npx skills add "$source" --skill "$name" -y </dev/null || failed="$failed $name"
done <<<"$pairs"

if [[ -n "$failed" ]]; then
  echo "Failed to update:$failed" >&2
  exit 1
fi
