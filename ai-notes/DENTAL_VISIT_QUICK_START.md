# Dental Visit Workflow - Quick Start Guide

## Overview
Complete patient visit documentation system that guides dentists through a structured workflow from chief complaint to clinical decision.

## Installation

### 1. Run Database Migration
```bash
cd backend/sql
node run_visit_workflow_migration.js
```

This creates:
- `dental_visits` - Main visit records
- `dental_visit_investigations` - Investigation requests
- `dental_visit_steps` - Step completion tracking
- `dental_visit_attachments` - Images and documents
- `dental_visit_summary` - Summary view

### 2. Verify Installation
Check that tables were created:
```sql
SHOW TABLES LIKE 'dental_visit%';
```

## Visit Workflow

### Starting a Visit

**From Appointments:**
1. Go to Dental Appointments
2. Find patient's appointment
3. Click "Start Visit" button
4. System creates visit record and navigates to visit page

**From Patient List:**
1. Go to Assigned Patients
2. Select patient
3. Click "Start Visit" button
4. System creates visit record

### Visit Steps

#### 1. Chief Complaint
- What brings the patient in?
- Duration of complaint
- Severity level
- Previous treatments attempted

**Required:** Chief complaint text

#### 2. Medical History
- **Allergies**: Drug, food, environmental
- **Infections**: Current, past, chronic
- **Diseases**: Diabetes, hypertension, heart disease, etc.
- **Medications**: Current medications with dosage
- **Social History**: Smoking, alcohol, drugs

**Required:** At least one section completed

#### 3. Clinical Examination
- **Extra-oral**: Facial symmetry, TMJ, lymph nodes
- **Intra-oral**: Soft tissue, hard tissue, occlusion
- **Dental Chart**: Visual tooth charting with findings

**Required:** Examination findings recorded

#### 4. Investigations (Optional)
Request any needed tests:
- **Imaging**: X-rays, CBCT, photos
- **Lab Tests**: Blood work, biopsy, culture
- **Dental Lab**: Study models, diagnostic wax-up

**Integration**: Dental lab requests automatically create jobs in lab module

#### 5. Diagnosis & Treatment Plan
- Primary diagnosis
- Differential diagnosis
- Recommended procedures
- Cost estimation
- Timeline

**Required:** Primary diagnosis

#### 6. Prescriptions (Optional)
- Add medications
- Dosage and instructions
- Duration

**Integration**: Prescriptions sent to oral care shop for dispensing

#### 7. Clinical Decision (Required)
Choose one of three pathways:

**A. Surgical**
- Procedure type
- Urgency level
- Pre-op requirements
- **Integration**: Creates theater booking

**B. Out-Patient**
- Treatment procedures
- Follow-up schedule
- Home care instructions
- **Integration**: Generates billing

**C. Appointment**
- Schedule follow-up
- Appointment type
- Duration
- **Integration**: Creates new appointment

### Completing a Visit

1. Review visit summary
2. Add final doctor's notes
3. Add patient instructions
4. Click "Complete Visit"
5. Print visit summary (optional)

## URL Structure

```
/me/dental/visit/:patientId/:appointmentId    → New visit
/me/dental/visit/:visitId                     → Continue existing visit
/me/dental/visits                             → Visit history
/me/dental/visits/:visitId/summary            → Visit summary
```

## API Endpoints

### Visit Management
```
POST   /dental/visits/start                   → Start new visit
GET    /dental/visits/:visitId                → Get visit details
PUT    /dental/visits/:visitId                → Update visit
POST   /dental/visits/:visitId/complete       → Complete visit
GET    /dental/visits/patient/:patientId      → Patient visit history
```

### Visit Steps
```
PUT    /dental/visits/:visitId/complaint      → Save chief complaint
PUT    /dental/visits/:visitId/medical-history → Save medical history
PUT    /dental/visits/:visitId/examination    → Save examination
POST   /dental/visits/:visitId/investigations → Request investigations
PUT    /dental/visits/:visitId/diagnosis      → Save diagnosis
POST   /dental/visits/:visitId/prescriptions  → Create prescriptions
PUT    /dental/visits/:visitId/decision       → Save clinical decision
```

### Integration
```
POST   /dental/visits/:visitId/lab-request    → Create dental lab request
POST   /dental/visits/:visitId/theater-booking → Book theater
GET    /dental/visits/:visitId/summary        → Get visit summary
```

## Integration Points

### 1. Appointments Module
- Visit linked to appointment
- Appointment status updated to "in_progress"
- Completed when visit ends

### 2. Dental Lab Module
- Investigation requests create lab jobs
- Job status tracked in visit
- Results linked back to visit

### 3. Oral Care Shop
- Prescriptions sent for dispensing
- Dispensing status tracked
- Billing integrated

### 4. Theater Module
- Surgical decisions create theater bookings
- Pre-op checklist linked
- Theater scheduling integrated

### 5. Billing Module
- Procedures generate bills
- Payment status tracked
- Visit-level billing summary

## Data Storage

### Visit Data Structure
```javascript
{
  visit_id: "VISIT-1234567890",
  patient_id: "PAT-123",
  doctor_id: "DOC-456",
  visit_status: "in_progress",
  
  // Chief Complaint
  chief_complaint: "Toothache on upper right",
  complaint_duration: "3 days",
  complaint_severity: "moderate",
  
  // Medical History (JSON)
  allergies: [
    { type: "drug", name: "Penicillin", reaction: "Rash" }
  ],
  diseases: [
    { name: "Diabetes Type 2", controlled: true }
  ],
  
  // Examination (JSON)
  dental_chart_data: {
    tooth_16: { condition: "caries", severity: "moderate" }
  },
  
  // Diagnosis
  primary_diagnosis: "Dental caries, tooth 16",
  
  // Clinical Decision
  clinical_decision: "outpatient",
  decision_details: {
    procedures: ["Composite filling"],
    follow_up: "2 weeks"
  }
}
```

## Best Practices

### 1. Auto-Save
- System auto-saves after each step
- No data loss if browser closes
- Can resume visit anytime

### 2. Step Navigation
- Can go back to previous steps
- Changes saved immediately
- Progress indicator shows completion

### 3. Required Fields
- System validates required fields
- Cannot complete visit without required data
- Clear error messages

### 4. Documentation
- Thorough documentation improves care
- Legal protection
- Better continuity of care

### 5. Integration
- Use integrations to reduce duplicate entry
- Lab requests auto-create jobs
- Prescriptions auto-send to pharmacy

## Troubleshooting

### Visit Won't Start
- Check patient has valid ID
- Verify appointment exists
- Check user permissions

### Can't Complete Visit
- Ensure all required steps completed
- Check clinical decision selected
- Verify diagnosis entered

### Integration Not Working
- Check module is enabled
- Verify API endpoints accessible
- Check facility configuration

## Reports Available

1. **Daily Visit Summary**: All visits for the day
2. **Visit Duration**: Average time per visit
3. **Common Diagnoses**: Most frequent diagnoses
4. **Investigation Utilization**: Most requested tests
5. **Revenue Per Visit**: Financial analytics
6. **Treatment Acceptance**: Plan acceptance rates

## Next Steps

1. Run database migration
2. Test visit workflow with sample patient
3. Configure integrations
4. Train staff on workflow
5. Review and customize forms
6. Set up reporting

## Support

For issues or questions:
1. Check this guide
2. Review DENTAL_VISIT_WORKFLOW_SPEC.md
3. Check API documentation
4. Contact system administrator
