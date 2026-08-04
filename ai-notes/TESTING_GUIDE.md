# DENTAL MODULE BILLING INTEGRATION - TESTING GUIDE

**Date:** March 4, 2026  
**Version:** 1.0  
**Status:** Ready for Testing

---

## 🎯 TESTING OVERVIEW

This guide provides step-by-step instructions for testing all Phase 1 billing workflows. Follow these tests in order to ensure complete functionality.

---

## 📋 PRE-TESTING CHECKLIST

### 1. Database Setup ✅
```bash
# Navigate to backend/sql directory
cd backend/sql

# Run the dental services setup script
# First, update the facilityId in the SQL file
# Then execute:
mysql -u your_username -p your_database < dental_services_setup.sql

# Or if using the MySQL client:
mysql -u your_username -p
USE your_database;
SOURCE dental_services_setup.sql;
```

### 2. Verify Services in Database ✅
```sql
-- Check if services were added
SELECT COUNT(*) FROM service_definitions 
WHERE category IN ('Dental Services', 'Dental Lab Services');

-- Should return 100+ services

-- View some services
SELECT service_code, service_name, base_price 
FROM service_definitions 
WHERE category = 'Dental Services' 
LIMIT 10;
```

### 3. Start Backend Server ✅
```bash
cd backend
npm install  # If not already installed
npm start    # Or your start command

# Server should start on port 3000 (or your configured port)
```

### 4. Start Frontend Server ✅
```bash
cd frontend
npm install  # If not already installed
npm run dev  # Or npm start

# Frontend should start on port 5173 (Vite) or 3001
```

### 5. Login to Application ✅
- Open browser: `http://localhost:5173` (or your frontend URL)
- Login with valid credentials
- Ensure you have access to Dental module

---

## 🧪 TEST 1: APPOINTMENT BOOKING WITH PAYMENT

### Objective
Test the complete appointment booking workflow with billing integration.

### Prerequisites
- At least one patient in the system
- At least one dentist user
- Services setup complete

### Test Steps

#### Step 1: Navigate to Appointments
```
1. Login to application
2. Navigate to: Dental Module → Appointments
3. Click "Schedule Appointment" or "New Appointment" button
```

#### Step 2: Select Patient (Step 1)
```
1. Search for patient by name or ID
2. Select a patient from the list
3. Verify patient details are displayed
4. Click "Next" button
```

**Expected Result:**
- Patient search works
- Patient can be selected
- "Next" button is enabled after selection

#### Step 3: Select Dentist & Time (Step 2)
```
1. Select a dentist from dropdown
2. Select appointment date and time
3. Select duration (e.g., 30 minutes)
4. Verify available slots are shown (if implemented)
5. Click "Next" button
```

**Expected Result:**
- Dentist dropdown populated
- Date/time picker works
- Duration can be selected
- "Next" button enabled

#### Step 4: Enter Appointment Details (Step 3)
```
1. Select appointment type: "Consultation"
2. Enter chief complaint: "Toothache"
3. Enter notes: "Patient reports pain in upper right molar"
4. Review appointment summary
5. Click "Continue to Payment" button
```

**Expected Result:**
- Appointment type dropdown works
- Text fields accept input
- Summary displays correctly
- Button changes to "Continue to Payment"

#### Step 5: Payment (Step 4) - CRITICAL TEST
```
1. Verify billing information is displayed:
   - Service: "Dental Consultation"
   - Amount: ₦2,000
   - Service Code: DENTAL-001

2. Test "Pay Now" option:
   a. Click "Pay Now" button
   b. Payment modal should open
   c. Select payment method: "CASH"
   d. Click "Confirm Payment"
   e. Wait for processing
   f. Verify success message
   g. Verify receipt number is generated

3. OR Test "Add to Bill" option:
   a. Click "Add to Bill" button
   b. Verify bill is generated
   c. Verify message about cashier payment
```

**Expected Results:**
- ✅ Billing information displays correctly
- ✅ Amount is ₦2,000 for consultation
- ✅ Payment modal opens
- ✅ Payment methods are available
- ✅ Payment processes successfully
- ✅ Success message appears
- ✅ Appointment is confirmed
- ✅ Receipt number is generated

**Database Verification:**
```sql
-- Check if appointment was created
SELECT * FROM dental_appointments 
WHERE patient_id = 'YOUR_PATIENT_ID' 
ORDER BY created_at DESC LIMIT 1;

-- Check if bill was generated
SELECT * FROM charges 
WHERE patient_id = 'YOUR_PATIENT_ID' 
AND description LIKE '%Consultation%'
ORDER BY created_at DESC LIMIT 1;

-- Check payment status
SELECT * FROM transactions 
WHERE patient_id = 'YOUR_PATIENT_ID'
ORDER BY transaction_date DESC LIMIT 1;
```

### Test Variations

#### Variation 1: Different Appointment Types
```
Repeat test with:
- Appointment Type: "Checkup" → Should charge ₦1,500
- Appointment Type: "Cleaning" → Should charge ₦5,000
- Appointment Type: "Emergency" → Should charge ₦5,000
```

#### Variation 2: Payment Methods
```
Test each payment method:
- CASH
- POS (Card)
- BANK (Transfer)
- INSURANCE
```

#### Variation 3: Add to Bill
```
1. Select "Add to Bill" instead of "Pay Now"
2. Verify bill is created with status "pending"
3. Navigate to: Account → Pending Bills
4. Search for patient
5. Verify bill appears in pending bills
6. Process payment from cashier page
```

---

## 🧪 TEST 2: PRESCRIPTION WITH PHARMACY BILLING

### Objective
Test prescription creation with pharmacy billing integration.

### Prerequisites
- Patient selected or in context
- Drugs in pharmacy inventory
- Pharmacy billing endpoint working

### Test Steps

#### Step 1: Open Prescription Form
```
1. Navigate to: Dental Module → Prescriptions
2. Click "New Prescription" or "Create Prescription"
3. Select patient (if not already selected)
```

#### Step 2: Add Medications (Step 1)
```
1. Search for medication: "Amoxicillin"
2. Select from suggestions
3. Verify drug details auto-fill:
   - Dosage: 500mg
   - Price: (from pharmacy)
4. Set frequency: "TDS" (Three times daily)
5. Set duration: "7 days"
6. Set quantity: 21 (7 days × 3 times)
7. Add instructions: "Take after meals"
8. Click "Add Medication"

9. Add second medication:
   - Drug: "Ibuprofen 400mg"
   - Frequency: "TDS"
   - Duration: "5 days"
   - Quantity: 15
   - Instructions: "Take with food"
   - Click "Add Medication"

10. Verify medications list shows both drugs
11. Add notes: "Patient allergic to penicillin - use alternative if needed"
12. Click "Continue to Billing"
```

**Expected Results:**
- ✅ Drug search works
- ✅ Suggestions appear
- ✅ Prices fetch from pharmacy
- ✅ Medications can be added
- ✅ Medications list displays correctly
- ✅ Total cost calculates automatically

#### Step 3: Billing (Step 2) - CRITICAL TEST
```
1. Verify billing summary displays:
   - Amoxicillin 500mg × 21 = ₦1,050 (example)
   - Ibuprofen 400mg × 15 = ₦450 (example)
   - Total: ₦1,500 (example)

2. Review workflow information:
   - Bill generated in pharmacy system
   - Patient goes to pharmacy
   - Patient pays at pharmacy cashier
   - Pharmacist dispenses medications

3. Click "Generate Pharmacy Bill"
4. Verify confirmation modal
5. Click "Generate Bill"
6. Wait for processing
7. Verify success message
```

**Expected Results:**
- ✅ Cost breakdown displays correctly
- ✅ Total calculates correctly
- ✅ Workflow information is clear
- ✅ Bill generates successfully
- ✅ Success message appears
- ✅ Prescription is saved

**Database Verification:**
```sql
-- Check if prescription was created
SELECT * FROM dental_prescriptions 
WHERE patient_id = 'YOUR_PATIENT_ID' 
ORDER BY created_at DESC LIMIT 1;

-- Check if pharmacy bill was generated
SELECT * FROM pharmacy_charges 
WHERE patient_id = 'YOUR_PATIENT_ID'
ORDER BY created_at DESC LIMIT 1;

-- Check prescription medications
SELECT * FROM prescription_medications 
WHERE prescription_id = 'YOUR_PRESCRIPTION_ID';
```

### Test Variations

#### Variation 1: Multiple Medications
```
Add 5+ medications and verify:
- All are added to list
- Total calculates correctly
- Bill includes all items
```

#### Variation 2: Skip Billing
```
1. Click "Skip Billing" button
2. Verify prescription is saved without bill
3. Verify appropriate message
```

#### Variation 3: Pharmacy Payment
```
1. After generating bill, navigate to pharmacy
2. Search for patient in pending bills
3. Verify bill appears
4. Process payment
5. Verify prescription status updates
```

---

## 🧪 TEST 3: PROCEDURE WITH PAYMENT GATE

### Objective
Test procedure billing with payment gate that blocks unpaid procedures.

### Prerequisites
- Patient selected
- Procedure services in service_definitions
- Charges API working

### Test Steps

#### Step 1: Select Procedure
```
1. Navigate to: Dental Module → Procedures
2. Select patient
3. Click "New Procedure" or "Add Procedure"
4. Select procedure: "Tooth Filling (Amalgam)"
5. Enter tooth number: "16"
6. Enter notes: "Cavity on occlusal surface"
```

#### Step 2: View Billing Information
```
1. Verify billing component displays:
   - Service: "Tooth Filling (Amalgam)"
   - Tooth: 16
   - Amount: ₦5,000
   - Service Code: DENTAL-010
   - Payment Status: "Not Billed" (red alert)

2. Verify alert message:
   "Payment Required: Bill must be generated and paid before procedure can be performed"
```

**Expected Results:**
- ✅ Billing information displays
- ✅ Price fetched from service_definitions
- ✅ Payment status shows "Not Billed"
- ✅ Warning message displays

#### Step 3: Generate Bill - CRITICAL TEST
```
1. Click "Generate Bill" button
2. Wait for processing
3. Verify success message
4. Verify payment status changes to "Pending" (yellow alert)
5. Verify new message:
   "Payment Required - Amount: ₦5,000 - Bill generated. Awaiting payment."
6. Verify buttons appear:
   - "Go to Cashier"
   - "Verify Payment"
```

**Expected Results:**
- ✅ Bill generates successfully
- ✅ Status changes to "Pending"
- ✅ Amount displays correctly
- ✅ Action buttons appear

#### Step 4: Test Payment Gate - CRITICAL TEST
```
1. Try to execute/complete procedure
2. Verify procedure is BLOCKED
3. Verify error message:
   "Payment required before procedure can be performed"
4. Verify procedure cannot be marked as completed
```

**Expected Results:**
- ✅ Procedure execution is blocked
- ✅ Clear error message
- ✅ Cannot proceed without payment

#### Step 5: Process Payment
```
1. Click "Go to Cashier" button
2. Should redirect to: Account → Pending Bills
3. Search for patient
4. Verify bill appears in pending bills
5. Select payment method: "CASH"
6. Click "Pay Now"
7. Process payment
8. Verify receipt is generated
```

**Expected Results:**
- ✅ Redirects to cashier
- ✅ Bill appears in pending bills
- ✅ Payment processes successfully
- ✅ Receipt generated

#### Step 6: Verify Payment - CRITICAL TEST
```
1. Return to procedure page
2. Click "Verify Payment" button
3. Wait for verification
4. Verify payment status changes to "Paid" (green alert)
5. Verify message:
   "Payment Verified - Procedure Authorized"
6. Verify procedure can now be executed
7. Complete the procedure
8. Verify status updates to "Completed"
```

**Expected Results:**
- ✅ Payment verification works
- ✅ Status changes to "Paid"
- ✅ Success message displays
- ✅ Procedure can be executed
- ✅ Procedure can be completed

**Database Verification:**
```sql
-- Check procedure
SELECT * FROM dental_procedures 
WHERE patient_id = 'YOUR_PATIENT_ID' 
AND tooth_number = '16'
ORDER BY created_at DESC LIMIT 1;

-- Check bill
SELECT * FROM charges 
WHERE patient_id = 'YOUR_PATIENT_ID'
AND description LIKE '%Filling%'
ORDER BY created_at DESC LIMIT 1;

-- Check payment
SELECT * FROM transactions 
WHERE patient_id = 'YOUR_PATIENT_ID'
ORDER BY transaction_date DESC LIMIT 1;
```

### Test Variations

#### Variation 1: Different Procedures
```
Test with:
- Root Canal (₦20,000 - ₦35,000)
- Tooth Extraction (₦5,000 - ₦35,000)
- Crown (₦25,000 - ₦60,000)
```

#### Variation 2: Multiple Procedures
```
1. Add multiple procedures for same patient
2. Verify each has separate billing
3. Verify payment gates work independently
```

---

## 🧪 TEST 4: LAB JOB WITH DUAL PAYMENT GATES

### Objective
Test lab job billing with two payment gates (before work starts and before delivery).

### Prerequisites
- Patient information
- Lab services in service_definitions
- Lab job tables exist

### Test Steps - Orthodontic Job

#### Step 1: Create Orthodontic Job Card
```
1. Navigate to: Dental Module → Lab → Orthodontic Jobs
2. Click "New Job Card"
3. Fill patient information:
   - Patient Name: "John Doe"
   - Age: 25
   - Gender: Male
4. Fill doctor information:
   - Doctor Name: "Dr. Smith"
   - Practice: "Dental Clinic"
5. Fill job details:
   - Date Received: Today
   - Due Date: +7 days
6. Select items:
   - ☑ Hawley Retainer - Upper
   - ☑ Adams Clasp (2)
   - ☑ Z Spring
7. Click "Create Job Card & Continue to Billing"
```

**Expected Results:**
- ✅ Form accepts all inputs
- ✅ Items can be selected
- ✅ Job card is created

#### Step 2: View Cost Breakdown - CRITICAL TEST
```
1. Verify billing step displays
2. Verify cost breakdown shows:
   - Hawley Retainer - Upper: ₦15,000
   - Adams Clasp × 2: ₦4,000
   - Z Spring: ₦2,500
   - Total: ₦21,500

3. Verify payment status: "Not Billed"
4. Verify alert message:
   "Payment Required: Bill must be generated and paid before lab can start work"
```

**Expected Results:**
- ✅ Cost breakdown displays correctly
- ✅ Prices match pricing table
- ✅ Total calculates correctly
- ✅ Warning message displays

#### Step 3: Generate Bill - PAYMENT GATE 1
```
1. Click "Generate Bill" button
2. Wait for processing
3. Verify success message
4. Verify payment status changes to "Pending"
5. Verify message:
   "Payment Required Before Lab Starts Work - Amount: ₦21,500"
6. Verify buttons:
   - "Go to Cashier"
   - "Verify Payment"
```

**Expected Results:**
- ✅ Bill generates successfully
- ✅ Status changes to "Pending"
- ✅ Gate 1 message displays
- ✅ Lab work is blocked

#### Step 4: Test Payment Gate 1 - CRITICAL TEST
```
1. Try to start lab work
2. Verify lab work is BLOCKED
3. Verify error message
4. Verify job status remains "pending"
```

**Expected Results:**
- ✅ Lab work cannot start
- ✅ Clear blocking message
- ✅ Status remains "pending"

#### Step 5: Process Payment for Gate 1
```
1. Click "Go to Cashier"
2. Navigate to pending bills
3. Find lab job bill
4. Process payment (₦21,500)
5. Generate receipt
6. Return to lab job
7. Click "Verify Payment"
```

**Expected Results:**
- ✅ Payment processes successfully
- ✅ Receipt generated

#### Step 6: Verify Payment Gate 1 Passed - CRITICAL TEST
```
1. After payment verification
2. Verify payment status: "Paid" (green)
3. Verify message:
   "Payment Verified - Lab Work Authorized"
4. Verify job status can change to "in_progress"
5. Start lab work
6. Complete lab work
7. Change status to "completed"
```

**Expected Results:**
- ✅ Payment verified
- ✅ Lab work can start
- ✅ Status can change to "in_progress"
- ✅ Work can be completed

#### Step 7: Test Payment Gate 2 - CRITICAL TEST
```
1. With job status "completed"
2. Try to deliver job to dentist
3. Verify delivery is BLOCKED (if partial payment)
4. Verify message:
   "Full Payment Required Before Delivery"
5. If full payment already made, verify delivery is ALLOWED
```

**Expected Results:**
- ✅ Gate 2 checks full payment
- ✅ Delivery blocked if unpaid
- ✅ Delivery allowed if paid
- ✅ Clear messages

**Database Verification:**
```sql
-- Check lab job
SELECT * FROM dental_lab_orthodontic 
WHERE patient_name = 'John Doe'
ORDER BY created_at DESC LIMIT 1;

-- Check bill
SELECT * FROM charges 
WHERE description LIKE '%Orthodontic Lab%'
ORDER BY created_at DESC LIMIT 1;

-- Check payment
SELECT * FROM transactions 
WHERE description LIKE '%Lab%'
ORDER BY transaction_date DESC LIMIT 1;
```

### Test Steps - Prosthetic Job

#### Repeat Similar Steps for Prosthetic
```
1. Create prosthetic job card
2. Select items:
   - Complete Denture - Upper
   - Denture Repair
3. Verify cost calculation:
   - Complete Denture - Upper: ₦50,000
   - Denture Repair: ₦8,000
   - Total: ₦58,000
4. Test both payment gates
5. Verify workflow
```

---

## 🧪 TEST 5: END-TO-END INTEGRATION TEST

### Objective
Test complete patient journey with multiple services.

### Scenario: Patient with Multiple Services

#### Step 1: Appointment
```
1. Book consultation appointment
2. Pay consultation fee (₦2,000)
3. Verify appointment confirmed
```

#### Step 2: Examination & Prescription
```
1. After consultation, create prescription
2. Add medications
3. Generate pharmacy bill
4. Patient pays at pharmacy
5. Medications dispensed
```

#### Step 3: Procedure
```
1. Dentist recommends filling
2. Generate procedure bill (₦5,000)
3. Patient pays
4. Procedure performed
5. Procedure completed
```

#### Step 4: Lab Work
```
1. Dentist orders crown
2. Create lab job
3. Generate lab bill (₦45,000)
4. Patient pays
5. Lab starts work
6. Lab completes work
7. Verify full payment
8. Deliver to dentist
```

#### Step 5: Verify Complete Journey
```
1. Check patient's billing history
2. Verify all services billed
3. Verify all payments recorded
4. Verify all receipts generated
5. Calculate total spent
6. Verify no unbilled services
```

**Expected Total:**
- Consultation: ₦2,000
- Medications: ~₦1,500
- Filling: ₦5,000
- Crown: ₦45,000
- **Total: ₦53,500**

---

## 🔍 VERIFICATION CHECKLIST

### For Each Test
- [ ] Component loads without errors
- [ ] Data fetches correctly
- [ ] Forms accept input
- [ ] Validation works
- [ ] Bills generate correctly
- [ ] Payments process successfully
- [ ] Status updates correctly
- [ ] Error messages are clear
- [ ] Success messages appear
- [ ] Database records created
- [ ] Receipts generated
- [ ] Payment gates work
- [ ] Redirects work correctly

---

## 🐛 COMMON ISSUES & SOLUTIONS

### Issue 1: Services Not Found
**Problem:** "Service not found" error  
**Solution:**
```sql
-- Verify services exist
SELECT * FROM service_definitions WHERE service_code = 'DENTAL-001';

-- If missing, run dental_services_setup.sql again
```

### Issue 2: Payment Not Processing
**Problem:** Payment fails or hangs  
**Solution:**
- Check backend logs
- Verify `/transactions/new-service/from-deposit` endpoint
- Check receipt generation function
- Verify database connection

### Issue 3: Payment Status Not Updating
**Problem:** Status stays "pending" after payment  
**Solution:**
- Check `/get-mode-of-payment/:patient_id` endpoint
- Verify transaction was recorded
- Click "Verify Payment" button
- Check database for transaction record

### Issue 4: Bill Not Appearing in Cashier
**Problem:** Bill doesn't show in pending bills  
**Solution:**
```sql
-- Check if bill was created
SELECT * FROM charges WHERE patient_id = 'YOUR_PATIENT_ID' AND status = 'pending';

-- If exists, check cashier query
-- Verify patient_id matches
```

### Issue 5: Payment Gate Not Blocking
**Problem:** Service can be performed without payment  
**Solution:**
- Check payment status check logic
- Verify `checkPaymentStatus` function
- Check if payment verification is called
- Review component code

---

## 📊 TEST RESULTS TEMPLATE

Use this template to record test results:

```
TEST: [Test Name]
DATE: [Date]
TESTER: [Your Name]

STEPS COMPLETED:
[ ] Step 1: [Description]
[ ] Step 2: [Description]
[ ] Step 3: [Description]

RESULTS:
✅ PASS / ❌ FAIL

ISSUES FOUND:
1. [Issue description]
2. [Issue description]

SCREENSHOTS:
- [Attach screenshots]

NOTES:
[Additional notes]
```

---

## 🎯 SUCCESS CRITERIA

### All Tests Pass When:
- ✅ All components load without errors
- ✅ All forms accept and validate input
- ✅ All bills generate correctly
- ✅ All payments process successfully
- ✅ All payment gates block unpaid services
- ✅ All payment gates allow paid services
- ✅ All status updates work correctly
- ✅ All database records are created
- ✅ All receipts are generated
- ✅ All error messages are clear
- ✅ All success messages appear
- ✅ No console errors
- ✅ No broken links
- ✅ No UI glitches

---

## 📞 SUPPORT

### If You Encounter Issues:
1. Check console for errors (F12 → Console)
2. Check network tab for failed requests (F12 → Network)
3. Check backend logs
4. Review database records
5. Refer to component code
6. Check API endpoints
7. Verify service definitions exist

### Debug Mode:
```javascript
// Add to component for debugging
console.log('Payment Status:', paymentStatus);
console.log('Bill ID:', billId);
console.log('Service:', service);
console.log('Total Cost:', totalCost);
```

---

**Happy Testing! 🧪**

Remember: The goal is to ensure NO SERVICE is rendered WITHOUT PAYMENT. Every test should verify this critical principle.
