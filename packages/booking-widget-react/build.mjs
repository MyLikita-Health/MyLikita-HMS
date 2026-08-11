/**
 * Build script for @mylikita/booking-widget-react.
 *
 * Emits two bundles into dist/:
 *   mylikita-booking-widget-react.esm.js — ES module (`import`)
 *   mylikita-booking-widget-react.cjs    — CommonJS (`require`)
 *
 * react/react-dom are peer dependencies and stay external (consumers bring
 * their own copy). @mylikita/booking-widget is a regular dependency and stays
 * external too, so a site using both packages gets a single widget copy.
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
  esbuild = require(path.resolve(here, '../../frontend/node_modules/esbuild'));
}

const pkg = JSON.parse(fs.readFileSync(path.join(here, 'package.json'), 'utf8'));
const banner = { js: `/*! @mylikita/booking-widget-react v${pkg.version} | MIT */` };

const common = {
  entryPoints: [path.join(here, 'src/index.jsx')],
  bundle: true,
  banner,
  logLevel: 'info',
  // Transpile ?. / ?? so the published dist works on older browsers — bundlers
  // do not transpile node_modules, so what ships must be ES2018-clean.
  target: ['es2018'],
  external: ['react', 'react-dom', '@mylikita/booking-widget'],
};

const out = path.join(here, 'dist');
const builds = [
  { ...common, format: 'esm', outfile: path.join(out, 'mylikita-booking-widget-react.esm.js') },
  { ...common, format: 'cjs', outfile: path.join(out, 'mylikita-booking-widget-react.cjs') },
];

for (const b of builds) await esbuild.build(b);
console.log('Built dist/ (esm, cjs)');
