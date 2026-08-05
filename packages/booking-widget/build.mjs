/**
 * Build script for @mylikita/booking-widget.
 *
 * Emits four bundles into dist/:
 *   mylikita-booking-widget.js       — IIFE, global `MyLikitaBookingWidget` (script tag)
 *   mylikita-booking-widget.min.js   — minified IIFE (CDN)
 *   mylikita-booking-widget.esm.js   — ES module (bundlers / `import`)
 *   mylikita-booking-widget.cjs.js   — CommonJS (`require`)
 *
 * esbuild is resolved from the package's own devDependency, falling back to
 * the monorepo's frontend install so the build works before `npm install`.
 */
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';

const require = createRequire(import.meta.url);
const here = path.dirname(fileURLToPath(import.meta.url));

let esbuild;
try {
  esbuild = require('esbuild');
} catch (_) {
  // Monorepo fallback: frontend/ installs esbuild for Vite.
  esbuild = require(path.resolve(here, '../../frontend/node_modules/esbuild'));
}

const pkg = JSON.parse(fs.readFileSync(path.join(here, 'package.json'), 'utf8'));
const banner = { js: `/*! @mylikita/booking-widget v${pkg.version} | MIT */` };

const common = {
  entryPoints: [path.join(here, 'src/index.js')],
  bundle: true,
  banner,
  logLevel: 'info',
};

const out = path.join(here, 'dist');
const builds = [
  { ...common, format: 'iife', globalName: 'MyLikitaBookingWidget', outfile: path.join(out, 'mylikita-booking-widget.js') },
  { ...common, format: 'iife', globalName: 'MyLikitaBookingWidget', minify: true, outfile: path.join(out, 'mylikita-booking-widget.min.js') },
  { ...common, format: 'esm', outfile: path.join(out, 'mylikita-booking-widget.esm.js') },
  { ...common, format: 'cjs', outfile: path.join(out, 'mylikita-booking-widget.cjs') },
];

for (const b of builds) await esbuild.build(b);
console.log('Built dist/ (iife, iife.min, esm, cjs)');
