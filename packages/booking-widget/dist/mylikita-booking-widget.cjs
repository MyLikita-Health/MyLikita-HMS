/*! @mylikita/booking-widget v1.26.0 | MIT */
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/index.js
var index_exports = {};
__export(index_exports, {
  DEFAULT_THEME: () => DEFAULT_THEME,
  MYLIKITA_MARK_DATA_URI: () => MYLIKITA_MARK_DATA_URI,
  STATUS_COPY: () => STATUS_COPY,
  TERMINAL_STATUSES: () => TERMINAL_STATUSES,
  createBooking: () => createBooking,
  createBookingWidget: () => createBookingWidget,
  createBrandHeader: () => createBrandHeader,
  fetchProviders: () => fetchProviders,
  fetchStatus: () => fetchStatus,
  newExternalRef: () => newExternalRef,
  pollStatus: () => pollStatus,
  resolveTheme: () => resolveTheme,
  statusCopy: () => statusCopy
});
module.exports = __toCommonJS(index_exports);

// src/client.js
async function createBooking({ relayUrl, websiteKey, payload, signal }) {
  const res = await fetch(`${trimUrl(relayUrl)}/v1/bookings`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${websiteKey}`
    },
    body: JSON.stringify(payload),
    signal
  });
  const body = await readJson(res);
  if (res.status === 409) {
    if (body?.error === "slot_unavailable") {
      throw apiError(res.status, body, "create");
    }
    return { ok: true, duplicate: true, booking_ref: body?.booking_ref, error: body?.message };
  }
  if (!res.ok) {
    throw apiError(res.status, body, "create");
  }
  return { ok: true, duplicate: false, booking_ref: body?.booking_ref, status: body?.status || "pending_confirmation" };
}
async function fetchProviders({ relayUrl, websiteKey, signal }) {
  const res = await fetch(`${trimUrl(relayUrl)}/v1/providers`, {
    headers: { Authorization: `Bearer ${websiteKey}` },
    signal
  });
  const body = await readJson(res);
  if (!res.ok) throw apiError(res.status, body, "providers");
  const list = Array.isArray(body?.providers) ? body.providers : [];
  return list.map((p) => ({
    external_id: p.external_id,
    name: p.name || p.external_id,
    specialty: p.specialty || null,
    module: p.module || "general"
  }));
}
async function fetchServices({ relayUrl, websiteKey, signal }) {
  const res = await fetch(`${trimUrl(relayUrl)}/v1/services`, {
    headers: { Authorization: `Bearer ${websiteKey}` },
    signal
  });
  const body = await readJson(res);
  if (!res.ok) throw apiError(res.status, body, "services");
  const list = Array.isArray(body?.services) ? body.services : [];
  return list.map((s) => ({
    external_id: s.external_id,
    name: s.name || s.external_id,
    duration_mins: Number.isFinite(Number(s.duration_mins)) ? Number(s.duration_mins) : 30,
    price: s.price == null ? null : Number(s.price),
    module: s.module || "general",
    provider_external_ids: Array.isArray(s.provider_external_ids) ? s.provider_external_ids : []
  }));
}
async function createWaitlist({ relayUrl, websiteKey, payload, signal }) {
  const res = await fetch(`${trimUrl(relayUrl)}/v1/waitlist`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${websiteKey}`
    },
    body: JSON.stringify(payload),
    signal
  });
  const body = await readJson(res);
  if (res.status === 409) {
    return { ok: true, duplicate: true, error: body?.message };
  }
  if (!res.ok) throw apiError(res.status, body, "waitlist");
  return { ok: true, duplicate: false, status: body?.status || "waiting" };
}
async function trackPageView({ relayUrl, websiteKey, source, signal }) {
  try {
    const res = await fetch(`${trimUrl(relayUrl)}/v1/track`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${websiteKey}` },
      body: JSON.stringify({ source: source || null }),
      signal
    });
    if (!res.ok) await readJson(res);
  } catch (_) {
  }
}
async function fetchAvailability({ relayUrl, websiteKey, date, signal }) {
  const qs = new URLSearchParams({ date });
  const res = await fetch(`${trimUrl(relayUrl)}/v1/availability?${qs}`, {
    headers: { Authorization: `Bearer ${websiteKey}` },
    signal
  });
  const body = await readJson(res);
  if (!res.ok) throw apiError(res.status, body, "availability");
  const list = Array.isArray(body?.booked) ? body.booked : [];
  return list.filter((b) => b && typeof b.start === "string" && typeof b.end === "string").map((b) => ({ start: b.start, end: b.end }));
}
async function fetchStatus({ relayUrl, websiteKey, bookingRef, signal }) {
  const res = await fetch(`${trimUrl(relayUrl)}/v1/bookings/${encodeURIComponent(bookingRef)}`, {
    headers: { Authorization: `Bearer ${websiteKey}` },
    signal
  });
  const body = await readJson(res);
  if (!res.ok) throw apiError(res.status, body, "status");
  return { booking_ref: body?.booking_ref, status: body?.status || "pending_confirmation", appt_ref: body?.appt_ref || null };
}
async function pollStatus(client, { intervalMs = 5e3, maxTries = 12, signal } = {}) {
  for (let i = 0; i < maxTries; i++) {
    if (signal?.aborted) return { status: "aborted", resolved: false, data: null };
    const data = await client();
    if (data.status !== "pending_confirmation") {
      return { status: data.status, resolved: true, data };
    }
    if (i < maxTries - 1) await sleep(intervalMs, signal);
  }
  return { status: "pending_confirmation", resolved: false, data: null };
}
function newExternalRef() {
  return `BK-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
}
function trimUrl(url) {
  return String(url || "").replace(/\/+$/, "");
}
function apiError(status, body, phase) {
  const err = new Error(body?.message || body?.error || `Relay ${phase} failed (HTTP ${status})`);
  err.code = body?.error || "http_error";
  err.status = status;
  return err;
}
async function readJson(res) {
  try {
    return await res.json();
  } catch (_) {
    return null;
  }
}
function sleep(ms, signal) {
  return new Promise((resolve) => {
    if (signal?.aborted) return resolve();
    const onAbort = () => {
      clearTimeout(t);
      resolve();
    };
    const t = setTimeout(() => {
      signal?.removeEventListener("abort", onAbort);
      resolve();
    }, ms);
    signal?.addEventListener("abort", onAbort, { once: true });
  });
}

// src/state.js
var STATUS_COPY = {
  pending_confirmation: {
    title: "Request received",
    message: "We've received your booking request \u2014 we'll confirm shortly.",
    kind: "info"
  },
  confirmed: {
    title: "Appointment confirmed",
    message: "Your appointment is confirmed. See you at the clinic!",
    kind: "success"
  },
  cancelled: {
    title: "Appointment cancelled",
    message: "This appointment was cancelled. Please contact the clinic if this was unexpected.",
    kind: "danger"
  },
  rescheduled: {
    title: "Appointment rescheduled",
    message: "This appointment was moved \u2014 the new time was sent to you.",
    kind: "info"
  },
  no_show: {
    title: "Missed appointment",
    message: "This appointment was marked as missed.",
    kind: "danger"
  },
  expired: {
    title: "Request expired",
    message: "This booking request expired \u2014 please call the clinic to book.",
    kind: "danger"
  },
  // Widget-internal: the poll itself failed (network, rotated key, etc.).
  poll_error: {
    title: "Something went wrong",
    message: "We could not check your booking right now. Please try again shortly.",
    kind: "danger"
  }
};
function statusCopy(status) {
  return STATUS_COPY[status] || STATUS_COPY.pending_confirmation;
}
var TERMINAL_STATUSES = ["confirmed", "cancelled", "rescheduled", "no_show", "expired"];

// src/theme.js
var DEFAULT_THEME = {
  primary: "#0d6efd",
  primaryDark: "#0b5ed7",
  primaryText: "#ffffff",
  // Second tone of the facility's two-tone brand — the relay's hosted booking
  // page themes its gradient strip / avatar with brand→accent, and the
  // widget mirrors that on its status screen (see styles.js). The hosted
  // page's own default accent is #0d9488, kept here so an un-themed widget
  // matches the default hosted page.
  accent: "#0d9488",
  bg: "#ffffff",
  text: "#1e293b",
  muted: "#64748b",
  border: "#e2e8f0",
  danger: "#dc3545",
  success: "#15803d",
  radius: 10,
  font: "system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif"
};
function resolveTheme(theme = {}) {
  const raw = theme || {};
  const accent = raw.accent ?? raw.secondary ?? DEFAULT_THEME.accent;
  const t = { ...DEFAULT_THEME, ...raw, accent };
  return {
    "--mlw-primary": t.primary,
    "--mlw-primary-dark": t.primaryDark,
    "--mlw-primary-text": t.primaryText,
    "--mlw-accent": t.accent,
    "--mlw-bg": t.bg,
    "--mlw-text": t.text,
    "--mlw-muted": t.muted,
    "--mlw-border": t.border,
    "--mlw-danger": t.danger,
    "--mlw-success": t.success,
    "--mlw-radius": `${t.radius}px`,
    "--mlw-font": t.font
  };
}

// src/styles.js
var STYLES = `
.mylikita-widget {
  --mlw-primary: #0d6efd;
  --mlw-primary-dark: #0b5ed7;
  --mlw-primary-text: #ffffff;
  --mlw-accent: #0d9488;
  --mlw-bg: #ffffff;
  --mlw-text: #1e293b;
  --mlw-muted: #64748b;
  --mlw-border: #e2e8f0;
  --mlw-danger: #dc3545;
  --mlw-success: #15803d;
  --mlw-radius: 10px;
  --mlw-font: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif;
  font-family: var(--mlw-font);
  color: var(--mlw-text);
  background: var(--mlw-bg);
  border: 1px solid var(--mlw-border);
  border-radius: calc(var(--mlw-radius) + 2px);
  padding: 22px;
  max-width: 480px;
  box-sizing: border-box;
  line-height: 1.5;
}
.mylikita-widget *,
.mylikita-widget *::before,
.mylikita-widget *::after { box-sizing: border-box; }

.mylikita-widget__brand {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 14px;
  padding-bottom: 12px;
  border-bottom: 1px solid var(--mlw-border);
}
.mylikita-widget__brand-mark {
  display: block;
  flex: 0 0 auto;
  border-radius: 5px;
  box-shadow: 0 1px 3px rgba(15, 23, 42, .12);
}
.mylikita-widget__brand-word {
  font-size: 14px;
  font-weight: 700;
  letter-spacing: .3px;
  color: var(--mlw-muted);
}

.mylikita-widget__title {
  font-size: 18px;
  font-weight: 700;
  margin: 0 0 4px;
  color: var(--mlw-text);
}
.mylikita-widget__subtitle {
  font-size: 13px;
  color: var(--mlw-muted);
  margin: 0 0 16px;
}

.mylikita-widget__field { margin-bottom: 12px; }
/* "No account needed" reassurance pill under the heading. */
.mylikita-widget__noaccount {
  display: inline-block;
  font-size: 11px;
  font-weight: 700;
  color: var(--mlw-accent);
  background: color-mix(in srgb, var(--mlw-accent) 10%, transparent);
  border: 1px solid color-mix(in srgb, var(--mlw-accent) 35%, transparent);
  border-radius: 999px;
  padding: 3px 10px;
  margin-bottom: 12px;
}
/* Small helper text under a field (e.g. the service autocomplete). */
.mylikita-widget__field-hint {
  font-size: 11.5px;
  color: var(--mlw-muted);
  margin: 4px 0 0;
}
/* Date + time-slot picker (P0) \u2014 a native date input plus selectable chips. */
.mylikita-widget__slotfield { margin-top: 12px; }
.mylikita-widget__slots {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(82px, 1fr));
  gap: 8px;
}
.mylikita-widget__slot {
  font: inherit;
  font-size: 13px;
  font-weight: 600;
  color: var(--mlw-text);
  background: var(--mlw-bg);
  border: 1px solid var(--mlw-border);
  border-radius: var(--mlw-radius);
  padding: 8px 10px;
  text-align: center;
  cursor: pointer;
  transition: border-color .15s ease, background .15s ease, color .15s ease, box-shadow .15s ease;
}
.mylikita-widget__slot:hover {
  border-color: var(--mlw-primary);
  color: var(--mlw-primary);
  background: color-mix(in srgb, var(--mlw-primary) 7%, transparent);
}
.mylikita-widget__slot:focus-visible {
  outline: 2px solid var(--mlw-primary);
  outline-offset: 2px;
}
.mylikita-widget__slot.selected {
  color: var(--mlw-primary-text);
  background: var(--mlw-primary);
  border-color: var(--mlw-primary);
  box-shadow: 0 3px 10px color-mix(in srgb, var(--mlw-primary) 28%, transparent);
}
.mylikita-widget__slot.selected:hover {
  color: var(--mlw-primary-text);
  background: var(--mlw-primary);
}
/* Taken slots \u2014 shown struck-through and disabled so patients see the whole
   day at a glance (Phase C6), not just the free times. */
.mylikita-widget__slot-taken {
  color: var(--mlw-muted) !important;
  background: color-mix(in srgb, var(--mlw-border) 45%, transparent) !important;
  border-color: var(--mlw-border) !important;
  text-decoration: line-through;
  cursor: not-allowed;
  opacity: .7;
}
.mylikita-widget__slot-hint { font-size: 12px; color: var(--mlw-muted); margin: 8px 0 0; }

/* Waitlist panel (Phase C6) \u2014 revealed under the slots when nothing is free. */
.mylikita-widget__waitlist {
  margin-top: 12px;
  padding: 12px 14px;
  border: 1px dashed var(--mlw-accent);
  border-left: 3px solid var(--mlw-accent);
  border-radius: calc(var(--mlw-radius) * 0.7);
  background: color-mix(in srgb, var(--mlw-accent) 5%, transparent);
}
.mylikita-widget__waitlist[hidden] { display: none; }
.mylikita-widget__waitlist-title { margin: 0 0 3px; font-size: 13px; font-weight: 700; color: var(--mlw-text); }
.mylikita-widget__waitlist-hint { margin: 0 0 10px; font-size: 12px; color: var(--mlw-muted); line-height: 1.5; }
.mylikita-widget__waitlist-btn {
  font: inherit;
  font-size: 13px;
  font-weight: 700;
  color: var(--mlw-primary-text);
  background: var(--mlw-primary);
  border: none;
  border-radius: 999px;
  padding: 8px 16px;
  cursor: pointer;
  transition: background .15s ease;
}
.mylikita-widget__waitlist-btn:hover { background: var(--mlw-primary-dark); }
.mylikita-widget__waitlist-btn:disabled { opacity: .6; cursor: wait; }
.mylikita-widget__label {
  display: block;
  font-size: 12px;
  font-weight: 600;
  color: var(--mlw-text);
  margin-bottom: 5px;
}
.mylikita-widget__label .req { color: var(--mlw-danger); }
.mylikita-widget__input,
.mylikita-widget__select,
.mylikita-widget__textarea {
  width: 100%;
  font: inherit;
  font-size: 14px;
  color: var(--mlw-text);
  background: var(--mlw-bg);
  border: 1px solid var(--mlw-border);
  border-radius: var(--mlw-radius);
  padding: 9px 11px;
  outline: none;
  transition: border-color .15s ease, box-shadow .15s ease;
}
.mylikita-widget__input:focus,
.mylikita-widget__select:focus,
.mylikita-widget__textarea:focus {
  border-color: var(--mlw-primary);
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--mlw-primary) 22%, transparent);
}
.mylikita-widget__row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
@media (max-width: 420px) { .mylikita-widget__row { grid-template-columns: 1fr; } }

.mylikita-widget__error {
  display: none;
  font-size: 13px;
  color: var(--mlw-danger);
  background: color-mix(in srgb, var(--mlw-danger) 8%, transparent);
  border: 1px solid color-mix(in srgb, var(--mlw-danger) 35%, transparent);
  border-radius: var(--mlw-radius);
  padding: 9px 12px;
  margin-bottom: 12px;
}
.mylikita-widget__error.visible { display: block; }

.mylikita-widget__submit {
  width: 100%;
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  color: var(--mlw-primary-text);
  background: var(--mlw-primary);
  border: none;
  border-radius: var(--mlw-radius);
  padding: 11px 16px;
  cursor: pointer;
  transition: background .15s ease, transform .05s ease;
}
.mylikita-widget__submit:hover { background: var(--mlw-primary-dark); }
.mylikita-widget__submit:active { transform: translateY(1px); }
.mylikita-widget__submit:disabled { opacity: .6; cursor: wait; }

.mylikita-widget__hint { font-size: 12px; color: var(--mlw-muted); margin: 8px 0 0; }

/* ANC sub-group (antenatal booking, ancBooking option) \u2014 visually distinct
   so the LMP question reads as a deliberate extra step, and hidden entirely
   for normal appointments via the hidden attribute (never display:none
   overrides it). */
.mylikita-widget__anc {
  margin: -2px 0 12px;
  padding: 10px 12px 12px;
  border: 1px dashed var(--mlw-border);
  border-left: 3px solid var(--mlw-accent);
  border-radius: calc(var(--mlw-radius) * 0.7);
  background: color-mix(in srgb, var(--mlw-accent) 4%, transparent);
}
.mylikita-widget__anc[hidden] { display: none; }
.mylikita-widget__anc-note { font-size: 12px; color: var(--mlw-muted); margin: 2px 0 0; }

/* status view \u2014 carries the facility's two-tone brand (brand\u2192accent),
   mirroring the hosted booking page's gradient strip and avatar so the
   embed's confirmation/status screen reads as the same page. */
.mylikita-widget__status { text-align: center; padding: 8px 4px 4px; }
.mylikita-widget__status-bar {
  display: block;
  height: 3px;
  margin: 0 0 18px;
  border-radius: 999px;
  background: linear-gradient(90deg, var(--mlw-primary), var(--mlw-accent));
}
.mylikita-widget__status-icon {
  width: 46px; height: 46px;
  border-radius: 50%;
  display: inline-flex; align-items: center; justify-content: center;
  font-size: 22px; margin-bottom: 10px;
}
/* "info" is the pending/processing state \u2014 it wears the two-tone gradient
   (like the hosted page's hero avatar); semantic results keep their colours. */
.mylikita-widget__status-icon.info {
  color: var(--mlw-primary-text);
  background: linear-gradient(135deg, var(--mlw-primary), var(--mlw-accent));
}
.mylikita-widget__status-icon.success { color: var(--mlw-success); background: color-mix(in srgb, var(--mlw-success) 14%, transparent); }
.mylikita-widget__status-icon.danger { color: var(--mlw-danger); background: color-mix(in srgb, var(--mlw-danger) 12%, transparent); }
.mylikita-widget__status-title { font-size: 16px; font-weight: 700; margin: 0 0 4px; }
.mylikita-widget__status-message { font-size: 13px; color: var(--mlw-muted); margin: 0 0 14px; }
.mylikita-widget__status-ref { font-size: 12px; color: var(--mlw-muted); margin: 0 0 14px; }

.mylikita-widget__spinner {
  width: 18px; height: 18px;
  display: inline-block;
  border: 2px solid color-mix(in srgb, var(--mlw-primary-text) 40%, transparent);
  border-top-color: var(--mlw-primary-text);
  border-radius: 50%;
  animation: mylikita-widget-spin .7s linear infinite;
  vertical-align: -3px;
  margin-right: 7px;
}
@keyframes mylikita-widget-spin { to { transform: rotate(360deg); } }

.mylikita-widget__link-btn {
  background: none;
  border: 1px solid var(--mlw-border);
  border-radius: var(--mlw-radius);
  color: var(--mlw-text);
  font: inherit;
  font-size: 13px;
  padding: 8px 14px;
  cursor: pointer;
}
.mylikita-widget__link-btn:hover { border-color: var(--mlw-primary); color: var(--mlw-primary); }

/* confirmation summary card + actions (rendered on the status screen). */
.mylikita-widget__confirm {
  margin: 14px auto;
  max-width: 340px;
  text-align: left;
  border: 1px solid var(--mlw-border);
  border-radius: calc(var(--mlw-radius) * 0.8);
  overflow: hidden;
}
.mylikita-widget__confirm-row {
  display: flex;
  justify-content: space-between;
  gap: 14px;
  padding: 9px 14px;
  font-size: 13px;
}
.mylikita-widget__confirm-row + .mylikita-widget__confirm-row { border-top: 1px solid var(--mlw-border); }
.mylikita-widget__confirm-k { color: var(--mlw-muted); flex-shrink: 0; }
.mylikita-widget__confirm-v { font-weight: 600; text-align: right; }

.mylikita-widget__confirm-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  justify-content: center;
  margin: 4px auto 16px;
}
.mylikita-widget__act {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  background: none;
  border: 1px solid var(--mlw-border);
  border-radius: 999px;
  color: var(--mlw-text);
  font: inherit;
  font-size: 13px;
  font-weight: 600;
  padding: 8px 14px;
  cursor: pointer;
  text-decoration: none;
}
.mylikita-widget__act:hover { border-color: var(--mlw-primary); color: var(--mlw-primary); }
.mylikita-widget__act-wa {
  color: #fff;
  background: #25d366;
  border-color: #25d366;
}
.mylikita-widget__act-wa:hover {
  color: #fff;
  background: #1ebe5b;
  border-color: #1ebe5b;
}

/* V2 guided flow \u2014 4-step progress indicator */
.mylikita-widget__progress {
  list-style: none;
  display: flex;
  align-items: center;
  gap: 4px;
  margin: 0 0 16px;
  padding: 0;
}
.mylikita-widget__progress-item {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 5px;
  color: var(--mlw-muted);
  font-size: 11px;
  font-weight: 600;
  min-width: 0;
}
.mylikita-widget__progress-item + .mylikita-widget__progress-item::before {
  content: '';
  flex: 1;
  height: 2px;
  border-radius: 999px;
  background: var(--mlw-border);
  margin-right: 5px;
}
.mylikita-widget__progress-dot {
  width: 20px;
  height: 20px;
  flex: 0 0 auto;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 700;
  color: var(--mlw-muted);
  background: color-mix(in srgb, var(--mlw-border) 60%, transparent);
}
.mylikita-widget__progress-item.active .mylikita-widget__progress-dot {
  color: var(--mlw-primary-text);
  background: var(--mlw-primary);
}
.mylikita-widget__progress-item.done .mylikita-widget__progress-dot {
  color: var(--mlw-primary-text);
  background: var(--mlw-accent);
}
.mylikita-widget__progress-item.done .mylikita-widget__progress-label {
  color: var(--mlw-accent);
}
.mylikita-widget__progress-item.active .mylikita-widget__progress-label {
  color: var(--mlw-primary);
}
.mylikita-widget__progress-label {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
@media (max-width: 380px) { .mylikita-widget__progress-label { display: none; } }

/* Step shells */
.mylikita-widget__step[hidden] { display: none; }
.mylikita-widget__step-title {
  font-size: 16px;
  font-weight: 700;
  margin: 0 0 3px;
  color: var(--mlw-text);
}
.mylikita-widget__step-sub {
  font-size: 13px;
  color: var(--mlw-muted);
  margin: 0 0 14px;
  line-height: 1.5;
}
.mylikita-widget__step-actions {
  display: flex;
  gap: 8px;
  margin-top: 14px;
}
.mylikita-widget__cta {
  flex: 1;
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  color: var(--mlw-primary-text);
  background: var(--mlw-primary);
  border: none;
  border-radius: var(--mlw-radius);
  padding: 11px 16px;
  cursor: pointer;
  transition: background .15s ease;
}
.mylikita-widget__cta:hover { background: var(--mlw-primary-dark); }
.mylikita-widget__cta-ghost {
  flex: 0 0 auto;
  color: var(--mlw-text);
  background: var(--mlw-bg);
  border: 1px solid var(--mlw-border);
}
.mylikita-widget__cta-ghost:hover { border-color: var(--mlw-primary); color: var(--mlw-primary); background: var(--mlw-bg); }

/* Date cards \u2014 horizontally scrollable day picker */
.mylikita-widget__dates {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding: 2px 2px 8px;
  margin-bottom: 14px;
  -webkit-overflow-scrolling: touch;
  scrollbar-width: thin;
}
.mylikita-widget__date-card {
  flex: 0 0 auto;
  min-width: 58px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  padding: 9px 8px;
  border: 1px solid var(--mlw-border);
  border-radius: 12px;
  background: var(--mlw-bg);
  cursor: pointer;
  font-family: var(--mlw-font);
  box-shadow: 0 1px 2px rgba(15, 23, 42, .04);
  transition: border-color .15s ease, background .15s ease, color .15s ease, box-shadow .15s ease;
}
.mylikita-widget__date-card:hover {
  border-color: var(--mlw-primary);
  background: color-mix(in srgb, var(--mlw-primary) 6%, transparent);
}
.mylikita-widget__date-card:focus-visible {
  outline: 2px solid var(--mlw-primary);
  outline-offset: 2px;
}
.mylikita-widget__date-card.selected {
  color: var(--mlw-primary-text);
  background: var(--mlw-primary);
  border-color: var(--mlw-primary);
  box-shadow: 0 4px 14px color-mix(in srgb, var(--mlw-primary) 30%, transparent);
}
.mylikita-widget__date-card.selected:hover { background: var(--mlw-primary); }
/* Unavailable (closed) days \u2014 clearly muted and non-interactive: reduced
   opacity, dashed border, the day numeral struck through, no hover lift. */
.mylikita-widget__date-card.closed {
  opacity: .5;
  cursor: not-allowed;
  background: var(--mlw-bg);
  border-style: dashed;
  border-color: var(--mlw-border);
  box-shadow: none;
}
.mylikita-widget__date-card.closed:hover {
  border-color: var(--mlw-border);
  background: var(--mlw-bg);
}
.mylikita-widget__date-card.closed .mylikita-widget__date-day {
  text-decoration: line-through;
  text-decoration-thickness: 1.5px;
  text-decoration-color: color-mix(in srgb, var(--mlw-muted) 70%, transparent);
}
.mylikita-widget__date-week { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .04em; opacity: .8; }
.mylikita-widget__date-day { font-size: 18px; font-weight: 700; line-height: 1; }
.mylikita-widget__date-month { font-size: 10px; opacity: .8; }

/* Review step \u2014 appointment summary + patient details */
.mylikita-widget__review {
  border: 1px solid var(--mlw-border);
  border-radius: calc(var(--mlw-radius) * 0.8);
  overflow: hidden;
}
.mylikita-widget__review-row {
  display: flex;
  justify-content: space-between;
  gap: 14px;
  padding: 9px 14px;
  font-size: 13px;
}
.mylikita-widget__review-row + .mylikita-widget__review-row { border-top: 1px solid var(--mlw-border); }
.mylikita-widget__review-k { color: var(--mlw-muted); flex-shrink: 0; }
.mylikita-widget__review-v { font-weight: 600; text-align: right; }
.mylikita-widget__review-yours {
  border-top: 1px solid var(--mlw-border);
  padding: 9px 14px;
}
.mylikita-widget__review-head {
  font-size: 12px;
  font-weight: 700;
  color: var(--mlw-muted);
  margin-bottom: 3px;
}
.mylikita-widget__review-line { font-size: 13px; font-weight: 600; }

/* Sticky step CTA on small screens (the action stays reachable) */
@media (max-width: 480px) {
  .mylikita-widget__step-actions {
    position: sticky;
    bottom: 10px;
    background: var(--mlw-bg);
    padding: 8px 2px 2px;
    margin: 12px -2px -2px;
    z-index: 2;
  }
}
`;

// src/brand.js
var MYLIKITA_MARK_DATA_URI = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0ODMgODA0IiB3aWR0aD0iNDgzIiBoZWlnaHQ9IjgwNCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsPSJNeUxpa2l0YSI+CiAgICA8cmVjdCB4PSIxNjEiIHk9IjAiIHdpZHRoPSIxNjEiIGhlaWdodD0iMTYxIiBmaWxsPSIjMDE2OURBIi8+CiAgICA8cmVjdCB4PSIwIiB5PSIxNjAiIHdpZHRoPSIxNjIiIGhlaWdodD0iMTYxIiBmaWxsPSIjMDE2OURBIi8+CiAgICA8cmVjdCB4PSIzMjEiIHk9IjE2MCIgd2lkdGg9IjE2MiIgaGVpZ2h0PSIxNjEiIGZpbGw9IiMwMTY5REEiLz4KICAgIDxyZWN0IHg9IjAiIHk9IjQ4MiIgd2lkdGg9IjE2MiIgaGVpZ2h0PSIxNjIiIGZpbGw9IiMwNDk4RkIiLz4KICAgIDxyZWN0IHg9IjMyMSIgeT0iNDgyIiB3aWR0aD0iMTYyIiBoZWlnaHQ9IjE2MiIgZmlsbD0iIzA0OThGQiIvPgogICAgPHJlY3QgeD0iMTYxIiB5PSI2NDMiIHdpZHRoPSIxNjEiIGhlaWdodD0iMTYxIiBmaWxsPSIjMDQ5OEZCIi8+Cjwvc3ZnPg==";
function createBrandHeader() {
  const header = document.createElement("div");
  header.className = "mylikita-widget__brand";
  const img = document.createElement("img");
  img.className = "mylikita-widget__brand-mark";
  img.src = MYLIKITA_MARK_DATA_URI;
  img.alt = "MyLikita";
  img.width = 24;
  img.height = 24;
  const word = document.createElement("span");
  word.className = "mylikita-widget__brand-word";
  word.textContent = "MyLikita";
  header.append(img, word);
  return header;
}

// src/widget.js
var DEFAULT_TEXT = {
  title: "Book an appointment",
  subtitle: "Request a slot and we will confirm shortly.",
  name: "Full name",
  phone: "Phone number",
  email: "Email address",
  provider: "Preferred doctor (optional)",
  noPreference: "No preference",
  service: "Service (optional)",
  serviceHint: "Start typing to see options, or type your own.",
  // Phase C4 structured service registry dropdown.
  selectService: "Select a service\u2026",
  otherService: "Other / not listed",
  otherServiceLabel: "Tell us what you need",
  serviceOtherPlaceholder: "e.g. tooth extraction, cleaning\u2026",
  // P0 conversion UX — the raw datetime input is replaced by a friendly
  // date + time-slot picker (native date field + operating-hours slot chips).
  date: "Choose a date",
  slot: "Available times",
  selectDateHint: "Pick a date to see available times.",
  closedDay: "We are closed on this day \u2014 please choose another date.",
  noSlots: "No times available for this date \u2014 please pick another day.",
  checkingAvailability: "Checking available times\u2026",
  requiredSlot: "Please choose an available time.",
  // Phase C6 — visual taken/free + waitlist. Taken slots render struck-through
  // alongside free ones so patients see the whole day at a glance; a legend
  // distinguishes them. When no slot is free a waitlist panel appears.
  slotTakenLabel: "Taken",
  slotFreeLabel: "Available",
  slotLegend: "Struck-through times are already booked.",
  noFreeSlots: "No times are free on this day \u2014 join the waitlist below.",
  waitlistTitle: "All booked? Join the waitlist",
  waitlistHint: "We\u2019ll contact you if a slot opens up.",
  waitlistSubmit: "Join waitlist",
  waitlistSubmitted: "You\u2019re on the waitlist",
  waitlistSubmittedMsg: "We\u2019ll call or message you if an appointment becomes available.",
  // Nigerian-aware phone validation + the "no account needed" reassurance.
  requiredPhone: "Please enter your phone number.",
  invalidPhone: "Please enter a valid phone number (e.g. 0803 123 4567).",
  noAccount: "No account needed",
  datetime: "Preferred date & time",
  visitType: "Appointment type",
  visitPhysical: "In person",
  visitTelemedicine: "Video call",
  visitHome: "Home visit",
  // ANC (antenatal) flow — only shown when the widget is constructed with
  // `ancBooking: true` (see ancBooking option). All text stays i18n-overridable.
  visitAntenatal: "Antenatal checkup",
  ancPrompt: "To book your antenatal visit we need your last period date.",
  ancLmp: "First day of your last period (LMP)",
  ancLmpHint: "We will estimate your baby's due date from this.",
  ancRequiredLmp: "Please enter the first day of your last period.",
  notes: "Notes (optional)",
  submit: "Request appointment",
  submitting: "Submitting\u2026",
  bookAnother: "Book another appointment",
  requiredPhoneOrEmail: "Please provide a phone number or an email address.",
  requiredName: "Please enter your name.",
  requiredDatetime: "Please choose a date and time.",
  networkError: "Could not reach the booking service. Please try again.",
  rateLimited: "Too many requests \u2014 please wait a moment and try again.",
  slotTaken: "That time was just booked by someone else \u2014 please pick another.",
  // Confirmation screen (booking ref + summary + calendar/WhatsApp actions).
  addToCalendar: "Add to calendar",
  calAdded: "\u2713 Added to calendar",
  whatsappClinic: "WhatsApp clinic",
  confirmWhen: "When",
  confirmService: "Service",
  confirmDoctor: "Doctor",
  confirmVisit: "Visit type",
  general: "General",
  // V2 guided flow — 4 steps with a progress indicator.
  stepService: "Service",
  stepDateTime: "Date & Time",
  stepDetails: "Your Details",
  stepReview: "Confirm",
  progressLabel: "Booking progress",
  step1Title: "What service do you need?",
  step1Sub: "Select the service you need. This helps us find the right doctor and available times.",
  step2Title: "Choose a date & time",
  step2Sub: "Pick a date, then choose an available time.",
  step3Title: "Tell us about yourself",
  step3Sub: "We only need these details to confirm your appointment.",
  step4Title: "Review your appointment",
  step4Sub: "Please check everything is correct before you confirm.",
  back: "\u2190 Back",
  nextDateTime: "Next: Choose Date & Time \u2192",
  nextDetails: "Next: Your Details \u2192",
  reviewAction: "Review Appointment \u2192",
  confirmLabel: "Confirm Appointment",
  requiredService: "Please choose a service.",
  closedDayShort: "Closed",
  otherServicePrompt: "Please describe the service you need"
};
var STYLE_ID = "mylikita-widget-styles";
function createBookingWidget(element, options = {}) {
  if (!element) throw new Error("createBookingWidget: a container element is required");
  const opts = {
    relayUrl: options.relayUrl,
    websiteKey: options.websiteKey,
    facilityId: options.facilityId,
    providers: options.providers || [],
    services: options.services || [],
    // Phase C2/C3: fetch the facility's mapped provider list from the relay
    // (GET /v1/providers) on mount and populate the doctor dropdown. The
    // static `providers` option, when given, always wins and skips the fetch.
    loadProviders: options.loadProviders === true && !(options.providers && options.providers.length),
    // Phase C4 service-registry load — mirrors loadProviders (hosted page and
    // embeds that opt in get real services + durations + doctor filtering).
    loadServices: options.loadServices === true ? true : options.loadServices === false ? false : options.loadProviders === true,
    // Confirmation screen context — clinic name + WhatsApp number (digits) let
    // the widget show "WhatsApp clinic" and an Add-to-calendar event name.
    clinicName: options.clinicName || null,
    whatsappNumber: options.whatsappNumber || null,
    // Booking SOURCE (Phase C7 analytics) — the campaign/channel this visitor
    // came from (?source=instagram etc.). Defaults to reading ?source= off the
    // page URL; hosts may override. Sent with the booking payload so the relay
    // can compute conversion by source.
    source: options.source != null && String(options.source) || readSourceFromUrl(),
    // Track a page view on mount (POST /v1/track) so conversion (bookings /
    // views) per source is meaningful. Defaults on for the hosted page/embed.
    trackView: options.trackView !== false,
    // White-label flag: premium hosts can drop the MyLikita brand header.
    // Defaults to true (brand shown); pass showBrand:false to hide it.
    showBrand: options.showBrand !== false,
    pollIntervalMs: options.pollIntervalMs ?? 5e3,
    maxTries: options.maxTries ?? 12,
    text: { ...DEFAULT_TEXT, ...options.text || {} },
    theme: options.theme || {},
    onStatus: typeof options.onStatus === "function" ? options.onStatus : null,
    onError: typeof options.onError === "function" ? options.onError : null,
    onBooking: typeof options.onBooking === "function" ? options.onBooking : null,
    externalRef: typeof options.externalRef === "function" ? options.externalRef : newExternalRef,
    // ANC-aware booking (P2, maternity roadmap 2.1): when a facility opts in,
    // the appointment-type dropdown gains an "Antenatal checkup" entry that
    // reveals an LMP date field. Choosing it submits booking_type 'anc' +
    // anc_lmp_date so the prime backend can register the pregnancy + WHO
    // visit schedule and GA-anchor the booked slot (see services/ancBooking.js).
    ancBooking: options.ancBooking === true
  };
  if (!opts.relayUrl || !opts.websiteKey || !opts.facilityId) {
    throw new Error("createBookingWidget: relayUrl, websiteKey and facilityId are required");
  }
  injectStyles();
  const t = opts.text;
  const root = element;
  root.classList.add("mylikita-widget");
  applyTheme(root, opts.theme);
  let alive = true;
  let submitting = false;
  let pollCtrl = null;
  let lastPayload = null;
  const instanceId = Math.random().toString(36).slice(2, 8);
  const refKey = `mylikita_ref_${opts.facilityId}_${instanceId}`;
  const brand = opts.showBrand ? createBrandHeader() : null;
  const form = el("form", { className: "mylikita-widget__form" });
  const title = el("h3", { className: "mylikita-widget__title", text: t.title });
  const subtitle = el("p", { className: "mylikita-widget__subtitle", text: t.subtitle });
  const errorBox = el("div", { className: "mylikita-widget__error", attrs: { role: "alert" } });
  const noAccountBadge = el("span", { className: "mylikita-widget__noaccount", text: t.noAccount });
  const name = fieldText("name", t.name, { required: true });
  const phoneEmail = el("div", { className: "mylikita-widget__row" });
  const phone = fieldText("phone", t.phone, { type: "tel", inputmode: "tel" });
  const email = fieldText("email", t.email, { type: "email" });
  phoneEmail.append(phone.wrap, email.wrap);
  const provider = fieldSelect("provider", t.provider, [
    { value: "", label: t.noPreference },
    ...opts.providers.map((p) => ({ value: p.external_id, label: p.label || p.name || p.external_id }))
  ]);
  let allProviders = [...opts.providers || []];
  function repopulateProviders(list) {
    const current = provider.input.value;
    provider.input.replaceChildren();
    const noPref = document.createElement("option");
    noPref.value = "";
    noPref.textContent = t.noPreference;
    provider.input.append(noPref);
    for (const p of list || []) {
      const opt = document.createElement("option");
      opt.value = p.external_id;
      opt.textContent = p.label || p.name || p.external_id;
      provider.input.append(opt);
    }
    if (current && [...provider.input.options].some((o) => o.value === current)) provider.input.value = current;
    else provider.input.value = "";
  }
  function setProviderList(list) {
    allProviders = list || [];
    opts.providers = allProviders;
    applyProviderFilter();
    refreshServiceList();
  }
  const serviceWrap = el("div", { className: "mylikita-widget__field" });
  let structuredServices = normalizeServices(opts.services);
  let selectedService = null;
  let service = { input: null, mode: "text", otherInput: null, otherWrap: null, datalist: null };
  function buildServiceControl(list) {
    serviceWrap.replaceChildren();
    const services = normalizeServices(list);
    structuredServices = services;
    selectedService = null;
    if (services.length) {
      const lab = el("label", { className: "mylikita-widget__label", attrs: { for: "mlw-service" } });
      lab.textContent = t.service;
      const select = el("select", { className: "mylikita-widget__select", attrs: { id: "mlw-service" } });
      const ph = document.createElement("option");
      ph.value = "";
      ph.textContent = t.selectService;
      select.append(ph);
      for (const s of services) {
        const o = document.createElement("option");
        o.value = s.external_id;
        o.textContent = s.duration_mins ? `${s.name} (${s.duration_mins} min)` : s.name;
        select.append(o);
      }
      const otherOpt = document.createElement("option");
      otherOpt.value = "__other__";
      otherOpt.textContent = t.otherService;
      select.append(otherOpt);
      serviceWrap.append(lab, select);
      const otherWrap = el("div", { className: "mylikita-widget__field", attrs: { hidden: true } });
      const otherLab = el("label", { className: "mylikita-widget__label", attrs: { for: "mlw-service-other" } });
      otherLab.textContent = t.otherServiceLabel;
      const otherInput = el("input", { className: "mylikita-widget__input", attrs: { id: "mlw-service-other", type: "text", placeholder: t.serviceOtherPlaceholder } });
      otherWrap.append(otherLab, otherInput);
      serviceWrap.append(otherWrap);
      service = { input: select, mode: "select", otherInput, otherWrap, datalist: null };
      const sync = () => {
        const val = select.value;
        const isOther = val === "__other__";
        otherWrap.hidden = !isOther;
        selectedService = null;
        if (val && !isOther) {
          selectedService = services.find((x) => x.external_id === val) || null;
        }
        applyProviderFilter();
      };
      select.addEventListener("change", sync);
      sync();
    } else {
      const lab = el("label", { className: "mylikita-widget__label", attrs: { for: "mlw-service" } });
      lab.textContent = t.service;
      const input = el("input", { className: "mylikita-widget__input", attrs: { id: "mlw-service", type: "text" } });
      const datalist = el("datalist", { attrs: { id: "mlw-service-list" } });
      input.setAttribute("list", "mlw-service-list");
      const hint2 = el("p", { className: "mylikita-widget__field-hint", text: t.serviceHint });
      serviceWrap.append(lab, input, datalist, hint2);
      service = { input, mode: "text", otherInput: null, otherWrap: null, datalist };
      refreshServiceList();
    }
  }
  buildServiceControl(structuredServices);
  service.wrap = serviceWrap;
  function refreshServiceList() {
    if (service.mode !== "text" || !service.datalist) return;
    const dl = service.datalist;
    const seen = /* @__PURE__ */ new Set();
    const add = (s) => {
      const v = String(s || "").trim();
      if (v && !seen.has(v)) {
        seen.add(v);
        const o = el("option", { attrs: { value: v } });
        dl.append(o);
      }
    };
    dl.replaceChildren();
    (opts.services || []).forEach(add);
    allProviders.forEach((p) => {
      add(p.specialty);
      add(p.label || p.name);
    });
  }
  function applyProviderFilter() {
    if (selectedService && Array.isArray(selectedService.provider_external_ids) && selectedService.provider_external_ids.length) {
      const set = new Set(selectedService.provider_external_ids);
      repopulateProviders(allProviders.filter((p) => set.has(p.external_id)));
    } else {
      repopulateProviders(allProviders);
    }
  }
  function setServiceList(list) {
    opts.services = list || [];
    buildServiceControl(opts.services);
    service.wrap = serviceWrap;
    if (service.input && typeof onServiceSlotReRender === "function") {
      service.input.addEventListener("change", onServiceSlotReRender);
    }
    applyProviderFilter();
  }
  function getServiceSelection() {
    if (service.mode === "select") {
      if (selectedService) return selectedService;
      if (service.input.value === "__other__") {
        const other = service.otherInput && service.otherInput.value.trim() || "";
        return other ? { external_id: null, name: other, duration_mins: null } : null;
      }
      return null;
    }
    const name2 = service.input && service.input.value.trim() || "";
    return name2 ? { external_id: null, name: name2, duration_mins: null } : null;
  }
  const datePick = fieldText("date", t.date, { type: "date", required: true });
  const nowRef = /* @__PURE__ */ new Date();
  datePick.input.min = toLocalDateValue(nowRef);
  const slotGroup = el("div", { className: "mylikita-widget__field mylikita-widget__slotfield" });
  const slotLab = el("label", { className: "mylikita-widget__label", text: t.slot });
  const slotChips = el("div", { className: "mylikita-widget__slots", attrs: { role: "group", "aria-label": t.slot } });
  const slotHint = el("p", { className: "mylikita-widget__slot-hint", text: t.selectDateHint });
  const waitlistBox = el("div", { className: "mylikita-widget__waitlist", attrs: { hidden: true } });
  const waitlistTitle = el("p", { className: "mylikita-widget__waitlist-title", text: t.waitlistTitle });
  const waitlistHint = el("p", { className: "mylikita-widget__waitlist-hint", text: t.waitlistHint });
  const waitlistBtn = el("button", { type: "button", className: "mylikita-widget__waitlist-btn", text: t.waitlistSubmit });
  waitlistBox.append(waitlistTitle, waitlistHint, waitlistBtn);
  slotGroup.append(slotLab, slotChips, slotHint, waitlistBox);
  const datetime = fieldText("datetime", "", { type: "hidden", required: true });
  datetime.wrap.hidden = true;
  datetime.input.value = "";
  let availCtrl = null;
  function cancelAvailability() {
    if (availCtrl) {
      availCtrl.abort();
      availCtrl = null;
    }
  }
  function renderWaitlist(show) {
    waitlistBox.hidden = !show;
  }
  async function renderSlots() {
    const dateVal = datePick.input.value;
    if (!dateVal) {
      cancelAvailability();
      slotChips.replaceChildren();
      slotHint.textContent = t.selectDateHint;
      renderWaitlist(false);
      return;
    }
    const { closed, slots } = buildSlotsForDate(dateVal, opts.operatingHours || null, nowRef);
    slotChips.replaceChildren();
    if (closed) {
      slotHint.textContent = t.closedDay;
      renderWaitlist(false);
      return;
    }
    if (!slots.length) {
      slotHint.textContent = t.noSlots;
      renderWaitlist(false);
      return;
    }
    cancelAvailability();
    availCtrl = new AbortController();
    const signal = availCtrl.signal;
    slotHint.textContent = t.checkingAvailability;
    let booked = [];
    try {
      booked = await fetchAvailability({
        relayUrl: opts.relayUrl,
        websiteKey: opts.websiteKey,
        date: dateVal,
        signal
      });
    } catch (err) {
      if (!alive || signal.aborted) return;
    }
    if (!alive || signal.aborted) return;
    const slotDur = selectedService && selectedService.duration_mins || opts.durationMins || 30;
    slotChips.replaceChildren();
    let freeCount = 0;
    for (const time of slots) {
      const taken = overlapsBooked(time, slotDur, booked);
      if (taken) {
        const chip = el("button", {
          type: "button",
          className: "mylikita-widget__slot mylikita-widget__slot-taken",
          attrs: { disabled: "", title: t.slotTakenLabel }
        });
        chip.textContent = time;
        slotChips.append(chip);
      } else {
        freeCount += 1;
        const chip = el("button", { type: "button", className: "mylikita-widget__slot", text: time });
        chip.addEventListener("click", () => {
          slotChips.querySelectorAll(".mylikita-widget__slot:not(:disabled)").forEach((c) => c.classList.remove("selected"));
          chip.classList.add("selected");
          datetime.input.value = `${dateVal}T${time}`;
        });
        slotChips.append(chip);
      }
    }
    if (freeCount === 0) {
      slotHint.textContent = t.noFreeSlots;
      renderWaitlist(true);
    } else {
      slotHint.textContent = booked.length ? t.slotLegend : "";
      renderWaitlist(false);
    }
  }
  datePick.input.addEventListener("change", () => {
    datetime.input.value = "";
    slotChips.querySelectorAll(".mylikita-widget__slot").forEach((c) => c.classList.remove("selected"));
    renderSlots();
  });
  const onServiceSlotReRender = () => {
    if (datePick.input.value) renderSlots();
  };
  if (service.input) service.input.addEventListener("change", onServiceSlotReRender);
  const visitTypeOptions = [
    { value: "physical", label: t.visitPhysical },
    { value: "telemedicine", label: t.visitTelemedicine },
    { value: "home_visit", label: t.visitHome }
  ];
  if (opts.ancBooking) visitTypeOptions.push({ value: "antenatal", label: t.visitAntenatal });
  const visitType = fieldSelect("visitType", t.visitType, visitTypeOptions);
  const notes = fieldText("notes", t.notes, { type: "textarea", maxlength: 500 });
  let ancLmp = null;
  let ancGroup = null;
  let syncAncVisibility = null;
  if (opts.ancBooking) {
    ancLmp = fieldText("ancLmp", t.ancLmp, { type: "date" });
    const ancNote = el("p", { className: "mylikita-widget__anc-note", text: t.ancLmpHint });
    ancGroup = el("div", { className: "mylikita-widget__anc", attrs: { hidden: true } });
    ancGroup.append(ancLmp.wrap, ancNote);
    const isAntenatal = () => visitType.input.value === "antenatal";
    syncAncVisibility = () => {
      ancGroup.hidden = !isAntenatal();
      ancLmp.input.max = toLocalDateValue(/* @__PURE__ */ new Date());
    };
    visitType.input.addEventListener("change", syncAncVisibility);
    syncAncVisibility();
  }
  const submitBtn = el("button", { className: "mylikita-widget__submit", type: "submit", text: t.submit });
  const submitRow = el("div");
  submitRow.append(submitBtn);
  const hint = el("p", { className: "mylikita-widget__hint" });
  const stepDefs = [
    { key: "service", label: t.stepService },
    { key: "datetime", label: t.stepDateTime },
    { key: "details", label: t.stepDetails },
    { key: "review", label: t.stepReview }
  ];
  const progressBar = el("ol", { className: "mylikita-widget__progress", attrs: { "aria-label": t.progressLabel } });
  const progressItems = stepDefs.map((d, i) => {
    const li = el("li", { className: "mylikita-widget__progress-item" });
    li.append(
      el("span", { className: "mylikita-widget__progress-dot", text: String(i + 1) }),
      el("span", { className: "mylikita-widget__progress-label", text: d.label })
    );
    progressBar.append(li);
    return li;
  });
  const stepService = el("div", { className: "mylikita-widget__step", attrs: { "data-step": "1" } });
  const stepDateTime = el("div", { className: "mylikita-widget__step", attrs: { "data-step": "2" }, hidden: true });
  const stepDetails = el("div", { className: "mylikita-widget__step", attrs: { "data-step": "3" }, hidden: true });
  const stepReview = el("div", { className: "mylikita-widget__step", attrs: { "data-step": "4" }, hidden: true });
  const stepNodes = [stepService, stepDateTime, stepDetails, stepReview];
  let currentStep = 1;
  stepService.append(
    el("h4", { className: "mylikita-widget__step-title", text: t.step1Title }),
    el("p", { className: "mylikita-widget__step-sub", text: t.step1Sub }),
    service.wrap,
    provider.wrap
  );
  const step1Actions = el("div", { className: "mylikita-widget__step-actions" });
  const next1 = el("button", { type: "button", className: "mylikita-widget__cta", text: t.nextDateTime });
  next1.addEventListener("click", () => {
    if (validateStep1()) showStep(2);
  });
  step1Actions.append(next1);
  stepService.append(step1Actions);
  stepDateTime.append(
    el("h4", { className: "mylikita-widget__step-title", text: t.step2Title }),
    el("p", { className: "mylikita-widget__step-sub", text: t.step2Sub })
  );
  const dateCardsWrap = el("div", { className: "mylikita-widget__dates" });
  let dateCards = [];
  const ohDays = Array.isArray(opts.operatingHours && opts.operatingHours.working_days) && opts.operatingHours.working_days.length ? opts.operatingHours.working_days : [1, 2, 3, 4, 5, 6];
  function renderDateCards() {
    dateCardsWrap.replaceChildren();
    dateCards = [];
    const horizon = opts.dateHorizonDays || 14;
    const now = /* @__PURE__ */ new Date();
    for (let i = 0; i < horizon; i++) {
      const d = new Date(now);
      d.setDate(now.getDate() + i);
      const ds = toLocalDateValue(d);
      const closed = !ohDays.includes(d.getDay());
      const card = el("button", {
        type: "button",
        className: "mylikita-widget__date-card" + (closed ? " closed" : ""),
        attrs: {
          "data-date": ds,
          title: closed ? t.closedDayShort : "",
          ...closed ? { disabled: "", "aria-disabled": "true" } : {}
        }
      });
      card.append(
        el("span", { className: "mylikita-widget__date-week", text: d.toLocaleDateString(void 0, { weekday: "short" }) }),
        el("span", { className: "mylikita-widget__date-day", text: String(d.getDate()) }),
        el("span", { className: "mylikita-widget__date-month", text: d.toLocaleDateString(void 0, { month: "short" }) })
      );
      if (!closed) {
        card.addEventListener("click", () => {
          dateCards.forEach((c) => c.classList.toggle("selected", c === card));
          datePick.input.value = ds;
          datetime.input.value = "";
          slotChips.querySelectorAll(".mylikita-widget__slot").forEach((c) => c.classList.remove("selected"));
          renderSlots();
        });
      }
      dateCardsWrap.append(card);
      dateCards.push(card);
    }
  }
  renderDateCards();
  datePick.wrap.hidden = true;
  stepDateTime.append(dateCardsWrap, slotGroup);
  const step2Actions = el("div", { className: "mylikita-widget__step-actions" });
  const back2 = el("button", { type: "button", className: "mylikita-widget__cta mylikita-widget__cta-ghost", text: t.back });
  back2.addEventListener("click", () => showStep(1));
  const next2 = el("button", { type: "button", className: "mylikita-widget__cta", text: t.nextDetails });
  next2.addEventListener("click", () => {
    if (validateStep2()) showStep(3);
  });
  step2Actions.append(back2, next2);
  stepDateTime.append(step2Actions);
  stepDetails.append(
    el("h4", { className: "mylikita-widget__step-title", text: t.step3Title }),
    el("p", { className: "mylikita-widget__step-sub", text: t.step3Sub }),
    name.wrap,
    phoneEmail,
    visitType.wrap
  );
  if (ancGroup) stepDetails.append(ancGroup);
  stepDetails.append(notes.wrap);
  const step3Actions = el("div", { className: "mylikita-widget__step-actions" });
  const back3 = el("button", { type: "button", className: "mylikita-widget__cta mylikita-widget__cta-ghost", text: t.back });
  back3.addEventListener("click", () => showStep(2));
  const next3 = el("button", { type: "button", className: "mylikita-widget__cta", text: t.reviewAction });
  next3.addEventListener("click", () => {
    if (validateStep3()) showStep(4);
  });
  step3Actions.append(back3, next3);
  stepDetails.append(step3Actions);
  const reviewCard = el("div", { className: "mylikita-widget__review" });
  stepReview.append(
    el("h4", { className: "mylikita-widget__step-title", text: t.step4Title }),
    el("p", { className: "mylikita-widget__step-sub", text: t.step4Sub }),
    reviewCard
  );
  const step4Actions = el("div", { className: "mylikita-widget__step-actions" });
  const back4 = el("button", { type: "button", className: "mylikita-widget__cta mylikita-widget__cta-ghost", text: t.back });
  back4.addEventListener("click", () => showStep(3));
  const confirmBtn = el("button", { type: "submit", className: "mylikita-widget__cta", text: t.confirmLabel });
  step4Actions.append(back4, confirmBtn);
  stepReview.append(step4Actions);
  function refreshReview() {
    reviewCard.replaceChildren();
    const sel = getServiceSelection();
    const rows = [
      { k: t.confirmService, v: sel ? sel.name || t.otherService : "\u2014" },
      {
        k: t.confirmDoctor,
        v: provider.input.value ? (allProviders.find((p) => p.external_id === provider.input.value) || {}).name || provider.input.value : t.noPreference
      },
      { k: t.confirmVisit, v: visitTypeLabel(visitType.input.value) }
    ];
    const dt = datetime.input.value;
    if (dt) rows.push({ k: t.confirmWhen, v: formatApptDateTime(dt) });
    else if (datePick.input.value) rows.push({ k: t.confirmWhen, v: datePick.input.value });
    for (const r of rows) {
      const row = el("div", { className: "mylikita-widget__review-row" });
      row.append(el("span", { className: "mylikita-widget__review-k", text: r.k }), el("span", { className: "mylikita-widget__review-v", text: r.v }));
      reviewCard.append(row);
    }
    const yours = el("div", { className: "mylikita-widget__review-yours" });
    const yHead = el("div", { className: "mylikita-widget__review-head", text: t.step3Title });
    const yLine = el("div", { className: "mylikita-widget__review-line" });
    yLine.textContent = [name.input.value.trim(), phone.input.value.trim(), email.input.value.trim()].filter(Boolean).join(" \xB7 ") || "\u2014";
    yours.append(yHead, yLine);
    reviewCard.append(yours);
  }
  function showStep(n) {
    currentStep = n;
    stepNodes.forEach((s, i) => {
      s.hidden = i + 1 !== n;
    });
    progressItems.forEach((li, i) => {
      const done = i + 1 < n;
      const active = i + 1 === n;
      li.classList.toggle("done", done);
      li.classList.toggle("active", active);
      li.querySelector(".mylikita-widget__progress-dot").textContent = done ? "\u2713" : String(i + 1);
    });
    if (n === 4) refreshReview();
  }
  function validateStep1() {
    const sel = getServiceSelection();
    if (!sel || !sel.name) {
      setError(t.requiredService);
      return false;
    }
    setError(null);
    return true;
  }
  function validateStep2() {
    if (!datetime.input.value) {
      setError(t.requiredSlot);
      return false;
    }
    setError(null);
    return true;
  }
  function validateStep3() {
    if (!name.input.value.trim()) {
      setError(t.requiredName);
      return false;
    }
    const p = normalizePhone(phone.input.value);
    if (!p) {
      setError(t.requiredPhone);
      return false;
    }
    if (!isValidPhone(p)) {
      setError(t.invalidPhone);
      return false;
    }
    setError(null);
    return true;
  }
  form.replaceChildren(noAccountBadge, errorBox, progressBar, stepService, stepDateTime, stepDetails, stepReview, hint, datetime.wrap);
  submitRow.hidden = true;
  showStep(1);
  waitlistBtn.addEventListener("click", async () => {
    if (submitting) return;
    const pname = name.input.value.trim();
    const pphone = phone.input.value.trim();
    const pemail = email.input.value.trim();
    if (!pname) return fail(t.requiredName);
    const norm = normalizePhone(pphone);
    if (!norm) return fail(t.requiredPhone);
    if (!isValidPhone(norm)) return fail(t.invalidPhone);
    if (!datePick.input.value) return fail(t.requiredSlot);
    const sel = getServiceSelection();
    submitting = true;
    waitlistBtn.disabled = true;
    waitlistBtn.textContent = t.submitting;
    try {
      const ref = readStoredRef(refKey) || opts.externalRef();
      try {
        sessionStorage.setItem(refKey, ref);
      } catch (_) {
      }
      await createWaitlist({
        relayUrl: opts.relayUrl,
        websiteKey: opts.websiteKey,
        signal: pollCtrl?.signal,
        payload: {
          external_ref: ref,
          patient_name: pname,
          patient_phone: norm,
          patient_email: pemail || void 0,
          service_external_id: sel && sel.external_id || void 0,
          service_name: sel && sel.name || void 0,
          preferred_date: datePick.input.value,
          flexibility: "any_day",
          notes: notes.input.value.trim() || void 0
        }
      });
      waitlistTitle.textContent = t.waitlistSubmitted;
      waitlistHint.textContent = t.waitlistSubmittedMsg;
      waitlistBtn.hidden = true;
    } catch (err) {
      if (!alive) return;
      if (opts.onError) safeCall(opts.onError, err);
      const friendly = err.status === 429 ? t.rateLimited : err.message || t.networkError;
      fail(friendly);
      waitlistBtn.disabled = false;
      waitlistBtn.textContent = t.waitlistSubmit;
    } finally {
      submitting = false;
    }
  });
  const statusView = el("div", { className: "mylikita-widget__status", attrs: { "aria-live": "polite" }, hidden: true });
  form.addEventListener("submit", (e) => {
    e.preventDefault();
    if (submitting) return;
    submit();
  });
  async function submit() {
    submitting = true;
    setError(null);
    submitBtn.disabled = true;
    submitBtn.textContent = t.submitting;
    const sel = getServiceSelection();
    const payload = {
      facility_id: opts.facilityId,
      patient_name: name.input.value.trim(),
      patient_phone: phone.input.value.trim(),
      patient_email: email.input.value.trim(),
      provider_external_id: provider.input.value || void 0,
      service_name: sel && sel.name || void 0,
      // Phase C4 — a structured service id lets the hospital resolve the
      // service by code instead of free-text name.
      service_external_id: sel && sel.external_id || void 0,
      appt_datetime: datetime.input.value,
      visit_type: visitType.input.value || "physical",
      duration_mins: sel && sel.duration_mins || opts.durationMins || void 0,
      notes: notes.input.value.trim() || void 0,
      // Phase C7 — campaign/channel source (only when a valid tag is set).
      source: opts.source || void 0
    };
    if (payload.visit_type === "antenatal") {
      const lmp = ancLmp.input.value.trim();
      if (!lmp) return fail(t.ancRequiredLmp);
      if (Number.isNaN(Date.parse(`${lmp}T00:00:00Z`))) return fail(t.ancRequiredLmp);
      payload.booking_type = "anc";
      payload.anc_lmp_date = lmp;
    }
    if (!payload.patient_name) return fail(t.requiredName);
    const normalizedPhone = normalizePhone(payload.patient_phone);
    if (!normalizedPhone) return fail(t.requiredPhone);
    if (!isValidPhone(normalizedPhone)) return fail(t.invalidPhone);
    payload.patient_phone = normalizedPhone;
    if (!payload.appt_datetime || Number.isNaN(Date.parse(payload.appt_datetime))) return fail(t.requiredSlot);
    let external_ref = readStoredRef(refKey);
    if (!external_ref) {
      external_ref = opts.externalRef();
      try {
        sessionStorage.setItem(refKey, external_ref);
      } catch (_) {
      }
    }
    payload.external_ref = external_ref;
    lastPayload = payload;
    pollCtrl = new AbortController();
    let bookingRef = null;
    try {
      const created = await createBooking({ relayUrl: opts.relayUrl, websiteKey: opts.websiteKey, payload, signal: pollCtrl.signal });
      bookingRef = created.booking_ref;
      if (created.duplicate) {
        hint.textContent = "";
        showStatus("pending_confirmation", bookingRef, "We found an existing booking request for this slot \u2014 checking it\u2026");
      } else {
        if (opts.onBooking) safeCall(opts.onBooking, created, payload);
        showStatus("pending_confirmation", bookingRef, null);
      }
      startPoll(bookingRef);
    } catch (err) {
      if (!alive || err?.name === "AbortError") return;
      const friendly = err.status === 429 ? t.rateLimited : err.code === "slot_unavailable" ? t.slotTaken : err.message || t.networkError;
      if (opts.onError) safeCall(opts.onError, err);
      fail(friendly);
    }
  }
  async function startPoll(bookingRef) {
    if (!bookingRef) {
      submitting = false;
      return;
    }
    let result;
    try {
      result = await pollStatus(
        () => fetchStatus({ relayUrl: opts.relayUrl, websiteKey: opts.websiteKey, bookingRef, signal: pollCtrl.signal }),
        { intervalMs: opts.pollIntervalMs, maxTries: opts.maxTries, signal: pollCtrl.signal }
      );
    } catch (err) {
      if (!alive || err?.name === "AbortError") return;
      if (opts.onError) safeCall(opts.onError, err);
      renderStatus("poll_error", bookingRef, err.message || t.networkError);
      submitting = false;
      return;
    }
    if (!alive || result.status === "aborted") return;
    if (opts.onStatus && result.data) safeCall(opts.onStatus, result.data);
    if (result.resolved) {
      try {
        sessionStorage.removeItem(refKey);
      } catch (_) {
      }
      renderStatus(result.status, bookingRef);
    } else {
      renderStatus("pending_confirmation", bookingRef);
    }
    submitting = false;
  }
  function showStatus(status, bookingRef, messageOverride) {
    form.hidden = true;
    title.hidden = true;
    subtitle.hidden = true;
    statusView.hidden = false;
    renderStatus(status, bookingRef, messageOverride);
  }
  function renderStatus(status, bookingRef, messageOverride) {
    const c = statusCopy(status);
    const bar = el("div", { className: "mylikita-widget__status-bar" });
    const icon = el("div", { className: `mylikita-widget__status-icon ${c.kind}` });
    icon.textContent = iconGlyph(c.kind);
    const st = el("p", { className: "mylikita-widget__status-title", text: c.title });
    const msg = el("p", { className: "mylikita-widget__status-message", text: messageOverride || c.message });
    const ref = el("p", { className: "mylikita-widget__status-ref", text: bookingRef ? `Booking ref: ${bookingRef}` : "" });
    const nodes = [bar, icon, st, msg, ref];
    if (lastPayload && (status === "pending_confirmation" || status === "confirmed")) {
      const summary = buildSummaryCard(lastPayload);
      if (summary) nodes.push(summary);
      const actions = buildConfirmationActions(lastPayload, status === "confirmed", bookingRef);
      if (actions) nodes.push(actions);
    }
    const again = el("button", { className: "mylikita-widget__link-btn", type: "button", text: t.bookAnother });
    again.addEventListener("click", () => reset());
    nodes.push(again);
    statusView.replaceChildren(...nodes);
  }
  function buildSummaryCard(payload) {
    const rows = [
      { k: t.confirmWhen, v: formatApptDateTime(payload.appt_datetime) },
      { k: t.confirmService, v: payload.service_name || t.general },
      { k: t.confirmDoctor, v: providerLabelFor(payload.provider_external_id) },
      { k: t.confirmVisit, v: visitTypeLabel(payload.visit_type) }
    ].filter((r) => r.v);
    if (!rows.length) return null;
    const card = el("div", { className: "mylikita-widget__confirm" });
    for (const r of rows) {
      const row = el("div", { className: "mylikita-widget__confirm-row" });
      const k = el("div", { className: "mylikita-widget__confirm-k", text: r.k });
      const v = el("div", { className: "mylikita-widget__confirm-v", text: r.v });
      row.append(k, v);
      card.append(row);
    }
    return card;
  }
  function buildConfirmationActions(payload, confirmed, bookingRef) {
    const wrap = el("div", { className: "mylikita-widget__confirm-actions" });
    const cal = el("button", { type: "button", className: "mylikita-widget__act", text: t.addToCalendar });
    cal.addEventListener("click", () => downloadIcs(payload, bookingRef, cal, t));
    wrap.append(cal);
    const waNum = waNumber(opts.whatsappNumber);
    if (waNum) {
      const wa = el("a", {
        className: "mylikita-widget__act mylikita-widget__act-wa",
        attrs: { href: waClinicLink(waNum, payload, bookingRef, opts.clinicName), target: "_blank", rel: "noopener" },
        text: t.whatsappClinic
      });
      wrap.append(wa);
    }
    return wrap;
  }
  function providerLabelFor(ext) {
    if (!ext) return null;
    const p = allProviders.find((x) => x.external_id === ext);
    return p && (p.name || p.label) || ext;
  }
  function visitTypeLabel(type) {
    if (type === "telemedicine") return t.visitTelemedicine;
    if (type === "home_visit") return t.visitHome;
    if (type === "antenatal") return t.visitAntenatal;
    return t.visitPhysical;
  }
  function downloadIcs(payload, bookingRef, btn, txt) {
    try {
      const title2 = [opts.clinicName, payload.service_name].filter(Boolean).join(" \u2014 ") || txt.title;
      const dur = Number.isFinite(Number(payload.duration_mins)) ? Number(payload.duration_mins) : 30;
      const ics = buildIcs(payload.appt_datetime, dur, title2, payload.notes);
      const blob = new Blob([ics], { type: "text/calendar;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = bookingRef ? `appointment-${bookingRef}.ics` : "appointment.ics";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      setTimeout(() => URL.revokeObjectURL(url), 3e3);
      const original = btn.textContent;
      btn.textContent = txt.calAdded;
      setTimeout(() => {
        btn.textContent = original;
      }, 2200);
    } catch (_) {
    }
  }
  function fail(message) {
    submitting = false;
    submitBtn.disabled = false;
    submitBtn.textContent = t.submit;
    setError(message);
  }
  function setError(message) {
    errorBox.textContent = message || "";
    errorBox.classList.toggle("visible", Boolean(message));
  }
  function reset() {
    try {
      sessionStorage.removeItem(`mylikita_ref_${opts.facilityId}`);
    } catch (_) {
    }
    form.reset();
    setError(null);
    statusView.replaceChildren();
    statusView.hidden = true;
    form.hidden = false;
    title.hidden = false;
    subtitle.hidden = false;
    hint.textContent = "";
    submitting = false;
    submitBtn.disabled = false;
    submitBtn.textContent = t.submit;
    datePick.input.value = "";
    datePick.input.min = toLocalDateValue(/* @__PURE__ */ new Date());
    datetime.input.value = "";
    slotChips.replaceChildren();
    slotHint.textContent = t.selectDateHint;
    renderWaitlist(false);
    waitlistTitle.textContent = t.waitlistTitle;
    waitlistHint.textContent = t.waitlistHint;
    waitlistBtn.hidden = false;
    waitlistBtn.disabled = false;
    waitlistBtn.textContent = t.waitlistSubmit;
    visitType.input.value = visitTypeOptions[0].value;
    if (ancLmp) ancLmp.input.value = "";
    if (syncAncVisibility) syncAncVisibility();
    if (service && service.input && service.input.value) service.input.value = "";
    selectedService = null;
    if (service && service.mode === "select" && service.otherInput) {
      service.otherInput.value = "";
      if (service.otherWrap) service.otherWrap.hidden = true;
    }
    if (provider && provider.input) provider.input.value = "";
    if (typeof renderDateCards === "function") renderDateCards();
    if (typeof showStep === "function") showStep(1);
  }
  root.replaceChildren(brand, title, subtitle, form, statusView);
  let destroyProvidersFetch = null;
  if (opts.trackView) {
    trackPageView({
      relayUrl: opts.relayUrl,
      websiteKey: opts.websiteKey,
      source: opts.source || null
    });
  }
  if (opts.loadProviders) {
    const provCtrl = new AbortController();
    (async () => {
      try {
        const list = await fetchProviders({
          relayUrl: opts.relayUrl,
          websiteKey: opts.websiteKey,
          signal: provCtrl.signal
        });
        if (alive && !provCtrl.signal.aborted) setProviderList(list);
      } catch (err) {
        if (!alive || err?.name === "AbortError") return;
        if (opts.onError) safeCall(opts.onError, err);
      }
    })();
    destroyProvidersFetch = () => provCtrl.abort();
  }
  if (opts.loadServices) {
    const svcCtrl = new AbortController();
    (async () => {
      try {
        const list = await fetchServices({
          relayUrl: opts.relayUrl,
          websiteKey: opts.websiteKey,
          signal: svcCtrl.signal
        });
        if (alive && !svcCtrl.signal.aborted) setServiceList(list);
      } catch (err) {
        if (!alive || err?.name === "AbortError") return;
        if (opts.onError) safeCall(opts.onError, err);
      }
    })();
    const abort = () => svcCtrl.abort();
    if (destroyProvidersFetch) {
      const prev = destroyProvidersFetch;
      destroyProvidersFetch = () => {
        prev();
        abort();
      };
    } else destroyProvidersFetch = abort;
  }
  return {
    destroy() {
      alive = false;
      if (pollCtrl) pollCtrl.abort();
      if (destroyProvidersFetch) destroyProvidersFetch();
      cancelAvailability();
      root.replaceChildren();
      root.classList.remove("mylikita-widget");
    },
    reset,
    getForm() {
      return { name: name.input.value, phone: phone.input.value, email: email.input.value };
    }
  };
}
function fieldText(name, label, { type = "text", required = false, maxlength, inputmode } = {}) {
  const wrap = el("div", { className: "mylikita-widget__field" });
  const lab = el("label", { className: "mylikita-widget__label", attrs: { for: `mlw-${name}` } });
  lab.append(document.createTextNode(label));
  if (required) lab.append(el("span", { className: "req", text: " *" }));
  let input;
  if (type === "textarea") {
    input = el("textarea", { className: "mylikita-widget__textarea", attrs: { id: `mlw-${name}`, rows: 3, maxlength: maxlength || "" } });
  } else {
    input = el("input", { className: "mylikita-widget__input", attrs: { id: `mlw-${name}`, type, inputmode: inputmode || "" } });
  }
  if (required) input.setAttribute("required", "");
  wrap.append(lab, input);
  return { wrap, input };
}
function fieldSelect(name, label, options) {
  const wrap = el("div", { className: "mylikita-widget__field" });
  const lab = el("label", { className: "mylikita-widget__label", attrs: { for: `mlw-${name}` } });
  lab.textContent = label;
  const select = el("select", { className: "mylikita-widget__select", attrs: { id: `mlw-${name}` } });
  for (const o of options) {
    const opt = el("option", { text: o.label });
    opt.value = o.value;
    select.append(opt);
  }
  wrap.append(lab, select);
  return { wrap, input: select };
}
function el(tag, { className, text, attrs = {} } = {}) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== void 0) node.textContent = text;
  for (const [k, v] of Object.entries(attrs)) {
    if (v === void 0 || v === "") continue;
    node.setAttribute(k, v);
  }
  return node;
}
function iconGlyph(kind) {
  return kind === "success" ? "\u2713" : kind === "danger" ? "!" : "\u2026";
}
function readSourceFromUrl() {
  try {
    const v = new URLSearchParams(window.location.search).get("source");
    return v && /^[a-zA-Z0-9_-]{1,40}$/.test(String(v)) ? String(v).toLowerCase() : null;
  } catch (_) {
    return null;
  }
}
function readStoredRef(key) {
  try {
    return sessionStorage.getItem(key) || null;
  } catch (_) {
    return null;
  }
}
function safeCall(fn, ...args) {
  try {
    fn(...args);
  } catch (_) {
  }
}
function toLocalDateValue(date) {
  const pad = (n) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}
function buildSlotsForDate(dateStr, oh, now) {
  const workingDays = Array.isArray(oh && oh.working_days) && oh.working_days.length ? oh.working_days : [1, 2, 3, 4, 5, 6];
  const day = (/* @__PURE__ */ new Date(`${dateStr}T00:00:00`)).getDay();
  if (!workingDays.includes(day)) return { closed: true, slots: [] };
  const open = parseHM(oh && oh.open_time || "09:00") || { h: 9, m: 0 };
  const close = parseHM(oh && oh.close_time || "17:00") || { h: 17, m: 0 };
  const dur = Math.max(15, parseInt(oh && oh.slot_duration, 10) || 30);
  const isToday = toLocalDateValue(now) === dateStr;
  const nowMin = now.getHours() * 60 + now.getMinutes();
  const slots = [];
  let t = open.h * 60 + open.m;
  const end = close.h * 60 + close.m;
  while (t + dur <= end) {
    if (!isToday || t > nowMin) slots.push(formatHM(t));
    t += dur;
  }
  return { closed: false, slots };
}
function parseHM(v) {
  const m = /^(\d{1,2}):(\d{2})$/.exec(String(v || "").trim());
  if (!m) return null;
  const h = parseInt(m[1], 10);
  const mn = parseInt(m[2], 10);
  if (h > 23 || mn > 59) return null;
  return { h, m: mn };
}
function formatHM(minutesOfDay) {
  const pad = (n) => String(n).padStart(2, "0");
  return `${pad(Math.floor(minutesOfDay / 60))}:${pad(minutesOfDay % 60)}`;
}
function formatApptDateTime(localStr) {
  if (!localStr) return "";
  const [date, time] = String(localStr).split("T");
  const ymd = String(date).split("-");
  if (ymd.length !== 3) return localStr;
  const d = new Date(Number(ymd[0]), Number(ymd[1]) - 1, Number(ymd[2]));
  const dateLabel = Number.isNaN(d.getTime()) ? date : d.toLocaleDateString(void 0, { weekday: "short", day: "numeric", month: "short", year: "numeric" });
  let timeLabel = time || "";
  const m = /^(\d{1,2}):(\d{2})/.exec(String(time));
  if (m) {
    let h = parseInt(m[1], 10);
    const mn = parseInt(m[2], 10);
    const ap = h >= 12 ? "PM" : "AM";
    h = h % 12 || 12;
    timeLabel = `${h}:${String(mn).padStart(2, "0")} ${ap}`;
  }
  return `${dateLabel} \xB7 ${timeLabel}`;
}
function buildIcs(localStart, durMin, summary, notes) {
  const toIso = (v) => String(v).replace(/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}).*/, "$1$2$3T$4$5");
  const start = toIso(localStart);
  const end = toIso(addMinutesLocal(localStart, durMin));
  const nowIso = (/* @__PURE__ */ new Date()).toISOString().replace(/(-|:|\.\d{3})/g, "").slice(0, 15);
  const uid = `mylikita-${Date.now()}@mylikita`;
  return [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//MyLikita//Booking//EN",
    "CALSCALE:GREGORIAN",
    "BEGIN:VEVENT",
    `UID:${uid}`,
    `DTSTAMP:${nowIso}`,
    `DTSTART:${start}`,
    `DTEND:${end}`,
    `SUMMARY:${escapeIcs(summary || "Appointment")}`,
    notes ? `DESCRIPTION:${escapeIcs(notes)}` : "DESCRIPTION:",
    "END:VEVENT",
    "END:VCALENDAR"
  ].join("\r\n");
}
function addMinutesLocal(localStr, mins) {
  const m = /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/.exec(String(localStr));
  if (!m) return localStr;
  const d = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]), Number(m[4]), Number(m[5]));
  d.setMinutes(d.getMinutes() + (Number.isFinite(Number(mins)) ? Number(mins) : 30));
  const pad = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}
function escapeIcs(s) {
  return String(s || "").replace(/\\/g, "\\\\").replace(/;/g, "\\;").replace(/,/g, "\\,").replace(/\r?\n/g, "\\n");
}
function waNumber(raw) {
  let d = String(raw || "").replace(/\D/g, "");
  if (d.startsWith("0")) d = "234" + d.slice(1);
  return d;
}
function waClinicLink(num, payload, bookingRef, clinicName) {
  const lines = [];
  if (clinicName) lines.push(clinicName);
  if (bookingRef) lines.push(`Booking ref: ${bookingRef}`);
  const when = formatApptDateTime(payload && payload.appt_datetime);
  if (when) lines.push(when);
  if (payload && payload.service_name) lines.push(payload.service_name);
  const text = lines.filter(Boolean).join("\n");
  return `https://wa.me/${num}?text=${encodeURIComponent(text)}`;
}
function overlapsBooked(time, durMin, booked) {
  const start = toMinutesOfDay(time);
  const dur = Number.isFinite(Number(durMin)) ? Number(durMin) : 30;
  if (Number.isNaN(start)) return false;
  const end = start + dur;
  for (const b of booked || []) {
    const bs = toMinutesOfDay(b.start);
    const be = toMinutesOfDay(b.end);
    if (Number.isNaN(bs) || Number.isNaN(be)) continue;
    if (start < be && end > bs) return true;
  }
  return false;
}
function toMinutesOfDay(hm) {
  const m = /^(\d{1,2}):(\d{2})$/.exec(String(hm || ""));
  return m ? parseInt(m[1], 10) * 60 + parseInt(m[2], 10) : NaN;
}
function normalizePhone(raw) {
  let p = String(raw || "").trim().replace(/[^0-9+]/g, "");
  if (!p) return "";
  if (p.startsWith("+")) return p;
  if (p.startsWith("234") && p.length >= 12) return `+${p}`;
  if (p.length === 11 && p.startsWith("0")) return `+234${p.slice(1)}`;
  if (p.length === 10 && /^[789]/.test(p)) return `+234${p}`;
  return p;
}
function isValidPhone(phone) {
  return /^\+\d{8,15}$/.test(String(phone || ""));
}
function normalizeServices(list) {
  return (Array.isArray(list) ? list : []).map((s) => {
    if (typeof s === "string") {
      const v = s.trim();
      return v ? { external_id: v, name: v, duration_mins: null, provider_external_ids: [] } : null;
    }
    if (!s || typeof s !== "object") return null;
    const ext = String(s.external_id || s.code || s.name || "").trim();
    const name = String(s.name || ext || "").trim();
    if (!ext || !name) return null;
    return {
      external_id: ext,
      name,
      duration_mins: Number.isFinite(Number(s.duration_mins)) ? Number(s.duration_mins) : null,
      provider_external_ids: Array.isArray(s.provider_external_ids) ? s.provider_external_ids : []
    };
  }).filter(Boolean);
}
function injectStyles() {
  if (document.getElementById(STYLE_ID)) return;
  const style = document.createElement("style");
  style.id = STYLE_ID;
  style.textContent = STYLES;
  document.head.appendChild(style);
}
function applyTheme(rootNode, theme) {
  for (const [k, v] of Object.entries(resolveTheme(theme))) {
    rootNode.style.setProperty(k, v);
  }
}
