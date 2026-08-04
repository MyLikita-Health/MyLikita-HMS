# Orthanc Configuration Guide
## DICOM Worklist & Webhook Setup

**Date**: March 11, 2026  
**Status**: Week 9 Implementation  
**Purpose**: Configure Orthanc for modality integration

---

## Prerequisites

- Orthanc installed and running
- Backend API running on port 46990
- Network connectivity between Orthanc and backend
- Root/admin access to Orthanc configuration

---

## Step 1: Verify Orthanc Installation

```bash
# Check if Orthanc is running
curl -X GET http://localhost:8042/system

# Expected response includes version and configuration
```

---

## Step 2: Locate Configuration File

```bash
# Find orthanc.json
find / -name "orthanc.json" 2>/dev/null

# Common locations:
# /etc/orthanc/orthanc.json
# /opt/orthanc/orthanc.json
# /usr/local/etc/orthanc/orthanc.json
```

---

## Step 3: Backup Configuration

```bash
# Create backup
cp /etc/orthanc/orthanc.json /etc/orthanc/orthanc.json.backup

# Verify backup
ls -la /etc/orthanc/orthanc.json*
```

---

## Step 4: Configure Webhooks

Add to orthanc.json:

```json
"Webhooks": {
  "ImageReceived": "http://backend:46990/radiology/webhook/image-received",
  "ImageStored": "http://backend:46990/radiology/webhook/image-stored",
  "StudyCompleted": "http://backend:46990/radiology/webhook/study-completed",
  "ModalityStatus": "http://localhost:46990/radiology/webhook/modality-status"
}
```

---

## Step 5: Configure Worklist

Add to orthanc.json:

```json
"ServeFolders": {
  "/worklists": "/var/lib/orthanc/worklists"
}
```

---

## Step 6: Create Worklist Directory

```bash
mkdir -p /var/lib/orthanc/worklists
chmod 755 /var/lib/orthanc/worklists
```

---

## Step 7: Restart Orthanc

```bash
systemctl restart orthanc

# Verify restart
systemctl status orthanc
```

---

## Step 8: Test Configuration

```bash
# Test webhook endpoint
curl -X POST http://localhost:46990/radiology/webhook/test

# Test Orthanc API
curl -X GET http://localhost:8042/system
```

---

**Status**: Configuration Complete
