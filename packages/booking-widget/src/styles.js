/**
 * Widget styles, injected once per document as a <style id="mylikita-widget-styles">.
 * Everything is scoped under `.mylikita-widget` and driven by CSS custom
 * properties (see theme.js) so host pages can restyle without fighting
 * specificity wars.
 */
export const STYLES = `
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
/* Date + time-slot picker (P0) — a native date input plus selectable chips. */
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
/* Taken slots — shown struck-through and disabled so patients see the whole
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

/* Waitlist panel (Phase C6) — revealed under the slots when nothing is free. */
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

/* ANC sub-group (antenatal booking, ancBooking option) — visually distinct
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

/* status view — carries the facility's two-tone brand (brand→accent),
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
/* "info" is the pending/processing state — it wears the two-tone gradient
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

/* V2 guided flow — 4-step progress indicator */
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

/* Date cards — horizontally scrollable day picker */
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
/* Unavailable (closed) days — clearly muted and non-interactive: reduced
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

/* Review step — appointment summary + patient details */
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
