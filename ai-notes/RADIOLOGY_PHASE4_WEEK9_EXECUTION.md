# Radiology Phase 4 - Week 9 Execution Guide
## Day-by-Day Implementation

**Status**: Ready to Execute  
**Date**: March 11, 2026  
**Duration**: 10 Days

---

## Day 1: Orthanc Configuration - Part 1

### Morning (2 hours)

**Task 1.1: Verify Orthanc Installation**
```bash
# Check Orthanc status
curl -X GET http://localhost:8042/system

# Expected: System information returned
```

**Task 1.2: Backup Configuration**
```bash
cp /etc/orthanc/orthanc.json /etc/orthanc/orthanc.json.backup
```

### Afternoon (2 hours)

**Task 1.3: Configure Webhooks**
- Edit `/etc/orthanc/orthanc.json`
- Add webhook endpoints
- Save file

**Task 1.4: Create Worklist Directory**
```bash
mkdir -p /var/lib/orthanc/worklists
chmod 755 /var/lib/orthanc/worklists
```

---

## Day 2: Orthanc Configuration - Part 2

### Morning (2 hours)

**Task 2.1: Restart Orthanc**
```bash
systemctl restart orthanc
systemctl status orthanc
```

**Task 2.2: Verify Configuration**
```bash
curl -X GET http://localhost:8042/system
```

### Afternoon (2 hours)

**Task 2.3: Test Webhook Delivery**
```bash
curl -X POST http://localhost:46990/radiology/webhook/test
```

**Task 2.4: Document Configuration**
- Record all settings
- Note any issues
- Create runbook

---

## Day 3: Unit Testing

### Morning (3 hours)

**Test 1: Register Modality**
```bash
curl -X POST http://localhost:46990/radiology/modalities \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "modality_name": "X-ray Room 1",
    "modality_type": "XR",
    "ae_title": "XRAY01",
    "ip_address": "192.168.1.100",
    "port": 104,
    "facilityId": "'$FACILITY_ID'"
  }'
```

**Test 2: Create Request**
```bash
curl -X POST http://localhost:46990/radiology/requests \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "'$PATIENT_ID'",
    "requesting_doctor_id": "'$USER_ID'",
    "procedure_id": "'$PROCEDURE_ID'",
    "priority": "routine",
    "clinical_indication": "Test",
    "facilityId": "'$FACILITY_ID'",
    "created_by": "'$USER_ID'"
  }'
```

### Afternoon (3 hours)

**Test 3: Create Appointment**
```bash
curl -X POST http://localhost:46990/radiology/appointments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "request_id": "'$REQUEST_ID'",
    "patient_id": "'$PATIENT_ID'",
    "procedure_id": "'$PROCEDURE_ID'",
    "appointment_date": "2026-03-11 10:00:00",
    "room_number": "1",
    "facilityId": "'$FACILITY_ID'"
  }'
```

**Document Results**:
- Record test results
- Note any issues
- Verify database updates

---

## Day 4: Integration Testing

### Morning (3 hours)

**Test 4: Get Worklist**
```bash
curl -X GET "http://localhost:46990/radiology/worklist?status=pending&facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN"
```

**Test 5: Get by Accession**
```bash
curl -X GET "http://localhost:46990/radiology/worklist/$ACCESSION_NUMBER"
```

### Afternoon (3 hours)

**Test 6: Export Worklist**
```bash
curl -X POST "http://localhost:46990/radiology/worklist/$WORKLIST_ID/export" \
  -H "Authorization: Bearer $TOKEN"
```

**Verify Export**:
```bash
ls -la /var/lib/orthanc/worklists/
cat /var/lib/orthanc/worklists/$ACCESSION_NUMBER.json
```

---

## Day 5: End-to-End Testing

### Morning (4 hours)

**Complete Workflow Test**:
1. Create request
2. Create appointment (auto-creates worklist)
3. Export worklist
4. Simulate image received
5. Verify all updates

**Verification**:
```bash
# Check request status
mysql -u root prime -e "SELECT id, status FROM radiology_requests WHERE id='$REQUEST_ID';"

# Check worklist status
mysql -u root prime -e "SELECT id, worklist_status FROM radiology_worklist WHERE accession_number='$ACCESSION_NUMBER';"

# Check billing
mysql -u root prime -e "SELECT id, payment_status FROM radiology_billing WHERE request_id='$REQUEST_ID';"
```

### Afternoon (4 hours)

**Document Results**:
- Record all test results
- Note any issues
- Create test report

---

## Day 6: Performance Testing

### Morning (3 hours)

**Measure Performance**:
```bash
# Accession number generation
time curl -X POST http://localhost:46990/radiology/appointments \
  -H "Authorization: Bearer $TOKEN" \
  -d '{...}'

# Worklist query
time curl -X GET "http://localhost:46990/radiology/worklist?status=pending" \
  -H "Authorization: Bearer $TOKEN"
```

### Afternoon (3 hours)

**Measure Webhook Processing**:
```bash
# Webhook processing
time curl -X POST http://localhost:46990/radiology/webhook/image-received \
  -H "Content-Type: application/json" \
  -d '{...}'
```

**Document Results**:
- Record all timings
- Compare to targets
- Identify bottlenecks

---

## Day 7: Error Handling Testing

### Morning (3 hours)

**Test Error Scenarios**:
1. Invalid appointment ID
2. Duplicate AE Title
3. Missing required fields

**Document Results**:
- Record error responses
- Verify error messages
- Check error handling

### Afternoon (3 hours)

**Test Recovery**:
- Test system recovery
- Verify no data loss
- Check logs for errors

**Create Test Report**:
- Summarize all tests
- List any issues
- Recommend fixes

---

## Day 8: Code Review & Staging

### Morning (4 hours)

**Code Review**:
- Review all new files
- Check for security issues
- Verify error handling
- Check logging

**Checklist**:
- ✅ All tests passing
- ✅ No console.log statements
- ✅ Error handling comprehensive
- ✅ Security best practices
- ✅ Documentation complete

### Afternoon (4 hours)

**Staging Deployment**:
1. Create staging branch
2. Deploy to staging
3. Run smoke tests
4. Verify functionality

---

## Day 9: Production Preparation

### Morning (4 hours)

**Final Testing**:
- Run all tests on staging
- Verify performance
- Check error handling
- Get approval

**Preparation**:
- Create database backup
- Prepare deployment script
- Create rollback plan
- Notify stakeholders

### Afternoon (4 hours)

**Documentation**:
- Complete deployment guide
- Create operations manual
- Create troubleshooting guide
- Train operations team

---

## Day 10: Production Deployment

### Morning (4 hours)

**Pre-Deployment**:
1. Verify database backup
2. Verify deployment script
3. Notify users
4. Prepare rollback

**Deployment**:
1. Deploy code
2. Run smoke tests
3. Monitor logs
4. Verify functionality

### Afternoon (4 hours)

**Post-Deployment**:
1. Monitor performance
2. Check error logs
3. Gather feedback
4. Document issues

**Handoff**:
- Train operations team
- Provide documentation
- Establish support process
- Set up monitoring

---

## Daily Standup Template

**Time**: 9:00 AM  
**Duration**: 15 minutes

**Agenda**:
1. What was completed yesterday?
2. What will be completed today?
3. Any blockers or issues?
4. Any risks?

---

## Testing Report Template

**Date**: [Date]  
**Tester**: [Name]  
**Test Phase**: [Phase]

**Results**:
- Test 1: ✅ PASS / ❌ FAIL
- Test 2: ✅ PASS / ❌ FAIL
- ...

**Issues Found**:
- [Issue 1]
- [Issue 2]
- ...

**Performance**:
- [Metric 1]: [Value]
- [Metric 2]: [Value]
- ...

**Recommendations**:
- [Recommendation 1]
- [Recommendation 2]
- ...

---

## Success Criteria

✅ All tests passing  
✅ Performance targets met  
✅ Error handling working  
✅ Orthanc configured  
✅ Webhooks working  
✅ Production deployment successful  
✅ Monitoring in place  
✅ Documentation complete  

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Ready for Execution
