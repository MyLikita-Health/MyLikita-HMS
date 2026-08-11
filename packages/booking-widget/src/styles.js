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
