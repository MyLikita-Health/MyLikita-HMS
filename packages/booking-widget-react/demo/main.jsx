/**
 * Demo entry for @mylikita/booking-widget-react. Bundled by build-demo.mjs
 * (react + react-dom + the widget are inlined) into dist/react-demo.html, a
 * fully self-contained page that runs offline against an in-page mock relay.
 */
import React, { useRef, useState } from 'react';
import ReactDOM from 'react-dom';
import BookingWidget from '../src/index.jsx';

// ── in-page mock relay (implements the v1 contract). Demo-only — a real page
//    points the widget at the actual relay URL and must NOT override fetch. ──
const bookings = new Map();
let seq = 0;

function json(status, body) {
  return Promise.resolve(new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } }));
}

const mockRelay = async (url, init) => {
  const method = (init && init.method) || 'GET';
  const u = new URL(url, location.href);

  if (method === 'POST' && u.pathname === '/v1/bookings') {
    const body = JSON.parse(init.body);
    const existing = [...bookings.values()].find((b) => b.external_ref === body.external_ref);
    if (existing) return json(201, { booking_ref: existing.booking_ref, status: 'pending_confirmation' });
    const booking_ref = 'MLB-' + (++seq).toString(36).toUpperCase();
    bookings.set(booking_ref, { ...body, booking_ref, external_ref: body.external_ref, polls: 0 });
    return json(201, { booking_ref, status: 'pending_confirmation' });
  }

  if (method === 'GET' && u.pathname === '/v1/providers') {
    return json(200, {
      facility_id: 'F1',
      providers: [
        { external_id: 'dr-khalil', name: 'Dr. Khalil', specialty: 'General medicine' },
        { external_id: 'dr-amina', name: 'Dr. Amina', specialty: 'Dentistry' },
      ],
    });
  }

  if (method === 'GET' && u.pathname.startsWith('/v1/bookings/')) {
    const ref = decodeURIComponent(u.pathname.split('/').pop());
    const b = bookings.get(ref);
    if (!b) return json(404, { error: 'not_found' });
    b.polls += 1;
    const status = b.polls >= 2 ? 'confirmed' : 'pending_confirmation';
    return json(200, { booking_ref: ref, status, appt_ref: status === 'confirmed' ? 'APT-REACT123' : undefined });
  }

  return json(500, { error: 'server_error', message: 'mock relay: unhandled ' + method + ' ' + url });
};

window.fetch = (url, init) => mockRelay(url, init);

// ── demo app ────────────────────────────────────────────────────────────────
const KEY = 'wk_demo_public_key';
const FACILITY = 'F1';

function Log({ lines }) {
  return <pre className="log">{lines.join('\n')}</pre>;
}

function Demo() {
  const [logLines, setLogLines] = useState(['[demo] ready — submit a booking; it flips to confirmed after two polls.']);
  const [theme, setTheme] = useState({ primary: '#0d9488', primaryDark: '#0f766e' });
  const w2Ref = useRef(null);

  const addLog = (line) => setLogLines((prev) => [line, ...prev].slice(0, 60));

  return (
    <div className="demo">
      <h1>@mylikita/booking-widget-react — offline demo</h1>
      <p className="tagline">
        Two <code>&lt;BookingWidget/&gt;</code> components against an in-page mock relay: submit a booking,
        watch the poll loop, and it flips to <b>confirmed</b> after two polls. No backend needed.
      </p>

      <div className="cards">
        <div className="panel">
          <h2>Widget (default theme)</h2>
          <BookingWidget
            relayUrl="https://api.mylikita.com"
            websiteKey={KEY}
            facilityId={FACILITY}
            providers={[
              { external_id: 'dr-khalil', label: 'Dr. Khalil' },
              { external_id: 'dr-amina', label: 'Dr. Amina' },
            ]}
            services={['General consultation', 'Dental check-up', 'X-ray']}
            pollIntervalMs={800}
            maxTries={20}
            onBooking={(b) => addLog('[widget 1] booked → ' + b.booking_ref)}
            onStatus={(s) => addLog('[widget 1] status → ' + s.status + (s.appt_ref ? ' (' + s.appt_ref + ')' : ''))}
          />
        </div>

        <div className="panel">
          <h2>Second widget (themed, loadProviders) + live log</h2>
          <BookingWidget
            ref={w2Ref}
            relayUrl="https://api.mylikita.com"
            websiteKey={KEY}
            facilityId={FACILITY}
            loadProviders
            pollIntervalMs={800}
            maxTries={20}
            theme={theme}
            onBooking={(b) => addLog('[widget 2] booked → ' + b.booking_ref)}
            onStatus={(s) => addLog('[widget 2] status → ' + s.status)}
            onError={(e) => addLog('[widget 2] error (non-fatal): ' + e.message)}
          />
          <div className="theme-row">
            <button onClick={() => setTheme({ primary: '#0d9488', primaryDark: '#0f766e' })}>Teal</button>
            <button onClick={() => setTheme({ primary: '#ea580c', primaryDark: '#c2410c' })}>Sunset</button>
            <button onClick={() => w2Ref.current && w2Ref.current.reset()}>Reset form</button>
          </div>
          <Log lines={logLines} />
        </div>
      </div>
    </div>
  );
}

ReactDOM.render(<Demo />, document.getElementById('root'));
