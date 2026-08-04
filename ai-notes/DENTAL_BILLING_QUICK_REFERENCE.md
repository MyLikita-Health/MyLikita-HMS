# DENTAL BILLING INTEGRATION - QUICK REFERENCE

**Last Updated:** March 4, 2026  
**Status:** Implementation Ready

---

## 🚨 CRITICAL RULE: NO SERVICE WITHOUT PAYMENT

Every dental service MUST follow this workflow:
```
Service Request → Bill Generation → Payment → Service Authorization → Service Delivery
```

---

## 📋 BILLING WORKFLOW BY SERVICE TYPE

### 1. CONSULTATION APPOINTMENT
```
Step 1: Patient books consultation
Step 2: Generate bill (DENTAL-001, ₦2,000)
Step 3: Redirect to cashier OR "Add to Bill"
Step 4: Cashier processes payment
Step 5: Appointment confirmed
Step 6: Receipt generated
```

**Service Code:** `DENTAL-001`  
**Service Name:** Dental Consultation  
**Price:** ₦2,000

---

### 2. DENTAL PROCEDURE
```
Step 1: Dentist selects procedure from catalog
Step 2: System auto-fills price from service_definitions
Step 3: Generate bill immediately
Step 4: Check payment status
Step 5: If unpaid → Block procedure, show "Pay Now" button
Step 6: If paid → Authorize procedure execution
Step 7: Dentist performs procedure
Step 8: Update status to "completed"
```

**Example Services:**
- `DENTAL-010` - Tooth Filling (Amalgam) - ₦5,000
- `DENTAL-011` - Tooth Filling (Composite) - ₦8,000
- `DENTAL-020` - Root Canal (Single Canal) - ₦20,000
- `DENTAL-030` - Simple Tooth Extraction - ₦5,000

---

### 3. PRESCRIPTION
```
Step 1: Dentist writes prescription
Step 2: System fetches drug prices from pharmacy
Step 3: Generate pharmacy bill
Step 4: Bill appears in pharmacy pending bills
Step 5: Patient pays at pharmacy cashier
Step 6: Pharmacist dispenses medications
Step 7: Update prescription status to "dispensed"
```

**Integration:** Links to existing pharmacy billing system

---

### 4. LAB JOB (ORTHODONTIC/PROSTHETIC)
```
Step 1: Dentist creates lab job card
Step 2: Select appliances/components
Step 3: System calculates total cost
Step 4: Generate lab bill
Step 5: Payment Gate 1: Payment required before lab starts work
Step 6: Lab technician completes work
Step 7: Payment Gate 2: Verify full payment before delivery
Step 8: Deliver to dentist
```

**Service Codes:**
- `DENTAL-LAB-001` - Orthodontic Lab Work (Basic) - ₦15,000
- `DENTAL-LAB-002` - Orthodontic Lab Work (Complex) - ₦25,000
- `DENTAL-LAB-003` - Prosthetic Lab Work (Basic) - ₦20,000
- `DENTAL-LAB-004` - Prosthetic Lab Work (Complex) - ₦35,000

---

### 5. DIAGNOSTIC IMAGING
```
Step 1: Request X-ray/imaging
Step 2: Get service from catalog (DENTAL-070 to DENTAL-075)
Step 3: Generate bill
Step 4: Check payment status
Step 5: If unpaid → Block imaging, redirect to cashier
Step 6: If paid → Proceed with imaging
Step 7: Upload/store images
```

**Service Codes:**
- `DENTAL-070` - Periapical X-Ray - ₦2,000
- `DENTAL-071` - Bitewing X-Ray - ₦3,000
- `DENTAL-072` - Panoramic X-Ray (OPG) - ₦8,000
- `DENTAL-073` - Cephalometric X-Ray - ₦6,000
- `DENTAL-074` - CBCT Scan (Small) - ₦20,000
- `DENTAL-075` - CBCT Scan (Large) - ₦35,000

---

### 6. TREATMENT PLAN
```
Step 1: Build multi-phase treatment plan
Step 2: Calculate total cost from service_definitions
Step 3: Patient reviews and accepts plan
Step 4: Generate deposit bill (30% of total)
Step 5: Process deposit payment
Step 6: For each phase:
   a. Generate phase bill
   b. Verify payment
   c. If unpaid → Block phase, redirect to cashier
   d. If paid → Execute phase procedures
   e. Update progress
Step 7: Track payments vs treatment progress
```

**Payment Options:**
- Full payment upfront
- Installment plan (monthly)
- Insurance coverage
- Combination

---

## 💳 PAYMENT METHODS

### Available Options
1. **CASH** - Cash payment at cashier
2. **BANK** - Bank transfer
3. **POS** - Card payment via POS terminal
4. **INSURANCE** - Insurance coverage
5. **CREDIT** - Add to patient's bill (credit account)

### Payment Processing
All payments processed through: **Account Module → Pending Bills**

---

## 🔍 PAYMENT STATUS INDICATORS

### Status Types
- 🟢 **PAID** - Payment received, service authorized
- 🟡 **PENDING** - Bill generated, awaiting payment
- 🔵 **PARTIAL** - Partial payment received
- 🔴 **OVERDUE** - Payment overdue

### Status Checks
```javascript
// Check before ANY service
const isPaid = await checkPaymentStatus(patient_id, service_id);
if (!isPaid) {
  alert("Payment required before service");
  redirectToCashier();
  return;
}
```

---

## 📊 SERVICE CATEGORIES & PRICING

### Preventive Services (₦1,000 - ₦5,000)
- Consultation, Checkup, Cleaning, Fluoride

### Restorative Services (₦5,000 - ₦60,000)
- Fillings, Crowns, Bridges, Inlays, Veneers

### Endodontic Services (₦8,000 - ₦40,000)
- Root Canal, Pulpotomy, Apicectomy

### Oral Surgery (₦5,000 - ₦35,000)
- Extractions, Wisdom Teeth, Frenectomy, Biopsy

### Prosthodontic Services (₦8,000 - ₦400,000)
- Dentures, Implants, Repairs, Relines

### Orthodontic Services (₦5,000 - ₦500,000)
- Braces, Retainers, Aligners, Adjustments

### Periodontic Services (₦8,000 - ₦50,000)
- Scaling, Root Planing, Gum Surgery, Grafts

### Pediatric Services (₦2,000 - ₦8,000)
- Children's consultation, Sealants, Fluoride

### Cosmetic Services (₦15,000 - ₦50,000)
- Whitening, Bonding, Smile Makeover

### Emergency Services (₦3,000 - ₦8,000)
- Emergency consultation, Pain relief, Temporary fixes

---

## 🔗 API ENDPOINTS

### 1. Generate Bill
```
POST /post-charges

Body:
{
  "patient_id": "PAT123",
  "facilityId": "FAC001",
  "items": [{
    "service_id": "DENTAL-001",
    "service_name": "Dental Consultation",
    "quantity": 1,
    "unit_price": 2000,
    "total": 2000,
    "category": "Dental Services"
  }],
  "subtotal": 2000,
  "discount": 0,
  "total": 2000,
  "status": "pending",
  "transaction_type": "dental_service"
}
```

### 2. Process Payment
```
POST /transactions/new-service/from-deposit

Body:
{
  "amount": 2000,
  "modeOfPayment": "CASH",
  "receiptsn": "REC-001",
  "receiptno": "12345",
  "patientId": "PAT123",
  "transaction_date": "2026-03-04",
  "description": "Dental Consultation"
}
```

### 3. Check Payment Status
```
GET /get-mode-of-payment/:patient_id

Response:
{
  "success": true,
  "data": [{
    "transaction_id": "TXN123",
    "description": "Dental Consultation",
    "amount": 2000,
    "status": "pending",
    "service_type": "CONSULTATION",
    "createdAt": "2026-03-04T10:00:00Z"
  }]
}
```

### 4. Get Services
```
GET /services/all?category=Dental Services

Response:
{
  "success": true,
  "results": [{
    "service_code": "DENTAL-001",
    "service_name": "Dental Consultation",
    "category": "Dental Services",
    "base_price": 2000,
    "description": "Initial dental consultation"
  }]
}
```

---

## ✅ IMPLEMENTATION CHECKLIST

### Day 1 (CRITICAL)
- [ ] Run `dental_services_setup.sql`
- [ ] Verify services in Services Setup
- [ ] Test billing endpoints
- [ ] Test cashier page

### Week 1
- [ ] Appointment billing integration
- [ ] Prescription billing integration
- [ ] Test complete workflows

### Week 2
- [ ] Procedure billing integration
- [ ] Lab job billing integration
- [ ] Payment gates implemented

### Week 3-4
- [ ] Procedure catalog linked to services
- [ ] Imaging billing integrated
- [ ] Treatment plan billing complete

### Week 5-6
- [ ] Revenue analytics dashboard
- [ ] Payment notifications
- [ ] Queue payment status

### Week 7-8
- [ ] UI/UX polish
- [ ] Performance optimization
- [ ] Receipt/invoice templates

---

## 🚫 COMMON MISTAKES TO AVOID

### ❌ DON'T
1. Hardcode prices in frontend
2. Allow service without payment verification
3. Skip bill generation
4. Forget to update status after payment
5. Use different billing flow for different services

### ✅ DO
1. Always fetch prices from service_definitions
2. Always check payment before service
3. Generate bill immediately on service request
4. Update bill and service status after payment
5. Use consistent billing workflow

---

## 📞 SUPPORT

### For Developers
- Implementation Guide: `DENTAL_IMPLEMENTATION_GUIDE.md`
- Complete Plan: `DENTAL_COMPLETE_IMPLEMENTATION_PLAN.md`
- Update Summary: `BILLING_INTEGRATION_UPDATE_SUMMARY.md`

### For Users
- Quick Start: `QUICK_START.md`
- Appointments Guide: `APPOINTMENTS_QUICK_REFERENCE.md`

---

## 🎯 SUCCESS CRITERIA

- ✅ 100% of services billed
- ✅ 0% unbilled services
- ✅ Payment collection rate > 95%
- ✅ Outstanding payments < 5%
- ✅ Average payment time < 5 minutes
- ✅ Zero revenue leakage

---

**Remember:** Every service request = Immediate bill generation = Payment verification = Service authorization = Service delivery

**NO EXCEPTIONS!**
