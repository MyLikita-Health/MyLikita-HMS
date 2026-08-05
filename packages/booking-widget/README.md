# @mylikita/booking-widget

Drop-in appointment booking for hospital websites built on MyLikita. A
zero-dependency vanilla-JS widget (no framework required) that:

1. renders a booking form into any element on your page,
2. submits through the **MyLikita relay** (`POST /v1/bookings`),
3. polls the booking (`GET /v1/bookings/:ref`) until the hospital confirms,
   cancels, reschedules, marks no-show, or the request expires.

It implements the [MyLikita Website Booking API (v1)](/backend/WEBSITE_BOOKING_API.md)
exactly — same auth, same fields, same idempotency rules, same statuses.

---

## Install

**Script tag (simplest for agency sites):**

```html
<script src="https://unpkg.com/@mylikita/booking-widget"></script>
<div id="booking"></div>
<script>
  MyLikitaBookingWidget.createBookingWidget(document.getElementById('booking'), {
    relayUrl: 'https://api.mylikita.clinic',
    websiteKey: 'wk_9f2k…',        // public client id — not a secret
    facilityId: 'F1',
  });
</script>
```

**npm (for bundlers):**

```bash
npm install @mylikita/booking-widget
```

```js
import { createBookingWidget } from '@mylikita/booking-widget';
createBookingWidget(document.getElementById('booking'), { relayUrl, websiteKey, facilityId });
```

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `relayUrl` | string | — | **required** — relay base URL, e.g. `https://api.mylikita.clinic` |
| `websiteKey` | string | — | **required** — your public client id (Bearer on every request) |
| `facilityId` | string | — | **required** — the hospital's public facility id |
| `providers` | array | `[]` | `[{ external_id, label }]` — shown as a "Preferred doctor" select; unmapped slugs simply arrive unassigned (never block on them) |
| `services` | array | `[]` | `['General consultation', …]` — shown as a service select (free-text input otherwise) |
| `durationMins` | number | `30` | sent with the booking |
| `pollIntervalMs` | number | `5000` | how often to poll the booking status |
| `maxTries` | number | `12` | poll budget (~1 min at the default); the widget then shows "request received" |
| `theme` | object | defaults | see [Theming](#theming) |
| `text` | object | defaults | i18n overrides for every label/message (see `src/widget.js` `DEFAULT_TEXT`) |
| `externalRef` | fn | auto | override the idempotency-key generator |
| `onBooking` | fn | — | `(booking, payload) => …` called once the relay accepted it |
| `onStatus` | fn | — | `(statusObj) => …` called on each poll result |
| `onError` | fn | — | `(err) => …` on create failure |

Returns `{ destroy(), reset(), getForm() }`.

## Idempotency & double-submit (built in)

- An `external_ref` is minted (`BK-<ts>-<rand>`) and stored in `sessionStorage`
  **before** submitting, so a page refresh resubmits the *same* booking instead
  of creating a duplicate — the relay returns the original `booking_ref`.
- A genuine double-click on a fresh page hits the relay's
  `409 duplicate_booking`; the widget treats that as success and polls the
  existing booking, showing "We found an existing booking request for this slot".
- The stored ref is cleared once the booking reaches a terminal state, so the
  next booking mints a fresh one.

## Statuses

| Widget shows | When |
|---|---|
| Request received (spinner) | hospital hasn't collected it, or still pending after the poll budget |
| Confirmed ✓ | `confirmed` |
| Cancelled / Rescheduled / Missed | corresponding terminal status |
| Request expired | hospital never collected within 72 h (offline server) — "please call the clinic" |

## Theming

Every colour, radius and font is a CSS custom property scoped to
`.mylikita-widget`, so you can restyle it from your own stylesheet without
specificity fights:

```css
.mylikita-widget {
  --mlw-primary: #0d9488;      /* buttons, focus rings, accents */
  --mlw-primary-dark: #0f766e; /* hover state */
  --mlw-primary-text: #ffffff; /* button label */
  --mlw-bg: #ffffff;           /* widget background */
  --mlw-text: #1e293b;         /* labels + values */
  --mlw-muted: #64748b;        /* secondary text */
  --mlw-border: #e2e8f0;       /* inputs + widget border */
  --mlw-danger: #dc3545;
  --mlw-success: #15803d;
  --mlw-radius: 10px;          /* input + button radius */
  --mlw-font: system-ui, …;
}
```

Or programmatically:

```js
createBookingWidget(el, {
  relayUrl, websiteKey, facilityId,
  theme: { primary: '#e91e63', radius: 6, bg: '#fffaf5' },
});
```

## Demo

`demo/demo.html` runs the widget **fully offline** against an in-page mock of
the relay — submit a booking and watch it flip to *confirmed* after two polls.
Open it in a browser directly:

```bash
open packages/booking-widget/demo/demo.html
```

## Development

```bash
npm run build   # esbuild → dist/ (iife, iife.min, esm, cjs)
npm test        # mocked-fetch suite for the core logic
```

`dist/` is committed so the package works before any install; rebuild after
touching `src/`.

## Security notes

- `websiteKey` is a **public client id by design** (it ships in browser JS).
  It is rate-limited per key on the relay and scoped to the facility. Real
  protection against abuse is the relay's per-key rate limits, not secrecy.
- The widget never receives or stores hospital patient data — only what the
  patient typed into your form.
