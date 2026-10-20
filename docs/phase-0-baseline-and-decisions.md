# Phase 0 — Baseline, Product Decisions and Safety Net

**Status:** Codebase baseline recorded; live-environment discovery and client/product decisions remain open.  
**Related documents:** [Implementation plan](client-platform-implementation-plan.md), [platform audit](client-platform-demo-audit.md).  
**Repository inspection date:** 1 October 2026.

Phase 0 is a discovery/safety-net phase. It does not change production workflows, facility defaults, schema, permissions, notification behavior, or plan entitlements.

## 1. Repository baseline (verified from source)

### Facility types and module availability

The registry in [facilityTypes.js](../backend/config/facilityTypes.js) currently defines seven types: `hospital`, `clinic`, `pharmacy`, `laboratory`, `diagnosticCenter`, `dentalClinic`, and `maternityClinic`.

| Type | Registry baseline relevant to this work | Planning note |
|---|---|---|
| `hospital` | Includes Laboratory and Radiology modules; multi-specialty module expansion is supported. | New capabilities should be opt-in through Settings, without changing current hospital behavior by default. |
| `laboratory` | Includes Laboratory and Accounts; `labModule: 'newlab'`. | Target facility type. Current new-lab UI is selected by registry/plan context. |
| `diagnosticCenter` | Includes Laboratory and Radiology; `labModule: 'newlab'`. | Target facility type for relevant lab/radiology capabilities. |
| `clinic` | Uses base modules plus selected specialties. Laboratory/Radiology are specialty-dependent. | Do not show capability settings when the needed module is absent. |
| `maternityClinic` | Registry includes Laboratory and Radiology modules. | Other facility type: preserve behavior unless eligible admin opts in and plan/module requirements are met. |
| `dentalClinic` | Registry includes Radiology, not Laboratory. | Do not expose lab-specific features without the Laboratory module. |
| `pharmacy` | Registry excludes Laboratory and Radiology. | Do not expose clinical diagnostic capability settings. |

`hospital.type` normalization is already handled by [facility-type migration](../backend/migrations/20260806000001-normalize-facility-types.js). It lists accepted types through `dentalClinic`, while the application registry also contains `maternityClinic`; this is a baseline discrepancy to verify with deployment/schema owners **before modifying facility-type validation**. Do not add type aliases or run broad recategorization as part of Phase 0.

The current module/plan feature catalog has entries for `quality_control`, `analyzer_integration`, `lab_barcodes`, `pacs`, `tele_radiology`, and `audit_trail` in [moduleFeatures.js](../backend/config/moduleFeatures.js), and plan matrices in [featureMatrix.js](../backend/config/featureMatrix.js). These are plan-level product flags, not an existing per-facility operational settings system. Phase 1 must not conflate plan entitlements with the capability switches.

### Existing settings store

[Migration 20260804000009](../backend/migrations/20260804000009-facility-settings.js) creates the per-facility key/value table. [Migration 20260815000001](../backend/migrations/20260815000001-facility-settings-unique.js) adds a unique facility/key constraint after deduplication. Existing settings use `facilityId`, `setting_key`, `setting_value`, `updated_by`, `updated_at`; missing keys commonly imply a default. This is a plausible additive persistence surface for Phase 1, but the actual production schema, migration status, and uniqueness must be checked before relying on it.

### Laboratory/radiology baseline

- New-lab routes for requests, specimens, results, QC, instruments and settings are mounted from [app.js](../backend/app.js); lab is currently selected by plan/module context and facility registry.
- New-lab request/specimen/result tables and critical flags are described in [newlab_schema.sql](../backend/sql/newlab_schema.sql). An instrument registry/calibration log is in [newlab_instruments.sql](../backend/sql/newlab_instruments.sql). These SQL files alone do not prove every production database has them installed.
- Existing backend integration tests include new-lab write flow, results gates, result flags, amendments, reports and dashboard tests under `backend/tests/network/`; these are useful regression foundations. They do not substitute for device/hardware acceptance.
- Radiology has route and schema surfaces for requests, appointments, exams, reports, billing, DICOM and worklists. Actual PACS/Orthanc/modality configuration is deployment-specific and not verified by this baseline.

### Permission and audit baseline

- [permissions.js](../backend/middleware/permissions.js) currently has an unconditional `next()` at the beginning of `checkPermission`; its database checks below are unreachable. This is a known P0 issue for Phase 2, **not a Phase 0 fix**.
- New-lab routes call `checkPermission` but mostly do not use an explicit `requireFacilityScope` middleware. Controllers perform some facility checks, not necessarily uniformly across every route.
- Radiology route files checked mostly apply `authenticate`, without granular `checkPermission`/facility-scope enforcement. A complete endpoint inventory is still required in Phase 2.
- Inventory router applies the generic `auditLog()` middleware, while the audited lab/radiology routers do not show equivalent global audit logging. Result versions and some actor/time fields exist, but this is not a comprehensive audit baseline.

### Test/config conventions

Backend uses CommonJS, Mocha, Chai/Node assertions, and has pure config tests under `backend/tests/mmi/config/`. Added [facilityTypesPhase0Baseline.test.js](../backend/tests/mmi/config/facilityTypesPhase0Baseline.test.js) as a behavior-neutral snapshot of present registry facts. It deliberately does not encode future capability defaults.

## 2. Behavior-preservation matrix for subsequent phases

This matrix records the agreed rollout intent, not implemented behavior:

| Facility cohort | Phase 0 baseline | Intended default after capability rollout |
|---|---|---|
| Laboratory | New lab module currently selected by registry. | Applicable new lab capabilities enabled by default, except hardware/external channels until configured. |
| Diagnostic Center | New lab + Radiology in registry. | Applicable lab and radiology capabilities enabled by default, except hardware/external channels until configured. |
| Hospital | Laboratory + Radiology modules available; current settings/behavior remain as-is. | Optional capabilities stay off/current by default; authorized facility admin opts in via Settings. Mandatory authorization/tenant security fixes apply regardless of toggles. |
| Clinic | Module set varies by selected specialty. | Current behavior preserved; offer only a capability whose owning module is present and plan allows it. |
| Maternity Clinic | Laboratory + Radiology currently in registry. | Current behavior preserved; optional capability settings only when module/plan requirements pass. |
| Dental Clinic | Radiology available; no Laboratory module in current registry. | No lab capability settings unless the facility’s allowed modules are explicitly changed through normal plan/module processes. |
| Pharmacy | No Laboratory or Radiology in registry. | No diagnostic capability settings. |
| Unknown/legacy values | Need database and deployment inventory; migration indicates canonical values but appears inconsistent for maternityClinic. | No new optional capability until type is safely resolved; do not mutate records automatically. |

## 3. Required live-environment discovery (operator-owned)

These facts cannot be established safely from repository source; record the evidence/date/owner in the deployment inventory before Phase 1:

- [ ] Count and export a **metadata-only** inventory of facility IDs, canonical `hospitals.type`, active status, enabled modules and subscription product/tier. Protect the export as operational data; do not attach patient data.
- [ ] Identify historical type aliases/casing, especially `maternityClinic`, `factory`, null/unknown values and any types not in the current migration list. Propose mappings; do not run an update in Phase 0.
- [ ] For each in-scope facility, record new vs legacy lab module, current lab workflow mode, whether Laboratory/Radiology is enabled by plan, and whether any site depends on older routes or custom code.
- [ ] Check applied migration fingerprint/status per environment; specifically facility_settings table/unique key, new-lab tables/views/functions, instrument tables, radiology schema/worklist tables, permissions tables and version of MySQL/MariaDB. Do not infer installed schema from SQL source files.
- [ ] Confirm roles in active use, actual permission/catalog tables and grants, super-admin mechanism, custom roles, direct user overrides/expiry and route/API callers. Export role names/permission counts only, not users’ secrets or PHI.
- [ ] Confirm audit log tables, retention/backup, configured audit viewers and which routes currently write audit records. This requires a reviewed read-only query or approved admin UI; do not run production migrations or scripts for discovery.
- [ ] Confirm data hosting, TLS/reverse proxy, secret source/rotation ownership, DICOM/PACS/Orthanc topology, uploads/storage access policy, backup schedule and most recent restore evidence with the deployment/security owner.
- [ ] Identify demo/training facility IDs and confirm all records are fictional/synthetic. Do not seed or modify production data during Phase 0.

## 4. Product and clinical decisions needed

Assign a named decision-maker and record the chosen value before implementation begins:

| Decision | Options/questions to resolve | Needed for |
|---|---|---|
| Module target | Is new lab the standard for new installations only, or should any existing laboratory/diagnostic facility migrate from legacy? What facility exceptions must remain legacy? | Phases 1, 3, 4, 5 |
| Capability meaning | Separate user-facing toggle for each: lab barcode workflow, critical alerts, QC release gate, analyser interface, PACS/worklist, enhanced audit views? Which should be combined or omitted? | Phase 1 |
| Plan entitlement | Which flags/tiers are prerequisites for each capability? Does the setting only configure an already-entitled feature? What should an admin see when their plan lacks it? | Phases 1, 6, 8 |
| Hospital safety defaults | Which hospital capabilities remain off by default, and who can enable each one? Confirm no setting can disable core security controls. | Phase 1 onward |
| Lab barcode | **Approved (2026-10-01):** new-lab only; one opaque generated identifier per individual test/panel; Code 128; identifiers must be unique and reprints reuse the saved identifier; label fields configurable in Lab Settings (barcode always shown; test/panel, specimen and order date enabled by default); 40×25 mm default with 50×30 mm alternate; anyone with print-page access may print; issue at order creation; USB barcode printer/scanner. Printer/scanner driver and physical-label validation remain deployment acceptance tests. | Phase 3 |
| Critical result | What constitutes critical; who is notified; in-app/email/SMS/push/phone; escalation deadlines; acknowledgment role; downtime/failure policy; result content permitted per channel. | Phase 4 |
| QC policy | Required control rules, statistical standard (if any), when a failed QC blocks results, override role/reason, and scope of affected tests/instruments. | Phase 5 |
| Analyser | Vendor/model/firmware; ASTM/HL7/vendor protocol; interface engine/connector; orders/results direction; codes/units; throughput; support agreement and test simulator. | Phase 6 |
| Radiology/PACS | PACS/Orthanc product/version; DICOM worklist/image protocol; network/VPN/IP/AE titles; external party owner; retention/viewer/security requirements; callback authentication. | Phase 8 |
| Audit/compliance | Applicable local legal/accreditation requirements; retention; access log vs clinical change log; export format; tamper-evidence expectations; data residency. | Phase 7 |
| Commercial operations | Client training audience/schedule, support channel/hours/SLA, ownership of device integration, hosting model and written quote/inclusions. | Phase 9 |

## 5. Safe synthetic test matrix and evidence packet

Create isolated test tenants or fixtures; never use production patients. For each fixture save the facility type, selected modules, plan tier, expected lab module, current config/migration fingerprint and pass/fail outputs. Keep secrets and patient-like content out of screenshots/logs.

- [ ] `laboratory`, with Laboratory module and `labModule = newlab`.
- [ ] `diagnosticCenter`, with Laboratory and Radiology modules and `labModule = newlab`.
- [ ] `hospital`, with both modules, including one hospital with a standard existing setup and one with opted-in specialty modules if available.
- [ ] `clinic` with no specialty; `clinic` with `general_practice`; `clinic` with `radiology_diagnostic`.
- [ ] `maternityClinic`, `dentalClinic`, and `pharmacy` as negative-gating controls.
- [ ] Unknown facility type and legacy type alias as fail-safe resolver controls; no data rewrite.

For each, record module/plan settings, which settings should be visible, default effective capabilities, whether APIs reject unavailable modules, and that no data or existing route behavior changes in this discovery phase. The fixture must assert the **current baseline only** until the product decisions above are approved.

## 6. Phase 0 work performed in this checkout

- Added a pure config baseline test at [facilityTypesPhase0Baseline.test.js](../backend/tests/mmi/config/facilityTypesPhase0Baseline.test.js). It pins registry types, target modules, hospital modules, specialty-dependent clinic modules, pharmacy exclusion and module deduplication.
- No migration, settings UI/API, permission enforcement, notification behavior, facility default, plan entitlement, or workflow code was changed.
- Full database inventory, production migration/schema verification, hardware tests and non-barcode business decisions are not possible from this local repository alone and remain operator/stakeholder tasks above.
- Product decision recorded for Phase 3 barcode work: new-lab only, Code 128 opaque per-test/panel IDs, uniqueness with stable reprints, issue at order creation, configurable label content, two size presets, and USB-connected printer/scanner support.

## 7. Exit criteria

Phase 0 is fully complete when all are checked and evidence is attached to the project tracking item:

- [ ] Production/staging facility-type/module/plan/migration inventory reviewed by deployment owner.
- [ ] Historical type discrepancy (including `maternityClinic`) resolved through an approved compatibility decision; no speculative conversion.
- [ ] New vs legacy lab target and exceptions approved.
- [ ] Capability-to-module-to-plan matrix and facility-type defaults approved by product owner.
- [ ] Client/clinical answers recorded for critical alerts, barcode labels, QC policy, analyser and PACS requirements.
- [ ] Synthetic facility fixtures exist for target, configurable and negative-gating cohorts.
- [ ] Baseline test command and results attached; any unrelated pre-existing failures clearly identified.
- [ ] Security, training/support and commercial owners named.

**Gate to Phase 1:** Do not add settings keys or default logic until the module/plan/capability ownership and hospital opt-in model are approved. **Gate to Phase 2:** Authorization fixes are a priority safety/security task and should not wait for hardware or pricing decisions; first identify active role grants and establish representative acceptance tests so enforcement does not lock out legitimate existing workflows.
