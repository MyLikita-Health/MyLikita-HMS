# Radiology Phase 4 Implementation Plan
## DICOM Worklist & Modality Integration

**Status**: In Progress  
**Timeline**: Week 8-9 (2 weeks)  
**Priority**: High - Critical for modality integration  
**Date Started**: March 11, 2026

---

## Phase 4 Overview

Phase 4 focuses on enabling automatic communication between the radiology system and DICOM modalities (X-ray, CT, MR machines). This allows machines to:
1. Fetch worklist items (patient info, procedures to perform)
2. Automatically send images back to the system
3. Trigger automatic status updates and billing

### Key Components

**Week 8: DICOM Worklist (MWL) Generation**
- Generate worklist items when appointments are scheduled
- Export worklist to Orthanc format
- Create modality registry
- Implement worklist API endpoints

**Week 9: Automatic Image Reception**
- Configure Orthanc webhooks
- Implement webhook handlers
- Auto-match images to requests
- Auto-update status and trigger billing
- Send notifications

---

## Implementation Roadmap

### TASK 1: Worklist Generation & Export (Week 8)

#### 1.1 Database Setup
- ✅ Tables already created: `radiology_worklist`, `radiology_modalities`
- Status: Ready to use

#### 1.2 Worklist Controller (`radiology-worklist.js`)
**Responsibilities:**
- Generate worklist items when appointments are scheduled
- Export worklist to Orthanc JSON format
- Manage worklist status updates
- Query worklist by accession number

**Key Functions:**
```javascript
- generateWorklistItem(appointmentId) - Create worklist from appointment
- exportWorklistToOrthanc(worklistId) - Export to Orthanc format
- getWorklistByAccession(accessionNumber) - Fetch by accession
- updateWorklistStatus(worklistId, status) - Update status
- getWorklistForModality(modalityId) - Get pending worklist for machine
```

#### 1.3 Worklist Routes
**Endpoints:**
```
POST   /radiology/worklist                    - Create worklist item
GET    /radiology/worklist                    - List worklist items
GET    /radiology/worklist/:accessionNumber   - Get by accession
PUT    /radiology/worklist/:id/status         - Update status
GET    /radiology/worklist/modality/:modalityId - Get for modality
POST   /radiology/worklist/:id/export         - Export to Orthanc
```

#### 1.4 Modality Registry Controller
**Responsibilities:**
- Register DICOM modalities
- Manage modality configuration
- Track modality status and connectivity

**Key Functions:**
```javascript
- registerModality(modalityData) - Register new machine
- getModalities() - List all modalities
- updateModalityStatus(modalityId, status) - Update status
- getModalityByAETitle(aeTitle) - Find by AE Title
```

#### 1.5 Accession Number Generation
- Format: `FAC-YYYYMMDD-XXXXXX` (facility-date-sequence)
- Unique per facility per day
- Auto-increment sequence

---

### TASK 2: Automatic Image Reception (Week 9)

#### 2.1 Webhook Handler (`radiology-dicom-webhook.js`)
**Responsibilities:**
- Receive notifications from Orthanc when images arrive
- Match images to worklist items
- Update request status to 'completed'
- Trigger auto-billing
- Send notifications

**Key Functions:**
```javascript
- handleImageReceived(studyData) - Process new images
- matchImageToRequest(studyUID) - Find associated request
- updateRequestStatus(requestId, status) - Update status
- triggerAutoBilling(requestId) - Create billing
- notifyRadiologist(requestId) - Send notification
```

#### 2.2 Orthanc Configuration
**Setup:**
- Configure C-STORE receiver (port 104)
- Set up auto-routing rules
- Configure webhook notifications
- Enable DICOMweb API

**Webhook URL:**
```
POST http://backend:46990/radiology/webhook/image-received
```

#### 2.3 Auto-Billing Integration
**Flow:**
1. Image received → Webhook triggered
2. Match to request → Get procedure details
3. Create billing entry → Link to pending_txn
4. Update status → Mark as 'completed'
5. Notify → Alert radiologist

---

## Implementation Tasks

### Week 8 Tasks

**Task 8.1: Create Worklist Controller**
- [ ] Create `backend/controller/radiology-worklist.js`
- [ ] Implement worklist generation
- [ ] Implement Orthanc export
- [ ] Add accession number generation

**Task 8.2: Create Modality Registry Controller**
- [ ] Create modality management functions
- [ ] Add to `radiology-worklist.js` or separate file

**Task 8.3: Create Worklist Routes**
- [ ] Add routes to `backend/routes/radiology-worklist.js`
- [ ] Register routes in `app.js`

**Task 8.4: Integrate with Appointment Scheduling**
- [ ] Modify `radiology-appointments.js` to create worklist on scheduling
- [ ] Auto-generate accession numbers

**Task 8.5: Testing**
- [ ] Test worklist creation
- [ ] Test Orthanc export
- [ ] Test accession number generation
- [ ] Test modality queries

---

### Week 9 Tasks

**Task 9.1: Create Webhook Handler**
- [ ] Create `backend/controller/radiology-dicom-webhook.js`
- [ ] Implement image received handler
- [ ] Implement image-to-request matching
- [ ] Implement auto-billing trigger

**Task 9.2: Configure Orthanc Webhooks**
- [ ] Update Orthanc configuration
- [ ] Set up webhook notifications
- [ ] Test webhook delivery

**Task 9.3: Integrate with Billing**
- [ ] Link webhook to billing creation
- [ ] Update pending_txn on image receipt
- [ ] Trigger notifications

**Task 9.4: Testing**
- [ ] Test webhook reception
- [ ] Test image matching
- [ ] Test auto-billing
- [ ] Test notifications
- [ ] End-to-end workflow test

---

## Database Schema Review

### radiology_worklist Table
```sql
- id (PK)
- accession_number (UNIQUE) - Unique identifier for exam
- request_id (FK) - Link to request
- appointment_id (FK) - Link to appointment
- patient_id (FK) - Link to patient
- procedure_id (FK) - Link to procedure
- patient_name - For DICOM
- patient_mrn - Medical Record Number
- patient_dob - Date of birth
- patient_sex - M/F/O
- patient_age - Age in years
- procedure_code - DICOM procedure code
- procedure_description - Procedure name
- body_part - Body part examined
- modality - XR, CT, MR, US, etc.
- scheduled_date - Appointment date/time
- scheduled_ae_title - Target modality AE Title
- requesting_physician - Doctor name
- worklist_status - pending/in-progress/completed/cancelled
- exported_to_orthanc - Boolean flag
- export_date - When exported
- clinical_indication - Why exam needed
- special_instructions - Special notes
- contrast_required - Boolean
```

### radiology_modalities Table
```sql
- id (PK)
- modality_name - Display name
- modality_type - XR, CT, MR, US, MG, FL, DX, CR, DR, OTHER
- ae_title (UNIQUE) - DICOM Application Entity Title
- ip_address - Machine IP
- port - DICOM port (default 104)
- supports_worklist - Boolean
- supports_storage - Boolean
- manufacturer - Equipment manufacturer
- model - Equipment model
- serial_number - Equipment serial
- room_location - Physical location
- status - active/inactive/maintenance/offline
- last_connection - Last connection time
- auto_route_to_pacs - Auto-route images
- auto_notify_on_receive - Send notifications
```

---

## API Endpoints

### Worklist Endpoints

**1. Create Worklist Item**
```
POST /radiology/worklist
Body: {
  appointment_id: "uuid",
  modality_id: "uuid"
}
Response: {
  success: true,
  data: {
    id: "uuid",
    accession_number: "FAC-20260311-000001"
  }
}
```

**2. List Worklist Items**
```
GET /radiology/worklist?status=pending&modality_id=uuid
Response: {
  success: true,
  data: [
    {
      id: "uuid",
      accession_number: "FAC-20260311-000001",
      patient_name: "John Doe",
      procedure_description: "Chest X-ray",
      scheduled_date: "2026-03-11 10:00:00",
      status: "pending"
    }
  ]
}
```

**3. Get by Accession Number**
```
GET /radiology/worklist/FAC-20260311-000001
Response: {
  success: true,
  data: {
    id: "uuid",
    accession_number: "FAC-20260311-000001",
    patient_name: "John Doe",
    patient_mrn: "7-1",
    patient_dob: "1990-05-15",
    patient_sex: "M",
    procedure_code: "CHEST-XR",
    procedure_description: "Chest X-ray",
    modality: "XR",
    scheduled_date: "2026-03-11 10:00:00",
    requesting_physician: "Dr. Smith",
    clinical_indication: "Suspected pneumonia",
    special_instructions: "Upright position"
  }
}
```

**4. Update Worklist Status**
```
PUT /radiology/worklist/:id/status
Body: { status: "in-progress" }
Response: { success: true, message: "Status updated" }
```

**5. Get Worklist for Modality**
```
GET /radiology/worklist/modality/uuid?status=pending
Response: {
  success: true,
  data: [
    { /* worklist items for this modality */ }
  ]
}
```

**6. Export to Orthanc**
```
POST /radiology/worklist/:id/export
Response: {
  success: true,
  data: {
    exported: true,
    export_date: "2026-03-11 10:00:00",
    orthanc_path: "/var/lib/orthanc/worklists/FAC-20260311-000001.json"
  }
}
```

### Modality Endpoints

**1. Register Modality**
```
POST /radiology/modalities
Body: {
  modality_name: "X-ray Room 1",
  modality_type: "XR",
  ae_title: "XRAY01",
  ip_address: "192.168.1.100",
  port: 104,
  manufacturer: "Siemens",
  model: "AXIOM Luminos",
  room_location: "Ground Floor - Room 1"
}
Response: {
  success: true,
  data: { id: "uuid", ae_title: "XRAY01" }
}
```

**2. List Modalities**
```
GET /radiology/modalities
Response: {
  success: true,
  data: [
    {
      id: "uuid",
      modality_name: "X-ray Room 1",
      modality_type: "XR",
      ae_title: "XRAY01",
      status: "active",
      last_connection: "2026-03-11 09:45:00"
    }
  ]
}
```

**3. Update Modality Status**
```
PUT /radiology/modalities/:id/status
Body: { status: "active" }
Response: { success: true, message: "Status updated" }
```

### Webhook Endpoint

**Image Received Webhook**
```
POST /radiology/webhook/image-received
Body: {
  studyUID: "1.2.3.4.5",
  patientID: "7-1",
  patientName: "John Doe",
  modality: "XR",
  studyDate: "20260311",
  studyTime: "100000",
  numberOfImages: 3,
  accessionNumber: "FAC-20260311-000001"
}
Response: {
  success: true,
  data: {
    request_id: "uuid",
    status_updated: true,
    billing_created: true
  }
}
```

---

## Integration Points

### 1. Appointment Scheduling
**When:** Appointment is scheduled
**Action:** Create worklist item with accession number
**File:** `radiology-appointments.js`

### 2. Image Reception
**When:** Images arrive at Orthanc
**Action:** Webhook triggers status update and billing
**File:** `radiology-dicom-webhook.js`

### 3. Billing
**When:** Images received
**Action:** Auto-create billing entry
**File:** `radiology-billing.js`

### 4. Notifications
**When:** Status changes or images received
**Action:** Send notifications to radiologist
**File:** Notification service

---

## Testing Strategy

### Unit Tests
- [ ] Accession number generation
- [ ] Worklist item creation
- [ ] Orthanc export format
- [ ] Image matching logic
- [ ] Billing creation

### Integration Tests
- [ ] Appointment → Worklist flow
- [ ] Image reception → Status update flow
- [ ] Status update → Billing flow
- [ ] Modality registration → Worklist query flow

### End-to-End Tests
- [ ] Complete workflow: Schedule → Worklist → Image → Billing
- [ ] Multiple procedures in one bill
- [ ] Modality connectivity
- [ ] Webhook reliability

### Manual Tests
- [ ] Test with real DICOM modality (if available)
- [ ] Test Orthanc integration
- [ ] Test webhook delivery
- [ ] Test error scenarios

---

## Deployment Checklist

### Pre-Deployment
- [ ] Database migrations run
- [ ] Controllers created and tested
- [ ] Routes registered
- [ ] Orthanc configured
- [ ] Webhooks configured
- [ ] Environment variables set

### Deployment
- [ ] Deploy backend code
- [ ] Verify API endpoints
- [ ] Test worklist creation
- [ ] Test webhook reception
- [ ] Monitor logs

### Post-Deployment
- [ ] Monitor system performance
- [ ] Check webhook delivery
- [ ] Verify billing creation
- [ ] Gather user feedback
- [ ] Document any issues

---

## Success Criteria

✅ Worklist items created automatically on appointment scheduling  
✅ Accession numbers generated correctly  
✅ Modalities can fetch worklist via API  
✅ Images automatically matched to requests  
✅ Status updated to 'completed' when images received  
✅ Billing created automatically  
✅ Radiologist notified of new images  
✅ System handles multiple procedures per bill  
✅ Webhook delivery reliable (>99%)  
✅ No data loss or corruption  

---

## Next Steps

1. **Immediate**: Create worklist controller and routes
2. **Day 2-3**: Integrate with appointment scheduling
3. **Day 4-5**: Create webhook handler
4. **Day 6-7**: Configure Orthanc webhooks
5. **Day 8-10**: Comprehensive testing
6. **Day 11-14**: Deployment and monitoring

---

## Files to Create/Modify

### New Files
- `backend/controller/radiology-worklist.js` - Worklist management
- `backend/controller/radiology-dicom-webhook.js` - Webhook handler
- `backend/routes/radiology-worklist.js` - Worklist routes
- `backend/routes/radiology-modalities.js` - Modality routes

### Modified Files
- `backend/controller/radiology-appointments.js` - Add worklist creation
- `backend/controller/radiology-billing.js` - Add auto-billing trigger
- `backend/app.js` - Register new routes
- `backend/sql/radiology_integrated_workflow_migration.sql` - Add any schema updates

---

## References

- RADIOLOGY_COMPLETE_IMPLEMENTATION_PLAN.md - Full plan
- DICOM_MODALITY_INTEGRATION_GUIDE.md - DICOM setup
- backend/sql/radiology_worklist_schema.sql - Database schema
- backend/services/orthancClient.js - Orthanc integration

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Ready for Implementation
