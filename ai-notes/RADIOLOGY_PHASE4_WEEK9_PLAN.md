# Radiology Phase 4 - Week 9 Plan
## Orthanc Configuration, Testing & Production Deployment

**Status**: Ready to Begin  
**Date**: March 11, 2026  
**Timeline**: Week 9 (Days 1-10)  
**Objective**: Configure Orthanc, run comprehensive tests, and deploy to production

---

## Week 9 Overview

Week 9 focuses on three critical areas:
1. **Orthanc Configuration** (Days 1-2) - Set up webhooks and auto-routing
2. **Comprehensive Testing** (Days 3-7) - Run all test cases and verify functionality
3. **Production Deployment** (Days 8-10) - Deploy to production and monitor

---

## Day 1-2: Orthanc Configuration

### Task 1.1: Verify Orthanc Installation

**Objective**: Ensure Orthanc is running and accessible

**Steps**:
```bash
# Check if Orthanc is running
curl -X GET http://localhost:8042/system

# Expected Response:
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

**Verification**:
- ✅ Orthanc responds to API calls
- ✅ HTTP port 8042 is accessible
- ✅ DICOM port 4242 is accessible

---

### Task 1.2: Configure Orthanc Webhooks

**Objective**: Set up webhook notifications for image events

**File**: `/etc/orthanc/orthanc.json`

**Configuration**:
```json
{
  "Plugins": [
    "libServeFolders.so"
  ],
  "ServeFolders": {
    "/worklists": "/var/lib/orthanc/worklists"
  },
  "Webhooks": {
    "ImageReceived": "http://backend:46990/radiology/webhook/image-received",
    "ImageStored": "http://backend:46990/radiology/webhook/image-stored",
    "StudyCompleted": "http://backend:46990/radiology/webhook/study-completed",
    "ModalityStatus": "http://backend:46990/radiology/webhook/modality-status"
  },
  "DicomWeb": {
    "Enable": true,
    "PublicUrl": "http://localhost:8042/dicom-web/"
  }
}
```

**Steps**:
1. Edit `/etc/orthanc/orthanc.json`
2. Add webhook endpoints
3. Restart Orthanc: `systemctl restart orthanc`
4. Verify configuration: `curl -X GET http://localhost:8042/system`

---

### Task 1.3: Create Worklist Directory

**Objective**: Set up directory for worklist exports

**Steps**:
```bash
# Create worklist directory
mkdir -p /var/lib/orthanc/worklists

# Set permissions
chmod 755 /var/lib/orthanc/worklists

# Verify
ls -la /var/lib/orthanc/worklists
```

---

### Task 1.4: Configure DICOM Networking

**Objective**: Set up DICOM C-STORE receiver for modalities

**File**: `/etc/orthanc/orthanc.json`

**Configuration**:
```json
{
  "DicomAet": "ORTHANC",
  "DicomPort": 4242,
  "RemoteAccessAllowed": false,
  "DicomModalities": {
    "XRAY01": ["192.168.1.100", 104],
    "CT01": ["192.168.1.101", 104],
    "MR01": ["192.168.1.102", 104]
  }
}
```

**Steps**:
1. Edit `/etc/orthanc/orthanc.json`
2. Configure DICOM modalities
3. Restart Orthanc
4. Test connectivity: `curl -X GET http://localhost:8042/modalities`

---

### Task 1.5: Test Webhook Delivery

**Objective**: Verify webhooks are working

**Steps**:
```bash
# Test webhook endpoint
curl -X POST http://localhost:46990/radiology/webhook/test \
  -H "Content-Type: application/json"

# Expected Response:
{
  "success": true,
  "message": "Webhook test successful"
}
```

**Verification**:
- ✅ Webhook endpoint responds
- ✅ Backend is accessible from Orthanc
- ✅ Network connectivity verified

---

## Day 3-7: Comprehensive Testing

### Test Phase 1: Unit Tests (Day 3)

**Objective**: Test individual functions

**Test Cases**:
1. ✅ Accession number generation
2. ✅ Worklist item creation
3. ✅ Modality registration
4. ✅ Worklist export
5. ✅ Image matching logic

**Execution**:
```bash
# Run test cases from RADIOLOGY_PHASE4_TESTING_GUIDE.md
# Test 1: Register Modality
curl -X POST http://localhost:46990/radiology/modalities \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{...}'

# Test 2: Create Request
curl -X POST http://localhost:46990/radiology/requests \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{...}'

# Test 3: Create Appointment
curl -X POST http://localhost:46990/radiology/appointments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{...}'
```

**Verification**:
- ✅ All functions work correctly
- ✅ Data is stored in database
- ✅ No errors in logs

---

### Test Phase 2: Integration Tests (Day 4)

**Objective**: Test workflows

**Test Cases**:
1. ✅ Appointment → Worklist creation
2. ✅ Modality registration → Worklist query
3. ✅ Worklist creation → Export

**Execution**:
```bash
# Test Appointment → Worklist
1. Create appointment
2. Verify worklist created
3. Check accession number generated

# Test Modality → Worklist Query
1. Register modality
2. Query worklist for modality
3. Verify results

# Test Worklist → Export
1. Create worklist
2. Export to Orthanc
3. Verify JSON file created
```

**Verification**:
- ✅ Workflows execute correctly
- ✅ Data flows between systems
- ✅ No data loss

---

### Test Phase 3: End-to-End Tests (Day 5)

**Objective**: Test complete workflow

**Test Case**: Schedule → Worklist → Image → Billing

**Execution**:
```bash
# Step 1: Create request
curl -X POST http://localhost:46990/radiology/requests \
  -H "Authorization: Bearer $TOKEN" \
  -d '{...}'

# Step 2: Create appointment (auto-creates worklist)
curl -X POST http://localhost:46990/radiology/appointments \
  -H "Authorization: Bearer $TOKEN" \
  -d '{...}'

# Step 3: Export worklist
curl -X POST http://localhost:46990/radiology/worklist/$WORKLIST_ID/export \
  -H "Authorization: Bearer $TOKEN"

# Step 4: Simulate image received
curl -X POST http://localhost:46990/radiology/webhook/image-received \
  -H "Content-Type: application/json" \
  -d '{...}'

# Step 5: Verify status updates
mysql -u root prime -e "SELECT * FROM radiology_requests WHERE id='$REQUEST_ID';"
mysql -u root prime -e "SELECT * FROM radiology_billing WHERE request_id='$REQUEST_ID';"
```

**Verification**:
- ✅ Complete workflow executes
- ✅ All status updates occur
- ✅ Billing created automatically
- ✅ Notifications sent

---

### Test Phase 4: Performance Tests (Day 6)

**Objective**: Verify performance targets

**Test Cases**:
1. ✅ Accession number generation: < 10ms
2. ✅ Worklist creation: < 50ms
3. ✅ Webhook processing: < 500ms

**Execution**:
```bash
# Measure accession number generation
time curl -X POST http://localhost:46990/radiology/appointments \
  -H "Authorization: Bearer $TOKEN" \
  -d '{...}'

# Measure worklist query
time curl -X GET "http://localhost:46990/radiology/worklist?status=pending" \
  -H "Authorization: Bearer $TOKEN"

# Measure webhook processing
time curl -X POST http://localhost:46990/radiology/webhook/image-received \
  -H "Content-Type: application/json" \
  -d '{...}'
```

**Verification**:
- ✅ All operations meet performance targets
- ✅ No bottlenecks identified
- ✅ System scales well

---

### Test Phase 5: Error Handling Tests (Day 7)

**Objective**: Test error scenarios

**Test Cases**:
1. ✅ Invalid appointment ID
2. ✅ Duplicate AE Title
3. ✅ Missing required fields
4. ✅ Database connection errors
5. ✅ Webhook delivery failures

**Execution**:
```bash
# Test 1: Invalid appointment ID
curl -X POST http://localhost:46990/radiology/worklist \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"appointment_id":"invalid-uuid",...}'
# Expected: 404 error

# Test 2: Duplicate AE Title
curl -X POST http://localhost:46990/radiology/modalities \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"ae_title":"XRAY01",...}'  # Already exists
# Expected: 400 error

# Test 3: Missing required fields
curl -X POST http://localhost:46990/radiology/modalities \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"modality_name":"X-ray"}'  # Missing ae_title
# Expected: 400 error
```

**Verification**:
- ✅ Errors handled gracefully
- ✅ Appropriate error messages returned
- ✅ System doesn't crash

---

## Day 8-10: Production Deployment

### Task 8.1: Code Review

**Objective**: Review code for production readiness

**Checklist**:
- ✅ All tests passing
- ✅ No console.log statements (use proper logging)
- ✅ Error handling comprehensive
- ✅ Security best practices followed
- ✅ Documentation complete
- ✅ Performance acceptable

**Review Process**:
1. Review all new files
2. Check for security issues
3. Verify error handling
4. Check logging
5. Verify documentation

---

### Task 8.2: Staging Deployment

**Objective**: Deploy to staging environment

**Steps**:
1. Create staging branch
2. Deploy code to staging
3. Run all tests on staging
4. Verify functionality
5. Get approval for production

**Verification**:
- ✅ All tests pass on staging
- ✅ No errors in logs
- ✅ Performance acceptable
- ✅ Ready for production

---

### Task 8.3: Production Deployment

**Objective**: Deploy to production

**Steps**:
1. Create backup of production database
2. Deploy code to production
3. Run smoke tests
4. Monitor logs
5. Verify functionality

**Deployment Checklist**:
- ✅ Database backup created
- ✅ Code deployed
- ✅ Smoke tests passing
- ✅ Logs monitored
- ✅ Users notified

---

### Task 8.4: Production Monitoring

**Objective**: Monitor system after deployment

**Monitoring Tasks**:
1. Monitor error logs
2. Monitor performance metrics
3. Monitor webhook delivery
4. Monitor database performance
5. Gather user feedback

**Metrics to Monitor**:
- ✅ API response times
- ✅ Webhook delivery success rate
- ✅ Database query performance
- ✅ Error rates
- ✅ User feedback

---

### Task 8.5: Documentation & Handoff

**Objective**: Complete documentation and hand off to operations

**Documentation**:
- ✅ Deployment guide
- ✅ Operations manual
- ✅ Troubleshooting guide
- ✅ API documentation
- ✅ Architecture documentation

**Handoff**:
- ✅ Train operations team
- ✅ Provide documentation
- ✅ Establish support process
- ✅ Set up monitoring
- ✅ Define escalation procedures

---

## Testing Checklist

### Pre-Testing
- ✅ Backend code complete
- ✅ Routes registered
- ✅ Database tables ready
- ✅ Orthanc configured
- ✅ Webhooks configured

### Testing Phase
- ⏳ Run 12 test cases
- ⏳ Verify database updates
- ⏳ Check performance metrics
- ⏳ Test error scenarios
- ⏳ Verify webhook processing

### Post-Testing
- ⏳ Document results
- ⏳ Fix any issues
- ⏳ Get approval for deployment

---

## Deployment Checklist

### Pre-Deployment
- ⏳ Code review completed
- ⏳ All tests passing
- ⏳ Documentation complete
- ⏳ Staging deployment successful
- ⏳ Performance acceptable

### Deployment
- ⏳ Database backup created
- ⏳ Code deployed
- ⏳ Smoke tests passing
- ⏳ Logs monitored

### Post-Deployment
- ⏳ Monitor performance
- ⏳ Check error logs
- ⏳ Gather feedback
- ⏳ Document issues

---

## Success Criteria

✅ All 12 test cases passing  
✅ Orthanc webhooks working  
✅ Complete workflow functional  
✅ Performance targets met  
✅ Error handling working  
✅ Production deployment successful  
✅ Monitoring in place  
✅ Documentation complete  
✅ Team trained  
✅ Support process established  

---

## Risk Management

### Technical Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Webhook delivery failure | High | Implement retry logic, monitoring |
| Database performance | Medium | Monitor queries, optimize indexes |
| Orthanc connectivity | High | Test connectivity, redundancy |
| Image matching failure | High | Comprehensive testing, logging |

### Operational Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| User resistance | Medium | Training, documentation |
| Data migration issues | High | Thorough testing, rollback plan |
| Support gaps | Medium | Training, documentation, support plan |

---

## Rollback Plan

### If Issues Occur
1. Stop new deployments
2. Revert to previous version
3. Investigate issue
4. Fix and test
5. Redeploy

### Rollback Steps
```bash
# Revert code
git revert <commit-hash>

# Restart backend
systemctl restart backend

# Verify
curl -X GET http://localhost:46990/radiology/worklist
```

---

## Communication Plan

### Stakeholders
- Development team
- QA team
- Operations team
- Management
- Users

### Communication Schedule
- Daily standup (9 AM)
- Testing updates (3 PM)
- Deployment notification (before deployment)
- Post-deployment review (next day)

---

## Next Steps (Phase 5)

After Week 9 completion:
- Phase 5: Advanced Features (Week 10-11)
  - Analytics & Reporting
  - Equipment Management
  - Quality Control

---

## Files to Reference

### Testing
- RADIOLOGY_PHASE4_TESTING_GUIDE.md - Complete testing guide
- RADIOLOGY_PHASE4_WEEK8_READY.md - Testing checklist

### Implementation
- RADIOLOGY_PHASE4_IMPLEMENTATION_SUMMARY.md - Code examples
- RADIOLOGY_PHASE4_QUICK_START.md - API reference

### Status
- RADIOLOGY_PHASE4_STATUS.md - Current status
- RADIOLOGY_PHASE4_WEEK8_FINAL_SUMMARY.md - Week 8 summary

---

## Summary

Week 9 focuses on three critical areas:

1. **Orthanc Configuration** (Days 1-2)
   - Set up webhooks
   - Configure DICOM networking
   - Create worklist directory
   - Test connectivity

2. **Comprehensive Testing** (Days 3-7)
   - Unit tests
   - Integration tests
   - End-to-end tests
   - Performance tests
   - Error handling tests

3. **Production Deployment** (Days 8-10)
   - Code review
   - Staging deployment
   - Production deployment
   - Monitoring
   - Documentation & handoff

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Ready for Week 9 Implementation
