🔍 MyLikita Platform — Diagnostic Center Readiness Report

Platform Overview

MyLikita is a comprehensive multi-facility Health Information System (HIS) with explicit support for 6 facility types: Hospital, Clinic, Pharmacy, Laboratory, Diagnostic Center, and Dental Clinic. The  diagnosticCenter  type is a first-class citizen with its own modules, roles, subscription tiers, and onboarding flow.

────────────────────────────────────────────────────────────────────────────────

✅ What It HAS (Ready for Diagnostic Center)

1. Radiology Module (Core — Full Suite)

┌──────────────────────────┬────────┬───────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Feature                  │ Status │ Details                                                                                               │
├──────────────────────────┼────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Radiology Dashboard      │ ✅     │ Pending requests, today's appointments, completed exams, critical findings                            │
│ Patient Requests         │ ✅     │ Create/request/list with priority (routine/urgent/stat), status tracking                              │
│ Appointments Scheduler   │ ✅     │ Schedule, list, track radiology appointments with room assignments                                    │
│ Examinations             │ ✅     │ Full exam workflow: create → record contrast/technique → complete                                     │
│ DICOM Integration        │ ✅     │ Upload DICOM files, Orthanc PACS integration, OHIF viewer URL generation, study list, patient studies │
│ DICOM Webhook            │ ✅     │ Receives stable-study notifications from Orthanc                                                      │
│ Report Editor            │ ✅     │ Rich findings/impression/recommendations with critical findings flag                                  │
│ Report Templates         │ ✅     │ Per-procedure/category templates, default template support                                            │
│ Report PDF Generation    │ ✅     │ Puppeteer-based A4 PDF with facility branding, signatures                                             │
│ Report Finalization      │ ✅     │ Draft → Final workflow with radiologist verification                                                  │
│ Radiology Billing        │ ✅     │ Billing list, forms, payment processing, department cashier                                           │
│ Analytics                │ ✅     │ Dashboard metrics, radiologist productivity, equipment utilization                                    │
│ Equipment Management     │ ✅     │ Utilization tracking, downtime analysis, maintenance scheduling, performance scoring                  │
│ Export Reports           │ ✅     │ Data export functionality                                                                             │
│ Worklist                 │ ✅     │ Radiology worklist for workflow management                                                            │
│ Report Templates Manager │ ✅     │ Create/edit/delete/manage report templates                                                            │
└──────────────────────────┴────────┴───────────────────────────────────────────────────────────────────────────────────────────────────────┘

2. Laboratory Module (NewLab — Full Suite)

┌──────────────────────┬────────┬─────────────────────────────────────────────────────────────────────────────────────┐
│ Feature              │ Status │ Details                                                                             │
├──────────────────────┼────────┼─────────────────────────────────────────────────────────────────────────────────────┤
│ Lab Dashboard        │ ✅     │ Requests today, pending samples, awaiting auth, critical values                     │
│ Request Management   │ ✅     │ Walk-in and referral requests, urgency levels, status tracking                      │
│ Specimen Collection  │ ✅     │ Collection workflow with walk-in payment gate                                       │
│ Result Entry         │ ✅     │ Result recording interface                                                          │
│ Result Authorization │ ✅     │ Authorization workflow with critical value alerts                                   │
│ Test Catalogue       │ ✅     │ Manage lab test definitions                                                         │
│ Quality Control (QC) │ ✅     │ QC dashboard for lab quality management                                             │
│ Lab Analytics        │ ✅     │ Lab performance analytics                                                           │
│ Lab Settings         │ ✅     │ Workflow mode (full/simple), walk-in payment gate, report header, share link expiry │
│ Lab Instruments      │ ✅     │ Instrument tracking, calibration logs, maintenance scheduling, decommission         │
│ Shared Reports       │ ✅     │ Public report sharing via token links                                               │
│ Lab Cashier          │ ✅     │ Department-specific cashier for lab payments                                        │
└──────────────────────┴────────┴─────────────────────────────────────────────────────────────────────────────────────┘

3. Patient Management

┌──────────────────────┬────────┬───────────────────────────────────────────────────┐
│ Feature              │ Status │ Details                                           │
├──────────────────────┼────────┼───────────────────────────────────────────────────┤
│ Patient Records      │ ✅     │ Full patient registration and management          │
│ Walk-in Registration │ ✅     │ In-lab walk-in patient registration               │
│ Referral Patients    │ ✅     │ Doctor referral workflow with clinician tracking  │
│ Patient Documents    │ ✅     │ Document management                               │
│ Patient Timeline     │ ✅     │ Patient activity timeline                         │
│ Patient Portal       │ ✅     │ Patient self-service portal (flagship deployment) │
│ Result Viewer        │ ✅     │ Public result viewing by patient ID + lab number  │
└──────────────────────┴────────┴───────────────────────────────────────────────────┘

4. Financial & Billing

┌────────────────────────┬────────┬──────────────────────────────────────────────────────────────────────┐
│ Feature                │ Status │ Details                                                              │
├────────────────────────┼────────┼──────────────────────────────────────────────────────────────────────┤
│ Accounts Module        │ ✅     │ Chart of accounts, opening balances, transactions                    │
│ Transaction Management │ ✅     │ Full transaction recording                                           │
│ Receipt Numbering      │ ✅     │ Automatic receipt/PRN/transaction ID generation                      │
│ Financial Reports      │ ✅     │ Revenue, expense, and departmental reports                           │
│ HMO/Insurance          │ ✅     │ HMO providers, insurance schemes, NHIA registration, coverage checks │
│ Split Payments         │ ✅     │ Split payment utilities                                              │
│ Discounts              │ ✅     │ Discount policy management                                           │
│ Radiology Billing      │ ✅     │ Dedicated radiology billing with invoicing                           │
│ Pay-As-You-Go (PAYG)   │ ✅     │ PAYG billing model with per-test/per-consultation rates              │
└────────────────────────┴────────┴──────────────────────────────────────────────────────────────────────┘

5. Administration

┌───────────────────────────┬────────┬───────────────────────────────────────────────────────────────────────────────────────┐
│ Feature                   │ Status │ Details                                                                               │
├───────────────────────────┼────────┼───────────────────────────────────────────────────────────────────────────────────────┤
│ User Management           │ ✅     │ Full user CRUD with role-based access                                                 │
│ Role-Based Access Control │ ✅     │ Granular permissions (radiologist, lab_tech, lab_scientist, technician, etc.)         │
│ Setup Guide               │ ✅     │ Post-onboarding readiness checklist (staff, services, accounts, lab tests, insurance) │
│ Notifications             │ ✅     │ Real-time socket.io notifications                                                     │
│ Network Settings          │ ✅     │ LAN access configuration                                                              │
│ Maintenance Module        │ ✅     │ Equipment maintenance tracking                                                        │
└───────────────────────────┴────────┴───────────────────────────────────────────────────────────────────────────────────────┘

6. Subscription & Plans (Diagnostic Center Specific)

┌──────────┬─────────────┬───────────────────────────────────────┬─────────────────┐
│ Tier     │ Price       │ Modules                               │ Limits          │
├──────────┼─────────────┼───────────────────────────────────────┼─────────────────┤
│ Basic    │ ₦25,000/mo  │ Dashboard, Records, Radiology, Admin  │ 3 staff         │
│ Standard │ ₦50,000/mo  │ Basic + Laboratory, Accounts, Reports │ 10 staff        │
│ Premium  │ ₦100,000/mo │ All modules + Management + PACS       │ Unlimited staff │
└──────────┴─────────────┴───────────────────────────────────────┴─────────────────┘

7. Additional Features

┌─────────────────────────────┬────────┐
│ Feature                     │ Status │
├─────────────────────────────┼────────┤
│ Real-time Socket.io         │ ✅     │
│ Print Agent                 │ ✅     │
│ SWAP Integration (NHIA)     │ ✅     │
│ Insurance/Coverage Engine   │ ✅     │
│ Clinical Summary Engine     │ ✅     │
│ SMS Notifications           │ ✅     │
│ Monthly Business Reports    │ ✅     │
│ Website Embed Widget        │ ✅     │
│ Data Import/Export          │ ✅     │
│ Swagger API Docs            │ ✅     │
│ Docker Deployment           │ ✅     │
│ Offline/On-premises Support │ ✅     │
└─────────────────────────────┴────────┘

────────────────────────────────────────────────────────────────────────────────

⚠️ What's MISSING or LIMITED

Critical Gaps

┌────────────────────────┬───────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Gap                    │ Severity  │ Details                                                                                                                │
├────────────────────────┼───────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ No Consultation Module │ 🔴 High   │ Diagnostic centers often have physician consultations — this is missing from the diagnosticCenter module set           │
│ No Pharmacy Module     │ 🟡 Medium │ Some diagnostic centers dispense contrast agents or basic medications — not available                                  │
│ No Appointments Module │ 🟡 Medium │ The diagnosticCenter type doesn't include the general Appointments module (only radiology-specific appointments exist) │
│ No Inventory Module    │ 🟡 Medium │ No inventory tracking for consumables, contrast agents, reagents, etc.                                                 │
│ No HR Module           │ 🟡 Medium │ No human resource management (employees, attendance, payroll) — would be needed for larger centers                     │
│ No Nursing Module      │ 🟢 Low    │ Not typically needed for diagnostic centers                                                                            │
│ No Theater Module      │ 🟢 Low    │ Not needed for diagnostic centers                                                                                      │
│ No Dental Module       │ 🟢 Low    │ Not applicable                                                                                                         │
└────────────────────────┴───────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

Feature Gaps Within Available Modules

┌───────────────────────────────────┬───────────┬─────────────────────────────────────────────────────────────────────────────┐
│ Gap                               │ Severity  │ Details                                                                     │
├───────────────────────────────────┼───────────┼─────────────────────────────────────────────────────────────────────────────┤
│ No HL7/FHIR Integration           │ 🟡 Medium │ HL7 server code is commented out — no standard interoperability             │
│ No Multi-modality Scheduling      │ 🟡 Medium │ No CT/MRI/X-ray/Ultrasound room-level scheduling with time slots            │
│ No Turnaround Time (TAT) Tracking │ 🟡 Medium │ Analytics exist but no real-time TAT dashboard or SLA alerts                │
│ No Patient Referral Network       │ 🟡 Medium │ No outbound referral tracking to other facilities                           │
│ No Mobile App                     │ 🟡 Medium │ Web-only — no native mobile app for patients or staff                       │
│ No Batch/Panel Test Ordering      │ 🟡 Medium │ No predefined test panels (e.g., "Full Blood Count", "Liver Function Test") │
│ No Auto-Report from Instruments   │ 🟡 Medium │ Instrument management exists but no HL7/auto-entry from analyzers           │
│ No Image Annotation               │ 🟢 Low    │ DICOM viewer exists but no annotation/markup tools                          │
│ No Voice Dictation                │ 🟢 Low    │ No speech-to-text for report dictation                                      │
└───────────────────────────────────┴───────────┴─────────────────────────────────────────────────────────────────────────────┘

Deployment/Infrastructure Gaps

┌─────────────────────────┬───────────┬──────────────────────────────────────────────────────────────┐
│ Gap                     │ Severity  │ Details                                                      │
├─────────────────────────┼───────────┼──────────────────────────────────────────────────────────────┤
│ Orthanc PACS Dependency │ 🟡 Medium │ PACS integration requires separate Orthanc server deployment │
│ Puppeteer for PDFs      │ 🟡 Medium │ PDF generation requires headless Chrome — resource-intensive │
│ No Redis (Optional)     │ 🟢 Low    │ Cache falls back to in-memory if Redis unavailable           │
└─────────────────────────┴───────────┴──────────────────────────────────────────────────────────────┘

────────────────────────────────────────────────────────────────────────────────

📊 Overall Readiness Score

┌───────────────────────┬────────┬────────────────────────────────────────────────────────────────────┐
│ Category              │ Score  │ Notes                                                              │
├───────────────────────┼────────┼────────────────────────────────────────────────────────────────────┤
│ Radiology Workflow    │ 9/10   │ Excellent — full request → exam → report → billing cycle           │
│ Laboratory Workflow   │ 9/10   │ Excellent — full request → specimen → result → authorization cycle │
│ DICOM/PACS            │ 7/10   │ Good — Orthanc integration works but needs external PACS server    │
│ Patient Management    │ 8/10   │ Good — records, walk-in, referrals all present                     │
│ Billing & Finance     │ 8/10   │ Good — department-specific billing, HMO support                    │
│ Administration        │ 8/10   │ Good — roles, permissions, setup guide                             │
│ Analytics & Reporting │ 7/10   │ Good — dashboards exist but TAT/SLA tracking needs work            │
│ Interoperability      │ 4/10   │ Limited — no HL7/FHIR, HL7 code commented out                      │
│ Mobile Access         │ 3/10   │ Web-only, responsive design but no native app                      │
│ Overall               │ 7.5/10 │ Production-ready for basic diagnostic center operations            │
└───────────────────────┴────────┴────────────────────────────────────────────────────────────────────┘

────────────────────────────────────────────────────────────────────────────────

🎯 Recommendations for Deployment

1. Deploy the Standard or Premium tier — Basic tier is too limited (no Laboratory, no Reports)
2. Set up Orthanc PACS separately for DICOM imaging
3. Configure NHIA/HMO schemes for insurance billing
4. Add Radiology Procedures (CT, MRI, X-ray, Ultrasound, Mammography, etc.) in the catalogue
5. Add Lab Tests in the test catalogue for the laboratory module
6. Create staff roles — radiologists, lab technicians, receptionists, cashiers
7. Set service prices for all imaging procedures and lab tests
8. Configure report templates for common radiology procedures

The platform is production-ready for a diagnostic center's core operations (imaging + lab + billing), with the main gaps being in advanced features like HL7 interoperability, mobile access, and multi-modality scheduling optimization.