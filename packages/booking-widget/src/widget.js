/**
 * DOM layer of the booking widget. Renders a self-contained booking form,
 * submits through the relay client, and swaps to a status view that polls the
 * booking until it resolves (or the poll budget runs out). All text is
 * i18n-overridable via `options.text`; all colours via `options.theme` or the
 * CSS variables (see theme.js).
 *
 * Imported from index.js — not meant to be used directly.
 */

import { createBooking, fetchStatus, pollStatus, newExternalRef, fetchProviders } from './client.js';
import { statusCopy, TERMINAL_STATUSES } from './state.js';
import { resolveTheme } from './theme.js';
import { STYLES as STYLES_CSS } from './styles.js';

const DEFAULT_TEXT = {
  title: 'Book an appointment',
  subtitle: 'Request a slot and we will confirm shortly.',
  name: 'Full name',
  phone: 'Phone number',
  email: 'Email address',
  provider: 'Preferred doctor (optional)',
  noPreference: 'No preference',
  service: 'Service (optional)',
  datetime: 'Preferred date & time',
  visitType: 'Appointment type',
  visitPhysical: 'In person',
  visitTelemedicine: 'Video call',
  visitHome: 'Home visit',
  notes: 'Notes (optional)',
  submit: 'Request appointment',
  submitting: 'Submitting…',
  bookAnother: 'Book another appointment',
  requiredPhoneOrEmail: 'Please provide a phone number or an email address.',
  requiredName: 'Please enter your name.',
  requiredDatetime: 'Please choose a date and time.',
  networkError: 'Could not reach the booking service. Please try again.',
  rateLimited: 'Too many requests — please wait a moment and try again.',
};

const STYLE_ID = 'mylikita-widget-styles';
const VISIT_TYPES = ['physical', 'telemedicine', 'home_visit'];

export function createBookingWidget(element, options = {}) {
  if (!element) throw new Error('createBookingWidget: a container element is required');
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
    pollIntervalMs: options.pollIntervalMs ?? 5000,
    maxTries: options.maxTries ?? 12,
    text: { ...DEFAULT_TEXT, ...(options.text || {}) },
    theme: options.theme || {},
    onStatus: typeof options.onStatus === 'function' ? options.onStatus : null,
    onError: typeof options.onError === 'function' ? options.onError : null,
    onBooking: typeof options.onBooking === 'function' ? options.onBooking : null,
    externalRef: typeof options.externalRef === 'function' ? options.externalRef : newExternalRef,
  };

  if (!opts.relayUrl || !opts.websiteKey || !opts.facilityId) {
    throw new Error('createBookingWidget: relayUrl, websiteKey and facilityId are required');
  }

  injectStyles();
  const t = opts.text;

  // ── root / lifecycle state ──────────────────────────────────────────────
  const root = element;
  root.classList.add('mylikita-widget');
  applyTheme(root, opts.theme);
  let alive = true;          // destroy() flips this; async continuations check it
  let submitting = false;
  let pollCtrl = null;       // AbortController for the in-flight booking/poll
  // Per-instance ref key: two widgets on one page (e.g. sidebar + page) must
  // never share a single external_ref (reviewer-caught — the demo had widget
  // 2's booking replay widget 1's).
  const instanceId = Math.random().toString(36).slice(2, 8);
  const refKey = `mylikita_ref_${opts.facilityId}_${instanceId}`;

  // ── DOM construction ────────────────────────────────────────────────────
  const form = el('form', { className: 'mylikita-widget__form' });

  const title = el('h3', { className: 'mylikita-widget__title', text: t.title });
  const subtitle = el('p', { className: 'mylikita-widget__subtitle', text: t.subtitle });

  const errorBox = el('div', { className: 'mylikita-widget__error', attrs: { role: 'alert' } });

  // NOTE: fieldText/fieldSelect return { wrap, input } — only `.wrap` goes
  // into the DOM; `.input` is the live control the submit flow reads.
  const name = fieldText('name', t.name, { required: true });
  const phoneEmail = el('div', { className: 'mylikita-widget__row' });
  const phone = fieldText('phone', t.phone, { type: 'tel', inputmode: 'tel' });
  const email = fieldText('email', t.email, { type: 'email' });
  phoneEmail.append(phone.wrap, email.wrap);

  const provider = fieldSelect('provider', t.provider, [
    { value: '', label: t.noPreference },
    ...opts.providers.map((p) => ({ value: p.external_id, label: p.label || p.name || p.external_id })),
  ]);
  // Repopulate the provider <select> with a fetched/static list, preserving
  // the current selection when it still exists.
  function setProviderList(list) {
    const current = provider.input.value;
    provider.input.replaceChildren();
    const noPref = document.createElement('option');
    noPref.value = '';
    noPref.textContent = t.noPreference;
    provider.input.append(noPref);
    for (const p of list || []) {
      const opt = document.createElement('option');
      opt.value = p.external_id;
      opt.textContent = p.label || p.name || p.external_id;
      provider.input.append(opt);
    }
    if (current) provider.input.value = current;
  }
  const service = opts.services.length
    ? fieldSelect('service', t.service, [
        { value: '', label: '—' },
        ...opts.services.map((s) => ({ value: s, label: s })),
      ])
    : fieldText('service', t.service);

  const datetime = fieldText('datetime', t.datetime, { type: 'datetime-local', required: true });
  datetime.input.min = toLocalInputValue(new Date());

  const visitType = fieldSelect('visitType', t.visitType, [
    { value: 'physical', label: t.visitPhysical },
    { value: 'telemedicine', label: t.visitTelemedicine },
    { value: 'home_visit', label: t.visitHome },
  ]);
  const notes = fieldText('notes', t.notes, { type: 'textarea', maxlength: 500 });

  const submitBtn = el('button', { className: 'mylikita-widget__submit', type: 'submit', text: t.submit });
  const submitRow = el('div');
  submitRow.append(submitBtn);
  const hint = el('p', { className: 'mylikita-widget__hint' });

  form.append(errorBox, name.wrap, phoneEmail, provider.wrap, service.wrap, datetime.wrap, visitType.wrap, notes.wrap, submitRow, hint);

  // ── status view (built lazily, reused for poll updates) ─────────────────
  const statusView = el('div', { className: 'mylikita-widget__status', attrs: { 'aria-live': 'polite' }, hidden: true });

  // ── submit flow ─────────────────────────────────────────────────────────
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    if (submitting) return;
    submit();
  });

  async function submit() {
    submitting = true;
    setError(null);
    submitBtn.disabled = true;
    submitBtn.textContent = t.submitting;

    const payload = {
      facility_id: opts.facilityId,
      patient_name: name.input.value.trim(),
      patient_phone: phone.input.value.trim(),
      patient_email: email.input.value.trim(),
      provider_external_id: provider.input.value || undefined,
      service_name: service.input.value.trim() || undefined,
      appt_datetime: datetime.input.value,
      visit_type: visitType.input.value || 'physical',
      duration_mins: opts.durationMins || undefined,
      notes: notes.input.value.trim() || undefined,
    };

    // Client-side validation (mirrors the relay's rules) BEFORE touching
    // storage, so an invalid form never mints/spends an external_ref.
    if (!payload.patient_name) return fail(t.requiredName);
    if (!payload.patient_phone && !payload.patient_email) return fail(t.requiredPhoneOrEmail);
    if (!payload.appt_datetime || Number.isNaN(Date.parse(payload.appt_datetime))) return fail(t.requiredDatetime);

    // Idempotency (§4): reuse the stored ref on refresh/resubmit, mint once.
    let external_ref = readStoredRef(refKey);
    if (!external_ref) {
      external_ref = opts.externalRef();
      try { sessionStorage.setItem(refKey, external_ref); } catch (_) { /* private mode */ }
    }
    payload.external_ref = external_ref;

    pollCtrl = new AbortController();
    let bookingRef = null;
    try {
      const created = await createBooking({ relayUrl: opts.relayUrl, websiteKey: opts.websiteKey, payload, signal: pollCtrl.signal });
      bookingRef = created.booking_ref;
      if (created.duplicate) {
        // §4: same slot already booked by this patient — treat as success.
        hint.textContent = '';
        showStatus('pending_confirmation', bookingRef, 'We found an existing booking request for this slot — checking it…');
      } else {
        if (opts.onBooking) safeCall(opts.onBooking, created, payload);
        showStatus('pending_confirmation', bookingRef, null);
      }
      startPoll(bookingRef);
    } catch (err) {
      if (!alive || err?.name === 'AbortError') return;
      const friendly = err.status === 429 ? t.rateLimited : err.message || t.networkError;
      if (opts.onError) safeCall(opts.onError, err);
      fail(friendly);
    }
  }

  async function startPoll(bookingRef) {
    let result;
    try {
      result = await pollStatus(
        () => fetchStatus({ relayUrl: opts.relayUrl, websiteKey: opts.websiteKey, bookingRef, signal: pollCtrl.signal }),
        { intervalMs: opts.pollIntervalMs, maxTries: opts.maxTries, signal: pollCtrl.signal },
      );
    } catch (err) {
      if (!alive || err?.name === 'AbortError') return;
      if (opts.onError) safeCall(opts.onError, err);
      // The form is already hidden — surface the failure in the status view
      // (the 'Book another' button lets the patient retry).
      renderStatus('poll_error', bookingRef, err.message || t.networkError);
      submitting = false;
      return;
    }
    if (!alive || result.status === 'aborted') return;
    if (opts.onStatus && result.data) safeCall(opts.onStatus, result.data);

    if (result.resolved) {
      // Terminal — a future submission must mint a fresh ref.
      try { sessionStorage.removeItem(refKey); } catch (_) { /* ignore */ }
      renderStatus(result.status, bookingRef);
    } else {
      // Still pending after the budget — show "request received" and let the
      // patient keep the ref for a manual re-check after refresh.
      renderStatus('pending_confirmation', bookingRef);
    }
    submitting = false;
  }

  // ── rendering helpers ───────────────────────────────────────────────────
  function showStatus(status, bookingRef, messageOverride) {
    form.hidden = true;
    title.hidden = true;
    subtitle.hidden = true;
    statusView.hidden = false;
    renderStatus(status, bookingRef, messageOverride);
  }

  function renderStatus(status, bookingRef, messageOverride) {
    const c = statusCopy(status);
    const icon = el('div', { className: `mylikita-widget__status-icon ${c.kind}` });
    icon.textContent = iconGlyph(c.kind);
    const st = el('p', { className: 'mylikita-widget__status-title', text: c.title });
    const msg = el('p', { className: 'mylikita-widget__status-message', text: messageOverride || c.message });
    const ref = el('p', { className: 'mylikita-widget__status-ref', text: bookingRef ? `Booking ref: ${bookingRef}` : '' });
    const again = el('button', { className: 'mylikita-widget__link-btn', type: 'button', text: t.bookAnother });
    again.addEventListener('click', () => reset());
    statusView.replaceChildren(icon, st, msg, ref, again);
  }

  function fail(message) {
    submitting = false;
    submitBtn.disabled = false;
    submitBtn.textContent = t.submit;
    setError(message);
  }

  function setError(message) {
    errorBox.textContent = message || '';
    errorBox.classList.toggle('visible', Boolean(message));
  }

  function reset() {
    try { sessionStorage.removeItem(`mylikita_ref_${opts.facilityId}`); } catch (_) { /* ignore */ }
    form.reset();
    setError(null);
    statusView.replaceChildren();
    statusView.hidden = true;
    form.hidden = false;
    title.hidden = false;
    subtitle.hidden = false;
    hint.textContent = '';
    submitting = false;
    submitBtn.disabled = false;
    submitBtn.textContent = t.submit;
    datetime.input.min = toLocalInputValue(new Date());
  }

  root.replaceChildren(title, subtitle, form, statusView);

  // ── async provider load (Phase C2/C3) ────────────────────────────────────
  // When loadProviders is on, fetch the facility's mapped doctors and fill the
  // dropdown. Failures are non-fatal: the widget still works with "No
  // preference" (an unmapped provider slug simply arrives unassigned). The
  // abort ties the fetch to the widget's lifecycle so destroy() can't leak it.
  let destroyProvidersFetch = null;
  if (opts.loadProviders) {
    const provCtrl = new AbortController();
    (async () => {
      try {
        const list = await fetchProviders({
          relayUrl: opts.relayUrl,
          websiteKey: opts.websiteKey,
          signal: provCtrl.signal,
        });
        if (alive && !provCtrl.signal.aborted) setProviderList(list);
      } catch (err) {
        if (!alive || err?.name === 'AbortError') return;
        if (opts.onError) safeCall(opts.onError, err);
        // keep "No preference" — a quiet fallback beats a broken form
      }
    })();
    destroyProvidersFetch = () => provCtrl.abort();
  }

  // ── public API ──────────────────────────────────────────────────────────
  return {
    destroy() {
      alive = false;
      if (pollCtrl) pollCtrl.abort(); // stop the in-flight booking/poll immediately
      if (destroyProvidersFetch) destroyProvidersFetch(); // cancel the provider fetch
      root.replaceChildren();
      root.classList.remove('mylikita-widget');
    },
    reset,
    getForm() { return { name: name.input.value, phone: phone.input.value, email: email.input.value }; },
  };
}

// ── field builders ──────────────────────────────────────────────────────────

function fieldText(name, label, { type = 'text', required = false, maxlength, inputmode } = {}) {
  const wrap = el('div', { className: 'mylikita-widget__field' });
  const lab = el('label', { className: 'mylikita-widget__label', attrs: { for: `mlw-${name}` } });
  lab.append(document.createTextNode(label));
  if (required) lab.append(el('span', { className: 'req', text: ' *' }));
  let input;
  if (type === 'textarea') {
    input = el('textarea', { className: 'mylikita-widget__textarea', attrs: { id: `mlw-${name}`, rows: 3, maxlength: maxlength || '' } });
  } else {
    input = el('input', { className: 'mylikita-widget__input', attrs: { id: `mlw-${name}`, type, inputmode: inputmode || '' } });
  }
  if (required) input.setAttribute('required', '');
  wrap.append(lab, input);
  return { wrap, input };
}

function fieldSelect(name, label, options) {
  const wrap = el('div', { className: 'mylikita-widget__field' });
  const lab = el('label', { className: 'mylikita-widget__label', attrs: { for: `mlw-${name}` } });
  lab.textContent = label;
  const select = el('select', { className: 'mylikita-widget__select', attrs: { id: `mlw-${name}` } });
  for (const o of options) {
    // opt.value is set as a property, not an attribute, so an EMPTY value
    // ("no preference") is preserved — el() skips empty attributes, which
    // would otherwise make the select submit the label text as the value.
    const opt = el('option', { text: o.label });
    opt.value = o.value;
    select.append(opt);
  }
  wrap.append(lab, select);
  return { wrap, input: select };
}

// ── misc DOM helpers ────────────────────────────────────────────────────────

function el(tag, { className, text, attrs = {} } = {}) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  for (const [k, v] of Object.entries(attrs)) {
    if (v === undefined || v === '') continue;
    node.setAttribute(k, v);
  }
  return node;
}

function iconGlyph(kind) {
  return kind === 'success' ? '✓' : kind === 'danger' ? '!' : '…';
}

function readStoredRef(key) {
  try { return sessionStorage.getItem(key) || null; } catch (_) { return null; }
}

// Call a user callback defensively — a throwing callback must never break the
// widget's own flow (reviewer-caught: this was previously undefined).
function safeCall(fn, ...args) {
  try { fn(...args); } catch (_) { /* callback errors are the host's problem */ }
}

function toLocalInputValue(date) {
  const pad = (n) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function injectStyles() {
  if (document.getElementById(STYLE_ID)) return;
  const style = document.createElement('style');
  style.id = STYLE_ID;
  style.textContent = STYLES_CSS;
  document.head.appendChild(style);
}

function applyTheme(rootNode, theme) {
  for (const [k, v] of Object.entries(resolveTheme(theme))) {
    rootNode.style.setProperty(k, v);
  }
}
