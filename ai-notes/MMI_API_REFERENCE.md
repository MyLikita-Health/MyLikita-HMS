# MMI API Reference — All 33 Endpoints

**Base path:** `/mmi`  
**Auth:** JWT via `authenticate` middleware (all endpoints)  
**Error format:** `400` → `{ success: false, error: "message" }`, `500` → `{ success: false, error: "message" }`

---

## Medication History (5)

### `GET /mmi/patients/:patientId/medications/active?facilityId=`

**Response 200:**
```json
{
  "success": true,
  "data": [
    { "id": 1, "drug": "Ibuprofen", "dosage": "400mg", "frequency": "TDS",
      "route": "oral", "status": "active", "startTime": "2026-01-01",
      "end_date": null, "created_at": "ISO", "patient_id": "4-1", "facilityId": "..." }
  ],
  "count": 1
}
```

### `GET /mmi/patients/:patientId/medications/historical?facilityId=&limit=50`

**Response 200:** Same shape as active, with `status` ≠ `"active"`.

### `GET /mmi/patients/:patientId/medications/timeline?facilityId=`

**Response 200:**
```json
{
  "success": true,
  "data": [
    { "date": "2026-01-15", "event_type": "started|stopped|changed",
      "drug": "Amoxicillin", "detail": "Started 500mg TDS", "created_at": "ISO" }
  ],
  "count": 1
}
```

### `POST /mmi/patients/:patientId/medications/reconcile`

**Request:**
```json
{ "facilityId": "...", "newlyPrescribed": ["Amoxicillin", "Ibuprofen"] }
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "current_medications": [/* active meds array */],
    "newly_prescribed": ["Amoxicillin", "Ibuprofen"],
    "reconciliation": {
      "duplicates": [{ "name": "Ibuprofen", "class_name": "NSAIDs", "severity": "moderate" }],
      "restarted": [{ "name": "Amoxicillin", "class_name": "Penicillins" }],
      "missing_continuations": []
    }
  }
}
```

### `GET /mmi/patients/:patientId/medications/summary?facilityId=`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "patient_id": "4-1",
    "summary": "Patient has 3 active medications...",
    "active_medications": [], "historical_medications": [], "timeline": []
  }
}
```

---

## Drug Interactions (2)

### `POST /mmi/interactions/check`

**Request:**
```json
{ "prescribedDrugs": ["Ciprofloxacin", "Diclofenac"], "drugClassIds": [22, 2] }
```

**Response 200:**
```json
{
  "success": true,
  "data": [{
    "alert_type": "drug_interaction",
    "severity": "critical|major|moderate|minor",
    "severity_config": { "level": 4, "label": "Critical",
      "color": "red", "blocks_prescription": true },
    "title": "Ciprofloxacin + Diclofenac",
    "message": "Increased risk of CNS effects including seizures",
    "recommendation": "Consider alternative antibiotic or analgesic",
    "drug_a": "Ciprofloxacin", "drug_b": "Diclofenac",
    "interaction_type": "CNS effects", "severity_label": "Critical"
  }],
  "count": 1
}
```

### `POST /mmi/interactions/check-drug`

**Request:** `{ "drugName": "Ciprofloxacin", "drugClassIds": [22] }`  
**Response 200:** Same alert array shape.

---

## Allergies (3)

### `GET /mmi/patients/:patientId/allergies?facilityId=`

**Response 200:**
```json
{
  "success": true,
  "data": [
    { "id": 1, "patient_id": "4-1", "allergen_name": "Penicillin",
      "severity": "moderate", "reaction_type": "Rash", "notes": "Hives",
      "created_at": "ISO", "facilityId": "..." }
  ],
  "count": 1
}
```

### `POST /mmi/patients/:patientId/allergies`

**Request:** `{ "facilityId": "...", "allergen": "Penicillin", "severity": "moderate", "reaction": "Rash", "notes": "..." }`  
**Response 201:** `{ "success": true, "data": { /* created record */ }, "message": "Allergy recorded successfully" }`

### `POST /mmi/allergies/check`

**Request:** `{ "patientId": "4-1", "facilityId": "...", "prescribedDrugs": ["Amoxicillin"], "drugClassIds": [20] }`  
**Response 200:** Alert array with `"alert_type": "allergy"`.

---

## Duplicate Therapy (2)

### `POST /mmi/duplicate-therapy/check`

**Request:** `{ "prescribedDrugs": ["Ibuprofen","Diclofenac"], "currentMedicationInfo": [{ "name":"Naproxen","classId":2 }] }`  
**Response 200:** Alert array with `"alert_type": "duplicate_therapy"`.

### `POST /mmi/duplicate-therapy/check-drug`

**Request:** `{ "drugName": "Ibuprofen", "drugClassId": 2, "currentMeds": ["Naproxen"] }`  
**Response 200:** Same alert array shape.

---

## Contraindications (1)

### `POST /mmi/contraindications/check`

**Request:**
```json
{
  "clinicalContext": { "conditions": ["heart failure"], "egfr": "25",
    "childPugh": "B", "isPregnant": false, "isLactating": false },
  "prescribedDrugs": ["Ibuprofen"], "drugClassIds": [2]
}
```

**Response 200:** Alert array with `"alert_type": "contraindication"`, potentially `severity_config.blocks_prescription: true`.

---

## Dose Validation (2)

### `POST /mmi/dose/validate`

**Request:**
```json
{ "drugName": "Ibuprofen", "prescribedDose": 800, "unit": "mg",
  "patientAge": 45, "patientWeight": 70, "egfr": 60, "childPugh": "B",
  "isPediatric": false, "isGeriatric": false }
```

**Response 200:**
```json
{
  "success": true,
  "data": [{
    "alert_type": "dose_validation", "severity": "major",
    "title": "Dose exceeds maximum", "message": "...", "recommendation": "...",
    "prescribed_dose": 800, "unit": "mg", "max_dose": 400, "min_dose": 200,
    "dose_check_type": "max_exceeded|subtherapeutic|renal_adjustment|hepatic_adjustment|weight_based"
  }],
  "count": 1
}
```

### `POST /mmi/dose/info`

**Request:** `{ "drugName": "Ibuprofen", "drugClassId": 2, "patientAge": 45, "patientWeight": 70, "egfr": 60, "childPugh": "B" }`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "has_renal_rules": true,
    "renal_rules": [{ "egfr_min": 30, "egfr_max": 60, "adjustment": "Reduce dose by 50%", "max_dose": 400 }],
    "has_hepatic_rules": false,
    "hepatic_rules": []
  }
}
```

---

## Pregnancy & Lactation (1)

### `POST /mmi/pregnancy/check`

**Request:** `{ "prescribedDrugInfo": [{ "name":"Ibuprofen","dose":400,"unit":"mg" }], "clinicalContext": { "isPregnant":true,"isLactating":false } }`  
**Response 200:** Alert array with `"alert_type": "pregnancy_safety"`.

---

## Clinical Rules (4)

### `GET /mmi/rules/:facilityId`

**Response 200:**
```json
{
  "success": true,
  "data": [
    { "id": 1, "facilityId": "...", "rule_name": "Avoid NSAIDs in CKD",
      "rule_description": "Do not prescribe NSAIDs if eGFR < 30",
      "rule_type": "contraindication", "rule_scope": "facility",
      "condition": "egfr < 30", "action": "block", "priority": "critical",
      "is_active": true, "created_at": "ISO" }
  ],
  "count": 1
}
```

### `POST /mmi/rules`

**Request:** `{ "facilityId": "...", "rule_name": "...", "rule_description": "...", "rule_type": "contraindication", "rule_scope": "facility", "condition": "egfr < 30", "action": "block", "priority": "critical", "is_active": true }`  
**Response 201:** `{ "success": true, "data": {}, "message": "Clinical rule created successfully" }`

### `PUT /mmi/rules/:ruleId`

**Request body:** Any subset of rule fields.  
**Response 200:** `{ "success": true, "data": {}, "message": "Clinical rule updated successfully" }`

### `POST /mmi/rules/evaluate`

**Request:** `{ "facilityId": "...", "prescription": { "drugNames": ["Ceftriaxone"], "drugClassIds": [21], "condition": "UTI", "doctorRole": "registrar", "hasCulture": true } }`  
**Response 200:** `{ "success": true, "data": [/* alerts */], "count": number }`

---

## Antimicrobial Stewardship (2)

### `POST /mmi/antimicrobial/check`

**Request:**
```json
{
  "prescribedDrugInfo": [{ "name": "Ceftriaxone", "classId": 21 }],
  "options": { "durationDays": 7, "hasCulture": false, "hasConsult": false, "doctorRole": "registrar" }
}
```

**Response 200:** Alert array with `"alert_type": "antimicrobial"`, includes `aware_category: "Watch|Reserve|Access"`, `requires_culture`, `requires_consult`.

### `POST /mmi/antimicrobial/therapy-duration`

**Request:** `{ "drugName":"Ceftriaxone","drugClassId":21,"startDate":"2026-06-01","currentDate":"2026-06-07" }`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "drug_name": "Ceftriaxone", "days_of_therapy": 6,
    "recommended_duration": 7, "days_remaining": 1,
    "status": "active|completed|exceeded"
  }
}
```

---

## Adverse Drug Events (4)

### `POST /mmi/adverse-events`

**Request:** `{ "patient_id":"4-1","facilityId":"...","drug_name":"Diclofenac","event_type":"GI bleed","event_description":"Melena","severity":"severe","outcome":"recovering","action_taken":"stopped drug","reporter_name":"Dr. Smith" }`  
**Response 201:** `{ "success": true, "data": {}, "message": "Adverse event recorded successfully" }`

### `GET /mmi/adverse-events/:facilityId?status=&severity=&fromDate=&toDate=&limit=50&offset=0`

**Response 200:**
```json
{ "success": true, "data": [/* events */], "pagination": { "total": N, "limit": 50, "offset": 0 } }
```

### `PUT /mmi/adverse-events/:eventId/status`

**Request:** `{ "status":"resolved","follow_up_notes":"...","causality_assessment":"probable" }`  
**Response 200:** `{ "success": true, "data": {}, "message": "Adverse event updated successfully" }`

### `GET /mmi/adverse-events/:facilityId/summary?fromDate=&toDate=`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "total_events": 10,
    "by_severity": { "mild": 3, "moderate": 5, "severe": 2 },
    "by_type": { "GI bleed": 4, "Allergy": 3, "Nausea": 3 },
    "common_drugs": [{ "drug_name": "Diclofenac", "count": 5 }]
  }
}
```

---

## Orchestrator — Prescription Analysis (3)

### `POST /mmi/analyze` — Full (8 engines)

**Request:**
```json
{
  "patientId": "4-1", "facilityId": "...",
  "prescribedDrugs": ["Ciprofloxacin", "Diclofenac"],
  "patientContext": { "age":45, "weight":70, "egfr":90, "isPregnant":false, "isLactating":false },
  "prescribedDose": 400, "doseUnit": "mg", "durationDays": 7,
  "prescriberRole": "consultant", "hasCulture": false, "hasConsult": false
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "patient_id": "4-1", "facility_id": "...",
    "prescription": { "drugs": ["Ciprofloxacin","Diclofenac"], "dose": "400 mg", "duration_days": 7 },
    "analysis": {
      "execution_time_ms": 42,
      "total_alerts": 3, "critical_count": 1, "major_count": 1,
      "moderate_count": 1, "minor_count": 0,
      "risk_score": 68,       // 0–100
      "risk_level": "high",   // minimal|low|moderate|high|very_high
      "blocks_prescription": true
    },
    "alerts": [
      /* all 8 engines merged, deduplicated, sorted by severity */
    ],
    "summary": {
      "patient_medications": 3,
      "patient_allergies": 1,
      "patient_conditions": 1,
      "engines_consulted": ["interactions","allergies","duplicates","contraindications","dosing","pregnancy","clinical_rules","antimicrobial"]
    },
    "meta": {
      "generated_at": "2026-01-01T00:00:00.000Z",
      "version": "1.0",
      "target_response_time_ms": 500,
      "actual_response_time_ms": 42
    }
  }
}
```

### `POST /mmi/analyze/quick` — Lightweight (reconciliation + interactions + allergies)

**Request:** `{ "patientId":"4-1","facilityId":"...","prescribedDrugs":["Amoxicillin"],"patientContext":{} }`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "patient_id": "4-1",
    "alerts": [/* interaction + allergy alerts */],
    "reconciliation": { "duplicates":[], "restarted":[], "missing_continuations":[] },
    "summary": { "current_medications":3, "alerts_count":1, "critical_count":0 }
  }
}
```

### `POST /mmi/override`

**Request:**
```json
{
  "alert_log_id": 42,
  "patient_id": "4-1",
  "facilityId": "...",
  "prescription_id": "rx-123",
  "alert_type": "drug_interaction",
  "severity": "critical",
  "override_reason": "No alternative antibiotic available",
  "override_category": "clinical_judgement",
  "overridden_by": "Dr. Smith",
  "overridden_by_role": "consultant",
  "approving_authority": "Dr. Jones"
}
```

**Response 200:** `{ "success": true, "data": { "id": 1, /* override data */ }, "message": "Override recorded successfully" }`

---

## Dashboard & Audit (4)

### `GET /mmi/dashboard/:facilityId?fromDate=&toDate=`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "alert_stats": [{ "status": "generated|acknowledged|overridden|resolved", "count": N }],
    "severity_breakdown": [{ "severity": "critical|major|moderate|minor", "count": N }],
    "knowledge_base": { "drug_classes": 30, "total_drugs": 150 },
    "recent_critical_alerts": [/* last 10 critical/major alerts */],
    "override_rate": { "total_overrides": 5, "total_alertable": 50 },
    "top_interaction_types": [{ "interaction_type": "CNS effects", "count": 12 }]
  }
}
```

### `GET /mmi/alert-logs/:facilityId?severity=&status=&alert_type=&patientId=&limit=50&offset=0`

**Response 200:**
```json
{ "success": true, "data": [/* mmi_alert_logs rows */], "pagination": { "total": N, "limit": 50, "offset": 0 } }
```

### `GET /mmi/override-logs/:facilityId?limit=50&offset=0`

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1, "alert_log_id": 42, "patient_id": "4-1",
      "override_reason": "No alternative",
      "title": "Ciprofloxacin + Diclofenac",
      "message": "Increased risk of CNS effects",
      "alert_type": "drug_interaction",
      "severity": "critical",
      "created_at": "ISO"
    }
  ],
  "pagination": { "total": N, "limit": 50, "offset": 0 }
}
```

### `GET /mmi/knowledge-base/stats`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "drugs": 150, "drug_classes": 30, "interactions": 200,
    "allergy_mappings": 50, "contraindications": 40,
    "pregnancy_rules": 25, "antimicrobial_rules": 20
  }
}
```

---

## Unified Alert Shape

Every engine returns alerts conforming to this shape. The orchestrator aggregates, deduplicates, and sorts them by severity.

```json
{
  "alert_type": "drug_interaction|allergy|duplicate_therapy|contraindication|dose_validation|pregnancy_safety|antimicrobial|adverse_event|clinical_rule",
  "severity": "critical|major|moderate|minor",
  "severity_config": {
    "level": 4|3|2|1,
    "label": "Critical|Major|Moderate|Minor",
    "color": "red|orange|blue|gray",
    "blocks_prescription": false
  },
  "title": "Human-readable alert title",
  "message": "Detailed clinical explanation",
  "recommendation": "Suggested clinical action",
  // Engine-specific fields:
  // "drug_a", "drug_b", "interaction_type"           (interactions)
  // "allergen", "drug", "patient_allergy_severity"    (allergies)
  // "drugs", "class_name"                              (duplicates)
  // "contraindication"                                (contraindications)
  // "prescribed_dose", "max_dose", "dose_check_type"  (dose validation)
  // "drug", "pregnancy_category", "risk_factor"       (pregnancy)
  // "aware_category", "requires_culture"              (antimicrobial)
}
```
