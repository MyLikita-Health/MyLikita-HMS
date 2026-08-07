# Retainership Module — Deep Analysis & Complete Implementation Plan

**Date:** August 7, 2026
**Status:** Backend 70% complete, Frontend 0%, Integration 0%

---

## 1. What Exists Today

### 1.1 Database (prime-db.sql) — ✅ Complete

| Table | Lines in prime-db.sql | Status |
|---|---|---|
| `retainership_organizations` | 11258 | ✅ Fully defined |
| `retainership_plans` | 11328 | ✅ Fully defined |
| `retainership_plan_services` | 11299 | ✅ Fully defined |
| `retainership_visits` | 11400 | ✅ Fully defined |
| `retainership_invoices` | 11216 | ✅ Fully defined |
| `retainership_deposits` | 11178 | ✅ Fully defined |
| `retainership_refunds` | 11364 | ✅ Fully defined |

Patient records have the needed columns:
- `patient_type` ENUM('cash','retainership','hmo','nhia','corporate') — line 9152
- `retainership_organization_id` — line 9153
- `retainership_plan_id` — line 9154
- `staff_id` — line 9155
- `retainership_expiry_date` — line 9156

Permissions for retainership exist:
- `billing.retainership.view` (id 31)
- `billing.retainership.manage` (id 32)

### 1.2 Backend Controller (controller/retainership.js) — ✅ 70% Complete

| Function | Status | Notes |
|---|---|---|
| `createOrganization` | ✅ Working | Uses UUID, validates facilityId |
| `getOrganizations` | ✅ Working | Optional status filter |
| `getOrganizationById` | ✅ Working | |
| `updateOrganization` | ✅ Working | Dynamic field updates |
| `deleteOrganization` | ✅ Working | Checks for linked patients |
| `createPlan` | ✅ Working | Validates org exists, JSON services |
| `getPlans` / `getAllPlans` | ✅ Working | Parses JSON fields |
| `updatePlan` / `deletePlan` | ✅ Working | Guard checks |
| `trackVisit` | ✅ Working | Records covered/uncovered amounts |
| `getVisits` | ✅ Working | With patient/organization JOINs |
| `checkCoverage` | ⚠️ Partially working | Checks plan exclusions but DOES NOT integrate with the billing engine (`billingService.splitBill` / `insuranceEngine.checkCoverage`) |
| `generateInvoice` | ✅ Working | Generates monthly invoices, links visits |
| `getInvoices` / `getAllInvoices` | ✅ Working | |
| `getInvoiceById` | ✅ Working | Returns line items (visits) |
| `markInvoicePaid` | ✅ Working | |
| `getBalanceReport` | ✅ Working | Comprehensive org-level AR report |
| `getOrganizationBalance` | ✅ Working | Single org detail with recent visits/invoices |

### 1.3 Backend Routes (routes/retainership.js) — ✅ Registered

Routes ARE registered in `app.js` line 310: `require("./routes/retainership")(app)`

**⚠️ Critical gap:** NONE of the routes use authentication middleware. Every other module uses `passport.authenticate("jwt", { session: false })` or a gate middleware. Retainership endpoints are wide open.

### 1.4 Frontend — ❌ Nothing

Zero frontend components exist for retainership. There is:
- No organization management page
- No plan configuration UI
- No visit tracking UI
- No invoice generation/viewing
- No accounts receivable dashboard
- No employee/beneficiary management
- No integration with the patient registration flow

### 1.5 SQL Migration Files — ✅ Exist but need wiring

| File | Purpose |
|---|---|
| `sql/retainership_tables.sql` | Original schema (standalone service codes) |
| `sql/retainership_tables_updated.sql` | Updated schema (uses existing services/lab/pharm_store) |
| `sql/retainership_deposits_refunds.sql` | Deposits and refunds with audit trails |
| `sql/add_retainership_permissions.sql` | Permission seeding |
| `sql/add_retainership_management_permission.sql` | Management permission |

There's no Sequelize migration for retainership — it uses raw SQL files, not the migration framework.

---

## 2. What's Broken / Missing

### 2.1 CRITICAL: No Authentication on Routes

```javascript
// Current (routes/retainership.js):
app.post("/retainership/organizations/create", retainership.createOrganization);
// NO AUTH — anyone can hit this

// Should be:
const passport = require("passport");
app.post("/retainership/organizations/create",
  passport.authenticate("jwt", { session: false }),
  retainership.createOrganization);
```

### 2.2 CRITICAL: Not Integrated with Billing Engine

The `checkCoverage` function in retainership.js is a standalone implementation. It does NOT integrate with:

- `services/billingService.js` — `splitBill()` / `splitLineItem()`
- `services/insuranceEngine.js` — `checkCoverage()`
- `controller/account.js` — `casherPayBill` (the cashier payment flow)

When a retainership patient visits the cashier, the system doesn't:
1. Detect the patient is retainership
2. Route billing through the retainership coverage check
3. Record the visit in `retainership_visits`
4. Apply the retainership plan's coverage rules

### 2.3 HIGH: No Employee/Beneficiary Management

The spec requires:
- Employees with staff ID, department, grade, employment status
- Dependents (wife, child) with relationship tracking
- Per-employee annual limits (e.g., ₦250,000/year)
- Usage tracking against limits

None of this exists. The `patientrecords` table has `staff_id` but no:
- Employee table linking to organizations
- Dependent relationships
- Annual limit tracking
- Usage/remaining balance per employee

### 2.4 HIGH: No Frontend UI

Complete absence of any React components for retainership.

### 2.5 MEDIUM: No Approval Workflow

The spec requires:
- Service requests that need company approval (e.g., MRI)
- Quotation generation
- Approve/deny flow
- This doesn't exist

### 2.6 MEDIUM: Invoice Email/PDF Generation

No mechanism to:
- Export invoices as PDF
- Email monthly statements to organizations
- Track payment status with reminders

### 2.7 LOW: No services_existing Controller

The routes reference `controller/services_existing.js` — the file exists but may not be fully functional.

### 2.8 LOW: Plan Schema Drift

`retainership_tables.sql` uses `covered_services` (single JSON array) while `retainership_tables_updated.sql` uses per-category arrays (`covered_general_services`, `covered_lab_services`, `covered_pharmacy_services`). The controller code references both patterns inconsistently.

---

## 3. Implementation Plan

### Phase 1: Foundation (Security + Schema Alignment) — 4h

| # | Task | Files |
|---|---|---|
| 1.1 | Add JWT auth to all retainership routes | `routes/retainership.js` |
| 1.2 | Create a Sequelize migration that runs all retainership SQL on fresh install | New: `migrations/20260807000008-retainership-tables.js` |
| 1.3 | Align plan schema: standardize on per-category JSON columns | `sql/retainership_tables_updated.sql`, `controller/retainership.js` |
| 1.4 | Add retainership receivable account (400035) to the HMO receivable accounts mapping | `services/billingService.js` |
| 1.5 | Wire retainership checkCoverage into `billingService.splitLineItem` as a payer type | `services/billingService.js` |
| 1.6 | Backend syntax + frontend build check | — |

### Phase 2: Billing Integration — 5h

| # | Task | Files |
|---|---|---|
| 2.1 | Add retainership detection to `casherPayBill`: detect `patient_type = 'retainership'`, call retainership coverage check, route to retainership receivable (400035) | `controller/account.js` |
| 2.2 | Auto-create `retainership_visits` row when retainership patient is billed | `controller/account.js` |
| 2.3 | Add retainership mode to `DeptCashier.jsx` and `Review.jsx` (like INSURANCE mode but for retainership) | `frontend/src/components/common/DeptCashier.jsx`, `frontend/src/components/account/Review.jsx` |
| 2.4 | Add retainership AR aging to insurance dashboard (400035 receivable) | `services/insuranceDashboard.js` |
| 2.5 | Validate: backend syntax + frontend build | — |

### Phase 3: Employee & Beneficiary Management — 6h

| # | Task | Files |
|---|---|---|
| 3.1 | Create `retainership_employees` table (staff_id, org_id, department, grade, employment_status, annual_limit, used_amount) | New migration |
| 3.2 | Create `retainership_dependents` table (employee_id, relationship, name, phone, covered) | New migration |
| 3.3 | Backend CRUD for employees and dependents | `controller/retainership.js` |
| 3.4 | Employee limit tracking: deduct from annual_limit on each visit, block when exhausted | `controller/retainership.js` |
| 3.5 | Employee/dependent search by staff ID at registration | `controller/retainership.js` |

### Phase 4: Frontend UI — 8h

| # | Task | Files |
|---|---|---|
| 4.1 | **RetainershipDashboard** — main menu entry point with org summary cards | `frontend/src/components/account/retainership/` |
| 4.2 | **OrganizationsList** — table with search, status filter, create/edit modal | New component |
| 4.3 | **OrganizationDetail** — tabs: overview, employees, plans, invoices, balance | New component |
| 4.4 | **PlansManagement** — create/edit plans with coverage picker (services/lab/pharmacy multi-select) | New component |
| 4.5 | **EmployeesPanel** — employee table, add/edit modal, dependency management | New component |
| 4.6 | **InvoicesPanel** — monthly invoice list, generate, mark paid, view line items | New component |
| 4.7 | **RetainershipARWidget** — accounts receivable aging by organization for the account dashboard | New component |
| 4.8 | Wire into AccountDashboard.jsx sidebar/navigation | `frontend/src/components/account/AccountDashboard.jsx` |
| 4.9 | Patient registration integration: retainership fields in patient form | `frontend/src/components/record/patients/` |

### Phase 5: Approval Workflow — 3h

| # | Task | Files |
|---|---|---|
| 5.1 | Create `retainership_auth_requests` table (like preauth_requests but for retainership) | New migration |
| 5.2 | Backend: request approval, send quotation, approve/deny | `controller/retainership.js` |
| 5.3 | Frontend: corporate desk approval queue | New component |

### Phase 6: Invoice PDF & Delivery — 2h

| # | Task | Files |
|---|---|---|
| 6.1 | PDF export for retainership invoices (reuse pdfkit from claim export) | `controller/retainership.js` |
| 6.2 | Batch monthly invoice generation cron job | `services/retainershipCron.js` |
| 6.3 | Email invoice to organization contact_email (using Resend) | `controller/retainership.js` |

### Phase 7: Testing & Validation — 2h

| # | Task |
|---|---|
| 7.1 | E2E test script: create organization → plan → employee → register patient → bill → generate invoice → mark paid |
| 7.2 | Coverage badge verification for retainership services |
| 7.3 | Frontend build + backend syntax validation |

---

## 4. Payer Engine Future Architecture (Phase 8+)

The user's spec calls for a **Payer Management Framework** that unifies all payer types under one engine. This is the long-term vision:

```
payer_organizations
├── type: 'insurance' | 'retainership' | 'corporate' | 'government' | 'donor'
├── contracts (many-to-many with organizations)
│   ├── covered_services (per-category JSON)
│   ├── authorization_rules
│   ├── limits (annual, per-visit, per-employee)
│   ├── payment_terms
│   └── invoice_cycle
├── beneficiaries (patients linked to payer/contract)
└── financials (AR aging, invoices, receipts)

Billing Engine
├── detectPayer(patientId) → { type, contract, coverage }
├── splitBill(service, payer) → { covered, patient_responsibility }
└── routeReceivable(payerType) → account 40003x
```

When this is built, the HMO/insurance module and retainership module merge into one configurable Payer Management module, with insurance and retainership as two payer types.

---

## 5. Summary of Changes

| Phase | Hours | Impact |
|---|---|---|
| Phase 1 (Foundation) | 4h | Security + billing integration |
| Phase 2 (Billing) | 5h | Retainership works at the cashier |
| Phase 3 (Employees) | 6h | Staff/dependent management + limits |
| Phase 4 (Frontend) | 8h | Complete UI for retainership |
| Phase 5 (Approval) | 3h | Company approval flow |
| Phase 6 (PDF/Email) | 2h | Invoice delivery |
| Phase 7 (Testing) | 2h | End-to-end validation |
| **Total** | **30h** | |

---

## 6. Backward Compatibility

- All existing tables are additive — no columns removed
- Patient `patient_type` enum already includes 'retainership' — no migration needed
- `casherPayBill` already supports INSURANCE mode — retainership follows the same pattern
- Existing permissions (`billing.retainership.view`, `billing.retainership.manage`) are preserved
- The HMO/insurance module is completely unaffected

---

## 7. Immediate Next Steps

1. **Phase 1.1**: Add JWT auth to retainership routes (critical security fix — 30 min)
2. **Phase 2.1**: Wire retainership into casherPayBill (enables core billing — 2h)
3. **Phase 4.1-4.2**: Build RetainershipDashboard + OrganizationsList (visible progress — 3h)
