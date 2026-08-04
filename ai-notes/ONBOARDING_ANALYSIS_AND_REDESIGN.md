# Facility Onboarding — Analysis & Redesign

> Status: analysis + implementation complete. Covers both product paths: **Cloud (multi-tenant)** and **Offline (self-hosted Windows)**.
> Date: 2026-08-04

---

## 1. How the system currently onboards facilities

### 1.1 Cloud (online) — legacy flow

Entry points: `/signup` (chooser) → `/signup/hospital` → `hospital-reg.jsx`.

The old form fired **two uncoordinated API calls**:

1. `POST /hospitals/create` (`controller/hospitals.js` → `create`)
2. `POST /auth/sign-up` (`controller/users.js` → `create`)

**Problems found:**

| # | Issue | Where |
|---|-------|-------|
| 1 | **Broken facility row.** The controller reads `req.body.adminCode` for the hospital `id`, but the form never sends `adminCode` — so `Hospital.create({ id: undefined })` is attempted. The form does send `code` (prefix), but the controller reads `req.body.prefix`, so even the code lands in the wrong column (`req.body.prefix` is undefined). | `controller/hospitals.js:create` |
| 2 | **Admin user not linked to facility.** `sign-up` → `users.create` inserts the user without a `facilityId`, with default `status: 'pending'`, no role, and `must_change_password` unset. The new admin cannot even log in (`login` rejects non-`approved`/`active` accounts), and nothing ever approves them. | `controller/users.js:create`, `models/users.js` |
| 3 | **No transaction.** Two independent calls; a failure in the second leaves an orphaned facility row (or vice-versa). No rollback. | `hospital-reg.jsx:handleSubmit` |
| 4 | **No baseline data.** A new facility gets zero departments, zero services, no role assignment — the admin lands on an empty shell and has to hand-configure everything before first use. | — |
| 5 | **No onboarding state.** Nothing tracks whether a facility finished setup, which deployment it uses, or its contact info. | — |
| 6 | **Global `UNIQUE KEY name` on `departments`.** Facility B cannot create a department named "Pharmacy" if Facility A already has one — impossible to seed per-facility baseline data in a shared-schema tenant model. | `prime-db.sql:departments` |

### 1.2 Offline (self-hosted Windows)

- The installer (`postinstall.cmd`) imports `prime-db.sql`, which seeds a **single fixed facility UUID** (`1be0a9da-…`, "Amisal Dental Care") with a **fixed admin** `admin` / `123456`.
- Every offline install gets the same facility UUID and same default credentials — no facility profile setup, no unique identity, no forced password change.

**Problems:**

| # | Issue |
|---|-------|
| 1 | Every install is "the same facility" (same UUID + same admin). Security risk: default `admin/123456` credentials ship on every server. |
| 2 | No first-run wizard to claim/configure the local facility (name, type, admin credentials). |
| 3 | No `deployment_type` marker, so the platform can't tell offline installs apart from cloud tenants. |

---

## 2. Target flow (implemented)

A single **5-step wizard** (`FacilityOnboarding.jsx`) at `/onboarding` (also reachable at the legacy `/signup/hospital` routes), powering both paths: Deployment → Facility → Admin Account → **Branding (optional logo upload)** → Confirm.

```
Step 0  Deployment choice        ☁️ Cloud (hosted)   |   🖥️ Offline (self-hosted)
Step 1  Facility profile         name, type, prefix, address, hasStore
Step 2  Admin account            first/last name, email, phone, username, password
Step 3  Review & confirm         single atomic POST /onboarding/facility
```

### 2.1 Cloud path

One transactional call — `POST /onboarding/facility`:

1. **Validates** everything up front (facility name/type/prefix/address, admin name/email/username/password ≥ 6 chars).
2. Inside a **transaction**:
   - availability checks (username / email / prefix uniqueness),
   - creates the `hospitals` row with a fresh UUID, `deployment_type='cloud'`, `onboarding_status='complete'`, `contact_email/phone`, `app_url`,
   - creates the **admin user**: `status='approved'`, `role='admin'`, full `accessTo`/`functionality`, `must_change_password=1`, **linked to the facility**,
   - assigns the admin role in `user_roles` (granular permissions),
   - seeds **baseline departments** per facility type,
   - seeds **starter services** per facility type.
3. Rollback on any failure — no orphan rows.

The wizard then shows a success screen with the username/code and directs to login. First login forces a password change (`must_change_password`).

### 2.2 Offline path

- The wizard's **Offline** choice shows the download landing (installer link + 3-step install instructions + link to the offline guide) instead of a cloud account.
- After the installer runs, the local server is **claimed** via `PUT /onboarding/claim` (first-run wizard on the server):
  - verifies the current (default) admin credentials,
  - updates the facility profile (name/type/address/contact),
  - sets `deployment_type='offline'`, `onboarding_status='complete'`,
  - **replaces the default admin** with the client-chosen username/password (hashed) — eliminating the shared `admin/123456` risk.

### 2.3 Status endpoint

`GET /onboarding/status/:facilityId` returns deployment type, onboarding state and step — lets the UI decide between "show first-run wizard" and "go to app".

---

## 3. What changed

### Backend
- `controller/onboarding.js` — new (createFacility, claimFacility, checkPrefix, getStatus)
- `routes/onboarding.js` — new; mounted in `app.js`
- `models/hospital.js` — onboarding fields added to the model
- `migrations/20260804000001-add-onboarding-fields-to-hospitals.js` — new columns on `hospitals`
- `migrations/20260804000002-departments-facility-unique.js` — replaces global `UNIQUE(name)` on `departments` with `(facilityId, name)` (multi-tenant-safe)
- `migrations/20260804000003-users-unique-username-email.js` — defensive unique indexes on `users.username`/`users.email` (skips if legacy duplicate data exists)

### Frontend
- `components/auth/registration/FacilityOnboarding.jsx` — the 5-step wizard (Deployment, Facility, Admin, Branding/logo, Confirm) plus the `FacilityClaim` offline wizard
- `components/auth/registration/facilityOnboarding.css` — wizard styling
- `components/auth/registration/signUp.jsx` — chooser now routes to `/onboarding`
- `App.jsx` — `/signup/hospital|pharmacy|laboratory` and `/onboarding` → wizard

### DB columns added to `hospitals`
| Column | Type | Purpose |
|--------|------|---------|
| `deployment_type` | varchar(20) | `cloud` \| `offline` |
| `onboarding_status` | varchar(20) | `pending` \| `in_progress` \| `complete` |
| `onboarding_step` | int | last completed wizard step |
| `onboarding_completed_at` | datetime | when profile finalized |
| `contact_email` | varchar(255) | facility contact |
| `contact_phone` | varchar(50) | facility contact |

### `departments`
- `UNIQUE KEY name` → `UNIQUE KEY uq_departments_facility_name (facilityId, name)`

---

## 4. Running the migrations

```bash
cd backend
npm run db:migrate          # applies both new migrations
npm run db:migrate:status   # verify
```

For the **offline installer**: the new columns will be picked up the next time the bundle is rebuilt (prime-db.sql import + `postinstall` path is unchanged; the claim endpoint drives first-run setup). To ship the wizard to existing offline installs, either re-run the installer (data-preserving) or apply the migration on the client server.

---

## 5. Notes / future work

- The legacy `hospitals/create` + `sign-up` two-call flow is **left in place** (other screens may still reference it) but is no longer what the wizard uses.
- `hasStore` in the wizard flows through to the hospital row (1/0) as the old flow intended but never wired.
- **Security note:** `PUT /onboarding/claim` now requires the current (default) admin credentials unconditionally — every offline install ships the same seeded UUID, so a claim without proof of access would let anyone hijack the facility.
- **Prefix check:** the wizard uses `POST /onboarding/check-prefix` against `hospitals.code` — the legacy `/users/check/prefix` checks `users.prefix`, a different namespace.
- **Post-login redirect (wired):** `AuthenticatedContainer` calls `GET /onboarding/status/:facilityId` on mount and, if `onboarding_status` is present and not `'complete'`, redirects to `/onboarding/claim?facilityId=…`. It **fails open** — if the endpoint is unavailable (very old installs without the columns), access is not blocked. Existing facilities are backfilled to `'complete'`/`'cloud'` by migration 0001, so only fresh offline installs (marked `'pending'` by `postinstall.cmd`) trigger the redirect.
- **Offline claim wizard (wired):** `FacilityOnboarding.jsx` exports `FacilityClaim` at `/onboarding/claim`. It collects the facility profile + current (default) admin credentials + new credentials, calls `PUT /onboarding/claim`, clears any leftover default-admin session, and directs to login.
- **Installer migration gap (fixed):** `postinstall.cmd` previously only marked the baseline migration as applied and never ran the pending chain — offline installs were missing `hospitals.app_url` and every post-baseline column. It now runs `npx --no-install sequelize db:migrate` after writing `.env` (mirroring `backend/entrypoint.sh`), then marks the seeded facility `pending`/`offline` (guarded so reinstall never resets a claimed facility). `sequelize-cli` was already in `dependencies`, so it ships in the offline bundle.
- **`must_change_password` note:** the cloud admin is created with `must_change_password=1`, but the current frontend login doesn't yet redirect on that flag — the wizard's success screen no longer promises it. Wiring that redirect is future work.
- **Facility logo (wired):** the Branding step (cloud wizard) and the claim wizard both collect an optional logo and upload it via the existing `POST /facility/logo/upload` (FormData `image` + `id`) right after the facility is created/claimed. Upload failure is **non-fatal** — the user can add it later from Settings. **Offline uploads now work fully:** the route picks Cloudinary when `CLOUD_NAME`/`API_KEY`/`API_SECRET` env vars are set (cloud deployment, docker-compose) and otherwise saves to `backend/public/logos` via multer disk storage, served through the existing `/public` static mount; the controller stores a URL-safe `/public/logos/<filename>` (never the absolute server path), and `ensureDirectories` creates the folder at boot.
- **Facility list shows deployment & onboarding (wired):** the admin dashboard (`ManageFacilities.jsx`, `GET /hospitals`) now renders **Deployment** (☁️ Cloud / 🖥️ Offline / —) and **Onboarding** (Complete / In progress / Pending / —) badges. Requires **migration 0001** to be applied on the DB — `findAll` selects `deployment_type`/`onboarding_status`, so a DB that never ran it will error (MySQL 1054). The cloud path migrates on deploy; the offline installer runs `db:migrate`; apply `cd backend && npm run db:migrate` on any DB that predates both.
