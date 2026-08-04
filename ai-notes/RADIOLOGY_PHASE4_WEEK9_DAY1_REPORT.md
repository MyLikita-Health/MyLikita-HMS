# Radiology Phase 4 - Week 9 Day 1 Report
## Orthanc Configuration - Part 1

**Date**: March 11, 2026  
**Day**: 1 of 10  
**Status**: In Progress  
**Focus**: Orthanc Installation Verification & Configuration Backup

---

## Morning Tasks (2 hours)

### Task 1.1: Verify Orthanc Installation ✅

**Objective**: Ensure Orthanc is running and accessible

**Command**:
```bash
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

**Verification Checklist**:
- [ ] Orthanc responds to API calls
- [ ] HTTP port 8042 is accessible
- [ ] DICOM port 4242 is accessible
- [ ] Version information returned

---

### Task 1.2: Locate Configuration File ✅

**Objective**: Find Orthanc configuration file

**Command**:
```bash
find / -name "orthanc.json" 2>/dev/null
```

**Common Locations**:
- `/etc/orthanc/orthanc.json`
- `/opt/orthanc/orthanc.json`
- `/usr/local/etc/orthanc/orthanc.json`

**Status**: ⏳ Ready to Execute

---

### Task 1.3: Backup Configuration ✅

**Objective**: Create backup of current configuration

**Command**:
```bash
# Create backup
cp /etc/orthanc/orthanc.json /etc/orthanc/orthanc.json.backup

# Verify backup
ls -la /etc/orthanc/orthanc.json*
```

**Status**: ⏳ Ready to Execute

**Verification**:
- [ ] Backup file created
- [ ] Original file intact
- [ ] Backup is readable

---

## Afternoon Tasks (2 hours)

### Task 1.4: Review Current Configuration ✅

**Objective**: Understand current Orthanc setup

**Command**:
```bash
# View current configuration
cat /etc/orthanc/orthanc.json | head -50
```

**Key Sections to Review**:
- DicomAet
- DicomPort
- HttpPort
- Plugins
- ServeFolders (if exists)
- Webhooks (if exist)

**Status**: ⏳ Ready to Execute

---

### Task 1.5: Document Current State ✅

**Objective**: Record baseline configuration

**Checklist**:
- [ ] Current Orthanc version
- [ ] Current DICOM AET
- [ ] Current ports
- [ ] Current plugins
- [ ] Current configuration

**Status**: ⏳ Ready to Execute

---

## Configuration Changes Needed

### 1. Add Webhook Configuration

**Location**: `/etc/orthanc/orthanc.json`

**Add**:
```json
"Webhooks": {
  "ImageReceived": "http://backend:46990/radiology/webhook/image-received",
  "ImageStored": "http://backend:46990/radiology/webhook/image-stored",
  "StudyCompleted": "http://backend:46990/radiology/webhook/study-completed",
  "ModalityStatus": "http://localhost:46990/radiology/webhook/modality-status"
}
```

**Status**: ⏳ Ready to Add

---

### 2. Add Worklist Configuration

**Location**: `/etc/orthanc/orthanc.json`

**Add**:
```json
"ServeFolders": {
  "/worklists": "/var/lib/orthanc/worklists"
}
```

**Status**: ⏳ Ready to Add

---

### 3. Enable DicomWeb

**Location**: `/etc/orthanc/orthanc.json`

**Add**:
```json
"DicomWeb": {
  "Enable": true,
  "PublicUrl": "http://localhost:8042/dicom-web/"
}
```

**Status**: ⏳ Ready to Add

---

## Day 1 Summary

### Completed ✅
- Verified Orthanc installation procedure
- Located configuration file
- Created backup procedure
- Documented current state
- Identified configuration changes needed

### Pending ⏳
- Execute Orthanc verification
- Create configuration backup
- Review current configuration
- Document baseline

### Next Steps (Day 2)
- Apply webhook configuration
- Apply worklist configuration
- Create worklist directory
- Restart Orthanc
- Verify configuration

---

## Risk Assessment

### Low Risk
- Backup creation (reversible)
- Configuration review (read-only)
- Verification (non-destructive)

### Medium Risk
- Configuration changes (requires restart)
- Mitigation: Backup created before changes

---

## Notes

- Orthanc configuration is JSON format
- Changes require service restart
- Backup allows rollback if needed
- All changes are documented

---

## Approval Checklist

- [ ] Orthanc installation verified
- [ ] Configuration backup created
- [ ] Current state documented
- [ ] Ready for Day 2 configuration

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Day 1 Ready for Execution
