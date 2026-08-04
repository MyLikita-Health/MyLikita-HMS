# Central Appointment Module — Full Implementation Plan

## Current State Summary

The platform has **4 siloed appointment systems** that don't talk to each other:
- **Dental** — most complete (reminders, follow-ups, availability, stored procs)
- **Radiology** — good request→appointment workflow, conflict detection
- **Surgery/Theatre** — full pre-op/post-op workflow
- **Doctor (General)** — legacy, basic, disconnected

The strategy is **not to rebuild from scratch** but to build a **Central Appointment Hub** that:
1. Provides a unified API and dashboard
2. Federates the existing module-specific systems (they keep their domain logic)
3. Adds the missing cross-cutting features (reminders, public booking, analytics)

---

## Architecture Decision

```
┌─────────────────────────────────────────────────────────┐
│              CENTRAL APPOINTMENT HUB                     │
│  appt_* tables  |  /appointments/* API  |  Unified UI   │
└────────┬────────┴──────────┬────────────┴───────────────┘
         │ references        │ delegates to
    ┌────▼────┐  ┌──────────▼──────────────────────────┐
    │ appt_   │  │  Module-specific systems (unchanged) │
    │ master  │  │  dental_appointments                 │
    │ table   │  │  radiology_appointments              │
    │         │  │  surgery_schedule                    │
    └─────────┘  │  (general) appointments              │
                 └─────────────────────────────────────┘
```

The `appt_master` table is a **lightweight index** — it stores the appointment's module type, module-specific ID, patient, provider, datetime, and status. The full details live in the module tables. This avoids duplicating data while enabling cross-module queries.

---

## Phase 1 — Core Data Model & API (Foundation)

### 1.1 Database Schema

**New tables needed:**

```sql
-- Central appointment index (lightweight, no duplication)
appt_master          -- cross-module appointment registry
appt_providers       -- provider availability (doctors, dentists, radiologists, etc.)
appt_provider_schedule  -- weekly availability per provider
appt_provider_blocks    -- leave/unavailability/blocked times
appt_service_types   -- procedure types with duration (dental scaling=30min, surgery=2h)
appt_reminders_queue -- unified reminder queue (replaces dental_appointment_reminders)
appt_waitlist        -- waitlist entries per slot
appt_public_tokens   -- tokens for patient self-booking links
```

**Migration file:** `20260506000001-central-appointment-hub.js`

### 1.2 Backend API Routes

```
POST   /appointments                    — create (any module)
GET    /appointments                    — list with filters
GET    /appointments/:id                — get with module details
PUT    /appointments/:id/status         — status transitions
PUT    /appointments/:id/reschedule     — reschedule with conflict check
DELETE /appointments/:id                — cancel

GET    /appointments/availability       — available slots (provider + date + service)
GET    /appointments/conflicts          — check for conflicts before booking
GET    /appointments/calendar           — calendar view (all modules)
GET    /appointments/queue              — today's queue for a provider/location

POST   /appointments/waitlist           — join waitlist
GET    /appointments/waitlist/:slotId   — get waitlist for a slot

GET    /appointments/providers          — list providers with specialties
POST   /appointments/providers/:id/schedule  — set weekly schedule
POST   /appointments/providers/:id/block     — block time

GET    /appointments/public/slots       — PUBLIC (no auth) — for patient portal
POST   /appointments/public/book        — PUBLIC — patient self-booking
GET    /appointments/public/:token      — PUBLIC — view/confirm via token

GET    /appointments/analytics/summary  — dashboard stats
GET    /appointments/analytics/no-show-rate
GET    /appointments/analytics/utilization
GET    /appointments/analytics/revenue-per-slot
```

### 1.3 Conflict Detection Engine

The core scheduling engine needs to prevent double-booking across all modules. Logic:

```
For a given provider + time window:
  1. Check appt_master for overlapping appointments
  2. Check module-specific table (dental_appointments, radiology_appointments, etc.)
  3. Check appt_provider_blocks (leave, unavailability)
  4. Return: available | conflict | warning (soft conflict)
```

---

## Phase 2 — Module Integration

### 2.1 Dental Integration

Dental already has the best system. The integration work:
- When `dental_appointments` is created/updated → sync a row to `appt_master`
- Add a DB trigger or application-level hook
- The dental UI stays unchanged; the central hub just reads from `appt_master` for cross-module views

### 2.2 Radiology Integration

Same pattern — `radiology_appointments` → `appt_master` sync.

The radiology appointment scheduler already has conflict detection; expose it through the central API.

### 2.3 Surgery/Theatre Integration

`surgery_schedule` → `appt_master` sync. Theatre appointments are long-duration (2–8 hours) so the conflict detection needs to handle multi-hour blocks.

### 2.4 Doctor (General) Integration

The legacy `appointments` table needs to be migrated to use `appt_master`. The doctor dashboard appointment components need to be updated to call the new central API instead of the legacy endpoints.

### 2.5 Nursing Integration

Nurses don't create appointments but need to:
- See today's queue for their ward
- Check patients in
- Update status (arrived, in consultation, etc.)

Add a nursing view to the central appointment dashboard.

### 2.6 Dental Lab Integration

Dental lab jobs have their own scheduling. The integration:
- Lab job due dates appear in the central calendar as "Lab: [job type]" blocks
- When a dental appointment requires a lab job, the lab job is linked via `appt_master`

---

## Phase 3 — Automated Reminders

The dental module already has `dental_appointment_reminders` and `dental_appointment_notifications` tables. The plan:

1. **Unify into `appt_reminders_queue`** — one table for all modules
2. **Background job** (node-cron, already installed) — runs every 5 minutes, processes pending reminders
3. **Channels**: SMS (Twilio, already configured), Email (Nodemailer, already configured), In-app (Socket.io, already configured)
4. **Schedule**: 24h before, 1h before, same-day morning
5. **Confirmation links**: Generate a token → patient clicks Yes/No → updates status

```javascript
// backend/services/appointmentReminders.js
// Runs via node-cron every 5 minutes
// Queries appt_reminders_queue WHERE scheduled_time <= NOW() AND status = 'pending'
// Sends via Twilio/Nodemailer/Socket.io
// Updates status to 'sent' or 'failed' with retry logic
```

---

## Phase 4 — Patient Self-Booking (Public API)

This is the "APIs that can be called from hospital website" requirement.

### Public Endpoints (no auth required)

```
GET  /appointments/public/providers?facilityId=&specialty=
GET  /appointments/public/slots?facilityId=&provider_id=&date=&service_type=
POST /appointments/public/book
     { facilityId, patient_name, patient_phone, patient_email,
       provider_id, service_type_id, slot_datetime, visit_type, notes }
GET  /appointments/public/confirm/:token?action=yes|no
```

The booking flow:
1. Patient visits hospital website → embedded booking widget calls these APIs
2. Selects specialty → gets providers
3. Selects provider → gets available slots (real-time)
4. Fills in details → appointment created with status `pending_confirmation`
5. SMS/email sent with confirmation link
6. Patient confirms → status → `scheduled`
7. Front desk sees it in the queue

### Visit Types
- `physical` — standard in-person
- `telemedicine` — video call (link generated)
- `home_visit` — home visit request (requires approval)

---

## Phase 5 — Unified Frontend Dashboard

### 5.1 Central Appointments Dashboard (`/me/appointments`)

The existing `/me/appointments` route currently shows a basic component. Replace it with:

```
AppointmentsDashboard
├── AppointmentCalendar (week/day/month view, all modules color-coded)
├── TodayQueue (real-time patient flow for front desk)
├── QuickBook (fast booking modal)
├── WaitlistPanel
└── AppointmentFilters (by module, provider, status, date)
```

Color coding by module:
- 🔵 General/Doctor — blue
- 🟢 Dental — green  
- 🟣 Radiology — purple
- 🔴 Theatre — red
- 🟡 Lab — yellow

### 5.2 Provider-Specific Views

Each module's existing appointment UI stays but gets enhanced:
- **Doctor dashboard** — upgrade from legacy calendar to new central API
- **Dental** — already good, just add central sync
- **Radiology** — already good, just add central sync
- **Theatre** — already good, just add central sync
- **Nursing** — new queue view showing today's patients

### 5.3 Queue Management (Real-time)

Using the existing Socket.io setup:
```
Room: `facility_${facilityId}_queue`
Events:
  - patient:checked_in
  - appointment:status_changed
  - queue:updated
```

Front desk sees live updates as patients check in and move through the system.

---

## Phase 6 — Billing & Insurance Integration

When an appointment is completed:
1. Auto-trigger a charge to `charges_fees` (consultation fee)
2. Link to `pending_txn` for billing
3. If insurance: flag for authorization tracking

The `appt_service_types` table stores the default fee per service type. On completion, the system creates the billing entry automatically.

---

## Phase 7 — Analytics Dashboard

New analytics endpoints + frontend dashboard:

| Metric | Query |
|---|---|
| No-show rate | `COUNT(status='no_show') / COUNT(*) by provider/date` |
| Doctor utilization | `SUM(duration_minutes) / available_minutes by provider` |
| Peak hours | `COUNT(*) GROUP BY HOUR(appointment_date)` |
| Revenue per slot | `SUM(consultation_fee) / COUNT(slots)` |
| Appointment trends | `COUNT(*) GROUP BY DATE, module_type` |
| Cancellation reasons | `GROUP BY cancellation_reason` |

---

## Implementation Sequence

| Sprint | Deliverable |
|---|---|
| **Sprint 1** | `appt_master` schema + migration + central API skeleton |
| **Sprint 2** | Conflict detection engine + availability calculator |
| **Sprint 3** | Dental + Radiology + Surgery sync to `appt_master` |
| **Sprint 4** | Unified calendar dashboard frontend |
| **Sprint 5** | Reminder queue + background job (SMS/Email) |
| **Sprint 6** | Public booking API + confirmation tokens |
| **Sprint 7** | Queue management (real-time Socket.io) |
| **Sprint 8** | Billing auto-trigger on completion |
| **Sprint 9** | Analytics dashboard |
| **Sprint 10** | Doctor dashboard upgrade + nursing queue view |

---

## Key Design Decisions

**Why `appt_master` instead of one big table?**
Each module has domain-specific fields (dental has `dentist_id`, `tooth_number`; radiology has `procedure_id`, `room_number`; surgery has `theatre_room`, `lead_surgeon`). Forcing everything into one table creates a sparse, unmaintainable schema. The hub pattern keeps domain logic in domain tables while enabling cross-module queries.

**Why keep module-specific APIs?**
Dental, radiology, and surgery already have working UIs and workflows. Replacing them would be high-risk with no user benefit. The central hub adds value on top without breaking what works.

**Why node-cron for reminders instead of a message queue?**
The app already uses node-cron (it's in `package.json`). A full message queue (Redis/Bull) would be the right long-term choice but adds infrastructure complexity. node-cron is sufficient for a hospital with hundreds of appointments per day.

---

Ready to start implementing? I'd suggest starting with Sprint 1 — the `appt_master` schema and central API skeleton — as everything else builds on it. Want me to proceed?