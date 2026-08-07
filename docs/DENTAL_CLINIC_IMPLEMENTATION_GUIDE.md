# 🦷 MyLikita Dental Clinic — Implementation Guide & Plan

> **Status:** Wireframe complete — Dental Clinic facility type is registered, modules
> are gated, and the existing dental UI is wired. This document covers the features
> that still need to be built to reach the Professional, Advanced, and Enterprise tiers.

---

## What's Already Wired (Phase 1 — COMPLETE)

When a facility selects **Dental Clinic** during onboarding, the system automatically:

| What | How |
|---|---|
| **Facility type** | Canonical key `dentalClinic` stored in `hospitals.type` |
| **Admin access** | `accessTo` = `Dashboard,Records,Dental,Dental Lab,Oral Care Shop,Radiology,Pharmacy,Accounts,Admin,Reports,Appointments,Inventory` |
| **Default departments** | General, Consultation, Dental Surgery, Dental Lab |
| **Starter services** | Dental Consultation, Dental Examination, Dental Procedure |
| **Trial plan** | Auto-assigned from `product_line = 'dental'` |
| **Plan ceiling** | Intersects type-resolved modules with the subscribed plan's `features.modules` |

**Existing dental components already connected:**
- `DentalRouter.jsx` — dental sidebar nav (Dashboard, Patients, Assigned, Appointments, Visits, Procedures, Treatment Plans, Prescriptions, Dental Lab, Radiology, Analytics, Settings)
- `DentalChart.jsx` — basic odontogram (adult/deciduous teeth, click-to-record conditions)
- `DentalProcedures.jsx` — procedure catalog with billing integration
- `DentalAppointments.jsx` + `AppointmentCalendar.jsx` — appointment booking, calendar, reminders
- `VisitsPage.jsx` + `VisitDocumentation.jsx` — visit flow (chief complaint → exam → diagnosis → treatment plan)
- `DentalLabDashboard.jsx` — lab job management (orthodontic + prosthetic)
- `PrescriptionForm.jsx` — dental prescriptions
- `TreatmentPlansDashboard.jsx` / `TreatmentPlansPage.jsx` — treatment plan creation and tracking
- `AnalyticsPage.jsx` / `SettingsPage.jsx` — dental analytics and settings
- API routes: `/dental/*`, `/dental/visits/*`, `/dental/clinical/*`, `/dental/lab/*`, `/dental/appointments/*`

---

## 🔵 Tier 2 — Professional Dental (not yet built)

These features should be built into the existing Dental module alongside the wired components above.

### 2.1 Periodontal Charting

**What it does:** Records per-tooth periodontal measurements with graphical visualization.

**Database:**
```sql
CREATE TABLE periodontal_chart (
  id VARCHAR(36) PRIMARY KEY,
  patient_id VARCHAR(36) NOT NULL,
  visit_id VARCHAR(36),
  facilityId VARCHAR(36) NOT NULL,
  chart_date DATE NOT NULL,
  tooth_number VARCHAR(3) NOT NULL,  -- e.g. '11','12',...,'48'
  pocket_depth_mb DECIMAL(4,1),       -- mesiobuccal
  pocket_depth_b  DECIMAL(4,1),       -- buccal
  pocket_depth_db DECIMAL(4,1),       -- distobuccal
  pocket_depth_ml DECIMAL(4,1),       -- mesiolingual
  pocket_depth_l  DECIMAL(4,1),       -- lingual
  pocket_depth_dl DECIMAL(4,1),       -- distolingual
  gingival_margin DECIMAL(4,1),
  bleeding BOOLEAN DEFAULT FALSE,
  plaque    BOOLEAN DEFAULT FALSE,
  furcation TINYINT DEFAULT 0,        -- 0=none, 1=incipient, 2=moderate, 3=through-and-through
  mobility TINYINT DEFAULT 0,         -- 0=none, 1=1mm, 2=2mm, 3=>2mm+vertical
  recession DECIMAL(4,1),
  notes TEXT,
  created_at DATETIME DEFAULT NOW(),
  updated_at DATETIME DEFAULT NOW() ON UPDATE NOW(),
  INDEX idx_perio_patient (patient_id, chart_date)
);
```

**Backend:**
- `GET /dental/periodontal/:patientId/:facilityId` — latest chart
- `POST /dental/periodontal` — save chart
- `GET /dental/periodontal/history/:patientId/:facilityId` — historical charts for trend

**Frontend:**
- New component: `PeriodontalChart.jsx` — tooth-by-tooth form with millimeter inputs per surface
- Visualization: color-coded tooth grid (green=yellow=red based on pocket depth)
- Trend chart: pocket depth over time per tooth (reuse the chart pattern from `VitalSignsHistory.jsx`)

**Estimated effort:** 3–4 days backend, 4–5 days frontend

---

### 2.2 Advanced Odontogram (Interactive Tooth Surfaces)

**What it does:** Extends the existing `DentalChart.jsx` with per-surface condition recording, treatment history per tooth, and tooth-level notes/attachments.

**Frontend changes (existing `DentalChart.jsx` + `ToothDiagram.jsx`):**
- Surface picker: when a tooth is clicked, show mesial/distal/buccal/lingual/occlusal surfaces for condition assignment
- Tooth timeline: click tooth → see chronological history (examination → treatment → follow-up)
- Tooth attachments: upload X-ray/photos linked to specific teeth
- Tooth mobility slider (0–3)
- Existing restorations overlay on the chart (amalgam/composite/crown/bridge/implant icons)
- Print chart button → PDF export

**Database additions:**
```sql
CREATE TABLE tooth_conditions (
  id VARCHAR(36) PRIMARY KEY,
  patient_id VARCHAR(36) NOT NULL,
  visit_id VARCHAR(36),
  tooth_number VARCHAR(3) NOT NULL,
  surface VARCHAR(20),              -- 'mesial','distal','buccal','lingual','occlusal'
  condition_code VARCHAR(20),       -- 'caries','filling','crown','rct','extraction','implant','bridge','missing','sealant','veneer'
  notes TEXT,
  recorded_at DATETIME DEFAULT NOW()
);
```

**Estimated effort:** 3–4 days frontend-heavy (the tooth diagram work is SVG/Canvas)

---

### 2.3 Patient Portal (Basic)

**What it does:** Patients can log in, view appointments, treatment history, invoices, and prescriptions.

**Backend:**
- `POST /patient-portal/auth` — OTP-less login (patient ID + phone/email verification)
- `GET /patient-portal/appointments/:patientId` — upcoming + past
- `GET /patient-portal/treatments/:patientId` — procedure history
- `GET /patient-portal/invoices/:patientId` — billing history
- `GET /patient-portal/prescriptions/:patientId` — prescriptions

**Frontend:**
- New route group: `/portal/*` (Public wrapper, separate from the authenticated app)
- `PortalLogin.jsx` — enter patient ID + OTP/DOB verification
- `PortalDashboard.jsx` — appointments card, recent treatments, outstanding balance
- `PortalAppointments.jsx` — book from available slots
- `PortalBilling.jsx` — view invoices + pay online (Phase 2)

**Estimated effort:** 3 days backend, 3–4 days frontend

---

## 🟣 Tier 3 — Advanced Dental Platform (not yet built)

### 3.1 DICOM / Digital Imaging Integration

**What it does:** Ingest and view DICOM images (X-rays, CBCT, panoramic) directly in the patient record.

**Approach A — Lightweight (recommended for v1):**
- Use **Orthanc** (open-source DICOM server) running alongside the app
- Backend proxy: `GET /dental/imaging/studies/:patientId` → queries Orthanc REST API
- Frontend: embed **Cornerstone.js** DICOM viewer (open-source, zero license cost)
- Upload flow: drag-and-drop DICOM files → proxy to Orthanc via `POST /dental/imaging/upload`

**Approach B — Cloud-based (for cloud deployments):**
- Orthanc in Docker (already in docker-compose.yml)
- S3/DigitalOcean Spaces for DICOM object storage

**Backend:**
- `GET /dental/imaging/studies/:patientId/:facilityId` — list studies
- `GET /dental/imaging/studies/:studyId/series` — series in study
- `GET /dental/imaging/instances/:instanceId/frame` — rendered PNG frame
- `POST /dental/imaging/upload` — multipart DICOM file upload

**Frontend:**
- New component: `DicomViewer.jsx` — Cornerstone.js-based viewer (windowing, zoom, pan, measurement tools)
- Integration into `DentalDashboard.jsx` patient view tab

**Dependencies to add:**
```json
{
  "cornerstone-core": "^2.6.1",
  "cornerstone-tools": "^6.0.6",
  "cornerstone-wado-image-loader": "^4.7.3",
  "dicom-parser": "^1.8.21",
  "cornerstone-math": "^0.1.10"
}
```

**Estimated effort:** 5–7 days backend (Orthanc integration), 5–7 days frontend (Cornerstone.js viewer)

---

### 3.2 Insurance / HMO Claims for Dental

**What it does:** The insurance infrastructure is already built (HMO providers, plans, patient policies, claims lifecycle, split billing). Dental needs disease/procedure-code mapping for claims.

**Backend additions:**
- `DentalInsuranceMapper.js` — maps dental procedures (e.g., `DENTAL-EXAM`) to insurance benefit codes
- `POST /dental/claims/preauthorize` — pre-auth request for planned procedures
- Coverage check: reuse `billingService.splitBill()` with `payerType = 'insurance'`

**Frontend additions:**
- `InsuranceTab.jsx` in the dental visit flow — shows coverage breakdown before treatment
- Pre-authorization status badge in treatment plan view

**Estimated effort:** 2–3 days (most infrastructure is reusable from the HMO module)

---

### 3.3 Advanced Financial Management

**What it does:** Dentist commissions, staff commissions, chair utilization, revenue per chair.

**Database:**
```sql
CREATE TABLE dentist_commissions (
  id VARCHAR(36) PRIMARY KEY,
  dentist_id INT NOT NULL,
  procedure_id VARCHAR(36),
  commission_pct DECIMAL(5,2),
  commission_flat DECIMAL(10,2),
  effective_from DATE,
  effective_to DATE,
  facilityId VARCHAR(36)
);

CREATE TABLE chair_utilization (
  id VARCHAR(36) PRIMARY KEY,
  chair_name VARCHAR(50),
  appointment_id VARCHAR(36),
  start_time DATETIME,
  end_time DATETIME,
  facilityId VARCHAR(36),
  INDEX idx_chair_date (facilityId, start_time)
);
```

**Estimated effort:** 2–3 days backend, 2–3 days frontend reports

---

### 3.4 Multi-Branch Support

**What it does:** A dental group with multiple locations sees all branches centrally.

This is already partially supported by the `facilityId` tenant isolation architecture. The remaining work:
- Super-admin: "Add branch" links facilities under a `parent_facility_id`
- Central dashboard: aggregates across branches
- Staff assignment: which branches a dentist works at
- Inventory: transfer between branches

**Estimated effort:** 5–7 days (leveraging existing tenant isolation)

---

## 🟠 Tier 4 — Enterprise Dental Platform (not yet built)

### 4.1 AI-Assisted Features

| Feature | Approach | Effort |
|---|---|---|
| **Caries detection** | Integrate open-source model (e.g., YOLOv8 fine-tuned on dental X-rays) via REST API | 10–14 days |
| **Bone loss detection** | Periapical image analysis — measure CEJ-to-bone-crest distance | 8–10 days |
| **Clinical note summarization** | LLM prompt (reuse the Clinical Summary queue infrastructure) | 3–4 days |
| **Treatment plan recommendation** | Rules engine based on diagnosis → procedure mapping | 5–7 days |
| **Analytics Q&A** | Natural language → SQL (reuse existing query infrastructure) | 5–7 days |

### 4.2 Enterprise Identity (SSO / MFA)

- SSO: SAML 2.0 / OIDC integration (Azure AD, Okta)
- MFA: TOTP (already partially in `users` model — `two_factor_secret`, `two_factor_enabled`)
- Session management: device tracking, force-logout

### 4.3 Advanced Audit

- Immutable audit log (append-only table with hash-chain verification)
- Field-level change tracking (before/after values)
- HIPAA-compliant access logs

### 4.4 High Availability / Disaster Recovery

- MySQL replication (primary-replica)
- Automated backups to S3-compatible storage
- Failover automation

### 4.5 Enterprise Integration Platform

- Webhook system (subscribe to events: `patient.created`, `claim.submitted`, `appointment.booked`)
- REST API with API-key authentication for third-party integrations
- FHIR R4 compatibility layer (for health system interoperability)

---

## 🎯 Recommended Build Order

| Priority | Feature | Tier | Rationale |
|---|---|---|---|
| **P0** | Periodontal Charting | Professional | Core dental differentiator — every dentist needs this |
| **P0** | Advanced Odontogram (surfaces + history) | Professional | Builds on existing DentalChart.jsx — high impact, moderate effort |
| **P1** | Insurance Claims for Dental | Advanced | Leverages complete existing HMO infrastructure |
| **P1** | Patient Portal (basic) | Professional | High patient demand, reduces front-desk load |
| **P2** | DICOM / Imaging | Advanced | Requires Orthanc + Cornerstone.js — heavier lift |
| **P2** | Dentist Commissions + Chair Utilization | Advanced | Revenue-critical for multi-dentist practices |
| **P3** | Multi-Branch | Advanced | Only relevant for growing groups |
| **P4** | AI-Assisted Features | Enterprise | Requires ML infrastructure |
| **P4** | Enterprise SSO / Audit / HA | Enterprise | Large institutional deployments only |

---

## 📋 Integration Testing Checklist

After each tier is built, run this E2E test:

1. Onboard a **Dental Clinic** facility via wizard
2. Verify admin sees ONLY dental modules in sidebar (no Theater, no Nurse, no Surgery)
3. Create a dental patient → book appointment → start visit
4. Open odontogram → click tooth → record caries → save
5. Create treatment plan → add procedure → estimate cost
6. Complete visit → bill → verify dental procedure billing
7. Lab request: create prosthetic job → track status → complete
8. Prescription: prescribe medication → verify pharmacy integration
9. Reports: verify dental procedures report, revenue by dentist
10. Subscription: assign Professional plan → verify module ceiling shrinks to paid modules only
