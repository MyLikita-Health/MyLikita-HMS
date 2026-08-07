/*! @mylikita/booking-widget v0.1.1 | MIT */

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
  const t = { ...DEFAULT_THEME, ...theme || {} };
  return {
    "--mlw-primary": t.primary,
    "--mlw-primary-dark": t.primaryDark,
    "--mlw-primary-text": t.primaryText,
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

/* status view */
.mylikita-widget__status { text-align: center; padding: 8px 4px; }
.mylikita-widget__status-icon {
  width: 46px; height: 46px;
  border-radius: 50%;
  display: inline-flex; align-items: center; justify-content: center;
  font-size: 22px; margin-bottom: 10px;
}
.mylikita-widget__status-icon.info { background: color-mix(in srgb, var(--mlw-primary) 12%, transparent); }
.mylikita-widget__status-icon.success { background: color-mix(in srgb, var(--mlw-success) 14%, transparent); }
.mylikita-widget__status-icon.danger { background: color-mix(in srgb, var(--mlw-danger) 12%, transparent); }
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
`;

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
  datetime: "Preferred date & time",
  visitType: "Appointment type",
  visitPhysical: "In person",
  visitTelemedicine: "Video call",
  visitHome: "Home visit",
  notes: "Notes (optional)",
  submit: "Request appointment",
  submitting: "Submitting\u2026",
  bookAnother: "Book another appointment",
  requiredPhoneOrEmail: "Please provide a phone number or an email address.",
  requiredName: "Please enter your name.",
  requiredDatetime: "Please choose a date and time.",
  networkError: "Could not reach the booking service. Please try again.",
  rateLimited: "Too many requests \u2014 please wait a moment and try again."
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
    pollIntervalMs: options.pollIntervalMs ?? 5e3,
    maxTries: options.maxTries ?? 12,
    text: { ...DEFAULT_TEXT, ...options.text || {} },
    theme: options.theme || {},
    onStatus: typeof options.onStatus === "function" ? options.onStatus : null,
    onError: typeof options.onError === "function" ? options.onError : null,
    onBooking: typeof options.onBooking === "function" ? options.onBooking : null,
    externalRef: typeof options.externalRef === "function" ? options.externalRef : newExternalRef
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
  const instanceId = Math.random().toString(36).slice(2, 8);
  const refKey = `mylikita_ref_${opts.facilityId}_${instanceId}`;
  const form = el("form", { className: "mylikita-widget__form" });
  const title = el("h3", { className: "mylikita-widget__title", text: t.title });
  const subtitle = el("p", { className: "mylikita-widget__subtitle", text: t.subtitle });
  const errorBox = el("div", { className: "mylikita-widget__error", attrs: { role: "alert" } });
  const name = fieldText("name", t.name, { required: true });
  const phoneEmail = el("div", { className: "mylikita-widget__row" });
  const phone = fieldText("phone", t.phone, { type: "tel", inputmode: "tel" });
  const email = fieldText("email", t.email, { type: "email" });
  phoneEmail.append(phone.wrap, email.wrap);
  const provider = fieldSelect("provider", t.provider, [
    { value: "", label: t.noPreference },
    ...opts.providers.map((p) => ({ value: p.external_id, label: p.label || p.name || p.external_id }))
  ]);
  function setProviderList(list) {
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
    if (current) provider.input.value = current;
  }
  const service = opts.services.length ? fieldSelect("service", t.service, [
    { value: "", label: "\u2014" },
    ...opts.services.map((s) => ({ value: s, label: s }))
  ]) : fieldText("service", t.service);
  const datetime = fieldText("datetime", t.datetime, { type: "datetime-local", required: true });
  datetime.input.min = toLocalInputValue(/* @__PURE__ */ new Date());
  const visitType = fieldSelect("visitType", t.visitType, [
    { value: "physical", label: t.visitPhysical },
    { value: "telemedicine", label: t.visitTelemedicine },
    { value: "home_visit", label: t.visitHome }
  ]);
  const notes = fieldText("notes", t.notes, { type: "textarea", maxlength: 500 });
  const submitBtn = el("button", { className: "mylikita-widget__submit", type: "submit", text: t.submit });
  const submitRow = el("div");
  submitRow.append(submitBtn);
  const hint = el("p", { className: "mylikita-widget__hint" });
  form.append(errorBox, name.wrap, phoneEmail, provider.wrap, service.wrap, datetime.wrap, visitType.wrap, notes.wrap, submitRow, hint);
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
    const payload = {
      facility_id: opts.facilityId,
      patient_name: name.input.value.trim(),
      patient_phone: phone.input.value.trim(),
      patient_email: email.input.value.trim(),
      provider_external_id: provider.input.value || void 0,
      service_name: service.input.value.trim() || void 0,
      appt_datetime: datetime.input.value,
      visit_type: visitType.input.value || "physical",
      duration_mins: opts.durationMins || void 0,
      notes: notes.input.value.trim() || void 0
    };
    if (!payload.patient_name) return fail(t.requiredName);
    if (!payload.patient_phone && !payload.patient_email) return fail(t.requiredPhoneOrEmail);
    if (!payload.appt_datetime || Number.isNaN(Date.parse(payload.appt_datetime))) return fail(t.requiredDatetime);
    let external_ref = readStoredRef(refKey);
    if (!external_ref) {
      external_ref = opts.externalRef();
      try {
        sessionStorage.setItem(refKey, external_ref);
      } catch (_) {
      }
    }
    payload.external_ref = external_ref;
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
    const icon = el("div", { className: `mylikita-widget__status-icon ${c.kind}` });
    icon.textContent = iconGlyph(c.kind);
    const st = el("p", { className: "mylikita-widget__status-title", text: c.title });
    const msg = el("p", { className: "mylikita-widget__status-message", text: messageOverride || c.message });
    const ref = el("p", { className: "mylikita-widget__status-ref", text: bookingRef ? `Booking ref: ${bookingRef}` : "" });
    const again = el("button", { className: "mylikita-widget__link-btn", type: "button", text: t.bookAnother });
    again.addEventListener("click", () => reset());
    statusView.replaceChildren(icon, st, msg, ref, again);
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
    datetime.input.min = toLocalInputValue(/* @__PURE__ */ new Date());
  }
  root.replaceChildren(title, subtitle, form, statusView);
  let destroyProvidersFetch = null;
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
  return {
    destroy() {
      alive = false;
      if (pollCtrl) pollCtrl.abort();
      if (destroyProvidersFetch) destroyProvidersFetch();
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
function toLocalInputValue(date) {
  const pad = (n) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
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
export {
  DEFAULT_THEME,
  STATUS_COPY,
  TERMINAL_STATUSES,
  createBooking,
  createBookingWidget,
  fetchProviders,
  fetchStatus,
  newExternalRef,
  pollStatus,
  resolveTheme,
  statusCopy
};
