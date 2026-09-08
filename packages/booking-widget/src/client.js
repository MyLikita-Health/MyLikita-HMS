/**
 * Relay API client (pure — no DOM). Implements the exact v1 contract from
 * WEBSITE_BOOKING_API.md:
 *
 *   POST /v1/bookings          → { booking_ref, status } | 400/401/403/409/429/500
 *   GET  /v1/bookings/:ref     → { booking_ref, status, appt_ref? }
 *   GET  /v1/providers         → { facility_id, providers: [{external_id, name, ...}] }
 *
 * Auth is `Authorization: Bearer <website_key>` on every request. The
 * website_key is a public client id by design (never a secret).
 */

/**
 * Create a booking. Returns `{ ok: true, booking_ref, status }` on success.
 * A 409 `duplicate_booking` is NOT an error — the patient double-submitted or
 * refreshed — it resolves with `{ ok: true, duplicate: true, booking_ref }`
 * and the caller treats it as success (per the contract §4) so the widget can
 * poll the existing booking. Other failures throw an Error with `.code` and
 * `.status`.
 */
export async function createBooking({ relayUrl, websiteKey, payload, signal }) {
  const res = await fetch(`${trimUrl(relayUrl)}/v1/bookings`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${websiteKey}`,
    },
    body: JSON.stringify(payload),
    signal,
  });
  const body = await readJson(res);

  if (res.status === 409) {
    // Two distinct 409 codes:
    //  - duplicate_booking: this SAME patient already holds the exact slot
    //    (page refresh / double-submit) — NOT an error; treat as success and
    //    poll the existing booking (per the contract §4).
    //  - slot_unavailable: the window is genuinely taken by ANOTHER booking
    //    (a race with another patient, or a walk-in / admin / provider block
    //    pushed after the widget cached availability) — surface it as an
    //    error so the patient picks a different time instead of being told
    //    their request is already in.
    if (body?.error === 'slot_unavailable') {
      throw apiError(res.status, body, 'create');
    }
    return { ok: true, duplicate: true, booking_ref: body?.booking_ref, error: body?.message };
  }
  if (!res.ok) {
    throw apiError(res.status, body, 'create');
  }
  return { ok: true, duplicate: false, booking_ref: body?.booking_ref, status: body?.status || 'pending_confirmation' };
}

/**
 * Fetch the facility's mapped provider list (Phase C2/C3) — the doctors the
 * hospital has published for the website's dropdown. The hospital pushes this
 * registry to the relay on its sync cycle; the website only ever sees mapped,
 * active providers (names + slugs, no PHI). Returns a normalized array
 * `[{ external_id, name, specialty, module }]`; an empty list is valid (the
 * widget falls back to "No preference").
 */
export async function fetchProviders({ relayUrl, websiteKey, signal }) {
  const res = await fetch(`${trimUrl(relayUrl)}/v1/providers`, {
    headers: { Authorization: `Bearer ${websiteKey}` },
    signal,
  });
  const body = await readJson(res);
  if (!res.ok) throw apiError(res.status, body, 'providers');
  const list = Array.isArray(body?.providers) ? body.providers : [];
  return list.map((p) => ({
    external_id: p.external_id,
    name: p.name || p.external_id,
    specialty: p.specialty || null,
    module: p.module || 'general',
  }));
}

/**
 * Fetch the facility's SERVICE registry (Phase C4) — real services with
 * durations and the providers that offer each. Returns a normalized array
 * [{ external_id, name, duration_mins, price, module, provider_external_ids }];
 * an empty list is valid (the widget falls back to a free-text service field).
 */
export async function fetchServices({ relayUrl, websiteKey, signal }) {
  const res = await fetch(`${trimUrl(relayUrl)}/v1/services`, {
    headers: { Authorization: `Bearer ${websiteKey}` },
    signal,
  });
  const body = await readJson(res);
  if (!res.ok) throw apiError(res.status, body, 'services');
  const list = Array.isArray(body?.services) ? body.services : [];
  return list.map((s) => ({
    external_id: s.external_id,
    name: s.name || s.external_id,
    duration_mins: Number.isFinite(Number(s.duration_mins)) ? Number(s.duration_mins) : 30,
    price: s.price == null ? null : Number(s.price),
    module: s.module || 'general',
    provider_external_ids: Array.isArray(s.provider_external_ids) ? s.provider_external_ids : [],
  }));
}

/**
 * Join a facility's waitlist (Phase C6) — used when every slot on a date is
 * taken so the patient doesn't give up. Buffered on the relay and pulled by
 * the hospital. Idempotent: re-submitting the same external_ref resolves with
 * { ok: true } (the entry already exists).
 */
export async function createWaitlist({ relayUrl, websiteKey, payload, signal }) {
  const res = await fetch(`${trimUrl(relayUrl)}/v1/waitlist`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${websiteKey}`,
    },
    body: JSON.stringify(payload),
    signal,
  });
  const body = await readJson(res);
  if (res.status === 409) {
    return { ok: true, duplicate: true, error: body?.message };
  }
  if (!res.ok) throw apiError(res.status, body, 'waitlist');
  return { ok: true, duplicate: false, status: body?.status || 'waiting' };
}

/**
 * Track a booking-page/embed VIEW (Phase C7) so the relay can compute
 * conversion-by-source (bookings / views). Only the source + facility + day
 * are sent — no visitor identity. Best-effort; failures are swallowed by the
 * caller (a tracking ping must never break the widget).
 */
export async function trackPageView({ relayUrl, websiteKey, source, signal }) {
  try {
    const res = await fetch(`${trimUrl(relayUrl)}/v1/track`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${websiteKey}` },
      body: JSON.stringify({ source: source || null }),
      signal,
    });
    if (!res.ok) await readJson(res); // swallow — best-effort
  } catch (_) { /* best-effort: never surface tracking failures */ }
}

/**
 * Fetch the facility's BOOKED time ranges for a date (real-time availability).
 * The widget blocks candidate slots that overlap an already-booked range so
 * two patients can't double-book the same window. Returns `[{ start, end }]`
 * in local wall-clock HH:MM; an empty array means the whole day is free.
 */
export async function fetchAvailability({ relayUrl, websiteKey, date, signal }) {
  const qs = new URLSearchParams({ date });
  const res = await fetch(`${trimUrl(relayUrl)}/v1/availability?${qs}`, {
    headers: { Authorization: `Bearer ${websiteKey}` },
    signal,
  });
  const body = await readJson(res);
  if (!res.ok) throw apiError(res.status, body, 'availability');
  const list = Array.isArray(body?.booked) ? body.booked : [];
  return list
    .filter((b) => b && typeof b.start === 'string' && typeof b.end === 'string')
    .map((b) => ({ start: b.start, end: b.end }));
}

/** Fetch a booking's current status. */
export async function fetchStatus({ relayUrl, websiteKey, bookingRef, signal }) {
  const res = await fetch(`${trimUrl(relayUrl)}/v1/bookings/${encodeURIComponent(bookingRef)}`, {
    headers: { Authorization: `Bearer ${websiteKey}` },
    signal,
  });
  const body = await readJson(res);
  if (!res.ok) throw apiError(res.status, body, 'status');
  return { booking_ref: body?.booking_ref, status: body?.status || 'pending_confirmation', appt_ref: body?.appt_ref || null };
}

/**
 * Bounded status poll. Calls `client()` (a thunk returning a status object)
 * every `intervalMs` until the status leaves `pending_confirmation` or
 * `maxTries` attempts run out.
 *
 * Cancellation: pass an `AbortSignal`. Aborting resolves early with
 * `{ status: 'aborted', resolved: false }` — the caller should treat that as
 * "stop, the widget was destroyed", not as an error.
 *
 * @returns {Promise<{status:string, resolved:boolean, data:object}>}
 */
export async function pollStatus(client, { intervalMs = 5000, maxTries = 12, signal } = {}) {
  for (let i = 0; i < maxTries; i++) {
    if (signal?.aborted) return { status: 'aborted', resolved: false, data: null };
    const data = await client();
    if (data.status !== 'pending_confirmation') {
      return { status: data.status, resolved: true, data };
    }
    if (i < maxTries - 1) await sleep(intervalMs, signal);
  }
  return { status: 'pending_confirmation', resolved: false, data: null };
}

export function newExternalRef() {
  return `BK-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
}

// ── internals ───────────────────────────────────────────────────────────────

function trimUrl(url) {
  return String(url || '').replace(/\/+$/, '');
}

function apiError(status, body, phase) {
  const err = new Error(body?.message || body?.error || `Relay ${phase} failed (HTTP ${status})`);
  err.code = body?.error || 'http_error';
  err.status = status;
  return err;
}

async function readJson(res) {
  try { return await res.json(); } catch (_) { return null; }
}

function sleep(ms, signal) {
  return new Promise((resolve) => {
    if (signal?.aborted) return resolve();
    const onAbort = () => { clearTimeout(t); resolve(); };
    const t = setTimeout(() => { signal?.removeEventListener('abort', onAbort); resolve(); }, ms);
    signal?.addEventListener('abort', onAbort, { once: true });
  });
}
