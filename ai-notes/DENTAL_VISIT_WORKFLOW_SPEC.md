# Dental Patient Visit Workflow Specification

## Overview
Complete patient visit documentation system integrated with appointments, dental lab, oral care shop, and theater modules.

## Visit Flow

### 1. Start Visit (Entry Point)
- **Trigger**: "Start Visit" button on appointments/assigned patients
- **Action**: Navigate to visit documentation page
- **URL**: `/me/dental/visit/:patientId/:appointmentId`

### 2. Visit Documentation Steps

#### Step 1: Chief Complaint
- Presenting complaint (free text)
- Duration of complaint
- Severity (mild/moderate/severe)
- Previous treatment attempts

#### Step 2: Medical History
- **Allergies**
  - Drug allergies
  - Food allergies
  - Environmental allergies
- **Infections**
  - Current infections
  - Past infections
  - Chronic infections
- **Diseases**
  - Diabetes
  - Hypertension
  - Heart disease
  - Bleeding disorders
  - Other systemic diseases
- **Medications**
  - Current medications
  - Dosage and frequency
- **Social History**
  - Smoking
  - Alcohol consumption
  - Drug use

#### Step 3: Clinical Examination
- **Extra-oral Examination**
  - Facial symmetry
  - TMJ assessment
  - Lymph nodes
  - Soft tissue examination
- **Intra-oral Examination**
  - Soft tissue (gums, tongue, palate, etc.)
  - Hard tissue (teeth condition)
  - Occlusion
  - Periodontal status
- **Dental Chart Integration**
  - Visual tooth charting
  - Tooth-specific findings
  - Existing restorations
  - Caries/decay marking

#### Step 4: Investigations (Optional)
- **Imaging**
  - X-rays (periapical, bitewing, panoramic)
  - CBCT
  - Photos
- **Lab Tests**
  - Blood tests
  - Biopsy
  - Culture & sensitivity
- **Dental Lab Requests**
  - Study models
  - Diagnostic wax-up
  - Custom trays
  - Integration with dental lab module

#### Step 5: Diagnosis
- Primary diagnosis
- Differential diagnosis
- ICD-10 codes (optional)
- Severity assessment

#### Step 6: Treatment Plan
- Recommended procedures
- Alternative options
- Cost estimation
- Timeline

#### Step 7: Prescriptions (Optional)
- Medications
- Dosage and instructions
- Duration
- Integration with oral care shop for dispensing

#### Step 8: Clinical Decision
Three pathways:

**A. Surgical**
- Procedure type
- Urgency (elective/urgent/emergency)
- Pre-operative requirements
- Integration with theater module
- Theater booking

**B. Out-Patient**
- Treatment procedures
- Follow-up schedule
- Home care instructions
- Billing integration

**C. Appointment**
- Schedule follow-up appointment
- Appointment type
- Estimated duration
- Special requirements

### 3. Visit Completion
- Visit summary
- Doctor's notes
- Patient instructions
- Next steps
- Print visit summary

## Database Schema

### dental_visits Table
```sql
CREATE TABLE dental_visits (
  id INT PRIMARY KEY AUTO_INCREMENT,
  visit_id VARCHAR(50) UNIQUE NOT NULL,
  patient_id VARCHAR(50) NOT NULL,
  appointment_id INT,
  doctor_id VARCHAR(50) NOT NULL,
  facility_id VARCHAR(50) NOT NULL,
  visit_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  visit_status ENUM('in_progress', 'completed', 'cancelled') DEFAULT 'in_progress',
  
  -- Chief Complaint
  chief_complaint TEXT,
  complaint_duration VARCHAR(100),
  complaint_severity ENUM('mild', 'moderate', 'severe'),
  previous_treatment TEXT,
  
  -- Medical History
  allergies JSON,
  infections JSON,
  diseases JSON,
  current_medications JSON,
  social_history JSON,
  
  -- Examination
  extraoral_findings JSON,
  intraoral_findings JSON,
  dental_chart_data JSON,
  
  -- Diagnosis
  primary_diagnosis TEXT,
  differential_diagnosis TEXT,
  icd10_codes JSON,
  
  -- Treatment Plan
  treatment_plan JSON,
  estimated_cost DECIMAL(10,2),
  
  -- Clinical Decision
  clinical_decision ENUM('surgical', 'outpatient', 'appointment'),
  decision_details JSON,
  
  -- References
  investigation_ids JSON,
  prescription_ids JSON,
  lab_request_ids JSON,
  theater_booking_id INT,
  followup_appointment_id INT,
  
  -- Metadata
  visit_duration INT, -- in minutes
  completed_at DATETIME,
  notes TEXT,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
  FOREIGN KEY (doctor_id) REFERENCES users(id),
  FOREIGN KEY (facility_id) REFERENCES facilities(id),
  INDEX idx_patient (patient_id),
  INDEX idx_doctor (doctor_id),
  INDEX idx_visit_date (visit_date),
  INDEX idx_status (visit_status)
);
```

### dental_visit_investigations Table
```sql
CREATE TABLE dental_visit_investigations (
  id INT PRIMARY KEY AUTO_INCREMENT,
  visit_id VARCHAR(50) NOT NULL,
  investigation_type ENUM('imaging', 'lab_test', 'dental_lab'),
  investigation_name VARCHAR(200),
  request_details JSON,
  status ENUM('requested', 'in_progress', 'completed', 'cancelled') DEFAULT 'requested',
  results JSON,
  lab_request_id INT, -- Link to dental lab jobs
  requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME,
  
  FOREIGN KEY (visit_id) REFERENCES dental_visits(visit_id),
  INDEX idx_visit (visit_id),
  INDEX idx_status (status)
);
```

## Integration Points

### 1. Appointments Module
- Start visit from appointment
- Update appointment status to "in_progress" when visit starts
- Update to "completed" when visit ends
- Link visit record to appointment

### 2. Dental Lab Module
- Create lab requests from visit
- Track request status
- Link results back to visit
- Billing integration

### 3. Oral Care Shop Module
- Send prescriptions for dispensing
- Track dispensing status
- Link to visit record
- Billing integration

### 4. Theater Module
- Create theater booking for surgical cases
- Pre-operative checklist
- Link to visit record
- Theater scheduling

### 5. Billing Module
- Generate bills for procedures
- Track payment status
- Link to visit record

## UI Components

### Main Components
1. `VisitDocumentation.jsx` - Main visit page with stepper
2. `ChiefComplaint.jsx` - Step 1
3. `MedicalHistory.jsx` - Step 2
4. `ClinicalExamination.jsx` - Step 3 (integrate existing)
5. `InvestigationRequest.jsx` - Step 4
6. `DiagnosisPlan.jsx` - Step 5 & 6
7. `PrescriptionManager.jsx` - Step 7 (integrate existing)
8. `ClinicalDecisionMaker.jsx` - Step 8 (enhance existing)
9. `VisitSummary.jsx` - Final summary

### Shared Components
- `VisitStepper.jsx` - Progress indicator
- `VisitHeader.jsx` - Patient info header
- `VisitActions.jsx` - Save, cancel, complete actions

## API Endpoints

### Visit Management
- `POST /dental/visits/start` - Start new visit
- `GET /dental/visits/:visitId` - Get visit details
- `PUT /dental/visits/:visitId` - Update visit
- `POST /dental/visits/:visitId/complete` - Complete visit
- `GET /dental/visits/patient/:patientId` - Get patient visit history

### Visit Steps
- `PUT /dental/visits/:visitId/complaint` - Save chief complaint
- `PUT /dental/visits/:visitId/medical-history` - Save medical history
- `PUT /dental/visits/:visitId/examination` - Save examination findings
- `POST /dental/visits/:visitId/investigations` - Request investigations
- `PUT /dental/visits/:visitId/diagnosis` - Save diagnosis
- `PUT /dental/visits/:visitId/treatment-plan` - Save treatment plan
- `POST /dental/visits/:visitId/prescriptions` - Create prescriptions
- `PUT /dental/visits/:visitId/decision` - Save clinical decision

### Integration Endpoints
- `POST /dental/visits/:visitId/lab-request` - Create dental lab request
- `POST /dental/visits/:visitId/theater-booking` - Book theater
- `POST /dental/visits/:visitId/prescription/dispense` - Send to pharmacy
- `GET /dental/visits/:visitId/summary` - Get visit summary

## Workflow States

### Visit Status Flow
```
not_started → in_progress → completed
                ↓
            cancelled
```

### Step Completion Tracking
- Each step marked as complete/incomplete
- Can navigate back to previous steps
- Must complete required steps before finishing visit
- Auto-save on each step

## User Permissions
- Dentists: Full access to create and manage visits
- Dental assistants: Can view and assist with data entry
- Nurses: Can view visit details
- Admin: Full access including reports

## Reporting
- Daily visit summary
- Visit duration analytics
- Common diagnoses report
- Treatment plan acceptance rate
- Revenue per visit
- Investigation utilization

## Next Steps
1. Create database migration
2. Implement backend API
3. Create frontend components
4. Integrate with existing modules
5. Testing and validation
6. User training documentation
