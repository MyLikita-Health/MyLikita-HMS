/**
 * Relay API client (pure — no DOM). Implements the exact v1 contract from
 * WEBSITE_BOOKING_API.md:
 *
 *   POST /v1/bookings          → { booking_ref, status } | 400/401/403/409/429/500
 *   GET  /v1/bookings/:ref     → { booking_ref, status, appt_ref? }
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
    return { ok: true, duplicate: true, booking_ref: body?.booking_ref, error: body?.message };
  }
  if (!res.ok) {
    throw apiError(res.status, body, 'create');
  }
  return { ok: true, duplicate: false, booking_ref: body?.booking_ref, status: body?.status || 'pending_confirmation' };
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
