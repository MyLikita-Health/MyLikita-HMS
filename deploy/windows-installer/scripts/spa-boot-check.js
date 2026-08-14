#!/usr/bin/env node
'use strict';

/**
 * spa-boot-check.js — dependency-free headless-browser boot check for MyLikita.
 *
 * Why this exists: the v0.1.0 release served HTTP 200 with the right
 * <title> but the frontend bundle threw a V8 parse-time SyntaxError in the
 * browser, so the app rendered a blank white page with zero React. No HTTP or
 * title check can see that class of failure — only actually booting the app in
 * a browser can. (check-bundles.js covers it statically; this is the runtime
 * proof.)
 *
 * Why CDP and not `chrome --headless --dump-dom`: the app keeps the renderer
 * busy after load (live UI timers), so the dump-dom virtual-time budget never
 * expires and the process hangs forever. This script instead launches Chrome
 * with a remote-debugging port and drives it over the DevTools Protocol in
 * REAL time — deterministic, always terminates, and captures runtime
 * exceptions for diagnostics.
 *
 * Zero dependencies on purpose: it runs from the INSTALLED server's embedded
 * Node (bundled with the installer, v20) on machines with no internet, so only
 * Node built-ins (child_process, http, crypto, net) are used — the WebSocket
 * client is hand-rolled (RFC 6455).
 *
 * Usage:
 *   node spa-boot-check.js [--url=http://localhost:46990/auth]
 *                          [--browser=<path to chrome/edge>]
 *                          [--settleMs=6000] [--timeoutMs=60000]
 *   exit 0 = SPA rendered the login form, 1 = failure (see [FAIL] lines).
 */

const { spawn } = require('child_process');
const http = require('http');
const crypto = require('crypto');
const os = require('os');
const path = require('path');
const fs = require('fs');

// ---------------------------------------------------------------------------
// args
// ---------------------------------------------------------------------------
function parseArgs(argv) {
  const a = {};
  for (let i = 2; i < argv.length; i++) {
    const m = argv[i].match(/^--([^=]+)=(.*)$/);
    if (m) a[m[1]] = m[2];
  }
  return a;
}
const args = parseArgs(process.argv);
const URL_TARGET = args.url || 'http://localhost:46990/auth';
const BROWSER_ARG = args.browser || '';
const SETTLE_MS = parseInt(args.settleMs || '6000', 10);
const TIMEOUT_MS = parseInt(args.timeoutMs || '90000', 10);

let failures = 0;
function ok(msg) { console.log('[OK] ' + msg); }
function fail(msg) { failures += 1; console.log('[FAIL] ' + msg); }

// ---------------------------------------------------------------------------
// locate a Chromium browser (Chrome, then Edge — Edge ships with Win10/11)
// ---------------------------------------------------------------------------
function findBrowser() {
  if (BROWSER_ARG && fs.existsSync(BROWSER_ARG)) return BROWSER_ARG;
  const candidates = [
    process.env.ProgramFiles + '\\Google\\Chrome\\Application\\chrome.exe',
    (process.env['ProgramFiles(x86)'] || '') + '\\Google\\Chrome\\Application\\chrome.exe',
    process.env.ProgramFiles + '\\Microsoft\\Edge\\Application\\msedge.exe',
    (process.env['ProgramFiles(x86)'] || '') + '\\Microsoft\\Edge\\Application\\msedge.exe',
    (process.env.LOCALAPPDATA || '') + '\\Google\\Chrome\\Application\\chrome.exe',
    (process.env.LOCALAPPDATA || '') + '\\Microsoft\\Edge\\Application\\msedge.exe',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
  ].filter(Boolean);
  for (const c of candidates) if (fs.existsSync(c)) return c;
  return null;
}

// ---------------------------------------------------------------------------
// minimal WebSocket client (RFC 6455) over Node's http upgrade — no deps
// ---------------------------------------------------------------------------
const WS_GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

function wsConnect(wsUrl) {
  return new Promise((resolve, reject) => {
    const u = new URL(wsUrl);
    const key = crypto.randomBytes(16).toString('base64');
    const req = http.request({
      hostname: u.hostname,
      port: u.port,
      path: u.pathname + u.search,
      headers: {
        Connection: 'Upgrade',
        Upgrade: 'websocket',
        'Sec-WebSocket-Key': key,
        'Sec-WebSocket-Version': '13',
      },
    });
    req.on('upgrade', (res, socket) => {
      const expect = crypto.createHash('sha1').update(key + WS_GUID).digest('base64');
      if (res.headers['sec-websocket-accept'] !== expect) {
        socket.destroy();
        return reject(new Error('WebSocket handshake failed (bad Sec-WebSocket-Accept)'));
      }
      resolve(new WsClient(socket));
    });
    req.on('error', reject);
    req.end();
  });
}

class WsClient {
  constructor(socket) {
    this.socket = socket;
    this.buffer = Buffer.alloc(0);
    this.onmessage = null;
    this.onclose = null;
    socket.on('data', (d) => this._onData(d));
    socket.on('close', () => this.onclose && this.onclose());
    socket.on('error', () => {});
  }

  _onData(d) {
    this.buffer = Buffer.concat([this.buffer, d]);
    for (;;) {
      const frame = this._tryReadFrame();
      if (!frame) break;
      if (frame.opcode === 0x8) { // close
        this.socket.end();
        return;
      }
      if (frame.opcode === 0x9) { // ping -> pong
        this._writeRaw(Buffer.concat([Buffer.from([0x8a]), this._mask(frame.payload)]));
        continue;
      }
      if (frame.opcode === 0x1 || frame.opcode === 0x2) {
        this.onmessage && this.onmessage(frame.payload.toString('utf8'));
      }
    }
  }

  // server -> client frames are UNMASKED; returns null until a whole frame
  // is buffered
  _tryReadFrame() {
    if (this.buffer.length < 2) return null;
    const b0 = this.buffer[0];
    const b1 = this.buffer[1];
    const opcode = b0 & 0x0f;
    let len = b1 & 0x7f;
    let off = 2;
    if (len === 126) {
      if (this.buffer.length < 4) return null;
      len = this.buffer.readUInt16BE(2);
      off = 4;
    } else if (len === 127) {
      if (this.buffer.length < 10) return null;
      len = Number(this.buffer.readBigUInt64BE(2));
      off = 10;
    }
    if (this.buffer.length < off + len) return null;
    const payload = this.buffer.slice(off, off + len);
    this.buffer = this.buffer.slice(off + len);
    return { opcode, payload };
  }

  _mask(payload) {
    const key = crypto.randomBytes(4);
    const masked = Buffer.alloc(payload.length);
    for (let i = 0; i < payload.length; i++) masked[i] = payload[i] ^ key[i % 4];
    return Buffer.concat([key, masked]);
  }

  _writeRaw(buf) {
    this.socket.write(buf);
  }

  // client -> server frames must be MASKED
  send(text) {
    const payload = Buffer.from(text, 'utf8');
    let header;
    if (payload.length < 126) {
      header = Buffer.from([0x81, 0x80 | payload.length]);
    } else if (payload.length < 65536) {
      header = Buffer.alloc(4);
      header[0] = 0x81; header[1] = 0x80 | 126;
      header.writeUInt16BE(payload.length, 2);
    } else {
      header = Buffer.alloc(10);
      header[0] = 0x81; header[1] = 0x80 | 127;
      header.writeBigUInt64BE(BigInt(payload.length), 2);
    }
    this.socket.write(Buffer.concat([header, this._mask(payload)]));
  }

  close() {
    try { this.socket.end(); } catch (e) {}
  }
}

// ---------------------------------------------------------------------------
// launch chrome with a remote-debugging port and discover it
// ---------------------------------------------------------------------------
function launchChrome(browserPath) {
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'mylikita-boot-'));
  const child = spawn(browserPath, [
    '--headless=new',
    '--remote-debugging-port=0',
    '--user-data-dir=' + profile,
    '--no-sandbox',
    '--disable-gpu',
    '--disable-dev-shm-usage',
    '--disable-background-networking',
    '--no-first-run',
    '--no-default-browser-check',
    '--window-size=1280,900',
    'about:blank',
  ], { stdio: 'ignore' });

  const portFile = path.join(profile, 'DevToolsActivePort');
  return new Promise((resolve, reject) => {
    const deadline = Date.now() + 20000;
    const poll = setInterval(() => {
      if (child.exitCode !== null) {
        clearInterval(poll);
        return reject(new Error('Chrome exited early (code ' + child.exitCode + ')'));
      }
      if (fs.existsSync(portFile)) {
        try {
          const lines = fs.readFileSync(portFile, 'utf8').split(/\r?\n/);
          const port = parseInt(lines[0], 10);
          if (port > 0) {
            clearInterval(poll);
            return resolve({ child, port, profile });
          }
        } catch (e) {}
      }
      if (Date.now() > deadline) {
        clearInterval(poll);
        child.kill('SIGKILL');
        reject(new Error('Chrome did not open a debugging port within 20s'));
      }
    }, 250);
  });
}

function getPageWsUrl(port) {
  return new Promise((resolve, reject) => {
    const deadline = Date.now() + 20000;
    const poll = () => {
      http.get({ hostname: '127.0.0.1', port, path: '/json/list', timeout: 3000 }, (res) => {
        let body = '';
        res.on('data', (d) => (body += d));
        res.on('end', () => {
          try {
            const targets = JSON.parse(body);
            const page = targets.find((t) => t.type === 'page' && t.webSocketDebuggerUrl);
            if (page) return resolve(page.webSocketDebuggerUrl);
          } catch (e) {}
          if (Date.now() > deadline) return reject(new Error('No page target from CDP within 20s'));
          setTimeout(poll, 250);
        });
      }).on('error', () => {
        if (Date.now() > deadline) return reject(new Error('CDP HTTP endpoint unreachable'));
        setTimeout(poll, 250);
      });
    };
    poll();
  });
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------
// Hard global watchdog: whatever happens (wedged CDP call, hung renderer),
// this process ALWAYS terminates. An installer boot check that hangs forever
// is worse than one that fails loudly.
setTimeout(() => {
  console.error('[FAIL] SPA boot check timed out (global watchdog).');
  process.exit(1);
}, TIMEOUT_MS + 30000).unref();

(async () => {
  const browserPath = findBrowser();
  if (!browserPath) {
    fail('No Chrome/Edge found - cannot verify the SPA actually renders.');
    fail('Install Google Chrome or Microsoft Edge, or pass --browser=<path>.');
    process.exit(1);
  }
  ok('Using browser: ' + browserPath);

  let chrome = null;
  let ws = null;
  try {
    const launched = await launchChrome(browserPath);
    chrome = launched.child;
    ok('Chrome launched (debug port ' + launched.port + ').');

    const wsUrl = await getPageWsUrl(launched.port);
    ws = await wsConnect(wsUrl);
    ok('CDP attached.');

    // --- CDP plumbing -----------------------------------------------------
    let seq = 0;
    const pending = new Map();
    const events = [];
    ws.onmessage = (text) => {
      let msg;
      try { msg = JSON.parse(text); } catch (e) { return; }
      if (msg.id && pending.has(msg.id)) {
        const p = pending.get(msg.id);
        pending.delete(msg.id);
        if (msg.error) p.reject(new Error(msg.error.message));
        else p.resolve(msg.result);
        return;
      }
      events.push(msg);
    };

    const send = (method, params) =>
      new Promise((resolve, reject) => {
        const id = ++seq;
        pending.set(id, { resolve, reject });
        ws.send(JSON.stringify({ id, method, params: params || {} }));
        setTimeout(() => {
          if (pending.has(id)) { pending.delete(id); reject(new Error('CDP timeout: ' + method)); }
        }, 15000);
      });

    const evaluate = async (expression) => {
      const r = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
      if (r.exceptionDetails) {
        throw new Error('evaluate threw: ' + (r.exceptionDetails.exception && r.exceptionDetails.exception.description || r.exceptionDetails.text));
      }
      return r.result.value;
    };

    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

    // --- boot the app ------------------------------------------------------
    await send('Page.enable');
    await send('Runtime.enable');
    ok('Navigating to ' + URL_TARGET);
    await send('Page.navigate', { url: URL_TARGET });

    // wait for load + the login form, in real time (bounded)
    const deadline = Date.now() + TIMEOUT_MS;
    let state = null;
    while (Date.now() < deadline) {
      await sleep(750);
      try {
        state = await evaluate(
          '(() => { const root = document.getElementById("root"); return { ready: document.readyState, title: document.title, rootEmpty: !!root && root.children.length === 0, hasUser: !!document.getElementById("login-username"), hasPass: !!document.getElementById("login-password") }; })()'
        );
      } catch (e) {
        continue; // page mid-load
      }
      if (state.ready === 'complete' && state.hasUser && state.hasPass && !state.rootEmpty) break;
    }

    // extra settle time for React paint
    await sleep(SETTLE_MS);
    const final = await evaluate(
      '(() => { const root = document.getElementById("root"); return { title: document.title, rootEmpty: !!root && root.children.length === 0, hasUser: !!document.getElementById("login-username"), hasPass: !!document.getElementById("login-password") }; })()'
    );

    // --- assertions ---------------------------------------------------------
    if (final.title !== 'MyLikita') fail('SPA shell not served: title is "' + final.title + '" (expected "MyLikita")');
    if (final.rootEmpty) fail('Root element is EMPTY - the app crashed at boot (blank white page, the v0.1.0 class). HTTP 200 + title cannot catch this.');
    if (!final.hasUser) fail('React did not mount the login form: id="login-username" missing from the rendered DOM');
    if (!final.hasPass) fail('React did not mount the login form: id="login-password" missing from the rendered DOM');
    if (final.rootEmpty || !final.hasUser || !final.hasPass) {
      fail('DOM state: title=' + JSON.stringify(final.title) + ' rootEmpty=' + final.rootEmpty + ' loginUsername=' + final.hasUser + ' loginPassword=' + final.hasPass);
      const excs = events.filter((e) => e.method === 'Runtime.exceptionThrown')
        .map((e) => {
          const d = e.params.exceptionDetails;
          return (d.exception && d.exception.description || d.text || 'unknown').split('\n')[0];
        });
      if (excs.length) {
        fail('Browser exceptions during boot:');
        [...new Set(excs)].slice(0, 8).forEach((x) => fail('  ' + x));
      }
      const bodySnippet = await evaluate('(document.body ? document.body.innerHTML.slice(0, 400) : "(no body)")');
      console.log('       body head: ' + bodySnippet.replace(/[\r\n]+/g, ' '));
    } else {
      ok('React mounted - login form rendered (login-username / login-password present).');
      ok('SPA BOOT CHECK PASSED');
    }
  } catch (err) {
    fail('SPA boot check errored: ' + err.message);
  } finally {
    if (ws) ws.close();
    if (chrome) { try { chrome.kill('SIGKILL'); } catch (e) {} }
  }
  process.exit(failures ? 1 : 0);
})();
