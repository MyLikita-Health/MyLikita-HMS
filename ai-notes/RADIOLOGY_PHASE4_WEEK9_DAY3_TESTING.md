# Radiology Phase 4 - Week 9 Day 3 Testing
## Unit Tests Execution

**Date**: March 11, 2026  
**Day**: 3 of 10  
**Status**: Ready to Execute  
**Focus**: Unit Testing - Individual Functions

---

## Pre-Testing Setup

### Get Authentication Token

```bash
# Login to get token
curl -X POST http://localhost:46990/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "password"
  }'

# Save token
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### Get Required IDs

```bash
# Get facility ID
curl -X GET http://localhost:46990/hospitals \
  -H "Authorization: Bearer $TOKEN"

export FACILITY_ID="facility-uuid"

# Get patient ID
curl -X GET "http://localhost:46990/patientrecords?facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN"

export PATIENT_ID="7-1"

# Get procedure ID
curl -X GET "http://localhost:46990/radiology/procedures?facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN"

export PROCEDURE_ID="procedure-uuid"

# Get user ID
export USER_ID="user-uuid"
```

---

## Morning Tests (3 hours)

### Test 1: Register Modality ✅

**Objective**: Test modality registration

**Command**:
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

**Verification**:
```bash
# Save modality ID
export MODALITY_ID="modality-uuid"

# Verify in database
mysql -u root prime -e "SELECT * FROM radiology_modalities WHERE ae_title='XRAY01';"
```

**Status**: ⏳ Ready to Execute

---

### Test 2: Create Radiology Request ✅

**Objective**: Test request creation

**Command**:
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

**Verification**:
```bash
# Save request ID
export REQUEST_ID="request-uuid"

# Verify in database
mysql -u root prime -e "SELECT * FROM radiology_requests WHERE id='$REQUEST_ID';"
```

**Status**: ⏳ Ready to Execute

---

### Test 3: Create Appointment (Auto-creates Worklist) ✅

**Objective**: Test appointment creation and auto-worklist generation

**Command**:
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

**Verification**:
```bash
# Save appointment ID
export APPOINTMENT_ID="appointment-uuid"

# Verify appointment created
mysql -u root prime -e "SELECT * FROM radiology_appointments WHERE id='$APPOINTMENT_ID';"

# Verify worklist auto-created
mysql -u root prime -e "SELECT * FROM radiology_worklist WHERE appointment_id='$APPOINTMENT_ID';"

# Save accession number
export ACCESSION_NUMBER=$(mysql -u root prime -N -e "SELECT accession_number FROM radiology_worklist WHERE appointment_id='$APPOINTMENT_ID';")

# Save worklist ID
export WORKLIST_ID=$(mysql -u root prime -N -e "SELECT id FROM radiology_worklist WHERE appointment_id='$APPOINTMENT_ID';")
```

**Status**: ⏳ Ready to Execute

---

## Afternoon Tests (3 hours)

### Test 4: Get Worklist Items ✅

**Objective**: Test worklist listing

**Command**:
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
      "patient_name": "John Doe",
      "procedure_description": "Chest X-ray",
      "scheduled_date": "2026-03-11 10:00:00",
      "worklist_status": "pending"
    }
  ]
}
```

**Verification**:
- [ ] Worklist items returned
- [ ] Accession number present
- [ ] Status is pending
- [ ] Patient information correct

**Status**: ⏳ Ready to Execute

---

### Test 5: Get Worklist by Accession Number ✅

**Objective**: Test accession number query

**Command**:
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
    "procedure_description": "Chest X-ray",
    "scheduled_date": "2026-03-11 10:00:00",
    "worklist_status": "pending"
  }
}
```

**Verification**:
- [ ] Worklist item returned
- [ ] Accession number matches
- [ ] All patient information present
- [ ] Status is pending

**Status**: ⏳ Ready to Execute

---

### Test 6: Get Worklist for Modality ✅

**Objective**: Test modality-specific worklist query

**Command**:
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

**Verification**:
- [ ] Worklist items returned
- [ ] Items are for correct modality
- [ ] Status is pending
- [ ] Patient information correct

**Status**: ⏳ Ready to Execute

---

## Test Results Summary

### Test 1: Register Modality
- Status: ⏳ Pending
- Expected: Success
- Actual: [To be filled]

### Test 2: Create Request
- Status: ⏳ Pending
- Expected: Success
- Actual: [To be filled]

### Test 3: Create Appointment
- Status: ⏳ Pending
- Expected: Success + Auto-worklist
- Actual: [To be filled]

### Test 4: Get Worklist
- Status: ⏳ Pending
- Expected: Success
- Actual: [To be filled]

### Test 5: Get by Accession
- Status: ⏳ Pending
- Expected: Success
- Actual: [To be filled]

### Test 6: Get for Modality
- Status: ⏳ Pending
- Expected: Success
- Actual: [To be filled]

---

## Database Verification

### Check Modalities Table
```bash
mysql -u root prime -e "SELECT * FROM radiology_modalities WHERE facilityId='$FACILITY_ID';"
```

### Check Requests Table
```bash
mysql -u root prime -e "SELECT * FROM radiology_requests WHERE id='$REQUEST_ID';"
```

### Check Appointments Table
```bash
mysql -u root prime -e "SELECT * FROM radiology_appointments WHERE id='$APPOINTMENT_ID';"
```

### Check Worklist Table
```bash
mysql -u root prime -e "SELECT * FROM radiology_worklist WHERE accession_number='$ACCESSION_NUMBER';"
```

---

## Day 3 Summary

### Tests Completed
- [ ] Test 1: Register Modality
- [ ] Test 2: Create Request
- [ ] Test 3: Create Appointment
- [ ] Test 4: Get Worklist
- [ ] Test 5: Get by Accession
- [ ] Test 6: Get for Modality

### Expected Outcomes
- ✅ All tests passing
- ✅ Data stored correctly
- ✅ No errors in logs
- ✅ Database verified

### Next Steps (Day 4)
- Integration tests
- Workflow testing
- Data flow verification

---

## Approval Checklist

- [ ] All 6 unit tests executed
- [ ] All tests passing
- [ ] Database verified
- [ ] No errors in logs
- [ ] Ready for Day 4 integration tests

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Day 3 Ready for Execution
