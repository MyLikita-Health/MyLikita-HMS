# TESTING CHECKLIST - PHASE 1 BILLING INTEGRATION

**Quick reference checklist for testing all Phase 1 workflows**

---

## 🚀 QUICK START

### 1. Setup (Do Once)
```bash
# 1. Run services setup SQL
cd backend/sql
mysql -u username -p database < dental_services_setup.sql

# 2. Start backend
cd backend
npm start

# 3. Start frontend
cd frontend
npm run dev

# 4. Login to application
# Open: http://localhost:5173
```

### 2. Verify Setup
```sql
-- Check services exist
SELECT COUNT(*) FROM service_definitions 
WHERE category IN ('Dental Services', 'Dental Lab Services');
-- Should return 100+
```

---

## ✅ TEST 1: APPOINTMENT BOOKING (15 mins)

### Quick Steps
1. [ ] Navigate to Dental → Appointments
2. [ ] Click "New Appointment"
3. [ ] Select patient
4. [ ] Select dentist & time
5. [ ] Select type: "Consultation"
6. [ ] Continue to payment
7. [ ] Verify amount: ₦2,000
8. [ ] Click "Pay Now"
9. [ ] Select payment: CASH
10. [ ] Confirm payment
11. [ ] Verify success message
12. [ ] Verify receipt generated

### Expected Results
- ✅ Billing shows ₦2,000
- ✅ Payment processes
- ✅ Appointment confirmed
- ✅ Receipt generated

### Quick Verify
```sql
SELECT * FROM dental_appointments 
WHERE patient_id = 'YOUR_PATIENT_ID' 
ORDER BY created_at DESC LIMIT 1;
```

---

## ✅ TEST 2: PRESCRIPTION (10 mins)

### Quick Steps
1. [ ] Navigate to Dental → Prescriptions
2. [ ] Click "New Prescription"
3. [ ] Search drug: "Amoxicillin"
4. [ ] Set: TDS, 7 days, qty 21
5. [ ] Add medication
6. [ ] Add second drug: "Ibuprofen"
7. [ ] Continue to billing
8. [ ] Verify total cost
9. [ ] Click "Generate Pharmacy Bill"
10. [ ] Verify success message

### Expected Results
- ✅ Drugs found
- ✅ Prices fetched
- ✅ Total calculated
- ✅ Bill generated

### Quick Verify
```sql
SELECT * FROM dental_prescriptions 
WHERE patient_id = 'YOUR_PATIENT_ID' 
ORDER BY created_at DESC LIMIT 1;
```

---

## ✅ TEST 3: PROCEDURE WITH PAYMENT GATE (20 mins)

### Quick Steps
1. [ ] Navigate to Dental → Procedures
2. [ ] Click "New Procedure"
3. [ ] Select: "Tooth Filling"
4. [ ] Enter tooth: 16
5. [ ] Verify status: "Not Billed" (RED)
6. [ ] Click "Generate Bill"
7. [ ] Verify status: "Pending" (YELLOW)
8. [ ] Try to execute → Should BLOCK ❌
9. [ ] Click "Go to Cashier"
10. [ ] Find bill in pending bills
11. [ ] Process payment
12. [ ] Return to procedure
13. [ ] Click "Verify Payment"
14. [ ] Verify status: "Paid" (GREEN)
15. [ ] Execute procedure → Should ALLOW ✅
16. [ ] Complete procedure

### Expected Results
- ✅ Bill generates: ₦5,000
- ✅ Procedure BLOCKED before payment
- ✅ Payment processes
- ✅ Procedure ALLOWED after payment
- ✅ Status updates correctly

### Critical Test Points
- ❌ MUST block unpaid procedure
- ✅ MUST allow paid procedure

---

## ✅ TEST 4: LAB JOB - ORTHODONTIC (25 mins)

### Quick Steps
1. [ ] Navigate to Dental → Lab → Orthodontic
2. [ ] Click "New Job Card"
3. [ ] Fill patient info
4. [ ] Select items:
   - [ ] Hawley Retainer - Upper
   - [ ] Adams Clasp
   - [ ] Z Spring
5. [ ] Click "Create & Continue to Billing"
6. [ ] Verify cost breakdown
7. [ ] Verify total: ~₦19,500
8. [ ] Verify status: "Not Billed"
9. [ ] Click "Generate Bill"
10. [ ] Verify status: "Pending"
11. [ ] Try to start lab work → Should BLOCK ❌ (Gate 1)
12. [ ] Go to cashier
13. [ ] Process payment
14. [ ] Verify payment
15. [ ] Verify status: "Paid"
16. [ ] Start lab work → Should ALLOW ✅
17. [ ] Complete lab work
18. [ ] Try to deliver → Check Gate 2
19. [ ] Verify full payment
20. [ ] Deliver → Should ALLOW ✅

### Expected Results
- ✅ Cost calculates correctly
- ✅ Gate 1: Blocks lab start without payment
- ✅ Gate 1: Allows lab start after payment
- ✅ Gate 2: Blocks delivery without full payment
- ✅ Gate 2: Allows delivery after full payment

### Critical Test Points
- ❌ MUST block lab start (Gate 1)
- ❌ MUST block delivery (Gate 2)
- ✅ MUST allow after payment

---

## ✅ TEST 5: LAB JOB - PROSTHETIC (25 mins)

### Quick Steps
1. [ ] Navigate to Dental → Lab → Prosthetic
2. [ ] Click "New Job Card"
3. [ ] Fill patient info
4. [ ] Select items:
   - [ ] Complete Denture - Upper
   - [ ] Denture Repair
5. [ ] Continue to billing
6. [ ] Verify total: ~₦58,000
7. [ ] Test both payment gates
8. [ ] Complete workflow

### Expected Results
- ✅ Same as orthodontic test
- ✅ Both gates work correctly

---

## 🔍 QUICK VERIFICATION QUERIES

### Check All Patient Bills
```sql
SELECT 
  description,
  amount,
  status,
  created_at
FROM charges 
WHERE patient_id = 'YOUR_PATIENT_ID'
ORDER BY created_at DESC;
```

### Check All Payments
```sql
SELECT 
  amount,
  modeOfPayment,
  receiptno,
  transaction_date
FROM transactions 
WHERE patient_id = 'YOUR_PATIENT_ID'
ORDER BY transaction_date DESC;
```

### Check Pending Bills
```sql
SELECT * FROM charges 
WHERE patient_id = 'YOUR_PATIENT_ID' 
AND status = 'pending';
```

---

## 🐛 QUICK TROUBLESHOOTING

### Services Not Found?
```sql
-- Run this:
SOURCE backend/sql/dental_services_setup.sql;
```

### Payment Not Processing?
- Check backend logs
- Verify endpoint: `/transactions/new-service/from-deposit`
- Check receipt generation function

### Status Not Updating?
- Click "Verify Payment" button
- Check endpoint: `/get-mode-of-payment/:patient_id`
- Refresh page

### Bill Not in Cashier?
```sql
-- Check if bill exists:
SELECT * FROM charges 
WHERE patient_id = 'YOUR_PATIENT_ID' 
AND status = 'pending';
```

---

## 📊 TEST COMPLETION TRACKER

### Day 1
- [ ] Setup complete
- [ ] Test 1: Appointments
- [ ] Test 2: Prescriptions

### Day 2
- [ ] Test 3: Procedures
- [ ] Test 4: Orthodontic Lab
- [ ] Test 5: Prosthetic Lab

### Final
- [ ] All tests passed
- [ ] No critical issues
- [ ] Documentation updated
- [ ] Ready for production

---

## ✅ PASS CRITERIA

### All Tests Must:
- ✅ Load without errors
- ✅ Generate bills correctly
- ✅ Process payments successfully
- ✅ Block unpaid services
- ✅ Allow paid services
- ✅ Update status correctly
- ✅ Generate receipts
- ✅ Show clear messages

### Critical: Payment Gates
- ❌ Unpaid services MUST be blocked
- ✅ Paid services MUST be allowed
- ⚠️ Clear error messages MUST show

---

## 🎯 TESTING PRIORITY

### Priority 1 (Must Test)
1. ✅ Appointment payment
2. ✅ Procedure payment gate
3. ✅ Lab payment gates (both)

### Priority 2 (Should Test)
4. ✅ Prescription billing
5. ✅ Multiple payment methods
6. ✅ Cashier integration

### Priority 3 (Nice to Test)
7. ✅ Different service types
8. ✅ Multiple services per patient
9. ✅ Error scenarios

---

## 📞 NEED HELP?

### Check:
1. Console (F12 → Console)
2. Network (F12 → Network)
3. Backend logs
4. Database records

### Debug:
```javascript
// Add to component:
console.log('Payment Status:', paymentStatus);
console.log('Bill ID:', billId);
console.log('Total:', totalCost);
```

---

## 🎉 WHEN ALL TESTS PASS

### You've Verified:
- ✅ Complete billing integration
- ✅ Payment gates working
- ✅ NO SERVICE WITHOUT PAYMENT
- ✅ All workflows functional
- ✅ Ready for production

### Next Steps:
1. Document any issues found
2. Create bug reports if needed
3. Update documentation
4. Proceed to Phase 2

---

**Estimated Total Testing Time: 2-3 hours**

**Remember:** Every service MUST require payment. If any service can be performed without payment, that's a CRITICAL BUG! 🚨
