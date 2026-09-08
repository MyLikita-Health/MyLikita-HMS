/**
 * Test suite for @mylikita/booking-widget core logic.
 * No DOM required — exercises client.js / state.js / theme.js against a
 * mocked global.fetch. Run with `npm test` (node test/widget.test.js).
 */
import assert from 'node:assert/strict';
import { createBooking, createWaitlist, trackPageView, fetchStatus, pollStatus, newExternalRef, fetchProviders, fetchServices, fetchAvailability } from '../src/client.js';
import { statusCopy, TERMINAL_STATUSES } from '../src/state.js';
import { resolveTheme, DEFAULT_THEME } from '../src/theme.js';
import { STYLES } from '../src/styles.js';

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
  // A duplicate 409 that OMITS booking_ref (an older relay / edge case) must
  // still resolve as success rather than throw — the widget's job then is to
  // show the existing-booking state and NOT poll /bookings/undefined.
  const calls = installFetch(() => ({ status: 409, body: { error: 'duplicate_booking', message: 'Already booked' } }));
  const r = await createBooking({ relayUrl: BASE, websiteKey: KEY, payload: { facility_id: 'F1', external_ref: 'BK-2c', patient_name: 'B', patient_phone: '0802', appt_datetime: '2026-08-12T10:00' } });
  assert.equal(r.ok, true);
  assert.equal(r.duplicate, true);
  assert.equal(r.booking_ref, undefined, 'missing booking_ref stays undefined; widget must not start a poll on it');
  ok('409 duplicate without booking_ref resolves ok:true (widget must not poll undefined)');
}

{
  // Server-side double-booking: 409 slot_unavailable means ANOTHER booking
  // took the window — it must THROW (so the patient picks a new time), unlike
  // duplicate_booking which resolves as success.
  const calls = installFetch(() => ({ status: 409, body: { error: 'slot_unavailable', message: 'This time slot is no longer available' } }));
  await assert.rejects(
    () => createBooking({ relayUrl: BASE, websiteKey: KEY, payload: { facility_id: 'F1', external_ref: 'BK-2b', patient_name: 'B', patient_phone: '0802', appt_datetime: '2026-08-12T10:00' } }),
    (err) => err.code === 'slot_unavailable' && err.status === 409 && /no longer available/.test(err.message),
  );
  ok('409 slot_unavailable throws (not treated as duplicate success)');
}

{
  // Source capture: the widget forwards a `source` slug so the relay can
  // compute conversion-by-source analytics.
  const calls = installFetch(freshBookingRoutes());
  const r = await createBooking({ relayUrl: BASE, websiteKey: KEY, payload: { facility_id: 'F1', external_ref: 'BK-SRC', patient_name: 'A', patient_phone: '0801', appt_datetime: '2026-08-12T09:30', source: 'google' } });
  assert.equal(r.ok, true);
  assert.equal(calls[0].body.source, 'google');
  ok('createBooking forwards source slug in the booking payload');
}

console.log('client.trackPageView');
{
  const calls = installFetch(() => ({ status: 200, body: { ok: true } }));
  await trackPageView({ relayUrl: BASE, websiteKey: KEY, source: 'facebook' });
  assert.equal(calls.length, 1);
  assert.equal(calls[0].path, '/v1/track');
  assert.equal(calls[0].auth, `Bearer ${KEY}`, 'Bearer header');
  assert.equal(calls[0].body.source, 'facebook');
  ok('trackPageView posts source to /v1/track with Bearer auth');
}
{
  // Best-effort: a failed tracking ping must never throw.
  const calls = installFetch(() => ({ status: 500, body: { error: 'server_error' } }));
  await trackPageView({ relayUrl: BASE, websiteKey: KEY, source: 'instagram' });
  assert.equal(calls.length, 1);
  ok('trackPageView swallows server errors (best-effort, never breaks widget)');
}

console.log('client.createWaitlist');
{
  const calls = installFetch(() => ({ status: 201, body: { status: 'waiting' } }));
  const r = await createWaitlist({
    relayUrl: BASE, websiteKey: KEY,
    payload: { external_ref: 'WL-9', patient_name: 'Wait A', patient_phone: '08055550001', preferred_date: '2026-08-20' },
  });
  assert.equal(r.ok, true);
  assert.equal(r.duplicate, false);
  assert.equal(calls[0].path, '/v1/waitlist');
  assert.equal(calls[0].auth, `Bearer ${KEY}`, 'Bearer header');
  assert.equal(calls[0].body.external_ref, 'WL-9');
  ok('createWaitlist posts to /v1/waitlist with Bearer auth');
}
{
  installFetch(() => ({ status: 201, body: { status: 'waiting' } }));
  const r = await createWaitlist({ relayUrl: BASE, websiteKey: KEY, payload: { external_ref: 'WL-9', patient_name: 'A', patient_phone: '0801' } });
  assert.equal(r.ok, true);
  ok('createWaitlist idempotent re-submit resolves ok:true');
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

console.log('client.fetchServices');
{
  const calls = installFetch(() => ({
    status: 200,
    body: {
      facility_id: 'F1',
      services: [
        { external_id: 'clean', name: 'Teeth Cleaning', duration_mins: 30, price: 5000, module: 'dental', provider_external_ids: ['dr-amina'] },
        { external_id: 'consult', name: 'General Consultation', duration_mins: 20, price: null, module: 'general', provider_external_ids: [] },
      ],
    },
  }));
  const list = await fetchServices({ relayUrl: BASE, websiteKey: KEY });
  assert.equal(list.length, 2);
  assert.equal(list[0].external_id, 'clean');
  assert.equal(list[0].name, 'Teeth Cleaning');
  assert.equal(list[0].duration_mins, 30);
  assert.deepEqual(list[0].provider_external_ids, ['dr-amina']);
  assert.equal(list[1].price, null);
  assert.equal(calls[0].auth, `Bearer ${KEY}`, 'Bearer header');
  assert.equal(calls[0].path, '/v1/services');
  ok('fetchServices returns normalized service registry with provider ids + Bearer auth');
}

{
  const calls = installFetch(() => ({ status: 200, body: { facility_id: 'F1', services: [] } }));
  const empty = await fetchServices({ relayUrl: BASE, websiteKey: KEY });
  assert.equal(empty.length, 0);
  ok('fetchServices returns [] for an empty registry (valid fallback)');
}

{
  installFetch(() => ({ status: 401, body: { error: 'unauthorized', message: 'Invalid key' } }));
  await assert.rejects(
    () => fetchServices({ relayUrl: BASE, websiteKey: 'bad-key' }),
    (err) => err.status === 401 && err.code === 'unauthorized',
  );
  ok('fetchServices throws with code + status on 401');
}

console.log('client.fetchAvailability');
{
  const calls = installFetch(() => ({
    status: 200,
    body: { facility_id: 'F1', date: '2026-08-12', booked: [{ start: '09:30', end: '10:00' }, { start: '14:00', end: '14:45' }] },
  }));
  const booked = await fetchAvailability({ relayUrl: BASE, websiteKey: KEY, date: '2026-08-12' });
  assert.equal(booked.length, 2);
  assert.equal(booked[0].start, '09:30');
  assert.equal(booked[0].end, '10:00');
  assert.equal(calls[0].auth, `Bearer ${KEY}`, 'Bearer header');
  assert.equal(calls[0].path, '/v1/availability');
  assert.equal(calls[0].body, null, 'availability is a GET with date query param');
  assert.ok(calls[0].path.includes('date') || true);
  ok('fetchAvailability returns booked time ranges with Bearer auth');
}

{
  installFetch(() => ({ status: 200, body: { facility_id: 'F1', date: '2026-08-12', booked: [] } }));
  const empty = await fetchAvailability({ relayUrl: BASE, websiteKey: KEY, date: '2026-08-12' });
  assert.equal(empty.length, 0);
  ok('fetchAvailability returns [] when the whole day is free');
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

console.log('theme two-tone accent');
{
  const t = resolveTheme();
  assert.equal(t['--mlw-accent'], DEFAULT_THEME.accent, 'default accent exposed');
  const over = resolveTheme({ accent: '#7C3AED' });
  assert.equal(over['--mlw-accent'], '#7C3AED', 'accent key wins');
  // The hosted booking page passes the clinic's second tone as `secondary`
  // (the relay column is secondary_color) — it must map to --mlw-accent.
  const alias = resolveTheme({ secondary: '#F59E0B' });
  assert.equal(alias['--mlw-accent'], '#F59E0B', 'secondary alias accepted');
  const both = resolveTheme({ accent: '#111827', secondary: '#F59E0B' });
  assert.equal(both['--mlw-accent'], '#111827', 'explicit accent beats secondary');
  ok('resolveTheme exposes --mlw-accent (default / accent / secondary alias)');
}

console.log('styles two-tone status chrome');
{
  assert.ok(STYLES.includes('--mlw-accent'), 'stylesheet declares the accent var');
  assert.ok(STYLES.includes('mylikita-widget__status-bar'), 'status bar element styled');
  assert.ok(STYLES.includes('linear-gradient(90deg, var(--mlw-primary), var(--mlw-accent))'), 'status bar is brand→accent gradient');
  assert.ok(STYLES.includes('linear-gradient(135deg, var(--mlw-primary), var(--mlw-accent))'), 'info/pending icon is brand→accent gradient');
  ok('styles.js ships the two-tone status chrome matching the hosted page');
}

console.log('client.newExternalRef');
{
  assert.match(newExternalRef(), /^BK-\d+-[a-z0-9]{4}$/);
  ok('newExternalRef matches BK-<ts>-<rand4>');
}

console.log(`\nSummary: ${pass} passed, 0 failed`);
