# Subscription & Billing Plan — Enforcing Paid Tiers Across MyLikita

**Status:** Plan (design phase — no code written yet)
**Date:** 2026-08-06

---

## 1. The goal

1. Nobody gets MyLikita free forever — every cloud facility starts on a **14-day trial**, then must hold an active plan.
2. Three editable tiers (**Basic / Standard / Premium**) across two product lines (**General Hospital**, **Dental Practice**), plus an **online Pay-As-You-Go** metered model.
3. **Every price and every included feature can be changed by the super admin at runtime** — no code deploys, reflected immediately everywhere (onboarding wizard, plan pages, enforcement).
4. Offline/self-hosted installs are enforced by **license level**, not subscription.

---

## 2. The core design principle — "module ceiling"

The platform already has a working module-access system, and the billing layer should **ride on top of it** instead of adding a parallel one:

```
effective modules a facility can use  =  (facility type modules ∩ plan modules)
```

- `facilityTypes.js` already computes the type module set (hospital, clinic+dental, pharmacy…).
- A plan defines the **ceiling** — the modules that tier pays for (e.g. Hospital Basic = `Records, Doctors, Nurse`).
- The admin's `accessTo` becomes the intersection. All existing enforcement follows automatically:
  - **UI:** WelcomePage tiles and the sidebar already filter on `accessTo` → locked modules simply disappear.
  - **API:** `requireModuleAccess('Radiology')` already 403s when a module isn't in `accessTo` → locked modules are hard-blocked server-side for free.

So **enforcement is one computed string**, and we reuse the existing `sync-access` machinery to recompute it whenever the plan or the type changes.

---

## 3. Data model (3 new tables — all super-admin editable)

### 3.1 `subscription_plans` — the catalog (super admin edits this freely)

| Column | Type | Notes |
|---|---|---|
| `id` | INT PK AI | |
| `product_line` | ENUM('hospital','dental') | Two catalogs |
| `tier` | ENUM('basic','standard','premium') | |
| `name` | VARCHAR(120) | e.g. "Standard — Dental" |
| `description` | TEXT | Shown in pickers |
| `price_monthly` | DECIMAL(12,2) | NGN, 0 = n/a |
| `price_yearly` | DECIMAL(12,2) | NGN, 0 = n/a |
| `billing_model` | ENUM('subscription','payg','both') | |
| `features` | JSON | **Allowed module keys** — the ceiling |
| `limits` | JSON | `{ doctors, patients, practitioners, visit_band_min, visit_band_max }` |
| `payg_rates` | JSON | `{ new_patient_visit, follow_up_visit, pharmacy_request, laboratory_processed }` |
| `is_active` | TINYINT | Hidden from pickers when 0 |
| `is_trial_default` | TINYINT | Used when onboarding starts a trial |
| `trial_days` | INT DEFAULT 14 | Free trial length |
| `sort_order` | INT | Display order |
| `created_at` / `updated_at` | DATETIME | |

### 3.2 `facility_subscriptions` — one row per facility

| Column | Type | Notes |
|---|---|---|
| `id` | INT PK AI | |
| `facility_id` | VARCHAR(50) UNIQUE | one active subscription |
| `plan_id` | INT FK | current plan |
| `status` | ENUM('trial','active','past_due','expired','suspended','cancelled') | |
| `billing_model` | ENUM('subscription','payg') | |
| `trial_started_at` / `trial_ends_at` | DATETIME | |
| `current_period_start` / `current_period_end` | DATETIME | renewal window |
| `last_invoice_at` | DATETIME | |
| `updated_by` | VARCHAR(100) | super admin who changed it |
| `created_at` / `updated_at` | DATETIME | |

### 3.3 `usage_events` — Pay-As-You-Go metering

| Column | Type | Notes |
|---|---|---|
| `id` | INT PK AI | |
| `facility_id` | VARCHAR(50) | |
| `plan_id` | INT | rate snapshot at time of event |
| `event_type` | ENUM('new_patient_visit','follow_up_visit','pharmacy_request','laboratory_processed','surgery_processed') | surgery_processed = theatre/surgery usage, ₦300 |
| `ref` | VARCHAR(100) | patient id / dispense id / lab result id — **dedupe** |
| `quantity` | INT DEFAULT 1 | |
| `unit_price` | DECIMAL(12,2) | copied from plan at event time |
| `amount` | DECIMAL(12,2) | qty × unit price |
| `status` | ENUM('accrued','invoiced','waived') | |
| `created_at` | DATETIME | |

`UNIQUE (facility_id, event_type, ref)` → an event can never be double-counted (idempotent metering).

### 3.4 (optional) `facility_plan_audit` — history of every plan change, who did it, from/to, effective_at.

---

## 4. Seed catalog — exactly the pricing given

### General Hospital (monthly subscription by visit band)
| Tier | Modules (features) | Monthly | Band |
|---|---|---|---|
| Basic | Record (Records), Doctor (Doctors), Nursing (Nurse) | 50,000 | 0–100 visits |
| Standard | Basic + Laboratory, Pharmacy, Account (patient billing, revenue/expense reports, health insurance) | 100,000 | 101–250 |
| Premium | Standard + Full Accounting, Inventory, Radiology, Theatre, HMO interface, Appointments | 150,000 | >250 |

### General Hospital — Online Pay-As-You-Go
| Event | Rate |
|---|---|
| New patient visit | 1,000 |
| Follow-up visit | 500 |
| Pharmacy request | 300 |
| Laboratory processed | 300 |
| Surgery / theatre processed | 300 |

### Dental Practice
| Tier | Modules | Monthly | Yearly | Limits |
|---|---|---|---|---|
| Basic | Records, Dental, Accounts (basic billing); smart scheduling, dental chart, billing & quotes | 25,000 | 250,000 | 3 doctors, 5,000 patients |
| Standard | + Dental Lab, Accounts, Pharmacy (Oral Care Shop), Inventory, advanced reports, WhatsApp reminders | 50,000 | 500,000 | 7 practitioners, unlimited patients |
| Premium | + Full Accounting, Health Insurance, online booking, multi-specialty, automatic WhatsApp reminders | 100,000 | 1,000,000 | unlimited |

> Note: Hospital *monthly subscription* prices are banded by monthly visits; the band is stored in `limits.visit_band_min/max` and surfaced in the picker. Dental has no banding — limits are seats/patients.

---

## 5. Enforcement layers (defense in depth)

### Layer 1 — Feature availability (modules)
- Compute `accessTo = typeModules ∩ plan.features` at: onboarding, plan change, sync-access, and login (`/auth/me` recomputes from DB).
- Existing `requireModuleAccess` middleware enforces at every route. **Zero per-route work** — the ceiling flows through.
- WelcomePage/sidebar hide locked tiles automatically.

### Layer 2 — Hard limits (seats/records)
- New middleware/helper: `enforcePlanLimit(facilityId, 'practitioners')` and `('patients')`.
- Hooked into:
  - `users.js: exports.create` (staff/doctor creation) → practitioners limit
  - patient registration (`record.js`) → patients limit
- Returns `402 Payment Required` with a friendly message: *"Your plan allows up to 7 practitioners. Upgrade to Premium to add more."*

### Layer 3 — Pay-As-You-Go usage metering
- Helper `recordUsage(facilityId, eventType, ref)` called from the four write points:
  - new patient registration → `new_patient_visit`
  - follow-up consultation → `follow_up_visit`
  - pharmacy dispensing → `pharmacy_request`
  - lab result processed → `laboratory_processed`
- **Accrue-then-invoice** (recommended): never block mid-workflow; usage accumulates, invoice at period end. Show a live "usage this period" meter + warning banner past a threshold (super-admin configurable). Optional hard block flag per plan.

### Layer 4 — Trial
- Cloud onboarding creates the facility with a `trial` subscription: `trial_days` (default 14) from `subscription_plans.trial_days`.
- The admin sees a countdown banner. On expiry → status `expired` → modules collapse to the free/trial tier (e.g. Records + Admin only), writes blocked with an upgrade modal (Paystack/Flutterwave).
- A daily cron (`services/subscriptionCron.js`) flips expired/past-due states and fires the recompute.

### Offline installs — license mode (different product, same catalog)
- Offline = **yearly license** (level: Basic/Standard/Premium for the product line they bought). `subscription_plans.license_price_yearly` holds the yearly license price (dental: 250k/500k/1M; hospital: to be priced — nullable for now).
- **Renewal happens in-app**: when the offline server has internet, the facility admin renews/extends the license from Settings (Paystack/Flutterwave) — the server calls the platform, gets a new expiry, and updates `facility_subscriptions.license_key / license_expires_at`.
- **Multi-year**: a facility can pay for 2+ years at once — `facility_subscriptions.license_years` (default 1) and `license_expires_at = NOW() + INTERVAL license_years YEAR`.
- License file stores `plan level + expiry + facility id`; the installer's `seed-access.js` already computes accessTo — extend it to apply the license ceiling. Works fully offline; phone-home only when renewing.

---

## 6. Super-admin configurability (pricing + features, anytime)

### API (all super-admin gated, mirror existing `/facilities/*` pattern)
- `GET /plans` — active plans (public-lite: no limits internals)
- `GET/POST/PUT/DELETE /api/plans` — full CRUD (super admin)
- `GET /api/subscriptions` — all facilities' plans
- `POST /api/subscriptions` — assign plan / start trial / activate
- `POST /api/subscriptions/:id/status` — suspend / extend / cancel / waive usage
- `POST /api/plans/:id/apply` — recompute accessTo for every facility on that plan

### UI (Super Admin Console)
- **Plans page** (`/super-admin/plans`): edit price, toggle features (module checkboxes), limits, PAYG rates, activate/deactivate, set trial default. Mirrors the ManageFacilities design system.
- **Facilities drill-down**: add a "Subscription" section — current plan, status, trial expiry, seats used, **Change plan / Extend trial / Suspend / Activate** buttons.
- Any save immediately affects the onboarding picker, plan pages and enforcement (data-driven, no redeploy).

---

## 7. Frontend surfaces

1. **Onboarding wizard (cloud mode)** — new step after Facility: "Choose your plan" card list (prices read live from `GET /plans`, so edits show instantly) → starts 14-day trial of the chosen tier.
2. **Facility admin → Settings → "My Plan" card**: tier, price, renewal date, limits used (`4/7 practitioners`), usage meter (PAYG), Upgrade CTA.
3. **Banners**: trial countdown, expired lock screen with upgrade modal, near-limit warnings.
4. **Super admin**: Plans page + subscription management in facility drill-down.

---

## 8. Payment integration (later phase)

- NGN pricing → **Paystack** (and/or Flutterwave). Webhooks: `subscription.activated` → activate; `invoice.paid` → renew period; `invoice.failed` → past_due → suspend after grace.
- No payment gateway in the dev/test loop — the subscription API works with manual "activate" so CI/preview stays deterministic.

---

## 9. What already exists to reuse (verified)

- `facilityTypes.js` — type module sets + `resolveEffectiveModules` + `getAccessToString`
- `routesHelper.requireModuleAccess` — route gating by accessTo (super admin bypass)
- `sync-access` endpoint + `ManageSpecialties` "Sync Admin Access" — the recompute machinery
- `facility_settings` key-value — quick per-facility flags (e.g. plan banner dismissed)
- HMO/insurance infrastructure: `hmo`, `hmo_providers`, `hmo_registration_table`, `insurance_schemes`, `managedcare.js` — Premium tier "HMO interface" already has backend tables to hook into
- Super admin console + gating (`isSuperAdmin`, privilege bit 8)

---

## 10. Phased implementation

| Phase | Scope | Est. |
|---|---|---|
| **P1** | Migrations (3 tables + seed catalog with the exact pricing) + plans CRUD API + **Plans page** in super admin console | 1.5 days |
| **P2** | Plan-aware accessTo ceiling + trial on onboarding + plan-change recompute + facility subscription management (assign/extend/suspend) in drill-down | 1.5 days |
| **P3** | Hard limits (practitioners, patients) with friendly 402s + "My Plan" settings card + banners | 1 day |
| **P4** | PAYG usage metering (4 event hooks) + usage meter UI + invoice generation + subscription cron | 1 day |
| **P5** | Offline license mode (license file, plan ceiling in `seed-access.js`, reinstall preservation) | 1 day |
| **P6** | Payment gateway (Paystack webhooks), upgrade/expired lock UX, HMO interface wiring to Premium tier | 1.5 days |

---

## 11. Decisions locked (2026-08-07)
1. **PAYG tracks surgery/theatre usage** — `surgery_processed` event at ₦300, alongside the four original events.
2. **Offline = yearly license** — renewed in-app when the server is online, 2+ years purchasable (`license_years`).

## 13. Phase status (2026-08-07)

| Phase | Status |
|---|---|
| **P1** catalog + Plans console | ✅ done |
| **P2** plan-aware accessTo ceiling + trial on onboarding + subscription management in drill-down | ✅ done |
| **P3** hard limits + "My Plan" card + banners | ✅ done |
| **P4** PAYG metering hooks + usage UI + cron | ✅ done |
| **P5** offline license renewal | ✅ done |
| **P6** payment gateway | pending |

### P5 delivered
- **Signed license files** — `licenseService.js`: RSA-SHA256 over canonical sorted JSON. Platform signs with a private key (persisted `config/license-keys/`, gitignored); offline installs ship `config/license-public.pem` and VERIFY with only the public key — a leaked installer can never forge licenses. An offline server with no key can never self-mint (auto-generate is guarded with a loud warning + only when no public key exists at all).
- **License file contents** — `license_key`, `facility_id`, `facility_name`, `product_line`, `tier`, `plan_id`, `plan_name`, `license_years`, `issued_at`, `license_expires_at`, `signature`. Tamper detection verified: any field edit invalidates the signature.
- **Super admin issue** — `POST /api/licenses/:facilityId/issue` (1/2/5-yr buttons in the SubscriptionPanel drill-down): upserts the facility_subscriptions license row, applies the plan ceiling, returns the signed file with a Download button. **Key is preserved across reissues** (only years/expiry change) so deployed offline installs never strand.
- **Offline activation** — `POST /api/license/activate` in Settings → Offline License card: pastes the license JSON, verifies signature + facility binding + expiry + active plan, upserts the row, applies the ceiling, persists `backend/data/license.json` for reinstall preservation. Wrong-facility + expired + tampered licenses all rejected (verified).
- **Phone-home renewal** — `POST /api/license/renew` (+ platform's public `POST /api/license/check`, keyed on license_key, rate-limited): the offline server calls the platform when online, gets the authoritative status (extended/upgraded by the super admin), refreshes local state, re-signs a fresh local file. Verified: local expiry moved 2028 → 2031 → 2029 across reissues; the stable key keeps renewals working.
- **Install-time ceiling** — `seed-access.js` now reads `backend/data/license.json`, VERIFIES the signature with the shipped public key, and intersects the license plan's modules with the type modules (Dashboard+Admin always kept). Tampered files fall back to full type modules. Also fixed dual-layout path resolution (installed `C:\MyLikita\scripts` vs source tree), process-env DB precedence, and mysql2 resolution.
- **UI** — `LicenseCard.jsx` in Settings (status badge, key, expiry + days-left countdown, activate textarea, renew-with-online controls); `MyPlanCard` now shows LICENSE EXPIRES (was showing the stale trial date) + a 60/14-day license-expiry warning banner.

### P4 delivered
- **Metering core** — `recordUsage(facilityId, eventType, ref)` in `subscriptionService.js`: reads the plan's `payg_rates`, `INSERT IGNORE` into `usage_events` keyed on `(facility_id, event_type, ref)` for idempotency, fire-and-forget from the write path (never breaks a clinical write). Non-billable plans (dental subscription models) are skipped automatically.
- **5 event hooks** — `new_patient_visit` (patientrecords.newRecord + dental.createPatient), `follow_up_visit` (diagnosis consultationRecord, ref = consult_id), `pharmacy_request` (drugs.dispenseDrugs — once per request, not per line), `laboratory_processed` (lab.saveTestResult, ref = booking_no), `surgery_processed` (surgery schedule marked completed, ₦300).
- **Usage meter** — `getPaygUsage` period summary (per-event counts + ₦ totals); `GET /api/plans/usage/payg` endpoint; MyPlanCard renders the PAYG meter only for `payg`/`both` plans.
- **Invoices** — `usage_invoices` migration (`uq_invoice_no`, JSON items); `generateUsageInvoice` accrues only un-invoiced events, marks them `invoiced`, and returns `no_events` (no row) when nothing accrued — verified: second run never double-bills.
- **Subscription cron** — `subscriptionCron.js` daily 00:15: trial→expired, active→past_due (grace), past_due→expired, license→expired; collapses expired facilities to the free tier (Dashboard+Admin+Records); per-row + pass-level try/catch so a missing table can never crash the app.
- **Bonus fix** — `getAwaitingSpecialistReview` crashed the Admin Dashboard on MySQL 8 (`only_full_group_by` across the consultations JOIN); fixed with `ANY_VALUE`.

### P2 delivered
- `backend/services/subscriptionService.js` — the enforcement core: `getFacilitySubscription` (plan+subscription join), `effectiveAccessModules(type, slugs, plan)` = **type/specialty modules ∩ plan modules** (always keeps Dashboard+Admin so a locked facility stays usable), `applyPlanCeiling(facilityId, plan?, transaction?)` writes the intersection to all admin users (role admin/Administrator/super_admin or privilege ≥ 4).
- **Onboarding (cloud)** — `createFacility` now accepts `planId`; seeds a `trial` `facility_subscriptions` row (trial days from the plan) and applies the ceiling inside the transaction; falls back to the product line's `is_trial_default` plan.
- **Onboarding (offline claim)** — `claimFacility` seeds the product line's trial-default plan as a trial subscription and applies the ceiling in-transaction (fix: passes `t` + plan override so the uncommitted row is visible).
- **Plan change** — `setSubscription` recomputes the ceiling after every assign/change/extend/suspend; upgrade widens accessTo, downgrade narrows it.
- **Recompute endpoints** — `POST /api/subscriptions/:facilityId/apply` (one facility) and `POST /api/plans/:id/apply` (all facilities on a plan, after the super admin edits modules).
- **Plan-aware sync-access** — `POST /facilities/:facilityId/sync-access` now intersects the plan ceiling.
- **Drill-down UI** — `frontend/src/components/admin/SubscriptionPanel.jsx` mounted in the facility modal: plan, status/tier badges, trial & license expiry, change-plan dropdown, +14d trial, suspend/activate, re-apply ceiling. Verified live in preview.
- **Bugfix** — `models/hospital.js` now declares `tableName: 'hospitals'` (was querying `Hospitals`, which silently returns 0 rows on case-sensitive MySQL 8 fresh installs; only MariaDB's case-insensitivity masked it).

### Verified on a fresh MySQL 8 install (Docker test DB)
- Cloud onboarding w/ planId → trial row + ceiling (hospital basic = Dashboard,Admin,Records,Doctors,Nurse; premium = 12 modules).
- Plan change Basic→Premium widened accessTo in real time; suspend/extend/activate all worked.
- Offline claim → Dental Basic trial + clinic∩dental ceiling.
- Apply endpoints + plan-aware sync-access all return the expected accessTo.

### P3 delivered
- **Seat enforcement service** — `subscriptionService.countPlanUsage(facilityId)` counts `practitioners` (clinical staff, excluding super admins + non-clinical roles), `doctors` (role-matched clinical), `patients` (patientrecords rows); `enforcePlanLimit(facilityId, key)` returns `{ code:'limit_exceeded', limit, used, message }` when `used >= limit` (null when no subscription row or unlimited → never locks out an unclassifiable facility).
- **402 hooks** — `users.create` (practitioners), `patientrecords.newRecord` (patients), `dental.createPatient` (patients). All emit `{ success:false, error: message, code, limit, used }` with the friendly upgrade message. Super admins (privilege 8) are exempt.
- **My Plan card** — `frontend/src/components/admin/MyPlanCard.jsx` in Settings: plan tier/name, TRIAL badge + days-left countdown, billing model, limit meters (Practitioners/Doctors/Patients with used/limit), period end, Upgrade CTA. Backed by `GET /api/plans/usage` (auth-gated to the caller's own facility).
- **`POST /api/plans/limit-check`** — pre-flight seat check endpoint (any authed user, own facility).
- **Critical bugfix (found by review)** — `config/passport.js` JWT strategy was passing `req.user` as a Sequelize *array*, so `req.user.facilityId` was always undefined on every passport-gated handler (tenant scoping silently broke; the usage endpoint 404'd / returned null). Now unwraps to `dataValues`. `routesHelper.allowOnly` + `requireModuleAccess` hardened to accept array / instance / plain-object shapes — **without this, the super-admin-gated `/api/plans*` + `/api/subscriptions*` routes crashed after the passport fix**. Verified live: super admin 200, facility admin 403, own usage 200.

### Verified on the fresh MySQL 8 test DB
- Usage endpoint returns plan + seat counts; My Plan card renders live in Settings (Trial badge, 14 days, 1/3 practitioners, 0/5000 patients).
- 2nd/3rd doctor created OK; 4th blocked with 402 + friendly message. 2 patients OK; 3rd blocked with 402.
- Super-admin gating re-verified after the passport fix (200/403/200 as expected).

## 12. Open decisions for you

1. **Block vs accrue on PAYG**: hard-block when the wallet/balance runs out, or always accrue and invoice? (Recommend: accrue + warning banner; block only if you set a flag.)
2. **Trial enforcement**: full features during trial, or a reduced "trial" feature set? (Recommend: full features for 14 days, then lock.)
3. **What happens on expiry**: read-only + upgrade modal (recommend), or hard logout?
4. **Offline license validation**: purely offline license file, or phone-home when internet is available?
5. **Payment gateway**: Paystack, Flutterwave, or both?
6. **Hospital monthly banding**: enforce the visit band strictly (block above 250 visits on Standard), or soft-invoice the overage?

## 13. Phase 6 — Paystack payments — DONE ✅ (August 6, 2026)

### Delivered
- **`payment_intents` migration** (`20260807000006-create-payments.js`) — facility_id, intent_type enum (subscription/license/usage_invoice), plan_id, license_years, amount, currency, reference UNIQUE, status enum, metadata JSON, created_by, paid_at.
- **`services/paymentService.js`** — `initializePayment` (server-side amount derivation: subscription = plan.price_monthly, license = yearly×years, usage_invoice = actual invoice total from DB — never trusts client amounts), Paystack `/transaction/initialize` when `PAYSTACK_SECRET_KEY` set, sandbox otherwise; `applyPaidIntent` with **atomic `SELECT … FOR UPDATE` row-claim** so concurrent webhook deliveries can never double-apply (double license stack / double period extension); license renewals re-sign the offline license file AFTER commit so the stacked expiry is preserved; `handleWebhook` with HMAC-SHA512 + `crypto.timingSafeEqual`.
- **`controller/payments.js` + `routes/payments.js`** — initialize / verify / history / simulate (sandbox-only) / super-admin list; public webhook with scoped `req.rawBody` capture in app.js.
- **Premium gating** — `routesHelper.requirePremiumFeature(featureKey)` (data-driven via plan `flags`, super-admin bypass, legacy installs with no subscription row pass, lapsed → 402); applied to all HMO/insurance/enrollee/preauth routes in `managedcare.js`.
- **Frontend** — `UpgradeModal.jsx` (plan/years picker → Paystack redirect or sandbox simulate, payment history), wired into `MyPlanCard` CTA + expired-lock banner.

### Verified end-to-end
- Sandbox: initialize → simulate → paid → subscription upgrade applied (Basic→Standard, DB rows confirmed). Idempotency: second simulate returns "already applied".
- License stacking exact (1yr + 2yr = 3yrs, expiry 2027→2029, idempotent). Usage-invoice intent works; second invoice run returns no_events.
- Webhook HMAC: good signature processes, tampered/length-mismatch rejected (timing-safe, no throw).
- Premium gating: Basic facility 403 on HMO routes, super admin passes, unauthenticated 401.
- Preview: full checkout flow clicked through live (Standard ₦50,000 sandbox paid, MyPlanCard refreshed to STANDARD 1/7 practitioners, 9 modules).

### Security hardening (from review)
1. **Production fail-closed** — sandbox mode is disabled when `NODE_ENV=production` unless the operator explicitly sets `PAYMENTS_SANDBOX=1` (test stack / CI only). A real deployment with a missing key refuses payments with 503-style error instead of silently accepting fake-paid intents.
2. **Atomic idempotency** — `SELECT … FOR UPDATE` row claim prevents double-application on concurrent Paystack deliveries.
3. **Server-side amounts** — usage_invoice total is read from the DB invoice, never the client request body.
4. **Timing-safe HMAC** — `crypto.timingSafeEqual` with length guard; prod with no key rejects webhooks outright.

### Env (see .env.example)
`PAYSTACK_SECRET_KEY`, `PAYSTACK_PUBLIC_KEY`, `PAYMENTS_SANDBOX=1` (dev/test/CI only).

### Remaining (Phase 7+)
- Flutterwave secondary gateway, real Paystack key provisioning on the platform, HMO interface wiring to Premium data models, Paystack recurring (subscription plan) integration.

## 15. Phase 7 — trial countdown banner + expired lock screen (August 6, 2026) ✅

App-shell UX enforcing the plan state for facility users (super admins always pass).

### Delivered
- **`GET /api/plans/status`** (`backend/controller/subscriptions.js`) — lightweight facility-scoped endpoint: `{ facilityId, subscription: {status, billing_model, trial_ends_at, current_period_end, license_expires_at, license_years}, plan: {id, name, tier, product_line, billing_model} }`, facility resolved from the JWT (never a query param).
- **`SubscriptionGate`** (`frontend/src/components/admin/SubscriptionGate.jsx`, wired into `AuthenticatedContainer`) — renders app-wide while keeping the navbar visible:
  - `trial` → sticky blue countdown banner (days left + end date), dismissible, Upgrade now opens the UpgradeModal.
  - `past_due` → full lock screen with grace copy + Renew button.
  - `expired` / `suspended` / `cancelled` → full lock screen with plan badge + support contact; suspended/cancelled hide the Renew button.
  - Trial-lapsed clamp: a `trial` row whose `trial_ends_at` is in the past locks as `expired` instead of showing a stale "0 days left" banner.
  - Super admins and users without facility context bypass the gate entirely.
  - Fail-open on network errors (never lock someone out on a blip).
  - 30s re-poll **while locked** so a payment completed in another tab unlocks the session without a reload.
  - After payment: refresh Redux user (accessTo widened server-side) + re-poll status → app unlocks in place.
- **Server-side enforcement (already present, confirmed):** `subscriptionCron` (daily 00:15) flips lapsed trials → past_due → expired and calls `applyPlanCeiling` (narrows admin `accessTo` to free tier); `premiumGate` middleware returns **402 "Your subscription has lapsed"** on premium routes for non-active facilities — the lock can't be bypassed by URL.

### Verified in preview + API
- Trial banner renders with correct countdown + end date, modal opens ✓
- past_due lock → sandbox subscription payment → app unlocks in place (DB row paid, status active, period extended) ✓
- Expired lock ("Most modules are now locked to read-only core") ✓
- Premium HMO route as expired facility → 402 with clear message ✓
- Super admin unaffected by the gate ✓ (exempt path)
- Frontend esbuild transform clean for gate + modal + container.

## 14. Phase 6 testing pass — bugs found & fixed (August 6, 2026)

Full preview end-to-end test of the payment flows (login → Settings → MyPlanCard → UpgradeModal → sandbox checkout → DB verification). **3 bugs found, all fixed and re-verified.**

### Bug 1 — MyPlanCard showed a stale renewal date
`expiresAt` preferred `trial_ends_at` over `current_period_end` for non-license models, so an active subscription that paid showed "RENEWS Aug 20" (old trial date) while the footer said "period ends Sep 6".
**Fix:** trial-aware — `isTrial ? trial_ends_at : current_period_end` for subscriptions (both the banner and the RENEWS grid line).

### Bug 2 — UpgradeModal's license branch was dead code
No plan has `billing_model='license'` (hospital = `both`, dental = `subscription` with `license_price_yearly`), so the years picker and license intent were unreachable — dental annual pricing (₦250k/₦500k/₦1M) could never be paid, and offline license renewals couldn't go through Paystack.
**Fix:** added a `billingModel` state ('subscription'|'license') seeded from the facility's subscription row; a **Monthly / Yearly license toggle** (rendered only when a plan has yearly pricing); per-plan /yr pricing in license mode; years picker (1/2/5); `startCheckout` falls back to subscription when a plan has no yearly price; CTA disabled at amount ≤ 0.

### Bug 3 — license payments didn't adopt the paid plan
`applyPaidIntent`'s license branch stacked `license_years`/`license_expires_at` but never updated `plan_id` — a facility paying for Standard yearly stayed on its old Basic ceiling.
**Fix:** the license branch now does `plan_id = COALESCE(:paidPlanId, plan_id)` (mirroring `issueLicense`) and calls `applyPlanCeiling` inside the transaction. Verified: Basic(4) → Standard(5), years 3→5, expiry 2029→2031, ceiling applied.

### Scenario matrix verified in preview + API
- Login → post-login redirect ✓ · type-filtered module grid ✓
- MyPlanCard: ACTIVE/TRIAL/EXPIRED badges, seat limits, PAYG meter, license countdown ✓
- Modal: plans load, next-tier auto-select, Monthly↔Yearly toggle ✓
- Sandbox subscription checkout: initialize → simulate → paid → card refresh ✓ (DB row `paid`)
- License renewal: 2-yr intent ₦1,000,000 → paid, stacking math exact ✓
- Error paths: unknown reference (404/400 clean), idempotent re-simulate ("already applied"), usage_invoice w/o invoice (clean 400), tenant-scoped verify ✓
- Premium gating: Basic Dental → 403 "upgrade to unlock", no-auth → 401, super admin → 200 ✓
- Webhook: HMAC verified live-path earlier; sandbox fails closed (no fake payments) ✓
- Frontend `vite build` clean; backend syntax clean.

### Env addition
`PAYMENTS_SANDBOX=1` added to the test backend plist — production stays fail-closed (no key → initialize blocked), test/preview keeps sandbox.
