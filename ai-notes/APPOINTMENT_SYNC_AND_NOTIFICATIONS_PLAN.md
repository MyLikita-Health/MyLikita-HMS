# Appointment Module — Multi-Channel Notifications & Website Sync (Design & Implementation Plan)

**Date:** 2026-08-05 · **Status:** Design / proposal — no code written yet
**Applies to:** offline on-premise installs, cloud multi-tenant MyLikita, self-hosted single-tenant servers, and hospital websites (ours or third-party)
**Review:** architecture-reviewed 2026-08-05; findings folded into sections 4–9 (marked **REV**) — see section 10 for the full list

---

## 0. Executive summary

A hospital running MyLikita — offline, cloud, or self-hosted — wants two things:

1. **Every appointment lifecycle event notifies the people involved**, over **SMS (Termii)**, **WhatsApp (Termii)**, and **email (Resend)** — both the **patient** and the **doctor/provider** concerned.
2. **Appointments booked on the hospital's public website** (whether we built the site or a third-party agency did) **appear automatically in the hospital's MyLikita appointment dashboard**.

The core difficulty: **offline installs sit behind a NAT/firewall and cannot receive inbound connections**, so a website can never push a booking *directly into* the hospital's server. The answer is a **cloud relay + pull sync**:

> The website books into a **cloud relay** (always reachable). The hospital's MyLikita server — online or offline — **pulls** pending bookings from the relay on an interval, writes them into `appt_master`, then **pushes status changes back** to the relay, which the website displays. Every sync hop is idempotent, retried with backoff, and secured by a per-facility sync key.

The same relay architecture also covers the cloud and self-hosted cases (they can just pull on a shorter interval), and it gives **one uniform integration contract** that third-party website builders can implement against.

---

## 1. Goals & non-goals

### Goals
- **G1 — Notify both sides, all channels.** On book / confirm / reschedule / cancel / no-show / complete: patient gets SMS + WhatsApp + email; assigned provider gets the same (plus in-app bell). Channel mix is per-facility and per-recipient configurable.
- **G2 — Website → dashboard sync.** Any appointment booked on the hospital's website lands on the appointment dashboard automatically (status `pending_confirmation`, source `website`), with the patient's confirmation link working exactly as for in-app bookings.
- **G3 — Dashboard → website sync.** When staff confirm/cancel/reschedule, the website reflects it (patient sees "confirmed ✓" or "cancelled" when they check their booking).
- **G4 — Works in every deployment:** offline on-prem, cloud multi-tenant, self-hosted single server.
- **G5 — One contract, third-party friendly.** A website agency only needs one documented REST contract + one facility sync key; no knowledge of MyLikita internals.

### Non-goals (v1)
- Real-time push *into* offline servers (impossible behind NAT without a tunnel — out of scope; pull interval + configurable frequency is the answer).
- Bi-directional full appointment calendar mirroring (e.g. two-way edits from website). Website is **booking-in / status-out** only in v1.
- Patient-facing reschedule/cancel from the website (only confirm/decline via token link, as today).
- WhatsApp via Meta official API (we use **Termii WhatsApp** — one vendor for SMS + WhatsApp).

---

## 2. Current state (what exists today)

| Capability | Where | Status |
|---|---|---|
| Central appointment index (`appt_master`) with lifecycle statuses | `migrations/20260506000001-central-appointment-hub.js` | ✅ live |
| Hub UI: queue / calendar / waitlist / providers / analytics | `frontend/src/components/appointments/` | ✅ live |
| Public booking: `POST /appointments/public/book` (source `website`, status `pending_confirmation`) + confirm token link | `backend/controller/appointments-public.js` | ✅ live, **no auth** |
| Confirmation reminders queued (sms + email) on public booking | `appointments-public.js::book` | ✅ live |
| Reminder queue cron (5 min) — channels **sms / email / in_app** | `backend/services/appointmentReminders.js` | ✅ live |
| `whatsapp` channel declared in `appt_reminders_queue` schema | hub migration line 183 | ⬜ **unused** |
| SMS via **Termii** (`TERMII_API_KEY`), email via **Resend** (`RESEND_API_KEY`) | `services/smsApi.js`, `config/nodemailer.js` | ✅ just migrated |
| In-app notifications with rule-based recipients | `services/notificationService.js` | ✅ live |
| Provider registry with **`user_id`** column (provider → login link) | `appt_providers` | ✅ live (used by hub providers tab) |
| Module write-through adapter (dental/radiology/theatre → hub) | `services/apptSync.js` | 🔄 partial |
| Per-facility settings table | `facility_settings` (Phase 3) | ✅ live |
| Facility identity | `hospitals` table + `facilityId` strings | ✅ |
| Facility API keys / webhook / relay concept | — | ⬜ **does not exist** |

### Gaps this plan closes
1. No WhatsApp sending (channel exists, nothing reads it).
2. No **direct notifications to the doctor/provider** (only in-app rule-based bell; no SMS/WhatsApp/email to the provider's phone/email).
3. Public booking is **unauthenticated and facilityId-only** — anyone who knows a facilityId can book (Phase-1 deferred rate limit item 7). The relay design introduces real credentials.
4. No path for a website to see the *outcome* of a booking (confirmed/cancelled).
5. No outbound sync for offline installs.

---

## 3. Architecture overview

```
                        ┌──────────────────────────────┐
                        │   CLOUD RELAY (ours)         │
                        │  api.mylikita.clinic         │
                        │  • in_master (website→local) │
                        │  • out_master (local→website)│
                        │  • facility registry + keys  │
                        └───────┬──────────┬───────────┘
                                │          │
              (HTTPS, sync key) │          │ (HTTPS, sync key)
               pull every N min │          │ push on change
                                ▼          ▼
               ┌──────────────────┐   ┌──────────────────┐
               │ HOSPITAL MyLikita │   │ HOSPITAL WEBSITE │
               │ server (any dep) │   │ (ours or 3rd-pty) │
               │  local DB + cron  │   │  booking widget   │
               └──────────────────┘   └──────────────────┘
```

- **Relay is the rendezvous point.** It is the only piece that must be publicly reachable. It stores **minimal PHI** (name, phone/email for notification routing, appointment datetime, status, refs) for a short window, never full clinical data.
- **Hospital server pulls** (`GET /in/feed?facility=…&since=<cursor>` → creates appt_master rows) and **pushes** (`POST /out/feed` with status changes). Offline servers just pull less often; cloud/self-hosted can pull every 30–60 s.
- **Website pushes** bookings to the relay (`POST /bookings` with facility sync key) and **polls** (`GET /bookings/{ref}`) for status to show the patient.
- **Notifications never depend on the relay**: they fire from the hospital server's own cron (Termii/Resend) exactly as they do today — offline-safe. The relay only moves *appointment data*.

---

## 4. Component design

### 4.1 Facility sync identity & credentials (new)

**New columns on `hospitals`** (migration):

```sql
ALTER TABLE hospitals
  ADD COLUMN sync_key         VARCHAR(64)  DEFAULT NULL,   -- per-facility secret (random, bcrypt-hashed at rest)
  ADD COLUMN relay_configured TINYINT(1)   DEFAULT 0,      -- site/admin opted in
  ADD COLUMN website_domain   VARCHAR(255) DEFAULT NULL;    -- optional: allowed origin for webhook CORS
```

- `sync_key` = `crypto.randomBytes(32).toString('hex')`, stored **bcrypt-hashed** like a password (**REV:** HMAC is wrong here — verifying an HMAC requires storing the signing pepper, which defeats "hashed at rest"; bcrypt/argon2 is the correct primitive). The plaintext is shown **once** at generation (super-admin UI) and at offline-install claim time.
- Cloud tenants get one from the super-admin console. Offline installs get one during **onboarding/claim** (the existing claim wizard already registers the facility on the platform — we piggyback key issuance there).
- All relay endpoints require `Authorization: Bearer <sync_key>` (or `X-Facility-Id` + signed payload).

**Two keys, two trust levels:**

| Key | Holder | Trust | Protection |
|---|---|---|---|
| `sync_key` (server↔relay) | Hospital server (`.env`) | Secret | bcrypt at rest; shown once; rotation UI; installer writes with file ACL |
| `website_key` (website↔relay) | Public website (browser JS) | **Non-secret client identifier** | **REV:** it ships in browser JS, so anyone can read it — treat it as a public id, rely on per-key rate limits + honeypot/CAPTCHA, never on its secrecy |

**REV — the legacy public booking endpoint must be gated.** `POST /appointments/public/book` remains unauthenticated and facilityId-only today. On cloud/self-hosted it is directly reachable, which makes the "website_key stops spam" story hollow. Phase B must: (a) apply `apiLimiter` (already exists in `middleware/rateLimit.js`) to it, (b) require a facility key (accept either the public `website_key` or the old unauthenticated mode behind a per-facility toggle defaulting OFF), or (c) retire it in favor of the relay contract for website traffic. Recommend (a) + (c): keep the endpoint for backward compat behind `apiLimiter`, but stop advertising it; all new website integrations use the relay.

### 4.2 The relay data model (cloud side)

Three small tables (live on the cloud DB, not shipped to offline installs):

```sql
-- Inbound: website bookings waiting to be pulled by the hospital server
CREATE TABLE relay_in_master (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  facilityId      VARCHAR(100) NOT NULL,
  external_ref    VARCHAR(64)  NOT NULL,          -- website's own booking id (idempotency)
  patient_name    VARCHAR(200),
  patient_phone   VARCHAR(30),
  patient_email   VARCHAR(200),
  provider_external_id VARCHAR(64),               -- website's provider id
  service_name    VARCHAR(200),
  appt_datetime   DATETIME NOT NULL,
  duration_mins   INT DEFAULT 30,
  visit_type      VARCHAR(20) DEFAULT 'physical',
  notes           VARCHAR(500),
  status          ENUM('new','delivered','failed') DEFAULT 'new',
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  delivered_at    DATETIME NULL,
  UNIQUE KEY uq_facility_ext (facilityId, external_ref)
);

-- Outbound: hospital status changes awaiting the website
CREATE TABLE relay_out_master (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY,
  facilityId   VARCHAR(100) NOT NULL,
  appt_ref     VARCHAR(64)  NOT NULL,
  external_ref VARCHAR(64),
  status       VARCHAR(30)  NOT NULL,             -- confirmed/cancelled/rescheduled/no_show
  changed_at   DATETIME     NOT NULL,
  UNIQUE KEY uq_ref (facilityId, appt_ref)
);
```

Plus a per-facility **cursor** (last pulled `relay_in_master.id`) stored server-side in the relay (`relay_cursors`), so pulls are incremental and cheap.

**Why a table instead of the website writing straight to the hospital API:** the hospital server is unreachable when offline; the relay buffers until the server's next pull. This is a classic **outbox / message-queue** pattern, implemented with plain tables + HTTP so third parties can integrate with zero SDK.

**REV — dual path for reachable deployments.** Cloud and self-hosted servers *with a public address* don't need the relay buffer at all: the website (or relay) can POST the booking directly to the hospital API for near-real-time delivery. Decision: the relay accepts bookings and tries an immediate **direct webhook push** to the hospital's public URL when one is configured; if the push fails (offline/NAT), the row stays in `relay_in_master` for the hospital's next pull. Same write path server-side either way, so there's exactly one contract for website builders and zero latency for reachable facilities.

**REV — expiry for undelivered bookings.** If a hospital server is offline for days, relay rows sit `new` and the website shows "pending" forever. Add a TTL: mark `expired` after 72 h un-pulled, and the website renders "request expired — please call the clinic" for that state.

### 4.3 Hospital-server sync engine (new service, `services/relaySync.js`)

A node-cron job (pattern copied from `appointmentReminders.js` / `alert-scheduler.js`), started in `app.js`, **only when `RELAY_URL` + `FACILITY_SYNC_KEY` are set** (offline installs fill these from `.env` written by the installer; cloud/self-hosted from `.env` too).

**Pull (inbound, every N minutes — default 2 min, configurable via `facility_settings` key `sync_pull_interval_min`):**

1. `GET {RELAY_URL}/v1/in/feed?facility={facilityId}&cursor={lastId}` with Bearer key.
2. For each booking: **idempotency check** — skip if `appt_master.external_ref` already exists (unique index below). Else insert into `appt_master` with `status='pending_confirmation'`, `source='website'`, `external_ref=<relay row external_ref>`, and create the `appt_public_tokens` confirmation token + queue sms/email/whatsapp confirmation reminders — **reusing the exact block from `appointments-public.js::book`** (extract it into a shared helper `createWebsiteBooking()`).
3. Ack: `POST {RELAY_URL}/v1/in/ack` with the relay row ids; the relay flips them to `delivered`. **(REV: keep pulls strictly single-threaded and ack by id-batch — parallel pulls could skip rows between the read and the ack.)**

**Push (outbound):** every pull cycle (or on status change), read a local **outbox** and POST to the relay:

- New table **`appt_sync_outbox`** (local):
  ```sql
  CREATE TABLE appt_sync_outbox (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    appt_master_id INT NOT NULL,
    appt_ref     VARCHAR(64) NOT NULL,
    external_ref VARCHAR(64),
    status       VARCHAR(30) NOT NULL,
    event_at     DATETIME    NOT NULL,
    pushed       TINYINT(1)  DEFAULT 0,
    push_attempts INT DEFAULT 0,
    last_error   VARCHAR(500),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_unsent (pushed, id)
  );
  ```
- A thin hook inside `updateStatus` / `reschedule` / public confirm writes a row when the appointment has an `external_ref` (i.e. it came from the website) **and** the facility has sync enabled. The sync job drains it with retry + backoff (max ~5 attempts, then surface in Reminder-Health-style panel).

**REV — reschedule must carry the link.** The hub's reschedule handler does `INSERT INTO appt_master ... SELECT ... WHERE id = :id` and does **not** copy `external_ref` to the new row. Without it, the new slot is invisible to the website and the patient's status poll shows "rescheduled" but never the new time. Phase B must (a) add `external_ref` to that INSERT, and (b) fire the outbound update for the **new** row too.
- Relay stores it in `relay_out_master`; the website reads it.

**Failure handling:** transient errors → retry next cycle (idempotent by `external_ref` / `appt_ref`); permanent auth errors → disable sync, log, and show a banner in Settings so the admin re-enters the key.

### 4.4 Multi-channel notifications (the "notify everyone" half)

**1) Wire the `whatsapp` channel in the reminder cron** (`services/appointmentReminders.js`):

- Add a `whatsapp` branch alongside `sms`/`email`:
  - Requires `TERMII_API_KEY` + `TERMII_WHATSAPP_ID` (new env; Termii WhatsApp sender) + `TERMII_WHATSAPP_FROM` (phone number registered with Termii WhatsApp).
  - Sends via Termii's WhatsApp endpoint (`https://api.ng.termii.com/api/sms/send/whatsapp`, same auth shape as SMS — verify against current Termii docs at implementation time).
- **Channel mix per facility** (`facility_settings` key `reminder_channels`, JSON `{sms:true, whatsapp:true, email:true, in_app:true}`), default all-on. `scheduleReminders` skips disabled channels.
- Reminder-health panel already shows per-channel counts — the provider-config banner already lists termii/resend; extend it to show **whatsapp: configured / not**.
- `appointmentReminders.js` is the single writer of channel delivery → **all reminder types (24h, 1h, same-day, confirmation) automatically gain WhatsApp** once the branch exists.

**REV — the cron needs a per-row target override.** `processReminder` resolves the recipient from the JOINed appt row (`appt.patient_phone` / `appt.patient_email`) — there is **no provider contact on appt_master**. Enqueuing *provider* lifecycle messages as reminder rows therefore requires: (a) a `payload.contact_phone` / `payload.contact_email` override that the cron honors when present, and (b) the cron's `reminder_24h_sent`/`reminder_1h_sent` flag logic must **skip lifecycle rows** (those flags only make sense for 24h/1h reminders). The `'lifecycle'` enum addition needs `ALTER TABLE ... MODIFY ENUM` (full table rebuild — fine on small offline installs, note it in the migration).

**2) Provider (doctor) notifications — direct to the person:**

- New rule-based lifecycle calls, or better: extend `sendLifecycleNotification` (in `controller/appointments.js`) to also deliver **person-level SMS/WhatsApp/email**:
  - **Patient**: to `appt_master.patient_phone` / `patient_email`.
  - **Provider**: resolve `appt_providers.user_id` for the row's `provider_id`, then read that user's `phone` + `email` (`users` table — both columns verified to exist) and send to them; fall back to `provider_name` only (no contact) → skip silently.
  - **REV — unassigned provider fallback.** Website bookings arrive with `provider_id` null until staff assign one, so the "doctor concerned" half would silently drop for exactly the bookings this feature targets. Decide a fallback: notify facility-level clinicians on the new-appointment event (`appointment_booked` rule already targets Doctors/Records in-app — mirror that for SMS/WhatsApp/email), and/or send the provider notification the moment an admin assigns a provider later.
- Message templates per event (confirmed / cancelled / rescheduled / no-show / completed), e.g.:
  - *"Hi {patient}, your appointment with {provider} on {datetime} is confirmed. Reply STOP to stop SMS."*
  - *"Dr {provider}: appointment with {patient} on {datetime} has been {status}."*
- **Never fire-and-forget through the website path** — these send from the server's cron-safe helper, so offline installs work identically to cloud.
- Add a **delivery log** (`appt_message_log`) so the Reminder Health / Notifications panel can show patient+SMS, provider+SMS, etc., with status and error (reuse the `appt_reminders_queue` pattern — simplest is to *also* enqueue these as reminders rows with `reminder_type='lifecycle'` and let the same cron deliver; one engine, one health view). **Recommended:** enqueue as reminders rows.

**3) Per-recipient opt-outs:** `user_notification_preferences` table already exists (used by inventory digest). Add channel columns (`sms`, `whatsapp`, `email` booleans, default 1) so doctors can mute SMS but keep email. Patient-level opt-out = the reminder row for `confirmation` already gets skipped when no contact; add a `STOP` keyword handler later (v2).

### 4.5 The website integration contract (for us and third parties)

**Published spec: [`backend/WEBSITE_BOOKING_API.md`](../backend/WEBSITE_BOOKING_API.md)** — the agency-facing document (auth, idempotency, error codes, `expired` state, examples). One REST spec, two v1 endpoints (+ registration). Website needs: `facility_id` (public id) + `website_key` (public key, issued per facility for the booking widget).

```
POST /v1/bookings                     # website → relay
  headers: Authorization: Bearer <website_key>
  body: { facility_id, external_ref, patient_name, patient_phone,
          patient_email, provider_external_id?, service_name?,
          appt_datetime, duration_mins?, visit_type?, notes? }
  → 201 { booking_ref, status: "pending_confirmation" }
  **REV: relay also dedupes on (patient_phone + appt_datetime + provider)
  before accepting, because client-generated external_ref is not safe
  against double-submit (page refresh mints a new ref). The widget
  additionally persists its ref in sessionStorage so a refresh reuses it.**

GET  /v1/bookings/{booking_ref}       # website polls status
  → { booking_ref, status, appt_ref? }   # confirmed / cancelled / rescheduled

POST /v1/facilities/register          # super-admin / claim-time issuance
  → { facility_id, sync_key, website_key }
```

- Provider mapping: the website sends a **provider_external_id**; the hospital server maps it to `appt_providers` via a new `appt_providers.external_id` column (set once from the hub UI, e.g. the website's doctor slug). Unmapped → leave `provider_id` null (appears as "no provider" — admin assigns later).
- **Our own website builder** ships a tiny npm package (`@mylikita/booking-widget`) wrapping these three calls; agencies can also call the API directly.
- **Multi-site:** a facility can register several `website_domain`s; each gets its own `website_key`, all feeding the same `relay_in_master`.

### 4.6 Security & privacy

| Concern | Control |
|---|---|
| Booking spam / fake bookings | Website requires `website_key`; relay rate-limits per key (reuse `apiLimiter`); hospital server rejects unknown `external_ref` duplicates |
| Server→relay impersonation | `sync_key` (Bearer); relay only returns data for the authenticated facility |
| Relay compromise | Relay stores **minimal PHI, no clinical data**, short retention (e.g. 14 days); full records live on the hospital server |
| Transport | TLS everywhere (HTTPS endpoints) |
| Offline server has no internet | Sync simply doesn't run; in-app + local queue still work; pull resumes when connectivity returns (outbox persists) |
| Clock skew between website/server/relay | All cursors are monotonic DB ids (not timestamps); statuses carry `event_at` but reconciliation is last-write-wins by `appt_ref` |
| `sync_key` leakage | Stored hashed; shown once; rotate from super-admin UI; installer writes it to `.env` with file ACL |

---

## 5. Data model changes (hospital server) — migration summary

One migration (e.g. `20260805000001-appointment-sync-notifications.js`):

1. `appt_master`:
   - `ADD COLUMN external_ref VARCHAR(64) DEFAULT NULL` + `UNIQUE KEY uq_external_ref (facilityId, external_ref)` ← idempotency anchor for website bookings.
   - (relay mirror ref optional: `relay_row_id BIGINT` — not needed; `external_ref` suffices.)
2. `appt_providers`: `ADD COLUMN external_id VARCHAR(64) DEFAULT NULL` + `UNIQUE KEY uq_ext (facilityId, external_id)` (website provider mapping).
3. New `appt_sync_outbox` (schema above).
4. `facility_settings` new keys (seeded defaults, not columns):
   - `reminder_channels` = `{"sms":true,"whatsapp":true,"email":true,"in_app":true}`
   - `sync_pull_interval_min` = `2`
   - `sync_enabled` = `true`
   - `relay_url` / `sync_key` are **env-driven** (`.env`), not DB — offline installer writes them; cloud console sets them. (Rationale: keys belong in env, not the shared DB; per-facility override only where DB is genuinely better.)
5. `user_notification_preferences`: `ADD COLUMN sms TINYINT(1) DEFAULT 1, whatsapp TINYINT(1) DEFAULT 1, email TINYINT(1) DEFAULT 1`.
6. Reminder cron: add `whatsapp` branch; `reminder_type` enum stays as-is (add `'lifecycle'` via `MODIFY ENUM` for provider/patient event messages, or reuse `confirmation`-style rows — prefer adding `'lifecycle'` for clarity).
7. `appt_message_log` (optional v2 audit; v1 reuses `appt_reminders_queue`).

Cloud relay schema (section 4.2) lives in the **cloud** repo/DB, not shipped offline.

---

## 6. Where each piece runs (deployment matrix)

| Piece | Offline on-prem | Self-hosted | Cloud multi-tenant |
|---|---|---|---|
| MyLikita app + DB | ✔ local | ✔ local | ✔ shared cloud |
| Reminder cron (sms/whatsapp/email/in_app) | ✔ local (needs internet for Termii/Resend) | ✔ | ✔ |
| **Relay sync pull** | ✔ (interval, default 2 min) | ✔ (30–60 s) | ✔ (30–60 s) |
| **Relay sync push** | ✔ | ✔ | ✔ |
| Cloud relay (in/out master) | ✘ (lives on cloud) | ✘ | ✔ |
| Website booking widget | ✔ (points at relay) | ✔ | ✔ |
| Termii/Resend accounts | ✔ per hospital (or central, billed per facility) | ✔ | ✔ central |

> Offline note: the **app and notifications never require the relay**. Only *website bookings* need the server to have periodic internet for the pull. The FAQ already tells clients the server "should be connected to the internet" — this plan makes that *optional per feature* rather than all-or-nothing.

---

## 7. Implementation phases

### Phase A — Multi-channel, person-targeted notifications (no relay needed) · ~2–3 days
- A1. ~~Add `whatsapp` branch to `appointmentReminders.js` (+ `TERMII_WHATSAPP_ID` / `TERMII_WHATSAPP_FROM` env, `.env.example`, installer `.env` block, health-panel whatsapp pill).~~ ✅ **done** (Termii WhatsApp device via `TERMII_WHATSAPP_ID`; smsApi `sendWhatsApp`, cron whatsapp branch, env templates, health pill).
- A2. ~~`facility_settings.reminder_channels` JSON + `scheduleReminders` honors it.~~ ✅ **done** (`getReminderChannels` default all-on; `enabledChannels` intersects facility prefs with env capability; scheduleReminders, lifecycle enqueuer and `remindersHealth`/`reminders/settings` all honor it).
- A3. ~~Enqueue patient **and** provider lifecycle messages (`reminder_type='lifecycle'`) from `sendLifecycleNotification` + public confirm; resolve provider contact via `appt_providers.user_id → users.phone/email`.~~ ✅ **done** (`enqueueLifecycleRows` in `controller/appointments.js`; cron honors `payload.contact_phone`/`contact_email` override and skips 24h/1h flags for lifecycle rows; migration `20260805000001-appointment-phase-a.js` adds the `'lifecycle'` enum; lifecycle rows exempt from cancel/no-show sweeps so "your appointment was cancelled" still delivers).
- A4. ~~`user_notification_preferences` channel columns; provider opt-out honored by the cron.~~ ✅ **done** (migration `20260805000002-user-notification-channels.js` adds sms/whatsapp toggles, default all-on, idempotent; `getUserChannelPrefs`/`providerChannelEnabled` in `appointmentReminders.js` match prefs by **users.id OR username** — seeds key by username, the provider registry links numeric ids (reviewer-caught); enqueuer fetches prefs once and skips disabled channels for provider lifecycle rows, carrying `provider_user_id` + `provider_username` in the payload; cron re-checks at delivery so prefs edited after enqueue are honored; rows without provider identifiers fail open).
  - **A4 admin UI + email-toggle fix:** migration `20260805000003-provider-prefs-email-toggle.js` adds a real `appt_email` toggle — 20260805000002's `email` add was a silent no-op (the table already has a varchar `email` = inventory digest contact), so email could never be disabled; `getUserChannelPrefs` now reads `appt_email`. New `GET/PUT /appointments/reminders/provider-prefs` (Reminder Health → "Provider notification channels (per doctor)") lists linked providers with per-doctor sms/whatsapp/email checkboxes; strict booleans, row-level facility guard, no-login providers excluded. Appointment rows leave the varchar `email` NULL and the inventory digest queries were guarded with `notification_type <> 'appointment'` so the new rows never join digest recipients. **Self-service:** `GET/PUT /appointments/reminders/my-prefs` (My Profile → "Notification Channels") let a doctor edit their OWN mix — scope is `req.user`, no client-supplied ids, shared `upsertAppointmentPrefs`/`validatePrefChannels` helpers so the admin and self-service paths can never drift.
- A5. Migration + validation (node --check, esbuild, mocked Termii WhatsApp payload test) + extend the CI install-test job (assert whatsapp channel row lands in `appt_reminders_queue`; assert a provider lifecycle message resolves a recipient). ⬜ **migration + mocked tests done; CI assertion pending**
- **Verify:** book → patient + doctor get sms/whatsapp/email; reminder health shows all channels; doctor toggles sms off → only email arrives.

### Phase B — Cloud relay + pull sync (the offline game-changer) · ~3–4 days
- B1. ~~Relay service (cloud): `relay_in_master` / `relay_out_master` / `relay_cursors`, three endpoints, key issuance, rate limiting, minimal-PHI retention.~~ ✅ **done** — standalone module `backend/relay/` (own DB `mylikita_relay`, idempotent schema bootstrap on boot, `node app.js` on port 46995). Endpoints: `POST /v1/facilities/register` (operator key, bcrypt hashes at rest, plaintext keys shown once, re-register rotates); `POST /v1/bookings` (idempotent on `external_ref`, 409 duplicate on phone+datetime+provider, dual-path webhook push to `website_domain`); `GET /v1/bookings/:booking_ref` (status incl. `expired`); `GET /v1/in/feed` + `POST /v1/in/ack` (server-side cursor in `relay_cursors`, batch ack); `POST /v1/out/feed` (upsert by facility+appt_ref). Auth per-route: `sync_key`/`website_key` bcrypt-verified → `req.principal.facility_id` (no cross-tenant enumeration), super-admin constant-time env compare. Per-key rate limits (website 30/min, sync 300/min, operator 10/min — keyed by the Bearer credential, not IP). Purge jobs: 72 h TTL → `expired`, 14-day retention hard-delete (node-cron). **Validated:** `node --check` all files + mocked e2e (13 checks: register→book→idempotent→dup 409→pull→ack→push→poll confirmed→401→404→400) + mocked purge tests.
- B2. ~~Hospital `services/relaySync.js` (pull + ack + outbox push) + cron wiring in `app.js` guarded by env; shared `createWebsiteBooking()` helper extracted from `appointments-public.js::book`; `external_ref` unique key; sync-outbox hook in status writers.~~ ✅ **done** — `backend/services/relaySync.js`: env-guarded (`RELAY_URL` + `FACILITY_SYNC_KEY` + `FACILITY_ID`, else the cron never starts) node-cron engine, single-flight; PULL `GET /v1/in/feed?cursor` → dedup by `appt_master.external_ref` → shared `createWebsiteBooking()` → batch `POST /v1/in/ack`, local cursor persisted in `facility_settings`; PUSH drains `appt_sync_outbox` → `POST /v1/out/feed` (batch 50, `push_attempts`/`last_error`, retry cap 5). `websiteBooking.js` is the ONE write path for the legacy `public/book`, the new `POST /v1/inbound/bookings` webhook receiver (mounted only when `FACILITY_ID` is set — single-facility servers; cloud uses the pull), and the relaySync pull: insert + confirmation token + reminder rows, `external_ref` idempotency. Outbox hooks fire from every status writer (hub `updateStatus`/`reschedule`, public confirm/cancel/reschedule, `apptSync.syncLifecycle`); reschedule nulls the old row's ref, pushes `rescheduled` with the preserved ref, and carries the ref onto the new row so the website tracks the live slot under the ORIGINAL booking id. Migration `20260805000010`: `appt_master.external_ref VARCHAR(64)` + UNIQUE `(facilityId, external_ref)`, `appt_sync_outbox` (UNIQUE `(appt_master_id, status)`, `pushed`/`push_attempts`/`last_error`). Reviewer fixes applied: `drainOutbox` destructuring bug (would have crashed on real rows), inbound-webhook `ER_DUP_ENTRY` race → `duplicate:true`, webhook route gated to `FACILITY_ID` servers, Node≥18 floor documented. **Validated:** node --check all files + mocked runtime suite 14/14 (env guard, pull→import→ack, dedup no re-import, outbox drain marks pushed, enqueue gating, shared booking path) + relay e2e still green.
- B3. ~~Super-admin console: issue/rotate `sync_key` + `website_key`; Settings page in app: paste key/relay URL, test-connection button, sync status banner.~~ ✅ **done** — **Relay** gained `GET /v1/facilities` (operator auth; facility_id, website_domain, pending_in/failed_in/pushed_out, last_pull_at — never hashes/plaintext). **Main app** — `controller/relay-settings.js` + `routes/relay-settings.js`: facility-scoped `GET/PUT /settings/relay` (runtime config into `facility_settings`, env fallback), `POST /settings/relay/test` (feed probe: 200 ok / 401 rejected / network err — always HTTP 200 so axios doesn't swallow the error text), `POST /settings/relay/sync-now` (manual `runSyncOnce`, returns pulled/pushed counts); super-admin `GET /admin/relay/facilities` + `POST /admin/relay/facilities/register` proxy to the relay with `RELAY_OPERATOR_KEY` (server-side only; 503 when unconfigured). `relaySync.js` now reads config from `facility_settings` (env fallback), records `relay_last_error`/`relay_last_sync_at`, `testConnection`/`getSyncStatus`/`saveRelayConfig`, and the cron starts lazily (`refreshSchedule` — no background polling on unconfigured installs; Settings save re-schedules immediately). **Frontend** — `RelaySettingsCard.jsx` in Settings (url/key/cron, Save/Test/Sync-now, status banner + health stats incl. unsent outbox); `RelayKeyConsole.jsx` super-admin page at `/me/admin/relay-keys` (register/rotate form, facilities table, reveal-once keys modal with copy). Reviewer fixes: dead `relayUrl()` removed, cron validated with `node-cron.validate`, test/sync-now return 200+success:false, SSRF trust comment, `getSyncStatus` array-vs-row destructure bug fixed (silently swallowed last_cursor). **Validated:** node --check + mocked suites 20/20 (config merge settings-wins, partial save, test 200/401/network, masked key, status, settings-driven runSyncOnce, enqueue gating, console proxy + 503) + regression 6/6 + relay e2e green + esbuild.
- B4. ~~Migration + CI: after install-test, assert pulled website booking appears in `appt_master` with `source='website'` and that a status change lands a relay-outbox row.~~ ✅ **done** — the install-test job (Phase B4 group, after the phase-2 reinstall so the .env edit + restart disturb nothing else) boots the REAL relay (`backend/relay`, port 46995) against the installed embedded MySQL (`mylikita_relay` DB auto-created by the relay bootstrap) using the app's bundled `node_modules` via `NODE_PATH` (no npm ci; checkout added to the job for the relay source). Then: operator-key `POST /v1/facilities/register` issues sync_key + website_key → `.env` gets `RELAY_URL/FACILITY_SYNC_KEY/FACILITY_ID` + service restart → website books via website_key (`relay_in_master`) → login + `POST /settings/relay/sync-now` pulls it → assert `appt_master` row has `source='website'` + `external_ref` + `pending_confirmation` → `PUT /appointments/:id/status confirmed` → assert `appt_sync_outbox` row → `sync-now` again → assert `relay_out_master.status='confirmed'` AND the website poll `GET /v1/bookings/:ref` returns `confirmed` (the widget's exact flow).
- **Verify:** seed `relay_in_master` row → next pull creates the appt + confirmation token + reminders; confirm via token → outbox row → relay; re-run pull is a no-op (idempotent).

### Phase C — Website integration contract + widget · ~2 days
- C1. Publish the REST spec (section 4.5) as API docs + OpenAPI.
- C2. ~~`@mylikita/booking-widget` npm package (form + status poll) with theme hooks for agency sites.~~ ✅ **done** — `packages/booking-widget/` in the monorepo: zero-dependency vanilla-JS widget implementing the exact v1 relay contract (Bearer `website_key`, `external_ref` idempotency via sessionStorage, 409-as-success, bounded poll, 72 h `expired` state). `createBookingWidget(el, { relayUrl, websiteKey, facilityId, providers, services, theme, text, onStatus… })` → `{ destroy, reset, getForm }`. Theme hooks: CSS custom properties on `.mylikita-widget` (`--mlw-*`) + programmatic `theme` object; i18n overrides via `text`. Built to IIFE (`MyLikitaBookingWidget` global, script-tag), IIFE.min, ESM and CJS via esbuild (`build.mjs`, resolves the monorepo frontend esbuild before `npm install`). `demo/demo.html` runs fully offline against an in-page mock relay (submit → polls → confirmed). **Validated:** esbuild build clean (4 bundles), mocked-fetch suite 9/9 (create, Bearer header + trailing-slash, 409 duplicate → ok+duplicate, 400 throws code/status, fetchStatus, poll resolves/gives-up, statusCopy incl. fallback, theme merge, external_ref format), IIFE + CJS require smoke-tested; reviewer fix applied (CJS bundle renamed `.cjs` — `"type": "module"` made `.cjs.js` require() fail).
  - **C2b (React wrapper) ✅ done** — `packages/booking-widget-react/`: `<BookingWidget relayUrl websiteKey facilityId … />` (forwardRef + imperative handle `{ reset, getForm, destroy, getWidget }`). Every vanilla option is a prop; `onBooking/onStatus/onError` live in a ref so callback identity changes never tear down the widget, while data options are JSON-keyed so only real changes rebuild it (new array/object literals each render are safe). SSR-safe (no DOM until the browser effect). react/react-dom are peers, the widget is a real dependency — all stay external in the bundles (ESM + CJS). jsdom harness (`test/`, resolves react/jsdom/esbuild from `frontend/node_modules`, no install): 26/26 — form mounts, submit → POST /v1/bookings (Bearer) → poll → confirmed with callbacks, unmount destroys the DOM, missing-config renders empty (async-config safe), `loadProviders` populates the doctor dropdown, `ref.reset()/getForm()`, theme change recreates the widget. `dist/react-demo.html` is fully self-contained (react+react-dom+widget inlined, offline mock relay) and verified live in the Preview tab (booking → confirmed, React-state live log).
- C3. ~~`appt_providers.external_id` mapping UI in hub Providers tab.~~ ✅ **done** — migration `20260805000011` adds `appt_providers.external_id VARCHAR(64)` + UNIQUE `(facilityId, external_id)` (MySQL NULLs distinct, so unmapped providers coexist; column+key guards make it re-run safe). `createWebsiteBooking` resolves `provider_external_id` → mapped provider (slug mapped by staff ⇒ booking arrives **pre-assigned**; unmapped ⇒ stays unassigned per decision Q5) across ALL three entry paths: legacy `public/book`, relay webhook `inboundBooking`, and the relaySync pull. Provider CRUD (`createProvider`/`updateProvider`) accepts, sets and **clears** `external_id` (`NULLIF('','')` unmap; ER_DUP_ENTRY → 409 friendly error). Notify-on-assignment: `enqueueProviderAssigned` enqueues the assigned doctor's SMS/WhatsApp/email (per-channel opt-outs + facility channel mix honored) through the same reminder queue the cron delivers. Hub Providers tab: Website ID column (mapped badge / 'not mapped') + modal field (maxLength 64). **Validated:** node --check all touched files + mocked runtime 6/6 (mapped slug, unmapped slug, explicit provider_id wins, no provider) + esbuild transform; reviewer fixes applied (dead `!provider_name` condition, input maxLength parity).
- C4. Multi-domain registration per facility.
- **Verify:** booking from a plain HTML demo page (simulating a third-party site) → shows on dashboard; staff confirm → demo page shows confirmed.

### Phase D — Hardening & polish · ~1–2 days
- D1. Sync health panel (outbox stuck rows, last pull time, last error, retry button) — mirrors Reminder Health.
- D2. STOP keyword SMS opt-out + provider/patient channel prefs UI.
- D3. Outbox retry backoff + alert after N failures (in-app + email to admins).
- D4. Docs: update OFFLINE_INSTALLATION_GUIDE (SMS/WhatsApp/email setup + website sync), API docs, and the `APPOINTMENTS_ANALYSIS_AND_PLAN.md` progress table.

---

## 8. Open questions for the product owner — ✅ RESOLVED

**All six questions are decided — see [`APPOINTMENT_SYNC_DECISIONS.md`](APPOINTMENT_SYNC_DECISIONS.md) for the full rationale and Phase B impact.** Summary:

1. **Billing model for Termii/Resend** → **Per-hospital own keys (v1)**. No central keys, no metering (metering is unreliable for offline installs).
2. **Pull cadence for offline installs** → **2 min default**, per-facility override `sync_pull_interval_min` (1–60); reachable deployments use direct webhook push, pull is the fallback.
3. **Website v1 scope** → **Book + view status only**; confirm/decline via the existing token link; cancel/reschedule from the website is **v2** (the patient portal already covers self-service).
4. **Relay PHI** → Relay **buffers minimal contact info as a pass-through, never uses or sends from it**, 14-day retention, 72 h TTL. Hospital server is the only sender.
5. **Provider external-id mapping** → Bookings arrive **unassigned**; staff map via hub (`appt_providers.external_id`, Phase C3); notify-on-assignment hook. ~~no hospital→website provider-list sync~~ **SUPERSEDED (Phase C2/C3 provider-list sync)**: the hospital PUSHES its mapped providers to the relay (`POST /v1/out/providers`, same sync cycle / NAT-friendly direction as status pushes), the relay serves `GET /v1/providers` to the website (website_key), and the booking widget fetches it with `loadProviders: true`. Only mapped+active providers are published (no PHI).
6. **Multi-facility website** → Contract is **multi-facility from day one** (`facility_id` per booking); **no group-level reporting on the relay** in v1 (website aggregates its own bookings).

**Guardrails Phase B must honor:** no Termii/Resend key storage or metering in the relay · no website-originated cancel/reschedule endpoints · the relay never sends SMS/email · no group-reporting endpoints · relay MUST implement 72 h TTL + 14-day retention purge. (Provider-list sync — formerly a guardrail — is now **in scope** via hospital→relay push + `GET /v1/providers`; see item 5 above.)

---

## 9. Risks

| Risk | Mitigation |
|---|---|
| **Legacy unauthenticated booking endpoint abused** | Gate with `apiLimiter` + require a facility key (toggle default OFF) or retire for website traffic; only relay carries new integrations (see §4.1 REV) |
| **`website_key` read from browser JS and abused** | It is a non-secret client id by design; per-key rate limits + honeypot/CAPTCHA are the real controls (see §4.1 REV) |
| **sync_key stored with wrong primitive** | bcrypt/argon2 at rest, never HMAC; rotation UI (see §4.1 REV) |
| **Reschedule breaks website follow-through** | Propagate `external_ref` into the reschedule INSERT + outbound the new row (see §4.3 REV) |
| **Provider lifecycle messages mis-targeted** | `payload.contact_phone`/`contact_email` override honored by the cron; skip 24h/1h flags for lifecycle rows (see §4.4 REV) |
| **Website booking has no provider → doctor never notified** | Facility-level clinician fallback + notify-on-assignment (see §4.4 REV) |
| **Double-submit creates duplicate bookings** | Relay-side dedupe on (phone + datetime + provider); widget persists ref in sessionStorage (see §4.5 REV) |
| **Hospital offline for days → booking hangs** | 72 h TTL marks undelivered bookings expired; website renders that state (see §4.3 REV) |

| Risk | Mitigation |
|---|---|
| Offline server offline when patient books → patient waits for confirmation | Confirmation link is emailed/texted immediately from the relay? No — v1 sends the confirmation request only after the hospital pulls (seconds–minutes). If unacceptable, relay itself sends a "request received" message (needs relay to hold contact info — see Q4). |
| Website double-books | Unique `(facilityId, external_ref)` + idempotent pull; widget generates `external_ref` client-side per submit. |
| Relay becomes a new single point of failure | It only moves appointment data; the app works fully without it. Outbox buffers outbound; inbound rows stay `new` until next pull. |
| Key leakage / abuse | Bearer keys, hashed at rest, rotation UI, per-key rate limits, minimal PHI at rest in relay. |
| Termii WhatsApp not available in client's region | Channel is per-facility configurable; SMS/email fall back automatically when whatsapp unconfigured. |

---

## 10. Review findings (folded in, 2026-08-05)

Architecture review of v1 of this doc found the following; all are now
incorporated above (REV markers) and listed here as a checklist:

1. **Legacy public booking endpoint** left unauthenticated → gate with `apiLimiter` + facility key, or retire for website traffic (§4.1).
2. **`website_key` is not a secret** (browser JS) → treat as public client id; rely on rate limits + honeypot (§4.1).
3. **HMAC "hash" was wrong** for `sync_key` → bcrypt/argon2 (§4.1).
4. **Reschedule drops `external_ref`** on the new row → propagate + outbound it (§4.3).
5. **Cron recipient resolution** has no provider path → `payload.contact_phone`/`contact_email` override + skip 24h/1h flags for lifecycle rows (§4.4).
6. **Provider notifications silent for unassigned website bookings** → facility-clinician fallback + notify-on-assignment (§4.4).
7. **Double-submit duplicates** (client ref unsafe) → relay dedupe on phone+datetime+provider + sessionStorage ref reuse (§4.5).
8. **Reachable deployments shouldn't pay pull latency** → dual path: direct webhook push when a public URL exists, relay buffering otherwise (§4.3).
9. **`users.phone`/`users.email`** — verified present in schema ✓ (no action).
10. **No expiry for undelivered bookings** → 72 h TTL + website "expired" state (§4.3).
11. **Ack ordering** → single-threaded pulls, batch ack by id (§4.3).
12. **Relay PHI contradiction** → v1 relay is a pass-through that never *uses* contact info (it only buffers it for the hospital pull); say so plainly and tighten retention to 14 days (§9/§4.2).

---

*Design review completed. Phases A–D land incrementally; each phase is independently deployable.*
