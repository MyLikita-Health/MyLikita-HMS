# Radiology Phase 4 - Testing Guide
## DICOM Worklist Implementation Testing

**Date**: March 11, 2026  
**Status**: Ready for Testing  
**Backend Port**: 46990  
**Database**: MySQL (prime)

---

## Prerequisites

### Required Information
- Backend URL: `http://localhost:46990`
- Facility ID: Get from your facility setup
- User Token: Get from login endpoint
- Patient ID: Format `accountNo-beneficiaryNo` (e.g., "7-1")

### Tools
- Postman or curl
- MySQL client
- Text editor

---

## Test Setup

### 1. Get Authentication Token

```bash
curl -X POST http://localhost:46990/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "password"
  }'
```

**Response**:
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user-uuid",
      "username": "admin",
      "facilityId": "facility-uuid"
    }
  }
}
```

**Save**: `TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 2. Get Facility ID

```bash
curl -X GET http://localhost:46990/hospitals \
  -H "Authorization: Bearer $TOKEN"
```

**Save**: `FACILITY_ID=facility-uuid`

### 3. Get Patient ID

```bash
curl -X GET "http://localhost:46990/patientrecords?facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN"
```

**Save**: `PATIENT_ID=7-1`

### 4. Get Procedure ID

```bash
curl -X GET "http://localhost:46990/radiology/procedures?facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN"
```

**Save**: `PROCEDURE_ID=procedure-uuid`

---

## Test Cases

### Test 1: Register Modality

**Endpoint**: `POST /radiology/modalities`

**Request**:
```bash
curl -X POST http://localhost:46990/radiology/modalities \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "modality_name": "X-ray Room 1",
    "modality_type": "XR",
    "ae_title": "XRAY01",
    "ip_address": "192.168.1.100",
    "port": 104,
    "manufacturer": "Siemens",
    "model": "AXIOM Luminos",
    "room_location": "Ground Floor - Room 1",
    "facilityId": "'$FACILITY_ID'"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "id": "modality-uuid",
    "ae_title": "XRAY01",
    "modality_name": "X-ray Room 1"
  },
  "message": "Modality registered successfully"
}
```

**Save**: `MODALITY_ID=modality-uuid`

**Verification**:
```bash
# Verify in database
mysql -u root prime -e "SELECT * FROM radiology_modalities WHERE ae_title='XRAY01';"
```

---

### Test 2: Create Radiology Request

**Endpoint**: `POST /radiology/requests`

**Request**:
```bash
curl -X POST http://localhost:46990/radiology/requests \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "patient_id": "'$PATIENT_ID'",
    "requesting_doctor_id": "'$USER_ID'",
    "procedure_id": "'$PROCEDURE_ID'",
    "priority": "routine",
    "clinical_indication": "Suspected pneumonia",
    "clinical_notes": "Patient has fever and cough",
    "special_instructions": "Upright position",
    "contrast_required": false,
    "requested_date": "2026-03-11",
    "facilityId": "'$FACILITY_ID'",
    "created_by": "'$USER_ID'"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "id": "request-uuid",
    "request_number": "RAD-20260311-1234"
  },
  "message": "Request created successfully"
}
```

**Save**: `REQUEST_ID=request-uuid`

---

### Test 3: Create Appointment (Auto-creates Worklist)

**Endpoint**: `POST /radiology/appointments`

**Request**:
```bash
curl -X POST http://localhost:46990/radiology/appointments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "request_id": "'$REQUEST_ID'",
    "patient_id": "'$PATIENT_ID'",
    "procedure_id": "'$PROCEDURE_ID'",
    "appointment_date": "2026-03-11 10:00:00",
    "duration_minutes": 30,
    "room_number": "1",
    "technician_id": "'$USER_ID'",
    "radiologist_id": "'$USER_ID'",
    "notes": "Standard chest X-ray",
    "facilityId": "'$FACILITY_ID'"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "id": "appointment-uuid"
  },
  "message": "Appointment created successfully"
}
```

**Save**: `APPOINTMENT_ID=appointment-uuid`

**Verification** - Worklist should be auto-created:
```bash
# Check worklist was created
curl -X GET "http://localhost:46990/radiology/worklist?status=pending&facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN"
```

---

### Test 4: Get Worklist Items

**Endpoint**: `GET /radiology/worklist`

**Request**:
```bash
curl -X GET "http://localhost:46990/radiology/worklist?status=pending&facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "worklist-uuid",
      "accession_number": "FAC-20260311-000001",
      "request_id": "request-uuid",
      "appointment_id": "appointment-uuid",
      "patient_id": "7-1",
      "procedure_id": "procedure-uuid",
      "patient_name": "John Doe",
      "patient_dob": "1990-05-15",
      "patient_sex": "M",
      "patient_age": 35,
      "procedure_code": "CHEST-XR",
      "procedure_description": "Chest X-ray",
      "body_part": "Chest",
      "modality": "XR",
      "scheduled_date": "2026-03-11 10:00:00",
      "scheduled_ae_title": "XRAY01",
      "requesting_physician": "Dr. Smith",
      "clinical_indication": "Suspected pneumonia",
      "special_instructions": "Upright position",
      "worklist_status": "pending",
      "exported_to_orthanc": false
    }
  ]
}
```

**Save**: `WORKLIST_ID=worklist-uuid`, `ACCESSION_NUMBER=FAC-20260311-000001`

---

### Test 5: Get Worklist by Accession Number

**Endpoint**: `GET /radiology/worklist/:accessionNumber`

**Request**:
```bash
curl -X GET "http://localhost:46990/radiology/worklist/$ACCESSION_NUMBER"
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "id": "worklist-uuid",
    "accession_number": "FAC-20260311-000001",
    "patient_name": "John Doe",
    "patient_mrn": "7-1",
    "patient_dob": "1990-05-15",
    "patient_sex": "M",
    "patient_age": 35,
    "procedure_code": "CHEST-XR",
    "procedure_description": "Chest X-ray",
    "body_part": "Chest",
    "modality": "XR",
    "scheduled_date": "2026-03-11 10:00:00",
    "scheduled_ae_title": "XRAY01",
    "requesting_physician": "Dr. Smith",
    "clinical_indication": "Suspected pneumonia",
    "special_instructions": "Upright position",
    "worklist_status": "pending"
  }
}
```

---

### Test 6: Get Worklist for Modality

**Endpoint**: `GET /radiology/worklist/modality/:modalityId`

**Request**:
```bash
curl -X GET "http://localhost:46990/radiology/worklist/modality/$MODALITY_ID?status=pending" \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "worklist-uuid",
      "accession_number": "FAC-20260311-000001",
      "patient_name": "John Doe",
      "procedure_description": "Chest X-ray",
      "scheduled_date": "2026-03-11 10:00:00",
      "worklist_status": "pending"
    }
  ]
}
```

---

### Test 7: Export Worklist to Orthanc

**Endpoint**: `POST /radiology/worklist/:id/export`

**Request**:
```bash
curl -X POST "http://localhost:46990/radiology/worklist/$WORKLIST_ID/export" \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "exported": true,
    "export_date": "2026-03-11 10:00:00",
    "orthanc_path": "/var/lib/orthanc/worklists/FAC-20260311-000001.json",
    "accession_number": "FAC-20260311-000001"
  },
  "message": "Worklist exported to Orthanc"
}
```

**Verification** - Check JSON file:
```bash
# Verify file exists
ls -la /var/lib/orthanc/worklists/FAC-20260311-000001.json

# View file content
cat /var/lib/orthanc/worklists/FAC-20260311-000001.json
```

---

### Test 8: Update Worklist Status

**Endpoint**: `PUT /radiology/worklist/:id/status`

**Request**:
```bash
curl -X PUT "http://localhost:46990/radiology/worklist/$WORKLIST_ID/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "status": "in-progress"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Worklist status updated"
}
```

**Verification**:
```bash
# Check status updated
curl -X GET "http://localhost:46990/radiology/worklist?status=in-progress&facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN"
```

---

### Test 9: Get All Modalities

**Endpoint**: `GET /radiology/modalities`

**Request**:
```bash
curl -X GET "http://localhost:46990/radiology/modalities?facilityId=$FACILITY_ID&status=active" \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "modality-uuid",
      "modality_name": "X-ray Room 1",
      "modality_type": "XR",
      "ae_title": "XRAY01",
      "ip_address": "192.168.1.100",
      "port": 104,
      "status": "active",
      "last_connection": null
    }
  ]
}
```

---

### Test 10: Update Modality Status

**Endpoint**: `PUT /radiology/modalities/:id/status`

**Request**:
```bash
curl -X PUT "http://localhost:46990/radiology/modalities/$MODALITY_ID/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "status": "active"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Modality status updated"
}
```

---

### Test 11: Test Webhook

**Endpoint**: `POST /radiology/webhook/test`

**Request**:
```bash
curl -X POST http://localhost:46990/radiology/webhook/test \
  -H "Content-Type: application/json"
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Webhook test successful"
}
```

---

### Test 12: Simulate Image Received

**Endpoint**: `POST /radiology/webhook/image-received`

**Request**:
```bash
curl -X POST http://localhost:46990/radiology/webhook/image-received \
  -H "Content-Type: application/json" \
  -d '{
    "studyUID": "1.2.3.4.5",
    "patientID": "'$PATIENT_ID'",
    "patientName": "John Doe",
    "modality": "XR",
    "studyDate": "20260311",
    "studyTime": "100000",
    "numberOfImages": 3,
    "accessionNumber": "'$ACCESSION_NUMBER'",
    "facilityId": "'$FACILITY_ID'"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "request_id": "request-uuid",
    "study_uid": "1.2.3.4.5",
    "status_updated": true,
    "billing_updated": true,
    "notification_sent": true
  },
  "message": "Image received and processed successfully"
}
```

**Verification** - Check status updates:
```bash
# Check request status
mysql -u root prime -e "SELECT id, status FROM radiology_requests WHERE id='$REQUEST_ID';"

# Check worklist status
mysql -u root prime -e "SELECT id, worklist_status FROM radiology_worklist WHERE accession_number='$ACCESSION_NUMBER';"

# Check billing status
mysql -u root prime -e "SELECT id, payment_status FROM radiology_billing WHERE request_id='$REQUEST_ID';"
```

---

## Database Verification Queries

### Check Worklist Table
```sql
SELECT 
  id, accession_number, patient_name, procedure_description,
  scheduled_date, worklist_status, exported_to_orthanc
FROM radiology_worklist
WHERE facilityId = 'facility-uuid'
ORDER BY created_at DESC;
```

### Check Modalities Table
```sql
SELECT 
  id, modality_name, modality_type, ae_title, 
  ip_address, port, status, last_connection
FROM radiology_modalities
WHERE facilityId = 'facility-uuid'
ORDER BY created_at DESC;
```

### Check DICOM Studies
```sql
SELECT 
  id, request_id, study_uid, patient_id, modality,
  number_of_images, status
FROM radiology_dicom_studies
WHERE facilityId = 'facility-uuid'
ORDER BY created_at DESC;
```

### Check Billing Updates
```sql
SELECT 
  id, request_id, payment_status, images_received_date
FROM radiology_billing
WHERE request_id IN (
  SELECT id FROM radiology_requests 
  WHERE facilityId = 'facility-uuid'
)
ORDER BY created_at DESC;
```

---

## Performance Testing

### Measure Accession Number Generation
```bash
time curl -X POST http://localhost:46990/radiology/appointments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{...}'
```

### Measure Worklist Query
```bash
time curl -X GET "http://localhost:46990/radiology/worklist?status=pending&facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN"
```

### Measure Webhook Processing
```bash
time curl -X POST http://localhost:46990/radiology/webhook/image-received \
  -H "Content-Type: application/json" \
  -d '{...}'
```

---

## Error Scenarios

### Test 1: Invalid Appointment ID
```bash
curl -X POST http://localhost:46990/radiology/worklist \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "appointment_id": "invalid-uuid",
    "modality_id": "'$MODALITY_ID'",
    "facilityId": "'$FACILITY_ID'"
  }'
```

**Expected**: 404 error - Appointment not found

### Test 2: Duplicate AE Title
```bash
curl -X POST http://localhost:46990/radiology/modalities \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "modality_name": "X-ray Room 2",
    "modality_type": "XR",
    "ae_title": "XRAY01",  # Already exists
    "ip_address": "192.168.1.101",
    "port": 104,
    "facilityId": "'$FACILITY_ID'"
  }'
```

**Expected**: 400 error - AE Title already registered

### Test 3: Missing Required Fields
```bash
curl -X POST http://localhost:46990/radiology/modalities \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "modality_name": "X-ray Room 3"
    # Missing modality_type, ae_title, etc.
  }'
```

**Expected**: 400 error - Missing required fields

---

## Test Summary Template

```
Test Date: 2026-03-11
Tester: [Name]
Backend Version: [Version]
Database: MySQL prime

Test Results:
- Test 1 (Register Modality): ✅ PASS / ❌ FAIL
- Test 2 (Create Request): ✅ PASS / ❌ FAIL
- Test 3 (Create Appointment): ✅ PASS / ❌ FAIL
- Test 4 (Get Worklist): ✅ PASS / ❌ FAIL
- Test 5 (Get by Accession): ✅ PASS / ❌ FAIL
- Test 6 (Get for Modality): ✅ PASS / ❌ FAIL
- Test 7 (Export to Orthanc): ✅ PASS / ❌ FAIL
- Test 8 (Update Status): ✅ PASS / ❌ FAIL
- Test 9 (Get Modalities): ✅ PASS / ❌ FAIL
- Test 10 (Update Modality): ✅ PASS / ❌ FAIL
- Test 11 (Test Webhook): ✅ PASS / ❌ FAIL
- Test 12 (Image Received): ✅ PASS / ❌ FAIL

Performance:
- Accession generation: [time]ms
- Worklist query: [time]ms
- Webhook processing: [time]ms

Issues Found:
[List any issues]

Notes:
[Any additional notes]
```

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Ready for Testing
