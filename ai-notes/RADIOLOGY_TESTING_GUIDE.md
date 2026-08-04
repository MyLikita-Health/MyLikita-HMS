# Radiology Module - Complete Testing Guide

## Quick Start & Testing Instructions

---

## 🚀 Quick Setup (5 Minutes)

### Step 1: Run Database Migration

```bash
cd backend/sql
node run_radiology_migration.js
```

**What this does**:
- Creates 14 radiology tables
- Seeds 35+ procedures with pricing
- Adds 20+ permissions
- Sets up DICOM and worklist tables

### Step 2: Update User Permissions

Add "Radiology" to your user's accessTo array:

```sql
UPDATE users 
SET accessTo = JSON_ARRAY_APPEND(accessTo, '$', 'Radiology')
WHERE id = 'your-user-id';
```

### Step 3: Start Servers

```bash
# Terminal 1: Backend
cd backend
npm run dev

# Terminal 2: Frontend
cd frontend
npm run dev
```

### Step 4: Access Module

Navigate to: `http://localhost:5173/me/radiology`

---

## 📋 Complete Feature Testing Checklist

### ✅ Test 1: Dashboard Access

**Steps**:
1. Login to system
2. Navigate to `/me/radiology`
3. Verify dashboard loads

**Expected Results**:
- Dashboard displays with 4 stat cards
- Quick action buttons visible
- No errors in console

**Status**: ⬜ Pass / ⬜ Fail

---

### ✅ Test 2: Create Radiology Request

**Steps**:
1. Click "Create Request" or go to `/me/radiology/requests/new`
2. Fill in form:
   - Patient: Select existing patient
   - Procedure: "Chest X-Ray PA" (₦5,000)
   - Clinical Indication: "Suspected pneumonia"
   - Priority: "Urgent"
3. Click "Submit Request"

**Expected Results**:
- Success message displayed
- Request created with status "pending"
- Redirected to request details
- Request appears in requests list

**Status**: ⬜ Pass / ⬜ Fail

---

### ✅ Test 3: View Requests List

**Steps**:
1. Navigate to `/me/radiology/requests`
2. Test filters:
   - Filter by status: "pending"
   - Filter by priority: "urgent"
   - Filter by date range

**Expected Results**:
- All requests displayed in table
- Filters work correctly
- Status badges show correct colors
- Priority badges display properly

**Status**: ⬜ Pass / ⬜ Fail

---

### ✅ Test 4: Schedule Appointment

**Steps**:
1. From requests list, click "Schedule" on a pending request
2. Or go to `/me/radiology/appointments/schedule`
3. Fill in form:
   - Request: Select from dropdown
   - Date: Tomorrow's date
   - Time: 10:00 AM
   - Room: "X-Ray Room 1"
4. Click "Schedule Appointment"

**Expected Results**:
- Appointment created successfully
- Status changes to "scheduled"
- Appointment appears in appointments list
- Request status updates

**Status**: ⬜ Pass / ⬜ Fail

---

### ✅ Test 5: Check In Patient

**Steps**:
1. Navigate to `/me/radiology/appointments`
2. Find scheduled appointment
3. Click "Check In" button
4. Confirm check-in

**Expected Results**:
- Status changes to "checked-in"
- Check-in button disappears
- "Start Examination" button appears
- Timestamp recorded

**Status**: ⬜ Pass / ⬜ Fail

---

### ✅ Test 6: Record Examination

**Steps**:
1. From checked-in appointment, click "Start Examination"
2. Fill in examination form:
   - Technique: "Standard PA and lateral views"
   - Image Quality: "Good"
   - Contrast Used: Check box
   - Contrast Type: "Iodinated"
   - Contrast Volume: "50"
   - Technical Notes: "Patient cooperative"
3. Click "Record Examination"

**Expected Results**:
- Examination record created
- Redirected to examination details
- All data saved correctly
- Status shows "in-progress"

**Status**: ⬜ Pass / ⬜ Fail

---

### ✅ Test 7: Upload DICOM Images (Optional - Requires Orthanc)

**Steps**:
1. From examination details, click "Upload Images"
2. Select a DICOM file (.dcm)
3. Click "Upload to PACS"
4. Wait for upload progress

**Expected Results**:
- Progress bar shows upload status
- Success message on completion
- Image count updates
- File stored in Orthanc

**Status**: ⬜ Pass / ⬜ Fail / ⬜ Skipped (No Orthanc)

---

### ✅ Test 8: Complete Examination

**Steps**:
1. From examination details page
2. Click "Complete Exam"
3. Confirm completion

**Expected Results**:
- Status changes to "completed"
- "Create Report" button appears
- Complete/Upload buttons disappear
- Timestamp recorded

**Status**: ⬜ Pass / ⬜ Fail

---

### ✅ Test 9: Create Report Template

**Steps**:
1. Navigate to `/me/radiology/reports/templates`
2. Click "New Template"
3. Fill in form:
   - Name: "Chest X-Ray Normal"
   - Category: "X-Ray"
   - Findings: "The lungs are clear. No infiltrates, masses, or effusions. Heart size is normal."
   - Impression: "Normal chest radiograph."
   - Recommendations: "No further imaging required."
4. Click "Save Template"

**Expected Results**:
- Template created successfully
- Appears in templates list
- Can be edited
- Can be deleted

**Status**: ⬜ Pass / ⬜ Fail

---

### ✅ Test 10: Create Report (Draft)

**Steps**:
1. From completed examination, click "Create Report"
2. Select template: "Chest X-Ray Normal"
3. Verify template text auto-fills
4. Modify as needed
5. Click "Save Draft"

**Expected Results**:
- Report saved as draft
- Can be edited later
- Not visible to referring doctor
- Status shows "draft"

**Status**: ⬜ Pass / ⬜ Fail

---

### ✅ Test 11: Finalize Report

**Steps**:
1. Open draft report
2. Click "Edit" if needed
3. Ensure Findings and Impression are filled
4. Click "Finalize Report"
5. Confirm finalization

**Expected Results**:
- Report status changes to "finalized"
- Cannot be edited anymore
- Request status changes to "reported"
- Report visible to referring doctor

**Status**: ⬜ Pass / ⬜ Fail

---

### ✅ Test 12: View Report

**Steps**:
1. Navigate to `/me/radiology/reports`
2. Click "View" on finalized report
3. Test print functionality
4. Test PDF download (if configured)

**Expected Results**:
- Professional report layout
- All sections displayed
- Print preview works
- PDF downloads (if configured)

**Status**: ⬜ Pass / ⬜ Fail

---

### ✅ Test 13: View DICOM Images (Optional - Requires Orthanc & OHIF)

**Steps**:
1. From examination with uploaded images
2. Click "View Images in OHIF Viewer"
3. Test viewer controls:
   - Zoom (mouse wheel)
   - Pan (click and drag)
   - Window/Level (right-click drag)

**Expected Results**:
- OHIF viewer opens
- Images load correctly
- All controls work
- Can view in full screen

**Status**: ⬜ Pass / ⬜ Fail / ⬜ Skipped (No OHIF)

---

### ✅ Test 14: Patient Study History

**Steps**:
1. Navigate to `/me/radiology/dicom/studies/{patientId}`
2. View all studies for patient
3. Test filters:
   - Filter by modality
   - Filter by date range

**Expected Results**:
- All patient studies displayed
- Study cards show thumbnails
- Filters work correctly
- Can click to view in OHIF

**Status**: ⬜ Pass / ⬜ Fail / ⬜ Skipped (No studies)

---

### ✅ Test 15: Filters and Search

**Test each list page**:
- Requests list filters
- Appointments list filters
- Reports list filters
- Study list filters

**Expected Results**:
- All filters work correctly
- Results update immediately
- No errors in console
- Empty states display properly

**Status**: ⬜ Pass / ⬜ Fail

---

## 🔧 Advanced Testing (Optional)

### Test 16: Concurrent Users

**Steps**:
1. Open system in 2 browsers
2. Login as different users
3. Create requests simultaneously
4. Schedule appointments simultaneously

**Expected Results**:
- No conflicts
- Data syncs correctly
- No race conditions

**Status**: ⬜ Pass / ⬜ Fail

---

### Test 17: Large DICOM Files

**Steps**:
1. Upload DICOM file > 50MB
2. Monitor upload progress
3. Verify successful upload

**Expected Results**:
- Progress bar updates smoothly
- Upload completes successfully
- No timeout errors

**Status**: ⬜ Pass / ⬜ Fail / ⬜ Skipped

---

### Test 18: Permissions Testing

**Steps**:
1. Create user without radiology permissions
2. Try to access `/me/radiology`
3. Add permissions
4. Verify access granted

**Expected Results**:
- Access denied without permissions
- Access granted with permissions
- Proper error messages

**Status**: ⬜ Pass / ⬜ Fail

---

## 🐛 Common Issues & Solutions

### Issue 1: Cannot Access Radiology Module
**Symptoms**: Menu item not visible or 404 error

**Solutions**:
```sql
-- Check user permissions
SELECT accessTo FROM users WHERE id = 'your-user-id';

-- Add Radiology access
UPDATE users 
SET accessTo = JSON_ARRAY_APPEND(accessTo, '$', 'Radiology')
WHERE id = 'your-user-id';
```

---

### Issue 2: DICOM Upload Fails
**Symptoms**: Upload error or timeout

**Solutions**:
1. Check Orthanc is running:
   ```bash
   curl http://localhost:8042/system
   ```

2. Verify environment variables:
   ```bash
   # backend/.env
   ORTHANC_URL=http://localhost:8042
   ORTHANC_USERNAME=orthanc
   ORTHANC_PASSWORD=orthanc
   ```

3. Check file is valid DICOM format

---

### Issue 3: Images Not Showing in Viewer
**Symptoms**: Viewer opens but no images

**Solutions**:
1. Verify study_instance_uid is set
2. Check OHIF_VIEWER_URL configuration
3. Ensure DICOMweb is enabled in Orthanc
4. Check browser console for errors

---

### Issue 4: Cannot Finalize Report
**Symptoms**: Finalize button disabled or error

**Solutions**:
1. Ensure Findings field is filled
2. Ensure Impression field is filled
3. Check user has finalize permission
4. Verify report is in draft status

---

### Issue 5: PDF Download Not Working
**Symptoms**: PDF button missing or error

**Solutions**:
- PDF generation requires additional setup
- Install PDF library (puppeteer or pdfkit)
- Configure backend PDF generation
- See documentation for setup

---

## 📊 Test Results Summary

### Overall Results

| Feature | Status | Notes |
|---------|--------|-------|
| Dashboard | ⬜ | |
| Create Request | ⬜ | |
| Schedule Appointment | ⬜ | |
| Check In Patient | ⬜ | |
| Record Examination | ⬜ | |
| Upload DICOM | ⬜ | |
| Complete Examination | ⬜ | |
| Create Template | ⬜ | |
| Create Report | ⬜ | |
| Finalize Report | ⬜ | |
| View Report | ⬜ | |
| View DICOM Images | ⬜ | |
| Patient History | ⬜ | |
| Filters/Search | ⬜ | |

**Legend**: ✅ Pass | ❌ Fail | ⏭️ Skipped

---

## 🎯 Performance Benchmarks

### Expected Performance

| Metric | Target | Actual |
|--------|--------|--------|
| Dashboard Load | < 2s | ___ |
| Request Creation | < 1s | ___ |
| DICOM Upload (10MB) | < 30s | ___ |
| Report Generation | < 2s | ___ |
| Image Viewer Load | < 5s | ___ |

---

## 📝 Test Environment

**Date**: _______________  
**Tester**: _______________  
**Environment**: Development / Staging / Production  
**Browser**: _______________  
**OS**: _______________  

**Database**:
- MySQL Version: _______________
- Radiology Tables: ⬜ Created
- Procedures Seeded: ⬜ Yes
- Permissions Added: ⬜ Yes

**Orthanc PACS**:
- Installed: ⬜ Yes / ⬜ No
- Version: _______________
- Accessible: ⬜ Yes / ⬜ No

**OHIF Viewer**:
- Configured: ⬜ Yes / ⬜ No
- URL: _______________
- Working: ⬜ Yes / ⬜ No

---

## 🚦 Test Status

**Overall Status**: ⬜ All Pass / ⬜ Some Fail / ⬜ Not Started

**Critical Issues**: _______________

**Minor Issues**: _______________

**Recommendations**: _______________

---

## 📞 Support

If you encounter issues:

1. Check this troubleshooting guide
2. Review full documentation:
   - RADIOLOGY_QUICK_START_GUIDE.md
   - RADIOLOGY_IMPLEMENTATION_SUMMARY.md
   - DICOM_INTEGRATION_STRATEGY.md
3. Check browser console for errors
4. Verify database migrations ran successfully
5. Contact system administrator

---

**Testing Complete**: ⬜ Yes / ⬜ No  
**Ready for Production**: ⬜ Yes / ⬜ No  
**Sign-off**: _______________  
**Date**: _______________
