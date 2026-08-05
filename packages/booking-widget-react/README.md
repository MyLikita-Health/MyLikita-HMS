# @mylikita/booking-widget-react

React component wrapper around
[`@mylikita/booking-widget`](/packages/booking-widget) — appointment booking
for React hospital websites that syncs through the **MyLikita relay**. Agency
sites built in React (Next.js, Vite, CRA, Gatsby…) can drop in a single
component:

```jsx
<BookingWidget
  relayUrl="https://api.mylikita.clinic"
  websiteKey="wk_9f2k…"   // public client id — not a secret
  facilityId="F1"
  loadProviders          // populate the doctor dropdown from the relay
/>
```

The component renders the vanilla widget's form, submits through
`POST /v1/bookings`, and polls `GET /v1/bookings/:ref` until the hospital
confirms, cancels, reschedules, no-shows, or the request expires. It implements
the [MyLikita Website Booking API (v1)](/backend/WEBSITE_BOOKING_API.md)
exactly — same auth, same fields, same idempotency, same statuses.

---

## Install

```bash
npm install @mylikita/booking-widget-react
```

`react` and `react-dom` are peer dependencies — bring your own (≥ 16.8).

## Usage

```jsx
import { useRef } from 'react';
import BookingWidget from '@mylikita/booking-widget-react';

export default function BookAppointment() {
  const widgetRef = useRef(null);
  return (
    <BookingWidget
      ref={widgetRef}
      relayUrl="https://api.mylikita.clinic"
      websiteKey="wk_9f2k…"
      facilityId="F1"
      providers={[{ external_id: 'dr-khalil', label: 'Dr. Khalil' }]}
      services={['General consultation', 'Dental check-up']}
      theme={{ primary: '#0d9488' }}
      onBooking={(b) => console.log('booked', b.booking_ref)}
      onStatus={(s) => console.log('status →', s.status)}
      onError={(e) => console.error(e)}
    />
  );
}
```

## Props

All option props map 1:1 onto the vanilla widget's options (see the
[vanilla README](/packages/booking-widget/README.md) for the full reference).

| Prop | Type | Default | Description |
|---|---|---|---|
| `relayUrl` | string | — | **required** — relay base URL, e.g. `https://api.mylikita.clinic` |
| `websiteKey` | string | — | **required** — your public client id (Bearer on every request) |
| `facilityId` | string | — | **required** — the hospital's public facility id |
| `providers` | array | `[]` | `[{ external_id, label }]` — static doctor list; wins over `loadProviders` |
| `loadProviders` | bool | `false` | fetch the facility's mapped providers from the relay on mount (`GET /v1/providers`) |
| `services` | array | `[]` | service select options (free-text input otherwise) |
| `durationMins` | number | `30` | sent with the booking |
| `pollIntervalMs` | number | `5000` | how often to poll booking status |
| `maxTries` | number | `12` | poll budget; the widget then shows "request received" |
| `theme` | object | defaults | CSS-variable overrides, see [Theming](#theming) |
| `text` | object | defaults | i18n overrides for every label/message |
| `externalRef` | fn | auto | override the idempotency-key generator |
| `onBooking` | fn | — | `(booking, payload) => …` once the relay accepted it |
| `onStatus` | fn | — | `(statusObj) => …` on each poll result |
| `onError` | fn | — | `(err) => …` on create/poll failure |
| `className` / `style` | — | — | applied to the wrapper container div |

Any other props (`id`, `data-*`, `aria-*`, …) are passed through to the
container div.

### Re-render behaviour

- **Callbacks** (`onBooking`/`onStatus`/`onError`) may change identity freely —
  they are kept in a ref and never tear down the widget, so inline arrows in
  the parent are fine.
- **Data options** (everything else) are compared by JSON value. Only a real
  change recreates the widget (tears down + re-mounts), so passing a new
  array/object literal each render does not rebuild the form.

## Imperative handle (`ref`)

| Method | Returns | Description |
|---|---|---|
| `reset()` | void | clear the form back to its initial state |
| `getForm()` | `{ name, phone, email }` | current form values |
| `destroy()` | void | tear down the widget early |
| `getWidget()` | object | the raw vanilla widget `{ destroy, reset, getForm }` |

## SSR / Next.js

The component is SSR-safe — nothing touches the DOM until the browser effect
runs, so server rendering produces an empty container. With Next.js App Router,
import it dynamically with `ssr: false` if you want to avoid hydration
mismatch warnings:

```jsx
import dynamic from 'next/dynamic';
const BookingWidget = dynamic(() => import('@mylikita/booking-widget-react'), { ssr: false });
```

## Theming

Every colour, radius and font is a CSS custom property scoped to
`.mylikita-widget` — restyle from your own stylesheet or via the `theme` prop:

```jsx
<BookingWidget
  relayUrl="https://api.mylikita.clinic"
  websiteKey="wk_…"
  facilityId="F1"
  theme={{ primary: '#e91e63', radius: 6, bg: '#fffaf5' }}
/>
```

See the vanilla README for the full variable list.

## Demo

`dist/react-demo.html` runs the component **fully offline** against an in-page
mock relay — react, react-dom and the widget are all inlined, so it works from
`file://` with no server and no network. Build it with:

```bash
npm run build && npm run build:demo
```

## Development

```bash
npm run build   # esbuild → dist/ (esm + cjs; react & the widget stay external)
npm test        # jsdom harness: mounts the component, exercises submit/poll/destroy/refs
```

`dist/` is committed so the package works before any install; rebuild after
touching `src/`. The test resolves react/jsdom/esbuild from the monorepo's
`frontend/node_modules` — no separate install needed.

## Security notes

- `websiteKey` is a **public client id by design** (it ships in browser JS).
  The relay rate-limits per key and scopes it to the facility.
- The widget never receives or stores hospital patient data — only what the
  patient typed into the form.
