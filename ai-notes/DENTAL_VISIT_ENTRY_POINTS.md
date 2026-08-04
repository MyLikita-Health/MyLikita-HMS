# Dental Visit Workflow - Entry Points

## Overview
The dental visit workflow can now be accessed from multiple entry points within the dental module, providing flexibility for different clinical scenarios.

## Entry Points

### 1. Patient Dashboard Tab (Original)
**Path**: `/me/dental` → Select Patient → "Visit Documentation" Tab

**Flow**:
1. Navigate to Dental module
2. Select a patient from sidebar (Assigned or Out-Patients)
3. Click "Visit Documentation" tab in patient dashboard
4. Click "Start New Visit" button
5. Visit workflow opens in the main content area

**Use Case**: When reviewing a patient's complete record and wanting to document a new visit.

---

### 2. Appointments Sidebar (New - Primary)
**Path**: `/me/dental?section=appointments` → Appointment List → "Visit" Button

**Flow**:
1. Navigate to Dental module
2. Click "Appointments" tab in sidebar
3. View today's appointments in the sidebar list
4. For confirmed or in-progress appointments, click the "Visit" button
5. Visit workflow opens in the main content area (embedded mode)

**Features**:
- "Visit" button appears only for appointments with status: `confirmed` or `in_progress`
- Automatically links the visit to the appointment
- Patient information is pre-populated from the appointment
- Embedded mode with close button to return to appointments view

**Use Case**: Quick access during scheduled appointments - the most common clinical workflow.

---

### 3. Direct URL (Programmatic)
**Path**: `/me/dental/visits/{visitId}/{patientId}`

**Flow**:
- Direct navigation to a specific visit
- Can be used for:
  - Continuing an existing visit
  - Deep linking from other modules
  - Bookmarking specific visits

**Use Case**: Returning to an incomplete visit or accessing from external links.

---

## Visit Workflow Steps

Once started, all entry points lead to the same 8-step workflow:

1. **Chief Complaint** - Why is the patient here?
2. **Medical History** - Relevant medical background
3. **Clinical Examination** - Physical examination findings
4. **Investigations** - Lab tests, X-rays, etc.
5. **Diagnosis** - Clinical diagnosis
6. **Treatment Plan** - Proposed treatment
7. **Prescriptions** - Medications prescribed
8. **Clinical Decision** - Admit, discharge, refer, follow-up

---

## Technical Implementation

### Components
- `VisitDocumentation.jsx` - Main workflow component
- `Dental.jsx` - Handles routing and embedded mode
- `DentalAppointments.jsx` - Sidebar with "Visit" buttons
- `DentalDashboard.jsx` - Patient dashboard with visit tab

### Props for Embedded Mode
```javascript
<VisitDocumentation 
  patientId={patientId}
  appointmentId={appointmentId}
  visitId={visitId}
  onClose={handleCloseVisit}
  embedded={true}
/>
```

### URL Parameters
- `section` - Current sidebar section (appointments, assigned-patients, out-patients)
- `patientId` - Selected patient ID
- `visitMode` - 'new' for new visit, or visitId for existing
- `appointmentId` - Associated appointment (optional)

---

## User Experience

### Appointments Sidebar Flow (Recommended)
1. Dentist opens Dental module
2. Clicks "Appointments" tab
3. Sees list of today's appointments
4. Clicks "Visit" button on a confirmed appointment
5. Visit workflow opens in main area
6. Completes documentation
7. Clicks "Close" to return to appointments list

### Benefits
- Minimal navigation
- Context-aware (appointment linked)
- Quick access during busy clinic hours
- Sidebar remains visible for reference
- Easy to switch between appointments

---

## Backend Integration

### API Endpoints Used
- `POST /dental/visits/start` - Start new visit
- `GET /dental/visits/:visitId` - Get visit data
- `PUT /dental/visits/:visitId/step` - Update step data
- `POST /dental/visits/:visitId/complete` - Complete visit

### Database Tables
- `dental_visits` - Main visit record
- `dental_visit_steps` - Step completion tracking
- `dental_visit_investigations` - Investigation requests
- `dental_visit_attachments` - Files and images

---

## Future Enhancements

1. **Quick Visit Button** - Add to patient card for instant access
2. **Visit Templates** - Pre-fill common visit types
3. **Voice Dictation** - Speech-to-text for faster documentation
4. **Visit History** - List of previous visits in sidebar
5. **Notifications** - Alert when visit is incomplete
