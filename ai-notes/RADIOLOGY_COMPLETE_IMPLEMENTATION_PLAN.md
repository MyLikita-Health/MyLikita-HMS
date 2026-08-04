# Radiology Module - Complete Implementation Plan
## Full-Featured Radiology System with DICOM & Modality Integration

---

## Executive Summary

**Timeline**: 12 weeks (3 months)  
**Team**: 2-3 developers  
**Budget**: $15,000 - $25,000  
**Complexity**: Medium-High

### What You'll Get:
✅ Complete radiology workflow (request → exam → report)  
✅ DICOM image storage & viewing (OHIF Viewer)  
✅ Automatic modality integration (machines send images)  
✅ Billing integration  
✅ Patient records integration  
✅ Doctor dashboard integration  
✅ Appointment scheduling  
✅ Report generation with templates  
✅ Analytics & reporting

---

## Technology Stack

### Core Infrastructure
- **PACS Server**: Orthanc (open-source DICOM server)
- **DICOM Viewer**: OHIF Viewer (FDA-cleared)
- **Backend**: Node.js/Express (existing)
- **Frontend**: React (existing)
- **Database**: MySQL (existing)
- **File Storage**: Local/NAS initially, S3 optional

### New Dependencies
```json
{
  "backend": {
    "multer": "^1.4.5",
    "dicom-parser": "^1.8.13",
    "winston": "^3.11.0"
  },
  "frontend": {
    "react-big-calendar": "^1.8.5",
    "react-pdf": "^7.5.1",
    "react-quill": "^2.0.0"
  }
}
```

---

## Phase-by-Phase Implementation


### PHASE 1: Foundation & Infrastructure (Week 1-2)

#### Week 1: Database Schema & Orthanc Setup

**Day 1-2: Database Schema**
- Create all radiology tables (9 core tables + 2 DICOM tables)
- Set up indexes and foreign keys
- Create stored procedures for common queries

**Day 3-4: Orthanc Installation**
- Install Orthanc via Docker
- Configure DICOM networking
- Set up DICOMweb API
- Configure storage directories
- Test with sample DICOM files

**Day 5: Permissions & Roles**
- Create radiology permissions (15 permissions)
- Set up role assignments
- Configure access control

**Deliverables:**
- ✅ Database schema deployed
- ✅ Orthanc running and accessible
- ✅ Permissions configured
- ✅ Documentation updated

**Files to Create:**
```
backend/sql/
├── radiology_schema.sql
├── radiology_worklist_schema.sql
├── radiology_dicom_schema.sql
├── radiology_permissions.sql
└── seed_radiology_procedures.sql
```

---

#### Week 2: Core Backend API

**Day 1-2: Procedures & Requests**
- Procedures CRUD endpoints
- Request creation & management
- Status workflow implementation

**Day 3: Appointments**
- Appointment scheduling API
- Calendar data endpoints
- Check-in functionality

**Day 4: Orthanc Integration**
- Orthanc client service
- DICOM upload endpoint
- Metadata extraction

**Day 5: Testing & Documentation**
- API testing with Postman
- Write API documentation
- Error handling review

**Deliverables:**
- ✅ 20+ API endpoints functional
- ✅ Orthanc integration working
- ✅ API documentation complete

**Files to Create:**
```
backend/
├── routes/
│   ├── radiology.js
│   ├── radiology-requests.js
│   ├── radiology-appointments.js
│   └── radiology-dicom.js
├── controller/
│   ├── radiology.js
│   ├── radiology-requests.js
│   ├── radiology-appointments.js
│   └── radiology-dicom.js
└── services/
    └── orthancClient.js
```

---

### PHASE 2: Core Workflow (Week 3-5)

#### Week 3: Request Management & Scheduling

**Frontend Components:**
- RadiologyDashboard (main dashboard)
- RequestForm (create/edit requests)
- RequestsList (view all requests)
- RequestDetails (detailed view)
- AppointmentScheduler (calendar-based scheduling)

**Integration Points:**
- Link to patient records
- Doctor dashboard integration
- Notification system

**Deliverables:**
- ✅ Doctors can create radiology requests
- ✅ Receptionists can schedule appointments
- ✅ Calendar view functional

**Files to Create:**
```
frontend/src/components/radiology/
├── RadiologyDashboard.jsx
├── RadiologyRouter.jsx
├── radiology.css
├── requests/
│   ├── RequestForm.jsx
│   ├── RequestsList.jsx
│   ├── RequestDetails.jsx
│   └── RequestWorkflow.jsx
└── appointments/
    ├── AppointmentScheduler.jsx
    ├── AppointmentCalendar.jsx
    └── AppointmentList.jsx
```

---

#### Week 4: Examination Workflow

**Frontend Components:**
- ExaminationForm (record exam details)
- ImageUploader (manual DICOM upload)
- ExaminationsList (view exams)
- CheckInForm (patient check-in)

**Backend:**
- Examination CRUD
- Image upload handling
- Quality control workflow

**Deliverables:**
- ✅ Technicians can record examinations
- ✅ Manual DICOM upload working
- ✅ Images stored in Orthanc

**Files to Create:**
```
frontend/src/components/radiology/examinations/
├── ExaminationForm.jsx
├── ExaminationsList.jsx
├── ImageUploader.jsx
└── CheckInForm.jsx
```

---

#### Week 5: DICOM Viewing

**OHIF Integration:**
- Embed OHIF viewer
- Study list component
- Image viewer component
- Thumbnail generation

**Backend:**
- Generate OHIF viewer URLs
- Study metadata API
- Patient studies endpoint

**Deliverables:**
- ✅ View DICOM images in OHIF
- ✅ Study list per patient
- ✅ Embedded and full-screen viewing

**Files to Create:**
```
frontend/src/components/radiology/dicom/
├── DicomViewer.jsx
├── StudyList.jsx
├── StudyCard.jsx
└── ImageThumbnail.jsx
```

---

### PHASE 3: Reporting & Billing (Week 6-7)

#### Week 6: Report Generation

**Frontend Components:**
- ReportEditor (rich text editor)
- ReportsList (view reports)
- ReportViewer (read-only view)
- ReportTemplates (manage templates)
- ReportPDF (PDF generation)

**Backend:**
- Report CRUD
- Template management
- PDF generation
- Digital signatures

**Deliverables:**
- ✅ Radiologists can create reports
- ✅ Template-based reporting
- ✅ PDF export functional

**Files to Create:**
```
frontend/src/components/radiology/reports/
├── ReportEditor.jsx
├── ReportsList.jsx
├── ReportViewer.jsx
├── ReportTemplates.jsx
└── ReportPDF.jsx

backend/controller/
└── radiology-reports.js
```

---

#### Week 7: Billing Integration

**Features:**
- Auto-create bills from examinations
- Link to pending_txn table
- Revenue account mapping
- Payment processing

**Integration:**
- Account module integration
- Service definitions linkage
- Revenue tracking

**Deliverables:**
- ✅ Automatic billing creation
- ✅ Payment processing
- ✅ Revenue reporting

**Files to Create:**
```
frontend/src/components/radiology/billing/
├── BillingForm.jsx
├── BillingList.jsx
└── PaymentForm.jsx

backend/controller/
└── radiology-billing.js
```

---

### PHASE 4: DICOM Worklist & Modality Integration (Week 8-9)

#### Week 8: DICOM Worklist (MWL)

**Backend:**
- Worklist generation
- Export to Orthanc format
- Worklist API endpoints
- Modality configuration

**Database:**
- Worklist tables
- Modality registry
- Accession number generation

**Deliverables:**
- ✅ Worklist items created on scheduling
- ✅ Machines can fetch worklist
- ✅ Patient info appears on modality

**Files to Create:**
```
backend/controller/
└── radiology-worklist.js

backend/services/
└── worklistExporter.js

/var/lib/orthanc/worklists/
└── [JSON worklist files]
```

---

#### Week 9: Automatic Image Reception

**Orthanc Configuration:**
- Configure C-STORE receiver
- Set up auto-routing rules
- Implement webhook notifications

**Backend:**
- Webhook handler
- Auto-status updates
- Auto-billing trigger
- Radiologist notifications

**Deliverables:**
- ✅ Machines automatically send images
- ✅ Images matched to requests
- ✅ Status auto-updated
- ✅ Notifications sent

**Files to Create:**
```
backend/controller/
└── radiology-dicom-webhook.js

/etc/orthanc/
├── orthanc.json (updated)
└── auto-routing.lua
```

---

### PHASE 5: Advanced Features (Week 10-11)

#### Week 10: Analytics & Reporting

**Dashboard Metrics:**
- Today's appointments
- Pending requests
- Completed exams
- Revenue summary
- Turnaround time
- Equipment utilization

**Reports:**
- Daily examination log
- Pending requests report
- Revenue by procedure
- Radiologist productivity
- Critical findings log

**Deliverables:**
- ✅ Comprehensive dashboard
- ✅ 5+ standard reports
- ✅ Export to Excel/PDF

**Files to Create:**
```
frontend/src/components/radiology/analytics/
├── Dashboard.jsx
├── MetricsCards.jsx
├── Charts.jsx
└── Reports.jsx

backend/controller/
└── radiology-analytics.js
```

---

#### Week 11: Equipment & Quality Control

**Features:**
- Equipment registry
- Maintenance tracking
- Quality control checks
- Image quality assessment
- Radiation dose tracking

**Deliverables:**
- ✅ Equipment management
- ✅ Maintenance scheduling
- ✅ QC workflow

**Files to Create:**
```
frontend/src/components/radiology/equipment/
├── EquipmentList.jsx
├── EquipmentForm.jsx
└── MaintenanceSchedule.jsx
```

---

### PHASE 6: Testing, Polish & Deployment (Week 12)

#### Week 12: Final Testing & Go-Live

**Day 1-2: Integration Testing**
- End-to-end workflow testing
- Modality connectivity testing
- Performance testing
- Security audit

**Day 3: User Training**
- Train radiologists
- Train technicians
- Train receptionists
- Train billing staff

**Day 4: Data Migration**
- Import existing procedures
- Set up report templates
- Configure modalities
- Test with real data

**Day 5: Go-Live**
- Deploy to production
- Monitor closely
- Quick bug fixes
- Gather feedback

**Deliverables:**
- ✅ System fully tested
- ✅ Users trained
- ✅ Production deployment
- ✅ Documentation complete

---

## Detailed File Structure



### Complete Directory Structure

```
project/
├── backend/
│   ├── sql/
│   │   ├── radiology_schema.sql
│   │   ├── radiology_worklist_schema.sql
│   │   ├── radiology_dicom_schema.sql
│   │   ├── radiology_permissions.sql
│   │   ├── seed_radiology_procedures.sql
│   │   └── run_radiology_migration.js
│   │
│   ├── routes/
│   │   ├── radiology.js
│   │   ├── radiology-requests.js
│   │   ├── radiology-appointments.js
│   │   ├── radiology-examinations.js
│   │   ├── radiology-reports.js
│   │   ├── radiology-billing.js
│   │   ├── radiology-dicom.js
│   │   └── radiology-worklist.js
│   │
│   ├── controller/
│   │   ├── radiology.js
│   │   ├── radiology-requests.js
│   │   ├── radiology-appointments.js
│   │   ├── radiology-examinations.js
│   │   ├── radiology-reports.js
│   │   ├── radiology-billing.js
│   │   ├── radiology-dicom.js
│   │   ├── radiology-dicom-webhook.js
│   │   ├── radiology-worklist.js
│   │   └── radiology-analytics.js
│   │
│   ├── services/
│   │   ├── orthancClient.js
│   │   ├── worklistExporter.js
│   │   └── dicomParser.js
│   │
│   └── middleware/
│       └── dicomAuth.js
│
├── frontend/src/components/radiology/
│   ├── RadiologyDashboard.jsx
│   ├── RadiologyRouter.jsx
│   ├── RadiologyMenu.jsx
│   ├── radiology.css
│   │
│   ├── requests/
│   │   ├── RequestForm.jsx
│   │   ├── RequestsList.jsx
│   │   ├── RequestDetails.jsx
│   │   └── RequestWorkflow.jsx
│   │
│   ├── appointments/
│   │   ├── AppointmentScheduler.jsx
│   │   ├── AppointmentCalendar.jsx
│   │   ├── AppointmentList.jsx
│   │   └── CheckInForm.jsx
│   │
│   ├── examinations/
│   │   ├── ExaminationForm.jsx
│   │   ├── ExaminationsList.jsx
│   │   ├── ImageUploader.jsx
│   │   └── CheckInForm.jsx
│   │
│   ├── dicom/
│   │   ├── DicomViewer.jsx
│   │   ├── DicomUploader.jsx
│   │   ├── StudyList.jsx
│   │   ├── StudyCard.jsx
│   │   └── ImageThumbnail.jsx
│   │
│   ├── reports/
│   │   ├── ReportEditor.jsx
│   │   ├── ReportsList.jsx
│   │   ├── ReportViewer.jsx
│   │   ├── ReportTemplates.jsx
│   │   └── ReportPDF.jsx
│   │
│   ├── billing/
│   │   ├── BillingForm.jsx
│   │   ├── BillingList.jsx
│   │   └── PaymentForm.jsx
│   │
│   ├── procedures/
│   │   ├── ProceduresList.jsx
│   │   ├── ProcedureForm.jsx
│   │   └── ProcedurePricing.jsx
│   │
│   ├── equipment/
│   │   ├── EquipmentList.jsx
│   │   ├── EquipmentForm.jsx
│   │   └── MaintenanceSchedule.jsx
│   │
│   ├── analytics/
│   │   ├── Dashboard.jsx
│   │   ├── MetricsCards.jsx
│   │   ├── Charts.jsx
│   │   └── Reports.jsx
│   │
│   └── shared/
│       ├── PatientSelector.jsx
│       ├── ProcedureSelector.jsx
│       ├── StatusBadge.jsx
│       └── PriorityBadge.jsx
│
├── orthanc/
│   ├── orthanc.json
│   ├── orthanc-worklist.json
│   ├── auto-routing.lua
│   └── docker-compose.yml
│
└── docs/
    ├── RADIOLOGY_USER_GUIDE.md
    ├── RADIOLOGY_API_DOCS.md
    ├── DICOM_SETUP_GUIDE.md
    └── MODALITY_CONFIGURATION.md
```

---

## Database Schema Summary

### Core Tables (9)
1. **radiology_procedures** - Procedure definitions
2. **radiology_requests** - Exam requests from doctors
3. **radiology_appointments** - Scheduled appointments
4. **radiology_examinations** - Exam execution details
5. **radiology_reports** - Radiologist reports
6. **radiology_images** - Image metadata
7. **radiology_report_templates** - Report templates
8. **radiology_billing** - Billing records
9. **radiology_equipment** - Equipment registry

### DICOM Tables (2)
10. **radiology_dicom_studies** - DICOM study metadata
11. **radiology_worklist** - Worklist for modalities

### Integration Tables (2)
12. **radiology_modalities** - Modality configuration
13. **radiology_notifications** - Notification queue

---

## API Endpoints Summary

### Procedures (5 endpoints)
- `GET /radiology/procedures`
- `GET /radiology/procedures/:id`
- `POST /radiology/procedures`
- `PUT /radiology/procedures/:id`
- `DELETE /radiology/procedures/:id`

### Requests (6 endpoints)
- `POST /radiology/requests`
- `GET /radiology/requests`
- `GET /radiology/requests/:id`
- `PUT /radiology/requests/:id`
- `PUT /radiology/requests/:id/status`
- `DELETE /radiology/requests/:id`

### Appointments (6 endpoints)
- `POST /radiology/appointments`
- `GET /radiology/appointments`
- `GET /radiology/appointments/calendar`
- `PUT /radiology/appointments/:id`
- `PUT /radiology/appointments/:id/check-in`
- `DELETE /radiology/appointments/:id`

### Examinations (5 endpoints)
- `POST /radiology/examinations`
- `GET /radiology/examinations/:id`
- `PUT /radiology/examinations/:id`
- `PUT /radiology/examinations/:id/complete`
- `POST /radiology/examinations/:id/images`

### Reports (6 endpoints)
- `POST /radiology/reports`
- `GET /radiology/reports/:id`
- `PUT /radiology/reports/:id`
- `PUT /radiology/reports/:id/finalize`
- `GET /radiology/reports/:id/pdf`
- `GET /radiology/reports/templates`

### DICOM (5 endpoints)
- `POST /radiology/dicom/upload`
- `GET /radiology/dicom/studies/:studyUID/viewer-url`
- `GET /radiology/dicom/patients/:patientId/studies`
- `POST /radiology/dicom/webhook` (internal)
- `GET /radiology/dicom/studies/:studyUID/metadata`

### Worklist (3 endpoints)
- `POST /radiology/worklist`
- `GET /radiology/worklist`
- `GET /radiology/worklist/:accessionNumber`

### Billing (3 endpoints)
- `POST /radiology/billing`
- `GET /radiology/billing/:requestId`
- `PUT /radiology/billing/:id/payment`

### Analytics (4 endpoints)
- `GET /radiology/analytics/dashboard`
- `GET /radiology/analytics/reports/daily-log`
- `GET /radiology/analytics/reports/turnaround-time`
- `GET /radiology/analytics/reports/revenue`

**Total: 48 API endpoints**

---

## Integration Points

### 1. Patient Records
- Link requests to patient records
- Display radiology history in patient profile
- Access from patient details page

### 2. Doctor Dashboard
- Create radiology requests from patient view
- View radiology results
- Access reports and images
- Track request status

### 3. Billing/Account Module
- Auto-create bills from examinations
- Link to pending_txn table
- Revenue account mapping (403 - Radiology Revenue)
- Payment processing integration

### 4. Appointment System
- Unified appointment calendar
- Resource scheduling (rooms, equipment)
- Conflict detection
- Reminder notifications

### 5. Inventory Module (Optional)
- Track contrast media usage
- Film/media inventory
- Consumables tracking

### 6. Notification System
- Email notifications
- SMS alerts
- In-app notifications
- Critical findings alerts

---

## Permissions Structure

### Radiology Permissions (15)
```sql
-- View permissions
radiology.view_dashboard
radiology.view_requests
radiology.view_appointments
radiology.view_examinations
radiology.view_images
radiology.view_reports
radiology.view_billing

-- Action permissions
radiology.create_request
radiology.edit_request
radiology.cancel_request
radiology.schedule_appointment
radiology.check_in_patient
radiology.perform_examination
radiology.upload_images
radiology.create_report
radiology.edit_report
radiology.finalize_report
radiology.manage_procedures
radiology.manage_billing
radiology.manage_equipment
```

### Role Assignments
- **Radiologist**: Full report access, view all
- **Radiology Technician**: Examinations, image upload
- **Doctor**: Create requests, view reports
- **Receptionist**: Scheduling, check-in
- **Billing Staff**: Billing management
- **Admin**: Full access

---

## Deployment Checklist

### Infrastructure
- [ ] Orthanc server deployed
- [ ] OHIF viewer configured
- [ ] Database migrations run
- [ ] File storage configured
- [ ] Backup system in place

### Configuration
- [ ] Environment variables set
- [ ] Orthanc configured
- [ ] Modalities registered
- [ ] Network firewall rules
- [ ] SSL certificates installed

### Data
- [ ] Procedures imported
- [ ] Report templates created
- [ ] Revenue accounts mapped
- [ ] Permissions assigned
- [ ] Users configured

### Testing
- [ ] API endpoints tested
- [ ] DICOM upload tested
- [ ] Worklist tested
- [ ] Image viewing tested
- [ ] Billing integration tested
- [ ] Modality connectivity tested

### Documentation
- [ ] User guide written
- [ ] API documentation complete
- [ ] Setup guide created
- [ ] Training materials prepared

### Go-Live
- [ ] Users trained
- [ ] Support plan in place
- [ ] Monitoring configured
- [ ] Backup verified
- [ ] Rollback plan ready

---

## Success Metrics

### Performance Metrics
- Request-to-report turnaround time < 24 hours
- Image availability < 5 minutes after scan
- System uptime > 99.5%
- Page load time < 2 seconds

### Business Metrics
- 100% of exams billed correctly
- Zero critical findings missed
- User adoption rate > 80%
- Patient satisfaction > 90%

### Technical Metrics
- API response time < 500ms
- DICOM upload success rate > 99%
- Worklist fetch success rate > 99%
- Zero data loss incidents

---

## Risk Management

### Technical Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Orthanc downtime | High | Redundant server, regular backups |
| DICOM compatibility | Medium | Test with all modalities, vendor support |
| Storage capacity | Medium | Monitor usage, plan expansion |
| Network issues | High | Dedicated VLAN, QoS configuration |

### Operational Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| User resistance | Medium | Training, change management |
| Data migration | High | Thorough testing, rollback plan |
| Vendor delays | Low | Early engagement, backup vendors |

---

## Budget Breakdown

### Development Costs
- Backend development: $8,000 (4 weeks × $2,000)
- Frontend development: $8,000 (4 weeks × $2,000)
- Integration & testing: $4,000 (2 weeks × $2,000)
- **Total Development: $20,000**

### Infrastructure Costs (Annual)
- Orthanc server: $1,200 ($100/month)
- Storage (2TB): $600 ($50/month)
- OHIF hosting: $0 (use hosted version)
- Backup storage: $360 ($30/month)
- **Total Infrastructure: $2,160/year**

### One-Time Costs
- Training: $1,000
- Documentation: $500
- Vendor coordination: $1,000
- **Total One-Time: $2,500**

### Grand Total
- **Year 1: $24,660**
- **Year 2+: $2,160/year**

---

## Support & Maintenance

### Ongoing Tasks
- Monitor Orthanc performance
- Backup verification (weekly)
- Security updates (monthly)
- User support
- Bug fixes
- Feature enhancements

### Support Levels
- **Level 1**: User training, basic troubleshooting
- **Level 2**: Technical issues, configuration
- **Level 3**: Development, major issues

---

## Future Enhancements

### Phase 2 Features (6-12 months)
- AI-assisted reporting
- Voice-to-text dictation
- Mobile app for radiologists
- Teleradiology support
- Advanced analytics
- Machine learning for quality control

### Phase 3 Features (12-24 months)
- Full PACS integration
- RIS integration
- HL7 interface
- Multi-facility support
- Cloud storage migration
- Advanced 3D visualization

---

## Conclusion

This comprehensive plan provides a complete roadmap for implementing a production-ready radiology module with full DICOM support and modality integration. The phased approach allows for incremental delivery and testing, reducing risk while providing value early.

**Key Success Factors:**
1. Strong project management
2. Early vendor engagement
3. Thorough testing
4. Comprehensive training
5. Ongoing support

**Next Steps:**
1. Review and approve plan
2. Assemble development team
3. Set up development environment
4. Begin Phase 1 implementation

---

## Quick Start Guide

### For Developers
1. Clone repository
2. Run database migrations: `node backend/sql/run_radiology_migration.js`
3. Install Orthanc: `docker-compose up -d`
4. Install dependencies: `npm install`
5. Start backend: `npm run dev`
6. Start frontend: `cd frontend && npm start`

### For Administrators
1. Configure Orthanc (see DICOM_SETUP_GUIDE.md)
2. Register modalities
3. Set up permissions
4. Import procedures
5. Train users

### For Users
1. Read user guide (RADIOLOGY_USER_GUIDE.md)
2. Complete training
3. Test with sample data
4. Provide feedback

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-09  
**Author**: Development Team  
**Status**: Ready for Implementation
