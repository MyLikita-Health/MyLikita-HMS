#!/usr/bin/env node
/**
 * generate-changelog.mjs
 *
 * Parses recent git commits and generates changelog entries formatted for
 * the MyLikita docs ChangelogDoc component.
 *
 * Usage:
 *   node scripts/generate-changelog.mjs                  # last 30 days
 *   node scripts/generate-changelog.mjs --days 60        # last 60 days
 *   node scripts/generate-changelog.mjs --since 2026-08-01
 *   node scripts/generate-changelog.mjs --output changelog.json
 *   node scripts/generate-changelog.mjs --update-doc     # auto-update ChangelogDoc.jsx
 *
 * Commit message conventions (Conventional Commits):
 *   feat: ...       → New
 *   fix: ...        → Fixed
 *   perf: ...       → Improved
 *   refactor: ...   → Improved
 *   docs: ...       → (skipped)
 *   chore: ...      → (skipped unless --all)
 *   ci: ...         → (skipped)
 *   test: ...       → (skipped)
 *
 * The script groups commits by date and outputs a structured JSON that
 * can be consumed by the ChangelogDoc component or printed as markdown.
 */

import { execSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, "..");

// ─── CLI args ────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);

function getArg(name, fallback) {
  const idx = args.indexOf(`--${name}`);
  if (idx === -1) return fallback;
  return args[idx + 1] || fallback;
}

const DAYS = parseInt(getArg("days", "30"), 10);
const SINCE = getArg("since", null);
const OUTPUT = getArg("output", null);
const UPDATE_DOC = args.includes("--update-doc");
const INCLUDE_ALL = args.includes("--all");
const DRY_RUN = args.includes("--dry-run");

// ─── Git log ─────────────────────────────────────────────────────────────────

const sinceDate = SINCE || (() => {
  const d = new Date();
  d.setDate(d.getDate() - DAYS);
  return d.toISOString().split("T")[0];
})();

const gitLog = execSync(
  `git log --since="${sinceDate}" --no-merges --format="%H|%ad|%s" --date=short`,
  { cwd: ROOT, encoding: "utf-8" }
).trim();

if (!gitLog) {
  console.log("No commits found in the specified date range.");
  process.exit(0);
}

const commits = gitLog.split("\n").map((line) => {
  const [hash, date, ...msgParts] = line.split("|");
  return { hash, date, message: msgParts.join("|") };
});

// ─── Categorize commits ──────────────────────────────────────────────────────

const TYPE_MAP = {
  feat: "feature",
  fix: "fix",
  perf: "improvement",
  refactor: "improvement",
};

const SKIP_PREFIXES = ["docs", "ci", "test", "chore"];

const LABEL_MAP = {
  feature: "New",
  improvement: "Improved",
  fix: "Fixed",
};

function parseCommit(msg) {
  // Conventional commit: feat(scope): description
  const match = msg.match(/^(\w+)(?:\(([^)]+)\))?\s*:\s*(.+)/i);
  if (match) {
    const [, type, scope, description] = match;
    const lowerType = type.toLowerCase();

    if (SKIP_PREFIXES.includes(lowerType) && !INCLUDE_ALL) {
      return null; // skip
    }

    const category = TYPE_MAP[lowerType];
    if (!category) {
      if (INCLUDE_ALL) {
        return { category: "feature", scope, title: description.trim() };
      }
      return null;
    }

    return {
      category,
      scope: scope || null,
      title: description.trim(),
    };
  }

  // Non-conventional: treat as feature
  return {
    category: "feature",
    scope: null,
    title: msg.trim(),
  };
}

const entries = [];
for (const commit of commits) {
  const parsed = parseCommit(commit.message);
  if (!parsed) continue;
  entries.push({
    ...parsed,
    hash: commit.hash.slice(0, 7),
    date: commit.date,
  });
}

// ─── Group by date ───────────────────────────────────────────────────────────

const grouped = {};
for (const entry of entries) {
  if (!grouped[entry.date]) grouped[entry.date] = [];
  grouped[entry.date].push(entry);
}

// Sort dates descending
const sortedDates = Object.keys(grouped).sort((a, b) => b.localeCompare(a));

// ─── Output ──────────────────────────────────────────────────────────────────

// Format as structured JSON
const changelog = {
  generatedAt: new Date().toISOString(),
  since: sinceDate,
  totalCommits: commits.length,
  entriesIncluded: entries.length,
  dates: sortedDates.map((date) => ({
    date,
    entries: grouped[date].map((e) => ({
      type: e.category,
      label: LABEL_MAP[e.category],
      title: e.title,
      scope: e.scope,
      hash: e.hash,
    })),
  })),
};

if (OUTPUT) {
  writeFileSync(resolve(ROOT, OUTPUT), JSON.stringify(changelog, null, 2));
  console.log(`✅ Changelog written to ${OUTPUT}`);
  console.log(`   ${entries.length} entries from ${sortedDates.length} dates`);
} else {
  // Print as readable text
  console.log(`\n📰 Changelog (since ${sinceDate})\n${"─".repeat(50)}`);
  for (const date of sortedDates) {
    console.log(`\n📅 ${date}`);
    for (const e of grouped[date]) {
      const icon = e.category === "feature" ? "🆕" : e.category === "fix" ? "🔧" : "✨";
      console.log(`  ${icon} [${LABEL_MAP[e.category]}] ${e.title}`);
    }
  }
  console.log(`\n${"─".repeat(50)}`);
  console.log(`Total: ${entries.length} entries from ${commits.length} commits\n`);
}

// ─── Auto-update ChangelogDoc.jsx ────────────────────────────────────────────

if (UPDATE_DOC) {
  const docPath = resolve(ROOT, "frontend/src/components/docs/modules/ChangelogDoc.jsx");
  let doc = readFileSync(docPath, "utf-8");

  // Find the first ChangelogDate and insert new entries before it
  const insertMarker = "{/* ── August 2026 ──────────────────────────────────────────────── */}";

  // Build new entries JSX
  let newEntries = "";
  for (const date of sortedDates) {
    newEntries += `\n        <ChangelogDate date="${formatDate(date)}" />\n\n`;
    for (const e of grouped[date]) {
      const escapedTitle = e.title.replace(/"/g, '\\"');
      newEntries += `        <ChangelogEntry\n          type="${e.category}"\n          title="${escapedTitle}"\n          description="${escapedTitle}"\n        />\n\n`;
    }
  }

  if (doc.includes(insertMarker)) {
    doc = doc.replace(insertMarker, newEntries + "\n" + insertMarker);
    writeFileSync(docPath, doc);
    console.log(`✅ Updated ${docPath}`);
  } else {
    console.log("⚠️  Could not find insertion marker in ChangelogDoc.jsx");
    console.log("   New entries were not inserted. Use the JSON output manually.");
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function formatDate(isoDate) {
  const d = new Date(isoDate + "T00:00:00");
  return d.toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}
