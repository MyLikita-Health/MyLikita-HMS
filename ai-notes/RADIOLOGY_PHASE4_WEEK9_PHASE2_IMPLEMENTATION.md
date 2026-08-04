# Radiology Phase 4 - Week 9 Phase 2 Implementation
## Complete Orthanc Configuration & Testing

**Date**: March 11, 2026  
**Phase**: 2 of 3  
**Status**: Ready to Execute  
**Estimated Time**: 4 hours

---

## Phase 2 Implementation Plan

### Part 1: Orthanc Configuration (30 minutes)

#### Step 1: Backup Configuration
```bash
# Create backup
cp /etc/orthanc/orthanc.json /etc/orthanc/orthanc.json.backup

# Verify
ls -la /etc/orthanc/orthanc.json*
```

#### Step 2: Add Webhook Configuration
```bash
# Edit configuration
nano /etc/orthanc/orthanc.json

# Add this section (find a good place after existing config):
"Webhooks": {
  "ImageReceived": "http://backend:46990/radiology/webhook/image-received",
  "ImageStored": "http://backend:46990/radiology/webhook/image-stored",
  "StudyCompleted": "http://backend:46990/radiology/webhook/study-completed",
  "ModalityStatus": "http://localhost:46990/radiology/webhook/modality-status"
},
```

#### Step 3: Add Worklist Configuration
```bash
# Add this section:
"ServeFolders": {
  "/worklists": "/var/lib/orthanc/worklists"
},
```

#### Step 4: Add DicomWeb Configuration
```bash
# Add this section:
"DicomWeb": {
  "Enable": true,
  "PublicUrl": "http://localhost:8042/dicom-web/"
},
```

#### Step 5: Verify Configuration
```bash
# Check JSON syntax
cat /etc/orthanc/orthanc.json | python -m json.tool > /dev/null && echo "Valid JSON"

# Verify sections
grep -A 10 "Webhooks" /etc/orthanc/orthanc.json
grep -A 3 "ServeFolders" /etc/orthanc/orthanc.json
grep -A 3 "DicomWeb" /etc/orthanc/orthanc.json
```

#### Step 6: Create Worklist Directory
```bash
# Create directory
mkdir -p /var/lib/orthanc/worklists

# Set permissions
chmod 755 /var/lib/orthanc/worklists

# Verify
ls -la /var/lib/orthanc/worklists
```

#### Step 7: Restart Orthanc
```bash
# Restart service
systemctl restart orthanc

# Wait for startup
sleep 5

# Verify running
curl -X GET http://localhost:8042/system | jq '.'
```

---

### Part 2: Integration Testing (30 minutes)

#### Setup: Get Required IDs
```bash
#!/bin/bash

# Get facility ID
export FACILITY_ID=$(mysql -u root prime -N -e "SELECT id FROM hospitals LIMIT 1;")
echo "Facility ID: $FACILITY_ID"

# Get user ID
export USER_ID=$(mysql -u root prime -N -e "SELECT id FROM users LIMIT 1;")
echo "User ID: $USER_ID"

# Get patient ID
export PATIENT_ID=$(mysql -u root prime -N -e "SELECT CONCAT(accountNo, '-', beneficiaryNo) FROM patientrecords LIMIT 1;")
echo "Patient ID: $PATIENT_ID"

# Get procedure ID
export PROCEDURE_ID=$(mysql -u root prime -N -e "SELECT id FROM radiology_procedures LIMIT 1;")
echo "Procedure ID: $PROCEDURE_ID"

# Get authentication token
export TOKEN=$(curl -s http://localhost:46990/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}' | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo "Token: $TOKEN"
```

#### Test 1: Webhook Connectivity
```bash
echo "=== Test 1: Webhook Connectivity ==="

curl -X POST http://localhost:46990/radiology/webhook/test \
  -H "Content-Type: application/json" | jq '.'

# Expected: {"success":true,"message":"Webhook test successful"}
```

#### Test 2: Register Modality
```bash
echo "=== Test 2: Register Modality ==="

MODALITY=$(curl -s -X POST http://localhost:46990/radiology/modalities \
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

echo $MODALITY | jq '.'

# Extract modality ID
export MODALITY_ID=$(echo $MODALITY | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "Modality ID: $MODALITY_ID"

# Verify in database
echo "Database verification:"
mysql -u root prime -e "SELECT id, ae_title, modality_name, status FROM radiology_modalities WHERE ae_title='XRAY01';"
```

#### Test 3: Create Request
```bash
echo "=== Test 3: Create Request ==="

REQUEST=$(curl -s -X POST http://localhost:46990/radiology/requests \
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

echo $REQUEST | jq '.'

# Extract request ID
export REQUEST_ID=$(echo $REQUEST | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "Request ID: $REQUEST_ID"

# Verify in database
echo "Database verification:"
mysql -u root prime -e "SELECT id, patient_id, status FROM radiology_requests WHERE id='$REQUEST_ID';"
```

#### Test 4: Create Appointment (Auto-creates Worklist)
```bash
echo "=== Test 4: Create Appointment ==="

APPOINTMENT=$(curl -s -X POST http://localhost:46990/radiology/appointments \
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

echo $APPOINTMENT | jq '.'

# Extract appointment ID
export APPOINTMENT_ID=$(echo $APPOINTMENT | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "Appointment ID: $APPOINTMENT_ID"

# Verify appointment created
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

#### Test 5: Get Worklist Items
```bash
echo "=== Test 5: Get Worklist Items ==="

curl -s -X GET "http://localhost:46990/radiology/worklist?status=pending&facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

#### Test 6: Get by Accession Number
```bash
echo "=== Test 6: Get by Accession Number ==="

curl -s -X GET "http://localhost:46990/radiology/worklist/$ACCESSION_NUMBER" | jq '.'
```

#### Test 7: Get for Modality
```bash
echo "=== Test 7: Get for Modality ==="

curl -s -X GET "http://localhost:46990/radiology/worklist/modality/$MODALITY_ID?status=pending" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

#### Test 8: Update Worklist Status
```bash
echo "=== Test 8: Update Worklist Status ==="

curl -s -X PUT "http://localhost:46990/radiology/worklist/$WORKLIST_ID/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"status": "in_progress"}' | jq '.'

# Verify status updated
echo "Database verification:"
mysql -u root prime -e "SELECT id, worklist_status FROM radiology_worklist WHERE id='$WORKLIST_ID';"
```

---

### Part 3: Database Verification (15 minutes)

#### Check All Tables
```bash
echo "=== Database Verification ==="

# Check modalities
echo "Modalities:"
mysql -u root prime -e "SELECT id, ae_title, modality_name, status FROM radiology_modalities LIMIT 5;"

# Check requests
echo "Requests:"
mysql -u root prime -e "SELECT id, patient_id, status FROM radiology_requests LIMIT 5;"

# Check appointments
echo "Appointments:"
mysql -u root prime -e "SELECT id, request_id, status FROM radiology_appointments LIMIT 5;"

# Check worklist
echo "Worklist:"
mysql -u root prime -e "SELECT id, accession_number, worklist_status FROM radiology_worklist LIMIT 5;"

# Check webhook logs
echo "Webhook Logs:"
mysql -u root prime -e "SELECT id, webhook_type, status FROM radiology_webhook_logs LIMIT 5;"
```

---

### Part 4: End-to-End Workflow Verification (15 minutes)

#### Complete Workflow Test
```bash
echo "=== End-to-End Workflow Test ==="

# 1. Verify modality registered
echo "1. Modality registered:"
mysql -u root prime -e "SELECT COUNT(*) as modalities FROM radiology_modalities;"

# 2. Verify request created
echo "2. Request created:"
mysql -u root prime -e "SELECT COUNT(*) as requests FROM radiology_requests WHERE status='pending';"

# 3. Verify appointment created
echo "3. Appointment created:"
mysql -u root prime -e "SELECT COUNT(*) as appointments FROM radiology_appointments WHERE status='scheduled';"

# 4. Verify worklist auto-created
echo "4. Worklist auto-created:"
mysql -u root prime -e "SELECT COUNT(*) as worklist_items FROM radiology_worklist WHERE worklist_status='pending';"

# 5. Verify accession number generated
echo "5. Accession number generated:"
mysql -u root prime -e "SELECT accession_number FROM radiology_worklist LIMIT 1;"

# 6. Verify all endpoints accessible
echo "6. All endpoints accessible:"
curl -s http://localhost:46990/radiology/webhook/test | jq '.success'
```

---

## Complete Test Script

Save this as `test-phase2.sh`:

```bash
#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Phase 2 Implementation Test ===${NC}"

# Setup
echo -e "${YELLOW}Setting up test environment...${NC}"

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

# Test 1: Webhook
echo -e "\n${YELLOW}Test 1: Webhook Connectivity${NC}"
WEBHOOK=$(curl -s -X POST http://localhost:46990/radiology/webhook/test)
if echo $WEBHOOK | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Webhook test successful${NC}"
else
  echo -e "${RED}✗ Webhook test failed${NC}"
  echo $WEBHOOK
fi

# Test 2: Register Modality
echo -e "\n${YELLOW}Test 2: Register Modality${NC}"
MODALITY=$(curl -s -X POST http://localhost:46990/radiology/modalities \
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

if echo $MODALITY | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Modality registered${NC}"
  export MODALITY_ID=$(echo $MODALITY | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
else
  echo -e "${RED}✗ Failed to register modality${NC}"
  echo $MODALITY
fi

# Test 3: Create Request
echo -e "\n${YELLOW}Test 3: Create Request${NC}"
REQUEST=$(curl -s -X POST http://localhost:46990/radiology/requests \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "patient_id": "'$PATIENT_ID'",
    "requesting_doctor_id": "'$USER_ID'",
    "procedure_id": "'$PROCEDURE_ID'",
    "priority": "routine",
    "clinical_indication": "Test",
    "facilityId": "'$FACILITY_ID'",
    "created_by": "'$USER_ID'"
  }')

if echo $REQUEST | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Request created${NC}"
  export REQUEST_ID=$(echo $REQUEST | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
else
  echo -e "${RED}✗ Failed to create request${NC}"
  echo $REQUEST
fi

# Test 4: Create Appointment
echo -e "\n${YELLOW}Test 4: Create Appointment${NC}"
APPOINTMENT=$(curl -s -X POST http://localhost:46990/radiology/appointments \
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
    "facilityId": "'$FACILITY_ID'"
  }')

if echo $APPOINTMENT | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Appointment created${NC}"
  export APPOINTMENT_ID=$(echo $APPOINTMENT | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  export ACCESSION_NUMBER=$(mysql -u root prime -N -e "SELECT accession_number FROM radiology_worklist WHERE appointment_id='$APPOINTMENT_ID';")
  export WORKLIST_ID=$(mysql -u root prime -N -e "SELECT id FROM radiology_worklist WHERE appointment_id='$APPOINTMENT_ID';")
else
  echo -e "${RED}✗ Failed to create appointment${NC}"
  echo $APPOINTMENT
fi

# Test 5: Get Worklist
echo -e "\n${YELLOW}Test 5: Get Worklist${NC}"
WORKLIST=$(curl -s -X GET "http://localhost:46990/radiology/worklist?status=pending&facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN")

if echo $WORKLIST | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Worklist retrieved${NC}"
else
  echo -e "${RED}✗ Failed to get worklist${NC}"
fi

# Test 6: Get by Accession
echo -e "\n${YELLOW}Test 6: Get by Accession Number${NC}"
ACCESSION=$(curl -s -X GET "http://localhost:46990/radiology/worklist/$ACCESSION_NUMBER")

if echo $ACCESSION | grep -q '"success":true'; then
  echo -e "${GREEN}✓ Accession number query successful${NC}"
else
  echo -e "${RED}✗ Failed to get by accession number${NC}"
fi

echo -e "\n${GREEN}All tests completed!${NC}"
```

---

## Execution Steps

1. **Configure Orthanc** (30 min)
   - Backup configuration
   - Add webhooks
   - Add worklist config
   - Enable DicomWeb
   - Create directory
   - Restart Orthanc

2. **Run Tests** (30 min)
   - Webhook connectivity
   - Register modality
   - Create request
   - Create appointment
   - Get worklist
   - Get by accession

3. **Verify Database** (15 min)
   - Check all tables
   - Verify records

4. **End-to-End Test** (15 min)
   - Complete workflow
   - All endpoints

**Total Time**: ~90 minutes

---

## Success Criteria

### Configuration ✅
- [x] Webhooks configured
- [x] Worklist directory created
- [x] DicomWeb enabled
- [x] Orthanc restarted

### Testing ✅
- [ ] All 6 tests passing
- [ ] Database verified
- [ ] No errors in logs
- [ ] End-to-end workflow working

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Phase 2 Ready for Implementation

