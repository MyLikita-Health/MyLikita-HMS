#!/usr/bin/env node
'use strict';

/**
 * check-bundles.js — build-time syntax guard for the frontend bundle.
 *
 * The MyLikita-Setup-0.1.0 release shipped a frontend bundle whose V8
 * parse-time SyntaxError ("Invalid regular expression ... Range out of order
 * in character class") crashed the whole app on load — a blank white page
 * with zero React. The error only appears when the browser parses the bundle,
 * so `vite build` never caught it (esbuild is lenient; V8 is not).
 *
 * This script walks the freshly-built frontend/dist and parses every emitted
 * .js file with acorn (the same parser semantics as V8's class-range rules).
 * The build fails loudly if ANY bundle is unparseable, so a bad regex can
 * never reach a client again.
 *
 * Usage:
 *   node check-bundles.js <frontendDistDir> <frontendNodeModulesDir>
 *   exit code 0 = all bundles parse, 1 = at least one bundle is broken.
 */

const fs = require('fs');
const path = require('path');

const distDir = path.resolve(process.argv[2] || '');
const nodeModulesDir = path.resolve(process.argv[3] || path.join(path.dirname(distDir), 'node_modules'));

if (!distDir || !fs.existsSync(distDir)) {
  console.error('[check-bundles] Missing dist dir:', distDir);
  process.exit(1);
}

// acorn ships as a dependency of vite/rollup — it is always present in the
// frontend's node_modules after `npm install` in build-installer.bat.
let acorn;
try {
  acorn = require(path.join(nodeModulesDir, 'acorn'));
} catch (e) {
  console.error('[check-bundles] Could not load acorn from:', nodeModulesDir);
  console.error(e.message);
  process.exit(1);
}

let checked = 0;
let failed = 0;
const failures = [];

function walk(dir) {
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch (e) {
    return;
  }
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full);
    } else if (entry.isFile() && entry.name.endsWith('.js')) {
      checked += 1;
      try {
        acorn.parse(fs.readFileSync(full, 'utf8'), {
          ecmaVersion: 'latest',
          sourceType: 'module',
          allowHashBang: true,
        });
      } catch (err) {
        failed += 1;
        failures.push({ file: full, message: err.message });
      }
    }
  }
}

walk(distDir);

console.log(`[check-bundles] Parsed ${checked} bundle files under ${distDir}`);

if (failed > 0) {
  console.error(`[check-bundles] FAILED: ${failed} bundle(s) contain invalid syntax:`);
  for (const f of failures) {
    console.error(`  - ${f.file}`);
    console.error(`    ${f.message.split('\n')[0]}`);
  }
  console.error('');
  console.error('  A bundle that cannot be parsed crashes the entire app on load');
  console.error('  (blank page, like the v0.1.0 "Range out of order" incident).');
  console.error('  Fix the offending regex/syntax in the frontend source and rebuild.');
  // exitCode (not exit()) so the failure list above is never truncated.
  process.exitCode = 1;
  return;
}

console.log('[check-bundles] OK — all bundles parse cleanly.');
process.exitCode = 0;
