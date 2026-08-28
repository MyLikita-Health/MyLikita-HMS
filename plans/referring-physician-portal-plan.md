# Referring Physician Portal — Implementation Plan

## Overview

A dedicated portal for external physicians (doctors who refer patients to the diagnostics center) to:
1. **Self-register** or be **admin-created** → facility admin approves
2. **Place lab and radiology requests** for their patients
3. **Track request status** (ordered → collected → resulted → authorised)
4. **View results** when ready (lab + radiology)
5. **Manage their patients** (search, register new)

## Architecture

### New Database Table: `referring_physicians`

```sql
CREATE TABLE referring_physicians (
  id INT AUTO_INCREMENT PRIMARY KEY,
  facilityId VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  fullname VARCHAR(255) NOT NULL,
  phone VARCHAR(50),
  specialization VARCHAR(100),
  license_number VARCHAR(100),
  clinic_name VARCHAR(255),
  clinic_address TEXT,
  status ENUM('pending','approved','rejected','suspended') DEFAULT 'pending',
  approved_by INT NULL,
  approved_at DATETIME NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_email_facility (email, facilityId)
);
```

### Auth Flow

- **Self-registration**: Physician signs up → status = `pending` → admin approves → status = `approved`
- **Admin-created**: Admin creates account → status = `approved` immediately
- **JWT scope**: `scope: 'physician'` (separate from `scope: 'patient'`)
- **Middleware**: `authenticatePhysician` (similar to `authenticatePatient`)

---

## Implementation Steps

### Step 1: Database Migration
**File**: `backend/migrations/YYYYMMDD000001-create-referring-physicians.js`
- Create `referring_physicians` table
- Add `referring_physician_id` column to `newlab_requests` and `radiology_requests`

### Step 2: Backend Auth Controller
**File**: `backend/controller/referringPhysicianAuth.js`
- `register()` — Self-registration (creates pending account)
- `login()` — JWT auth with scope `physician`
- `forgotPassword()` — Temporary password flow
- `getProfile()` — Return physician profile
- `updateProfile()` — Update profile fields
- `authenticatePhysician` middleware — Verify JWT, attach `req.physician`

### Step 3: Backend Request Controller
**File**: `backend/controller/referringPhysicianRequests.js`
- `createLabRequest()` — Place lab request (search patient, select tests, submit)
- `getLabRequests()` — List physician's lab requests with status
- `getLabRequestDetail()` — Full request detail + results
- `createRadiologyRequest()` — Place radiology request
- `getRadiologyRequests()` — List physician's radiology requests
- `getRadiologyRequestDetail()` — Full request detail + report
- `searchPatients()` — Search patients at the facility
- `registerPatient()` — Register a new patient

### Step 4: Backend Routes
**File**: `backend/routes/referring-physician.js`
```
POST   /api/physician/register          — Self-register
POST   /api/physician/login             — Login
POST   /api/physician/forgot-password   — Reset password
GET    /api/physician/profile           — Get profile
PUT    /api/physician/profile           — Update profile

POST   /api/physician/lab-requests      — Create lab request
GET    /api/physician/lab-requests      — List lab requests
GET    /api/physician/lab-requests/:id  — Lab request detail + results

POST   /api/physician/radiology-requests      — Create radiology request
GET    /api/physician/radiology-requests      — List radiology requests
GET    /api/physician/radiology-requests/:id  — Radiology request detail + report

GET    /api/physician/patients/search   — Search patients
POST   /api/physician/patients          — Register new patient
```

### Step 5: Admin Management
**File**: `backend/controller/adminReferringPhysicians.js`
- `listPhysicians()` — List all referring physicians for facility
- `approvePhysician()` — Approve pending physician
- `rejectPhysician()` — Reject pending physician
- `suspendPhysician()` — Suspend a physician
- `createPhysician()` — Admin creates account directly

**File**: `backend/routes/admin-referring-physicians.js`
```
GET    /api/admin/referring-physicians           — List all
POST   /api/admin/referring-physicians           — Create
PUT    /api/admin/referring-physicians/:id/approve  — Approve
PUT    /api/admin/referring-physicians/:id/reject   — Reject
PUT    /api/admin/referring-physicians/:id/suspend  — Suspend
```

### Step 6: Email Templates
**File**: `backend/emails/referringPhysician/referringPhysician.js`
- `buildRegistrationEmail()` — Welcome + pending approval notice
- `buildApprovalEmail()` — Account approved, can now log in
- `buildResultReadyEmail()` — Lab/radiology results ready

### Step 7: Frontend — Portal Auth Pages
**Directory**: `frontend/src/components/referring-physician/`
- `ReferringPhysicianApp.jsx` — Main app with routing
- `pages/LoginPage.jsx` — Login form
- `pages/RegisterPage.jsx` — Self-registration form
- `pages/ForgotPasswordPage.jsx` — Password reset
- `tokens.css` — Design tokens (reuse patient portal tokens)

### Step 8: Frontend — Portal Layout
**Directory**: `frontend/src/components/referring-physician/layout/`
- `PhysicianLayout.jsx` — Mobile + desktop layout (mirror patient portal)
- `DesktopSidebar.jsx` — Sidebar navigation
- `BottomNav.jsx` — Mobile bottom navigation

### Step 9: Frontend — Portal Pages
**Directory**: `frontend/src/components/referring-physician/pages/`
- `HomePage.jsx` — Dashboard with stats (pending, in-progress, completed)
- `NewLabRequest.jsx` — Place lab request (patient search, test selection, submit)
- `NewRadiologyRequest.jsx` — Place radiology request
- `LabRequestsPage.jsx` — List all lab requests with status tracking
- `LabRequestDetailPage.jsx` — View request + results
- `RadiologyRequestsPage.jsx` — List all radiology requests
- `RadiologyRequestDetailPage.jsx` — View request + report
- `PatientsPage.jsx` — Manage patients (search, register)
- `ProfilePage.jsx` — View/edit profile

### Step 10: Frontend — Admin Pages
**File**: `frontend/src/components/admin/ManageReferringPhysicians.jsx`
- List all referring physicians (pending/approved/rejected)
- Approve/reject/suspend actions
- Create new physician account

**File**: `frontend/src/components/admin/AdminDashboard.jsx`
- Add "Referring Physicians" to admin sidebar

### Step 11: Register Routes in App.jsx
**File**: `frontend/src/App.jsx`
- Add `/physician` routes for the portal
- Add `/me/admin/referring-physicians` for admin management

### Step 12: Register Backend Routes
**File**: `backend/app.js`
- Register `referring-physician.js` routes
- Register `admin-referring-physicians.js` routes

---

## Key Design Decisions

1. **Separate auth system** — Physicians have their own JWT scope (`physician`), separate from patients (`patient`) and staff. This keeps the portals isolated.

2. **Patient search** — Physicians search patients already registered at the facility. They can also register new patients (who then appear in the facility's patientrecords).

3. **Request source** — Lab requests from physicians use `source: 'doctor_referral'`. Radiology requests use the existing `referring_physician_id` column.

4. **Result viewing** — Physicians see results for patients they referred. The backend filters by `referring_physician_id`.

5. **Admin approval** — Self-registered physicians start as `pending`. Admins see a queue in the admin dashboard and can approve/reject.

6. **Email notifications** — Physicians receive emails when:
   - Account is approved
   - Lab results are authorised
   - Radiology report is finalised

---

## Files to Create (New)

| File | Purpose |
|---|---|
| `backend/migrations/...create-referring-physicians.js` | Database table |
| `backend/controller/referringPhysicianAuth.js` | Auth (register, login, profile) |
| `backend/controller/referringPhysicianRequests.js` | Request management |
| `backend/controller/adminReferringPhysicians.js` | Admin management |
| `backend/routes/referring-physician.js` | Physician API routes |
| `backend/routes/admin-referring-physicians.js` | Admin API routes |
| `backend/emails/referringPhysician/referringPhysician.js` | Email templates |
| `frontend/src/components/referring-physician/ReferringPhysicianApp.jsx` | Main portal app |
| `frontend/src/components/referring-physician/tokens.css` | Design tokens |
| `frontend/src/components/referring-physician/layout/PhysicianLayout.jsx` | Layout |
| `frontend/src/components/referring-physician/layout/DesktopSidebar.jsx` | Sidebar |
| `frontend/src/components/referring-physician/layout/BottomNav.jsx` | Bottom nav |
| `frontend/src/components/referring-physician/pages/LoginPage.jsx` | Login |
| `frontend/src/components/referring-physician/pages/RegisterPage.jsx` | Registration |
| `frontend/src/components/referring-physician/pages/HomePage.jsx` | Dashboard |
| `frontend/src/components/referring-physician/pages/NewLabRequest.jsx` | Create lab request |
| `frontend/src/components/referring-physician/pages/NewRadiologyRequest.jsx` | Create radiology request |
| `frontend/src/components/referring-physician/pages/LabRequestsPage.jsx` | Lab requests list |
| `frontend/src/components/referring-physician/pages/LabRequestDetailPage.jsx` | Lab request detail |
| `frontend/src/components/referring-physician/pages/RadiologyRequestsPage.jsx` | Radiology requests list |
| `frontend/src/components/referring-physician/pages/RadiologyRequestDetailPage.jsx` | Radiology request detail |
| `frontend/src/components/referring-physician/pages/PatientsPage.jsx` | Patient management |
| `frontend/src/components/referring-physician/pages/ProfilePage.jsx` | Profile |
| `frontend/src/components/admin/ManageReferringPhysicians.jsx` | Admin management page |

## Files to Modify (Existing)

| File | Change |
|---|---|
| `backend/app.js` | Register new routes |
| `backend/migrations/...newlab-requests.js` | Add `referring_physician_id` column |
| `backend/migrations/...radiology-requests.js` | Add `referring_physician_id` column |
| `frontend/src/App.jsx` | Add `/physician` routes |
| `frontend/src/components/admin/AdminDashboard.jsx` | Add sidebar link |
| `backend/controller/newlab-requests.js` | Filter by referring_physician_id |
| `backend/controller/radiology-requests.js` | Filter by referring_physician_id |

---

## Verification Plan

1. **Backend**: Run migration, verify table creation
2. **Auth**: Test self-registration → pending → admin approve → login flow
3. **Lab requests**: Create request → verify it appears in facility's lab module → verify results visible to physician
4. **Radiology requests**: Create request → verify it appears in facility's radiology module → verify report visible to physician
5. **Admin**: Test approve/reject/suspend flows
6. **Email**: Verify notification emails sent on approval and result ready
7. **Frontend**: Build passes, all pages render correctly
8. **Security**: Physician can only see their own requests and patients at their facility
