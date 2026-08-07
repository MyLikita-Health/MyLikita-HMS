# HMO & Health Insurance — Comprehensive Analysis & Implementation Plan

**Date:** August 7, 2026
**Based on:** Full insurance spec (NHIA, State Schemes, Private HMOs, split billing, claims, capitation, APIs, adapter layer)

---

## 1. Current State: What Exists Today

The codebase has **three overlapping partial systems**, none fully matching the spec:

### A. Legacy HMO/Insurance (stored-procedure era)
| Component | Status |
|---|---|
| `hmo` table (id, hmo_name, facilityId) | Exists — simple name-only |
| `InsuranceTypeCreation` table (insurance_name, percentage, packages) | Exists — name + coverage % |
| Stored procedures `hmo_registration`, `addInsuranceType` | Exists |
| `/user/register-hmo`, `/user/get-hmo`, `/user/add-insurance-type`, `/user/get-insurance-type` | Exists (legacy routes) |
| `HMORegistration.jsx`, `InsuranceTypeCreation.jsx` (Admin) | Exists — legacy UI |
| **Coverage per-drug, per-lab, per-service** | ❌ None |
| **Plan definitions, formularies** | ❌ None |

### B. Managed Care Module (newer, premium-gated)
| Component | Status |
|---|---|
| `hmo_providers` table (hmo_name, contact, email, phone, address, discount, status) | ✅ Full CRUD |
| `insurance_schemes` table (insurance_name, scheme_type, coverage_percent, status) | ✅ Full CRUD |
| `corporate_companies` table (company_name, contact, discount, credit_limit, payment_terms) | ✅ Full CRUD |
| `enrollees` table (enrollee_id, name, phone, email, plan_type, expiry_date, type, provider_id) | ✅ CRUD + CSV upload |
| `enrollees` benefit limits (`per_visit_limit`, `annual_limit`, `copay_percent`) | ✅ Added (Phase 1) |
| `agreements` table (name, type, provider_id, dates, discount, credit_limit, covered_services JSON, exclusions JSON) | ✅ Full CRUD |
| `pricing_rules` table (rule_name, patient_category, service_category, price_type, price_value, discount_percent) | ✅ Full CRUD |
| `preauth_requests` table (patient_id, service, amount, diagnosis, status, auth_code, expiry_date, denial_reason) | ✅ CRUD + approve/deny |
| `hmo_claims` table (claim_no, patient, hmo_provider, total, covered, patient_responsibility, status: draft→submitted→approved→paid) | ✅ Full lifecycle |
| `hmo_claim_items` table (claim_id, service, category, qty, amount, covered_amount) | ✅ |
| **Eligibility verification** (verifyNHIA, verifyHMO, verifyEmployee, getPatientEligibility) | ✅ |
| **Service authorization check** (checkServiceAuthorization, checkAgreementCoverage) | ✅ Basic |
| **Patient entitlements** (coverage, benefits, authorizations) | ✅ With benefit limits |
| **HMO patient/billing records** (getHMOPatientRecords, getHMOBillingRecords) | ✅ |
| **Premium gate** (`requirePremiumFeature('hmo_interface')`) | ✅ Active |
| **Frontend managed-care pages** (HMOProviders, InsuranceSchemes, Enrollees, Agreements, PricingRules, Companies, HMOClaims, PreAuthApprovals) | ✅ 13 components |
| **Patient-record widgets** (PatientEntitlements, PreAuthTracking, AgreementInfo) | ✅ Built — **not mounted** |

### C. Retainership Module (corporate, separate)
| Component | Status |
|---|---|
| `retainership_organizations`, `retainership_plans`, `retainership_visits`, `retainership_invoices` | ✅ |
| Billing cycle, coverage validation, invoice generation | ✅ |
| **Separate from managed-care HMO; no unified insurance engine** | Gap |

### D. Patient Records + Billing Integration
| Component | Status |
|---|---|
| `patientrecords` HMO fields (hmo, hmo_provider, hmo_plan_type, hmo_policy_number, hmo_expiry_date, nhia_number, enrollee_no, accountType) | ✅ |
| `CreateNewPatient.jsx` collects insurance fields + verifies eligibility | ✅ |
| **Billing (`casherPayBill`) insurance split** | ❌ Only legacy `insurancePercentage` hack |
| **Auto claim generation on insurance payment** | ❌ None |
| **Covered vs patient responsibility per service line** | ❌ None |

---

## 2. Gap Analysis vs User Spec

### G1 — No Insurance Organizations model (MAJOR)
**Spec requires:** Name, Type (Federal/State/Private HMO), Contact Persons, Billing Cycle, Claims Format, Authorization Rules, API Credentials, Payment Terms.

**Current:** `hmo_providers` has only name + contact + discount. No type classification, no billing cycles, no claims format, no auth rules, no API credentials.

### G2 — No Insurance Plans per provider (MAJOR)
**Spec requires:** Per-insurer plans with Covered services, Excluded services, Annual limits, Drug formulary, Co-payment %, Referral requirements, Authorization rules.

**Current:** `agreements` has covered_services + exclusions (JSON) but no drug formulary, no annual limits per plan, no co-pay rules, no referral requirements. `insurance_schemes` has only a flat coverage_percent.

### G3 — No primary/secondary/tertiary insurance (MAJOR)
**Spec requires:** Patient can have multiple policies with billing priority (who pays first).

**Current:** `patientrecords.accountType` is a single value. No concept of primary/secondary insurance or cascading billing.

### G4 — No drug formulary check (MAJOR)
**Spec requires:** Pharmacy screen shows per-drug coverage: "Covered" / "Not Covered" / "Needs Authorization".

**Current:** Pharmacy has no insurance integration at all. `drugs.js` controller doesn't call any insurance service.

### G5 — No lab/radiology coverage check (MAJOR)
**Spec requires:** Lab tech sees coverage per test. MRI "Needs approval" flagged.

**Current:** `lab.js` and `radiology-examinations.js` have no insurance integration.

### G6 — No split billing engine (CRITICAL)
**Spec requires:** Total bill split into Insurance ₦58,000 + Patient ₦3,500 per line item.

**Current:** Billing has a legacy `insurancePercentage` that applies ONE flat percentage to the entire bill. No per-line covered-amount calculation, no auto-claim generation.

### G7 — No capitation module (MAJOR)
**Spec requires:** Fixed monthly payment per enrollee, expected vs received reconciliation.

**Current:** No capitation concept anywhere.

### G8 — No payment reconciliation (MAJOR)
**Spec requires:** Claim ₦20,000, Paid ₦18,000, Difference ₦2,000 with deduction reasons (late submission, unsupported service, duplicate).

**Current:** `hmo_claims` has status transitions but no reconciliation screen, no deduction tracking, no remittance matching.

### G9 — No referral module with validation codes
**Spec requires:** Primary → Secondary referral with codes, receiving hospital validates.

**Current:** No referral system for insurance patients.

### G10 — No insurance dashboard
**Spec requires:** Revenue split (Cash vs Insurance), Claims stats (submitted/approved/rejected/pending), Outstanding receivables per HMO, Average reimbursement time.

**Current:** `getClaimsStats` returns counts by status. No revenue split, no receivables aging, no reimbursement-time calculation.

### G11 — No API adapter layer
**Spec requires:** NHIA Adapter, KASCHMA Adapter, Hygeia Adapter, Generic Adapter implementing verifyEligibility(), submitClaim(), checkClaimStatus(), requestAuthorization(), submitReferral(), downloadRemittance().

**Current:** All verification is local (enrollees table). No external API calls to any insurer.

### G12 — Patient-record widgets never mounted
`PatientEntitlements.jsx`, `PreAuthTracking.jsx`, `AgreementInfo.jsx` are built but NOT rendered in any patient record view. Clinicians never see coverage, auth codes, or agreement terms.

### G13 — Feature gating works but no visibility for non-premium
Facilities on Basic/Standard plans get a 403 "upgrade to Premium" error. There's no graceful degradation showing the feature as locked with an upgrade prompt.

### G14 — Legacy duplication
- `HMORegistration` (hmo table) vs `HMOProvidersManagement` (hmo_providers)
- `InsuranceTypeCreation` vs `InsuranceSchemesManagement`
- Patient reg HMO list from `/api/insurance/hmo`, reports from `/user/get-hmo` → lists diverge

### G15 — No EMR integration
Doctor prescribes → insurance engine checks coverage → warns if excluded or needs pre-auth. No hook exists in diagnosis/drug-prescription flows.

---

## 3. Implementation Plan

### Phase 1 — Insurance Organizations & Plans Model (DB + Backend)

**Migration:**
- Extend `hmo_providers`: add `type` ENUM('federal','state','private_hmo','tpa'), `billing_cycle` VARCHAR, `claims_format` VARCHAR, `authorization_rules` JSON, `api_credentials` JSON (encrypted), `payment_terms` TEXT, `contact_persons` JSON.
- New table `insurance_plans`: id, provider_id FK→hmo_providers, plan_name, covered_services JSON, excluded_services JSON, drug_formulary JSON, annual_limit DECIMAL, per_visit_limit DECIMAL, copay_percent DECIMAL, referral_required TINYINT, auth_required_for JSON (procedures needing pre-auth), status.
- New table `patient_insurance_policies`: id, patient_id, provider_id, plan_id, policy_number, priority (1=primary, 2=secondary, 3=tertiary), status, expiry_date, enrolment_date.

**Backend endpoints:**
- CRUD for `insurance_plans` (per provider).
- CRUD for `patient_insurance_policies` (per patient) — assign primary/secondary/tertiary.
- Extend patient eligibility check to cascade through policies (primary → secondary → tertiary → self-pay).

**Backward compatibility:** `patientrecords.hmo_provider` + `patientrecords.hmo_plan_type` continue to work. The new `patient_insurance_policies` is additive.

### Phase 2 — Insurance Engine + Coverage Check

**New service `services/insuranceEngine.js`:**
- `checkCoverage(patientId, service, category)` — cascades through patient's policies, returns { covered: bool, covered_amount, patient_responsibility, copay, needs_auth, insurer, plan }.
- `checkDrugFormulary(patientId, drugCode)` — returns { covered: bool, alternative: drugCode? }.
- `getApplicablePricing(facilityId, insurerId, service)` — resolves contracted rates from agreements/pricing_rules.

**Integration points:**
- **Doctor/Diagnosis:** Call `checkCoverage` before confirming a procedure — warn if excluded or needs pre-auth.
- **Pharmacy:** Call `checkDrugFormulary` per prescribed drug — show "Covered" / "Not Covered" / "Needs Auth" badges.
- **Laboratory:** Call `checkCoverage` per test — show coverage status.
- **Radiology:** Call `checkCoverage` per exam — show "Needs Authorization" for MRI/CT.

**Backward compatibility:** Non-insurance patients skip the engine (accountType not HMO/NHIA/Corporate). Facilities without `hmo_interface` flag never call the engine.

### Phase 3 — Split Billing Engine

**Extend `casherPayBill` / billing flow:**
- For insurance patients: each line item gets `covered_amount` (from insuranceEngine) and `patient_responsibility`.
- Patient pays patient_responsibility at the till (cash/POS).
- Covered portion creates an `hmo_claim` in `draft` status automatically.
- The claim links to the bill/invoice for traceability.

**New accounting entries:**
- Patient responsibility → Cash/POS account (existing).
- Covered portion → HMO Receivable account (new: `4000xx` series per HMO).

**Backward compatibility:** Cash patients unchanged. The legacy `insurancePercentage` path continues to work; the new split billing activates only when `accountType` is HMO/NHIA and a valid agreement exists.

### Phase 4 — Claims Lifecycle Enhancements

**Extend `hmo_claims`:**
- Add `submission_method` ENUM('electronic','pdf','manual','api').
- Add `remittance_ref`, `amount_paid`, `deduction_amount`, `deduction_reasons` JSON.
- Add `capitation_applied` TINYINT (for capitation-based claims).
- Add `invoice_no` link to `usage_invoices` / billing invoice.

**New endpoints:**
- `POST /api/claims/:id/submit` — marks submitted + generates PDF/electronic submission.
- `POST /api/claims/:id/reconcile` — records payment received vs claimed, with deduction reasons.
- `GET /api/claims/receivables` — outstanding per HMO, aging buckets (0-30, 31-60, 61-90, 90+).

**Backward compatibility:** Existing claims workflow (draft→submitted→approved→paid) unchanged. New fields are NULL-able.

### Phase 5 — Capitation Module

**New table `capitation_enrolments`:**
- facility_id, insurer_id, month, enrollee_count, capitation_rate, expected_amount, received_amount, status.

**New service `services/capitationService.js`:**
- Monthly capitation calculation from active enrollees.
- Reconciliation: expected vs received.
- Flag discrepancies for accounts team.

**Backward compatibility:** Only activates when `hmo_providers.type = 'federal' OR 'state'` (NHIA/state schemes).

### Phase 6 — Insurance Dashboard

**New endpoints:**
- `GET /api/insurance/dashboard/revenue-split` — Cash vs Insurance revenue (current month, YTD).
- `GET /api/insurance/dashboard/claims-stats` — Submitted/Approved/Rejected/Pending counts + values.
- `GET /api/insurance/dashboard/receivables` — Outstanding per HMO with aging.
- `GET /api/insurance/dashboard/reimbursement-time` — Average days from submission to payment per HMO.

**Frontend:** New `InsuranceDashboard.jsx` under Account → Managed Care.

**Backward compatibility:** Pure additive — new endpoints, new page.

### Phase 7 — API Adapter Layer

**New directory `backend/adapters/insurance/`:**
- `baseAdapter.js` — interface: verifyEligibility(), submitClaim(), checkClaimStatus(), requestAuthorization(), downloadRemittance().
- `nhiaAdapter.js` — NHIA API (when available).
- `genericAdapter.js` — CSV export / PDF generation / manual workflows for insurers without APIs.

**Adapter selection:** Per `hmo_providers.api_credentials` config. Falls back to `genericAdapter` when no API credentials exist.

**Backward compatibility:** All existing manual flows continue. Adapters are opt-in per insurer.

### Phase 8 — EMR Integration Hooks

**In diagnosis/drug/lab/radiology controllers:**
- After a service/drug/test is ordered, call `insuranceEngine.checkCoverage()`.
- Return coverage status in the response so the frontend can show badges.
- If `needs_auth: true`, auto-create a `preauth_request` or prompt the clinician.

**Frontend:** Show coverage badges (🟢 Covered / 🟡 Needs Auth / 🔴 Not Covered / ⚪ Self-Pay) in:
- Diagnosis/consultation screen
- Pharmacy prescription list
- Lab test order screen
- Radiology exam order screen

**Backward compatibility:** Only for insurance patients. Non-insurance/non-HMO patients see no change.

### Phase 9 — Feature Visibility & Upgrade Path

**Enhance `requirePremiumFeature`:**
- Instead of hard 403, return `{ blocked: true, feature: 'hmo_interface', required_tier: 'Premium', upgrade_url: '/me/account/plans' }`.
- Frontend `SubscriptionGate` component shows a locked card with "Upgrade to Premium to unlock HMO/Insurance features" + CTA.

**Facility-level toggle:**
- New column `features_enabled` JSON on `facility_subscriptions` (or reuse `features.flags`).
- Super admin can toggle `hmo_interface` per facility regardless of plan (for demos/trials).
- Facility admin sees the feature as "Available on Premium" if their plan doesn't include it.

### Phase 10 — Legacy Cleanup & Unification ✅ DONE

- ✅ **Deprecate** `hmo` table + stored procedures — migration marked deprecated, new code uses `hmo_providers`.
- ✅ **Deprecate** `InsuranceTypeCreation` table — `users.js getInsuranceType` now reads from `insurance_plans`, returns compatible shape (`plan_name AS insurance_name`).
- ✅ **Migrate** `HMORegistration.jsx` → `HMOProvidersManagement` — AdminDashboard routes now point to managed-care components.
- ✅ **Migrate** `InsuranceTypeCreation.jsx` → `InsuranceSchemesManagement` — same treatment.
- ✅ **PatientEntitlements, PreAuthTracking, AgreementInfo** — already mounted in `ViewPatient.jsx` (record/patients/).
- ✅ **HmoClaimsReport.jsx** — already uses `hmo_claims` (managed-care), SQL is correct.
- ✅ **HMOBillingReport + HMOPatientReport** — already wired to `/api/hmo/billing/records` and `/api/hmo/patient/records` (Phase 1 managed-care endpoints).

---

## 4. Backward Compatibility Guarantees

1. **All existing tables preserved** — new columns are NULL-able with defaults.
2. **All existing endpoints continue to work** — new endpoints are additive, old ones unchanged.
3. **Cash patients unaffected** — insurance engine only activates when `accountType ∈ {HMO, NHIA, Corporate, Retainership}`.
4. **Non-premium facilities** see locked cards, not broken pages.
5. **Legacy HMO `hmo` table** remains readable (reports that query it still work) but new writes go to `hmo_providers`.
6. **patientrecords.accountType** continues as the single source of truth for patient payment category — `patient_insurance_policies` is additive secondary data.
7. **Existing claims in `draft`/`submitted`/`approved`/`paid` statuses are untouched** — new columns added with NULL defaults.

---

## 5. Execution Order

| Phase | Description | Effort | Dependencies |
|---|---|---|---|
| P1 | Insurance Organizations & Plans model | 3h | None |
| P2 | Insurance Engine + Coverage Check | 4h | P1 |
| P3 | Split Billing Engine | 4h | P2 |
| P4 | Claims Lifecycle Enhancements | 2h | P1 |
| P5 | Capitation Module | 2h | P1 |
| P6 | Insurance Dashboard | 2h | P4 |
| P7 | API Adapter Layer | 3h | P1 |
| P8 | EMR Integration Hooks | 2h | P2 |
| P9 | Feature Visibility & Upgrade Path | 1h | None |
| P10 | Legacy Cleanup & Unification | 2h | P9 |

**Total estimated:** ~25 hours for full implementation.

**Can be parallelized:** P1 → (P2, P4, P5, P7 in parallel) → (P3, P6, P8 in parallel) → P9 → P10.
