# Orthanc Integration - Quick Reference
## Complete Setup & Testing Guide

**Status**: ✅ Backend Ready | ⏳ Orthanc Configuration Pending

---

## Quick Status Check

### Backend Running?
```bash
curl -X POST http://localhost:46990/radiology/webhook/test
# Expected: {"success":true,"message":"Webhook test successful"}
```

### Orthanc Running?
```bash
curl -X GET http://localhost:8042/system
# Expected: JSON with Orthanc system info
```

---

## Orthanc Configuration (5 minutes)

### 1. Backup Configuration
```bash
cp /etc/orthanc/orthanc.json /etc/orthanc/orthanc.json.backup
```

### 2. Add Webhooks
```bash
nano /etc/orthanc/orthanc.json
# Add after existing config:
"Webhooks": {
  "ImageReceived": "http://backend:46990/radiology/webhook/image-received",
  "ImageStored": "http://backend:46990/radiology/webhook/image-stored",
  "StudyCompleted": "http://backend:46990/radiology/webhook/study-completed",
  "ModalityStatus": "http://localhost:46990/radiology/webhook/modality-status"
}
```

### 3. Add Worklist & DicomWeb
```bash
# Add to same file:
"ServeFolders": {
  "/worklists": "/var/lib/orthanc/worklists"
},
"DicomWeb": {
  "Enable": true,
  "PublicUrl": "http://localhost:8042/dicom-web/"
}
```

### 4. Create Directory & Restart
```bash
mkdir -p /var/lib/orthanc/worklists
chmod 755 /var/lib/orthanc/worklists
systemctl restart orthanc
sleep 5
curl -X GET http://localhost:8042/system
```

---

## API Endpoints (16 Total)

### Modality Management
```bash
# Register modality
POST /radiology/modalities

# Get all modalities
GET /radiology/modalities

# Get by AE Title
GET /radiology/modalities/:aeTitle

# Update status
PUT /radiology/modalities/:id/status
```

### Worklist Management
```bash
# Create worklist item
POST /radiology/worklist

# Get worklist items
GET /radiology/worklist?status=pending&facilityId=$FACILITY_ID

# Get by accession number
GET /radiology/worklist/:accessionNumber

# Get for modality
GET /radiology/worklist/modality/:modalityId

# Update status
PUT /radiology/worklist/:id/status

# Export to Orthanc
POST /radiology/worklist/:id/export
```

### Webhook Endpoints
```bash
# Test webhook
POST /radiology/webhook/test

# Image received (called by Orthanc)
POST /radiology/webhook/image-received

# Image stored (called by Orthanc)
POST /radiology/webhook/image-stored

# Study completed (called by Orthanc)
POST /radiology/webhook/study-completed

# Modality status (called by Orthanc)
POST /radiology/webhook/modality-status

# Get webhook logs
GET /radiology/webhook/logs
```

---

## Quick Test Script

```bash
#!/bin/bash

# Setup
export FACILITY_ID=$(mysql -u root prime -N -e "SELECT id FROM hospitals LIMIT 1;")
export USER_ID=$(mysql -u root prime -N -e "SELECT id FROM users LIMIT 1;")
export PATIENT_ID=$(mysql -u root prime -N -e "SELECT CONCAT(accountNo, '-', beneficiaryNo) FROM patientrecords LIMIT 1;")
export PROCEDURE_ID=$(mysql -u root prime -N -e "SELECT id FROM radiology_procedures LIMIT 1;")

# Get token
export TOKEN=$(curl -s http://localhost:46990/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}' | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# Test 1: Register Modality
echo "Test 1: Register Modality"
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
export MODALITY_ID=$(echo $MODALITY | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

# Test 2: Create Request
echo "Test 2: Create Request"
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
echo $REQUEST | jq '.'
export REQUEST_ID=$(echo $REQUEST | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

# Test 3: Create Appointment
echo "Test 3: Create Appointment"
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
echo $APPOINTMENT | jq '.'
export APPOINTMENT_ID=$(echo $APPOINTMENT | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

# Test 4: Get Worklist
echo "Test 4: Get Worklist"
curl -s -X GET "http://localhost:46990/radiology/worklist?status=pending&facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# Test 5: Test Webhook
echo "Test 5: Test Webhook"
curl -s -X POST http://localhost:46990/radiology/webhook/test | jq '.'

echo "All tests completed!"
```

---

## Database Verification

### Check All Tables
```bash
mysql -u root prime -e "
SELECT TABLE_NAME, TABLE_ROWS 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA='prime' AND TABLE_NAME LIKE 'radiology%'
ORDER BY TABLE_NAME;
"
```

### Check Modalities
```bash
mysql -u root prime -e "SELECT id, ae_title, modality_name, status FROM radiology_modalities;"
```

### Check Worklist
```bash
mysql -u root prime -e "SELECT id, accession_number, worklist_status FROM radiology_worklist;"
```

### Check DICOM Studies
```bash
mysql -u root prime -e "SELECT id, request_id, study_uid FROM radiology_dicom_studies;"
```

---

## Integration Components

### Backend Services
- ✅ Orthanc client service (`backend/services/orthancClient.js`)
- ✅ Worklist controller (`backend/controller/radiology-worklist.js`)
- ✅ Webhook handlers (`backend/controller/radiology-dicom-webhook.js`)
- ✅ Routes (`backend/routes/radiology-worklist.js`)

### Database Tables
- ✅ radiology_modalities
- ✅ radiology_worklist
- ✅ radiology_dicom_studies
- ✅ radiology_webhook_logs
- ✅ radiology_requests
- ✅ radiology_appointments
- ✅ radiology_billing

### API Endpoints
- ✅ 6 Worklist endpoints
- ✅ 4 Modality endpoints
- ✅ 6 Webhook endpoints

---

## Troubleshooting

### Backend Not Responding
```bash
# Check if running
lsof -i :46990

# Check logs
tail -50 backend.log

# Restart
cd backend && npm start
```

### Orthanc Not Responding
```bash
# Check if running
systemctl status orthanc

# Check logs
journalctl -u orthanc -n 50

# Restart
systemctl restart orthanc
```

### Webhooks Not Working
```bash
# Check configuration
grep -A 10 "Webhooks" /etc/orthanc/orthanc.json

# Test connectivity
curl -X POST http://localhost:46990/radiology/webhook/test

# Check backend logs
tail -50 backend.log
```

### Database Issues
```bash
# Check MySQL
mysql -u root -e "SELECT 1;"

# Check database
mysql -u root -e "SHOW DATABASES LIKE 'prime';"

# Check tables
mysql -u root prime -e "SHOW TABLES LIKE 'radiology%';"
```

---

## Files & Documentation

### Integration Guides
- `ORTHANC_INTEGRATION_VERIFICATION.md` - Detailed verification
- `ORTHANC_INTEGRATION_COMPLETE.md` - Complete integration status
- `ORTHANC_INTEGRATION_QUICK_REFERENCE.md` - This file

### Testing Guides
- `RADIOLOGY_PHASE4_WEEK9_API_TEST_SCRIPT.md` - Complete test script
- `RADIOLOGY_PHASE4_TESTING_GUIDE.md` - All test cases

### Configuration Guides
- `RADIOLOGY_PHASE4_WEEK9_DAY2_TASKS.md` - Configuration steps
- `ORTHANC_CONFIGURATION_GUIDE.md` - Orthanc setup

### Reference
- `RADIOLOGY_PHASE4_QUICK_START.md` - API reference
- `RADIOLOGY_PHASE4_README.md` - Overview

---

## Success Criteria

### Backend ✅
- [x] Running on port 46990
- [x] All routes registered
- [x] All endpoints functional
- [x] Database connected
- [x] Authentication working

### Orthanc ✅
- [x] Running on port 8042
- [ ] Webhooks configured
- [ ] Worklist directory created
- [ ] DicomWeb enabled
- [ ] Configuration verified

### Integration ✅
- [x] Client service implemented
- [x] Worklist management implemented
- [x] Webhook handlers implemented
- [x] Auto-worklist creation implemented
- [ ] End-to-end workflow tested

---

## Next Steps

1. Configure Orthanc webhooks (5 min)
2. Create worklist directory (1 min)
3. Enable DicomWeb (1 min)
4. Restart Orthanc (2 min)
5. Run integration tests (10 min)
6. Verify all endpoints (5 min)

**Total Time**: ~25 minutes

---

**Quick Reference Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Ready for Orthanc Configuration

