# MMI Implementation Plan

## Current State Assessment

### Already Implemented ✅
- **All 10 backend service modules** (orchestrator, medication history, interaction, allergy, duplicate therapy, contraindication, dose validation, pregnancy, clinical rules, antimicrobial, adverse events)
- **25+ API endpoints** in `backend/routes/mmi.js` + `backend/controller/mmi.js`
- **14 MMI database tables** created via migration `20260702000001-mmi-schema.js`
- **Frontend MMI module** with 5 pages (Dashboard, Medication History, Allergy Profile, Interaction Analysis, Dose Check)
- **Prescription guard** integrated into the prescribing workflow (`prescriptionGuard.js`)
- **Alert/override audit logging** (mmi_alert_logs, mmi_override_logs tables)
- **Basic seed data** (33 drug classes, 15 interactions, 9 contraindications, 5 antimicrobial rules, 16 allergy mappings)

### Gaps to Implement

#### Critical Gaps
1. **Knowledge base empty** — `mmi_drugs`, `mmi_renal_rules`, `mmi_hepatic_rules`, `mmi_pregnancy_rules` have zero seed data; interactions/contraindications are minimal
2. **Redis cache layer** — PRD specifies Redis; not in dependencies or code
3. **BullMQ queue processing** — PRD specifies BullMQ; not in dependencies or code
4. **Offline capability** — PRD requires 100% offline availability; no local-first strategy exists
5. **No drug-specific dosing rules** — Dose validation is class-level only

#### Important Gaps
6. **No MMI-specific permissions/RBAC** — No granular MMI permissions defined
7. **No clinical knowledge package update mechanism**
8. **No testing infrastructure** — No tests for any MMI module
9. **HL7 FHIR not integrated** — `node-hl7` in deps but unused
10. **No performance SLA monitoring** — No <500ms enforcement

#### Enhancement Gaps
11. **Frontend missing pages** — No pages for: Contraindication Check, Clinical Rules Builder, Antimicrobial Stewardship dashboard, Adverse Event Management
12. **No MMI reporting/analytics**
13. **No AI-assisted intelligence** (Phase 2 per PRD)

---

## Implementation Phases

### Phase 1: Knowledge Base Population (Foundation)

| # | Task | Files | Effort |
|---|------|-------|--------|
| 1.1 | Seed `mmi_drugs` with 200+ essential medications (generic + brand names, ATC codes, drug classes, routes, half-lives) | `backend/migrations/20260702000001-mmi-schema.js` (or new seed migration) | 3-4h |
| 1.2 | Seed `mmi_renal_rules` for nephrotoxic/renally-cleared drugs (eGFR thresholds, dose adjustments per CKD stage) | New seed migration | 2h |
| 1.3 | Seed `mmi_hepatic_rules` for hepatically-metabolized drugs (Child-Pugh A/B/C adjustments) | New seed migration | 2h |
| 1.4 | Seed `mmi_pregnancy_rules` with FDA pregnancy categories A-X + lactation safety for key drugs | New seed migration | 2h |
| 1.5 | Expand `mmi_drug_interactions` seed data to 100+ clinically significant pairs | New seed migration | 3h |
| 1.6 | Expand `mmi_contraindications` seed data (disease-based, organ dysfunction, special populations) | New seed migration | 2h |
| 1.7 | Expand `mmi_drug_classes` with more granular subclasses (fluoroquinolones, TCAs, SSRIs, etc.) | Seed migration update | 1h |
| 1.8 | Add CSV/JSON import utility for bulk drug data loading from standardized sources | `backend/scripts/import-mmi-data.js` | 2h |

**Total Phase 1: ~17-19h**

---

### Phase 2: Performance & Infrastructure

| # | Task | Files | Effort |
|---|------|-------|--------|
| 2.1 | Install and configure Redis (`ioredis`) for caching drug lookups, interaction results, patient context | `backend/package.json`, `backend/config/redis.js` | 2h |
| 2.2 | Create cache service layer for MMI (TTL-based cache for drug data, interaction results, patient profiles) | `backend/services/mmi/cacheService.js` | 3h |
| 2.3 | Integrate cache into orchestratorService — cache drug class resolution, patient data fetches | `backend/services/mmi/orchestratorService.js` | 2h |
| 2.4 | Install and configure BullMQ with Redis for async job processing | `backend/package.json`, `backend/config/queue.js` | 2h |
| 2.5 | Create queue workers for heavy analysis tasks (batch interaction checks, medication reconciliation) | `backend/services/mmi/queueWorker.js` | 3h |
| 2.6 | Add performance monitoring middleware — track analysis time per engine, log SLA violations | `backend/services/mmi/performanceMonitor.js` | 2h |
| 2.7 | Optimize database queries — add indexes on frequently queried columns in MMI tables | Migration for indexes | 1h |

**Total Phase 2: ~15h**

---

### Phase 3: Security & Permissions

| # | Task | Files | Effort |
|---|------|-------|--------|
| 3.1 | Define MMI-specific permissions in the permissions system (mmi.view, mmi.analyze, mmi.override_critical, mmi.manage_rules, mmi.manage_antimicrobial, mmi.view_audit) | `backend/middleware/permissions.js` or migration | 2h |
| 3.2 | Create MMI permission middleware — granular check per endpoint | `backend/middleware/mmiPermissions.js` | 1h |
| 3.3 | Apply permission checks to all MMI routes (different levels for physicians, pharmacists, clinical pharmacologists, admin) | `backend/routes/mmi.js` | 2h |
| 3.4 | Add MMI permission seeding to default roles | Role seed migration | 1h |
| 3.5 | Audit trail enhancement — log permission failures, add user context to all alert logs | `backend/services/mmi/orchestratorService.js`, `backend/controller/mmi.js` | 2h |

**Total Phase 3: ~8h**

---

### Phase 4: Offline Strategy

| # | Task | Files | Effort |
|---|------|-------|--------|
| 4.1 | Implement SQLite-based local drug database for offline reference data | `backend/services/mmi/offlineService.js` | 4h |
| 4.2 | Create offline sync mechanism — detect connectivity, sync knowledge base updates when online | `backend/services/mmi/syncService.js` | 4h |
| 4.3 | Add knowledge package versioning and distribution endpoint | `backend/routes/mmi.js`, `backend/controller/mmi.js` | 2h |
| 4.4 | Cache key MMI data (drugs, interactions, contraindications) in IndexedDB/PouchDB on frontend for offline prescribing | `frontend/src/services/mmiOffline.js` | 4h |
| 4.5 | Build update strategy — periodic check for new knowledge packages, delta updates | `backend/scripts/build-knowledge-package.js` | 3h |

**Total Phase 4: ~17h**

---

### Phase 5: Frontend Expansion

| # | Task | Files | Effort |
|---|------|-------|--------|
| 5.1 | Build Contraindication Check page — display patient condition-based contraindications with severity | `frontend/src/components/mmi/ContraindicationCheck.jsx` | 3h |
| 5.2 | Build Clinical Rules Builder UI — create/edit/activate/deactivate facility-specific rules | `frontend/src/components/mmi/ClinicalRulesBuilder.jsx` | 4h |
| 5.3 | Build Antimicrobial Stewardship Dashboard — therapy duration tracking, AWaRe classification, culture/consult compliance | `frontend/src/components/mmi/AntimicrobialDashboard.jsx` | 4h |
| 5.4 | Build Adverse Event Management page — record, list, filter, update status of ADEs | `frontend/src/components/mmi/AdverseEventManager.jsx` | 3h |
| 5.5 | Build Prescribing Safety Workflow UI — real-time analysis results display within the prescription form | `frontend/src/components/mmi/PrescribingSafetyPanel.jsx` | 4h |
| 5.6 | Build Audit Trail Viewer — searchable alert logs, override logs, compliance dashboard | `frontend/src/components/mmi/AuditTrailViewer.jsx` | 3h |
| 5.7 | Update MMIRouter to include new pages | `frontend/src/components/mmi/MMIRouter.jsx` | 1h |
| 5.8 | Add Redux state for new pages | `frontend/src/redux/actions/mmi.js`, new reducers | 2h |

**Total Phase 5: ~24h**

---

### Phase 6: Testing & Hardening

| # | Task | Files | Effort |
|---|------|-------|--------|
| 6.1 | Set up test framework (Jest + Supertest) and test database config | `backend/package.json`, `backend/jest.config.js` | 2h |
| 6.2 | Unit tests: interaction service, allergy service, contraindication engine, dose validation, duplicate therapy | `backend/tests/mmi/` | 6h |
| 6.3 | Integration tests: orchestrator end-to-end, prescription guard, alert/override pipeline | `backend/tests/mmi/` | 4h |
| 6.4 | API tests: all MMI endpoints (happy path + error cases) | `backend/tests/mmi/api.test.js` | 4h |
| 6.5 | Frontend component tests for MMI pages (Jest + React Testing Library) | `frontend/src/components/mmi/__tests__/` | 4h |
| 6.6 | Load test — simulate 100 concurrent prescription analyses, verify <500ms SLA | `backend/tests/load/mmi-load.js` | 2h |
| 6.7 | Security audit — SQL injection checks in raw queries, XSS in alert display, RBAC enforcement | Manual review | 3h |

**Total Phase 6: ~25h**

---

### Phase 7: Knowledge Package Distribution

| # | Task | Files | Effort |
|---|------|-------|--------|
| 7.1 | Build clinical knowledge package builder CLI script | `backend/scripts/build-knowledge-package.js` | 3h |
| 7.2 | Create version manifest and changelog tracking | `backend/services/mmi/knowledgeBaseService.js` | 2h |
| 7.3 | Add facility-level knowledge package version tracking | Migration + service | 2h |
| 7.4 | Build auto-update check endpoint and background job | `backend/services/mmi/updateChecker.js` + cron job | 2h |

**Total Phase 7: ~9h**

---

### Phase 8: HL7 FHIR Readiness (Optional)

| # | Task | Files | Effort |
|---|------|-------|--------|
| 8.1 | Implement FHIR MedicationRequest resource mapping | `backend/services/mmi/fhirMapping.js` | 4h |
| 8.2 | Implement FHIR AllergyIntolerance, Condition, Observation resource consumption | `backend/services/mmi/fhirPatientService.js` | 4h |
| 8.3 | Add FHIR-compatible export for alert logs and override records | `backend/services/mmi/fhirExport.js` | 3h |

**Total Phase 8: ~11h**

---

### Phase 9: AI-Assisted Intelligence (Phase 2 / Future)

| # | Task | Files | Effort |
|---|------|-------|--------|
| 9.1 | NLP-based alternative medication recommendation | New service | 8h |
| 9.2 | Clinical risk summarization model | New service | 8h |
| 9.3 | Therapy optimization suggestions | New service | 6h |
| 9.4 | AI advisory overlay (never replaces deterministic rules — per PRD) | Orchestrator integration | 4h |

**Total Phase 9: ~26h (deferred)**

---

## Summary

| Phase | Focus | Effort | Priority |
|-------|-------|--------|----------|
| 1 | Knowledge Base Population | 17-19h | **P0 — Must have** |
| 2 | Performance & Infrastructure | 15h | **P0 — Must have** |
| 3 | Security & Permissions | 8h | **P1 — Should have** |
| 4 | Offline Strategy | 17h | **P1 — Should have** |
| 5 | Frontend Expansion | 24h | P2 — Nice to have |
| 6 | Testing & Hardening | 25h | **P1 — Should have** |
| 7 | Knowledge Package Distribution | 9h | P2 — Nice to have |
| 8 | HL7 FHIR Readiness | 11h | P3 — Future |
| 9 | AI-Assisted Intelligence | 26h | P4 — Phase 2 |
| | **Total** | **~152h** | |

## Recommended Start Order

1. **Phase 1 (Knowledge Base)** — Without data, the entire system returns empty results. This is the #1 blocker.
2. **Phase 2 (Redis + BullMQ)** — Required for production-level performance and async processing. Many interactions can be slow at scale.
3. **Phase 3 (Permissions)** — Critical for clinical safety. Need to ensure only authorized roles can override critical alerts.
4. **Phase 6 (Tests)** — Need tests before further development to prevent regression.
5. **Phase 4 (Offline)** — Important for the African healthcare context where connectivity is unreliable.
6. **Phases 5, 7, 8, 9** — In parallel or deferred depending on business priorities.
