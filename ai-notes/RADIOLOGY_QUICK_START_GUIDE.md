# Radiology Module - Quick Start Guide

## Getting Started in 5 Minutes

This guide will help you start using the radiology module immediately.

---

## Prerequisites

- ✅ Database migrations run
- ✅ Backend server running (port 46990)
- ✅ Frontend server running
- ✅ User has "Radiology" in accessTo array
- ✅ Orthanc PACS server running (optional for basic testing)

---

## Step 1: Access the Module

1. Login to the system
2. Navigate to `/me/radiology`
3. You should see the Radiology Dashboard

**Dashboard Shows**:
- Today's Appointments
- Pending Requests
- Completed Today
- Pending Reports

---

## Step 2: Create Your First Request

### As a Doctor:

1. Go to patient record
2. Click "Create Radiology Request" (or navigate to `/me/radiology/requests/new`)
3. Fill in the form:
   - **Patient**: Auto-selected or search
   - **Procedure**: Select from dropdown (e.g., "Chest X-Ray PA")
   - **Clinical Indication**: "Suspected pneumonia"
   - **Priority**: Select (routine/urgent/emergency/stat)
4. Click "Submit Request"

**Result**: Request created with status "pending"

---

## Step 3: Schedule an Appointment

### As a Receptionist:

1. Navigate to `/me/radiology/appointments`
2. Click "Schedule Appointment" or go to scheduler
3. Fill in the form:
   - **Request**: Select from pending requests
   - **Date & Time**: Choose appointment slot
   - **Room**: Optional (e.g., "X-Ray Room 1")
   - **Notes**: Optional
4. Click "Schedule"

**Result**: Appointment created with status "scheduled"

---

## Step 4: Check In Patient

### When Patient Arrives:

1. Go to `/me/radiology/appointments`
2. Find today's appointments
3. Click "Check In" button for the patient
4. Confirm check-in

**Result**: Appointment status changes to "checked-in"

---

## Step 5: Perform Examination

### As a Technician:

1. From appointments list, click "Start Examination"
2. Fill in examination details:
   - **Technique Used**: "Standard PA and lateral views"
   - **Image Quality**: Select (excellent/good/adequate/poor)
   - **Contrast Used**: Check if applicable
     - Type: "Iodinated"
     - Volume: "50 ml"
   - **Technical Notes**: Any observations
3. Click "Record Examination"

**Result**: Examination record created

---

## Step 6: Upload Images

### Upload DICOM Files:

1. From examination details, click "Upload Images"
2. Select DICOM file from your computer
3. Click "Upload to PACS"
4. Wait for upload to complete

**Result**: Images stored in Orthanc PACS

**Note**: If Orthanc is not running, you can skip this step for testing

---

## Step 7: Complete Examination

1. Review examination details
2. Click "Complete Exam"
3. Confirm completion

**Result**: Examination status changes to "completed"

---

## Step 8: Create Report

### As a Radiologist:

1. From examination details, click "Create Report"
2. Optionally select a template
3. Fill in report sections:
   - **Clinical History**: "Patient presents with cough and fever"
   - **Technique**: Auto-filled from examination
   - **Findings**: "Clear lung fields. No infiltrates. Heart size normal."
   - **Impression**: "Normal chest radiograph"
   - **Recommendations**: "No further imaging required"
4. Click "Save Draft" (to save work in progress)
5. Or click "Finalize Report" (to complete)

**Result**: Report created and request status updated to "reported"

---

## Step 9: View Report

### View the Report:

1. Navigate to `/me/radiology/reports`
2. Find your report in the list
3. Click "View" to see the report
4. Options:
   - **Print**: Print the report
   - **Download PDF**: Save as PDF (if configured)
   - **Edit**: Edit draft reports

---

## Step 10: View Images (Optional)

### If Orthanc is Running:

1. From examination details, click "View Images in OHIF Viewer"
2. OHIF viewer opens with the study
3. Use viewer tools:
   - **Zoom**: Mouse wheel
   - **Pan**: Click and drag
   - **Window/Level**: Right-click and drag
   - **Measurements**: Use toolbar

---

## Common Workflows

### Workflow 1: Emergency Request

```
Doctor creates request (Priority: STAT)
↓
Receptionist schedules immediately
↓
Patient arrives and checks in
↓
Technician performs exam immediately
↓
Images uploaded
↓
Radiologist creates report immediately
↓
Doctor views report
```

### Workflow 2: Routine Request

```
Doctor creates request (Priority: Routine)
↓
Receptionist schedules for next available slot
↓
Patient arrives on scheduled date
↓
Check-in → Examination → Images → Report
↓
Doctor reviews report at convenience
```

### Workflow 3: Follow-up Study

```
Doctor creates request with comparison notes
↓
Schedule appointment
↓
Perform examination
↓
Radiologist compares with previous studies
↓
Report includes comparison findings
```

---

## Quick Reference

### URLs

```
Dashboard:           /me/radiology
Requests:            /me/radiology/requests
New Request:         /me/radiology/requests/new
Appointments:        /me/radiology/appointments
Examinations:        /me/radiology/examinations
Reports:             /me/radiology/reports
Templates:           /me/radiology/reports/templates
```

### Status Flow

**Request Status**:
```
pending → scheduled → in-progress → completed → reported
```

**Appointment Status**:
```
scheduled → checked-in → in-progress → completed
```

**Report Status**:
```
draft → finalized
```

---

## Keyboard Shortcuts

Currently no keyboard shortcuts implemented. Use mouse/touch navigation.

---

## Tips & Tricks

### For Doctors:
- Add detailed clinical indication for better reports
- Set appropriate priority levels
- Review reports promptly

### For Receptionists:
- Schedule appointments with buffer time
- Confirm patient details before check-in
- Keep room assignments updated

### For Technicians:
- Record technique details accurately
- Assess image quality honestly
- Add technical notes for radiologist

### For Radiologists:
- Use templates for common findings
- Save drafts frequently
- Finalize reports promptly
- Include comparison with previous studies

---

## Troubleshooting

### Issue: Cannot see Radiology menu
**Solution**: Ensure user has "Radiology" in accessTo array

### Issue: Cannot create request
**Solution**: Check permissions - need `radiology.create_request`

### Issue: DICOM upload fails
**Solution**: 
1. Check Orthanc is running (http://localhost:8042)
2. Verify ORTHANC_URL in .env
3. Check file is valid DICOM format

### Issue: Images not showing in viewer
**Solution**:
1. Verify images uploaded successfully
2. Check OHIF_VIEWER_URL configuration
3. Ensure study_instance_uid is set

### Issue: Cannot finalize report
**Solution**: Ensure Findings and Impression fields are filled

### Issue: PDF download not working
**Solution**: PDF generation library needs to be configured (see documentation)

---

## Sample Data

### Sample Procedures (Already Seeded)

**X-Ray**:
- Chest X-Ray PA - ₦5,000
- Chest X-Ray PA & Lateral - ₦7,500
- Abdomen X-Ray - ₦6,000
- Skull X-Ray - ₦8,000

**CT Scan**:
- CT Brain Plain - ₦35,000
- CT Brain with Contrast - ₦45,000
- CT Chest - ₦40,000
- CT Abdomen & Pelvis - ₦50,000

**MRI**:
- MRI Brain Plain - ₦60,000
- MRI Brain with Contrast - ₦75,000
- MRI Spine - ₦65,000

**Ultrasound**:
- Ultrasound Abdomen - ₦8,000
- Ultrasound Pelvis - ₦8,000
- Ultrasound Obstetric - ₦10,000

---

## Report Templates

### Create Your First Template

1. Navigate to `/me/radiology/reports/templates`
2. Click "New Template"
3. Fill in:
   - **Name**: "Chest X-Ray Normal"
   - **Category**: "X-Ray"
   - **Findings**: "The lungs are clear. No infiltrates, masses, or effusions. Heart size is normal. Mediastinum is unremarkable. Bony structures are intact."
   - **Impression**: "Normal chest radiograph."
   - **Recommendations**: "No further imaging required at this time."
4. Click "Save Template"

**Use Template**:
- When creating a report, select template from dropdown
- Template text auto-fills sections
- Customize as needed

---

## Best Practices

### Request Creation
- ✅ Provide detailed clinical indication
- ✅ Set appropriate priority
- ✅ Include relevant history
- ❌ Don't create duplicate requests

### Scheduling
- ✅ Allow buffer time between appointments
- ✅ Confirm patient contact information
- ✅ Send appointment reminders
- ❌ Don't overbook time slots

### Examination
- ✅ Record all technical details
- ✅ Assess image quality honestly
- ✅ Note any complications
- ❌ Don't skip quality checks

### Reporting
- ✅ Use templates for efficiency
- ✅ Include comparison with previous studies
- ✅ Be clear and concise
- ✅ Finalize reports promptly
- ❌ Don't leave reports in draft indefinitely

---

## Next Steps

### After Basic Setup:

1. **Configure Orthanc PACS**
   - See DICOM_INTEGRATION_STRATEGY.md
   - Set up DICOMweb
   - Configure modalities

2. **Set Up OHIF Viewer**
   - Install OHIF or use hosted version
   - Configure viewer URL
   - Test image viewing

3. **Create Report Templates**
   - Normal findings for common procedures
   - Common pathology templates
   - Procedure-specific templates

4. **Configure Billing** (When implemented)
   - Set up revenue accounts
   - Configure auto-billing
   - Test payment processing

5. **Train Users**
   - Doctors: Request creation
   - Receptionists: Scheduling
   - Technicians: Examination workflow
   - Radiologists: Reporting

6. **Test End-to-End**
   - Complete workflow with test patient
   - Verify all integrations
   - Check permissions

---

## Support & Documentation

### Full Documentation:
- **RADIOLOGY_COMPLETE_IMPLEMENTATION_PLAN.md** - Complete implementation plan
- **RADIOLOGY_IMPLEMENTATION_SUMMARY.md** - Feature summary
- **DICOM_INTEGRATION_STRATEGY.md** - DICOM setup guide
- **DICOM_MODALITY_INTEGRATION_GUIDE.md** - Modality integration

### Phase Completion Docs:
- **RADIOLOGY_PHASE2_WEEK3_COMPLETE.md** - Request management
- **RADIOLOGY_PHASE2_WEEK4_COMPLETE.md** - Examination workflow
- **RADIOLOGY_PHASE2_WEEK5_COMPLETE.md** - DICOM viewing
- **RADIOLOGY_PHASE3_WEEK6_COMPLETE.md** - Report generation

### Need Help?
- Check troubleshooting section above
- Review full documentation
- Contact system administrator

---

## Quick Command Reference

### Database Setup
```bash
cd backend/sql
node run_radiology_migration.js
```

### Start Orthanc (Docker)
```bash
docker run -p 8042:8042 jodogne/orthanc
```

### Check Orthanc Status
```bash
curl http://localhost:8042/system
```

### Backend
```bash
cd backend
npm run dev
```

### Frontend
```bash
cd frontend
npm run dev
```

---

## Success Checklist

After completing this guide, you should be able to:

- ✅ Access the radiology module
- ✅ Create a radiology request
- ✅ Schedule an appointment
- ✅ Check in a patient
- ✅ Record an examination
- ✅ Upload DICOM images (if Orthanc configured)
- ✅ Complete an examination
- ✅ Create a report
- ✅ Finalize a report
- ✅ View reports
- ✅ Use report templates
- ✅ View images in OHIF (if configured)

---

## What's Next?

### Immediate:
- Practice the complete workflow
- Create report templates
- Configure Orthanc PACS

### Short Term:
- Set up billing integration
- Configure modality worklist
- Train all users

### Long Term:
- Optimize workflows
- Add custom templates
- Integrate with other modules

---

**You're now ready to use the Radiology Module!**

For detailed information on any feature, refer to the complete documentation.

**Last Updated**: 2026-03-09  
**Version**: 1.0  
**Status**: Phase 1-3 Complete
