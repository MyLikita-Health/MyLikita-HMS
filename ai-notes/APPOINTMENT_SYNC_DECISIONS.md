# Appointment Sync & Notifications — Product-Owner Decision Log

**Date:** 2026-08-05 · **Status:** ⏳ Decided — supersedes §8 of `APPOINTMENT_SYNC_AND_NOTIFICATIONS_PLAN.md`
**Scope:** Answers the six product-owner questions so Phase B (cloud relay + pull sync) can be implemented without ambiguity.
**Decided by:** Engineering lead on behalf of the product owner, grounded in the existing codebase (offline Windows installer, per-facility `facility_settings`, `appt_master` hub, Termii/Resend integration, patient portal with token-based cancel/reschedule).

---

## Decision summary

| # | Question | Decision |
|---|---|---|
| Q1 | Termii/Resend billing model | **Per-hospital own API keys (v1)**. No central keys, no metering. |
| Q2 | Pull cadence for offline installs | **2 min default**, per-facility override (`sync_pull_interval_min`, 1–60 min). Reachable deployments use direct webhook push (near-real-time), pull is the fallback. |
| Q3 | Website v1 appointment scope | **Book + view status only.** Confirm/decline via the existing token link. Cancel/reschedule from the website is **v2** — the patient portal already covers self-service. |
| Q4 | Relay PHI (phone/email) | Relay **buffers minimal contact info** (name, phone, email, datetime) as a pass-through for the hospital's pull, **never uses or sends from it**, 14-day retention, 72 h TTL on undelivered bookings. |
| Q5 | Provider external-id mapping | Website bookings arrive **unassigned**; staff map later via hub UI (`appt_providers.external_id`). Provider-list sync from the hospital is **out of scope** (impossible for offline). Notify-on-assignment hook. |
| Q6 | Multi-facility website | Contract is **multi-facility from day one** (`facility_id` per booking; one site can host several facilities). **Group-level reporting on the website is not a relay feature in v1** — the website aggregates its own bookings client-side. |

---

## Q1 — Billing model for Termii / Resend

**Question:** Does each hospital bring its own API keys, or does MyLikita hold central keys and meter usage per facility?

**Decision: Per-hospital own API keys.** Every facility — offline, self-hosted, or cloud — provides its own `TERMII_API_KEY`, `TERMII_SENDER_ID`, `TERMII_WHATSAPP_ID`, `RESEND_API_KEY`, `EMAIL_FROM`. No central keys, no usage metering in v1.

**Rationale**
- **Offline installs make metering unreliable.** An on-premise server can be disconnected for days. A central-key model needs reliable usage reporting to bill; an offline server cannot guarantee that, and its keys must live on client hardware regardless (credential-leak surface with no metering upside).
- **We already shipped the per-hospital UX.** The installer's `OFFLINE_INSTALLATION_GUIDE.md` §1.1 is a pre-install "SMS/email configuration sheet" that collects exactly these credentials, and the Reminder Health panel's "Send test SMS / email" buttons verify them per facility. Per-hospital keys are the status quo we built.
- **Tenant isolation.** One facility exhausting its Termii balance (or getting banned for spam) must not take down other tenants. Own keys fail closed per tenant.
- **Billing simplicity.** No meter, no per-facility invoice reconciliation, no central API-key rotation affecting every client. The client's Termii/Resend bill is their own.

**Impact on Phase B**
- The relay needs **no billing/metering fields** — no usage counters, no per-facility credit columns.
- The cloud super-admin console issues `sync_key` + `website_key` only; **not** Termii/Resend keys.
- `.env` templates (installer `postinstall.cmd`, `backend/.env.example`) already carry the per-hospital keys — unchanged.

**Escape hatch (v2, optional):** a "managed channels" plan for cloud tenants where MyLikita holds central keys and bills by message count. The architecture doesn't preclude it — the notification cron reads keys from env, so a future managed mode would inject tenant keys at runtime. Not built now.

---

## Q2 — Pull cadence for offline installs

**Question:** Is a 2-minute default pull OK, or do clients expect near-real-time (~10–15 s, longer-lived connection)?

**Decision: 2-minute default pull for offline/NAT installs**, overridable per facility via `facility_settings.sync_pull_interval_min` (validated 1–60 min). Reachable deployments (cloud, self-hosted with a public URL) get **direct webhook push** — near-real-time, zero polling latency — with the pull as the fallback path when the push fails.

**Rationale**
- **The patient isn't waiting in real time.** A website booking lands on the dashboard within ~2 minutes; the confirmation link/notification is sent by the hospital server *after* the pull (seconds-to-minutes later). Booking a dental appointment is not a chat message — 2 minutes is imperceptible.
- **Near-real-time over NAT is not free.** ~10–15 s polling (or a persistent outbound tunnel) costs battery/bandwidth on the client server and complexity in the sync engine, for no user-visible gain in v1. The plan's own risk table accepts "seconds–minutes" for the confirmation request.
- **Reachable deployments shouldn't pay pull latency at all** — that's already the dual-path REV (§4.3): relay tries an immediate direct webhook push to the hospital's public URL; on failure the row buffers for the next pull. So "near-real-time" is delivered exactly where it's cheap.

**Impact on Phase B**
- `facility_settings` key `sync_pull_interval_min`, default `2`, range 1–60 (validation mirrors `reminder_offsets`/`reminder_channels` patterns).
- `services/relaySync.js` cron uses the interval; a webhook push attempt runs before buffering.
- Docs (Phase D4) state the guarantee honestly: *"Bookings appear on your dashboard within ~2 minutes; confirmations are sent shortly after."*

---

## Q3 — What can the website do with an appointment in v1?

**Question:** Book + view status only, or also cancel/reschedule (relay write-back to the hospital)?

**Decision: v1 = book + view status only.** The website can create a booking and poll its status (`confirmed` / `cancelled` / `rescheduled` / `expired`). Confirm/decline continues via the existing email/SMS token link (the `appt_public_tokens` confirmation flow, already live). **Cancel/reschedule from the website is deferred to v2.**

**Rationale**
- **Self-service already exists — in the right place.** The patient portal ("My Appointments", Phase 3 item 16) already offers token-based cancel/reschedule with an ownership-proof verification code delivered to the patient's phone/email. A website cancel button would duplicate this with *weaker* ownership proof (no verified contact) and add relay write-back + status-conflict handling — the exact complexity v1 is trying to avoid.
- **The plan already names it a non-goal** (§1 Non-goals): "Patient-facing reschedule/cancel from the website (only confirm/decline via token link, as today)."
- **One-way contract stays third-party friendly.** Two endpoints (`POST /v1/bookings`, `GET /v1/bookings/{ref}`) are trivial for an agency; write-back (status edits from the website into the hospital) is where contracts sprawl.

**Impact on Phase B**
- `relay_out_master` carries status changes **hospital → website only** (for the patient's status poll). No website-originated mutation endpoints.
- The reschedule `external_ref` propagation REV (§4.3) still applies — the *hospital's* own reschedule must flow to the website so the patient sees the new time. This is display-only, not website-initiated.

**v2 hook:** when a website-reschedule is eventually added, it goes through the relay as a *request* (not a direct write), landing in the hospital as a `pending_confirmation`-style row the staff confirm — mirroring booking, not bypassing the hub.

---

## Q4 — Should the relay hold patient phone/email at all?

**Question:** Relay carries contact info (so it could send confirmations while the hospital is offline), or zero contact info (hospital is the only sender, link minted only after pull)?

**Decision: The relay buffers minimal contact info (name, phone, email, datetime, external refs) as a pure pass-through — it never uses, sends from, or enriches it.** 14-day retention purge; 72 h TTL marks undelivered bookings `expired`. The hospital server is **always the only sender** of confirmations/notifications.

**Rationale**
- **The hospital is already the only sender.** Notifications fire from the hospital server's own cron (Termii/Resend) — that's the architecture in §3 and it's offline-safe by design. The relay holding contact info creates no new sending capability; the data must pass through the relay anyway because the website cannot reach an offline hospital directly.
- **Zero-contact is worse UX for no privacy gain.** If the relay dropped phone/email, the hospital would still receive them on the next pull from... nowhere — the website would need a second channel to deliver the patient's contact details, which is either another relay table (same PHI, worse shape) or the patient re-entering them. Buffer-as-pass-through is the minimal correct storage.
- **The risk is retention, not presence.** Minimal columns, 14-day purge, never used for marketing/analytics, TLS-only. This matches REV 12 ("v1 relay is a pass-through that never uses contact info") and §4.6.

**Impact on Phase B**
- `relay_in_master` keeps `patient_name / patient_phone / patient_email` (they're already in the schema) — **no change**.
- Add: a 72 h TTL job (`status='expired'` for un-pulled `new` rows) and a 14-day retention purge job on the relay.
- Confirmation link is minted **only after hospital pull** (already the plan). The website renders `expired` state ("request expired — please call the clinic") for TTL'd rows.

---

## Q5 — Provider external-id mapping

**Question:** Are website bookings "unassigned until staff map them", or must the website's provider list sync from the hospital first?

**Decision: Website bookings arrive unassigned (`provider_id` null) and staff map them later** via the hub Providers tab using `appt_providers.external_id` (Phase C3). **Provider-list sync from the hospital is now IN SCOPE (revised, Phase C2/C3)** — the hospital is *not* queried directly (it stays unreachable behind NAT); instead it **pushes** its mapped providers on the same outbound sync cycle as status changes (`POST /v1/out/providers` → relay `GET /v1/providers` for the website). This is the one direction that works offline, so the old "out of scope" reasoning no longer applies.

**Rationale**
- **Sync breaks the offline case.** The hospital is unreachable behind NAT; a website cannot fetch a live provider list from it. v1 must work with the hospital offline.
- **The website can still offer provider choice.** The website sends a `provider_external_id` (its own doctor slug). If the hospital has already mapped that slug to an `appt_providers.external_id`, the booking arrives **assigned**; otherwise it lands unassigned and appears in the dashboard as "no provider — assign".
- **The "doctor never notified" gap is already solved** (REV 6, Phase A): unassigned bookings trigger the facility-level clinician fallback on `appointment_booked`, and the notify-on-assignment hook pings the doctor the moment staff assigns one.

**Impact on Phase B**
- `createWebsiteBooking()` sets `provider_id` via the `external_id` lookup when a mapping exists, else null.
- Add the **notify-on-assignment hook**: when staff edits an unassigned website booking to set a provider, fire the provider lifecycle message (reuses `enqueueLifecycleRows` from Phase A).
- Phase C3 builds the `external_id` mapping UI in the hub Providers tab.

---

## Q6 — Multi-facility website (clinic groups)

**Question:** One website serving several hospitals? And does the product want group-level reporting on the website?

**Decision:** The contract is **multi-facility from day one** — `facility_id` is a required field on every booking, and a single website can host booking widgets for several of its hospitals (each with its own `website_key`). **Group-level reporting on the website is not a relay feature in v1.** The relay's job ends at per-facility delivery; the website may aggregate its own bookings client-side (every booking response carries `facility_id`).

**Rationale**
- **Multi-facility costs nothing at the contract level.** `facility_id` is already required; the relay already routes by it and dedupes by `(facilityId, external_ref)`. Supporting a clinic group is a matter of issuing multiple `website_key`s, not changing the schema (C4 already covers multi-domain registration per facility).
- **Group reporting is a website-side analytics feature**, not infrastructure. Building it into the relay would entangle BI with a pass-through buffer (and reintroduce the PHI-retention question at group scope). Keep the relay dumb.

**Impact on Phase B**
- `POST /v1/facilities/register` returns per-facility credentials; a group site registers each branch and holds a set of keys (or one key per domain).
- No group-level aggregate endpoints on the relay in v1.
- The booking widget accepts an explicit `facility_id` so one widget instance can be configured per branch page.

---

## What Phase B must NOT do (guardrails from these decisions)

1. No Termii/Resend key storage, metering, or usage counters anywhere in the relay.
2. No website-originated cancel/reschedule endpoints (v1).
3. No relay-initiated SMS/email (the relay never sends).
4. ~~No hospital→website provider-list sync~~ **REVISED (Phase C2/C3)**: hospital pushes mapped providers → relay `GET /v1/providers` → widget `loadProviders`. Only mapped+active, no PHI.
5. No group-level reporting endpoints on the relay.
6. The relay MUST implement the 72 h TTL and 14-day retention purge.

*Decisions reviewed against the existing codebase (Phase A delivery, patient portal, installer config sheet) — no conflicts found. Phase B can start.*
