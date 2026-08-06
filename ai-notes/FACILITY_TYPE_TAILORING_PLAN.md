# Facility Type Tailoring — Analysis & Enhancement Plan

> **Date:** August 6, 2026
> **Status:** Analysis complete → ready for Phase 1 implementation

---

## 1. Current State Analysis

### 1.1 Database Schema

**`hospitals.type`** — `varchar(20)` with no ENUM constraint. The following values exist in production seed data:

| Value | Count | Notes |
|---|---|---|
| `hospital` / `Hospital` | 3 | **Case-inconsistent!** |
| `pharmacy` | 10 | Most common in seed |
| `diagnosticCenter` | 2 | camelCase |
| `clinic` | 1 | Amisal Dental Care |
| `factory` | 1 | Binadam Oil Mills — should not exist |

**`users.userType`** — `varchar(10)`, exists in schema but is **never set during onboarding**. Only used in one place: `permissionHelper.isSuperAdmin()` checks for `userType === 'super_admin'`.

**`hospitals.modules`** and **`hospitals.features`** — `varchar(100)` and `varchar(500)` — columns exist in the schema but are **never populated or read**. They were clearly intended for this exact purpose but were abandoned.

### 1.2 How Type Is Captured During Onboarding

#### Cloud Onboarding (`FacilityOnboarding.jsx` → `POST /onboarding/facility`)
- Type selector has 5 options: Hospital/Clinic, Clinic, Pharmacy, Laboratory, Diagnostic Center
- The selected type is stored in `hospitals.type`
- Admin user is created with **FULL `accessTo`** (all 18 modules) — type is **NOT used to filter**
- Departments are seeded per type (Hospital gets 8, Pharmacy gets 3, etc.)
- Services are seeded per type
- ✅ Good type selection UI
- ❌ Type doesn't affect what the admin sees

#### Offline Claim (`FacilityClaim` → `PUT /onboarding/claim`)
- Type selector has same 5 options
- Facility type is updated
- Admin credentials are replaced
- ❌ No module filtering based on type

#### Legacy Sign-Up (`AddHospital.jsx` → `POST /hospitals/create` + `POST /auth/sign-up`)
- Type selector has 4 options: Hospital, Diagnostic Center, Laboratory, Pharmacy
- Module checkboxes are shown based on type:
  - Hospital → Admin, Records, Pharmacy, Reports, Lab, Operation, Theater
  - Pharmacy → Admin, Pharmacy, Reports, Account
  - Laboratory → Admin, Records, Reports, Laboratory
  - Diagnostic Center → Admin, Reports, Account, Laboratory
- ✅ Type-based module filtering exists here!
- ❌ But the `functionality` (fine-grained permissions) is populated from `allModule` data — all modules, not filtered

### 1.3 How Type Affects the Frontend Experience

#### Welcome Page (`WelcomePage.jsx`)
- Shows tiles for all 18 modules
- Filters only by `user.accessTo` (the user's access string array)
- **Zero awareness of facility type** — a pharmacy admin sees Dental, Radiology, Theater tiles

#### Route Gating (`AuthenticatedContainer.jsx`)
- Each route checks `hasAccess(user, ["ModuleName"])`
- `hasAccess` checks if `user.accessTo.includes(moduleName)`
- **No type-based gating** — if accessTo says "Dental", the route renders

#### Sidebar / Navigation
- The main app sidebar is module-specific (PharmacyIndex, DentalRouter, etc.)
- Each module has its own internal navigation
- **No central "type-based" sidebar filtering** — modules that don't apply to a facility type still appear

#### Ad-hoc Type Checks (Scattered)
A few components check `facility.type` directly:

| File | Check | Purpose |
|---|---|---|
| `Lab/NewLaboratory/SampleAnalysisContainer.jsx` | `facility.type === "hospital"` | Show/hide hospital-specific lab features |
| `Lab/NewLaboratory/DisplayDepartment2.jsx` | `facility.type === "hospital"` | Filter department list |
| `Appointments/AppointmentMenu.jsx` | `facility.type === 'hospital'` | (Commented out!) |

These are ad-hoc, inconsistent, and fragile. If a new type is added (e.g., "eyeClinic"), none of these checks would work.

### 1.4 How Type Affects Backend Behavior

#### `onboarding.js` — Defaults per type
```js
const DEFAULT_DEPARTMENTS = {
  Hospital: ["General", "Outpatient", ...],  // 8 depts
  Pharmacy: ["General", "Retail", "Dispensary"],  // 3 depts
  Laboratory: ["General", "Sample Collection", ...],  // 6 depts
  diagnosticCenter: ["General", "Radiology", ...],  // 4 depts
};
```
- ✅ Departments are type-aware
- ❌ But `Clinic` type has NO departments defined (falls back to Hospital)

#### `hospitals.js` — No type-based filtering
- `POST /hospitals/create` just stores the type string
- `Hospital.findAll()` returns all hospitals regardless of type
- No backend validation of type values

#### No Type-Aware Middleware
- The passport/authenticate middleware checks `accessTo` and `functionality`
- It does NOT check facility type
- A pharmacy admin with "Dental" in their accessTo can access dental routes

---

## 2. Identified Gaps

### Gap 1: Type Not Propagated to User's `accessTo`
**Severity: HIGH**
When a facility is onboarded (cloud), the admin gets ALL 18 modules in `accessTo`. The facility type is stored but never used to determine which modules the admin should see. A pharmacy admin sees Dental, Radiology, Theater, Nurse, MMI, etc.

### Gap 2: `users.userType` Never Set
**Severity: MEDIUM**
The `userType` column exists in the `users` table but is never populated during onboarding or user creation. The only code that reads it is `isSuperAdmin()`, which checks for `'super_admin'`.

### Gap 3: Case Inconsistency in Type Values
**Severity: LOW (but causes bugs)**
- `'hospital'` vs `'Hospital'` vs `'clinic'` vs `'Clinic'`
- `'diagnosticCenter'` (camelCase) vs `'Pharmacy'` (PascalCase)
- Ad-hoc checks like `facility.type === "hospital"` are case-sensitive and miss `'Hospital'`

### Gap 4: `hospitals.modules` and `hospitals.features` Are Unused
**Severity: MEDIUM**
These columns were clearly designed for type-based module configuration but are completely dead. They represent the right architectural intent that was never finished.

### Gap 5: No Specialty or Multi-Specialty Support
**Severity: CRITICAL**
The current architecture assumes one facility = one type = one (optional) sub-type. This cannot represent:
- **Single-specialty clinics**: e.g., "Lagos Eye Clinic" — ophthalmology only, no dental/dermatology modules
- **Multi-specialty clinics**: e.g., "Metro Medical Centre" — dental + eye + dermatology + general practice under one roof
- **Hospitals with specialty centers**: e.g., a full hospital with a dedicated cardiology center and fertility clinic
The single `clinic_sub_type` VARCHAR column can hold only ONE value (`'dental'` OR `'eye'`, never both). A many-to-many specialties system is needed.

### Gap 6: Legacy `AddHospital` and Modern `FacilityOnboarding` Diverge
**Severity: HIGH**
- `AddHospital.jsx` has type-based module filtering (checkbox sets change per type)
- `FacilityOnboarding.jsx` has NO module filtering (admin gets everything)
- Two different onboarding paths produce different results

### Gap 7: Offline Installer Seeds Fixed Modules
**Severity: MEDIUM**
The offline installer's `postinstall.cmd` seeds a facility with hardcoded `accessTo` that includes ALL modules. Offline installs can't customize modules at install time.

### Gap 8: `hasStore` Field Unused for Module Control
**Severity: LOW**
The `hospitals.hasStore` toggle exists but doesn't control whether the pharmacy store module is shown. A pharmacy with `hasStore=0` still sees store features.

---

## 3. Enhancement Plan

### Phase 1: Type Definition & Normalization (Foundation)

**A. Create a canonical facility type registry**

Define supported types with their properties in a single source of truth:

```js
// backend/config/facilityTypes.js (new file)
const FACILITY_TYPES = {
  hospital: {
    label: 'Hospital / Medical Center',
    icon: '🏥',
    modules: ['Dashboard', 'Records', 'Doctors', 'Nurse', 'Pharmacy', 'Laboratory', 
              'Radiology', 'Theater', 'Dental', 'Inventory', 'Accounts', 'Admin', 
              'Reports', 'Appointments', 'Human Resource', 'MMI'],
    departments: [...],
    services: [...],
    hasStore: true,  // hospitals can have pharmacy stores
  },
  clinic: {
    label: 'Clinic',
    icon: '🩺',
    // Base modules every clinic gets — specialties ADD more modules on top
    baseModules: ['Dashboard', 'Records', 'Doctors', 'Accounts', 'Admin', 'Reports', 'Appointments'],
    departments: [...],
    services: [...],
    // Specialties are selected during onboarding (multi-select).
    // Each specialty contributes its own modules, departments, and services.
    // See Phase 5A for the full specialty-to-module mapping.
    availableSpecialties: ['general_practice', 'dental', 'ophthalmology', 'dermatology', 
                           'cardiology', 'orthopedics', 'obstetrics_gynecology', 'pediatrics',
                           'ent', 'psychiatry', 'radiology_diagnostic', 'fertility', 
                           'physiotherapy', 'emergency'],
  },
  pharmacy: {
    label: 'Pharmacy',
    icon: '💊',
    modules: ['Dashboard', 'Pharmacy', 'Inventory', 'Accounts', 'Admin', 'Reports'],
    // Pharmacy-only: no clinical modules
    departments: ['General', 'Retail', 'Dispensary'],
    services: [...],
  },
  laboratory: {
    label: 'Laboratory',
    icon: '🔬',
    modules: ['Dashboard', 'Records', 'Laboratory', 'Accounts', 'Admin', 'Reports'],
    departments: [...],
    services: [...],
  },
  diagnosticCenter: {
    label: 'Diagnostic Center',
    icon: '🩻',
    modules: ['Dashboard', 'Records', 'Radiology', 'Laboratory', 'Accounts', 'Admin', 'Reports'],
    departments: [...],
    services: [...],
  },
};
```

**B. Normalize existing type values (migration)**

```sql
-- Migration: normalize hospitals.type to lowercase, consistent values
UPDATE hospitals SET type = 'hospital' WHERE LOWER(type) IN ('hospital', 'hospi');
UPDATE hospitals SET type = 'clinic' WHERE LOWER(type) = 'clinic';
UPDATE hospitals SET type = 'pharmacy' WHERE LOWER(type) = 'pharmacy';
UPDATE hospitals SET type = 'laboratory' WHERE LOWER(type) IN ('laboratory', 'lab');
UPDATE hospitals SET type = 'diagnosticCenter' WHERE LOWER(type) IN ('diagnosticcenter', 'diagnostic_center');

ALTER TABLE hospitals 
  MODIFY COLUMN type VARCHAR(20) NOT NULL DEFAULT 'hospital',
  ADD CONSTRAINT chk_facility_type CHECK (type IN ('hospital','clinic','pharmacy','laboratory','diagnosticCenter'));
```

**C. Replace `clinic_sub_type` with a specialties system (migration)**

```sql
-- Migration: create specialties lookup table
CREATE TABLE specialties (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  slug        VARCHAR(30)  NOT NULL UNIQUE,
  name        VARCHAR(100) NOT NULL,
  icon        VARCHAR(10)  DEFAULT '🏥',
  description VARCHAR(255) DEFAULT NULL,
  is_active   TINYINT(1)   DEFAULT 1,
  created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Junction table: many-to-many between hospitals and specialties
CREATE TABLE hospital_specialties (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  facility_id  VARCHAR(50) NOT NULL,
  specialty_id INT         NOT NULL,
  created_at   TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_fac_spec (facility_id, specialty_id),
  FOREIGN KEY (facility_id) REFERENCES hospitals(id) ON DELETE CASCADE,
  FOREIGN KEY (specialty_id) REFERENCES specialties(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed the core specialties
INSERT INTO specialties (slug, name, icon, description) VALUES
  ('general_practice',    'General Practice',    '🩺', 'Family medicine, primary care'),
  ('dental',              'Dental',              '🦷', 'General dentistry, oral surgery'),
  ('ophthalmology',       'Ophthalmology',       '👁️', 'Eye care, optical services'),
  ('dermatology',         'Dermatology',         '🔬', 'Skin, cosmetic dermatology'),
  ('cardiology',          'Cardiology',          '❤️', 'Heart and cardiovascular care'),
  ('orthopedics',         'Orthopedics',         '🦴', 'Bone, joint, and spine care'),
  ('obstetrics_gynecology','OB/GYN',             '🤰', 'Women''s health, maternity'),
  ('pediatrics',          'Pediatrics',          '👶', 'Child and adolescent health'),
  ('ent',                 'ENT',                 '👂', 'Ear, nose, and throat'),
  ('psychiatry',          'Psychiatry',          '🧠', 'Mental health and counseling'),
  ('radiology_diagnostic', 'Radiology/Diagnostic','🩻', 'Imaging, X-ray, ultrasound, DICOM'),
  ('fertility',           'Fertility',           '🍼', 'IVF, reproductive medicine'),
  ('physiotherapy',       'Physiotherapy',       '💪', 'Rehabilitation and physical therapy'),
  ('emergency',           'Emergency Medicine',  '🚑', 'Urgent and trauma care');
```

### Phase 2: Wire Type Into User Creation (Core Fix)

**A. Update `POST /onboarding/facility`**
- After creating the facility, compute `accessTo` from the facility type registry
- Set `userType` on the admin user to match the facility type
- Only include modules relevant to the facility type

**B. Update `PUT /onboarding/claim`**
- After updating the facility type, recompute `accessTo` for the admin
- If the admin already created other users, log a warning (can't retroactively change them)

**C. Update legacy `POST /hospitals/create`**
- Use the same type registry for module selection
- Stop hardcoding accessTo strings

**D. Update `POST /auth/sign-up` (user creation)**
- When creating additional users for a facility, default their `accessTo` based on facility type
- Allow facility admin to grant/restrict modules within the facility's type bounds

### Phase 3: Frontend Type-Aware Filtering

**A. Welcome Page (`WelcomePage.jsx`)**
- Read facility type from `user` context or facility data
- Filter the module grid to only show modules relevant to the facility type
- Add a "Request additional modules" option for facility admins

**B. Route Gating (`AuthenticatedContainer.jsx`)**
- Already uses `hasAccess(user, ["ModuleName"])` — works correctly once accessTo is type-filtered
- No changes needed to route gating itself

**C. Sidebar / Navigation**
- The sidebar already filters by `accessTo` — works correctly once accessTo is type-filtered
- No structural changes needed

**D. Onboarding Wizard (`FacilityOnboarding.jsx`)**
- Show a preview of which modules will be available based on selected type
- Allow the admin to customize (add/remove modules within type bounds)

**E. Offline Installer**
- Update `postinstall.cmd` to seed `accessTo` based on the facility type
- Add a `--type=pharmacy` flag to the installer for pre-configuration

### Phase 4: Backend Type-Aware Middleware

**A. Add `requireFacilityType` middleware**
- Double-check that the user's facility type allows the requested module
- Defense-in-depth: even if accessTo is compromised, type acts as a backstop

**B. Type-based default data seeding**
- Use the type registry for ALL default data creation (departments, services, settings)
- Remove hardcoded defaults scattered across multiple files

### Phase 5: Specialties & Multi-Specialty Support (Rewritten)

**A. Specialty-to-module mapping**
Each specialty defines which modules it enables. The facility's active modules = the union of all selected specialties' modules.

```js
// backend/config/specialties.js (extends the type registry)
const SPECIALTY_MODULES = {
  general_practice:    ['Dashboard', 'Records', 'Doctors', 'Pharmacy', 'Laboratory', 'Accounts', 'Admin', 'Reports', 'Appointments'],
  dental:              ['Dental', 'Dental Lab', 'Oral Care Shop', 'Radiology'],
  ophthalmology:       ['Records', 'Doctors', 'Pharmacy', 'Accounts', 'Admin', 'Reports'],
  dermatology:         ['Records', 'Doctors', 'Pharmacy', 'Laboratory', 'Accounts'],
  cardiology:          ['Records', 'Doctors', 'Nurse', 'Laboratory', 'Radiology', 'Theater'],
  orthopedics:         ['Records', 'Doctors', 'Radiology', 'Theater', 'Physiotherapy'],
  obstetrics_gynecology:['Records', 'Doctors', 'Nurse', 'Laboratory', 'Radiology', 'Theater'],
  pediatrics:          ['Records', 'Doctors', 'Nurse', 'Pharmacy', 'Laboratory'],
  ent:                 ['Records', 'Doctors', 'Theater', 'Radiology'],
  psychiatry:          ['Records', 'Doctors', 'Pharmacy', 'Admin'],
  radiology_diagnostic:['Radiology', 'Records', 'Reports', 'Accounts'],
  fertility:           ['Records', 'Doctors', 'Laboratory', 'Theater', 'Radiology'],
  physiotherapy:       ['Records', 'Doctors', 'Accounts', 'Admin'],
  emergency:           ['Records', 'Doctors', 'Nurse', 'Radiology', 'Laboratory', 'Theater', 'Pharmacy'],
};
```

**B. Multi-specialty resolution**
A facility's effective module set = `union(all selected specialties' modules)`. For example:
- Dental + Eye clinic → Dental, Dental Lab, Oral Care Shop, Radiology, Records, Doctors, Pharmacy, Accounts, Admin, Reports, Appointments
- Dermatology + Cardiology → Records, Doctors, Pharmacy, Laboratory, Accounts, Nurse, Radiology, Theater

**C. Onboarding multi-specialty selection**
The onboarding wizard shows a specialty picker (multi-select checkboxes or chips). For hospital types, all specialties are available. For clinic types, the admin picks which specialties apply to their clinic.

**D. Specialty-specific departments and services**
Each specialty seeds its own departments and starter services. A multi-specialty facility gets the union.

**E. Backfill existing facilities**
- Amisal Dental Care (`type='clinic'`) → `dental` specialty
- Diagnostic centers → `radiology_diagnostic`
- General hospitals → `general_practice` + all inpatient specialties

---

## 4. Migration Plan

### Migration 1: Normalize type values
- File: `backend/migrations/YYYYMMDD00001-normalize-facility-types.js`
- Normalizes all existing `hospitals.type` values to lowercase, consistent keys
- Adds CHECK constraint

### Migration 2: Add specialties system
- File: `backend/migrations/YYYYMMDD00002-add-specialties.js`
- Creates `specialties` and `hospital_specialties` tables
- Seeds 14 core specialties
- Backfills existing facilities with appropriate specialties
- Drops old `clinic_sub_type` column if it exists (from earlier migrations)

### Migration 3: Backfill users.userType
- File: `backend/migrations/YYYYMMDD00003-backfill-user-type.js`
- Sets `users.userType` based on `hospitals.type` for the user's facility

### Migration 4: Backfill accessTo for existing users
- File: `backend/migrations/YYYYMMDD00004-backfill-access-to.js`
- For users with ALL modules, filters to only the modules relevant to their facility type
- **CAREFUL**: This is a potentially breaking change — only filter users created via onboarding (not manually)

---

## 5. Implementation Order (Recommended)

| Priority | Phase | Effort | Impact |
|---|---|---|---|
| **P0** | Phase 1A: Type registry | 2h | Foundation for everything |
| **P0** | Phase 1B: Normalize types (migration) | 1h | Fixes case bugs |
| **P0** | Phase 1C: Add specialties system (migration) | 2h | Specialty & multi-specialty foundation |
| **P0** | Phase 2A: Wire type into onboarding accessTo | 3h | Core fix — closes Gap 1 |
| **P1** | Phase 5A: Specialty-to-module mapping | 1.5h | What each specialty enables |
| **P1** | Phase 3A: WelcomePage type filtering | 2h | User-visible improvement |
| **P1** | Phase 2D: Sign-up type-aware defaults | 1h | Consistency for new users |
| **P1** | Phase 5C: Multi-specialty onboarding picker | 2h | Admin selects specialties |
| **P1** | Phase 5D: Specialty-specific departments/services | 1.5h | Right data per specialty |
| **P2** | Phase 3E: Offline installer type flag | 2h | Offline installs get type-aware modules |
| **P2** | Phase 4A: Backend type middleware | 2h | Security defense-in-depth |
| **P2** | Phase 3D: Onboarding module preview | 1h | UX improvement |
| **P2** | Phase 5E: Backfill existing facilities | 0.5h | Migrate existing clinics |
| **P3** | Phase 4B: Centralize default data | 2h | Cleanup tech debt |

---

## 6. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Backfilling accessTo breaks existing users | Migration 4 runs only on users created via onboarding, not manually-created users. Add a `backfill_safe` flag. |
| Facility admins want modules not in their type | Add "Request additional modules" button in Settings. Super admin can grant exceptions. |
| Type registry gets out of sync with actual modules | Single source of truth — any new module must be added to the registry's type definitions. |
| Offline users can't change type post-install | Add "Change facility type" in admin Settings (with confirmation and accessTo recomputation). |
