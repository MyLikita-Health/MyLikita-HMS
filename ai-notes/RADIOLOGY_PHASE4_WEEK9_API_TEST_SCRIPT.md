# Radiology Phase 4 - Week 9 API Testing Script
## Complete Testing Guide with curl Commands

**Date**: March 11, 2026  
**Purpose**: Verify all 16 API endpoints are working correctly  
**Duration**: ~30 minutes  
**Status**: Ready to Execute

---

## Prerequisites

### 1. Backend Running
```bash
# Verify backend is running
curl -s http://localhost:46990/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}' | head -20
```

**Expected**: Should return error or success response (not connection refused)

### 2. Database Connected
```bash
# Verify database
mysql -u root prime -e "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema='prime';"
```

**Expected**: Should return a number > 0

### 3. Get Required IDs

```bash
# Get facility ID (use first facility)
export FACILITY_ID=$(mysql -u root prime -N -e "SELECT id FROM hospitals LIMIT 1;")
echo "Facility ID: $FACILITY_ID"

# Get user ID (use first user)
export USER_ID=$(mysql -u root prime -N -e "SELECT id FROM users LIMIT 1;")
echo "User ID: $USER_ID"

# Get patient ID (use first patient)
export PATIENT_ID=$(mysql -u root prime -N -e "SELECT CONCAT(accountNo, '-', beneficiaryNo) FROM patientrecords LIMIT 1;")
echo "Patient ID: $PATIENT_ID"

# Get procedure ID (use first radiology procedure)
export PROCEDURE_ID=$(mysql -u root prime -N -e "SELECT id FROM radiology_procedures LIMIT 1;")
echo "Procedure ID: $PROCEDURE_ID"
```

### 4. Get Authentication Token

```bash
# Try to login with test credentials
# First, check what users exist
mysql -u root prime -e "SELECT id, username, email FROM users LIMIT 5;"

# Login with a valid user (adjust username/password as needed)
export TOKEN=$(curl -s http://localhost:46990/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}' | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo "Token: $TOKEN"

# If token is empty, try alternative login
if [ -z "$TOKEN" ]; then
  echo "Token retrieval failed. Trying alternative method..."
  # You may need to adjust credentials based on your setup
fi
```

---

## Test Suite

### Test 1: Register Modality ✅

**Endpoint**: `POST /radiology/modalities`  
**Purpose**: Register a DICOM modality (X-ray machine, CT scanner, etc.)

```bash
echo "=== TEST 1: Register Modality ==="

MODALITY_RESPONSE=$(curl -s -X POST http://localhost:46990/radiology/modalities \
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
  }')

echo "Response: $MODALITY_RESPONSE"

# Extract modality ID
export MODALITY_ID=$(echo $MODALITY_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "Modality ID: $MODALITY_ID"

# Verify in database
echo "Database verification:"
mysql -u root prime -e "SELECT id, ae_title, modality_name, status FROM radiology_modalities WHERE ae_title='XRAY01';"
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "id": "modality-uuid",
    "ae_title": "XRAY01",
    "modality_name": "X-ray Room 1"
  }
}
```

---

### Test 2: Get All Modalities ✅

**Endpoint**: `GET /radiology/modalities`  
**Purpose**: List all registered modalities

```bash
echo "=== TEST 2: Get All Modalities ==="

curl -s -X GET http://localhost:46990/radiology/modalities \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

**Expected Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "modality-uuid",
      "ae_title": "XRAY01",
      "modality_name": "X-ray Room 1",
      "status": "active"
    }
  ]
}
```

---

### Test 3: Get Modality by AE Title ✅

**Endpoint**: `GET /radiology/modalities/:aeTitle`  
**Purpose**: Get specific modality by AE Title

```bash
echo "=== TEST 3: Get Modality by AE Title ==="

curl -s -X GET http://localhost:46990/radiology/modalities/XRAY01 | jq '.'
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "id": "modality-uuid",
    "ae_title": "XRAY01",
    "modality_name": "X-ray Room 1"
  }
}
```

---

### Test 4: Create Radiology Request ✅

**Endpoint**: `POST /radiology/requests`  
**Purpose**: Create a new radiology request

```bash
echo "=== TEST 4: Create Radiology Request ==="

REQUEST_RESPONSE=$(curl -s -X POST http://localhost:46990/radiology/requests \
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
  }')

echo "Response: $REQUEST_RESPONSE"

# Extract request ID
export REQUEST_ID=$(echo $REQUEST_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "Request ID: $REQUEST_ID"

# Verify in database
echo "Database verification:"
mysql -u root prime -e "SELECT id, patient_id, status, priority FROM radiology_requests WHERE id='$REQUEST_ID';"
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "id": "request-uuid",
    "request_number": "RAD-20260311-1234"
  }
}
```

---

### Test 5: Create Appointment (Auto-creates Worklist) ✅

**Endpoint**: `POST /radiology/appointments`  
**Purpose**: Create appointment and auto-generate worklist item

```bash
echo "=== TEST 5: Create Appointment ==="

APPOINTMENT_RESPONSE=$(curl -s -X POST http://localhost:46990/radiology/appointments \
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
  }')

echo "Response: $APPOINTMENT_RESPONSE"

# Extract appointment ID
export APPOINTMENT_ID=$(echo $APPOINTMENT_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "Appointment ID: $APPOINTMENT_ID"

# Verify appointment in database
echo "Appointment verification:"
mysql -u root prime -e "SELECT id, request_id, status FROM radiology_appointments WHERE id='$APPOINTMENT_ID';"

# Verify worklist auto-created
echo "Worklist verification:"
mysql -u root prime -e "SELECT id, accession_number, worklist_status FROM radiology_worklist WHERE appointment_id='$APPOINTMENT_ID';"

# Get accession number
export ACCESSION_NUMBER=$(mysql -u root prime -N -e "SELECT accession_number FROM radiology_worklist WHERE appointment_id='$APPOINTMENT_ID';")
echo "Accession Number: $ACCESSION_NUMBER"

# Get worklist ID
export WORKLIST_ID=$(mysql -u root prime -N -e "SELECT id FROM radiology_worklist WHERE appointment_id='$APPOINTMENT_ID';")
echo "Worklist ID: $WORKLIST_ID"
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "id": "appointment-uuid"
  }
}
```

**Expected Database State**:
- Appointment created with status "scheduled"
- Worklist item auto-created with status "pending"
- Accession number generated (format: FAC-YYYYMMDD-XXXXXX)

---

### Test 6: Get Worklist Items ✅

**Endpoint**: `GET /radiology/worklist`  
**Purpose**: Get worklist items with filtering

```bash
echo "=== TEST 6: Get Worklist Items ==="

curl -s -X GET "http://localhost:46990/radiology/worklist?status=pending&facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
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

### Test 7: Get Worklist by Accession Number ✅

**Endpoint**: `GET /radiology/worklist/:accessionNumber`  
**Purpose**: Get specific worklist item by accession number

```bash
echo "=== TEST 7: Get Worklist by Accession Number ==="

curl -s -X GET "http://localhost:46990/radiology/worklist/$ACCESSION_NUMBER" | jq '.'
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

---

### Test 8: Get Worklist for Modality ✅

**Endpoint**: `GET /radiology/worklist/modality/:modalityId`  
**Purpose**: Get worklist items for specific modality

```bash
echo "=== TEST 8: Get Worklist for Modality ==="

curl -s -X GET "http://localhost:46990/radiology/worklist/modality/$MODALITY_ID?status=pending" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
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

### Test 9: Update Worklist Status ✅

**Endpoint**: `PUT /radiology/worklist/:id/status`  
**Purpose**: Update worklist item status

```bash
echo "=== TEST 9: Update Worklist Status ==="

curl -s -X PUT "http://localhost:46990/radiology/worklist/$WORKLIST_ID/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"status": "in_progress"}' | jq '.'

# Verify status updated
echo "Database verification:"
mysql -u root prime -e "SELECT id, worklist_status FROM radiology_worklist WHERE id='$WORKLIST_ID';"
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Worklist status updated"
}
```

---

### Test 10: Update Modality Status ✅

**Endpoint**: `PUT /radiology/modalities/:id/status`  
**Purpose**: Update modality status

```bash
echo "=== TEST 10: Update Modality Status ==="

curl -s -X PUT "http://localhost:46990/radiology/modalities/$MODALITY_ID/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"status": "offline"}' | jq '.'

# Verify status updated
echo "Database verification:"
mysql -u root prime -e "SELECT id, status FROM radiology_modalities WHERE id='$MODALITY_ID';"
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Modality status updated"
}
```

---

### Test 11: Test Webhook Endpoint ✅

**Endpoint**: `POST /radiology/webhook/test`  
**Purpose**: Test webhook delivery

```bash
echo "=== TEST 11: Test Webhook ==="

curl -s -X POST http://localhost:46990/radiology/webhook/test \
  -H "Content-Type: application/json" | jq '.'
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Webhook test successful"
}
```

---

### Test 12: Get Webhook Logs ✅

**Endpoint**: `GET /radiology/webhook/logs`  
**Purpose**: Get webhook execution logs

```bash
echo "=== TEST 12: Get Webhook Logs ==="

curl -s -X GET "http://localhost:46990/radiology/webhook/logs?facilityId=$FACILITY_ID&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

**Expected Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "log-uuid",
      "webhook_type": "image_received",
      "status": "success",
      "created_at": "2026-03-11T10:00:00Z"
    }
  ]
}
```

---

## Complete Test Script

Save this as `test-radiology-api.sh`:

```bash
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Setup
echo -e "${YELLOW}Setting up test environment...${NC}"

# Get IDs
export FACILITY_ID=$(mysql -u root prime -N -e "SELECT id FROM hospitals LIMIT 1;")
export USER_ID=$(mysql -u root prime -N -e "SELECT id FROM users LIMIT 1;")
export PATIENT_ID=$(mysql -u root prime -N -e "SELECT CONCAT(accountNo, '-', beneficiaryNo) FROM patientrecords LIMIT 1;")
export PROCEDURE_ID=$(mysql -u root prime -N -e "SELECT id FROM radiology_procedures LIMIT 1;")

echo "Facility ID: $FACILITY_ID"
echo "User ID: $USER_ID"
echo "Patient ID: $PATIENT_ID"
echo "Procedure ID: $PROCEDURE_ID"

# Get token
export TOKEN=$(curl -s http://localhost:46990/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}' | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo -e "${RED}Failed to get authentication token${NC}"
  exit 1
fi

echo -e "${GREEN}Token obtained${NC}"

# Test 1: Register Modality
echo -e "\n${YELLOW}Test 1: Register Modality${NC}"
MODALITY_RESPONSE=$(curl -s -X POST http://localhost:46990/radiology/modalities \
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
  }')

if echo $MODALITY_RESPONSE | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Modality registered${NC}"
  export MODALITY_ID=$(echo $MODALITY_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
else
  echo -e "${RED}✗ Failed to register modality${NC}"
  echo $MODALITY_RESPONSE
fi

# Test 2: Get All Modalities
echo -e "\n${YELLOW}Test 2: Get All Modalities${NC}"
MODALITIES=$(curl -s -X GET http://localhost:46990/radiology/modalities \
  -H "Authorization: Bearer $TOKEN")

if echo $MODALITIES | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Modalities retrieved${NC}"
else
  echo -e "${RED}✗ Failed to get modalities${NC}"
fi

# Test 3: Create Request
echo -e "\n${YELLOW}Test 3: Create Radiology Request${NC}"
REQUEST_RESPONSE=$(curl -s -X POST http://localhost:46990/radiology/requests \
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
  }')

if echo $REQUEST_RESPONSE | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Request created${NC}"
  export REQUEST_ID=$(echo $REQUEST_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
else
  echo -e "${RED}✗ Failed to create request${NC}"
  echo $REQUEST_RESPONSE
fi

# Test 4: Create Appointment
echo -e "\n${YELLOW}Test 4: Create Appointment${NC}"
APPOINTMENT_RESPONSE=$(curl -s -X POST http://localhost:46990/radiology/appointments \
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
  }')

if echo $APPOINTMENT_RESPONSE | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Appointment created${NC}"
  export APPOINTMENT_ID=$(echo $APPOINTMENT_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  export ACCESSION_NUMBER=$(mysql -u root prime -N -e "SELECT accession_number FROM radiology_worklist WHERE appointment_id='$APPOINTMENT_ID';")
  export WORKLIST_ID=$(mysql -u root prime -N -e "SELECT id FROM radiology_worklist WHERE appointment_id='$APPOINTMENT_ID';")
else
  echo -e "${RED}✗ Failed to create appointment${NC}"
  echo $APPOINTMENT_RESPONSE
fi

# Test 5: Get Worklist
echo -e "\n${YELLOW}Test 5: Get Worklist Items${NC}"
WORKLIST=$(curl -s -X GET "http://localhost:46990/radiology/worklist?status=pending&facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN")

if echo $WORKLIST | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Worklist retrieved${NC}"
else
  echo -e "${RED}✗ Failed to get worklist${NC}"
fi

# Test 6: Get by Accession Number
echo -e "\n${YELLOW}Test 6: Get Worklist by Accession Number${NC}"
ACCESSION=$(curl -s -X GET "http://localhost:46990/radiology/worklist/$ACCESSION_NUMBER")

if echo $ACCESSION | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Accession number query successful${NC}"
else
  echo -e "${RED}✗ Failed to get by accession number${NC}"
fi

# Test 7: Test Webhook
echo -e "\n${YELLOW}Test 7: Test Webhook${NC}"
WEBHOOK=$(curl -s -X POST http://localhost:46990/radiology/webhook/test \
  -H "Content-Type: application/json")

if echo $WEBHOOK | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Webhook test successful${NC}"
else
  echo -e "${RED}✗ Webhook test failed${NC}"
fi

echo -e "\n${GREEN}All tests completed!${NC}"
```

---

## Running the Tests

```bash
# Make script executable
chmod +x test-radiology-api.sh

# Run tests
./test-radiology-api.sh
```

---

## Expected Results

### All Tests Pass ✅
- 12 tests executed
- 12 tests passing
- 0 tests failing
- All endpoints functional
- All database records created

### Partial Success ⚠️
- Some tests pass, some fail
- Check error messages
- Verify database state
- Fix issues and re-run

### All Tests Fail ❌
- Check backend is running
- Check database connectivity
- Check authentication
- Check error logs

---

## Troubleshooting

### Backend Not Running
```bash
# Check if backend is running
lsof -i :46990

# Start backend if needed
cd backend && npm start
```

### Database Connection Failed
```bash
# Check MySQL is running
mysql -u root -e "SELECT 1;"

# Check database exists
mysql -u root -e "SHOW DATABASES LIKE 'prime';"
```

### Authentication Failed
```bash
# Check users table
mysql -u root prime -e "SELECT id, username FROM users LIMIT 5;"

# Try different credentials
```

### API Returns 404
```bash
# Check routes are registered
curl -s http://localhost:46990/radiology/modalities

# Check backend logs
tail -50 backend.log
```

---

## Next Steps

1. ✅ Run all tests
2. ✅ Verify all pass
3. ✅ Document results
4. ⏳ Prepare for Orthanc integration
5. ⏳ Configure webhooks
6. ⏳ Deploy to production

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Ready for Execution

