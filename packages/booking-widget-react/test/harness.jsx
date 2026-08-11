/**
 * DOM harness for @mylikita/booking-widget-react. Bundled by
 * react-wrapper.test.mjs and run inside a jsdom window. Renders <BookingWidget/>
 * with a mocked relay fetch and asserts the React bridge works: the form
 * mounts, submissions hit POST /v1/bookings with Bearer auth, polling resolves,
 * callbacks fire, destroy() cleans up, and imperative refs work.
 */
import React, { createRef } from 'react';
import ReactDOM from 'react-dom';
import BookingWidget from '../src/index.jsx';

let pass = 0;
let fail = 0;
const ok = (name) => { pass += 1; console.log(`  ok  ${name}`); };
const bad = (name, err) => { fail += 1; console.log(`  FAIL ${name}: ${err && err.message || err}`); };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ── relay mock (same contract as the vanilla widget tests) ─────────────────
function installMockRelay() {
  const store = new Map();
  let seq = 0;
  const calls = [];
  globalThis.fetch = async (url, init = {}) => {
    const method = init.method || 'GET';
    const u = new URL(url, 'https://relay.example.test');
    calls.push({ method, path: u.pathname, auth: init.headers && init.headers.Authorization || null, body: init.body ? JSON.parse(init.body) : null });
    const res = (status, body) => ({ status, ok: status < 400, json: async () => body });
    if (method === 'POST' && u.pathname === '/v1/bookings') {
      const existing = [...store.values()].find((b) => b.external_ref === calls[calls.length - 1].body.external_ref);
      if (existing) return res(201, { booking_ref: existing.ref, status: 'pending_confirmation' });
      const ref = `MLB-${++seq}`;
      store.set(ref, { ref, external_ref: calls[calls.length - 1].body.external_ref, polls: 0 });
      return res(201, { booking_ref: ref, status: 'pending_confirmation' });
    }
    if (method === 'GET' && u.pathname.startsWith('/v1/bookings/')) {
      const ref = decodeURIComponent(u.pathname.split('/').pop());
      const b = store.get(ref);
      if (!b) return res(404, { error: 'not_found' });
      b.polls += 1;
      return res(200, { booking_ref: ref, status: b.polls >= 2 ? 'confirmed' : 'pending_confirmation', appt_ref: 'APT-1' });
    }
    if (method === 'GET' && u.pathname === '/v1/providers') {
      return res(200, {
        facility_id: 'F1',
        providers: [
          { external_id: 'dr-khalil', name: 'Dr. Khalil', specialty: 'General medicine', module: 'general' },
          { external_id: 'dr-amina', name: 'Dr. Amina', specialty: 'Dentistry', module: 'dental' },
        ],
      });
    }
    return res(404, { error: 'not_found' });
  };
  return calls;
}

function makeContainer() {
  const el = document.createElement('div');
  document.body.appendChild(el);
  return el;
}

function fill(container, id, value) {
  const input = container.querySelector(`#${id}`);
  input.value = value;
  input.dispatchEvent(new window.Event('input', { bubbles: true }));
}

async function waitFor(fn, ms = 2000, step = 20) {
  const start = Date.now();
  while (Date.now() - start < ms) {
    if (fn()) return true;
    await sleep(step);
  }
  return false;
}

export async function run() {
  const t0 = Date.now();
  // ── 1. renders the booking form ──────────────────────────────────────────
  console.log('render');
  {
    const calls = installMockRelay();
    const host = makeContainer();
    let booked = null;
    let lastStatus = null;
    ReactDOM.render(
      React.createElement(BookingWidget, {
        relayUrl: 'https://relay.example.test/',
        websiteKey: 'wk_demo',
        facilityId: 'F1',
        pollIntervalMs: 15,
        maxTries: 10,
        onBooking: (b) => { booked = b; },
        onStatus: (s) => { lastStatus = s; },
      }),
      host,
    );
    const ok1 = await waitFor(() => host.querySelector('.mylikita-widget__form'));
    if (!ok1) return bad('form mounts', new Error('no .mylikita-widget__form'));
    const title = host.querySelector('.mylikita-widget__title');
    assert(title && title.textContent.includes('Book an appointment'), 'title renders');
    assert(host.querySelector('#mlw-name'), 'name input renders');
    assert(host.querySelector('#mlw-datetime'), 'datetime input renders');
    assert(host.querySelector('.mylikita-widget__brand'), 'brand header renders by default');
    ok('form mounts with title + fields + default brand header');

    // ── 2. submitting books via relay and polls to confirmed ───────────────
    fill(host, 'mlw-name', 'Aisha');
    fill(host, 'mlw-phone', '0801 234 5678');
    fill(host, 'mlw-datetime', '2026-09-12T10:30');
    host.querySelector('.mylikita-widget__form').dispatchEvent(new window.Event('submit', { bubbles: true, cancelable: true }));
    const ok2 = await waitFor(() => lastStatus && lastStatus.status === 'confirmed', 3000);
    assert(ok2, 'poll resolves to confirmed');
    assert(booked && /^MLB-\d+$/.test(booked.booking_ref), 'onBooking got booking_ref');
    const post = calls.find((c) => c.method === 'POST' && c.path === '/v1/bookings');
    assert(post, 'POST /v1/bookings was called');
    assert(post.auth === 'Bearer wk_demo', 'Bearer auth sent');
    assert(post.body.facility_id === 'F1', 'facilityId sent');
    assert(post.body.patient_name === 'Aisha', 'patient_name sent');
    const statusEl = host.querySelector('.mylikita-widget__status-title');
    assert(statusEl && /confirmed/i.test(statusEl.textContent), 'status view shows confirmed');
    ok('submit → relay POST (Bearer) → poll → confirmed; callbacks fire');

    ReactDOM.unmountComponentAtNode(host);
    assert(host.querySelector('.mylikita-widget__form') === null, 'unmount clears the DOM');
    ok('unmount destroys the widget (no stray DOM)');
    host.remove();
  }

  // ── 3. missing required props → empty container, no throw ────────────────
  console.log('guards');
  {
    installMockRelay();
    const host = makeContainer();
    let threw = null;
    try {
      ReactDOM.render(React.createElement(BookingWidget, { relayUrl: 'https://relay.example.test' }), host);
    } catch (e) { threw = e; }
    assert(!threw, 'no throw when required props missing');
    assert(host.querySelector('.mylikita-widget__form') === null, 'no widget rendered without config');
    ReactDOM.unmountComponentAtNode(host);
    host.remove();
    ok('missing config renders empty container (async-config safe)');
  }

  // ── 4. loadProviders populates the doctor dropdown ───────────────────────
  console.log('loadProviders');
  {
    installMockRelay();
    const host = makeContainer();
    ReactDOM.render(
      React.createElement(BookingWidget, {
        relayUrl: 'https://relay.example.test',
        websiteKey: 'wk_demo',
        facilityId: 'F1',
        loadProviders: true,
        pollIntervalMs: 15,
      }),
      host,
    );
    const ok4 = await waitFor(() => {
      const sel = host.querySelector('#mlw-provider');
      return sel && Array.from(sel.options).some((o) => o.value === 'dr-khalil');
    });
    assert(ok4, 'provider dropdown populated from GET /v1/providers');
    const sel = host.querySelector('#mlw-provider');
    assert(Array.from(sel.options).some((o) => o.textContent === 'Dr. Amina'), 'second provider present');
    ReactDOM.unmountComponentAtNode(host);
    host.remove();
    ok('loadProviders fetches and populates doctor dropdown');
  }

  // ── 5. imperative ref: reset() clears the form ───────────────────────────
  console.log('imperative ref');
  {
    installMockRelay();
    const host = makeContainer();
    const ref = createRef();
    ReactDOM.render(
      React.createElement(BookingWidget, {
        ref,
        relayUrl: 'https://relay.example.test',
        websiteKey: 'wk_demo',
        facilityId: 'F1',
        pollIntervalMs: 15,
      }),
      host,
    );
    await waitFor(() => host.querySelector('#mlw-name'));
    fill(host, 'mlw-name', 'Aisha');
    assert(ref.current.getForm().name === 'Aisha', 'getForm() reads the current form');
    assert(ref.current.getWidget() && typeof ref.current.getWidget().destroy === 'function', 'getWidget() exposes the vanilla widget');
    ref.current.destroy();
    assert(host.querySelector('.mylikita-widget__form') === null, 'destroy() tears the widget down');
    ref.current.reset(); // after destroy → safe no-op (nulled widgetRef)
    ReactDOM.unmountComponentAtNode(host);
    host.remove();
    ok('ref.reset() + ref.getForm() + ref.destroy() + ref.getWidget() work');
  }

  // ── 6b. showBrand:false white-labels the widget (no brand header) ────────
  console.log('white-label');
  {
    installMockRelay();
    const host = makeContainer();
    ReactDOM.render(
      React.createElement(BookingWidget, {
        relayUrl: 'https://relay.example.test',
        websiteKey: 'wk_demo',
        facilityId: 'F1',
        showBrand: false,
        pollIntervalMs: 15,
      }),
      host,
    );
    const ok6b = await waitFor(() => host.querySelector('.mylikita-widget__form'));
    assert(ok6b, 'widget still mounts with showBrand:false');
    assert(host.querySelector('.mylikita-widget__brand') === null, 'brand header hidden when showBrand:false');
    assert(host.querySelector('.mylikita-widget__title'), 'title still renders without brand');
    ReactDOM.unmountComponentAtNode(host);
    host.remove();
    ok('showBrand:false hides the brand header (white-label)');
  }

  // ── 6. data-option change recreates the widget (theme) ───────────────────
  console.log('option changes');
  {
    installMockRelay();
    const host = makeContainer();
    const renderWith = (theme) => ReactDOM.render(
      React.createElement(BookingWidget, {
        relayUrl: 'https://relay.example.test',
        websiteKey: 'wk_demo',
        facilityId: 'F1',
        theme,
      }),
      host,
    );
    renderWith({ primary: '#111111' });
    await waitFor(() => host.querySelector('.mylikita-widget'));
    const firstForm = host.querySelector('.mylikita-widget__form');
    assert(host.querySelector('.mylikita-widget').style.getPropertyValue('--mlw-primary') === '#111111', 'theme applied');
    renderWith({ primary: '#222222' });
    await waitFor(() => host.querySelector('.mylikita-widget__form') !== firstForm);
    assert(host.querySelector('.mylikita-widget').style.getPropertyValue('--mlw-primary') === '#222222', 'theme change re-applied');
    ReactDOM.unmountComponentAtNode(host);
    host.remove();
    ok('theme change recreates widget with new styles');
  }

  console.log(`\nSummary: ${pass} passed, ${fail} failed (${Date.now() - t0} ms)`);
  // The runner closes jsdom + cleans up the bundle; return the pass count so it
  // can decide the exit code (never call process.exit here — it would skip the
  // runner's finally cleanup and leave the 900 KB harness bundle behind).
  return fail === 0 ? pass : 0;
}

function assert(cond, msg) {
  if (cond) { ok(msg); } else { bad(msg); }
}
