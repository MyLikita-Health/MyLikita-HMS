# Phase 8 — Payer Management Framework (COMPLETE)

**Status:** ✅ Implemented & validated · E2E **30 passed / 0 failed** · backend syntax/load ✅ · frontend `vite build` ✅

Includes the **follow-on work** (all implemented & E2E-proven): the contract-payer **cashier flow** (record visits, consume `used_amount`, generate invoices) and **`invoice_cycle` honoring** (frequency / day_of_month / auto_email) with a billing-period picker in the UI.

Phase 8 realizes the *Payer Management Framework* section of `RETAINERSHIP_ANALYSIS_AND_PLAN.md`: a single registry that unifies every payer type (**insurance, retainership, corporate, government, donor**) so the billing engine can resolve any patient's payer with one lookup. Legacy retainership (`patientrecords.retainership_*`) and insurance (`hmo_providers` / insurance enrollees) keep their existing, optimized engine branches; the new tables add explicit *contracts* for corporate/government/donor payers plus a unified registry facade.

---

## 1. Tables (migration `20260809000013-payer-management.js`)

Three tables, all facility-scoped (`facilityId`), UUID primary keys, `ON DELETE CASCADE` chains:

### `payer_organizations` — the payer entity
| Column | Type | Notes |
|---|---|---|
| `id` | VARCHAR(36) PK | UUID |
| `name` | VARCHAR(255) NOT NULL | |
| `payer_type` | ENUM `insurance/retainership/corporate/government/donor` | default `corporate` |
| `code` | VARCHAR(50) | short code |
| `contact_person` / `email` / `phone` / `address` | VARCHAR | |
| `billing_cycle` | ENUM `weekly/monthly/quarterly/adhoc` | default `monthly` |
| `payment_terms` | LONGTEXT (JSON) | |
| `receivable_account` | VARCHAR(10) | **optional chart-account override** — defaults by `payer_type` when null |
| `status` | ENUM `active/inactive` | |
| `facilityId` / `created_at` / `updated_at` | | indexes on facility + type |

### `payer_contracts` — per-payer coverage
| Column | Type | Notes |
|---|---|---|
| `id` | VARCHAR(36) PK | |
| `payer_id` | VARCHAR(36) FK → `payer_organizations` (cascade) | |
| `contract_no` / `name` | VARCHAR | |
| `organization_id` | VARCHAR(36) | optional link to `retainership_organizations` (drives AR rollup) |
| `covered_services` | LONGTEXT (JSON) | legacy single-array fallback |
| `covered_general_services` / `covered_lab_services` / `covered_pharmacy_services` | LONGTEXT (JSON) | per-category lists |
| `excluded_services` | LONGTEXT (JSON) | |
| `authorization_rules` | LONGTEXT (JSON) | `{ needs_auth_amount, auth_required_services }` |
| `limits` | LONGTEXT (JSON) | `{ annual_limit, max_amount_per_visit, max_visits_per_month, monthly_cap, per_employee_annual_limit }` |
| `payment_terms` / `invoice_cycle` | LONGTEXT (JSON) | `invoice_cycle`: `{ frequency, day_of_month, auto_email }` |
| `copay_percent` / `discount_percent` | DECIMAL(5,2) | |
| `status` | ENUM `active/inactive/expired` | |
| `facilityId` + timestamps | | indexes on payer/facility/org |

### `payer_beneficiaries` — patient ↔ contract links
| Column | Type | Notes |
|---|---|---|
| `id` | VARCHAR(36) PK | |
| `payer_id` | VARCHAR(36) FK → organizations (cascade) | |
| `contract_id` | VARCHAR(36) FK → contracts (cascade) | |
| `patient_id` | VARCHAR(255) NOT NULL | validated to exist in `patientrecords` at link time |
| `member_no` | VARCHAR(50) | |
| `relationship` | ENUM `self/spouse/child/dependent/staff/other` | |
| `annual_limit` | DECIMAL(15,2) | |
| `used_amount` | DECIMAL(15,2) DEFAULT 0 | |
| `status` | ENUM `active/suspended/expired` | |
| `facilityId` + timestamps | | |

`down()` drops beneficiaries → contracts → organizations (correct FK order).

---

## 2. Engine API (`backend/services/payerEngine.js`)

The registry facade — one interface for every payer type. Exports: `routeReceivable`, `detectPayer`, `evaluateLine`, `accrueUsage`, `getSummary`, `PAYER_TYPE_ACCOUNTS`.

### `routeReceivable(payerType, override?)` → chart account
One receivable account per payer type (single source of truth, mirrors `billingService`'s HMO map):

| payer_type | account |
|---|---|
| insurance | `400032` (Private HMO Receivable) |
| retainership | `400035` (Retainership/Corporate Receivable) |
| corporate | `400035` |
| government | `400031` (State Scheme Receivable) |
| donor | `400023` (Generic AR) |
| *(unknown / no override)* | `400023` |

An explicit `payer_organizations.receivable_account` overrides the default.

### `detectPayer(facilityId, patientId)` → payer object | null
Priority:
1. **Explicit beneficiary link** — joins `payer_beneficiaries` → `payer_contracts` → `payer_organizations`, all `status = 'active'`, newest `updated_at` first. Returns a fully-built payer (see `buildPayer`) with `source: 'payer_beneficiary'`.
2. **Legacy retainership fallback** — patient record with `patient_type = 'retainership'` → `{ type: 'retainership', source: 'retainership_legacy' }` so callers can route to the retainership branch.

`null` for cash/unknown patients → billing falls through to self-pay.

> ⚠️ Sequelize gotcha (fixed): with `QueryTypes.SELECT` the result *is* the rows array — destructuring it would grab the first row object and break the `.length` check. The first implementation had exactly this bug; verified by a direct DB repro before fixing.

### `evaluateLine(payer, item, amount)` → split result
Name-based coverage matching with the **same semantics as the retainership split engine** (catalog-ID matching handled by insurance engine separately). Steps:
1. Pick the coverage list by category (`consultation/general` → `covered_general_services`, `lab/laboratory` → `covered_lab_services`, `pharmacy/drugs` → `covered_pharmacy_services`, fallback → `covered_services`, then legacy `covered_services`).
2. **Exclusions first** — if the service name contains an excluded term → `covered: 0, patientRes: price` with `coverage_source: 'payer_excluded'`.
3. Not covered → `coverage_source: 'payer_not_covered'`.
4. **Authorization rules** — `needs_auth_amount` (`!= null` so a threshold of `0` means *every* service needs auth) and `auth_required_services` name match.
5. **Per-visit cap** — `limits.max_amount_per_visit` clamps the covered amount.
6. **Beneficiary annual limit** — `annual_limit − used_amount`; exhausted → `coverage_source: 'payer_limit_exhausted'`.
7. **Discount** — contract `discount_percent` caps covered to `price × (1 − d%)`.
8. **Copay** — `copay = round(covered × copay%)`; `patientRes = price − covered + copay` (never negative).

Returns the same shape as the retainership/insurance engines: `{ covered, patientRes, copay, insurer, plan, policy_number, insurer_type, needs_auth, hmo_receivable_account, coverage_source }`. When **not** covered it still returns `insurer: payer_name` so the UI shows the authoritative payer (never silently self-pay).

### `accrueUsage({ beneficiaryId, amount, facilityId })` → bool
Post-settlement write-back that **consumes a beneficiary's `annual_limit`**: `used_amount = LEAST(used_amount + amount, annual_limit)` when a limit is set (clamped so concurrent bills can never push usage past the limit), plain increment otherwise. Non-fatal — never fails a payment. Called by `payerBillingService.recordPayerVisit` after a contract-payer bill is settled.

### `getSummary(facilityId)` → per-payer dashboard rows
- Each payer with `active_contracts` / `active_beneficiaries` counts (subqueries).
- **Outstanding AR** = retainership invoices in `pending` status for orgs linked via `payer_contracts.organization_id` **+** `hmo_claims` (`submitted/acknowledged/approved`) whose `hmo_provider_name` case-insensitively matches the payer name (v1 name-matching — see follow-ups).
- Both AR queries are wrapped in try/catch so installs lacking `retainership_invoices`/`hmo_claims` still work.
- `receivable_account` resolved (override → default by type).

---

## 3. Billing engine integration (`backend/services/billingService.js`)

- `splitBill(facilityId, patientId, txItems, policyId, precomputedPayer?)` calls **`payerEngine.detectPayer` once per bill** (not per line item — avoids N lookups on the hot path) and passes `precomputedPayer` into `splitLineItem`. The optional `precomputedPayer` short-circuits the lookup when the cashier has already detected it (no duplicate query).
- In `splitLineItem`, **before** the insurance path and **only when the patient is not a retainership patient** (`!retainershipPatient`), a `payer_beneficiary` payer is **authoritative** via `evaluateLine` — its result is returned directly (including not-covered results, so a contract payer is never silently downgraded to self-pay).
- Legacy retainership patients keep the retainership branch; everyone else continues through `insuranceEngine.checkCoverage` → self-pay. All error paths are non-fatal (logged, fall through).

E2E proof: a corporate-contract patient's bill splits as *"covered ₦8,000 via E2E Corp Payer"* routed to `400035`.

---

## 4. Controller (`backend/controller/payers.js`) + Routes (`backend/routes/payers.js`)

All endpoints facility-scoped; `payments_terms`/`limits`/etc. JSON fields auto-stringified server-side.

### Organizations
| Method | Route | Notes |
|---|---|---|
| GET | `/payers/:facilityId` | list; optional `?type=` & `?status=` filters |
| GET | `/payers/:id/:facilityId` | detail |
| POST | `/payers` | body must include `facilityId` + `name` + `payer_type` (validated against enum) |
| PUT | `/payers/:id/:facilityId` | partial update (name, type, code, contact, cycle, status, payment_terms, receivable_account) |
| DELETE | `/payers/:id/:facilityId` | blocked while contracts exist (safe delete) |

### Contracts
| Method | Route | Notes |
|---|---|---|
| GET | `/payers/:payerId/:facilityId/contracts` | joined with payer name + org name |
| POST | `/payers/contracts` | validates payer exists & active; builds JSON columns from arrays |
| PUT | `/payers/contracts/:id/:facilityId` | partial update incl. all JSON coverage fields |
| DELETE | `/payers/contracts/:id/:facilityId` | blocked while beneficiaries linked |

### Beneficiaries
| Method | Route | Notes |
|---|---|---|
| GET | `/payers/contracts/:contractId/:facilityId/beneficiaries` | joined with payer + contract names |
| POST | `/payers/beneficiaries` | validates **active** contract + **existing patient**; deletes any prior active link for the same patient+contract (single authoritative row) |
| DELETE | `/payers/beneficiaries/:id/:facilityId` | unlink |

### Summary
| Method | Route |
|---|---|
| GET | `/payers/summary/:facilityId` | `payerEngine.getSummary` |

### Visits & Invoices (follow-on)
| Method | Route | Notes |
|---|---|---|
| GET | `/payers/:payerId/:facilityId/visits` | visit list for a payer; optional `?status=` |
| GET | `/payers/contracts/:contractId/:facilityId/invoices` | invoice list for a contract |
| POST | `/payers/invoices/generate` | body: `contract_id`, `billing_period` (YYYY-MM), `facilityId`, `skipEmpty?`; returns `{ invoice_id, invoice_number, total_amount, visits_count, due_date, auto_email, email_status }` |
| GET | `/payers/invoices/detail/:id/:facilityId` | invoice + payer/contract names + line items (visits) |
| POST | `/payers/invoices/:id/:facilityId/mark-paid` | mark an invoice paid |

### Auth gate (`requirePayerAccess`)
JWT (`passport.authenticate('jwt')`) → super admin pass-through → `accessTo` contains `payer` or `retainership` pass-through → else `checkPermission('billing', 'payer', action)`. `view` vs `manage` variants. **Literal segments (`/summary`, `/contracts`, `/beneficiaries`, `/invoices/generate`, `/invoices/detail`) are registered before param patterns** so they can never be shadowed (the Phase 7 invoice-route lesson applied).

**Wiring:** `backend/app.js` line 312: `require("./routes/payers")(app)`.

---

## 5. UI (`frontend/src/components/account/payers/PayerManagement.jsx`)

Route `/me/account/payers`, menu item **"Payer Management"** (`FaHandshake`) in the Account menu, gated by `billingPermissions.canViewManagedCare()`.

- **Summary chips** — Payers / Active Contracts / Active Beneficiaries / Outstanding AR (₦, formatted).
- **Toolbar** — type filter (5 payer types, color-coded tags), status filter, live search (name/code/contact/email), refresh, **New Payer**.
- **Payer table** — type tag, contact, contracts, beneficiaries, outstanding (red when > 0), status, edit/delete actions; row click opens the detail modal.
- **Payer modal** — create/edit with type, code, billing cycle, contact, receivable-account override, status.
- **Detail modal** — contracts list (coverage counts per category, copay/discount, status) with **per-contract beneficiary linking form** (patient ID, member no, relationship, annual limit; forms keyed by contract id so typing in one never leaks into another), show/hide beneficiaries, unlink. **New Contract** form: per-category covered lists (comma-separated), exclusions, copay/discount %, max-per-visit, annual limit, auth-required threshold + services, invoice cycle JSON.
- **Cashier (`components/common/DeptCashier.jsx`)** — new **"Payer / Contract"** payment mode: live split preview ("Covered by {payer name}"), sends `payerMode` so the backend books the covered portion to the payer's receivable, records the visit and accrues usage.
- **Detail modal (follow-on)** — per-contract **Invoices** block with a **billing-period picker** (`<input type="month">`, per-contract state), **Generate** (sends `skipEmpty: true`; honors `invoice_cycle` for due date + auto-email), Mark paid, `due` date shown per invoice, and a **Visits** table (auto-recorded at the cashier).
- Summary refreshes after create/edit/link/unlink.

---

## 6. Contract-payer cashier flow & invoicing (Phase 8 follow-on, implemented)

Mirrors the retainership Phase 2 loop (bill → visit → invoice) for explicit contract payers (corporate / government / donor), closing the two gaps the original plan left open (cashier UX + `used_amount` accrual) and honoring `invoice_cycle`.

### Tables (migration `20260809000014-payer-visits-invoices.js`)
- **`payer_visits`** — one row per settled beneficiary bill: `payer_id` / `contract_id` / `beneficiary_id`, `visit_date`, `total_amount` / `covered_amount` (what the contract owes) / `patient_amount` (copay/uncovered), `services` JSON, `status` `pending → billed`, `invoice_id` link. FK cascade on payer/contract; beneficiary FK `ON DELETE SET NULL`.
- **`payer_invoices`** — per-contract invoice: `contract_id`, `payer_id`, `invoice_number` (`PINV-YYYY-MM-…`), `billing_period` (YYYY-MM), `total_amount`, `status` `pending → paid`, `due_date`, `generated_by`; **`UNIQUE(contract_id, billing_period)`** blocks duplicate-period invoices (review fix).

### Service: `backend/services/payerBillingService.js`
- **`recordPayerVisit({…, payer})`** — settle-time: INSERT a `pending` `payer_visits` row **and** call `payerEngine.accrueUsage` for the beneficiary's `used_amount`. Only for `source === 'payer_beneficiary'` payers; both steps non-fatal to the payment.
- **`generateInvoiceForContract`** — accumulates `pending` visits for the contract+period, creates the invoice, marks visits `billed` + links `invoice_id`. **Honors `invoice_cycle`**: `day_of_month` (1–31) → due on that day of the month *after* the billing period (clamped for short months); otherwise a frequency grace (weekly 7d / else 30d from period end — preserving the legacy +30d default when no cycle is set). **`auto_email`** → dispatches `emailPayerInvoice` (non-fatal; `email_status` reports `sent` / `not_configured` / `no_email` / `error`).
- **`emailPayerInvoice`** — HTML summary (payer/contract, period, due date, total, visit rows) to the payer's contact email via the shared `sendEmail` helper (gracefully skips without `RESEND_API_KEY`).
- **`loadPayerInvoice`** (detail + line items + patient names; parses `invoice_cycle`) / **`markPayerInvoicePaid`** / **`listContractInvoices`** / **`listPayerVisits`**.

### Cashier integration (`controller/account.js` — `casherPayBill`)
- **PAYER mode** (`modeOfPayment: 'PAYER'` / `payerMode: true`) **plus auto-detection**: corporate/government/donor beneficiaries are detected via `payerEngine.detectPayer` on every bill-mode payment.
- `pushPayerEntries` in all 8 service-type cases: covered portion → the **payer's receivable account** (400035 / 400031 / 400023 or per-payer override), patient portion → cash (PAYER) or 400023 AR (BILL). Retainership still wins when a patient is both.
- After settlement: `recordPayerVisit` (visit + accrual). Both non-fatal; `splitBill` receives the already-detected payer (no duplicate lookup).

### E2E proof (steps 19–24)
PAYER bill paid → visit recorded (₦8,000 pending) → `used_amount` accrued → invoice generated (`due 2026-09-15`, `email=not_configured`) → detail shows line items → marked paid.

### Bugs surfaced & fixed by the follow-on E2E
- `patientrecords` uses `surname` (not `lastname`) in the two JOINs.
- Duplicate-invoice race → `UNIQUE(contract_id, billing_period)`.
- `used_amount` could exceed the annual limit → clamped via `LEAST()`.

---

## 7. Validation

- Migrations applied cleanly (`npx sequelize-cli db:migrate`): `20260809000013` (registry) + `20260809000014` (visits/invoices).
- Backend syntax + load of all touched files ✅.
- Frontend `vite build` ✅ (incl. cashier PAYER mode + period picker).
- E2E: **30 steps, 0 failed** (1 skip: email needs `RESEND_API_KEY`): org/plan/employee → beneficiary link → **payer split through the unified engine** → summary receivable → **PAYER-mode bill → visit → usage accrual → invoice (due-date/email assertions) → detail → mark paid** → Phase 5 approval workflow.
- Code review findings all addressed: Sequelize destructuring bug, dead code, `needs_auth_amount: 0` edge case, beneficiary link validation (patient exists + duplicate replace), per-bill payer detection (perf), per-contract beneficiary forms, E2E find-or-create (no row accumulation), `surname` JOIN fix, duplicate-invoice unique index, `used_amount` clamp, `skipEmpty` from the UI.

---

## 8. Deployment steps

1. **Backend:** restart the service to pick up the new routes — `app.js` now calls `require("./routes/payers")(app)` (already present in the repo; a fresh deploy/restart loads it). No env vars required. `auto_email` needs `RESEND_API_KEY` (graceful otherwise).
2. **Migration:** run `npx sequelize-cli db:migrate` in `backend/` (or the standard migration step of the deploy pipeline). Both migrations are idempotent (`CREATE TABLE IF NOT EXISTS`) and additive — safe on existing installs; the schema guards for `retainership_invoices`/`hmo_claims` queries mean installs lacking those tables still work. Fresh installs get `UNIQUE(contract_id, billing_period)` from `20260809000014`.
3. **Frontend:** rebuild + deploy the bundle (payer page, cashier PAYER mode, period picker). No config changes.
4. **Post-deploy smoke test:** `cd backend && node test-retainership-e2e.js` — 30 steps; expect `30 passed, 0 failed` (email steps skip without `RESEND_API_KEY`).

---

## 9. Known follow-ups (documented, not blocking)

- **AR via provider-name matching is v1** — a `payer_id` link on contracts/claims would make HMO-claim rollup deterministic instead of name-matched.
- **CASH-mode bypass (mirrored from retainership)** — a contract-payer beneficiary settled in CASH mode (not PAYER/BILL) pays the full amount with no split/receivable/visit. A cashier warning/guard that routes beneficiaries to PAYER mode is the natural hardening step.
- **`invoice_cycle` not yet mirrored to retainership** — `retainership_invoices` still hardcodes +30d; adopting the same cycle logic keeps the two engines consistent.
- **Payer invoice emails are HTML-only** — no PDF attachment yet (retainership attaches one); a `payerInvoicePDF` builder is the natural next step.
- **Per-contract contact email** — `auto_email` targets the payer's email; a `contact_email` on the contract itself would allow contract-specific recipients.
- **Monthly caps not enforced** — `limits.max_visits_per_month` / `monthly_cap` are stored but not yet enforced (needs visit-count tracking).
