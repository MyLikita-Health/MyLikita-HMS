/**
 * Produces dist/demo.html — a fully self-contained copy of the demo with the
 * widget bundle inlined, so agencies (and the Preview tab) can open ONE file
 * and have everything work, no server or ../dist path required.
 *
 * Run after `npm run build` (it reads dist/mylikita-booking-widget.min.js).
 */
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';

const here = path.dirname(fileURLToPath(import.meta.url));
const bundle = fs.readFileSync(path.join(here, 'dist/mylikita-booking-widget.min.js'), 'utf8');
const demo = fs.readFileSync(path.join(here, 'demo/demo.html'), 'utf8');

const marker = /<script src="\.\.\/dist\/mylikita-booking-widget\.js"><\/script>/;
if (!marker.test(demo)) {
  throw new Error('build-demo: could not find the widget <script src> tag in demo/demo.html');
}

const inlined = demo.replace(marker, `<script>\n${bundle}\n</script>`);
const out = path.join(here, 'dist/demo.html');
fs.writeFileSync(out, inlined);
console.log(`Wrote ${out} (${(inlined.length / 1024).toFixed(1)} KB, fully self-contained)`);
