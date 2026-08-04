# DENTAL MODULE - COMPLETE IMPLEMENTATION PLAN

**Project:** Full Frontend Implementation for Dental Module  
**Timeline:** 6-8 Weeks  
**Priority:** Critical Features First

---

## BILLING INTEGRATION WORKFLOW (CRITICAL)

### Core Principle: NO SERVICE WITHOUT PAYMENT
**All dental services MUST follow this workflow:**

1. **Service Selection** → Link to `service_definitions` table
2. **Bill/Invoice Generation** → Create pending bill
3. **Payment Processing** → Cashier receives payment
4. **Service Authorization** → Service can now be rendered
5. **Service Completion** → Update records

### Billing Integration Points

#### A. Service Definitions Setup
**Location:** Account Module → Services Setup

All dental services must be registered in `service_definitions` table:
- Service Code: `DENTAL-XXX`
- Service Name: e.g., "Tooth Extraction", "Root Canal"
- Category: `Dental Services`
- Department: `Dental`
- Base Price: Cost of service
- Facility ID: Current facility

**Dental Service Categories:**
- Preventive (Cleaning, Checkup, Fluoride)
- Restorative (Fillings, Crowns, Bridges)
- Endodontic (Root Canal)
- Periodontic (Gum Treatment)
- Prosthodontic (Dentures, Implants)
- Orthodontic (Braces, Retainers)
- Oral Surgery (Extractions, Implants)
- Dental Lab (Orthodontic Jobs, Prosthetic Jobs)

#### B. Bill Generation Flow
**Endpoint:** `/post-charges`

When dental service is requested:
```javascript
{
  patient_id: "PAT123",
  facilityId: "FAC001",
  items: [
    {
      service_id: "DENTAL-001",
      service_name: "Tooth Extraction",
      service_code: "DENTAL-001",
      quantity: 1,
      unit_price: 5000,
      total: 5000,
      category: "Dental Services",
      department: "Dental",
      tooth_number: "16" // Dental-specific field
    }
  ],
  subtotal: 5000,
  discount: 0,
  total: 5000,
  transaction_type: "dental_service",
  status: "pending", // CRITICAL: Bill is pending until paid
  created_by: userId
}
```

#### C. Cashier Payment Processing
**Location:** Account Module → Pending Bills

Cashier workflow:
1. Search patient by name/ID
2. View pending bills (from `/get-mode-of-payment/:patient_id`)
3. Select payment method:
   - Cash
   - Card/POS
   - Bank Transfer
   - Insurance
   - Add to Bill (Credit)
4. Process payment (generates receipt)
5. Bill status changes to "paid"
6. Service is now authorized

**Endpoint:** `/transactions/new-service/from-deposit`

#### D. Service Authorization Check
Before rendering ANY dental service, check:
```javascript
const isServicePaid = await checkPaymentStatus(patient_id, service_id);
if (!isServicePaid) {
  alert("Payment required before service can be rendered");
  redirectToCashier();
  return;
}
```

#### E. Service Completion
After service is rendered:
```javascript
// Update procedure status
await updateProcedureStatus(procedure_id, 'completed');

// Update bill status
await updateBillStatus(bill_id, 'completed');

// Record service delivery
await recordServiceDelivery({
  patient_id,
  service_id,
  delivered_by: dentist_id,
  delivered_at: new Date()
});
```

---

## PHASE 1: CRITICAL FEATURES (Weeks 1-2)r

### 1.0 Dental Services Setup (Day 1) ⚠️⚠️⚠️ MUST DO FIRST
**Priority:** CRITICAL - Foundation for all billing

#### Task: Register All Dental Services
**Location:** Account Module → Services Setup

Create comprehensive dental service catalog:

```sql
-- Insert dental services into service_definitions
INSERT INTO service_definitions 
(id, service_code, service_name, category, department, base_price, description, facilityId)
VALUES
-- Preventive Services
(UUID(), 'DENTAL-001', 'Dental Consultation', 'Dental Services', 'Dental', 2000, 'Initial dental consultation and examination', 'FAC001'),
(UUID(), 'DENTAL-002', 'Dental Cleaning (Scaling)', 'Dental Services', 'Dental', 5000, 'Professional teeth cleaning and scaling', 'FAC001'),
(UUID(), 'DENTAL-003', 'Fluoride Treatment', 'Dental Services', 'Dental', 3000, 'Fluoride application for cavity prevention', 'FAC001'),

-- Restorative Services
(UUID(), 'DENTAL-010', 'Tooth Filling (Amalgam)', 'Dental Services', 'Dental', 5000, 'Amalgam tooth filling', 'FAC001'),
(UUID(), 'DENTAL-011', 'Tooth Filling (Composite)', 'Dental Services', 'Dental', 8000, 'Composite (white) tooth filling', 'FAC001'),
(UUID(), 'DENTAL-012', 'Dental Crown (Metal)', 'Dental Services', 'Dental', 25000, 'Metal dental crown', 'FAC001'),
(UUID(), 'DENTAL-013', 'Dental Crown (Porcelain)', 'Dental Services', 'Dental', 45000, 'Porcelain dental crown', 'FAC001'),
(UUID(), 'DENTAL-014', 'Dental Bridge (3-unit)', 'Dental Services', 'Dental', 75000, '3-unit dental bridge', 'FAC001'),

-- Endodontic Services
(UUID(), 'DENTAL-020', 'Root Canal (Single Canal)', 'Dental Services', 'Dental', 25000, 'Root canal treatment - single canal', 'FAC001'),
(UUID(), 'DENTAL-021', 'Root Canal (Multi Canal)', 'Dental Services', 'Dental', 35000, 'Root canal treatment - multiple canals', 'FAC001'),

-- Oral Surgery
(UUID(), 'DENTAL-030', 'Simple Tooth Extraction', 'Dental Services', 'Dental', 5000, 'Simple tooth extraction', 'FAC001'),
(UUID(), 'DENTAL-031', 'Surgical Tooth Extraction', 'Dental Services', 'Dental', 15000, 'Surgical tooth extraction', 'FAC001'),
(UUID(), 'DENTAL-032', 'Wisdom Tooth Removal', 'Dental Services', 'Dental', 25000, 'Wisdom tooth extraction', 'FAC001'),

-- Prosthodontic Services
(UUID(), 'DENTAL-040', 'Complete Denture (Upper)', 'Dental Services', 'Dental', 50000, 'Complete upper denture', 'FAC001'),
(UUID(), 'DENTAL-041', 'Complete Denture (Lower)', 'Dental Services', 'Dental', 50000, 'Complete lower denture', 'FAC001'),
(UUID(), 'DENTAL-042', 'Partial Denture', 'Dental Services', 'Dental', 35000, 'Partial denture', 'FAC001'),
(UUID(), 'DENTAL-043', 'Dental Implant', 'Dental Services', 'Dental', 150000, 'Single dental implant', 'FAC001'),

-- Orthodontic Services
(UUID(), 'DENTAL-050', 'Orthodontic Consultation', 'Dental Services', 'Dental', 5000, 'Orthodontic assessment', 'FAC001'),
(UUID(), 'DENTAL-051', 'Metal Braces (Full)', 'Dental Services', 'Dental', 200000, 'Full metal braces treatment', 'FAC001'),
(UUID(), 'DENTAL-052', 'Ceramic Braces (Full)', 'Dental Services', 'Dental', 300000, 'Full ceramic braces treatment', 'FAC001'),
(UUID(), 'DENTAL-053', 'Retainer (Hawley)', 'Dental Services', 'Dental', 25000, 'Hawley retainer', 'FAC001'),

-- Periodontic Services
(UUID(), 'DENTAL-060', 'Gum Treatment (Scaling & Root Planing)', 'Dental Services', 'Dental', 15000, 'Deep cleaning for gum disease', 'FAC001'),
(UUID(), 'DENTAL-061', 'Gum Surgery', 'Dental Services', 'Dental', 50000, 'Periodontal surgery', 'FAC001'),

-- Diagnostic Services
(UUID(), 'DENTAL-070', 'Dental X-Ray (Periapical)', 'Dental Services', 'Dental', 2000, 'Single tooth X-ray', 'FAC001'),
(UUID(), 'DENTAL-071', 'Dental X-Ray (Bitewing)', 'Dental Services', 'Dental', 3000, 'Bitewing X-ray', 'FAC001'),
(UUID(), 'DENTAL-072', 'Panoramic X-Ray (OPG)', 'Dental Services', 'Dental', 8000, 'Full mouth panoramic X-ray', 'FAC001'),
(UUID(), 'DENTAL-073', 'CBCT Scan', 'Dental Services', 'Dental', 25000, 'Cone Beam CT scan', 'FAC001'),

-- Lab Services
(UUID(), 'DENTAL-LAB-001', 'Orthodontic Lab Work', 'Dental Lab Services', 'Dental Lab', 15000, 'Custom orthodontic appliance', 'FAC001'),
(UUID(), 'DENTAL-LAB-002', 'Prosthetic Lab Work', 'Dental Lab Services', 'Dental Lab', 20000, 'Custom prosthetic work', 'FAC001');
```

#### Implementation Steps:
1. **Create SQL Script:** `backend/sql/dental_services_setup.sql`
2. **Run Migration:** Execute script for each facility
3. **Verify in UI:** Account → Services Setup → Filter by "Dental"
4. **Test Service Selection:** Ensure services appear in dental module

---

### 1.1 Appointment Management with Billing (Week 1)
**Priority:** CRITICAL ⚠️⚠️⚠️

#### Components to Create:
- `AppointmentCalendar.jsx` ✅ CREATED
- `AppointmentScheduler.jsx` ✅ CREATED (UPDATE NEEDED)
- `AppointmentBilling.jsx` - NEW: Handle appointment deposits
- `AppointmentDetails.jsx` ✅ CREATED
- `DentistScheduleManager.jsx`
- `FollowUpScheduler.jsx`

#### Updated Features with Billing:
- ✅ Full calendar view (day/week/month)
- ✅ Drag-and-drop rescheduling
- ✅ Available slots display
- ✅ Multi-dentist view
- ✅ Color-coded by status
- ⚠️ **NEW:** Consultation fee billing on booking
- ⚠️ **NEW:** Payment status indicator
- ⚠️ **NEW:** Link to pending bills
- ✅ Appointment history
- ✅ Follow-up automation UI
- ✅ Reminder configuration
- ✅ Notification tracking

#### Billing Integration for Appointments:

**Scenario 1: Consultation Appointment**
```javascript
// When booking consultation appointment
1. Select appointment type: "Consultation"
2. Auto-fetch service: "DENTAL-001" (Dental Consultation - ₦2,000)
3. Generate bill immediately
4. Redirect to cashier OR allow "Add to Bill"
5. Appointment confirmed only after payment
```

**Scenario 2: Treatment Appointment**
```javascript
// When booking treatment appointment
1. Select procedures from catalog
2. Calculate total cost
3. Generate bill
4. Require payment/deposit
5. Appointment confirmed after payment
```

---

### 1.2 Prescription Management with Billing (Week 1)
**Priority:** CRITICAL ⚠️⚠️⚠️

#### Components to Create:
- `PrescriptionForm.jsx` - Create/edit prescriptions
- `PrescriptionList.jsx` - Patient prescription history
- `MedicationDatabase.jsx` - Searchable medication list
- `PrescriptionBilling.jsx` - NEW: Link prescriptions to pharmacy billing
- `PrescriptionPrint.jsx` - Print prescription

#### Features with Billing Integration:
- ✅ Medication search/autocomplete (from existing pharmacy module)
- ✅ Dosage calculator
- ⚠️ **NEW:** Auto-fetch drug prices from pharmacy
- ⚠️ **NEW:** Generate pharmacy bill for prescribed medications
- ⚠️ **NEW:** Payment required before dispensing
- ✅ Prescription templates
- ✅ Print functionality
- ✅ Digital signature
- ✅ Prescription history

#### Billing Integration for Prescriptions:

**Workflow:**
```javascript
// 1. Dentist writes prescription
const prescription = {
  medications: [
    { drug_name: "Amoxicillin 500mg", quantity: 21, price: 50 },
    { drug_name: "Ibuprofen 400mg", quantity: 20, price: 30 }
  ]
};

// 2. Auto-generate pharmacy bill
const bill = {
  patient_id: "PAT123",
  items: prescription.medications,
  total: 1080, // (21*50) + (20*30)
  department: "Pharmacy",
  source: "Dental Prescription",
  status: "pending"
};

// 3. Post to pharmacy billing
await postChargesPharm(bill);

// 4. Patient pays at pharmacy cashier
// 5. Pharmacist dispenses medications
// 6. Update prescription status to "dispensed"
```

---

### 1.3 Procedure Management with Billing (Week 2)
**Priority:** CRITICAL ⚠️⚠️⚠️

#### Components to Create/Update:
- `ProcedureCatalog.jsx` - Browse procedures (linked to service_definitions)
- `ProcedureSelector.jsx` - Quick procedure selection with pricing
- `ProcedureBilling.jsx` - NEW: Generate bills for procedures
- `EnhancedProcedures.jsx` - Update existing component
- `ProcedurePaymentStatus.jsx` - NEW: Track payment status

#### Features with Billing Integration:
- ⚠️ **NEW:** Link to service_definitions table
- ⚠️ **NEW:** Display service prices
- ⚠️ **NEW:** Generate bill on procedure request
- ⚠️ **NEW:** Payment required before procedure
- ⚠️ **NEW:** Payment status indicator (Paid/Pending/Partial)
- ⚠️ **NEW:** Link to cashier for payment
- ✅ Procedure templates
- ✅ Procedure history
- ✅ Cost calculation

#### Billing Integration for Procedures:

**Workflow:**
```javascript
// 1. Dentist selects procedure from catalog
const procedure = {
  service_id: "DENTAL-010",
  service_name: "Tooth Filling (Amalgam)",
  tooth_number: "16",
  price: 5000
};

// 2. Generate bill immediately
const bill = {
  patient_id: "PAT123",
  facilityId: "FAC001",
  items: [{
    service_id: procedure.service_id,
    service_name: procedure.service_name,
    quantity: 1,
    unit_price: procedure.price,
    total: procedure.price,
    tooth_number: procedure.tooth_number,
    category: "Dental Services"
  }],
  total: 5000,
  status: "pending",
  transaction_type: "dental_procedure"
};

await postCharges(bill);

// 3. Show payment prompt
showPaymentPrompt({
  message: "Payment required before procedure",
  amount: 5000,
  actions: ["Pay Now", "Add to Bill", "Cancel"]
});

// 4. If "Pay Now" → Redirect to cashier
// 5. If "Add to Bill" → Add to patient's credit account
// 6. After payment → Procedure status = "authorized"
// 7. Dentist can now perform procedure
// 8. After completion → Update status to "completed"
```

#### Payment Status Component:
```jsx
const ProcedurePaymentStatus = ({ procedure }) => {
  const getStatusBadge = () => {
    if (procedure.payment_status === 'paid') {
      return <span className="badge badge-success">Paid - Authorized</span>;
    } else if (procedure.payment_status === 'pending') {
      return (
        <div>
          <span className="badge badge-warning">Payment Pending</span>
          <button onClick={redirectToCashier}>Pay Now</button>
        </div>
      );
    } else if (procedure.payment_status === 'partial') {
      return <span className="badge badge-info">Partial Payment</span>;
    }
  };

  return (
    <div className="payment-status">
      {getStatusBadge()}
      {procedure.payment_status !== 'paid' && (
        <div className="alert alert-warning">
          ⚠️ Payment required before procedure can be performed
        </div>
      )}
    </div>
  );
};
```

---

### 1.4 Complete Lab Job Cards with Billing (Week 2)
**Priority:** CRITICAL ⚠️⚠️

#### Components to Update:
- `OrthodonticJobCard.jsx` - Add all 50+ fields + billing
- `ProstheticJobCard.jsx` - Add all 60+ fields + billing
- `LabJobBilling.jsx` - NEW: Generate bills for lab work
- `JobCardPrint.jsx` - Professional job card printing
- `JobWorkflow.jsx` - Job status workflow with payment gates
- `TechnicianAssignment.jsx` - Assign jobs to technicians

#### Features with Billing Integration:
- ✅ Complete orthodontic form (retainers, appliances, clasps, springs, etc.)
- ✅ Complete prosthetic form (dentures, crowns, bridges, etc.)
- ⚠️ **NEW:** Auto-calculate lab costs based on selections
- ⚠️ **NEW:** Generate bill on job submission
- ⚠️ **NEW:** Payment required before lab starts work
- ⚠️ **NEW:** Delivery only after full payment
- ✅ Field validation
- ✅ Auto-save drafts
- ✅ Job card printing
- ✅ Status workflow
- ✅ Due date tracking
- ✅ Technician assignment

#### Billing Integration for Lab Jobs:

**Workflow:**
```javascript
// 1. Dentist creates lab job (orthodontic/prosthetic)
const labJob = {
  job_type: "orthodontic",
  patient_id: "PAT123",
  items: [
    { item: "Hawley Retainer - Upper", price: 15000 },
    { item: "Labial Bow", price: 3000 },
    { item: "Adams Clasps (2)", price: 4000 }
  ],
  total_cost: 22000
};

// 2. Generate lab service bill
const bill = {
  patient_id: "PAT123",
  items: [{
    service_id: "DENTAL-LAB-001",
    service_name: "Orthodontic Lab Work",
    quantity: 1,
    unit_price: 22000,
    total: 22000,
    category: "Dental Lab Services",
    job_card_no: "ORTHO-001234"
  }],
  total: 22000,
  status: "pending",
  transaction_type: "dental_lab"
};

await postCharges(bill);

// 3. Payment gates:
// - Job submitted → Bill generated (status: pending)
// - Payment received → Lab starts work (status: in_progress)
// - Work completed → Ready for delivery (status: completed)
// - Full payment verified → Delivered (status: delivered)

// 4. Status workflow with payment checks
const canStartWork = await checkPaymentStatus(job_id);
if (!canStartWork) {
  alert("Payment required before lab can start work");
  return;
}

const canDeliver = await checkFullPayment(job_id);
if (!canDeliver) {
  alert("Full payment required before delivery");
  return;
}
```

#### Lab Cost Calculator:
```jsx
const LabCostCalculator = ({ jobType, selections }) => {
  const [cost, setCost] = useState(0);

  const pricingTable = {
    orthodontic: {
      hawley_retainer: 15000,
      wraparound: 18000,
      labial_bow: 3000,
      adams_clasp: 2000,
      c_clasp: 1500,
      // ... all items
    },
    prosthetic: {
      complete_denture_upper: 50000,
      complete_denture_lower: 50000,
      partial_denture: 35000,
      // ... all items
    }
  };

  useEffect(() => {
    let total = 0;
    selections.forEach(item => {
      total += pricingTable[jobType][item.code] || 0;
    });
    setCost(total);
  }, [selections]);

  return (
    <div className="cost-calculator">
      <h4>Estimated Cost</h4>
      <div className="cost-breakdown">
        {selections.map(item => (
          <div key={item.code}>
            <span>{item.name}</span>
            <span>₦{pricingTable[jobType][item.code]?.toLocaleString()}</span>
          </div>
        ))}
      </div>
      <div className="total-cost">
        <strong>Total:</strong>
        <strong>₦{cost.toLocaleString()}</strong>
      </div>
      <button onClick={generateBill}>Generate Bill</button>
    </div>
  );
};
```

---

## PHASE 2: HIGH PRIORITY FEATURES (Weeks 3-4)

### 2.1 Procedure Catalog & Management with Billing (Week 3)
**Priority:** HIGH ⚠️⚠️

#### Components to Create:
- `ProcedureCatalog.jsx` - Browse/search procedures (linked to service_definitions)
- `ProcedureSelector.jsx` - Quick procedure selection with pricing
- `ProcedureCatalogManager.jsx` - Manage catalog (admin)
- `ProcedureTemplates.jsx` - Procedure templates
- `ProcedureCostCalculator.jsx` - Cost estimation with billing preview

#### Features with Billing Integration:
- ⚠️ **NEW:** Link to service_definitions table for pricing
- ⚠️ **NEW:** Real-time price display from service catalog
- ⚠️ **NEW:** Multi-procedure selection with total calculation
- ⚠️ **NEW:** "Add to Bill" button for each procedure
- ⚠️ **NEW:** Bulk billing for multiple procedures
- ✅ Searchable procedure catalog
- ✅ Category filtering (Preventive, Restorative, Endodontic, etc.)
- ✅ Quick-add to treatment
- ✅ Cost auto-fill from service_definitions
- ✅ Procedure templates
- ✅ Custom procedures
- ✅ Procedure history with payment status

#### Billing Integration for Procedure Catalog:

**Workflow:**
```javascript
// 1. Load procedures from service_definitions
const loadProcedureCatalog = async () => {
  const response = await fetch(`${apiURL()}/services/all?category=Dental Services`);
  const procedures = response.data.results;
  
  // Display with pricing
  procedures.forEach(proc => {
    displayProcedure({
      code: proc.service_code,
      name: proc.service_name,
      category: proc.category,
      price: proc.base_price,
      description: proc.description
    });
  });
};

// 2. Select procedure and add to cart
const addProcedureToCart = (procedure) => {
  cart.push({
    service_id: procedure.service_code,
    service_name: procedure.service_name,
    unit_price: procedure.base_price,
    quantity: 1,
    total: procedure.base_price
  });
  updateCartTotal();
};

// 3. Generate bill for selected procedures
const generateBillFromCart = async () => {
  const bill = {
    patient_id: currentPatient.id,
    facilityId: facilityId,
    items: cart,
    subtotal: calculateSubtotal(),
    total: calculateTotal(),
    status: "pending",
    transaction_type: "dental_procedure"
  };
  
  await postCharges(bill);
  redirectToCashier();
};
```

---

### 2.2 Document & Image Management with Billing (Week 3)
**Priority:** HIGH ⚠️⚠️

#### Components to Create:
- `DocumentUpload.jsx` - File upload component
- `ImageGallery.jsx` - Patient image gallery
- `XRayViewer.jsx` - X-ray viewing (basic DICOM support)
- `DiagnosticImagingBilling.jsx` - NEW: Bill for X-rays and imaging
- `DocumentManager.jsx` - Manage all documents
- `ImageAnnotation.jsx` - Annotate images
- `BeforeAfterComparison.jsx` - Compare images

#### Features with Billing Integration:
- ⚠️ **NEW:** Auto-bill for diagnostic imaging (X-rays, OPG, CBCT)
- ⚠️ **NEW:** Link imaging services to service_definitions
- ⚠️ **NEW:** Payment required before imaging
- ⚠️ **NEW:** Payment status indicator on images
- ✅ Drag-drop file upload
- ✅ Image preview
- ✅ X-ray viewing
- ✅ Image annotation
- ✅ Before/after comparison
- ✅ Document categorization
- ✅ Download/print

#### Billing Integration for Diagnostic Imaging:

**Workflow:**
```javascript
// 1. Request X-ray/imaging
const requestImaging = async (imagingType) => {
  // Get service from catalog
  const service = await getService(`DENTAL-${imagingType}`);
  
  // Generate bill
  const bill = {
    patient_id: patient.id,
    items: [{
      service_id: service.service_code,
      service_name: service.service_name,
      unit_price: service.base_price,
      quantity: 1,
      total: service.base_price,
      category: "Dental Services"
    }],
    total: service.base_price,
    status: "pending",
    transaction_type: "dental_imaging"
  };
  
  await postCharges(bill);
  
  // 2. Check payment before imaging
  const isPaid = await checkPaymentStatus(patient.id, service.service_code);
  
  if (!isPaid) {
    alert("Payment required before imaging can be performed");
    redirectToCashier();
    return;
  }
  
  // 3. Proceed with imaging
  proceedWithImaging();
};

// Imaging service codes:
// DENTAL-070: Periapical X-Ray (₦2,000)
// DENTAL-071: Bitewing X-Ray (₦3,000)
// DENTAL-072: Panoramic X-Ray/OPG (₦8,000)
// DENTAL-073: Cephalometric X-Ray (₦6,000)
// DENTAL-074: CBCT Scan Small (₦20,000)
// DENTAL-075: CBCT Scan Large (₦35,000)
```

---

### 2.3 Enhanced Treatment Plans with Billing (Week 4)
**Priority:** HIGH ⚠️

#### Components to Create:
- `TreatmentPlanBuilder.jsx` - Visual plan builder with cost tracking
- `TreatmentTimeline.jsx` - Visual timeline with payment milestones
- `TreatmentCostBreakdown.jsx` - Detailed cost breakdown with payment schedule
- `TreatmentPlanPrint.jsx` - Professional plan printing with financial summary
- `PatientAcceptance.jsx` - Patient acceptance workflow with deposit payment
- `PaymentPlanManager.jsx` - NEW: Manage installment payments

#### Features with Billing Integration:
- ⚠️ **NEW:** Real-time cost calculation from service_definitions
- ⚠️ **NEW:** Payment plan options (full payment, installments, insurance)
- ⚠️ **NEW:** Deposit requirement for treatment plan acceptance
- ⚠️ **NEW:** Payment milestones tied to treatment phases
- ⚠️ **NEW:** Track payments vs treatment progress
- ⚠️ **NEW:** Generate bills for each treatment phase
- ⚠️ **NEW:** Payment status indicators on timeline
- ✅ Drag-drop procedure ordering
- ✅ Visual timeline
- ✅ Cost calculator
- ✅ Plan comparison
- ✅ Patient acceptance
- ✅ Progress tracking
- ✅ PDF export

#### Billing Integration for Treatment Plans:

**Workflow:**
```javascript
// 1. Build treatment plan with procedures
const treatmentPlan = {
  patient_id: "PAT123",
  plan_name: "Complete Dental Restoration",
  phases: [
    {
      phase: 1,
      name: "Initial Treatment",
      procedures: [
        { service_id: "DENTAL-002", name: "Dental Cleaning", cost: 5000 },
        { service_id: "DENTAL-020", name: "Root Canal", cost: 25000 }
      ],
      total: 30000,
      payment_required: "before_phase"
    },
    {
      phase: 2,
      name: "Restorative Work",
      procedures: [
        { service_id: "DENTAL-014", name: "Porcelain Crown", cost: 45000 },
        { service_id: "DENTAL-011", name: "Composite Filling", cost: 8000 }
      ],
      total: 53000,
      payment_required: "before_phase"
    }
  ],
  grand_total: 83000
};

// 2. Patient accepts plan - require deposit
const acceptTreatmentPlan = async () => {
  const depositAmount = treatmentPlan.grand_total * 0.3; // 30% deposit
  
  // Generate deposit bill
  const depositBill = {
    patient_id: treatmentPlan.patient_id,
    items: [{
      service_id: "DENTAL-DEPOSIT",
      service_name: "Treatment Plan Deposit",
      unit_price: depositAmount,
      quantity: 1,
      total: depositAmount,
      category: "Dental Services"
    }],
    total: depositAmount,
    status: "pending",
    transaction_type: "dental_deposit",
    treatment_plan_id: treatmentPlan.id
  };
  
  await postCharges(depositBill);
  redirectToCashier();
};

// 3. Before each phase - check payment
const startTreatmentPhase = async (phaseNumber) => {
  const phase = treatmentPlan.phases[phaseNumber - 1];
  
  // Generate bill for phase
  const phaseBill = {
    patient_id: treatmentPlan.patient_id,
    items: phase.procedures.map(proc => ({
      service_id: proc.service_id,
      service_name: proc.name,
      unit_price: proc.cost,
      quantity: 1,
      total: proc.cost,
      category: "Dental Services"
    })),
    total: phase.total,
    status: "pending",
    transaction_type: "dental_treatment_phase",
    treatment_plan_id: treatmentPlan.id,
    phase_number: phaseNumber
  };
  
  await postCharges(phaseBill);
  
  // Check payment
  const isPaid = await checkPaymentStatus(treatmentPlan.patient_id, phaseBill.id);
  
  if (!isPaid) {
    alert(`Payment of ₦${phase.total.toLocaleString()} required before Phase ${phaseNumber}`);
    redirectToCashier();
    return false;
  }
  
  return true; // Can proceed with phase
};

// 4. Payment plan option
const createPaymentPlan = (plan, installments) => {
  const installmentAmount = plan.grand_total / installments;
  
  for (let i = 1; i <= installments; i++) {
    schedulePayment({
      patient_id: plan.patient_id,
      amount: installmentAmount,
      due_date: addMonths(new Date(), i),
      installment_number: i,
      total_installments: installments,
      treatment_plan_id: plan.id
    });
  }
};
```

---

### 2.4 Enhanced Procedures UI with Billing (Week 4)
**Priority:** HIGH ⚠️

#### Components to Update:
- `DentalProcedures.jsx` - Complete overhaul with billing integration
- `ProcedureScheduler.jsx` - Schedule procedures with payment verification
- `ProcedureNotes.jsx` - Detailed procedure notes
- `ProcedureConsent.jsx` - Digital consent forms with cost acknowledgment
- `ProcedurePaymentGate.jsx` - NEW: Payment verification before procedure

#### Features with Billing Integration:
- ⚠️ **NEW:** Payment gate before procedure execution
- ⚠️ **NEW:** Real-time payment status display
- ⚠️ **NEW:** Link to pending bills
- ⚠️ **NEW:** Cost display on procedure selection
- ⚠️ **NEW:** "Pay Now" button for unpaid procedures
- ⚠️ **NEW:** Payment history for each procedure
- ✅ Procedure catalog integration
- ✅ Scheduling interface
- ✅ Cost calculation
- ✅ Consent forms
- ✅ Procedure templates
- ✅ Notes and attachments
- ✅ Timeline view

#### Billing Integration for Procedure Execution:

**Workflow:**
```javascript
// 1. Select procedure to perform
const selectProcedure = async (procedureId) => {
  const procedure = await getProcedure(procedureId);
  
  // Check if bill exists
  if (!procedure.bill_id) {
    // Generate bill if not exists
    const bill = await generateProcedureBill(procedure);
    procedure.bill_id = bill.id;
  }
  
  // Check payment status
  const paymentStatus = await checkPaymentStatus(procedure.patient_id, procedure.bill_id);
  
  displayProcedure(procedure, paymentStatus);
};

// 2. Payment gate component
const ProcedurePaymentGate = ({ procedure }) => {
  const [paymentStatus, setPaymentStatus] = useState(null);
  
  useEffect(() => {
    checkPayment();
  }, [procedure.id]);
  
  const checkPayment = async () => {
    const status = await checkPaymentStatus(procedure.patient_id, procedure.bill_id);
    setPaymentStatus(status);
  };
  
  if (paymentStatus === 'paid') {
    return (
      <div className="alert alert-success">
        <i className="fa fa-check-circle"></i> Payment Verified - Procedure Authorized
        <button onClick={startProcedure}>Start Procedure</button>
      </div>
    );
  } else if (paymentStatus === 'pending') {
    return (
      <div className="alert alert-warning">
        <i className="fa fa-exclamation-triangle"></i> Payment Required
        <p>Amount: ₦{procedure.cost.toLocaleString()}</p>
        <button onClick={redirectToCashier}>Pay Now</button>
        <button onClick={addToBill}>Add to Bill</button>
      </div>
    );
  } else {
    return (
      <div className="alert alert-danger">
        <i className="fa fa-times-circle"></i> Payment Status Unknown
        <button onClick={checkPayment}>Refresh Status</button>
      </div>
    );
  }
};

// 3. Procedure execution with payment verification
const executeProcedure = async (procedureId) => {
  const procedure = await getProcedure(procedureId);
  
  // CRITICAL: Verify payment before execution
  const isPaid = await checkPaymentStatus(procedure.patient_id, procedure.bill_id);
  
  if (!isPaid) {
    alert("⚠️ PAYMENT REQUIRED: This procedure cannot be performed without payment");
    redirectToCashier();
    return false;
  }
  
  // Payment verified - proceed with procedure
  await updateProcedureStatus(procedureId, 'in_progress');
  
  // ... perform procedure ...
  
  await updateProcedureStatus(procedureId, 'completed');
  await updateBillStatus(procedure.bill_id, 'completed');
  
  return true;
};
```

---

## PHASE 3: IMPORTANT FEATURES (Weeks 5-6)

### 3.1 Reports & Analytics Dashboard with Financial Integration (Week 5)
**Priority:** MEDIUM-HIGH ⚠️

#### Components to Create:
- `DentalAnalyticsDashboard.jsx` - Main analytics dashboard
- `ProductionReport.jsx` - Revenue by procedure with payment status
- `DentistProductivity.jsx` - Dentist performance with revenue tracking
- `PatientRetention.jsx` - Patient retention metrics
- `AppointmentAnalytics.jsx` - Appointment statistics with revenue
- `LabJobReports.jsx` - Lab job analytics with billing
- `InventoryReports.jsx` - Inventory analytics
- `FinancialReports.jsx` - Financial summaries with payment analysis
- `RevenueAnalytics.jsx` - NEW: Revenue vs services rendered
- `OutstandingPayments.jsx` - NEW: Track unpaid bills

#### Features with Billing Integration:
- ⚠️ **NEW:** Revenue tracking by service type
- ⚠️ **NEW:** Payment status analytics (Paid vs Pending vs Partial)
- ⚠️ **NEW:** Outstanding payments report
- ⚠️ **NEW:** Revenue by dentist
- ⚠️ **NEW:** Revenue by procedure category
- ⚠️ **NEW:** Payment method distribution
- ⚠️ **NEW:** Daily/Weekly/Monthly revenue trends
- ⚠️ **NEW:** Services rendered vs payments received
- ✅ Revenue charts
- ✅ Procedure statistics
- ✅ Dentist productivity
- ✅ Patient retention
- ✅ Appointment analytics
- ✅ Lab performance
- ✅ Inventory turnover
- ✅ Export to Excel/PDF

#### Billing Analytics Queries:

```javascript
// Revenue by service type
const getRevenueByServiceType = async (dateFrom, dateTo) => {
  const query = `
    SELECT 
      service_type,
      COUNT(*) as service_count,
      SUM(amount) as total_revenue,
      SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) as paid_revenue,
      SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) as pending_revenue
    FROM charges
    WHERE department = 'Dental'
      AND transaction_date BETWEEN ? AND ?
    GROUP BY service_type
  `;
  return await executeQuery(query, [dateFrom, dateTo]);
};

// Outstanding payments
const getOutstandingPayments = async () => {
  const query = `
    SELECT 
      p.patient_id,
      p.firstname,
      p.surname,
      c.description,
      c.amount,
      c.transaction_date,
      DATEDIFF(NOW(), c.transaction_date) as days_outstanding
    FROM charges c
    JOIN patients p ON c.patient_id = p.patient_id
    WHERE c.status = 'pending'
      AND c.department = 'Dental'
    ORDER BY c.transaction_date ASC
  `;
  return await executeQuery(query);
};

// Revenue by dentist
const getRevenueByDentist = async (dateFrom, dateTo) => {
  const query = `
    SELECT 
      u.firstname,
      u.lastname,
      COUNT(DISTINCT c.patient_id) as patients_served,
      COUNT(*) as services_rendered,
      SUM(c.amount) as total_revenue
    FROM charges c
    JOIN dental_procedures dp ON c.transaction_id = dp.bill_id
    JOIN users u ON dp.dentist_id = u.id
    WHERE c.transaction_date BETWEEN ? AND ?
      AND c.status = 'paid'
    GROUP BY u.id
    ORDER BY total_revenue DESC
  `;
  return await executeQuery(query, [dateFrom, dateTo]);
};
```

---

### 3.2 Notification Center with Payment Alerts (Week 5)
**Priority:** MEDIUM-HIGH ⚠️

#### Components to Create:
- `NotificationCenter.jsx` - Main notification hub
- `NotificationBell.jsx` - Header notification icon
- `NotificationSettings.jsx` - Configure notifications
- `ReminderManager.jsx` - Manage reminders
- `AlertsPanel.jsx` - System alerts
- `PaymentAlerts.jsx` - NEW: Payment-related notifications

#### Features with Billing Integration:
- ⚠️ **NEW:** Payment received notifications
- ⚠️ **NEW:** Pending payment reminders
- ⚠️ **NEW:** Overdue payment alerts
- ⚠️ **NEW:** Payment plan due date reminders
- ⚠️ **NEW:** Deposit required notifications
- ✅ Real-time notifications
- ✅ Notification history
- ✅ Mark as read/unread
- ✅ Notification preferences
- ✅ Alert configuration
- ✅ Reminder management

#### Payment Notification Types:

```javascript
const paymentNotifications = {
  payment_received: {
    title: "Payment Received",
    message: "Payment of ₦{amount} received from {patient_name}",
    icon: "fa-check-circle",
    color: "success"
  },
  payment_pending: {
    title: "Payment Pending",
    message: "{patient_name} has pending bill of ₦{amount}",
    icon: "fa-clock",
    color: "warning"
  },
  payment_overdue: {
    title: "Payment Overdue",
    message: "{patient_name} has overdue payment of ₦{amount} ({days} days)",
    icon: "fa-exclamation-triangle",
    color: "danger"
  },
  deposit_required: {
    title: "Deposit Required",
    message: "Treatment plan requires ₦{amount} deposit from {patient_name}",
    icon: "fa-money-bill",
    color: "info"
  },
  installment_due: {
    title: "Installment Due",
    message: "{patient_name} has installment of ₦{amount} due on {date}",
    icon: "fa-calendar-check",
    color: "warning"
  }
};
```

---

### 3.3 Enhanced Walk-in Queue with Payment Status (Week 6)
**Priority:** MEDIUM ⚠️

#### Components to Update:
- `WalkinQueue.jsx` - Complete overhaul with payment indicators
- `QueueDisplayBoard.jsx` - Digital display board
- `QueueStatistics.jsx` - Queue analytics
- `PatientNotification.jsx` - Notify patients
- `QueuePaymentStatus.jsx` - NEW: Show payment status in queue

#### Features with Billing Integration:
- ⚠️ **NEW:** Payment status indicator for each patient
- ⚠️ **NEW:** Filter by payment status (Paid/Pending/Unpaid)
- ⚠️ **NEW:** Quick payment link from queue
- ⚠️ **NEW:** Consultation fee collection before queue entry
- ⚠️ **NEW:** Outstanding balance display
- ✅ Real-time updates (WebSocket)
- ✅ Priority color coding
- ✅ Waiting time alerts
- ✅ Queue statistics
- ✅ Display board mode
- ✅ Patient SMS notifications

#### Queue with Payment Integration:

```javascript
const QueueItemWithPayment = ({ patient, queueItem }) => {
  const [paymentStatus, setPaymentStatus] = useState(null);
  
  useEffect(() => {
    checkPaymentStatus(patient.patient_id).then(setPaymentStatus);
  }, [patient.patient_id]);
  
  return (
    <div className="queue-item">
      <div className="patient-info">
        <strong>{patient.firstname} {patient.surname}</strong>
        <span className="queue-number">#{queueItem.queue_number}</span>
      </div>
      
      <div className="payment-status">
        {paymentStatus === 'paid' ? (
          <span className="badge badge-success">
            <i className="fa fa-check"></i> Paid
          </span>
        ) : paymentStatus === 'pending' ? (
          <span className="badge badge-warning">
            <i className="fa fa-clock"></i> Pending ₦{queueItem.amount}
          </span>
        ) : (
          <span className="badge badge-danger">
            <i className="fa fa-times"></i> Unpaid
          </span>
        )}
      </div>
      
      {paymentStatus !== 'paid' && (
        <button 
          className="btn btn-sm btn-primary"
          onClick={() => redirectToCashier(patient.patient_id)}
        >
          Collect Payment
        </button>
      )}
    </div>
  );
};

// Consultation fee collection on queue entry
const addToQueue = async (patientId) => {
  // Generate consultation bill
  const consultationBill = {
    patient_id: patientId,
    items: [{
      service_id: "DENTAL-001",
      service_name: "Dental Consultation",
      unit_price: 2000,
      quantity: 1,
      total: 2000,
      category: "Dental Services"
    }],
    total: 2000,
    status: "pending",
    transaction_type: "dental_consultation"
  };
  
  await postCharges(consultationBill);
  
  // Prompt for payment
  const payNow = confirm("Consultation fee: ₦2,000. Collect payment now?");
  
  if (payNow) {
    redirectToCashier(patientId);
  } else {
    // Add to queue with pending payment
    await addPatientToQueue(patientId, { payment_status: 'pending' });
  }
};
```

---

### 3.4 Oral Care Shop Enhancements with Billing (Week 6)
**Priority:** MEDIUM ⚠️

#### Components to Update:
- `ProductCatalog.jsx` - Enhanced catalog
- `ProductSales.jsx` - Improved POS with dental billing integration
- `InventoryManagement.jsx` - Complete inventory system
- `PurchaseOrders.jsx` - Purchase order management
- `SupplierManagement.jsx` - Supplier management
- `PromotionsManager.jsx` - Promotions and discounts
- `DentalProductBilling.jsx` - NEW: Link product sales to dental billing

#### Features with Billing Integration:
- ⚠️ **NEW:** Link oral care product sales to patient accounts
- ⚠️ **NEW:** Add products to dental bills
- ⚠️ **NEW:** Product recommendations based on procedures
- ⚠️ **NEW:** Bundle products with procedures (e.g., toothbrush with cleaning)
- ⚠️ **NEW:** Track product sales by dentist recommendation
- ✅ Barcode scanning
- ✅ Receipt printing
- ✅ Product search
- ✅ Low stock alerts
- ✅ Expiry tracking
- ✅ Purchase orders
- ✅ Supplier management
- ✅ Promotions

#### Product Sales Integration:

```javascript
// Add oral care products to dental bill
const addProductToDentalBill = async (patientId, product) => {
  const bill = {
    patient_id: patientId,
    items: [{
      service_id: `PRODUCT-${product.id}`,
      service_name: product.name,
      unit_price: product.price,
      quantity: 1,
      total: product.price,
      category: "Oral Care Products"
    }],
    total: product.price,
    status: "pending",
    transaction_type: "dental_product_sale"
  };
  
  await postCharges(bill);
};

// Recommend products after procedure
const recommendProducts = (procedureType) => {
  const recommendations = {
    cleaning: ["Toothbrush", "Toothpaste", "Mouthwash"],
    extraction: ["Gauze", "Pain Relief Gel", "Antiseptic Mouthwash"],
    filling: ["Sensitive Toothpaste", "Soft Toothbrush"],
    root_canal: ["Pain Relief Medication", "Antiseptic Mouthwash"],
    orthodontic: ["Orthodontic Wax", "Special Toothbrush", "Floss Threader"]
  };
  
  return recommendations[procedureType] || [];
};
```

---

## PHASE 4: POLISH & OPTIMIZATION (Weeks 7-8)

### 4.1 UI/UX Improvements with Billing UX (Week 7)
**Priority:** MEDIUM ⚠️

#### Focus Areas:
- Design system implementation
- Consistent styling across billing components
- Responsive design for cashier workflows
- Accessibility improvements
- Loading states for payment processing
- Error handling for failed transactions
- Form validation for billing forms
- User guidance (tooltips, help)
- ⚠️ **NEW:** Payment status badges and indicators
- ⚠️ **NEW:** Clear payment flow visualization
- ⚠️ **NEW:** Quick payment shortcuts
- ⚠️ **NEW:** Payment confirmation dialogs
- ⚠️ **NEW:** Receipt preview before printing

#### Billing UX Enhancements:

```javascript
// Payment status badge component
const PaymentStatusBadge = ({ status, amount }) => {
  const statusConfig = {
    paid: { color: 'success', icon: 'check-circle', text: 'Paid' },
    pending: { color: 'warning', icon: 'clock', text: 'Pending' },
    partial: { color: 'info', icon: 'hourglass-half', text: 'Partial' },
    overdue: { color: 'danger', icon: 'exclamation-triangle', text: 'Overdue' }
  };
  
  const config = statusConfig[status];
  
  return (
    <span className={`badge badge-${config.color}`}>
      <i className={`fa fa-${config.icon}`}></i> {config.text}
      {amount && ` - ₦${amount.toLocaleString()}`}
    </span>
  );
};

// Quick payment button
const QuickPayButton = ({ patientId, amount, onSuccess }) => {
  return (
    <button 
      className="btn btn-success btn-sm quick-pay"
      onClick={() => processQuickPayment(patientId, amount, onSuccess)}
    >
      <i className="fa fa-bolt"></i> Quick Pay ₦{amount.toLocaleString()}
    </button>
  );
};
```

---

### 4.2 Performance Optimization with Billing Performance (Week 7)
**Priority:** MEDIUM ⚠️

#### Focus Areas:
- Code splitting
- Lazy loading
- API call optimization
- Caching strategy
- WebSocket integration for real-time payment updates
- Real-time updates
- ⚠️ **NEW:** Cache service definitions locally
- ⚠️ **NEW:** Optimize payment status checks
- ⚠️ **NEW:** Batch billing operations
- ⚠️ **NEW:** Debounce payment verification calls
- ⚠️ **NEW:** Preload common billing data

#### Billing Performance Optimizations:

```javascript
// Cache service definitions
const ServiceCache = {
  data: null,
  timestamp: null,
  ttl: 3600000, // 1 hour
  
  async get() {
    if (this.data && Date.now() - this.timestamp < this.ttl) {
      return this.data;
    }
    
    const response = await fetch(`${apiURL()}/services/all`);
    this.data = await response.json();
    this.timestamp = Date.now();
    
    return this.data;
  },
  
  invalidate() {
    this.data = null;
    this.timestamp = null;
  }
};

// Batch payment status checks
const batchCheckPaymentStatus = async (patientIds) => {
  const response = await fetch(`${apiURL()}/batch-payment-status`, {
    method: 'POST',
    body: JSON.stringify({ patient_ids: patientIds })
  });
  
  return await response.json();
};

// Debounced payment verification
const debouncedPaymentCheck = debounce(async (patientId, callback) => {
  const status = await checkPaymentStatus(patientId);
  callback(status);
}, 500);
```

---

### 4.3 Additional Features with Billing Features (Week 8)
**Priority:** LOW-MEDIUM ⚠️

#### Features to Add:
- Consent forms management with cost acknowledgment
- Visit history timeline with payment history
- Patient portal (basic) with billing access
- Mobile optimization for cashier workflows
- Print templates for receipts and invoices
- Export functionality for financial reports
- Backup/restore
- ⚠️ **NEW:** Payment receipt templates
- ⚠️ **NEW:** Invoice generation and printing
- ⚠️ **NEW:** Payment history export
- ⚠️ **NEW:** Financial statement generation
- ⚠️ **NEW:** SMS payment reminders
- ⚠️ **NEW:** Email invoices to patients
- ⚠️ **NEW:** Payment plan agreements (PDF)

#### Additional Billing Features:

```javascript
// Receipt template
const generateReceipt = (payment) => {
  return {
    receipt_no: payment.receipt_no,
    date: payment.transaction_date,
    patient: {
      name: payment.patient_name,
      id: payment.patient_id
    },
    items: payment.items.map(item => ({
      description: item.service_name,
      amount: item.total
    })),
    subtotal: payment.subtotal,
    discount: payment.discount,
    total: payment.total,
    payment_method: payment.payment_method,
    received_by: payment.cashier_name
  };
};

// Invoice generation
const generateInvoice = async (patientId, dateFrom, dateTo) => {
  const charges = await getCharges(patientId, dateFrom, dateTo);
  
  const invoice = {
    invoice_no: generateInvoiceNo(),
    date: new Date(),
    patient: await getPatient(patientId),
    items: charges.map(charge => ({
      date: charge.transaction_date,
      description: charge.description,
      amount: charge.amount,
      status: charge.status
    })),
    total: charges.reduce((sum, c) => sum + c.amount, 0),
    paid: charges.filter(c => c.status === 'paid').reduce((sum, c) => sum + c.amount, 0),
    balance: charges.filter(c => c.status === 'pending').reduce((sum, c) => sum + c.amount, 0)
  };
  
  return invoice;
};

// SMS payment reminder
const sendPaymentReminder = async (patientId, amount, dueDate) => {
  const patient = await getPatient(patientId);
  
  const message = `
    Dear ${patient.firstname},
    
    This is a reminder that you have an outstanding balance of ₦${amount.toLocaleString()} 
    due on ${dueDate}. Please visit our facility to make payment.
    
    Thank you.
    ${facilityName}
  `;
  
  await sendSMS(patient.phoneNo, message);
};

// Email invoice
const emailInvoice = async (patientId, invoiceData) => {
  const patient = await getPatient(patientId);
  
  const emailData = {
    to: patient.email,
    subject: `Invoice #${invoiceData.invoice_no} - ${facilityName}`,
    template: 'dental_invoice',
    data: invoiceData,
    attachments: [
      {
        filename: `invoice_${invoiceData.invoice_no}.pdf`,
        content: await generateInvoicePDF(invoiceData)
      }
    ]
  };
  
  await sendEmail(emailData);
};
```

---

## TECHNICAL ARCHITECTURE

### State Management
- Redux for global state
- React Context for local state
- React Query for API calls

### UI Framework
- React 18+
- React Router v6
- Material-UI or Ant Design
- Tailwind CSS for styling

### Key Libraries
- FullCalendar for appointments
- React DnD for drag-drop
- Chart.js for analytics
- React-PDF for printing
- Socket.io for real-time
- Axios for API calls
- Formik + Yup for forms

### Code Organization
```
frontend/src/components/dental/
├── appointments/
│   ├── AppointmentCalendar.jsx
│   ├── AppointmentScheduler.jsx
│   ├── DentistScheduleManager.jsx
│   └── ...
├── prescriptions/
│   ├── PrescriptionForm.jsx
│   ├── PrescriptionList.jsx
│   └── ...
├── procedures/
│   ├── ProcedureCatalog.jsx
│   ├── ProcedureSelector.jsx
│   └── ...
├── treatment-plans/
│   ├── TreatmentPlanBuilder.jsx
│   ├── TreatmentTimeline.jsx
│   └── ...
├── documents/
│   ├── DocumentUpload.jsx
│   ├── ImageGallery.jsx
│   └── ...
├── reports/
│   ├── DentalAnalyticsDashboard.jsx
│   └── ...
├── shared/
│   ├── LoadingSpinner.jsx
│   ├── ErrorBoundary.jsx
│   └── ...
└── ...
```

---

## IMPLEMENTATION STRATEGY

### Week-by-Week Breakdown

**Week 1:**
- Day 1-2: Appointment Calendar
- Day 3-4: Appointment Scheduler
- Day 5: Prescription Form

**Week 2:**
- Day 1-2: Complete Prescription Module
- Day 3-5: Lab Job Cards (Orthodontic)

**Week 3:**
- Day 1-2: Lab Job Cards (Prosthetic)
- Day 3-4: Procedure Catalog
- Day 5: Document Upload

**Week 4:**
- Day 1-2: Image Gallery & Viewer
- Day 3-5: Treatment Plan Builder

**Week 5:**
- Day 1-3: Reports Dashboard
- Day 4-5: Notification Center

**Week 6:**
- Day 1-2: Enhanced Queue
- Day 3-5: Oral Care Enhancements

**Week 7:**
- Day 1-3: UI/UX Polish
- Day 4-5: Performance Optimization

**Week 8:**
- Day 1-3: Additional Features
- Day 4-5: Testing & Bug Fixes

---

## TESTING STRATEGY

### Unit Tests
- Component testing with Jest
- API integration tests
- Form validation tests

### Integration Tests
- End-to-end workflows
- API integration
- State management

### User Acceptance Testing
- Real dentist feedback
- Workflow validation
- Performance testing

---

## DEPLOYMENT PLAN

### Staging Environment
- Deploy to staging after each phase
- User testing
- Bug fixes

### Production Rollout
- Phased rollout by feature
- Monitor performance
- Gather feedback
- Iterate

---

## SUCCESS METRICS

### Technical Metrics
- Page load time < 2s
- API response time < 500ms
- 95% test coverage
- Zero critical bugs

### User Metrics
- User satisfaction > 4.5/5
- Task completion rate > 90%
- Reduced appointment booking time by 50%
- Reduced prescription time by 60%

---

## RISK MITIGATION

### Technical Risks
- **Risk:** Complex calendar integration
- **Mitigation:** Use proven library (FullCalendar)

- **Risk:** Real-time updates performance
- **Mitigation:** Implement WebSocket with fallback

- **Risk:** Large forms (lab cards)
- **Mitigation:** Auto-save, section-by-section

### Business Risks
- **Risk:** User adoption
- **Mitigation:** Training, documentation, support

- **Risk:** Data migration
- **Mitigation:** Backward compatibility, migration scripts

---

## NEXT STEPS

1. ✅ Review and approve plan
2. ⚠️ **CRITICAL:** Run dental services setup SQL script (`backend/sql/dental_services_setup.sql`)
3. ⚠️ **CRITICAL:** Verify services in Account → Services Setup
4. Set up development environment
5. Create component structure
6. Start Phase 1 implementation (with billing integration)
7. Weekly progress reviews
8. Continuous testing and feedback

---

## BILLING INTEGRATION CHECKLIST

### Pre-Implementation (Day 1)
- [ ] Run `dental_services_setup.sql` for each facility
- [ ] Verify all dental services appear in Services Setup
- [ ] Test service pricing display
- [ ] Verify `/post-charges` endpoint works
- [ ] Verify `/transactions/new-service/from-deposit` endpoint works
- [ ] Test `/get-mode-of-payment/:patient_id` endpoint
- [ ] Ensure cashier page (PendingBills.jsx) is functional

### Phase 1 Billing Integration
- [ ] Update AppointmentScheduler to generate consultation bills
- [ ] Create AppointmentBilling component
- [ ] Update PrescriptionForm to generate pharmacy bills
- [ ] Create PrescriptionBilling component
- [ ] Update DentalProcedures to check payment before execution
- [ ] Create ProcedureBilling component
- [ ] Update OrthodonticJobCard to generate lab bills
- [ ] Update ProstheticJobCard to generate lab bills
- [ ] Create LabJobBilling component
- [ ] Test complete workflow: Service → Bill → Payment → Service Delivery

### Phase 2 Billing Integration
- [ ] Link ProcedureCatalog to service_definitions
- [ ] Add billing to diagnostic imaging
- [ ] Create DiagnosticImagingBilling component
- [ ] Implement treatment plan deposit system
- [ ] Create PaymentPlanManager component
- [ ] Add payment gates to all procedure execution points

### Phase 3 Billing Integration
- [ ] Implement revenue analytics dashboard
- [ ] Create outstanding payments report
- [ ] Add payment notifications
- [ ] Integrate payment status in walk-in queue
- [ ] Link oral care shop to dental billing

### Phase 4 Billing Integration
- [ ] Optimize payment status checks
- [ ] Implement receipt templates
- [ ] Create invoice generation
- [ ] Add SMS payment reminders
- [ ] Implement email invoicing

---

## BILLING INTEGRATION TESTING CHECKLIST

### Appointment Billing Test
1. [ ] Schedule consultation appointment
2. [ ] Verify bill generated with DENTAL-001 (₦2,000)
3. [ ] Check bill appears in Pending Bills
4. [ ] Process payment via cashier
5. [ ] Verify appointment status updates to "confirmed"
6. [ ] Verify receipt generated

### Procedure Billing Test
1. [ ] Select procedure from catalog
2. [ ] Verify price auto-fills from service_definitions
3. [ ] Generate bill
4. [ ] Attempt to execute procedure without payment (should fail)
5. [ ] Process payment
6. [ ] Execute procedure (should succeed)
7. [ ] Verify bill status updates to "completed"

### Lab Job Billing Test
1. [ ] Create orthodontic job card
2. [ ] Select appliances/components
3. [ ] Verify cost calculation
4. [ ] Generate lab bill
5. [ ] Attempt to start lab work without payment (should fail)
6. [ ] Process payment
7. [ ] Start lab work (should succeed)
8. [ ] Complete job
9. [ ] Verify delivery only after full payment

### Prescription Billing Test
1. [ ] Write prescription
2. [ ] Verify drug prices fetched from pharmacy
3. [ ] Generate pharmacy bill
4. [ ] Check bill appears in pharmacy pending bills
5. [ ] Process payment
6. [ ] Dispense medications
7. [ ] Verify prescription status updates to "dispensed"

### Treatment Plan Billing Test
1. [ ] Create multi-phase treatment plan
2. [ ] Verify total cost calculation
3. [ ] Generate deposit bill (30%)
4. [ ] Process deposit payment
5. [ ] Attempt to start Phase 1 without payment (should fail)
6. [ ] Generate Phase 1 bill
7. [ ] Process Phase 1 payment
8. [ ] Start Phase 1 (should succeed)
9. [ ] Repeat for subsequent phases

---

## CRITICAL BILLING RULES (MUST FOLLOW)

### Rule 1: NO SERVICE WITHOUT PAYMENT
```javascript
// ALWAYS check payment before service
const canRenderService = async (patientId, serviceId) => {
  const paymentStatus = await checkPaymentStatus(patientId, serviceId);
  
  if (paymentStatus !== 'paid') {
    alert('⚠️ PAYMENT REQUIRED: Service cannot be rendered without payment');
    redirectToCashier(patientId);
    return false;
  }
  
  return true;
};
```

### Rule 2: ALWAYS LINK TO SERVICE_DEFINITIONS
```javascript
// NEVER hardcode prices - always fetch from service_definitions
const getServicePrice = async (serviceCode) => {
  const service = await fetch(`${apiURL()}/services/by-code/${serviceCode}`);
  return service.base_price;
};
```

### Rule 3: GENERATE BILL IMMEDIATELY
```javascript
// Generate bill as soon as service is requested
const requestService = async (patientId, serviceCode) => {
  const service = await getService(serviceCode);
  
  // Generate bill immediately
  const bill = await postCharges({
    patient_id: patientId,
    items: [{ service_id: serviceCode, ...service }],
    status: 'pending'
  });
  
  return bill;
};
```

### Rule 4: UPDATE STATUS AFTER PAYMENT
```javascript
// Update bill and service status after payment
const afterPayment = async (billId, serviceId) => {
  await updateBillStatus(billId, 'paid');
  await updateServiceStatus(serviceId, 'authorized');
  
  // Now service can be rendered
};
```

### Rule 5: TRACK EVERYTHING
```javascript
// Log all billing transactions
const logBillingTransaction = async (transaction) => {
  await insertLog({
    type: 'billing',
    action: transaction.action,
    patient_id: transaction.patient_id,
    amount: transaction.amount,
    status: transaction.status,
    timestamp: new Date(),
    user_id: currentUser.id
  });
};
```

---

## BILLING INTEGRATION ENDPOINTS REFERENCE

### Generate Bill
```
POST /post-charges
Body: {
  patient_id: string,
  facilityId: string,
  items: [{
    service_id: string,
    service_name: string,
    quantity: number,
    unit_price: number,
    total: number,
    category: string
  }],
  subtotal: number,
  discount: number,
  total: number,
  status: 'pending',
  transaction_type: string
}
```

### Process Payment
```
POST /transactions/new-service/from-deposit
Body: {
  amount: number,
  modeOfPayment: string, // 'CASH', 'BANK', 'POS', 'INSURANCE'
  receiptsn: string,
  receiptno: string,
  patientId: string,
  transaction_date: string,
  description: string
}
```

### Check Payment Status
```
GET /get-mode-of-payment/:patient_id
Response: {
  success: boolean,
  data: [{
    transaction_id: string,
    description: string,
    amount: number,
    status: string,
    service_type: string,
    createdAt: date
  }]
}
```

### Get Services
```
GET /services/all?category=Dental Services
Response: {
  success: boolean,
  results: [{
    service_code: string,
    service_name: string,
    category: string,
    base_price: number,
    description: string
  }]
}
```

---

## SUCCESS METRICS (UPDATED WITH BILLING)

### Technical Metrics
- Page load time < 2s
- API response time < 500ms
- Payment processing time < 3s
- 95% test coverage
- Zero critical bugs
- 100% billing accuracy

### User Metrics
- User satisfaction > 4.5/5
- Task completion rate > 90%
- Reduced appointment booking time by 50%
- Reduced prescription time by 60%
- 100% payment capture rate
- Zero revenue leakage
- Reduced billing errors by 95%

### Financial Metrics
- 100% of services billed
- 0% unbilled services
- Payment collection rate > 95%
- Outstanding payments < 5% of total revenue
- Average payment processing time < 5 minutes

---

## SUPPORT & DOCUMENTATION

### For Developers
- Billing integration guide: `DENTAL_IMPLEMENTATION_GUIDE.md`
- API documentation: `BACKEND_API_COMPLETE.md`
- Database schema: `backend/sql/dental_complete_schema.sql`
- Services setup: `backend/sql/dental_services_setup.sql`

### For Users
- Quick reference: `QUICK_REFERENCE_CARD.md`
- Appointments guide: `APPOINTMENTS_QUICK_REFERENCE.md`
- Quick start: `QUICK_START.md`

### For Administrators
- Implementation plan: This document
- Gap analysis: `FRONTEND_IMPLEMENTATION_GAP_ANALYSIS.md`
- Status summary: `CURRENT_STATUS_SUMMARY.md`

