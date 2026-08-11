/**
 * Brand assets for the widget.
 *
 * The MyLikita mark is embedded as a base64 data URI (not a network fetch) so
 * the widget is fully self-contained — no extra HTTP request, works offline,
 * and renders identically on every host page regardless of their origin.
 * The vector mark stays razor-sharp at any size.
 *
 * The mark (frontend/public/icons/mylikita-mark.svg) is a 6-block pixel-art
 * symbol: dark #0169DA top bar + upper arms, light #0498FB lower arms +
 * bottom bar, with the hollow middle gap preserved.
 *
 * The data URI is base64 of that exact SVG (no URL-encoding pitfalls — the
 * SVG contains `#` and `"` which would need escaping in a raw data URI).
 */

/** Base64 data URI of the MyLikita mark — embed directly in an <img src>. */
export const MYLIKITA_MARK_DATA_URI =
  'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0ODMgODA0IiB3aWR0aD0iNDgzIiBoZWlnaHQ9IjgwNCIgcm9sZT0iaW1nIiBhcmlhLWxhYmVsPSJNeUxpa2l0YSI+CiAgICA8cmVjdCB4PSIxNjEiIHk9IjAiIHdpZHRoPSIxNjEiIGhlaWdodD0iMTYxIiBmaWxsPSIjMDE2OURBIi8+CiAgICA8cmVjdCB4PSIwIiB5PSIxNjAiIHdpZHRoPSIxNjIiIGhlaWdodD0iMTYxIiBmaWxsPSIjMDE2OURBIi8+CiAgICA8cmVjdCB4PSIzMjEiIHk9IjE2MCIgd2lkdGg9IjE2MiIgaGVpZ2h0PSIxNjEiIGZpbGw9IiMwMTY5REEiLz4KICAgIDxyZWN0IHg9IjAiIHk9IjQ4MiIgd2lkdGg9IjE2MiIgaGVpZ2h0PSIxNjIiIGZpbGw9IiMwNDk4RkIiLz4KICAgIDxyZWN0IHg9IjMyMSIgeT0iNDgyIiB3aWR0aD0iMTYyIiBoZWlnaHQ9IjE2MiIgZmlsbD0iIzA0OThGQiIvPgogICAgPHJlY3QgeD0iMTYxIiB5PSI2NDMiIHdpZHRoPSIxNjEiIGhlaWdodD0iMTYxIiBmaWxsPSIjMDQ5OEZCIi8+Cjwvc3ZnPg==';

/**
 * Build the widget header branding: the MyLikita mark + "MyLikita" wordmark.
 * Returns a <div class="mylikita-widget__brand"> with the mark <img> and a
 * wordmark <span> — styled by styles.js, themeable via the widget's CSS vars.
 */
export function createBrandHeader() {
  const header = document.createElement('div');
  header.className = 'mylikita-widget__brand';
  const img = document.createElement('img');
  img.className = 'mylikita-widget__brand-mark';
  img.src = MYLIKITA_MARK_DATA_URI;
  img.alt = 'MyLikita';
  img.width = 24;
  img.height = 24;
  const word = document.createElement('span');
  word.className = 'mylikita-widget__brand-word';
  word.textContent = 'MyLikita';
  header.append(img, word);
  return header;
}
