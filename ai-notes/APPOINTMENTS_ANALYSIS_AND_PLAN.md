# Appointments System — Analysis & Implementation Plan

**Date:** 2026-08-04 · **Scope:** Booking, scheduling, lifecycle, queue/calendar, analytics, and notifications (in-app, SMS, email, confirmation links)

---

## Progress (2026-08-04)

Legend: ✅ done · 🔄 in progress (scaffolded / partial) · ⬜ not started

| Phase | Status |
|---|---|
| Phase 1 — Harden the hub | ✅ **DONE** — all P0 items shipped (optional hardening 7–8 deferred, see Remaining) |
| Phase 2 — Unify the data | ✅ **DONE** — backfill + provider sync ✅ · KPI fix ✅ (item 12) · doctor path ✅ (item 10) · module write-through ✅ (item 11) |
| Phase 3 — Notifications UX | ✅ **DONE** — items 13–16 shipped |
| Phase 4 — Features & polish | ✅ **DONE** — all five items shipped (backend + hub UI) |

**Done so far (with artifacts):**

- **Phase 1 hardening** — notification endpoints auth-gated (IDOR closed; `user_id` derived from the JWT, not the query param); appointment endpoints facility-scoped (`requireFacilityScope` middleware + row-level `canAccessFacility`, super-admin aware); analytics date filters parameterised; `resolveRecipients` fixed (`FIND_IN_SET` over comma-separated `accessTo`); lifecycle notifications seeded + fired (migration `20260804000008`, fired from `updateStatus`/`reschedule`/public confirm); stale reminders skipped on cancel/no-show/reschedule (`appointmentReminders.js` sweep + pre-send re-check + `skipPendingReminders`).
- **Phase 2 backfill + provider sync** — migration `20260804000007` links legacy `appointment`, `dental_appointments`, `radiology_appointments` rows into `appt_master` (`module`/`module_appt_id`, status/priority whitelists, idempotent via deterministic refs + `INSERT IGNORE`, runs on fresh installs) and upserts `appt_providers` from clinical users.
- **Phase 2 module write-through (item 11, DONE)** — `services/apptSync.js` (`syncToMaster`/`syncRadiologyAppointment`) now mirrors EVERY module write into `appt_master` and fires `appointment_cancelled`/`appointment_no_show` + skips stale reminders at the single choke point (dental keyed on `appointment_id`, matching the backfill). Wired paths: dental create/cancel/no-show/reschedule **+ confirm/check-in/complete (+ the auto-scheduled follow-up the complete proc creates)**; radiology create/update/check-in/status/delete **+ examinations create/complete + DICOM image-received webhook + billing `onPaymentComplete`**. Also fixed the adapter's existing-row lookup to key on the canonical module key (`appointment_id || id`) — previously every dental sync INSERTed a duplicate `appt_master` row instead of updating. `syncRadiologyAppointment` joins procedure/patient/staff names so the mirror carries real names, not bare FK ids; radiology `duration_minutes` and `checked-in` status now map correctly.
- **CI** — install-test job asserts the 5 lifecycle rules exist and a real confirm transition lands a `sys_notifications` row with ≥1 resolved recipient.

**Remaining:**

- Phase 1 optional hardening (deferred): public booking rate limit (`apiLimiter` exists but is not yet on `/appointments/public/*`) + index migration (`appt_reminders_queue (appt_master_id, status)`, `appt_master (facilityId, status, appt_datetime)`).
- Phase 2 fully done (item 11 shipped) — legacy tables can now be retired once their data is verified fully mirrored.
- Phase 3 fully shipped (item 16: patient-portal UI page + token-based cancel/reschedule).
- Phase 4 shipped — all five items (recurring series, wait-time, telemedicine, provider registry UI, analytics) live in the hub; see below for details.
- Phase 4 known-scope note: series creation is exposed via API only (no dedicated UI button in the hub yet) — the endpoint supports it and the queue/calendar/analytics all render series instances.

---

## 1. How it works today

### 1.1 The "Central Appointment Hub" (the modern system)

A cross-module appointment registry was built in migration
`backend/migrations/20260506000001-central-appointment-hub.js`. It creates
eight tables (none of which exist in `prime-db.sql` — they are created by
migrations at install):

| Table | Purpose |
|---|---|
| `appt_master` | Central appointment index — denormalised patient/provider/service, `appt_datetime`, `end_datetime` (generated), lifecycle timestamps, status enum, source, billing + reminder flags, follow-up link |
| `appt_service_types` | Procedure catalogue with `duration_mins` + `default_fee` |
| `appt_providers` | Provider registry (doctors, dentists, radiologists…) |
| `appt_provider_schedule` | Weekly availability per provider |
| `appt_provider_blocks` | Leave / unavailability blocks |
| `appt_reminders_queue` | Unified reminder queue (sms/email/in_app/whatsapp) |
| `appt_waitlist` | Waitlist entries |
| `appt_public_tokens` | Tokens for public booking/confirmation links |

**API surface** (`backend/routes/appointments.js` + `appointments-public.js`),
all reading/writing `appt_master`:

- **Auth**: `POST /appointments`, `GET /appointments` (list w/ filters),
  `GET /appointments/calendar`, `GET /appointments/queue` (today),
  `GET /appointments/availability`, `GET /appointments/conflicts`,
  `GET /appointments/:id`, `PUT /appointments/:id/status`,
  `PUT /appointments/:id/reschedule`, `DELETE /appointments/:id` (cancel),
  providers (list/schedule/block), waitlist (get/join), 6 analytics endpoints.
- **Public (no auth)**: `GET /appointments/public/providers`,
  `GET /appointments/public/slots`, `POST /appointments/public/book`,
  `GET /appointments/public/confirm/:token`.

**Lifecycle** (`appt_master.status`): `pending_confirmation → scheduled →
confirmed → checked_in → in_consultation → completed`; plus `cancelled`,
`no_show`, `rescheduled`, `waitlisted`. Timestamps (`confirmed_at`,
`checked_in_at`, …) are stamped by `PUT /:id/status`.

**Key behaviours in `backend/controller/appointments.js`:**
- **Create** runs a provider-conflict check (`services/appointmentConflicts.js`),
  schedules 24h/1h/same-day reminders (`scheduleReminders`), and fires a
  server-side notification (`notificationService.send`, event
  `appointment_booked`).
- **Reschedule** sets the old row to `rescheduled` and **inserts a new row**
  for the new slot (follow-up link), then schedules reminders for the new row.
- **Complete** auto-triggers a billing row in `pending_txn` (Sprint 8) if
  `consultation_fee > 0` and not already billed.
- **Status changes** emit socket events to `facility_{id}_queue`
  (`appointment:status_changed`, `patient:checked_in`, `queue:updated`).

**Public booking** (`appointments-public.js`): patient books →
`pending_confirmation`, a crypto-random confirmation token is stored in
`appt_public_tokens` (48 h expiry), and two `confirmation` reminders (sms +
email) are queued. The token link (`/appointments/public/confirm/:token?action=yes|no`)
confirms or cancels.

### 1.2 Notifications (the modern system)

- **Rule-based delivery** (`backend/services/notificationService.js`):
  `sys_notification_rules` maps an `event_type` → target roles / accessTo
  permissions. Rules are seeded from a `__default__` facility template
  (`migrations/20260507000001-notification-system.js`,
  `20260519000001-add-missing-notification-rules.js` — `appointment_booked`
  targets Doctors/Records).
- **Delivery**: `send()` inserts into `sys_notifications` + one
  `sys_notification_recipients` row per recipient (status `pending`), then
  emits `sys_notification` over Socket.io to `user_{id}` rooms; online users
  are marked `delivered`, offline stay `pending` (fetched on next login).
- **UI**: `frontend/src/context/NotificationContext.jsx` polls
  `GET /notifications` + `GET /notifications/unread-count`, listens for
  `sys_notification`, and exposes accept/accept-all.
  `NotificationBell.jsx` (red badge) + `NotificationModal.jsx` render them.
  Admins manage rules in `admin/NotificationRulesManager` via
  `/admin/notification-rules`.

### 1.3 Reminders

`backend/services/appointmentReminders.js` runs a node-cron job every 5 min
(started in `app.js`). It drains `appt_reminders_queue` where
`scheduled_at <= NOW()`, builds an SMS/email/in-app message per
`reminder_type` (24h / 1h / same_day / confirmation), sends via
`sendSMS`/`emailApi`/socket, marks `sent`/`failed`/`skipped`, retries up to 3
times, and flips `appt_master.reminder_24h_sent` / `reminder_1h_sent`.

### 1.4 The parallel legacy systems (still live)

| System | Path | Storage | Used by |
|---|---|---|---|
| Doctor booking | `POST /all/appointment/new` → `controller/doc.js` → `CALL appointment(...)` | legacy **`appointment`** table (stored procedure in `prime-db.sql`) | Doctor dashboard (`doc_dash/appointments/NewAppointment.jsx`, `appointmentsAction.js`), doctor "Today's Appointments" |
| Dental | `dental-appointments` routes/controller | **`dental_appointments`** | Dental module |
| Radiology | `radiology-appointments` routes/controller | **`radiology_appointments`** (+ auto-created from billing) | Radiology module |
| Legacy notifications | `redux/actions/notifications.js` | **PouchDB local** (`notification_db`) | Doctor UnapprovedAppointments approval flow, patient appointment actions, `notifications/Notifications.jsx`, `PatientNotificationBell.jsx` |

**None of the legacy systems write to `appt_master`** — the `module` /
`module_appt_id` linkage columns are unused in practice.

---

## 2. Gaps

### A. Data & integration (biggest structural issues)

1. **Three/four disjoint appointment stores.** `appt_master` (central hub),
   legacy `appointment` (doctor path), `dental_appointments`,
   `radiology_appointments` never synchronise. A patient's appointment can
   exist in one store but be invisible in the others; the central hub's
   calendar/queue/analytics and the doctor/dental/radiology views disagree.
2. **KPIs ignore the hub.** `reports-kpi.js` counts `appointments` +
   `dental_appointments` only; `appt_master` is excluded, so "today's
   appointments" on dashboards don't match the hub.
3. **Doctor path bypasses conflict checks + reminders + notifications.** The
   legacy `CALL appointment` path does raw inserts with no overlap check, no
   reminder queue, no `appointment_booked` notification.
4. **Two notification systems.** Server-side `sys_notifications` (good) vs
   PouchDB-local notifications. PouchDB notifications are browser-local:
   created by the doctor approval flow (`UnapprovedAppointments.jsx`), they
   never reach other users/machines and vanish with the browser data.
5. **`module`/`module_appt_id` linkage not enforced** — no backfill or
   sync job keeps `appt_master` in step with module tables.

### B. Security

6. **Notification endpoints are unauthenticated (IDOR).**
   `routes/notifications.js` has `authenticate` **commented out** on
   `GET /notifications`, `GET /notifications/unread-count`,
   `PUT /notifications/:id/accept`, `PUT /notifications/accept-all`, and the
   client passes `user_id`/`facilityId` as query params — any caller can read
   or acknowledge any user's notifications.
7. **No facility scoping on appointment CRUD.** `list`/`getById`/`updateStatus`/
   `reschedule`/`cancel` accept any `facilityId` and never verify the caller
   belongs to it (`requireFacility` is not applied) — cross-tenant read/write
   is possible.
8. **Public endpoints have no abuse protection.** `/appointments/public/*`
   have no rate limit, CAPTCHA, or token; knowing a `facilityId` lets anyone
   enumerate providers/slots and book repeatedly.
9. **SQL interpolation in analytics.** `analytics*` builds
   `dateFilter` by string-interpolating `date_from`/`date_to` — an injection
   vector (authenticated, but should be parameterised).
10. **Recipient resolution may silently fail.** `resolveRecipients` matches
    `accessTo LIKE '%"perm"%'` (JSON-array shape), but the `users.accessTo`
    column stores comma-separated values (e.g. `"Dashboard,Records,…"`) —
    permission-targeted rules likely resolve zero recipients.

### C. Notification & reminder correctness

11. **No notification on lifecycle changes.** Only `appointment_booked`
    fires. Confirmed / checked-in / completed / cancelled / no-show /
    reschedule produce **no** server notification to staff or patient.
12. **Cancel/reschedule don't cancel queued reminders.** The old slot's
    `appt_reminders_queue` rows stay pending, so a patient can receive
    reminders for both the old and new times (and for cancelled/no-show
    appointments).
13. **Reminder failures are silent.** SMS/email depend on external providers
    (`sendSMS`, nodemailer) that may be unconfigured (offline installs);
    reminders are silently `skipped`/`failed` with no admin visibility or
    retry for unconfigured channels. *(2026-08-05: SMS now via Termii
    (`TERMII_API_KEY`), email via Resend (`RESEND_API_KEY`) — env-driven, and
    the Reminder Health panel shows per-channel configured/not-configured
    status so unconfigured channels are visible instead of silent.)*
14. **Reminder scheduling is fixed.** 24h/1h/same-day(08:00) offsets are
    hard-coded in `scheduleReminders`; no per-facility configurability;
    (2026-08-05: `whatsapp` channel now wired — see item 14.)
15. **Public confirmation is weak.** Token is the only gate (48 h, no usage
    per purpose), `?action=no` cancels without recording
    `cancellation_reason`/`cancelled_by`, and booking-link/reschedule/cancel
    token types are unused.

### D. Functional

16. **No recurring appointments** (only an `is_follow_up` flag).
17. **No estimated wait time / waiting room** — the queue is time-ordered
    only.
18. **Telemedicine `visit_type` is a string only** — no video/consult link.
19. **Provider registry not auto-seeded** from existing users/doctors; no UI
    to create providers in the hub (only schedule/block on existing).
20. **No patient-facing appointment view** in the patient portal backed by the
    hub (patient actions still use the legacy path + PouchDB notifications).

### E. UX / operations

21. **Doctor "Today's Appointments"** (legacy) and the hub queue can show
    different lists — confusing for staff.
22. **`rescheduled` rows accumulate** as separate `appt_master` rows; they
    inflate analytics unless filtered.
23. **No cancel/reschedule flow for patients** — confirmation link supports
    yes/no only.

---

## 3. Implementation plan (phased)

Priorities: **P0 = security/correctness**, **P1 = integration/data**, **P2 = UX/features**.

### Phase 1 — Harden the hub (P0) · ✅ DONE (2026-08-04)

1. ✅ **Auth-gate notification endpoints.** Enable `authenticate` on
   `routes/notifications.js`; derive `user_id` from `req.user` instead of
   trusting the query param (drop the `user_id` param server-side, or verify
   `req.user.id === user_id`). *(Done: authenticate enabled on all 8 routes;
   controller derives the user from the JWT; facility-scope added on create.)*
2. ✅ **Facility-scope appointment endpoints.** Add a middleware (or per-route
   check) that binds `facilityId` to the caller's facility unless super admin
   (privilege 8), mirroring `findUsersRole`. Apply to list/getById/status/
   reschedule/cancel/queue/calendar/analytics. *(Done: `requireFacilityScope`
   middleware + row-level `canAccessFacility`; non-super-admins default to
   their own facility; read paths return 404 to block id enumeration.)*
3. ✅ **Parameterise analytics date filters** (`:date_from`/`:date_to`
   replacements instead of interpolation). *(Done: all five analytics
   handlers use replacements — zero interpolated filters remain.)*
4. ✅ **Fix `resolveRecipients`** to match `accessTo` as comma-separated (or
   `FIND_IN_SET`) in addition to the JSON-array pattern. *(Done:
   `FIND_IN_SET(REPLACE(:perm,' ',''), REPLACE(accessTo,' ',''))` + legacy
   LIKE fallback; simulation over seed data: 0 → 9/7/5 hits for
   Doctors/Records/Accounts.)*
5. ✅ **Cancel/complete/confirm notifications.** Fire `notificationService.send`
   for `appointment_cancelled`, `appointment_confirmed`,
   `appointment_completed`, `appointment_rescheduled`, `appointment_no_show`
   (seed `__default__` rules in a migration). *(Done: migration
   `20260804000008` seeds all five + propagates to existing facilities;
   fired from `updateStatus`, `reschedule`, and the public confirm path.)*
6. ✅ **Cancel queued reminders** when an appointment is cancelled/no-show/
   rescheduled (update `appt_reminders_queue.status='skipped'` for the old
   slot; on reschedule, also cancel the old row's reminders). *(Done:
   `skipPendingReminders` on all status writers + a 5-min cron sweep over
   dead `appt_master` statuses + a pre-send re-check to close the race.)*
7. ⬜ **Public endpoints rate limit** (`apiLimiter` from
   `middleware/rateLimit.js`) on `/appointments/public/*` + a simple HMAC or
   facility token for public booking (or a CAPTCHA/honeypot). *(Deferred:
   `apiLimiter` exists but is not yet applied to the public appointment
   routes.)*
8. ⬜ Migration: index `appt_reminders_queue (appt_master_id, status)`,
   `appt_master (facilityId, status, appt_datetime)` composite, and
   `cancelled_by`/`cancellation_reason` on public `action=no` confirm.
   *(Deferred — performance + polish, no behavioural bug.)*

**Verify:** curl the notification endpoints without a token (must 401);
cross-facility appointment read (must 403); unit-check recipient resolution
query against a comma-separated `accessTo` row.

### Phase 2 — Unify the data (P1) · 🔄 IN PROGRESS

9. ✅ **Backfill + sync job.** Migration `20260804000007`:
   - links existing `appointment` (legacy), `dental_appointments`,
     `radiology_appointments` rows into `appt_master` (set `module`,
     `module_appt_id`);
   - idempotently upserts providers into `appt_providers` from users with
     clinical roles.
   *(Done — idempotent for the installer's re-run path: deterministic refs +
   `INSERT IGNORE`, defensive enum whitelists, runs on fresh installs.)*
10. ✅ **Route the doctor path through the hub.** Point
    `appointmentsAction.js` / `NewAppointment.jsx` at `/appointments`
    (hub CRUD) instead of `/all/appointment/new`; keep the legacy endpoint
    as a thin adapter during transition. *(Done: `appointmentFunc` in both
    `doc_dash` and `doc_dash_old` now POSTs `/appointments` with a
    hub-shaped payload (`patient_id`, `appt_datetime`, `duration_mins`,
    `service_name`, `notes`, `source: 'admin'`) via `_postApi` (JWT +
    facilityId attached); `controller/doc.js` `exports.appointment` is now a
    thin adapter — `query_type='insert'` maps the legacy fields onto the hub
    create and delegates to `controller/appointments.js` (conflict checks +
    reminders + `appointment_booked` notification), while read/delete
    `query_type`s still call the legacy `CALL appointment(...)` proc. The
    legacy route is now `authenticate` + `requireFacilityScope`-gated like
    the hub routes; `requireFacilityScope` back-fills a missing body
    `facilityId` from the caller, so the delegation always gets a valid
    facility. No remaining frontend callers of `/all/appointment/new`.)*
11. ✅ **Module adapters.** For dental/radiology, add a write-through: after
    module create/status-change, upsert the mirrored row in `appt_master`
    (or move those modules fully onto the hub with `module_appt_id`).
    *(Done: `services/apptSync.js` is the single choke point — it fires
    `appointment_cancelled`/`appointment_no_show` + skips stale reminders on
    sync. Wired: dental create/cancel/no-show/reschedule **+ confirm /
    check-in / complete (+ the auto-scheduled follow-up row the
    `complete_appointment` proc creates when `requires_follow_up` is set)**;
    radiology create/update/check-in/status/delete **+ examinations
    create/complete (`radiology-examinations.js`), the DICOM
    image-received webhook (`radiology-dicom-webhook.js`, sync runs after
    COMMIT so it is not entangled with the webhook transaction), and the
    payment-created appointments (`radiology-billing.js`
    `onPaymentComplete`)**. Adapter fixes landed with this item: the
    existing-row lookup now keys on the canonical module key
    (`row.appointment_id || row.id` — dental rows carry both, and the old
    `row.id`-only lookup missed every dental row, INSERTing a duplicate
    master row on each sync), `radiology_appointments.duration_minutes` is
    read (was hard-coded 60), `checked-in` maps to `checked_in`, and
    `syncRadiologyAppointment(appointmentId)` joins procedure / patient /
    staff names so the mirror shows real names. All syncs are non-fatal
    fire-and-forget by design — a sync hiccup never fails the module write.)*
12. ✅ **Fix KPI + analytics** to count `appt_master` (and add a `source`
    breakdown); retire `appointment`/`appointments` legacy tables once no
    longer referenced. *(Done: `reports-kpi.js` `fetchTodayAppointments` now
    counts `appt_master` first — hub status definition (`NOT IN cancelled /
    no_show / rescheduled`) — then adds legacy rows (`appointment`,
    `appointments`, `dental_appointments`, `radiology_appointments`) that are
    NOT yet mirrored, anti-joined on the backfill's exact
    (module, module_appt_id) linkage keys so nothing double-counts. Legacy
    tables can be retired once the write-through adapter (item 11) is
    complete and their rows are fully mirrored.)*

**Verify:** end-to-end booking via doctor UI → visible in hub calendar,
queue, analytics; dental/radiology appointments appear in hub with correct
module tag; KPIs match hub counts. *(2026-08-05: item 11 done — write-through
verified with a mocked-DB test: two syncs of the same dental row produce one
INSERT + one UPDATE, proving the duplicate-row bug is gone. Remaining legacy
tables (`appointment`, `appointments`, `dental_appointments`,
`radiology_appointments`) can be retired once a data audit confirms full
mirroring. One known pre-existing gap, out of scope: the standalone
`scheduleFollowup` handler passes 6 args to a 5-param proc — verify against
the live DB before using it.)*

### Phase 3 — Notifications UX (P1) · ✅ DONE

13. ✅ **Move doctor approval flow off PouchDB** to `notificationService`
    (`NEW_APPOINTMENT_REQUEST` / `APPOINTMENT_SENT` event types with
    `specific_user_ids`); delete the PouchDB path once migrated. *(Done:
    rules seeded by migration `20260804000010`; patient booking
    (`patient/actions/appointments.js`) and doctor review
    (`doc_dash/actions/appointmentsAction.js`) now POST `/notifications` with
    `specific_user_ids` — the PouchDB `createNotification` calls are gone.
    Note: the PouchDB appointment-data storage itself stays until item 10
    routes the doctor path through the hub.)*
14. ✅ **Reminder health panel.** Admin view of `appt_reminders_queue` counts
    (pending/sent/failed/skipped) + per-channel status; alert on high failure
    rates (offline installs with no SMS/email config). *(Done:
    `GET /appointments/reminders/health` + admin panel at
    `/me/admin/reminder-health` with stat cards, channel/type breakdowns,
    failure rate, last-7-days failures and last error. 2026-08-05: the
    **WhatsApp channel is now live** — `scheduleReminders` and the website
    booking confirmation queue a `whatsapp` channel row per appointment when
    `TERMII_WHATSAPP_ID` is set, the reminder sweep routes them through
    `smsApi.sendWhatsApp` (Termii `/api/sms/send`, `channel:'whatsapp'`,
    `from` = WhatsApp device name), and the health panel shows WhatsApp
    configured/not-configured alongside SMS/email. 2026-08-05: the panel now
    has **Send test SMS / Send test email** buttons hitting
    `POST /appointments/reminders/test-send` (auth + facility-scoped +
    rate-limited) — a one-off real message through Termii/Resend with the
    provider's own error surfaced (bounded 10 s timeout), so admins can
    verify keys without waiting for a real reminder.)*
15. ✅ **Configurable reminder offsets** per facility (facility settings table
    or `facility_settings` column) consumed by `scheduleReminders`. *(Done:
    `facility_settings` table (migration `20260804000009`);
    `scheduleReminders` reads JSON `reminder_offsets` (24h/1h/same_day_hour)
    with defaults; `GET/PUT /appointments/reminders/settings` + editor in the
    reminder-health panel.)*
16. ✅ **Patient-facing hub pages** in the patient portal: upcoming/history +
    cancel/reschedule (reuse `appt_public_tokens` types). *(Done:
    backend `GET /appointments/public/lookup` (phone/reference, PHI-safe — no
    phone/email/notes in the response) + new two-step token endpoints in
    `appointments-public.js`: `POST /appointments/public/cancel-token` /
    `cancel` and `reschedule-token` / `reschedule`, reusing the `cancel` /
    `reschedule` types in `appt_public_tokens`. Step 1 proves ownership — the
    phone must match the appointment's `patient_phone` and the status must be
    open (`pending_confirmation`/`scheduled`/`confirmed`) — and issues a
    30-min token; step 2 consumes it. Reschedule mirrors the hub path exactly
    (old row → `rescheduled`, new row created, reminders re-scheduled,
    stale reminders skipped, `appointment_rescheduled` notification fired;
    `genRef`/`scheduleReminders` re-exported from `appointments.js`). Cancel
    skips pending reminders and fires `appointment_cancelled`. Frontend: new
    `MyAppointments.jsx` at `/user/my-appointments` (nav link in the patient
    navbar) — phone/reference lookup form, Upcoming + History sections,
    per-card Reschedule / Cancel with confirm modals, facility/phone prefilled
    from the logged-in patient where available.)*
    *(2026-08-05 hardening: cancel/reschedule codes are now delivered
    OUT-OF-BAND — never returned in the HTTP response. `cancel-token` /
    `reschedule-token` issue an 8-char unambiguous code (`genPatientCode`, no
    0/O/1/I) into `appt_public_tokens` and hand it to the patient over SMS
    (Termii `smsApi.sendSMS`) and email (Resend `emailApi.sendMail`), the
    same services the booking confirmation-link flow uses
    (`deliverPatientToken`; `patient_email` added to `verifyOwnership` so the
    email channel works). The response only reports `sent_to`/expiry — the
    portal then prompts the patient to paste the code they received (code
    input    normalises to uppercase alphanumerics), with a Resend button; a
    short expiry note is shown. Verified with a mocked-DB test: response has
    no token, SMS/email both carry the 8-char code, cancel with the code
    succeeds, and re-use / wrong codes are rejected. Every patient-facing
    reminder + verification-code SMS/email now also carries the appointment
    reference (`appt_ref` — added to the reminder-sweep JOIN select) so
    patients can always look the appointment up in the portal by reference.)*

**Verify:** approval notification appears for the target doctor's bell
across devices; failed-reminder counts visible in admin; patient portal
shows hub appointments.

### Phase 4 — Features & polish (P2) · ✅ DONE (2026-08-05)

17. ✅ **Recurring appointments.** Migration `20260804000011` adds
    `telemedicine_link` / `repeat_rule` / `series_id` (+ `idx_series`).
    `POST /appointments/series` creates a parent row (carries `repeat_rule`
    JSON, `series_id` = own id) + real instances that flow through
    queue/calendar/analytics; every occurrence is provider-conflict-checked
    BEFORE any insert (409 lists conflicting datetimes, no partial data);
    `GET /appointments/series/:id` returns parent + instances (parent
    excluded from the list — `id <> :id`). All datetime math funnels through
    one `fmt()` helper so the conflict check and inserts can never drift.
18. ✅ **Waiting room / wait-time.** `GET /appointments/wait-time` —
    per-provider queue walk (seeded from now), returns per-appt
    `estimated_start` / `wait_minutes` / `ahead_of_you`; the hub's Today
    Queue renders a `~Xm` chip per appointment.
19. ✅ **Telemedicine links.** `telemedicine_link` accepted on create, settable
    via `PUT /appointments/:id/telemedicine`, surfaced in queue / calendar /
    detail modal, with a **Join Call** button on `in_consultation` rows.
    Quick Book modal has a telemedicine link field + visit-type picker.
20. ✅ **Provider registry UI.** Providers tab in the hub: create / edit
    (name, specialty, module, colour) / activate-deactivate via
    `POST /appointments/providers` + `PUT /appointments/providers/:id`
    (COALESCE-based partial update, `is_active` toggle).
21. ✅ **Analytics polish.** `rescheduled` excluded from summary + provider-day
    counts; new `GET /appointments/analytics/cancellations` (reasons +
    cancellation rate) and `GET /appointments/analytics/provider-day`
    (per-provider per-day completed/no-show); both rendered in the Analytics
    tab.

**Verify:** manual QA — create a series → all occurrences visible in
calendar; telemedicine book → link renders + Join Call on start; provider
CRUD round-trips; analytics numbers agree with the queue.

---

## 4. Open decisions for product owner

- **Source of truth**: is `appt_master` the canonical store going forward, or
  should module tables remain authoritative with a sync layer?
- Should public booking require a facility booking token (SMS/email issued),
  or stay open with rate limiting only?
- Do offline installs need SMS/email (Twilio/nodemailer config), or is
  in-app-only acceptable for reminders?
