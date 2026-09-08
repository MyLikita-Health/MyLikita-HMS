/**
 * DOM layer of the booking widget. Renders a self-contained booking form,
 * submits through the relay client, and swaps to a status view that polls the
 * booking until it resolves (or the poll budget runs out). All text is
 * i18n-overridable via `options.text`; all colours via `options.theme` or the
 * CSS variables (see theme.js).
 *
 * Imported from index.js — not meant to be used directly.
 */

import { createBooking, createWaitlist, trackPageView, fetchStatus, pollStatus, newExternalRef, fetchProviders, fetchServices, fetchAvailability } from './client.js';
import { statusCopy, TERMINAL_STATUSES } from './state.js';
import { resolveTheme } from './theme.js';
import { STYLES as STYLES_CSS } from './styles.js';
import { createBrandHeader } from './brand.js';

const DEFAULT_TEXT = {
  title: 'Book an appointment',
  subtitle: 'Request a slot and we will confirm shortly.',
  name: 'Full name',
  phone: 'Phone number',
  email: 'Email address',
  provider: 'Preferred doctor (optional)',
  noPreference: 'No preference',
  service: 'Service (optional)',
  serviceHint: 'Start typing to see options, or type your own.',
  // Phase C4 structured service registry dropdown.
  selectService: 'Select a service…',
  otherService: 'Other / not listed',
  otherServiceLabel: 'Tell us what you need',
  serviceOtherPlaceholder: 'e.g. tooth extraction, cleaning…',
  // P0 conversion UX — the raw datetime input is replaced by a friendly
  // date + time-slot picker (native date field + operating-hours slot chips).
  date: 'Choose a date',
  slot: 'Available times',
  selectDateHint: 'Pick a date to see available times.',
  closedDay: 'We are closed on this day — please choose another date.',
  noSlots: 'No times available for this date — please pick another day.',
  checkingAvailability: 'Checking available times…',
  requiredSlot: 'Please choose an available time.',
  // Phase C6 — visual taken/free + waitlist. Taken slots render struck-through
  // alongside free ones so patients see the whole day at a glance; a legend
  // distinguishes them. When no slot is free a waitlist panel appears.
  slotTakenLabel: 'Taken',
  slotFreeLabel: 'Available',
  slotLegend: 'Struck-through times are already booked.',
  noFreeSlots: 'No times are free on this day — join the waitlist below.',
  waitlistTitle: 'All booked? Join the waitlist',
  waitlistHint: 'We\u2019ll contact you if a slot opens up.',
  waitlistSubmit: 'Join waitlist',
  waitlistSubmitted: 'You\u2019re on the waitlist',
  waitlistSubmittedMsg: 'We\u2019ll call or message you if an appointment becomes available.',
  // Nigerian-aware phone validation + the "no account needed" reassurance.
  requiredPhone: 'Please enter your phone number.',
  invalidPhone: 'Please enter a valid phone number (e.g. 0803 123 4567).',
  noAccount: 'No account needed',
  datetime: 'Preferred date & time',
  visitType: 'Appointment type',
  visitPhysical: 'In person',
  visitTelemedicine: 'Video call',
  visitHome: 'Home visit',
  // ANC (antenatal) flow — only shown when the widget is constructed with
  // `ancBooking: true` (see ancBooking option). All text stays i18n-overridable.
  visitAntenatal: 'Antenatal checkup',
  ancPrompt: 'To book your antenatal visit we need your last period date.',
  ancLmp: 'First day of your last period (LMP)',
  ancLmpHint: 'We will estimate your baby\'s due date from this.',
  ancRequiredLmp: 'Please enter the first day of your last period.',
  notes: 'Notes (optional)',
  submit: 'Request appointment',
  submitting: 'Submitting…',
  bookAnother: 'Book another appointment',
  requiredPhoneOrEmail: 'Please provide a phone number or an email address.',
  requiredName: 'Please enter your name.',
  requiredDatetime: 'Please choose a date and time.',
  networkError: 'Could not reach the booking service. Please try again.',
  rateLimited: 'Too many requests — please wait a moment and try again.',
  slotTaken: 'That time was just booked by someone else — please pick another.',
  // Confirmation screen (booking ref + summary + calendar/WhatsApp actions).
  addToCalendar: 'Add to calendar',
  calAdded: '✓ Added to calendar',
  whatsappClinic: 'WhatsApp clinic',
  confirmWhen: 'When',
  confirmService: 'Service',
  confirmDoctor: 'Doctor',
  confirmVisit: 'Visit type',
  general: 'General',
  // V2 guided flow — 4 steps with a progress indicator.
  stepService: 'Service',
  stepDateTime: 'Date & Time',
  stepDetails: 'Your Details',
  stepReview: 'Confirm',
  progressLabel: 'Booking progress',
  step1Title: 'What service do you need?',
  step1Sub: 'Select the service you need. This helps us find the right doctor and available times.',
  step2Title: 'Choose a date & time',
  step2Sub: 'Pick a date, then choose an available time.',
  step3Title: 'Tell us about yourself',
  step3Sub: 'We only need these details to confirm your appointment.',
  step4Title: 'Review your appointment',
  step4Sub: 'Please check everything is correct before you confirm.',
  back: '← Back',
  nextDateTime: 'Next: Choose Date & Time →',
  nextDetails: 'Next: Your Details →',
  reviewAction: 'Review Appointment →',
  confirmLabel: 'Confirm Appointment',
  requiredService: 'Please choose a service.',
  closedDayShort: 'Closed',
  otherServicePrompt: 'Please describe the service you need',
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
    // Phase C4 service-registry load — mirrors loadProviders (hosted page and
    // embeds that opt in get real services + durations + doctor filtering).
    loadServices: options.loadServices === true ? true : (options.loadServices === false ? false : (options.loadProviders === true)),
    // Confirmation screen context — clinic name + WhatsApp number (digits) let
    // the widget show "WhatsApp clinic" and an Add-to-calendar event name.
    clinicName: options.clinicName || null,
    whatsappNumber: options.whatsappNumber || null,
    // Booking SOURCE (Phase C7 analytics) — the campaign/channel this visitor
    // came from (?source=instagram etc.). Defaults to reading ?source= off the
    // page URL; hosts may override. Sent with the booking payload so the relay
    // can compute conversion by source.
    source: (options.source != null && String(options.source)) || readSourceFromUrl(),
    // Track a page view on mount (POST /v1/track) so conversion (bookings /
    // views) per source is meaningful. Defaults on for the hosted page/embed.
    trackView: options.trackView !== false,
    // White-label flag: premium hosts can drop the MyLikita brand header.
    // Defaults to true (brand shown); pass showBrand:false to hide it.
    showBrand: options.showBrand !== false,
    pollIntervalMs: options.pollIntervalMs ?? 5000,
    maxTries: options.maxTries ?? 12,
    text: { ...DEFAULT_TEXT, ...(options.text || {}) },
    theme: options.theme || {},
    onStatus: typeof options.onStatus === 'function' ? options.onStatus : null,
    onError: typeof options.onError === 'function' ? options.onError : null,
    onBooking: typeof options.onBooking === 'function' ? options.onBooking : null,
    externalRef: typeof options.externalRef === 'function' ? options.externalRef : newExternalRef,
    // ANC-aware booking (P2, maternity roadmap 2.1): when a facility opts in,
    // the appointment-type dropdown gains an "Antenatal checkup" entry that
    // reveals an LMP date field. Choosing it submits booking_type 'anc' +
    // anc_lmp_date so the prime backend can register the pregnancy + WHO
    // visit schedule and GA-anchor the booked slot (see services/ancBooking.js).
    ancBooking: options.ancBooking === true,
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
  let lastPayload = null;    // the submitted booking, for the confirmation screen
  // Per-instance ref key: two widgets on one page (e.g. sidebar + page) must
  // never share a single external_ref (reviewer-caught — the demo had widget
  // 2's booking replay widget 1's).
  const instanceId = Math.random().toString(36).slice(2, 8);
  const refKey = `mylikita_ref_${opts.facilityId}_${instanceId}`;

  // ── DOM construction ────────────────────────────────────────────────────
  // The brand header is optional (white-label hosts pass showBrand:false);
  // replaceChildren() ignores null, so the rest of the tree is unchanged.
  const brand = opts.showBrand ? createBrandHeader() : null;
  const form = el('form', { className: 'mylikita-widget__form' });

  const title = el('h3', { className: 'mylikita-widget__title', text: t.title });
  const subtitle = el('p', { className: 'mylikita-widget__subtitle', text: t.subtitle });

  const errorBox = el('div', { className: 'mylikita-widget__error', attrs: { role: 'alert' } });
  const noAccountBadge = el('span', { className: 'mylikita-widget__noaccount', text: t.noAccount });

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
  // Full provider list (static or fetched) — per-service filtering subsets it
  // for the dropdown without losing the source of truth.
  let allProviders = [...(opts.providers || [])];
  function repopulateProviders(list) {
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
    // Keep the previous selection only if it still exists in the filtered set.
    if (current && [...provider.input.options].some((o) => o.value === current)) provider.input.value = current;
    else provider.input.value = '';
  }
  function setProviderList(list) {
    allProviders = list || [];
    opts.providers = allProviders;
    applyProviderFilter();
    refreshServiceList();
  }

  // ── Service picker (Phase C4) ───────────────────────────────────────────
  // When the facility has a pushed service registry, show a real dropdown of
  // services with their durations plus an "Other" free-text escape hatch;
  // otherwise fall back to a datalist autocomplete. Selecting a service (1)
  // filters the doctor dropdown to the providers that offer it and (2) carries
  // the service's duration + external id into the booking payload. The wrap
  // node is persistent so swapping modes never breaks the appended form node.
  const serviceWrap = el('div', { className: 'mylikita-widget__field' });
  let structuredServices = normalizeServices(opts.services);
  let selectedService = null; // { external_id, name, duration_mins, provider_external_ids } | null
  let service = { input: null, mode: 'text', otherInput: null, otherWrap: null, datalist: null };

  function buildServiceControl(list) {
    serviceWrap.replaceChildren();
    const services = normalizeServices(list);
    structuredServices = services;
    selectedService = null;
    if (services.length) {
      const lab = el('label', { className: 'mylikita-widget__label', attrs: { for: 'mlw-service' } });
      lab.textContent = t.service;
      const select = el('select', { className: 'mylikita-widget__select', attrs: { id: 'mlw-service' } });
      const ph = document.createElement('option');
      ph.value = '';
      ph.textContent = t.selectService;
      select.append(ph);
      for (const s of services) {
        const o = document.createElement('option');
        o.value = s.external_id;
        o.textContent = s.duration_mins ? `${s.name} (${s.duration_mins} min)` : s.name;
        select.append(o);
      }
      const otherOpt = document.createElement('option');
      otherOpt.value = '__other__';
      otherOpt.textContent = t.otherService;
      select.append(otherOpt);
      serviceWrap.append(lab, select);
      // Free-text "other" input revealed only when __other__ is chosen.
      const otherWrap = el('div', { className: 'mylikita-widget__field', attrs: { hidden: true } });
      const otherLab = el('label', { className: 'mylikita-widget__label', attrs: { for: 'mlw-service-other' } });
      otherLab.textContent = t.otherServiceLabel;
      const otherInput = el('input', { className: 'mylikita-widget__input', attrs: { id: 'mlw-service-other', type: 'text', placeholder: t.serviceOtherPlaceholder } });
      otherWrap.append(otherLab, otherInput);
      serviceWrap.append(otherWrap);
      service = { input: select, mode: 'select', otherInput, otherWrap, datalist: null };
      const sync = () => {
        const val = select.value;
        const isOther = val === '__other__';
        otherWrap.hidden = !isOther;
        selectedService = null;
        if (val && !isOther) {
          selectedService = services.find((x) => x.external_id === val) || null;
        }
        applyProviderFilter();
      };
      select.addEventListener('change', sync);
      sync();
    } else {
      // Fallback: datalist autocomplete (services + provider specialties).
      const lab = el('label', { className: 'mylikita-widget__label', attrs: { for: 'mlw-service' } });
      lab.textContent = t.service;
      const input = el('input', { className: 'mylikita-widget__input', attrs: { id: 'mlw-service', type: 'text' } });
      const datalist = el('datalist', { attrs: { id: 'mlw-service-list' } });
      input.setAttribute('list', 'mlw-service-list');
      const hint = el('p', { className: 'mylikita-widget__field-hint', text: t.serviceHint });
      serviceWrap.append(lab, input, datalist, hint);
      service = { input, mode: 'text', otherInput: null, otherWrap: null, datalist };
      refreshServiceList();
    }
  }
  buildServiceControl(structuredServices);
  // `service` and `serviceWrap` must be a single form field — alias so the
  // rest of the code (form.append + submit) reads `service.wrap`.
  service.wrap = serviceWrap;

  function refreshServiceList() {
    if (service.mode !== 'text' || !service.datalist) return;
    const dl = service.datalist;
    const seen = new Set();
    const add = (s) => { const v = String(s || '').trim(); if (v && !seen.has(v)) { seen.add(v); const o = el('option', { attrs: { value: v } }); dl.append(o); } };
    dl.replaceChildren();
    (opts.services || []).forEach(add);
    allProviders.forEach((p) => { add(p.specialty); add(p.label || p.name); });
  }

  function applyProviderFilter() {
    if (selectedService && Array.isArray(selectedService.provider_external_ids) && selectedService.provider_external_ids.length) {
      const set = new Set(selectedService.provider_external_ids);
      repopulateProviders(allProviders.filter((p) => set.has(p.external_id)));
    } else {
      repopulateProviders(allProviders);
    }
  }

  // Swap in a fetched service registry (async load) — rebuilds the control if
  // the mode changes (no registry at construction → registry arrives later).
  function setServiceList(list) {
    opts.services = list || [];
    buildServiceControl(opts.services);
    service.wrap = serviceWrap;
    if (service.input && typeof onServiceSlotReRender === 'function') {
      service.input.addEventListener('change', onServiceSlotReRender);
    }
    applyProviderFilter();
  }

  // Resolve the current service selection for the payload.
  function getServiceSelection() {
    if (service.mode === 'select') {
      if (selectedService) return selectedService;
      if (service.input.value === '__other__') {
        const other = (service.otherInput && service.otherInput.value.trim()) || '';
        return other ? { external_id: null, name: other, duration_mins: null } : null;
      }
      return null;
    }
    const name = (service.input && service.input.value.trim()) || '';
    return name ? { external_id: null, name, duration_mins: null } : null;
  }

  // P0 conversion UX — friendly date + time-slot picker. A native date
  // input picks the day; time-slot chips are generated from the facility's
  // operating hours (working_days, open_time, close_time, slot_duration) via
  // the relay's operatingHours option. The chosen date+time is written into a
  // hidden `datetime` input so the rest of the submit flow and the relay
  // contract (appt_datetime = local datetime string) stay unchanged.
  const datePick = fieldText('date', t.date, { type: 'date', required: true });
  const nowRef = new Date();
  datePick.input.min = toLocalDateValue(nowRef);
  const slotGroup = el('div', { className: 'mylikita-widget__field mylikita-widget__slotfield' });
  const slotLab = el('label', { className: 'mylikita-widget__label', text: t.slot });
  const slotChips = el('div', { className: 'mylikita-widget__slots', attrs: { role: 'group', 'aria-label': t.slot } });
  const slotHint = el('p', { className: 'mylikita-widget__slot-hint', text: t.selectDateHint });
  // Waitlist panel (Phase C6) — revealed under the slots when nothing is free.
  const waitlistBox = el('div', { className: 'mylikita-widget__waitlist', attrs: { hidden: true } });
  const waitlistTitle = el('p', { className: 'mylikita-widget__waitlist-title', text: t.waitlistTitle });
  const waitlistHint = el('p', { className: 'mylikita-widget__waitlist-hint', text: t.waitlistHint });
  const waitlistBtn = el('button', { type: 'button', className: 'mylikita-widget__waitlist-btn', text: t.waitlistSubmit });
  waitlistBox.append(waitlistTitle, waitlistHint, waitlistBtn);
  slotGroup.append(slotLab, slotChips, slotHint, waitlistBox);
  // Hidden carrier — keeps appt_datetime in the wire format (Y-m-dTHH:MM, local).
  const datetime = fieldText('datetime', '', { type: 'hidden', required: true });
  datetime.wrap.hidden = true;
  datetime.input.value = '';

  // Rebuild the time-slot chips for the selected date. Candidate slots come
  // from operating hours (past/closed days yield none), then any slot that
  // overlaps an ALREADY-BOOKED range (from GET /v1/availability) is rendered
  // as TAKEN (disabled + struck-through) rather than hidden, so patients see
  // the whole day at a glance. Clicking a FREE chip stores `${date}T${time}`
  // into the hidden `datetime` input the submit flow reads.
  let availCtrl = null;
  function cancelAvailability() { if (availCtrl) { availCtrl.abort(); availCtrl = null; } }
  function renderWaitlist(show) { waitlistBox.hidden = !show; }
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
    if (closed) { slotHint.textContent = t.closedDay; renderWaitlist(false); return; }
    if (!slots.length) { slotHint.textContent = t.noSlots; renderWaitlist(false); return; }
    // Real-time availability — mark slots that overlap a booked range as taken.
    cancelAvailability();
    availCtrl = new AbortController();
    const signal = availCtrl.signal;
    slotHint.textContent = t.checkingAvailability;
    let booked = [];
    try {
      booked = await fetchAvailability({
        relayUrl: opts.relayUrl, websiteKey: opts.websiteKey, date: dateVal, signal,
      });
    } catch (err) {
      // Fall back to operating-hours slots if availability can't be fetched.
      if (!alive || signal.aborted) return;
    }
    if (!alive || signal.aborted) return;
    const slotDur = (selectedService && selectedService.duration_mins) || opts.durationMins || 30;
    slotChips.replaceChildren();
    let freeCount = 0;
    for (const time of slots) {
      const taken = overlapsBooked(time, slotDur, booked);
      if (taken) {
        const chip = el('button', {
          type: 'button',
          className: 'mylikita-widget__slot mylikita-widget__slot-taken',
          attrs: { disabled: '', title: t.slotTakenLabel },
        });
        chip.textContent = time;
        slotChips.append(chip);
      } else {
        freeCount += 1;
        const chip = el('button', { type: 'button', className: 'mylikita-widget__slot', text: time });
        chip.addEventListener('click', () => {
          slotChips.querySelectorAll('.mylikita-widget__slot:not(:disabled)').forEach((c) => c.classList.remove('selected'));
          chip.classList.add('selected');
          datetime.input.value = `${dateVal}T${time}`;
        });
        slotChips.append(chip);
      }
    }
    if (freeCount === 0) {
      slotHint.textContent = t.noFreeSlots;
      renderWaitlist(true);
    } else {
      slotHint.textContent = booked.length ? t.slotLegend : '';
      renderWaitlist(false);
    }
  }
  datePick.input.addEventListener('change', () => {
    datetime.input.value = '';
    slotChips.querySelectorAll('.mylikita-widget__slot').forEach((c) => c.classList.remove('selected'));
    renderSlots();
  });

  // When the service (and thus its duration) changes, the free-slot set may
  // change (a longer service can overlap more booked ranges) — re-render.
  // Attached to the CURRENT service control; re-attached when the registry
  // arrives async (see setServiceList).
  const onServiceSlotReRender = () => { if (datePick.input.value) renderSlots(); };
  if (service.input) service.input.addEventListener('change', onServiceSlotReRender);

  const visitTypeOptions = [
    { value: 'physical', label: t.visitPhysical },
    { value: 'telemedicine', label: t.visitTelemedicine },
    { value: 'home_visit', label: t.visitHome },
  ];
  if (opts.ancBooking) visitTypeOptions.push({ value: 'antenatal', label: t.visitAntenatal });
  const visitType = fieldSelect('visitType', t.visitType, visitTypeOptions);
  const notes = fieldText('notes', t.notes, { type: 'textarea', maxlength: 500 });

  // ANC sub-group — rendered ONLY when the facility opted into ANC booking.
  // Revealed while the visitor has picked the antenatal visit type, hidden by
  // default so a normal appointment never shows it, and absent entirely for
  // non-maternity facilities (no ANC DOM, no stray a11y noise).
  let ancLmp = null;
  let ancGroup = null;
  let syncAncVisibility = null;
  if (opts.ancBooking) {
    ancLmp = fieldText('ancLmp', t.ancLmp, { type: 'date' });
    const ancNote = el('p', { className: 'mylikita-widget__anc-note', text: t.ancLmpHint });
    ancGroup = el('div', { className: 'mylikita-widget__anc', attrs: { hidden: true } });
    ancGroup.append(ancLmp.wrap, ancNote);
    const isAntenatal = () => visitType.input.value === 'antenatal';
    syncAncVisibility = () => {
      ancGroup.hidden = !isAntenatal();
      // LMP must be in the past — an EDD far in the future is nonsense.
      ancLmp.input.max = toLocalDateValue(new Date());
    };
    visitType.input.addEventListener('change', syncAncVisibility);
    syncAncVisibility();
  }

  const submitBtn = el('button', { className: 'mylikita-widget__submit', type: 'submit', text: t.submit });
  const submitRow = el('div');
  submitRow.append(submitBtn);
  const hint = el('p', { className: 'mylikita-widget__hint' });

  // V2 — re-parent the existing fields into a guided 4-step flow with a
  // progress indicator, date cards, per-step CTAs and a review step. Every
  // input/control is the SAME node the submit/status flow already reads, so
  // the payload and confirmation behaviour are unchanged — this only
  // reorganises presentation and adds step navigation.
  const stepDefs = [
    { key: 'service', label: t.stepService },
    { key: 'datetime', label: t.stepDateTime },
    { key: 'details', label: t.stepDetails },
    { key: 'review', label: t.stepReview },
  ];
  const progressBar = el('ol', { className: 'mylikita-widget__progress', attrs: { 'aria-label': t.progressLabel } });
  const progressItems = stepDefs.map((d, i) => {
    const li = el('li', { className: 'mylikita-widget__progress-item' });
    li.append(
      el('span', { className: 'mylikita-widget__progress-dot', text: String(i + 1) }),
      el('span', { className: 'mylikita-widget__progress-label', text: d.label }),
    );
    progressBar.append(li);
    return li;
  });

  const stepService = el('div', { className: 'mylikita-widget__step', attrs: { 'data-step': '1' } });
  const stepDateTime = el('div', { className: 'mylikita-widget__step', attrs: { 'data-step': '2' }, hidden: true });
  const stepDetails = el('div', { className: 'mylikita-widget__step', attrs: { 'data-step': '3' }, hidden: true });
  const stepReview = el('div', { className: 'mylikita-widget__step', attrs: { 'data-step': '4' }, hidden: true });
  const stepNodes = [stepService, stepDateTime, stepDetails, stepReview];
  let currentStep = 1;

  // Step 1 — Service (+ doctor)
  stepService.append(
    el('h4', { className: 'mylikita-widget__step-title', text: t.step1Title }),
    el('p', { className: 'mylikita-widget__step-sub', text: t.step1Sub }),
    service.wrap,
    provider.wrap,
  );
  const step1Actions = el('div', { className: 'mylikita-widget__step-actions' });
  const next1 = el('button', { type: 'button', className: 'mylikita-widget__cta', text: t.nextDateTime });
  next1.addEventListener('click', () => { if (validateStep1()) showStep(2); });
  step1Actions.append(next1);
  stepService.append(step1Actions);

  // Step 2 — Date & Time (date cards + existing time-slot chips)
  stepDateTime.append(
    el('h4', { className: 'mylikita-widget__step-title', text: t.step2Title }),
    el('p', { className: 'mylikita-widget__step-sub', text: t.step2Sub }),
  );
  // Horizontally-scrollable date cards (replaces the raw native date input as
  // the primary picker). Selecting a card writes into the hidden `datePick`
  // input and re-renders the time slots via the existing renderSlots().
  const dateCardsWrap = el('div', { className: 'mylikita-widget__dates' });
  let dateCards = [];
  const ohDays = Array.isArray(opts.operatingHours && opts.operatingHours.working_days) && (opts.operatingHours.working_days.length)
    ? opts.operatingHours.working_days
    : [1, 2, 3, 4, 5, 6];
  function renderDateCards() {
    dateCardsWrap.replaceChildren();
    dateCards = [];
    const horizon = opts.dateHorizonDays || 14;
    const now = new Date();
    for (let i = 0; i < horizon; i++) {
      const d = new Date(now);
      d.setDate(now.getDate() + i);
      const ds = toLocalDateValue(d);
      const closed = !ohDays.includes(d.getDay());
      const card = el('button', {
        type: 'button',
        className: 'mylikita-widget__date-card' + (closed ? ' closed' : ''),
        attrs: {
          'data-date': ds,
          title: closed ? t.closedDayShort : '',
          ...(closed ? { disabled: '', 'aria-disabled': 'true' } : {}),
        },
      });
      card.append(
        el('span', { className: 'mylikita-widget__date-week', text: d.toLocaleDateString(undefined, { weekday: 'short' }) }),
        el('span', { className: 'mylikita-widget__date-day', text: String(d.getDate()) }),
        el('span', { className: 'mylikita-widget__date-month', text: d.toLocaleDateString(undefined, { month: 'short' }) }),
      );
      if (!closed) {
        card.addEventListener('click', () => {
          dateCards.forEach((c) => c.classList.toggle('selected', c === card));
          datePick.input.value = ds;
          datetime.input.value = '';
          slotChips.querySelectorAll('.mylikita-widget__slot').forEach((c) => c.classList.remove('selected'));
          renderSlots();
        });
      }
      dateCardsWrap.append(card);
      dateCards.push(card);
    }
  }
  renderDateCards();
  // Keep the hidden native date input (renderSlots/reset read its value) but
  // hide its visible field — the date cards are the primary picker now.
  datePick.wrap.hidden = true;
  stepDateTime.append(dateCardsWrap, slotGroup);
  const step2Actions = el('div', { className: 'mylikita-widget__step-actions' });
  const back2 = el('button', { type: 'button', className: 'mylikita-widget__cta mylikita-widget__cta-ghost', text: t.back });
  back2.addEventListener('click', () => showStep(1));
  const next2 = el('button', { type: 'button', className: 'mylikita-widget__cta', text: t.nextDetails });
  next2.addEventListener('click', () => { if (validateStep2()) showStep(3); });
  step2Actions.append(back2, next2);
  stepDateTime.append(step2Actions);

  // Step 3 — Patient details (+ appointment type, ANC, notes)
  stepDetails.append(
    el('h4', { className: 'mylikita-widget__step-title', text: t.step3Title }),
    el('p', { className: 'mylikita-widget__step-sub', text: t.step3Sub }),
    name.wrap,
    phoneEmail,
    visitType.wrap,
  );
  if (ancGroup) stepDetails.append(ancGroup);
  stepDetails.append(notes.wrap);
  const step3Actions = el('div', { className: 'mylikita-widget__step-actions' });
  const back3 = el('button', { type: 'button', className: 'mylikita-widget__cta mylikita-widget__cta-ghost', text: t.back });
  back3.addEventListener('click', () => showStep(2));
  const next3 = el('button', { type: 'button', className: 'mylikita-widget__cta', text: t.reviewAction });
  next3.addEventListener('click', () => { if (validateStep3()) showStep(4); });
  step3Actions.append(back3, next3);
  stepDetails.append(step3Actions);

  // Step 4 — Review + confirm
  const reviewCard = el('div', { className: 'mylikita-widget__review' });
  stepReview.append(
    el('h4', { className: 'mylikita-widget__step-title', text: t.step4Title }),
    el('p', { className: 'mylikita-widget__step-sub', text: t.step4Sub }),
    reviewCard,
  );
  const step4Actions = el('div', { className: 'mylikita-widget__step-actions' });
  const back4 = el('button', { type: 'button', className: 'mylikita-widget__cta mylikita-widget__cta-ghost', text: t.back });
  back4.addEventListener('click', () => showStep(3));
  const confirmBtn = el('button', { type: 'submit', className: 'mylikita-widget__cta', text: t.confirmLabel });
  step4Actions.append(back4, confirmBtn);
  stepReview.append(step4Actions);

  function refreshReview() {
    reviewCard.replaceChildren();
    const sel = getServiceSelection();
    const rows = [
      { k: t.confirmService, v: sel ? (sel.name || t.otherService) : '—' },
      {
        k: t.confirmDoctor,
        v: provider.input.value
          ? ((allProviders.find((p) => p.external_id === provider.input.value) || {}).name || provider.input.value)
          : t.noPreference,
      },
      { k: t.confirmVisit, v: visitTypeLabel(visitType.input.value) },
    ];
    const dt = datetime.input.value;
    if (dt) rows.push({ k: t.confirmWhen, v: formatApptDateTime(dt) });
    else if (datePick.input.value) rows.push({ k: t.confirmWhen, v: datePick.input.value });
    for (const r of rows) {
      const row = el('div', { className: 'mylikita-widget__review-row' });
      row.append(el('span', { className: 'mylikita-widget__review-k', text: r.k }), el('span', { className: 'mylikita-widget__review-v', text: r.v }));
      reviewCard.append(row);
    }
    const yours = el('div', { className: 'mylikita-widget__review-yours' });
    const yHead = el('div', { className: 'mylikita-widget__review-head', text: t.step3Title });
    const yLine = el('div', { className: 'mylikita-widget__review-line' });
    yLine.textContent = [name.input.value.trim(), phone.input.value.trim(), email.input.value.trim()].filter(Boolean).join(' · ') || '—';
    yours.append(yHead, yLine);
    reviewCard.append(yours);
  }

  function showStep(n) {
    currentStep = n;
    stepNodes.forEach((s, i) => { s.hidden = (i + 1) !== n; });
    progressItems.forEach((li, i) => {
      const done = (i + 1) < n;
      const active = (i + 1) === n;
      li.classList.toggle('done', done);
      li.classList.toggle('active', active);
      li.querySelector('.mylikita-widget__progress-dot').textContent = done ? '✓' : String(i + 1);
    });
    if (n === 4) refreshReview();
  }

  function validateStep1() {
    const sel = getServiceSelection();
    if (!sel || !sel.name) { setError(t.requiredService); return false; }
    setError(null);
    return true;
  }
  function validateStep2() {
    if (!datetime.input.value) { setError(t.requiredSlot); return false; }
    setError(null);
    return true;
  }
  function validateStep3() {
    if (!name.input.value.trim()) { setError(t.requiredName); return false; }
    const p = normalizePhone(phone.input.value);
    if (!p) { setError(t.requiredPhone); return false; }
    if (!isValidPhone(p)) { setError(t.invalidPhone); return false; }
    setError(null);
    return true;
  }

  // Rebuild the form so it reads: badge, error, progress, steps 1-4, hint.
  // The field nodes were re-parented into their step containers above, so
  // replaceChildren keeps them (now nested) — only the shell is rebuilt.
  // Keep the hidden `datetime` carrier in the DOM (not just on the JS node):
  // slot-chip clicks set datetime.input.value on the object, but any code that
  // reads the field by id (hosts, the CI harness's mlw-datetime, reset) needs
  // the element attached. It is invisible via the hidden attribute.
  form.replaceChildren(noAccountBadge, errorBox, progressBar, stepService, stepDateTime, stepDetails, stepReview, hint, datetime.wrap);
  submitRow.hidden = true; // the review step's Confirm button is the submitter
  showStep(1);

  // ── waitlist submit (Phase C6) ─────────────────────────────────────────
  // The waitlist button lives in the slots section (revealed when nothing is
  // free). It reuses the patient's name/phone/service from the form and posts
  // to the relay's /v1/waitlist; the hospital imports it on its next pull.
  waitlistBtn.addEventListener('click', async () => {
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
      try { sessionStorage.setItem(refKey, ref); } catch (_) { /* private mode */ }
      await createWaitlist({
        relayUrl: opts.relayUrl, websiteKey: opts.websiteKey, signal: pollCtrl?.signal,
        payload: {
          external_ref: ref,
          patient_name: pname,
          patient_phone: norm,
          patient_email: pemail || undefined,
          service_external_id: (sel && sel.external_id) || undefined,
          service_name: (sel && sel.name) || undefined,
          preferred_date: datePick.input.value,
          flexibility: 'any_day',
          notes: notes.input.value.trim() || undefined,
        },
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

    const sel = getServiceSelection();
    const payload = {
      facility_id: opts.facilityId,
      patient_name: name.input.value.trim(),
      patient_phone: phone.input.value.trim(),
      patient_email: email.input.value.trim(),
      provider_external_id: provider.input.value || undefined,
      service_name: (sel && sel.name) || undefined,
      // Phase C4 — a structured service id lets the hospital resolve the
      // service by code instead of free-text name.
      service_external_id: (sel && sel.external_id) || undefined,
      appt_datetime: datetime.input.value,
      visit_type: visitType.input.value || 'physical',
      duration_mins: (sel && sel.duration_mins) || opts.durationMins || undefined,
      notes: notes.input.value.trim() || undefined,
      // Phase C7 — campaign/channel source (only when a valid tag is set).
      source: opts.source || undefined,
    };

    // Antenatal booking — carry the ANC marker + LMP so the backend can
    // register the pregnancy and GA-anchor the visit (services/ancBooking.js).
    if (payload.visit_type === 'antenatal') {
      const lmp = ancLmp.input.value.trim();
      if (!lmp) return fail(t.ancRequiredLmp);
      if (Number.isNaN(Date.parse(`${lmp}T00:00:00Z`))) return fail(t.ancRequiredLmp);
      payload.booking_type = 'anc';
      payload.anc_lmp_date = lmp;
    }

    // Client-side validation (mirrors the relay's rules) BEFORE touching
    // storage, so an invalid form never mints/spends an external_ref. P0:
    // phone is now REQUIRED (the clinic confirms appointments over the
    // phone/WhatsApp) and must be a valid, normalized number.
    if (!payload.patient_name) return fail(t.requiredName);
    // `normalizedPhone` (not `phone`) — `phone` is the outer field control and
    // esbuild renames a shadowing local to a colliding identifier, which makes
    // the payload's `phone.input.value` reference a TDZ'd variable at runtime.
    const normalizedPhone = normalizePhone(payload.patient_phone);
    if (!normalizedPhone) return fail(t.requiredPhone);
    if (!isValidPhone(normalizedPhone)) return fail(t.invalidPhone);
    payload.patient_phone = normalizedPhone;
    if (!payload.appt_datetime || Number.isNaN(Date.parse(payload.appt_datetime))) return fail(t.requiredSlot);

    // Idempotency (§4): reuse the stored ref on refresh/resubmit, mint once.
    let external_ref = readStoredRef(refKey);
    if (!external_ref) {
      external_ref = opts.externalRef();
      try { sessionStorage.setItem(refKey, external_ref); } catch (_) { /* private mode */ }
    }
    payload.external_ref = external_ref;

    lastPayload = payload; // remember the booking for the confirmation screen
    pollCtrl = new AbortController();
    let bookingRef = null;
    try {
      const created = await createBooking({ relayUrl: opts.relayUrl, websiteKey: opts.websiteKey, payload, signal: pollCtrl.signal });
      bookingRef = created.booking_ref;
      if (created.duplicate) {
        // §4: same slot already booked by this patient — treat as success and
        // poll the EXISTING booking (resume from its booking_ref, never poll
        // an undefined ref).
        hint.textContent = '';
        showStatus('pending_confirmation', bookingRef, 'We found an existing booking request for this slot — checking it…');
      } else {
        if (opts.onBooking) safeCall(opts.onBooking, created, payload);
        showStatus('pending_confirmation', bookingRef, null);
      }
      startPoll(bookingRef);
    } catch (err) {
      if (!alive || err?.name === 'AbortError') return;
      const friendly = err.status === 429 ? t.rateLimited
        : (err.code === 'slot_unavailable' ? t.slotTaken : (err.message || t.networkError));
      if (opts.onError) safeCall(opts.onError, err);
      fail(friendly);
    }
  }

  async function startPoll(bookingRef) {
    // A booking ref is REQUIRED to poll. If the relay answered a duplicate 409
    // without carrying the existing booking_ref, polling /bookings/undefined
    // would 404 and mislead the patient into an error state — instead stop
    // quietly and leave the "request received" screen (the patient can retry
    // via 'Book another').
    if (!bookingRef) {
      submitting = false;
      return;
    }
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
    // Two-tone brand bar (brand→accent) — mirrors the hosted booking page's
    // gradient strip so the embed's status screen reads as the same page.
    const bar = el('div', { className: 'mylikita-widget__status-bar' });
    const icon = el('div', { className: `mylikita-widget__status-icon ${c.kind}` });
    icon.textContent = iconGlyph(c.kind);
    const st = el('p', { className: 'mylikita-widget__status-title', text: c.title });
    const msg = el('p', { className: 'mylikita-widget__status-message', text: messageOverride || c.message });
    const ref = el('p', { className: 'mylikita-widget__status-ref', text: bookingRef ? `Booking ref: ${bookingRef}` : '' });
    const nodes = [bar, icon, st, msg, ref];
    // Rich confirmation for the happy paths: appointment summary card + an
    // "Add to calendar" download and a "WhatsApp clinic" link.
    if (lastPayload && (status === 'pending_confirmation' || status === 'confirmed')) {
      const summary = buildSummaryCard(lastPayload);
      if (summary) nodes.push(summary);
      const actions = buildConfirmationActions(lastPayload, status === 'confirmed', bookingRef);
      if (actions) nodes.push(actions);
    }
    const again = el('button', { className: 'mylikita-widget__link-btn', type: 'button', text: t.bookAnother });
    again.addEventListener('click', () => reset());
    nodes.push(again);
    statusView.replaceChildren(...nodes);
  }

  // ── confirmation helpers (status view) ───────────────────────────────────
  // Summary rows card: When / Service / Doctor / Visit type for the booking.
  function buildSummaryCard(payload) {
    const rows = [
      { k: t.confirmWhen, v: formatApptDateTime(payload.appt_datetime) },
      { k: t.confirmService, v: payload.service_name || t.general },
      { k: t.confirmDoctor, v: providerLabelFor(payload.provider_external_id) },
      { k: t.confirmVisit, v: visitTypeLabel(payload.visit_type) },
    ].filter((r) => r.v);
    if (!rows.length) return null;
    const card = el('div', { className: 'mylikita-widget__confirm' });
    for (const r of rows) {
      const row = el('div', { className: 'mylikita-widget__confirm-row' });
      const k = el('div', { className: 'mylikita-widget__confirm-k', text: r.k });
      const v = el('div', { className: 'mylikita-widget__confirm-v', text: r.v });
      row.append(k, v);
      card.append(row);
    }
    return card;
  }

  function buildConfirmationActions(payload, confirmed, bookingRef) {
    const wrap = el('div', { className: 'mylikita-widget__confirm-actions' });
    const cal = el('button', { type: 'button', className: 'mylikita-widget__act', text: t.addToCalendar });
    cal.addEventListener('click', () => downloadIcs(payload, bookingRef, cal, t));
    wrap.append(cal);
    const waNum = waNumber(opts.whatsappNumber);
    if (waNum) {
      const wa = el('a', {
        className: 'mylikita-widget__act mylikita-widget__act-wa',
        attrs: { href: waClinicLink(waNum, payload, bookingRef, opts.clinicName), target: '_blank', rel: 'noopener' },
        text: t.whatsappClinic,
      });
      wrap.append(wa);
    }
    return wrap;
  }

  function providerLabelFor(ext) {
    if (!ext) return null;
    const p = allProviders.find((x) => x.external_id === ext);
    return (p && (p.name || p.label)) || ext;
  }

  function visitTypeLabel(type) {
    if (type === 'telemedicine') return t.visitTelemedicine;
    if (type === 'home_visit') return t.visitHome;
    if (type === 'antenatal') return t.visitAntenatal;
    return t.visitPhysical;
  }

  // Download a single-event .ics for the booked appointment.
  function downloadIcs(payload, bookingRef, btn, txt) {
    try {
      const title = [opts.clinicName, payload.service_name].filter(Boolean).join(' — ') || txt.title;
      const dur = Number.isFinite(Number(payload.duration_mins)) ? Number(payload.duration_mins) : 30;
      const ics = buildIcs(payload.appt_datetime, dur, title, payload.notes);
      const blob = new Blob([ics], { type: 'text/calendar;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = bookingRef ? `appointment-${bookingRef}.ics` : 'appointment.ics';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      setTimeout(() => URL.revokeObjectURL(url), 3000);
      const original = btn.textContent;
      btn.textContent = txt.calAdded;
      setTimeout(() => { btn.textContent = original; }, 2200);
    } catch (_) { /* calendar download unsupported — non-fatal */ }
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
    // P0 — reset the date + slot picker to a fresh today.
    datePick.input.value = '';
    datePick.input.min = toLocalDateValue(new Date());
    datetime.input.value = '';
    slotChips.replaceChildren();
    slotHint.textContent = t.selectDateHint;
    // Reset the waitlist panel (Phase C6) back to its default state.
    renderWaitlist(false);
    waitlistTitle.textContent = t.waitlistTitle;
    waitlistHint.textContent = t.waitlistHint;
    waitlistBtn.hidden = false;
    waitlistBtn.disabled = false;
    waitlistBtn.textContent = t.waitlistSubmit;
    // Reset the ANC sub-group (default back to the first visit type + hide).
    visitType.input.value = visitTypeOptions[0].value;
    if (ancLmp) ancLmp.input.value = '';
    if (syncAncVisibility) syncAncVisibility();
    // V2 — clear the service selection + date cards and return to step 1.
    if (service && service.input && service.input.value) service.input.value = '';
    selectedService = null;
    if (service && service.mode === 'select' && service.otherInput) {
      service.otherInput.value = '';
      if (service.otherWrap) service.otherWrap.hidden = true;
    }
    if (provider && provider.input) provider.input.value = '';
    if (typeof renderDateCards === 'function') renderDateCards();
    if (typeof showStep === 'function') showStep(1);
  }

  root.replaceChildren(brand, title, subtitle, form, statusView);

  // ── async provider + service load (Phase C2/C3, C4) ────────────────────
  // When loadProviders is on, fetch the facility's mapped doctors and service
  // registry and fill the dropdowns. Failures are non-fatal: the widget still
  // works with "No preference" / free-text service. The abort ties the fetch
  // to the widget's lifecycle so destroy() can't leak it.
  let destroyProvidersFetch = null;
  // Phase C7 — track the page/embed view on mount (best-effort) so the relay
  // can compute conversion-by-source. Never blocks or fails the widget.
  if (opts.trackView) {
    trackPageView({
      relayUrl: opts.relayUrl, websiteKey: opts.websiteKey, source: opts.source || null,
    });
  }
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
  if (opts.loadServices) {
    const svcCtrl = new AbortController();
    (async () => {
      try {
        const list = await fetchServices({
          relayUrl: opts.relayUrl,
          websiteKey: opts.websiteKey,
          signal: svcCtrl.signal,
        });
        if (alive && !svcCtrl.signal.aborted) setServiceList(list);
      } catch (err) {
        if (!alive || err?.name === 'AbortError') return;
        if (opts.onError) safeCall(opts.onError, err);
        // keep free-text service — a quiet fallback beats a broken form
      }
    })();
    const abort = () => svcCtrl.abort();
    if (destroyProvidersFetch) { const prev = destroyProvidersFetch; destroyProvidersFetch = () => { prev(); abort(); }; }
    else destroyProvidersFetch = abort;
  }

  // ── public API ──────────────────────────────────────────────────────────
  return {
    destroy() {
      alive = false;
      if (pollCtrl) pollCtrl.abort(); // stop the in-flight booking/poll immediately
      if (destroyProvidersFetch) destroyProvidersFetch(); // cancel the provider/service fetch
      cancelAvailability(); // stop any in-flight availability check
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

// Read the booking SOURCE (campaign/channel) off the page URL, e.g.
// ?source=instagram / ?source=whatsapp / ?source=poster. Sanitized to a short
// lowercase slug so it can never inject anything into analytics/labels; returns
// null when absent or invalid.
function readSourceFromUrl() {
  try {
    const v = new URLSearchParams(window.location.search).get('source');
    return v && /^[a-zA-Z0-9_-]{1,40}$/.test(String(v)) ? String(v).toLowerCase() : null;
  } catch (_) { return null; }
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

function toLocalDateValue(date) {
  const pad = (n) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

/**
 * Build the selectable time slots for a date from the facility's operating
 * hours. Returns `{ closed, slots }` where `closed` is true when the day is
 * outside `working_days` and `slots` is an array of "HH:MM" local strings.
 *
 * Operating hours shape (passed via the relay's `operatingHours` option):
 *   { working_days: [0-6], open_time: 'HH:MM', close_time: 'HH:MM', slot_duration: 30 }
 * When absent, defaults to Mon–Sat 09:00–17:00 at 30-minute steps. For
 * today, slots already in the past are dropped.
 */
function buildSlotsForDate(dateStr, oh, now) {
  const workingDays = Array.isArray(oh && oh.working_days) && oh.working_days.length
    ? oh.working_days
    : [1, 2, 3, 4, 5, 6];
  const day = new Date(`${dateStr}T00:00:00`).getDay();
  if (!workingDays.includes(day)) return { closed: true, slots: [] };

  const open = parseHM((oh && oh.open_time) || '09:00') || { h: 9, m: 0 };
  const close = parseHM((oh && oh.close_time) || '17:00') || { h: 17, m: 0 };
  const dur = Math.max(15, parseInt((oh && oh.slot_duration), 10) || 30);

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
  const m = /^(\d{1,2}):(\d{2})$/.exec(String(v || '').trim());
  if (!m) return null;
  const h = parseInt(m[1], 10);
  const mn = parseInt(m[2], 10);
  if (h > 23 || mn > 59) return null;
  return { h, m: mn };
}

function formatHM(minutesOfDay) {
  const pad = (n) => String(n).padStart(2, '0');
  return `${pad(Math.floor(minutesOfDay / 60))}:${pad(minutesOfDay % 60)}`;
}

/** Format a local 'YYYY-MM-DDTHH:MM' value into a readable "Tue, 15 Sep 2026 · 10:30 AM". */
function formatApptDateTime(localStr) {
  if (!localStr) return '';
  const [date, time] = String(localStr).split('T');
  const ymd = String(date).split('-');
  if (ymd.length !== 3) return localStr;
  const d = new Date(Number(ymd[0]), Number(ymd[1]) - 1, Number(ymd[2]));
  const dateLabel = Number.isNaN(d.getTime())
    ? date
    : d.toLocaleDateString(undefined, { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' });
  let timeLabel = time || '';
  const m = /^(\d{1,2}):(\d{2})/.exec(String(time));
  if (m) {
    let h = parseInt(m[1], 10);
    const mn = parseInt(m[2], 10);
    const ap = h >= 12 ? 'PM' : 'AM';
    h = h % 12 || 12;
    timeLabel = `${h}:${String(mn).padStart(2, '0')} ${ap}`;
  }
  return `${dateLabel} · ${timeLabel}`;
}

/** Build a single-event iCalendar (.ics) string from a local datetime + duration. */
function buildIcs(localStart, durMin, summary, notes) {
  const toIso = (v) => String(v).replace(/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}).*/, '$1$2$3T$4$5');
  const start = toIso(localStart);
  const end = toIso(addMinutesLocal(localStart, durMin));
  const nowIso = new Date().toISOString().replace(/(-|:|\.\d{3})/g, '').slice(0, 15);
  const uid = `mylikita-${Date.now()}@mylikita`;
  return [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//MyLikita//Booking//EN',
    'CALSCALE:GREGORIAN',
    'BEGIN:VEVENT',
    `UID:${uid}`,
    `DTSTAMP:${nowIso}`,
    `DTSTART:${start}`,
    `DTEND:${end}`,
    `SUMMARY:${escapeIcs(summary || 'Appointment')}`,
    notes ? `DESCRIPTION:${escapeIcs(notes)}` : 'DESCRIPTION:',
    'END:VEVENT',
    'END:VCALENDAR',
  ].join('\r\n');
}

function addMinutesLocal(localStr, mins) {
  const m = /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/.exec(String(localStr));
  if (!m) return localStr;
  const d = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]), Number(m[4]), Number(m[5]));
  d.setMinutes(d.getMinutes() + (Number.isFinite(Number(mins)) ? Number(mins) : 30));
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function escapeIcs(s) {
  return String(s || '').replace(/\\/g, '\\\\').replace(/;/g, '\\;').replace(/,/g, '\\,').replace(/\r?\n/g, '\\n');
}

/** Digits-only WhatsApp target, converting a leading 0 to the +234 country code. */
function waNumber(raw) {
  let d = String(raw || '').replace(/\D/g, '');
  if (d.startsWith('0')) d = '234' + d.slice(1);
  return d;
}

/** Build a wa.me link that sends the appointment summary to the clinic. */
function waClinicLink(num, payload, bookingRef, clinicName) {
  const lines = [];
  if (clinicName) lines.push(clinicName);
  if (bookingRef) lines.push(`Booking ref: ${bookingRef}`);
  const when = formatApptDateTime(payload && payload.appt_datetime);
  if (when) lines.push(when);
  if (payload && payload.service_name) lines.push(payload.service_name);
  const text = lines.filter(Boolean).join('\n');
  return `https://wa.me/${num}?text=${encodeURIComponent(text)}`;
}

/**
 * True when a candidate slot [start, start+dur) overlaps ANY already-booked
 * range in `booked` ([{ start, end }] in HH:MM). A 09:00 slot with a 30-min
 * service is blocked by a booking [08:45,09:15) or [09:00,09:30), but NOT by
 * one ending exactly at 09:00 or starting exactly at 09:30.
 */
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
  const m = /^(\d{1,2}):(\d{2})$/.exec(String(hm || ''));
  return m ? (parseInt(m[1], 10) * 60 + parseInt(m[2], 10)) : NaN;
}

/**
 * Normalize a phone number to E.164-ish for NG: strips separators, converts
 * local 0XXXXXXXXXX (11 digits) and XXXXXXXXXX (10 digits) to +234…, keeps an
 * explicit + prefix otherwise. Returns '' when nothing recognizable remains.
 */
function normalizePhone(raw) {
  let p = String(raw || '').trim().replace(/[^0-9+]/g, '');
  if (!p) return '';
  if (p.startsWith('+')) return p;
  if (p.startsWith('234') && p.length >= 12) return `+${p}`;
  if (p.length === 11 && p.startsWith('0')) return `+234${p.slice(1)}`;
  if (p.length === 10 && /^[789]/.test(p)) return `+234${p}`;
  return p;
}

/** Accept a normalized number with an international dial code and 8–15 digits. */
function isValidPhone(phone) {
  return /^\+\d{8,15}$/.test(String(phone || ''));
}

/**
 * Normalize a service list (Phase C4) into structured objects. Accepts either
 * plain strings (legacy `services: ['Consultation']`) or objects
 * `{ external_id, name, duration_mins, provider_external_ids }`. Invalid /
 * empty entries are dropped.
 */
function normalizeServices(list) {
  return (Array.isArray(list) ? list : [])
    .map((s) => {
      if (typeof s === 'string') {
        const v = s.trim();
        return v ? { external_id: v, name: v, duration_mins: null, provider_external_ids: [] } : null;
      }
      if (!s || typeof s !== 'object') return null;
      const ext = String(s.external_id || s.code || s.name || '').trim();
      const name = String(s.name || ext || '').trim();
      if (!ext || !name) return null;
      return {
        external_id: ext,
        name,
        duration_mins: Number.isFinite(Number(s.duration_mins)) ? Number(s.duration_mins) : null,
        provider_external_ids: Array.isArray(s.provider_external_ids) ? s.provider_external_ids : [],
      };
    })
    .filter(Boolean);
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
