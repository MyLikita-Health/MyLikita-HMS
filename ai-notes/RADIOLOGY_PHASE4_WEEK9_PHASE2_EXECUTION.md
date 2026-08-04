# Radiology Phase 4 - Week 9 Phase 2 Execution
## Orthanc Configuration & Webhook Setup

**Date**: March 11, 2026  
**Phase**: 2 of 3  
**Duration**: 4 hours  
**Status**: Ready to Execute

---

## Phase 2 Overview

### Objectives
1. Configure Orthanc webhooks
2. Create worklist directory
3. Enable DicomWeb
4. Verify configuration
5. Test webhook delivery
6. Verify end-to-end workflow

### Timeline
- **Days 1-2**: Orthanc configuration (2 hours)
- **Days 3-7**: Integration testing (2 hours)

### Success Criteria
- ✅ Orthanc configured with webhooks
- ✅ Worklist directory created
- ✅ DicomWeb enabled
- ✅ All webhooks responding
- ✅ End-to-end workflow tested

---

## Day 1-2: Orthanc Configuration

### Task 1: Backup Configuration (5 minutes)

**Objective**: Create backup of current Orthanc configuration

**Steps**:
```bash
# Create backup
cp /etc/orthanc/orthanc.json /etc/orthanc/orthanc.json.backup

# Verify backup created
ls -la /etc/orthanc/orthanc.json*
```

**Expected Output**:
```
-rw-r--r-- 1 root root 12345 Mar 11 10:00 /etc/orthanc/orthanc.json
-rw-r--r-- 1 root root 12345 Mar 11 10:00 /etc/orthanc/orthanc.json.backup
```

**Status**: ⏳ Ready to Execute

---

### Task 2: Add Webhook Configuration (10 minutes)

**Objective**: Configure Orthanc to send webhooks to backend

**Steps**:

1. **Edit Configuration File**:
```bash
nano /etc/orthanc/orthanc.json
```

2. **Add Webhook Section** (after existing configuration):
```json
"Webhooks": {
  "ImageReceived": "http://backend:46990/radiology/webhook/image-received",
  "ImageStored": "http://backend:46990/radiology/webhook/image-stored",
  "StudyCompleted": "http://backend:46990/radiology/webhook/study-completed",
  "ModalityStatus": "http://localhost:46990/radiology/webhook/modality-status"
}
```

3. **Save File**: Press Ctrl+X, then Y, then Enter

**Verification**:
```bash
# Verify JSON syntax
cat /etc/orthanc/orthanc.json | python -m json.tool > /dev/null && echo "Valid JSON"

# Verify webhooks section
grep -A 10 "Webhooks" /etc/orthanc/orthanc.json
```

**Expected Output**:
```
Valid JSON
"Webhooks": {
  "ImageReceived": "http://backend:46990/radiology/webhook/image-received",
  "ImageStored": "http://backend:46990/radiology/webhook/image-stored",
  "StudyCompleted": "http://backend:46990/radiology/webhook/study-completed",
  "ModalityStatus": "http://localhost:46990/radiology/webhook/modality-status"
}
```

**Status**: ⏳ Ready to Execute

---

### Task 3: Add Worklist Configuration (5 minutes)

**Objective**: Configure worklist directory serving

**Steps**:

1. **Edit Configuration File**:
```bash
nano /etc/orthanc/orthanc.json
```

2. **Add ServeFolders Section**:
```json
"ServeFolders": {
  "/worklists": "/var/lib/orthanc/worklists"
}
```

3. **Save File**: Press Ctrl+X, then Y, then Enter

**Verification**:
```bash
# Verify JSON syntax
cat /etc/orthanc/orthanc.json | python -m json.tool > /dev/null && echo "Valid JSON"

# Verify ServeFolders section
grep -A 3 "ServeFolders" /etc/orthanc/orthanc.json
```

**Expected Output**:
```
Valid JSON
"ServeFolders": {
  "/worklists": "/var/lib/orthanc/worklists"
}
```

**Status**: ⏳ Ready to Execute

---

### Task 4: Enable DicomWeb (5 minutes)

**Objective**: Enable DICOM Web API

**Steps**:

1. **Edit Configuration File**:
```bash
nano /etc/orthanc/orthanc.json
```

2. **Add DicomWeb Section**:
```json
"DicomWeb": {
  "Enable": true,
  "PublicUrl": "http://localhost:8042/dicom-web/"
}
```

3. **Save File**: Press Ctrl+X, then Y, then Enter

**Verification**:
```bash
# Verify JSON syntax
cat /etc/orthanc/orthanc.json | python -m json.tool > /dev/null && echo "Valid JSON"

# Verify DicomWeb section
grep -A 3 "DicomWeb" /etc/orthanc/orthanc.json
```

**Expected Output**:
```
Valid JSON
"DicomWeb": {
  "Enable": true,
  "PublicUrl": "http://localhost:8042/dicom-web/"
}
```

**Status**: ⏳ Ready to Execute

---

### Task 5: Create Worklist Directory (5 minutes)

**Objective**: Set up directory for worklist exports

**Commands**:
```bash
# Create directory
mkdir -p /var/lib/orthanc/worklists

# Set permissions
chmod 755 /var/lib/orthanc/worklists

# Verify
ls -la /var/lib/orthanc/worklists
```

**Expected Output**:
```
drwxr-xr-x  2 orthanc orthanc 4096 Mar 11 10:00 worklists
```

**Status**: ⏳ Ready to Execute

---

### Task 6: Verify Configuration (5 minutes)

**Objective**: Ensure all configuration changes are valid

**Commands**:
```bash
# Verify JSON syntax
cat /etc/orthanc/orthanc.json | python -m json.tool > /dev/null && echo "Configuration is valid JSON"

# Check all sections
echo "=== Webhooks ==="
grep -A 10 "Webhooks" /etc/orthanc/orthanc.json

echo "=== ServeFolders ==="
grep -A 3 "ServeFolders" /etc/orthanc/orthanc.json

echo "=== DicomWeb ==="
grep -A 3 "DicomWeb" /etc/orthanc/orthanc.json
```

**Expected Output**:
```
Configuration is valid JSON
=== Webhooks ===
"Webhooks": {
  "ImageReceived": "http://backend:46990/radiology/webhook/image-received",
  ...
}
=== ServeFolders ===
"ServeFolders": {
  "/worklists": "/var/lib/orthanc/worklists"
}
=== DicomWeb ===
"DicomWeb": {
  "Enable": true,
  "PublicUrl": "http://localhost:8042/dicom-web/"
}
```

**Status**: ⏳ Ready to Execute

---

### Task 7: Restart Orthanc (5 minutes)

**Objective**: Apply configuration changes

**Commands**:
```bash
# Restart service
systemctl restart orthanc

# Check status
systemctl status orthanc

# Wait for startup
sleep 5

# Verify running
curl -X GET http://localhost:8042/system
```

**Expected Response**:
```json
{
  "ApiVersion": 1,
  "DatabaseVersion": 6,
  "DicomAet": "ORTHANC",
  "DicomPort": 4242,
  "HttpPort": 8042,
  "IsHttpServerSecure": false,
  "Name": "MyOrthanc",
  "PluginsEnabled": true,
  "Version": "1.12.0"
}
```

**Status**: ⏳ Ready to Execute

---

## Day 3-7: Integration Testing

### Test 1: Webhook Connectivity (5 minutes)

**Objective**: Verify backend webhook endpoints are accessible

**Command**:
```bash
# Test webhook endpoint
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

**Status**: ⏳ Ready to Execute

---

### Test 2: Register Modality (5 minutes)

**Objective**: Test modality registration

**Command**:
```bash
# Get token
export TOKEN=$(curl -s http://localhost:46990/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}' | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# Get facility ID
export FACILITY_ID=$(mysql -u root prime -N -e "SELECT id FROM hospitals LIMIT 1;")

# Register modality
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
  }
}
```

**Verification**:
```bash
# Verify in database
mysql -u root prime -e "SELECT id, ae_title, modality_name, status FROM radiology_modalities WHERE ae_title='XRAY01';"
```

**Status**: ⏳ Ready to Execute

---

### Test 3: Create Request (5 minutes)

**Objective**: Test request creation

**Command**:
```bash
# Get IDs
export USER_ID=$(mysql -u root prime -N -e "SELECT id FROM users LIMIT 1;")
export PATIENT_ID=$(mysql -u root prime -N -e "SELECT CONCAT(accountNo, '-', beneficiaryNo) FROM patientrecords LIMIT 1;")
export PROCEDURE_ID=$(mysql -u root prime -N -e "SELECT id FROM radiology_procedures LIMIT 1;")

# Create request
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
  }
}
```

**Status**: ⏳ Ready to Execute

---

### Test 4: Create Appointment (Auto-creates Worklist) (5 minutes)

**Objective**: Test appointment creation and auto-worklist generation

**Command**:
```bash
# Save request ID from previous test
export REQUEST_ID="request-uuid"

# Create appointment
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
  }
}
```

**Verification**:
```bash
# Verify appointment created
mysql -u root prime -e "SELECT id, request_id, status FROM radiology_appointments WHERE id='appointment-uuid';"

# Verify worklist auto-created
mysql -u root prime -e "SELECT id, accession_number, worklist_status FROM radiology_worklist WHERE appointment_id='appointment-uuid';"
```

**Status**: ⏳ Ready to Execute

---

### Test 5: Get Worklist (5 minutes)

**Objective**: Test worklist retrieval

**Command**:
```bash
# Get worklist items
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

**Status**: ⏳ Ready to Execute

---

### Test 6: Get by Accession Number (5 minutes)

**Objective**: Test accession number query

**Command**:
```bash
# Get accession number from database
export ACCESSION_NUMBER=$(mysql -u root prime -N -e "SELECT accession_number FROM radiology_worklist WHERE appointment_id='appointment-uuid';")

# Query by accession number
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

**Status**: ⏳ Ready to Execute

---

## Configuration Verification Checklist

### Webhook Configuration
- [ ] ImageReceived endpoint configured
- [ ] ImageStored endpoint configured
- [ ] StudyCompleted endpoint configured
- [ ] ModalityStatus endpoint configured

### Worklist Configuration
- [ ] ServeFolders configured
- [ ] Worklist directory path set
- [ ] Directory created with correct permissions

### DicomWeb Configuration
- [ ] DicomWeb enabled
- [ ] Public URL configured

### Service Status
- [ ] Orthanc restarted successfully
- [ ] Service is running
- [ ] API responds to requests
- [ ] No errors in logs

---

## Testing Checklist

### Backend Verification
- [ ] Backend running on port 46990
- [ ] Database connected
- [ ] All routes registered
- [ ] Authentication working

### Modality Tests
- [ ] Register modality successful
- [ ] Get modalities returns data
- [ ] Modality stored in database
- [ ] AE Title query works

### Request Tests
- [ ] Create request successful
- [ ] Request stored in database
- [ ] Request ID returned
- [ ] Status is pending

### Appointment Tests
- [ ] Create appointment successful
- [ ] Appointment stored in database
- [ ] Worklist auto-created
- [ ] Accession number generated

### Worklist Tests
- [ ] Get worklist returns items
- [ ] Accession number query works
- [ ] Modality query works
- [ ] Status filtering works

### Webhook Tests
- [ ] Test webhook endpoint responds
- [ ] Webhook logs retrievable
- [ ] All webhook handlers registered

---

## Troubleshooting

### If Orthanc Fails to Start

**Steps**:
1. Check logs: `journalctl -u orthanc -n 50`
2. Verify JSON syntax: `cat /etc/orthanc/orthanc.json | python -m json.tool`
3. Restore backup: `cp /etc/orthanc/orthanc.json.backup /etc/orthanc/orthanc.json`
4. Restart: `systemctl restart orthanc`

### If Webhooks Not Working

**Steps**:
1. Verify configuration: `grep -A 10 "Webhooks" /etc/orthanc/orthanc.json`
2. Test connectivity: `curl -X POST http://localhost:46990/radiology/webhook/test`
3. Check firewall: `sudo ufw status`
4. Check logs: `tail -50 /var/log/orthanc/Orthanc.log`

### If Database Connection Failed

**Steps**:
1. Check MySQL: `mysql -u root -e "SELECT 1;"`
2. Check database: `mysql -u root -e "SHOW DATABASES LIKE 'prime';"`
3. Check tables: `mysql -u root prime -e "SHOW TABLES LIKE 'radiology%';"`

---

## Day Summary

### Tasks Completed
- [ ] Backup configuration
- [ ] Add webhook configuration
- [ ] Add worklist configuration
- [ ] Enable DicomWeb
- [ ] Create worklist directory
- [ ] Verify configuration
- [ ] Restart Orthanc

### Tests Completed
- [ ] Webhook connectivity
- [ ] Register modality
- [ ] Create request
- [ ] Create appointment
- [ ] Get worklist
- [ ] Get by accession number

### Expected Outcomes
- ✅ Orthanc configured with webhooks
- ✅ Worklist directory created
- ✅ DicomWeb enabled
- ✅ Service running
- ✅ Webhooks accessible
- ✅ All tests passing

### Next Steps (Phase 3)
- Code review
- Staging deployment
- Production deployment
- Monitoring setup

---

## Approval Checklist

- [ ] Configuration changes applied
- [ ] Orthanc restarted successfully
- [ ] Webhooks verified
- [ ] Worklist directory created
- [ ] Backend connectivity confirmed
- [ ] All tests passing
- [ ] Ready for Phase 3

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Phase 2 Ready for Execution

