/**
 * Theme hooks.
 *
 * The widget renders inside a `.mylikita-widget` container and every colour,
 * radius and font is a CSS custom property on that container. Agencies can
 * theme it two ways:
 *
 *   1. Programmatically: pass `theme: { primary: '#e91e63', ... }` to
 *      createBookingWidget() — the widget sets the CSS vars itself.
 *   2. Pure CSS: any stylesheet can set the vars on `.mylikita-widget` and
 *      they win (the widget only writes vars for values you passed).
 */

export const DEFAULT_THEME = {
  primary: '#0d6efd',
  primaryDark: '#0b5ed7',
  primaryText: '#ffffff',
  bg: '#ffffff',
  text: '#1e293b',
  muted: '#64748b',
  border: '#e2e8f0',
  danger: '#dc3545',
  success: '#15803d',
  radius: 10,
  font: "system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif",
};

/**
 * Map a (partial) theme object to CSS custom properties, merged over the
 * defaults. Unknown keys are ignored; `radius` is a number → `${n}px`.
 */
export function resolveTheme(theme = {}) {
  const t = { ...DEFAULT_THEME, ...(theme || {}) };
  return {
    '--mlw-primary': t.primary,
    '--mlw-primary-dark': t.primaryDark,
    '--mlw-primary-text': t.primaryText,
    '--mlw-bg': t.bg,
    '--mlw-text': t.text,
    '--mlw-muted': t.muted,
    '--mlw-border': t.border,
    '--mlw-danger': t.danger,
    '--mlw-success': t.success,
    '--mlw-radius': `${t.radius}px`,
    '--mlw-font': t.font,
  };
}
