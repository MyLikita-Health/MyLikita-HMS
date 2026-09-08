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
  // Second tone of the facility's two-tone brand — the relay's hosted booking
  // page themes its gradient strip / avatar with brand→accent, and the
  // widget mirrors that on its status screen (see styles.js). The hosted
  // page's own default accent is #0d9488, kept here so an un-themed widget
  // matches the default hosted page.
  accent: '#0d9488',
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
 *
 * The hosted booking page and the facility Settings card call the second
 * tone `secondary` (its relay column is `secondary_color`) — accepted here
 * as an alias for `accent` so embeds booted by the hosted page pick the
 * clinic's accent up unchanged. A real `accent` key wins over `secondary`.
 */
export function resolveTheme(theme = {}) {
  const raw = theme || {};
  const accent = raw.accent ?? raw.secondary ?? DEFAULT_THEME.accent;
  const t = { ...DEFAULT_THEME, ...raw, accent };
  return {
    '--mlw-primary': t.primary,
    '--mlw-primary-dark': t.primaryDark,
    '--mlw-primary-text': t.primaryText,
    '--mlw-accent': t.accent,
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
