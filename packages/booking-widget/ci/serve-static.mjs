/**
 * Minimal zero-dependency static file server used by the CI install-test job
 * to serve the widget CI harness (`demo/ci.html`) + the built bundle
 * (`dist/mylikita-booking-widget.js`) over HTTP, so the headless-Chrome step
 * can drive the widget against the REAL relay without file:// quirks.
 *
 *   node ci/serve-static.mjs            # serves packages/booking-widget on :47000
 *   WIDGET_SERVE_PORT=47001 node ci/serve-static.mjs
 *
 * Serves the package root only; path traversal is rejected.
 */
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const PORT = Number(process.env.WIDGET_SERVE_PORT || 47000);

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.map': 'application/json',
  '.svg': 'image/svg+xml',
};

http
  .createServer((req, res) => {
    const urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
    let file = path.normalize(path.join(ROOT, urlPath));
    // Guard: exact root OR inside it (prefix match alone would let a sibling
    // named e.g. 'booking-widget-evil' through).
    if (file !== ROOT && !file.startsWith(ROOT + path.sep)) {
      res.writeHead(403, { 'Content-Type': 'text/plain' });
      res.end('403');
      return;
    }
    try {
      if (fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
    } catch (_) { /* fall through to the read */ }
    fs.readFile(file, (err, data) => {
      if (err) {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end(`404 ${urlPath}`);
        return;
      }
      res.writeHead(200, { 'Content-Type': MIME[path.extname(file).toLowerCase()] || 'application/octet-stream' });
      res.end(data);
    });
  })
  .listen(PORT, '127.0.0.1', () => {
    console.log(`[widget-serve] http://127.0.0.1:${PORT} root=${ROOT}`);
  });
