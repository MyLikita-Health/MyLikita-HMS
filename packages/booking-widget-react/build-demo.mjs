/**
 * Produces dist/react-demo.html — a fully self-contained React demo with
 * react, react-dom and the widget BUNDLED INLINE (no CDN, no network), so the
 * Preview tab and agencies can open ONE file and everything works.
 *
 * Run after `npm run build` — reads the built esm bundle for the widget code
 * path, but actually bundles demo/main.jsx fresh with the widget aliased to
 * its source, matching what the library ships.
 */
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';

const require = createRequire(import.meta.url);
const here = path.dirname(fileURLToPath(import.meta.url));
const frontendNM = path.resolve(here, '../../frontend/node_modules');

let esbuild;
try {
  esbuild = require('esbuild');
} catch (_) {
  esbuild = require(path.join(frontendNM, 'esbuild'));
}

const out = path.join(here, 'dist', 'react-demo.bundle.js');
await esbuild.build({
  entryPoints: [path.join(here, 'demo/main.jsx')],
  bundle: true,
  format: 'iife',
  minify: true,
  target: ['es2018'],
  outfile: out,
  logLevel: 'info',
  alias: {
    'react': path.join(frontendNM, 'react/index.js'),
    'react-dom': path.join(frontendNM, 'react-dom/index.js'),
    '@mylikita/booking-widget': path.resolve(here, '../booking-widget/src/index.js'),
  },
});

const bundle = fs.readFileSync(out, 'utf8');
const demo = fs.readFileSync(path.join(here, 'demo/demo.html'), 'utf8');
if (!demo.includes('<!--INLINE_BUNDLE-->')) {
  throw new Error('build-demo: could not find the <!--INLINE_BUNDLE--> marker in demo/demo.html');
}
const inlined = demo.replace('<!--INLINE_BUNDLE-->', `<script>\n${bundle}\n</script>`);
const outHtml = path.join(here, 'dist', 'react-demo.html');
fs.writeFileSync(outHtml, inlined);
fs.rmSync(out, { force: true });
console.log(`Wrote ${outHtml} (${(inlined.length / 1024).toFixed(1)} KB, fully self-contained)`);
