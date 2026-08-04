# Phase 2: Clinical Workflow Additions

## Date: February 8, 2026

---

## 🎯 PURPOSE

This document addresses gaps identified between the actual dental clinic workflow and the current implementation plan. These additions ensure the system matches real-world operations.

---

## 📋 WORKFLOW ANALYSIS

### Current Real-World Workflow:

```
Patient Arrival
    ↓
Walk-in? → YES → Reception Registration
    ↓         NO → Skip (already registered)
    ↓
Consultation Room
    ↓
Presenting Complaints
    ↓
Medical History (Allergies, Infections, Diseases)
    ↓
Clinical Examination
    ↓
Investigation Requests (if needed)
    ↓
Doctor's Decision:
    - Surgical Procedure
    - Follow-up Appointment
    - Send Home (with/without medication)
    - Refer to Specialist
```

---

## ❌ GAPS IDENTIFIED

### 1. Walk-in Patient Flow
**Current:** No distinction between walk-in and appointment patients
**Needed:** 
- Walk-in registration workflow
- Queue management for walk-ins
- Priority handling (appointments vs walk-ins)

### 2. Comprehensive Medical History
**Current:** Basic `dental_history` text field
**Needed:**
- Structured allergies recording
- Infection history
- Systemic diseases checklist
- Current medications
- Previous surgeries
- Family medical history

### 3. Clinical Examination Module
**Current:** No structured examination form
**Needed:**
- Extraoral examination
- Intraoral examination
- Soft tissue examination
- Hard tissue examination
- Periodontal examination
- Occlusion assessment

### 4. Investigation Requests
**Current:** No lab/radiology integration
**Needed:**
- X-ray requests (OPG, Periapical, Bitewing)
- Lab test requests (Blood work, Biopsy)
- Investigation tracking
- Results attachment

### 5. Clinical Decision/Disposition
**Current:** No structured decision recording
**Needed:**
- Decision type (Surgical, Follow-up, Discharge, Referral)
- Procedure planning
- Referral management
- Discharge instructions

### 6. Specialist Referral System
**Current:** Not implemented
**Needed:**
- Referral creation
- Specialist directory
- Referral tracking
- Feedback loop

---

## 🗄️ ADDITIONAL DATABASE TABLES NEEDED

### 1. Patient Medical History

```sql
CREATE TABLE `dental_medical_history` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `patient_id` VARCHAR(50) NOT NULL,
  `facilityId` VARCHAR(50) NOT NULL,
  
  -- Allergies
  `has_allergies` BOOLEAN DEFAULT FALSE,
  `allergies_details` TEXT,
  `drug_allergies` TEXT,
  `food_allergies` TEXT,
  
  -- Current Medications
  `current_medications` TEXT,
  
  -- Systemic Diseases
  `has_diabetes` BOOLEAN DEFAULT FALSE,
  `has_hypertension` BOOLEAN DEFAULT FALSE,
  `has_heart_disease` BOOLEAN DEFAULT FALSE,
  `has_asthma` BOOLEAN DEFAULT FALSE,
  `has_hepatitis` BOOLEAN DEFAULT FALSE,
  `has_hiv` BOOLEAN DEFAULT FALSE,
  `has_bleeding_disorder` BOOLEAN DEFAULT FALSE,
  `other_diseases` TEXT,
  
  -- Infections History
  `recent_infections` TEXT,
  `chronic_infections` TEXT,
  
  -- Previous Surgeries
  `previous_surgeries` TEXT,
  
  -- Habits
  `smoking` BOOLEAN DEFAULT FALSE,
  `alcohol` BOOLEAN DEFAULT FALSE,
  `tobacco_chewing` BOOLEAN DEFAULT FALSE,
  
  -- Pregnancy (for female patients)
  `is_pregnant` BOOLEAN DEFAULT FALSE,
  `pregnancy_trimester` INT(1),
  
  -- Family History
  `family_history` TEXT,
  
  -- Last Updated
  `updated_by` VARCHAR(50),
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_patient_history` (`patient_id`, `facilityId`),
  KEY `idx_patient_medical` (`patient_id`, `facilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 2. Clinical Examination Records

```sql
CREATE TABLE `dental_clinical_examination` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `visit_id` VARCHAR(50) NOT NULL,
  `patient_id` VARCHAR(50) NOT NULL,
  `facilityId` VARCHAR(50) NOT NULL,
  `examination_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  -- Vital Signs
  `blood_pressure` VARCHAR(20),
  `pulse_rate` INT(3),
  `temperature` DECIMAL(4,1),
  
  -- Extraoral Examination
  `extraoral_findings` TEXT,
  `facial_symmetry` VARCHAR(50),
  `lymph_nodes` VARCHAR(100),
  `tmj_examination` TEXT,
  
  -- Intraoral Examination
  `oral_hygiene_status` VARCHAR(50), -- Good, Fair, Poor
  `gingival_condition` TEXT,
  `tongue_examination` TEXT,
  `palate_examination` TEXT,
  `floor_of_mouth` TEXT,
  `buccal_mucosa` TEXT,
  
  -- Periodontal Status
  `periodontal_status` VARCHAR(50), -- Healthy, Gingivitis, Periodontitis
  `pocket_depth` TEXT,
  `bleeding_on_probing` BOOLEAN DEFAULT FALSE,
  
  -- Occlusion
  `occlusion_type` VARCHAR(50), -- Class I, II, III
  `overjet` VARCHAR(20),
  `overbite` VARCHAR(20),
  `crossbite` BOOLEAN DEFAULT FALSE,
  
  -- Overall Assessment
  `clinical_findings` TEXT,
  `provisional_diagnosis` TEXT,
  
  -- Examiner
  `examined_by` VARCHAR(50),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  KEY `idx_examination` (`visit_id`, `patient_id`, `facilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 3. Investigation Requests

```sql
CREATE TABLE `dental_investigation_requests` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `request_id` VARCHAR(50) UNIQUE NOT NULL,
  `visit_id` VARCHAR(50) NOT NULL,
  `patient_id` VARCHAR(50) NOT NULL,
  `facilityId` VARCHAR(50) NOT NULL,
  
  -- Request Details
  `investigation_type` VARCHAR(50), -- Radiology, Laboratory, Biopsy
  `investigation_name` VARCHAR(200),
  `urgency` VARCHAR(20), -- Routine, Urgent, STAT
  `clinical_indication` TEXT,
  
  -- Radiology Specific
  `xray_type` VARCHAR(50), -- OPG, Periapical, Bitewing, Cephalometric, CBCT
  `tooth_number` VARCHAR(50), -- For periapical
  
  -- Lab Specific
  `lab_test_type` VARCHAR(100), -- CBC, Blood Sugar, Biopsy, Culture
  `specimen_type` VARCHAR(50),
  
  -- Status
  `status` VARCHAR(50) DEFAULT 'requested', -- requested, in_progress, completed, cancelled
  `requested_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `completed_date` DATETIME,
  
  -- Results
  `results` TEXT,
  `results_file_path` VARCHAR(255),
  `interpretation` TEXT,
  
  -- Personnel
  `requested_by` VARCHAR(50),
  `performed_by` VARCHAR(50),
  `reported_by` VARCHAR(50),
  
  PRIMARY KEY (`id`),
  KEY `idx_investigation` (`patient_id`, `facilityId`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 4. Clinical Decisions/Disposition

```sql
CREATE TABLE `dental_clinical_decisions` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `visit_id` VARCHAR(50) NOT NULL,
  `patient_id` VARCHAR(50) NOT NULL,
  `facilityId` VARCHAR(50) NOT NULL,
  
  -- Decision Type
  `decision_type` VARCHAR(50) NOT NULL, -- surgical, follow_up, discharge, referral
  
  -- Diagnosis
  `final_diagnosis` TEXT,
  `icd_code` VARCHAR(20),
  
  -- Surgical Decision
  `requires_surgery` BOOLEAN DEFAULT FALSE,
  `planned_procedure` VARCHAR(200),
  `procedure_urgency` VARCHAR(20), -- Elective, Urgent, Emergency
  `surgery_notes` TEXT,
  
  -- Follow-up Decision
  `requires_follow_up` BOOLEAN DEFAULT FALSE,
  `follow_up_interval_days` INT(3),
  `follow_up_reason` TEXT,
  
  -- Discharge Decision
  `discharge_status` VARCHAR(50), -- Improved, Stable, Referred
  `discharge_instructions` TEXT,
  `home_care_instructions` TEXT,
  
  -- Referral Decision
  `requires_referral` BOOLEAN DEFAULT FALSE,
  `referral_specialty` VARCHAR(100),
  `referral_reason` TEXT,
  `referral_urgency` VARCHAR(20),
  
  -- Prescription
  `prescription_given` BOOLEAN DEFAULT FALSE,
  `prescription_notes` TEXT,
  
  -- Decision Maker
  `decided_by` VARCHAR(50),
  `decision_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  KEY `idx_decisions` (`visit_id`, `patient_id`, `facilityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 5. Specialist Referrals

```sql
CREATE TABLE `dental_specialist_referrals` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `referral_id` VARCHAR(50) UNIQUE NOT NULL,
  `patient_id` VARCHAR(50) NOT NULL,
  `facilityId` VARCHAR(50) NOT NULL,
  `visit_id` VARCHAR(50),
  
  -- Referral Details
  `referring_doctor_id` VARCHAR(50),
  `referring_doctor_name` VARCHAR(200),
  `referral_date` DATE,
  
  -- Specialist Details
  `specialist_type` VARCHAR(100), -- Orthodontist, Periodontist, Endodontist, etc.
  `specialist_id` VARCHAR(50),
  `specialist_name` VARCHAR(200),
  `specialist_facility` VARCHAR(200),
  
  -- Clinical Information
  `reason_for_referral` TEXT,
  `clinical_summary` TEXT,
  `investigations_done` TEXT,
  `current_medications` TEXT,
  `urgency` VARCHAR(20), -- Routine, Urgent, Emergency
  
  -- Status Tracking
  `status` VARCHAR(50) DEFAULT 'pending', -- pending, accepted, seen, completed, declined
  `appointment_date` DATETIME,
  `seen_date` DATETIME,
  
  -- Feedback
  `specialist_notes` TEXT,
  `specialist_recommendations` TEXT,
  `feedback_received_date` DATETIME,
  
  -- Documents
  `referral_letter_path` VARCHAR(255),
  `reports_attached` TEXT,
  
  PRIMARY KEY (`id`),
  KEY `idx_referrals` (`patient_id`, `facilityId`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 6. Walk-in Queue Management

```sql
CREATE TABLE `dental_walkin_queue` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `queue_number` VARCHAR(20) NOT NULL,
  `patient_id` VARCHAR(50) NOT NULL,
  `facilityId` VARCHAR(50) NOT NULL,
  
  -- Queue Details
  `arrival_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `registration_time` DATETIME,
  `queue_status` VARCHAR(50) DEFAULT 'waiting', -- waiting, in_consultation, completed, left
  
  -- Priority
  `priority` VARCHAR(20) DEFAULT 'normal', -- emergency, urgent, normal
  `chief_complaint` TEXT,
  
  -- Assignment
  `assigned_dentist_id` VARCHAR(50),
  `consultation_start_time` DATETIME,
  `consultation_end_time` DATETIME,
  
  -- Metrics
  `waiting_time_minutes` INT(4),
  `consultation_duration_minutes` INT(4),
  
  PRIMARY KEY (`id`),
  KEY `idx_queue` (`facilityId`, `queue_status`, `arrival_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 7. Specialist Directory

```sql
CREATE TABLE `dental_specialists_directory` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `specialist_id` VARCHAR(50) UNIQUE NOT NULL,
  `facilityId` VARCHAR(50),
  
  -- Personal Details
  `full_name` VARCHAR(200) NOT NULL,
  `specialty` VARCHAR(100) NOT NULL, -- Orthodontics, Periodontics, Endodontics, etc.
  `sub_specialty` VARCHAR(100),
  
  -- Contact Information
  `phone` VARCHAR(50),
  `email` VARCHAR(100),
  `clinic_address` TEXT,
  
  -- Professional Details
  `qualification` VARCHAR(200),
  `registration_number` VARCHAR(50),
  `years_of_experience` INT(2),
  
  -- Availability
  `accepts_referrals` BOOLEAN DEFAULT TRUE,
  `consultation_days` VARCHAR(100),
  `consultation_fee` DECIMAL(10,2),
  
  -- Status
  `status` VARCHAR(20) DEFAULT 'active',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  KEY `idx_specialists` (`specialty`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 📊 VIEWS FOR WORKFLOW SUPPORT

```sql
-- Today's Walk-in Queue
CREATE VIEW v_today_walkin_queue AS
SELECT 
  q.queue_number,
  q.patient_id,
  p.firstname,
  p.surname,
  q.arrival_time,
  q.queue_status,
  q.priority,
  q.chief_complaint,
  q.assigned_dentist_id,
  u.username as dentist_name,
  q.waiting_time_minutes
FROM dental_walkin_queue q
LEFT JOIN patientrecords p ON q.patient_id = p.patientId
LEFT JOIN users u ON q.assigned_dentist_id = u.id
WHERE DATE(q.arrival_time) = CURDATE()
ORDER BY 
  CASE q.priority 
    WHEN 'emergency' THEN 1
    WHEN 'urgent' THEN 2
    ELSE 3
  END,
  q.arrival_time;

-- Pending Investigations
CREATE VIEW v_pending_investigations AS
SELECT 
  i.request_id,
  i.patient_id,
  p.firstname,
  p.surname,
  i.investigation_type,
  i.investigation_name,
  i.urgency,
  i.requested_date,
  u.username as requested_by_name,
  i.status
FROM dental_investigation_requests i
LEFT JOIN patientrecords p ON i.patient_id = p.patientId
LEFT JOIN users u ON i.requested_by = u.id
WHERE i.status IN ('requested', 'in_progress')
ORDER BY 
  CASE i.urgency
    WHEN 'STAT' THEN 1
    WHEN 'Urgent' THEN 2
    ELSE 3
  END,
  i.requested_date;

-- Pending Referrals
CREATE VIEW v_pending_referrals AS
SELECT 
  r.referral_id,
  r.patient_id,
  p.firstname,
  p.surname,
  r.specialist_type,
  r.specialist_name,
  r.reason_for_referral,
  r.urgency,
  r.referral_date,
  r.status
FROM dental_specialist_referrals r
LEFT JOIN patientrecords p ON r.patient_id = p.patientId
WHERE r.status IN ('pending', 'accepted')
ORDER BY 
  CASE r.urgency
    WHEN 'Emergency' THEN 1
    WHEN 'Urgent' THEN 2
    ELSE 3
  END,
  r.referral_date;
```

---

## 🔄 STORED PROCEDURES

### 1. Register Walk-in Patient

```sql
DELIMITER //

CREATE PROCEDURE register_walkin_patient(
  IN p_patient_id VARCHAR(50),
  IN p_facilityId VARCHAR(50),
  IN p_chief_complaint TEXT,
  IN p_priority VARCHAR(20)
)
BEGIN
  DECLARE v_queue_number VARCHAR(20);
  DECLARE v_queue_count INT;
  
  -- Generate queue number
  SELECT COUNT(*) + 1 INTO v_queue_count
  FROM dental_walkin_queue
  WHERE facilityId = p_facilityId
  AND DATE(arrival_time) = CURDATE();
  
  SET v_queue_number = CONCAT('Q', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(v_queue_count, 3, '0'));
  
  -- Insert into queue
  INSERT INTO dental_walkin_queue (
    queue_number,
    patient_id,
    facilityId,
    chief_complaint,
    priority,
    registration_time
  ) VALUES (
    v_queue_number,
    p_patient_id,
    p_facilityId,
    p_chief_complaint,
    COALESCE(p_priority, 'normal'),
    NOW()
  );
  
  SELECT v_queue_number as queue_number, 'success' as status;
END //

DELIMITER ;
```

### 2. Create Investigation Request

```sql
DELIMITER //

CREATE PROCEDURE create_investigation_request(
  IN p_visit_id VARCHAR(50),
  IN p_patient_id VARCHAR(50),
  IN p_facilityId VARCHAR(50),
  IN p_investigation_type VARCHAR(50),
  IN p_investigation_name VARCHAR(200),
  IN p_urgency VARCHAR(20),
  IN p_clinical_indication TEXT,
  IN p_requested_by VARCHAR(50)
)
BEGIN
  DECLARE v_request_id VARCHAR(50);
  
  -- Generate request ID
  SET v_request_id = CONCAT('INV-', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));
  
  -- Insert investigation request
  INSERT INTO dental_investigation_requests (
    request_id,
    visit_id,
    patient_id,
    facilityId,
    investigation_type,
    investigation_name,
    urgency,
    clinical_indication,
    requested_by
  ) VALUES (
    v_request_id,
    p_visit_id,
    p_patient_id,
    p_facilityId,
    p_investigation_type,
    p_investigation_name,
    p_urgency,
    p_clinical_indication,
    p_requested_by
  );
  
  SELECT v_request_id as request_id, 'success' as status;
END //

DELIMITER ;
```

### 3. Create Specialist Referral

```sql
DELIMITER //

CREATE PROCEDURE create_specialist_referral(
  IN p_patient_id VARCHAR(50),
  IN p_facilityId VARCHAR(50),
  IN p_visit_id VARCHAR(50),
  IN p_referring_doctor_id VARCHAR(50),
  IN p_specialist_type VARCHAR(100),
  IN p_reason TEXT,
  IN p_urgency VARCHAR(20)
)
BEGIN
  DECLARE v_referral_id VARCHAR(50);
  
  -- Generate referral ID
  SET v_referral_id = CONCAT('REF-', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));
  
  -- Insert referral
  INSERT INTO dental_specialist_referrals (
    referral_id,
    patient_id,
    facilityId,
    visit_id,
    referring_doctor_id,
    specialist_type,
    reason_for_referral,
    urgency,
    referral_date
  ) VALUES (
    v_referral_id,
    p_patient_id,
    p_facilityId,
    p_visit_id,
    p_referring_doctor_id,
    p_specialist_type,
    p_reason,
    p_urgency,
    CURDATE()
  );
  
  SELECT v_referral_id as referral_id, 'success' as status;
END //

DELIMITER ;
```

---

## 🎯 UPDATED WORKFLOW WITH NEW FEATURES

```
1. PATIENT ARRIVAL
   ├─ Walk-in → Register in Queue (dental_walkin_queue)
   └─ Appointment → Check-in (dental_appointments)

2. RECEPTION
   └─ Assign to Dentist / Update Queue Status

3. CONSULTATION ROOM
   ├─ Update Medical History (dental_medical_history)
   ├─ Record Presenting Complaints (dental_visits)
   └─ Clinical Examination (dental_clinical_examination)

4. INVESTIGATIONS (if needed)
   └─ Create Investigation Request (dental_investigation_requests)

5. DOCTOR'S DECISION (dental_clinical_decisions)
   ├─ Surgical → Plan Procedure
   ├─ Follow-up → Schedule Appointment
   ├─ Discharge → Home Care Instructions
   └─ Referral → Create Specialist Referral

6. COMPLETION
   ├─ Generate Prescription (if needed)
   ├─ Update Visit Status
   └─ Billing/Payment
```

---

## 📋 API ENDPOINTS NEEDED

### Medical History
- POST `/dental/medical-history/create`
- GET `/dental/medical-history/:patientId/:facilityId`
- PUT `/dental/medical-history/:patientId`

### Clinical Examination
- POST `/dental/examination/create`
- GET `/dental/examination/:visitId`
- PUT `/dental/examination/:id`

### Investigations
- POST `/dental/investigations/request`
- GET `/dental/investigations/:patientId/:facilityId`
- PUT `/dental/investigations/:requestId/complete`
- GET `/dental/investigations/pending/:facilityId`

### Clinical Decisions
- POST `/dental/decisions/create`
- GET `/dental/decisions/:visitId`
- PUT `/dental/decisions/:id`

### Referrals
- POST `/dental/referrals/create`
- GET `/dental/referrals/:patientId/:facilityId`
- PUT `/dental/referrals/:referralId/update-status`
- GET `/dental/referrals/pending/:facilityId`

### Walk-in Queue
- POST `/dental/walkin/register`
- GET `/dental/walkin/queue/:facilityId`
- PUT `/dental/walkin/:queueId/assign-dentist`
- PUT `/dental/walkin/:queueId/start-consultation`
- PUT `/dental/walkin/:queueId/complete`

### Specialists Directory
- POST `/dental/specialists/create`
- GET `/dental/specialists/list/:facilityId`
- GET `/dental/specialists/by-specialty/:specialty`

---

## ✅ IMPLEMENTATION PRIORITY

### HIGH PRIORITY (Implement First)
1. ✅ Medical History Module
2. ✅ Clinical Examination Module
3. ✅ Clinical Decisions Module
4. ✅ Walk-in Queue Management

### MEDIUM PRIORITY
5. Investigation Requests
6. Specialist Referrals

### LOW PRIORITY (Can be added later)
7. Specialist Directory (can use manual entry initially)

---

## 📝 SUMMARY

These additions complete the clinical workflow to match real-world dental practice operations. They integrate seamlessly with the existing Phase 1 implementation while adding critical missing functionality for:

- Comprehensive medical history tracking
- Structured clinical examinations
- Investigation management
- Clinical decision documentation
- Specialist referral system
- Walk-in patient queue management

---

*Document Created: February 8, 2026*
*Status: Ready for Implementation*
