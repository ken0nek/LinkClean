/**
 * Reciprocal-link verifier for the /trackers/ glossary.
 *
 * Anti-thinness gate from the programmatic-SEO playbook: every spoke's
 * `related` reference must be (a) a real slug and (b) reciprocated by the
 * target spoke. Catches dead refs from typos and unidirectional links from
 * forgetting the reciprocal-update step in a batch.
 *
 * Run with: pnpm verify-links  (from apps/landing/)
 */

import { TRACKERS } from "../src/trackers/data";

interface Violation {
  kind: "dead-ref" | "missing-reciprocal" | "self-ref";
  slug: string;
  related: string;
  detail?: string;
}

function verify(): Violation[] {
  const violations: Violation[] = [];
  const bySlug = new Map(TRACKERS.map((s) => [s.slug, s]));

  for (const spoke of TRACKERS) {
    for (const r of spoke.related ?? []) {
      if (r === spoke.slug) {
        violations.push({ kind: "self-ref", slug: spoke.slug, related: r });
        continue;
      }
      const target = bySlug.get(r);
      if (!target) {
        violations.push({ kind: "dead-ref", slug: spoke.slug, related: r });
        continue;
      }
      const reciprocates = (target.related ?? []).includes(spoke.slug);
      if (!reciprocates) {
        violations.push({
          kind: "missing-reciprocal",
          slug: spoke.slug,
          related: r,
          detail: `${r}.related is missing ${spoke.slug}`,
        });
      }
    }
  }
  return violations;
}

function main(): void {
  const violations = verify();

  // Coverage stats
  const total = TRACKERS.length;
  const withRelated = TRACKERS.filter((s) => (s.related?.length ?? 0) > 0).length;
  const totalLinks = TRACKERS.reduce((n, s) => n + (s.related?.length ?? 0), 0);

  console.log(
    `\n/trackers/ verify-links — ${total} spokes, ${withRelated} have related, ${totalLinks} total cross-references`,
  );

  if (violations.length === 0) {
    console.log("  ✓ All `related` references are valid + reciprocal");
    process.exit(0);
  }

  console.log(`  ✗ ${violations.length} violation(s):\n`);
  const byKind = new Map<Violation["kind"], Violation[]>();
  for (const v of violations) {
    const list = byKind.get(v.kind) ?? [];
    list.push(v);
    byKind.set(v.kind, list);
  }

  for (const [kind, list] of byKind) {
    console.log(`  [${kind}] (${list.length})`);
    for (const v of list) {
      const detail = v.detail ? ` — ${v.detail}` : "";
      console.log(`    ${v.slug}.related = "${v.related}"${detail}`);
    }
    console.log("");
  }

  process.exit(1);
}

main();
