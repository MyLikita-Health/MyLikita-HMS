/**
 * Test runner for @mylikita/booking-widget-react.
 *
 * No installs required: jsdom + esbuild + react + react-dom are resolved from
 * the monorepo's frontend/node_modules (the frontend app already installs them).
 *
 *  1. Boot a jsdom window and copy the globals React needs.
 *  2. Bundle test/harness.jsx with esbuild — react/react-dom and the widget are
 *     BUNDLED IN (not external), aliased to the local sources, so the harness
 *     runs in plain node against the real jsdom DOM. The bundle is written to
 *     a temp dir (NOT dist/, so a stale harness can never be published).
 *  3. Import the bundle; it renders <BookingWidget/> and asserts behaviour,
 *     printing ok/fail lines like the vanilla widget test.
 */
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';
import os from 'node:os';

const require = createRequire(import.meta.url);
const here = path.dirname(fileURLToPath(import.meta.url));
const pkgRoot = path.resolve(here, '..');

// Resolve test deps (jsdom / esbuild / react / react-dom) from the package's
// OWN node_modules first — that is what `npm ci` in CI creates, so the
// prepublishOnly build+test runs standalone on a fresh runner. Locally the
// package may not be installed yet, so fall back to the monorepo's
// frontend/node_modules (the frontend app already installs them).
function resolveNM(name) {
  const own = path.join(pkgRoot, 'node_modules', name);
  if (fs.existsSync(path.join(own, 'package.json'))) return own;
  const frontendNM = path.resolve(pkgRoot, '../../frontend/node_modules');
  const fe = path.join(frontendNM, name);
  if (fs.existsSync(path.join(fe, 'package.json'))) return fe;
  throw new Error(`cannot resolve ${name}: install the package deps (npm ci) or use the monorepo frontend install`);
}

// ── 1. jsdom ────────────────────────────────────────────────────────────────
// resolveNM returns the package DIR — require() resolves the package main
// from it (appending index.js would miss packages whose main lives elsewhere).
const { JSDOM } = require(resolveNM('jsdom'));
const dom = new JSDOM('<!doctype html><html><body></body></html>', {
  url: 'http://localhost/',
  pretendToBeVisual: true,
});
const { window } = dom;

// Copy the globals React / react-dom / the widget touch.
for (const key of [
  'window', 'document', 'navigator', 'HTMLElement', 'HTMLInputElement',
  'HTMLSelectElement', 'HTMLTextAreaElement', 'HTMLFormElement', 'HTMLButtonElement',
  'Element', 'Node', 'Text', 'Comment', 'DocumentFragment', 'DocumentType',
  'CustomEvent', 'Event', 'MouseEvent', 'KeyboardEvent', 'FocusEvent', 'InputEvent',
  'getComputedStyle', 'requestAnimationFrame', 'cancelAnimationFrame',
  'sessionStorage', 'localStorage', 'location', 'history', 'MutationObserver',
  'getSelection', 'documentURI', 'CSSStyleDeclaration', 'DOMRect',
]) {
  if (window[key] === undefined) continue;
  try {
    globalThis[key] = window[key];
  } catch (_) {
    // getter-only globals (e.g. navigator on Node ≥21) — redefine instead
    Object.defineProperty(globalThis, key, {
      value: window[key], writable: true, configurable: true,
    });
  }
}
globalThis.IS_REACT_ACT_ENVIRONMENT = false;

// ── 2. bundle the harness into a temp dir (never dist/) ─────────────────────
let esbuild;
try {
  esbuild = require('esbuild');
} catch (_) {
  esbuild = require(resolveNM('esbuild'));
}

const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'mlw-react-test-'));
const outFile = path.join(tmpDir, 'harness.mjs');
await esbuild.build({
  entryPoints: [path.join(here, 'harness.jsx')],
  bundle: true,
  format: 'esm',
  platform: 'browser',
  outfile: outFile,
  logLevel: 'silent',
  alias: {
    'react': path.join(resolveNM('react'), 'index.js'),
    'react-dom': path.join(resolveNM('react-dom'), 'index.js'),
    '@mylikita/booking-widget': path.resolve(pkgRoot, '../booking-widget/src/index.js'),
  },
  // esbuild resolves 'react' inside react-dom's CJS from the aliased entry,
  // which works because the alias points at the real package index.
});

// ── 3. run the harness ──────────────────────────────────────────────────────
let pass = 0;
try {
  const { run } = await import(pathToFileURL(outFile));
  pass = await run();
} finally {
  fs.rmSync(tmpDir, { recursive: true, force: true });
  dom.window.close(); // stop jsdom's rAF loop so the process can exit
}

process.exit(pass > 0 ? 0 : 1);

function pathToFileURL(p) {
  return { url: `file://${p.replace(/\\/g, '/')}` }.url;
}
