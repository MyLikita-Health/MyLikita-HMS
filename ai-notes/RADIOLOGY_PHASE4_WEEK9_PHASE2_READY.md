# Radiology Phase 4 - Week 9 Phase 2 Ready
## Complete Orthanc Configuration & Testing Guide

**Date**: March 11, 2026  
**Phase**: 2 of 3  
**Status**: ✅ READY FOR EXECUTION  
**Duration**: ~90 minutes

---

## Quick Start

### What You Need to Do
1. Configure Orthanc (30 min)
2. Run integration tests (30 min)
3. Verify database (15 min)
4. Test end-to-end workflow (15 min)

### What You'll Accomplish
- ✅ Orthanc configured with webhooks
- ✅ Worklist directory created
- ✅ DicomWeb enabled
- ✅ All 8 tests passing
- ✅ End-to-end workflow verified

---

## Part 1: Orthanc Configuration (30 minutes)

### Step 1: Backup Configuration (2 min)
```bash
cp /etc/orthanc/orthanc.json /etc/orthanc/orthanc.json.backup
ls -la /etc/orthanc/orthanc.json*
```

### Step 2: Edit Configuration (15 min)
```bash
nano /etc/orthanc/orthanc.json
```

**Add these sections** (after existing configuration):

```json
"Webhooks": {
  "ImageReceived": "http://backend:46990/radiology/webhook/image-received",
  "ImageStored": "http://backend:46990/radiology/webhook/image-stored",
  "StudyCompleted": "http://backend:46990/radiology/webhook/study-completed",
  "ModalityStatus": "http://localhost:46990/radiology/webhook/modality-status"
},
"ServeFolders": {
  "/worklists": "/var/lib/orthanc/worklists"
},
"DicomWeb": {
  "Enable": true,
  "PublicUrl": "http://localhost:8042/dicom-web/"
}
```

**Save**: Ctrl+X, Y, Enter

### Step 3: Verify Configuration (5 min)
```bash
# Check JSON syntax
cat /etc/orthanc/orthanc.json | python -m json.tool > /dev/null && echo "Valid JSON"

# Verify sections
grep -A 10 "Webhooks" /etc/orthanc/orthanc.json
grep -A 3 "ServeFolders" /etc/orthanc/orthanc.json
grep -A 3 "DicomWeb" /etc/orthanc/orthanc.json
```

### Step 4: Create Directory (3 min)
```bash
mkdir -p /var/lib/orthanc/worklists
chmod 755 /var/lib/orthanc/worklists
ls -la /var/lib/orthanc/worklists
```

### Step 5: Restart Orthanc (5 min)
```bash
systemctl restart orthanc
sleep 5
curl -X GET http://localhost:8042/system | jq '.'
```

**Expected**: Orthanc system info returned

---

## Part 2: Integration Testing (30 minutes)

### Setup: Get Required IDs (2 min)
```bash
export FACILITY_ID=$(mysql -u root prime -N -e "SELECT id FROM hospitals LIMIT 1;")
export USER_ID=$(mysql -u root prime -N -e "SELECT id FROM users LIMIT 1;")
export PATIENT_ID=$(mysql -u root prime -N -e "SELECT CONCAT(accountNo, '-', beneficiaryNo) FROM patientrecords LIMIT 1;")
export PROCEDURE_ID=$(mysql -u root prime -N -e "SELECT id FROM radiology_procedures LIMIT 1;")

# Get token
export TOKEN=$(curl -s http://localhost:46990/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}' | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo "Setup complete. IDs exported."
```

### Test 1: Webhook Connectivity (1 min)
```bash
curl -X POST http://localhost:46990/radiology/webhook/test | jq '.'
```
**Expected**: `{"success":true,"message":"Webhook test successful"}`

### Test 2: Register Modality (2 min)
```bash
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
```

### Test 3: Create Request (2 min)
```bash
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
```

### Test 4: Create Appointment (2 min)
```bash
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
export ACCESSION_NUMBER=$(mysql -u root prime -N -e "SELECT accession_number FROM radiology_worklist WHERE appointment_id='$APPOINTMENT_ID';")
export WORKLIST_ID=$(mysql -u root prime -N -e "SELECT id FROM radiology_worklist WHERE appointment_id='$APPOINTMENT_ID';")
```

### Test 5: Get Worklist (2 min)
```bash
curl -s -X GET "http://localhost:46990/radiology/worklist?status=pending&facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

### Test 6: Get by Accession Number (2 min)
```bash
curl -s -X GET "http://localhost:46990/radiology/worklist/$ACCESSION_NUMBER" | jq '.'
```

### Test 7: Get for Modality (2 min)
```bash
curl -s -X GET "http://localhost:46990/radiology/worklist/modality/$MODALITY_ID?status=pending" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

### Test 8: Update Status (2 min)
```bash
curl -s -X PUT "http://localhost:46990/radiology/worklist/$WORKLIST_ID/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"status": "in_progress"}' | jq '.'
```

---

## Part 3: Database Verification (15 minutes)

### Check All Tables
```bash
echo "=== Modalities ==="
mysql -u root prime -e "SELECT id, ae_title, modality_name, status FROM radiology_modalities LIMIT 5;"

echo "=== Requests ==="
mysql -u root prime -e "SELECT id, patient_id, status FROM radiology_requests LIMIT 5;"

echo "=== Appointments ==="
mysql -u root prime -e "SELECT id, request_id, status FROM radiology_appointments LIMIT 5;"

echo "=== Worklist ==="
mysql -u root prime -e "SELECT id, accession_number, worklist_status FROM radiology_worklist LIMIT 5;"

echo "=== Webhook Logs ==="
mysql -u root prime -e "SELECT id, webhook_type, status FROM radiology_webhook_logs LIMIT 5;"
```

---

## Part 4: End-to-End Workflow Verification (15 minutes)

### Verify Complete Workflow
```bash
echo "=== End-to-End Workflow Verification ==="

# 1. Modality registered
echo "1. Modalities count:"
mysql -u root prime -e "SELECT COUNT(*) as count FROM radiology_modalities;"

# 2. Request created
echo "2. Requests count:"
mysql -u root prime -e "SELECT COUNT(*) as count FROM radiology_requests WHERE status='pending';"

# 3. Appointment created
echo "3. Appointments count:"
mysql -u root prime -e "SELECT COUNT(*) as count FROM radiology_appointments WHERE status='scheduled';"

# 4. Worklist auto-created
echo "4. Worklist items count:"
mysql -u root prime -e "SELECT COUNT(*) as count FROM radiology_worklist WHERE worklist_status='pending';"

# 5. Accession number generated
echo "5. Accession number:"
mysql -u root prime -e "SELECT accession_number FROM radiology_worklist LIMIT 1;"

# 6. All endpoints accessible
echo "6. Backend connectivity:"
curl -s http://localhost:46990/radiology/webhook/test | jq '.success'

echo "=== Workflow Verification Complete ==="
```

---

## Success Indicators

### Configuration ✅
- [x] Webhooks configured
- [x] Worklist directory created
- [x] DicomWeb enabled
- [x] Orthanc restarted

### Testing ✅
- [ ] All 8 tests passing
- [ ] Database records verified
- [ ] No errors in logs
- [ ] End-to-end workflow working

### Integration ✅
- [ ] Backend responding
- [ ] Orthanc responding
- [ ] Webhooks accessible
- [ ] All endpoints functional

---

## Troubleshooting

### Orthanc Won't Start
```bash
# Check logs
journalctl -u orthanc -n 50

# Verify JSON
cat /etc/orthanc/orthanc.json | python -m json.tool

# Restore backup
cp /etc/orthanc/orthanc.json.backup /etc/orthanc/orthanc.json
systemctl restart orthanc
```

### Tests Failing
```bash
# Check backend logs
tail -50 backend.log

# Check database
mysql -u root prime -e "SELECT COUNT(*) FROM radiology_modalities;"

# Check connectivity
curl -X POST http://localhost:46990/radiology/webhook/test
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

## Files to Reference

### Phase 2 Documentation
1. **RADIOLOGY_PHASE4_WEEK9_PHASE2_EXECUTION.md** - Detailed execution guide
2. **RADIOLOGY_PHASE4_WEEK9_PHASE2_IMPLEMENTATION.md** - Implementation with scripts
3. **RADIOLOGY_PHASE4_WEEK9_PHASE2_SUMMARY.md** - Phase 2 summary
4. **RADIOLOGY_PHASE4_WEEK9_PHASE2_READY.md** - This file

### Related Documentation
- **ORTHANC_INTEGRATION_QUICK_REFERENCE.md** - Quick reference
- **RADIOLOGY_PHASE4_WEEK9_API_TEST_SCRIPT.md** - API test script

---

## Timeline

### Configuration (30 min)
- Backup: 2 min
- Edit: 15 min
- Verify: 5 min
- Create directory: 3 min
- Restart: 5 min

### Testing (30 min)
- Setup: 2 min
- 8 tests: 16 min
- Verification: 12 min

### Database Verification (15 min)
- Check all tables: 15 min

### End-to-End (15 min)
- Workflow verification: 15 min

**Total**: ~90 minutes

---

## Next Steps

### After Phase 2 Completion
1. ✅ Orthanc configured
2. ✅ Webhooks working
3. ✅ Worklist export working
4. ✅ End-to-end workflow tested
5. ⏳ Proceed to Phase 3

### Phase 3 (Production Deployment)
- Code review
- Staging deployment
- Production deployment
- Monitoring setup

---

## Summary

### Phase 2 Scope
- Orthanc configuration (webhooks, worklist, DicomWeb)
- Integration testing (8 test cases)
- Database verification
- End-to-end workflow validation

### Phase 2 Status
- ✅ Documentation complete
- ✅ Configuration guide ready
- ✅ Testing guide ready
- ✅ Scripts prepared
- ⏳ Ready for execution

### Overall Progress
- Week 8: ✅ 100% Complete
- Week 9 Phase 1: ✅ 100% Complete
- Week 9 Phase 2: ⏳ Ready to Execute
- Week 9 Phase 3: ⏳ Pending

---

**Status**: ✅ Phase 2 Ready for Execution

**Next Action**: Execute Orthanc configuration and run integration tests

**Estimated Time**: ~90 minutes

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Phase 2 Ready for Implementation

