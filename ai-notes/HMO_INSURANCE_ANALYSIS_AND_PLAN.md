# HMO & Health Insurance — Analysis, Gaps & Implementation Plan

**Date:** August 6, 2026
**Scope:** Admin (managed care), Account/Billing, Patient modules
**Status:** ✅ Analysis complete — Implementation in progress

---

## 1. How the system currently handles insurance/HMOs

There are **three overlapping systems** that evolved separately:

### A. Legacy HMO/Insurance (old, stored-procedure based)
- `hmo` table + `InsuranceTypeCreation` table + stored procedures (`hmo_registration`, `addInsuranceType`, `getInsuranceType`).
- Endpoints: `/user/register-hmo`, `/user/get-hmo`, `/user/add-insurance-type`, `/user/get-insurance-type`.
- Frontend: `HMORegistration.jsx`, `InsuranceTypeCreation.jsx` (Admin).
- Only stores a name + a coverage % — no enrolment, no plans, no agreements.

### B. Managed Care module (newer, full-featured)
- Tables: `hmo_providers`, `insurance_schemes`, `enrollees`, `agreements`, `pricing_rules`, `preauth_requests`, `corporate_companies`.
- Controller: `backend/controller/managedcare.js`; routes: `backend/routes/managedcare.js` (premium-gated via `requirePremiumFeature('hmo_interface')`).
- Features: HMO/company/scheme CRUD, enrollee management + CSV upload, agreements with covered/excluded services + contracted rates, pricing rules per category, eligibility verification (NHIA/HMO/employee), service authorization checks, pre-authorisation requests, patient entitlements (coverage + auth list).
- Frontend: `account/managed-care/*` (HMOProviders, InsuranceSchemes, Enrollees, Agreements, PricingRules, Companies), plus patient-record widgets `PatientEntitlements.jsx`, `PreAuthTracking.jsx`, `AgreementInfo.jsx` (built but **not mounted anywhere in the patient record view**).

### C. Retainership module (corporate retainership, separate)
- `retainership_organizations`, `retainership_plans`, `retainership_visits`, `retainership_invoices` with billing cycles, coverage validation, invoice generation, balance reports.
- This is the only place with an actual **invoice/claim-like lifecycle** (pending → billed → paid).

### D. Patient records + billing
- `patientrecords` has `accountType` (Single/Family/Cooporate/Retainership/NHIA/HMO/International), `hmo_provider`, `hmo_policy_number`, `hmo_expiry_date`, `nhia_number`, `company_id`, `enrollee_no`, etc.
- `CreateNewPatient.jsx` collects insurance fields per account type and calls `verify-nhia` / `verify-hmo` / `verify-employee`.
- Billing (`Review.jsx` → `casherPayBill`) only knows a legacy `patient_type === "Insurance"` special-case that applies a single `insurancePercentage` — it does **not** create claims, does not split covered vs patient responsibility per line, and does not know about the managed-care agreements/pricing.

---

## 2. Gaps identified

### G1 — No claims lifecycle (biggest gap)
There is **no HMO claims table and no claim workflow**. The "HMO Claims Report" (`HmoClaimsReport.jsx` → `/reports/financial/hmo-claims`) is a **stub** that queries `retainership_invoices` joined on `ro.org_name` — a column that doesn't exist (schema uses `ro.name`) — so it **500s**. There is no way to:
- create a claim from a patient's bill,
- submit it to an HMO,
- track approved / rejected / paid / partially-paid statuses,
- record claim numbers, submitted/approved amounts, or payment references.

### G2 — Pre-auth has no decision workflow
`preauth_requests` can be created and listed, but there is **no approve / deny endpoint** — `auth_code`, `expiry_date`, `denial_reason`, `approved_by` columns exist but are never written. The `PreAuthTracking.jsx` widget shows statuses but no one can act on them, and there's no facility-wide pre-auth queue for the accounts team.

### G3 — Entitlements are hollow
`getPatientEntitlements` returns `benefits: []` always and never computes:
- the HMO agreement's covered amount / patient co-pay for a service,
- enrollee plan limits (annual/per-visit caps),
- actual usage from bills/claims.

### G4 — Billing doesn't integrate with managed care
`casherPayBill` has no "Insurance / HMO claim" payment branch. Insurance patients are billed like cash (or the legacy % hack), so:
- no covered-amount vs patient-responsibility split per line,
- no auto-claim generation when an HMO/NHIA/corporate patient pays,
- no agreement/pricing-rule application at the till.

### G5 — Reports are broken or missing
- `/reports/financial/hmo-claims` → SQL error (`org_name`).
- `HMOBillingReport.jsx` fetches `/hmo/patient/records` which **does not exist** (empty results forever).
- `HMOPatientReport.jsx` uses the legacy `/hmo/patient/records` too — missing backend.
- No HMO receivables/outstanding report.

### G6 — Legacy duplication & inconsistency
- `HMORegistration` (hmo table) vs `HMOProvidersManagement` (hmo_providers) are two different stores for the same concept.
- `InsuranceTypeCreation` (insurance_type + %) vs `InsuranceSchemesManagement` (insurance_schemes).
- Patient registration HMO list comes from `/api/insurance/hmo` (new), reports use `/user/get-hmo` (legacy) → lists diverge.

### G7 — Patient-record widgets never rendered
`PatientEntitlements.jsx`, `PreAuthTracking.jsx`, `AgreementInfo.jsx` are well-built but **unused** — clinicians never see coverage, auth codes, or agreement terms in the patient record.

### G8 — Enrollees lack plan limits
`enrollees` has `plan_type`, `expiry_date` but no per-visit/annual caps or co-pay %, so plan limits can't be enforced or surfaced.

---

## 3. Implementation plan (defaults applied)

### Phase 1 — DB migration
- `hmo_claims` — id, claim_no, patient_id/name, hmo_provider_id/name, enrollee_no, plan_type, service_date, total_amount, covered_amount, patient_responsibility, status enum(draft,submitted,approved,partially_paid,paid,rejected), submitted/approved/paid dates, payment_reference, notes, facilityId.
- `hmo_claim_items` — claim_id, service, category, amount, covered_amount.
- `enrollees` — add `per_visit_limit`, `annual_limit`, `copay_percent`.
- `preauth_requests` — no schema change needed (columns exist).

### Phase 2 — Backend endpoints
- Pre-auth: `GET /api/preauth/all` (facility queue), `POST /api/preauth/approve`, `POST /api/preauth/deny`.
- Claims: `GET/POST /api/claims`, `GET /api/claims/:id`, `POST /api/claims/:id/submit|approve|reject|pay`, `GET /api/claims/stats`.
- Entitlements: enrich with agreement coverage, benefit limits, usage.
- Reports: fix `hmo-claims` (use `ro.name`, and drive from `hmo_claims` where present), add `hmo/billing/records` + `hmo/patient/records` real endpoints.
- Billing: extend `casherPayBill` to accept `INSURANCE` payment branch that writes accounting entries (covered → HMO receivable `4000xx`, patient responsibility → cash/POS) and auto-creates an `hmo_claim` for the covered portion.

### Phase 3 — Frontend
- New **HMO Claims** page (list, create from bill, detail with items, status actions) under Account → Managed Care.
- New **Pre-authorisation approvals** page (facility queue with approve/deny) under Account → Managed Care.
- Fix `HMOBillingReport` + `HMOPatientReport` to real endpoints.
- Mount `PatientEntitlements` + `PreAuthTracking` + `AgreementInfo` into the patient record detail view.
- Wire all new routes into `AccountMenu.jsx` / `AccountDashboard.jsx`.

### Phase 4 — Validation
Backend syntax, frontend esbuild transforms, live preview test of claim + preauth flows, code review, plan-doc update.

---

## 4. Accepted defaults (recommendations applied)
- Claims are **HMO-payable receivables**: covered amount billed to the HMO, patient responsibility collected at the till.
- Pre-auth approval generates a human-readable `auth_code` (e.g. `PA-XXXXXXXX`) with a 14-day default expiry, overridable.
- Claims auto-generate on insurance-mode payment; manual creation also supported.
- All managed-care endpoints stay premium-gated (`hmo_interface`).
