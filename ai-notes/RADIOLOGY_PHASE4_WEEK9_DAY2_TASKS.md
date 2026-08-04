# Radiology Phase 4 - Week 9 Day 2 Tasks
## Orthanc Configuration - Part 2

**Date**: March 11, 2026  
**Day**: 2 of 10  
**Status**: Ready to Execute  
**Focus**: Apply Configuration & Verify Webhooks

---

## Morning Tasks (2 hours)

### Task 2.1: Apply Webhook Configuration ✅

**Objective**: Add webhook endpoints to Orthanc

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
```

**Status**: ⏳ Ready to Execute

---

### Task 2.2: Apply Worklist Configuration ✅

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
```

**Status**: ⏳ Ready to Execute

---

### Task 2.3: Enable DicomWeb ✅

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
```

**Status**: ⏳ Ready to Execute

---

## Afternoon Tasks (2 hours)

### Task 2.4: Create Worklist Directory ✅

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

### Task 2.5: Restart Orthanc ✅

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

### Task 2.6: Verify Webhook Configuration ✅

**Objective**: Confirm webhooks are configured

**Commands**:
```bash
# Check configuration
grep -A 10 "Webhooks" /etc/orthanc/orthanc.json

# Expected output:
# "Webhooks": {
#   "ImageReceived": "http://backend:46990/radiology/webhook/image-received",
#   "ImageStored": "http://backend:46990/radiology/webhook/image-stored",
#   "StudyCompleted": "http://backend:46990/radiology/webhook/study-completed",
#   "ModalityStatus": "http://localhost:46990/radiology/webhook/modality-status"
# }
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

## Testing Webhook Connectivity

### Test 1: Verify Backend Accessibility

**Command**:
```bash
# From Orthanc server, test backend connectivity
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

### Test 2: Check Webhook Logs

**Command**:
```bash
# Check Orthanc logs for webhook configuration
tail -50 /var/log/orthanc/Orthanc.log | grep -i webhook
```

**Expected**: Webhook configuration messages

**Status**: ⏳ Ready to Execute

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

---

## Day 2 Summary

### Tasks to Complete
- [ ] Apply webhook configuration
- [ ] Apply worklist configuration
- [ ] Enable DicomWeb
- [ ] Create worklist directory
- [ ] Restart Orthanc
- [ ] Verify configuration
- [ ] Test webhook connectivity

### Expected Outcomes
- ✅ Orthanc configured with webhooks
- ✅ Worklist directory created
- ✅ DicomWeb enabled
- ✅ Service running
- ✅ Webhooks accessible

### Next Steps (Day 3)
- Begin comprehensive testing
- Run unit tests
- Verify all endpoints

---

## Configuration Summary

### Orthanc Configuration Changes

**File**: `/etc/orthanc/orthanc.json`

**Additions**:
1. Webhooks section (4 endpoints)
2. ServeFolders section (worklist directory)
3. DicomWeb section (enable API)

**Restart Required**: Yes

**Rollback Available**: Yes (backup created)

---

## Approval Checklist

- [ ] Configuration changes applied
- [ ] Orthanc restarted successfully
- [ ] Webhooks verified
- [ ] Worklist directory created
- [ ] Backend connectivity confirmed
- [ ] Ready for Day 3 testing

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Day 2 Ready for Execution
