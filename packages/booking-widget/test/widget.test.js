/**
 * Test suite for @mylikita/booking-widget core logic.
 * No DOM required — exercises client.js / state.js / theme.js against a
 * mocked global.fetch. Run with `npm test` (node test/widget.test.js).
 */
import assert from 'node:assert/strict';
import { createBooking, fetchStatus, pollStatus, newExternalRef, fetchProviders } from '../src/client.js';
import { statusCopy, TERMINAL_STATUSES } from '../src/state.js';
import { resolveTheme, DEFAULT_THEME } from '../src/theme.js';

const BASE = 'https://relay.example.test';
const KEY = 'wk_demo_public_key';
let pass = 0;
const ok = (name) => { pass += 1; console.log(`  ok  ${name}`); };

// ── fetch mock ─────────────────────────────────────────────────────────────
function installFetch(routes) {
  // routes: fn(method, path, body) -> { status, body } | null (null = 404)
  const calls = [];
  globalThis.fetch = async (url, init = {}) => {
    const method = init.method || 'GET';
    const u = new URL(url, BASE);
    calls.push({ method, path: u.pathname, body: init.body ? JSON.parse(init.body) : null, auth: init.headers?.Authorization || null });
    const out = routes(method, u.pathname, calls[calls.length - 1].body);
    const res = out || { status: 404, body: { error: 'not_found' } };
    return new Response(JSON.stringify(res.body), { status: res.status, headers: { 'Content-Type': 'application/json' } });
  };
  return calls;
}

function freshBookingRoutes() {
  const store = new Map();
  let seq = 0;
  return (method, path, body) => {
    if (method === 'POST' && path === '/v1/bookings') {
      if (!body.external_ref) return { status: 400, body: { error: 'validation_error', message: 'external_ref is required' } };
      const existing = [...store.values()].find((b) => b.external_ref === body.external_ref);
      if (existing) return { status: 201, body: { booking_ref: existing.ref, status: 'pending_confirmation' } };
      const ref = `MLB-${++seq}`;
      store.set(ref, { ref, external_ref: body.external_ref, polls: 0 });
      return { status: 201, body: { booking_ref: ref, status: 'pending_confirmation' } };
    }
    if (method === 'GET' && path.startsWith('/v1/bookings/')) {
      const ref = decodeURIComponent(path.split('/').pop());
      const b = store.get(ref);
      if (!b) return { status: 404, body: { error: 'not_found' } };
      b.polls += 1;
      const status = b.polls >= 3 ? 'confirmed' : 'pending_confirmation';
      return { status: 200, body: { booking_ref: ref, status, appt_ref: status === 'confirmed' ? 'APT-X' : undefined } };
    }
    return null;
  };
}

// ── tests ──────────────────────────────────────────────────────────────────
console.log('client.createBooking');

const calls1 = installFetch(freshBookingRoutes());
{
  const payload = { facility_id: 'F1', external_ref: 'BK-1-abc', patient_name: 'Aisha', patient_phone: '0801', appt_datetime: '2026-08-12T09:30' };
  const r = await createBooking({ relayUrl: BASE + '/', websiteKey: KEY, payload });
  assert.equal(r.ok, true);
  assert.equal(r.duplicate, false);
  assert.match(r.booking_ref, /^MLB-\d+$/);
  assert.equal(r.status, 'pending_confirmation');
  assert.equal(calls1[0].auth, `Bearer ${KEY}`, 'Bearer header');
  assert.equal(calls1[0].path, '/v1/bookings');
  assert.equal(calls1[0].body.external_ref, 'BK-1-abc');
  assert.equal(calls1[0].body.facility_id, 'F1');
  ok('createBooking posts payload with Bearer auth (trailing slash stripped)');
}

{
  const calls = installFetch(() => ({ status: 409, body: { error: 'duplicate_booking', message: 'Already booked', booking_ref: 'MLB-9' } }));
  const r = await createBooking({ relayUrl: BASE, websiteKey: KEY, payload: { facility_id: 'F1', external_ref: 'BK-2', patient_name: 'B', patient_phone: '0802', appt_datetime: '2026-08-12T10:00' } });
  assert.equal(r.ok, true);
  assert.equal(r.duplicate, true);
  assert.equal(r.booking_ref, 'MLB-9');
  ok('409 duplicate_booking surfaces as ok:true + duplicate:true (not an error)');
}

{
  const calls = installFetch(() => ({ status: 400, body: { error: 'validation_error', message: 'appt_datetime is required' } }));
  await assert.rejects(
    () => createBooking({ relayUrl: BASE, websiteKey: KEY, payload: {} }),
    (err) => err.code === 'validation_error' && err.status === 400 && /appt_datetime/.test(err.message),
  );
  ok('400 validation_error throws with code + status');
}

console.log('client.fetchProviders');
{
  const calls = installFetch(() => ({
    status: 200,
    body: {
      facility_id: 'F1',
      providers: [
        { external_id: 'dr-khalil', name: 'Dr. Khalil', specialty: 'General medicine', module: 'general' },
        { external_id: 'dr-amina', name: 'Dr. Amina', specialty: 'Dentistry', module: 'dental' },
      ],
    },
  }));
  const list = await fetchProviders({ relayUrl: BASE, websiteKey: KEY });
  assert.equal(list.length, 2);
  assert.equal(list[0].external_id, 'dr-khalil');
  assert.equal(list[0].name, 'Dr. Khalil');
  assert.equal(list[0].specialty, 'General medicine');
  assert.equal(calls[0].auth, `Bearer ${KEY}`, 'Bearer header');
  assert.equal(calls[0].path, '/v1/providers');
  ok('fetchProviders returns normalized mapped provider list with Bearer auth');
}

{
  const calls = installFetch(() => ({ status: 200, body: { facility_id: 'F1', providers: [] } }));
  const empty = await fetchProviders({ relayUrl: BASE, websiteKey: KEY });
  assert.equal(empty.length, 0);
  ok('fetchProviders returns [] for an empty registry (valid fallback)');
}

{
  installFetch(() => ({ status: 401, body: { error: 'unauthorized', message: 'Invalid key' } }));
  await assert.rejects(
    () => fetchProviders({ relayUrl: BASE, websiteKey: 'bad-key' }),
    (err) => err.status === 401 && err.code === 'unauthorized',
  );
  ok('fetchProviders throws with code + status on 401');
}

console.log('client.fetchStatus');
{
  installFetch(() => ({ status: 200, body: { booking_ref: 'MLB-1', status: 'confirmed', appt_ref: 'APT-1' } }));
  const s = await fetchStatus({ relayUrl: BASE, websiteKey: KEY, bookingRef: 'MLB-1' });
  assert.equal(s.status, 'confirmed');
  assert.equal(s.appt_ref, 'APT-1');
  ok('fetchStatus returns status + appt_ref');
}

console.log('client.pollStatus (abort)');
{
  const ac = new AbortController();
  let calls = 0;
  const p = pollStatus(async () => { calls += 1; return { status: 'pending_confirmation' }; }, { intervalMs: 20, maxTries: 50, signal: ac.signal });
  await new Promise((r) => setTimeout(r, 30));
  ac.abort();
  const result = await p;
  assert.equal(result.status, 'aborted');
  assert.equal(result.resolved, false);
  assert.ok(calls < 50, `poll stopped early after ${calls} calls`);
  ok('pollStatus aborts via AbortSignal and stops fetching');
}

console.log('client.pollStatus');
{
  let n = 0;
  const result = await pollStatus(async () => {
    n += 1;
    return { status: n >= 3 ? 'confirmed' : 'pending_confirmation' };
  }, { intervalMs: 2, maxTries: 5 });
  assert.equal(result.resolved, true);
  assert.equal(result.status, 'confirmed');
  ok('pollStatus resolves when status leaves pending_confirmation');
}
{
  const result = await pollStatus(async () => ({ status: 'pending_confirmation' }), { intervalMs: 1, maxTries: 3 });
  assert.equal(result.resolved, false);
  assert.equal(result.status, 'pending_confirmation');
  ok('pollStatus gives up (resolved:false) after maxTries when never leaves pending');
}

console.log('state');
{
  assert.equal(statusCopy('confirmed').kind, 'success');
  assert.equal(statusCopy('expired').kind, 'danger');
  assert.equal(statusCopy('weird').title, 'Request received'); // fallback
  assert.ok(TERMINAL_STATUSES.includes('confirmed'));
  assert.ok(!TERMINAL_STATUSES.includes('pending_confirmation'));
  ok('statusCopy maps every status incl. fallback; terminal set is correct');
}

console.log('theme');
{
  const t = resolveTheme();
  assert.equal(t['--mlw-primary'], DEFAULT_THEME.primary);
  assert.equal(t['--mlw-radius'], '10px');
  const over = resolveTheme({ primary: '#e91e63', radius: 6 });
  assert.equal(over['--mlw-primary'], '#e91e63');
  assert.equal(over['--mlw-primary-dark'], DEFAULT_THEME.primaryDark, 'unspecified keys fall through');
  assert.equal(over['--mlw-radius'], '6px');
  ok('resolveTheme merges overrides over defaults (radius → px)');
}

console.log('client.newExternalRef');
{
  assert.match(newExternalRef(), /^BK-\d+-[a-z0-9]{4}$/);
  ok('newExternalRef matches BK-<ts>-<rand4>');
}

console.log(`\nSummary: ${pass} passed, 0 failed`);
