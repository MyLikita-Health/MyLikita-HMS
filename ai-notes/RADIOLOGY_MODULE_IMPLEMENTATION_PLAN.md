# Radiology Module - Complete Implementation Plan

## Overview
Comprehensive radiology/imaging module integrated with existing patient records, doctor workflow, billing, and inventory systems.

---

## Phase 1: Database Schema & Core Tables

### 1.1 Core Tables

#### radiology_procedures
```sql
- id (VARCHAR PRIMARY KEY)
- procedure_code (VARCHAR UNIQUE)
- procedure_name (VARCHAR)
- category (ENUM: 'x-ray', 'ultrasound', 'ct-scan', 'mri', 'mammography', 'fluoroscopy', 'other')
- body_part (VARCHAR) -- chest, abdomen, skull, spine, etc.
- base_price (DECIMAL)
- contrast_price (DECIMAL) -- additional cost if contrast used
- estimated_duration (INT) -- minutes
- requires_preparation (BOOLEAN)
- preparation_instructions (TEXT)
- radiation_dose (VARCHAR) -- for safety tracking
- revenue_account_head (VARCHAR)
- revenue_account_subhead (VARCHAR)
- is_active (BOOLEAN)
- facilityId (VARCHAR)
- created_at, updated_at (TIMESTAMP)
```

#### radiology_requests
```sql
- id (VARCHAR PRIMARY KEY)
- request_number (VARCHAR UNIQUE)
- patient_id (VARCHAR FK -> patientrecords)
- requesting_doctor_id (VARCHAR FK -> users)
- procedure_id (VARCHAR FK -> radiology_procedures)
- priority (ENUM: 'routine', 'urgent', 'emergency', 'stat')
- clinical_indication (TEXT) -- reason for exam
- clinical_notes (TEXT)
- special_instructions (TEXT)
- contrast_required (BOOLEAN)
- patient_prepared (BOOLEAN)
- request_date (DATETIME)
- requested_date (DATE) -- when exam should be done
- status (ENUM: 'pending', 'scheduled', 'in-progress', 'completed', 'cancelled', 'reported')
- facilityId (VARCHAR)
- created_by (VARCHAR)
- created_at, updated_at (TIMESTAMP)
```

#### radiology_appointments
```sql
- id (VARCHAR PRIMARY KEY)
- request_id (VARCHAR FK -> radiology_requests)
- patient_id (VARCHAR FK -> patientrecords)
- procedure_id (VARCHAR FK -> radiology_procedures)
- appointment_date (DATETIME)
- duration_minutes (INT)
- room_number (VARCHAR)
- technician_id (VARCHAR FK -> users)
- radiologist_id (VARCHAR FK -> users)
- status (ENUM: 'scheduled', 'checked-in', 'in-progress', 'completed', 'no-show', 'cancelled')
- check_in_time (DATETIME)
- start_time (DATETIME)
- end_time (DATETIME)
- notes (TEXT)
- facilityId (VARCHAR)
- created_at, updated_at (TIMESTAMP)
```

#### radiology_examinations
```sql
- id (VARCHAR PRIMARY KEY)
- request_id (VARCHAR FK -> radiology_requests)
- appointment_id (VARCHAR FK -> radiology_appointments)
- patient_id (VARCHAR FK -> patientrecords)
- procedure_id (VARCHAR FK -> radiology_procedures)
- exam_date (DATETIME)
- technician_id (VARCHAR FK -> users)
- radiologist_id (VARCHAR FK -> users)
- contrast_used (BOOLEAN)
- contrast_type (VARCHAR)
- contrast_volume (DECIMAL)
- technique_used (TEXT)
- image_quality (ENUM: 'excellent', 'good', 'adequate', 'poor', 'repeat-required')
- number_of_images (INT)
- radiation_dose_actual (VARCHAR)
- technical_notes (TEXT)
- status (ENUM: 'in-progress', 'completed', 'quality-check', 'approved')
- facilityId (VARCHAR)
- created_at, updated_at (TIMESTAMP)
```

#### radiology_reports
```sql
- id (VARCHAR PRIMARY KEY)
- examination_id (VARCHAR FK -> radiology_examinations)
- request_id (VARCHAR FK -> radiology_requests)
- patient_id (VARCHAR FK -> patientrecords)
- radiologist_id (VARCHAR FK -> users)
- report_date (DATETIME)
- findings (TEXT) -- main report content
- impression (TEXT) -- summary/conclusion
- recommendations (TEXT)
- critical_findings (TEXT) -- urgent findings
- comparison_notes (TEXT) -- comparison with previous studies
- report_status (ENUM: 'draft', 'preliminary', 'final', 'amended', 'addendum')
- verified_by (VARCHAR FK -> users)
- verified_at (DATETIME)
- report_template_id (VARCHAR)
- facilityId (VARCHAR)
- created_at, updated_at (TIMESTAMP)
```

#### radiology_images
```sql
- id (VARCHAR PRIMARY KEY)
- examination_id (VARCHAR FK -> radiology_examinations)
- image_number (INT)
- image_type (ENUM: 'dicom', 'jpeg', 'png', 'pdf')
- file_path (VARCHAR) -- storage location
- file_size (BIGINT)
- image_view (VARCHAR) -- AP, lateral, oblique, etc.
- body_part (VARCHAR)
- thumbnail_path (VARCHAR)
- upload_date (DATETIME)
- uploaded_by (VARCHAR)
- is_key_image (BOOLEAN)
- annotations (JSON) -- measurements, markers
- facilityId (VARCHAR)
- created_at (TIMESTAMP)
```

#### radiology_report_templates
```sql
- id (VARCHAR PRIMARY KEY)
- template_name (VARCHAR)
- procedure_id (VARCHAR FK -> radiology_procedures)
- category (VARCHAR)
- template_content (TEXT) -- structured template
- sections (JSON) -- findings, impression, recommendations
- is_default (BOOLEAN)
- facilityId (VARCHAR)
- created_by (VARCHAR)
- created_at, updated_at (TIMESTAMP)
```

#### radiology_billing
```sql
- id (VARCHAR PRIMARY KEY)
- request_id (VARCHAR FK -> radiology_requests)
- examination_id (VARCHAR FK -> radiology_examinations)
- patient_id (VARCHAR FK -> patientrecords)
- transaction_id (VARCHAR FK -> pending_txn/txn)
- procedure_cost (DECIMAL)
- contrast_cost (DECIMAL)
- additional_charges (DECIMAL)
- discount_amount (DECIMAL)
- total_amount (DECIMAL)
- payment_status (ENUM: 'pending', 'partial', 'paid', 'refunded')
- amount_paid (DECIMAL)
- billing_date (DATETIME)
- facilityId (VARCHAR)
- created_at, updated_at (TIMESTAMP)
```

#### radiology_equipment
```sql
- id (VARCHAR PRIMARY KEY)
- equipment_name (VARCHAR)
- equipment_type (ENUM: 'x-ray', 'ultrasound', 'ct-scanner', 'mri', 'mammography')
- manufacturer (VARCHAR)
- model (VARCHAR)
- serial_number (VARCHAR)
- room_location (VARCHAR)
- installation_date (DATE)
- last_maintenance_date (DATE)
- next_maintenance_date (DATE)
- status (ENUM: 'operational', 'maintenance', 'out-of-service', 'calibration')
- facilityId (VARCHAR)
- created_at, updated_at (TIMESTAMP)
```

---

## Phase 2: Backend API Development

### 2.1 Routes Structure
```
backend/routes/
├── radiology.js              # Main radiology routes
├── radiology-requests.js     # Request management
├── radiology-appointments.js # Appointment scheduling
├── radiology-reports.js      # Report generation
└── radiology-billing.js      # Billing integration
```

### 2.2 Controllers
```
backend/controller/
├── radiology.js              # Main controller
├── radiology-requests.js     # Request handling
├── radiology-reports.js      # Report management
└── radiology-billing.js      # Billing logic
```

### 2.3 Key API Endpoints

#### Procedures
- `GET /radiology/procedures` - List all procedures
- `GET /radiology/procedures/:id` - Get procedure details
- `POST /radiology/procedures` - Create procedure
- `PUT /radiology/procedures/:id` - Update procedure
- `DELETE /radiology/procedures/:id` - Delete procedure

#### Requests
- `POST /radiology/requests` - Create new request (from doctor)
- `GET /radiology/requests` - List requests (with filters)
- `GET /radiology/requests/:id` - Get request details
- `PUT /radiology/requests/:id` - Update request
- `PUT /radiology/requests/:id/status` - Update status
- `DELETE /radiology/requests/:id` - Cancel request

#### Appointments
- `POST /radiology/appointments` - Schedule appointment
- `GET /radiology/appointments` - List appointments
- `GET /radiology/appointments/calendar` - Calendar view
- `PUT /radiology/appointments/:id` - Update appointment
- `PUT /radiology/appointments/:id/check-in` - Check-in patient
- `DELETE /radiology/appointments/:id` - Cancel appointment

#### Examinations
- `POST /radiology/examinations` - Start examination
- `GET /radiology/examinations/:id` - Get examination
- `PUT /radiology/examinations/:id` - Update examination
- `PUT /radiology/examinations/:id/complete` - Complete exam
- `POST /radiology/examinations/:id/images` - Upload images

#### Reports
- `POST /radiology/reports` - Create report
- `GET /radiology/reports/:id` - Get report
- `PUT /radiology/reports/:id` - Update report
- `PUT /radiology/reports/:id/finalize` - Finalize report
- `GET /radiology/reports/:id/pdf` - Generate PDF
- `GET /radiology/reports/templates` - List templates

#### Billing
- `POST /radiology/billing` - Create bill
- `GET /radiology/billing/:requestId` - Get billing info
- `PUT /radiology/billing/:id/payment` - Record payment

---

## Phase 3: Frontend Components

### 3.1 Component Structure
```
frontend/src/components/radiology/
├── RadiologyDashboard.jsx           # Main dashboard
├── RadiologyRouter.jsx              # Route management
├── radiology.css                    # Shared styles
│
├── requests/
│   ├── RequestForm.jsx              # Create/edit request
│   ├── RequestsList.jsx             # List all requests
│   ├── RequestDetails.jsx           # View request details
│   └── RequestWorkflow.jsx          # Status workflow
│
├── appointments/
│   ├── AppointmentScheduler.jsx     # Schedule appointments
│   ├── AppointmentCalendar.jsx      # Calendar view
│   ├── AppointmentList.jsx          # List view
│   └── CheckInForm.jsx              # Patient check-in
│
├── examinations/
│   ├── ExaminationForm.jsx          # Record examination
│   ├── ExaminationsList.jsx         # List examinations
│   ├── ImageUploader.jsx            # Upload images
│   └── ImageViewer.jsx              # View images
│
├── reports/
│   ├── ReportEditor.jsx             # Create/edit report
│   ├── ReportsList.jsx              # List reports
│   ├── ReportViewer.jsx             # View report
│   ├── ReportTemplates.jsx          # Manage templates
│   └── ReportPDF.jsx                # PDF generation
│
├── procedures/
│   ├── ProceduresList.jsx           # Manage procedures
│   ├── ProcedureForm.jsx            # Add/edit procedure
│   └── ProcedurePricing.jsx         # Pricing management
│
├── billing/
│   ├── BillingForm.jsx              # Create bill
│   ├── BillingList.jsx              # List bills
│   └── PaymentForm.jsx              # Process payment
│
└── shared/
    ├── RadiologyMenu.jsx            # Navigation menu
    ├── PatientSelector.jsx          # Select patient
    ├── ProcedureSelector.jsx        # Select procedure
    └── StatusBadge.jsx              # Status indicators
```

### 3.2 Key Features

#### Dashboard
- Today's appointments
- Pending requests
- Reports awaiting finalization
- Equipment status
- Revenue summary

#### Request Management
- Create request from doctor dashboard
- Link to patient record
- Select procedure(s)
- Set priority
- Clinical indication
- Special instructions

#### Appointment Scheduling
- Calendar view (day/week/month)
- Drag-and-drop scheduling
- Resource allocation (room, equipment)
- Technician assignment
- Patient notifications

#### Examination Workflow
- Check-in patient
- Record technical details
- Upload images
- Quality check
- Complete examination

#### Report Generation
- Template-based reporting
- Rich text editor
- Structured sections
- Critical findings alert
- Comparison with previous studies
- Digital signature
- PDF export

---

## Phase 4: Integration Points

### 4.1 Patient Records Integration
- Link radiology requests to patient records
- Display radiology history in patient profile
- Access from doctor dashboard
- View previous imaging studies

### 4.2 Doctor Dashboard Integration
- Request radiology from patient view
- View radiology results
- Access reports
- Track request status

### 4.3 Billing Integration
- Auto-create bills from examinations
- Link to pending_txn table
- Revenue account mapping (403 - Radiology Revenue)
- Payment processing
- Insurance claims

### 4.4 Inventory Integration (Optional)
- Track contrast media usage
- Film/media inventory
- Consumables tracking

### 4.5 Appointment System Integration
- Unified appointment calendar
- Resource scheduling
- Conflict detection

---

## Phase 5: Permissions & Security

### 5.1 Permission Structure
```sql
-- Radiology Module Permissions
radiology.view_dashboard
radiology.create_request
radiology.view_requests
radiology.edit_requests
radiology.cancel_requests
radiology.schedule_appointments
radiology.view_appointments
radiology.check_in_patients
radiology.perform_examination
radiology.upload_images
radiology.view_images
radiology.create_report
radiology.edit_report
radiology.finalize_report
radiology.view_reports
radiology.manage_procedures
radiology.manage_billing
radiology.view_billing
radiology.manage_equipment
```

### 5.2 Role Assignments
- **Radiologist**: Full access to reports, view all
- **Radiology Technician**: Examinations, image upload
- **Doctor**: Create requests, view reports
- **Receptionist**: Scheduling, check-in
- **Billing**: Billing management
- **Admin**: Full access

---

## Phase 6: Reporting & Analytics

### 6.1 Reports
- Daily examination log
- Pending requests report
- Turnaround time analysis
- Revenue by procedure
- Equipment utilization
- Radiologist productivity
- Critical findings log

### 6.2 Dashboard Metrics
- Exams completed today
- Average turnaround time
- Pending reports
- Revenue (daily/monthly)
- Equipment downtime

---

## Phase 7: Implementation Sequence

### Sprint 1: Foundation (Week 1-2)
1. Database schema creation
2. Core backend routes and controllers
3. Basic CRUD operations
4. Permission setup

### Sprint 2: Request Management (Week 3)
1. Request creation from doctor dashboard
2. Request list and details
3. Status workflow
4. Integration with patient records

### Sprint 3: Appointments (Week 4)
1. Appointment scheduling
2. Calendar view
3. Check-in functionality
4. Resource management

### Sprint 4: Examinations (Week 5)
1. Examination recording
2. Image upload
3. Technical details capture
4. Quality control

### Sprint 5: Reporting (Week 6-7)
1. Report editor
2. Templates
3. Report finalization
4. PDF generation
5. Digital signatures

### Sprint 6: Billing Integration (Week 8)
1. Billing creation
2. Payment processing
3. Revenue tracking
4. Integration with account module

### Sprint 7: Polish & Testing (Week 9)
1. UI/UX refinement
2. Integration testing
3. Performance optimization
4. Documentation

---

## Technical Considerations

### Image Storage
- Use file system storage initially
- Path: `/uploads/radiology/{facilityId}/{patientId}/{examId}/`
- Consider cloud storage (S3) for scalability
- DICOM support (future enhancement)

### Report Templates
- JSON-based template structure
- Rich text editor (React Quill/Draft.js)
- Macro support for common phrases
- Auto-fill patient/exam details

### Performance
- Pagination for lists
- Image lazy loading
- Report caching
- Database indexing on frequently queried fields

### Security
- Role-based access control
- Audit logging for report changes
- Secure image storage
- HIPAA compliance considerations

---

## Dependencies

### Backend
- Existing: Express, Sequelize, MySQL
- New: multer (file upload), pdfkit (PDF generation)

### Frontend
- Existing: React, React Router, Redux
- New: react-big-calendar (scheduling), react-pdf (PDF viewer)

---

## Migration Strategy

1. Run database migrations
2. Seed radiology procedures from service_definitions
3. Create default report templates
4. Set up permissions
5. Assign roles to users
6. Configure revenue accounts
7. Test with sample data

---

## Success Metrics

- Request-to-report turnaround time < 24 hours
- 100% of exams billed correctly
- Zero critical findings missed
- User adoption rate > 80%
- System uptime > 99%

---

## Future Enhancements

- DICOM viewer integration
- AI-assisted reporting
- Mobile app for radiologists
- Teleradiology support
- Integration with PACS
- Voice-to-text reporting
- Automated quality assurance
- Radiation dose tracking dashboard
