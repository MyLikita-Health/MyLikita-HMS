# PRESCRIPTION WORKFLOW - IMPLEMENTATION PLAN

**Date:** March 4, 2026  
**Status:** Planning Phase

---

## 🎯 CORRECT WORKFLOW UNDERSTANDING

### Current (Incorrect) Flow
```
Dentist → Create Prescription → Generate Bill → Patient Pays → Dispense
```

### Correct Flow
```
1. Dentist → Create Prescription (NO BILLING YET)
2. Prescription saved with status: 'pending_billing'
3. Patient goes to Oral Care Shop
4. Shop Staff → View Pending Prescriptions
5. Shop Staff → Match prescribed items with inventory
   - If item exists → Auto-match
   - If item doesn't exist → Replace with similar item
6. Shop Staff → Generate Bill (with actual inventory prices)
7. Patient → Pay at Cashier
8. Patient → Return to Shop with receipt
9. Shop Staff → Verify payment → Dispense items
10. Prescription status → 'completed'
```

---

## 📋 REQUIRED CHANGES

### 1. REMOVE BILLING FROM PRESCRIPTION FORM ✅

**File:** `frontend/src/components/dental/prescriptions/PrescriptionForm.jsx`

**Changes:**
- Remove Step 2 (Billing step)
- Remove `PrescriptionBilling` component import and usage
- Change to single-step form
- After saving prescription, show success message and close
- Remove `handleBillingComplete` and `handleSkipBilling` functions

**New Flow:**
```javascript
// Single step - just save prescription
const savePrescription = async () => {
  // Save prescription with status: 'pending_billing'
  // Show success: "Prescription created. Patient should go to Oral Care Shop."
  // Close modal
};
```

---

### 2. CREATE ORAL CARE SHOP MODULE 🆕

**Location:** `frontend/src/components/oral-care-shop/`

**Components to Create:**

#### A. PendingPrescriptions.jsx
- Display list of all prescriptions with status 'pending_billing'
- Filter by patient name, prescription ID, date
- Show prescription details (patient, dentist, date, medications)
- "Process" button to open billing modal

#### B. PrescriptionBilling.jsx (NEW - Different from dental version)
- Display prescribed medications
- For each medication:
  - Search inventory for matching item
  - If found: Auto-select with inventory price
  - If not found: Show "Not in stock" → Allow replacement
- Replacement functionality:
  - Search inventory for similar items
  - Select replacement item
  - Add note about replacement
- Calculate total cost
- Generate bill button
- After bill generated: Show "Send patient to cashier"

#### C. PrescriptionDispensing.jsx
- Display prescriptions with status 'billed' or 'paid'
- Verify payment status
- If paid: Allow dispensing
- If not paid: Show "Payment required"
- Mark items as dispensed
- Update prescription status to 'completed'
- Print dispensing receipt

---

### 3. UPDATE PRESCRIPTION TABLE STRUCTURE 🔧

**File:** `backend/sql/update_dental_prescriptions_table.sql`

**Add Columns:**
```sql
-- Billing status tracking
ALTER TABLE dental_prescriptions 
ADD COLUMN IF NOT EXISTS `billing_status` VARCHAR(50) DEFAULT 'pending_billing' 
COMMENT 'pending_billing, billed, paid, dispensed';

-- Inventory matching
ALTER TABLE dental_prescriptions 
ADD COLUMN IF NOT EXISTS `inventory_item_id` INT(11) NULL 
COMMENT 'Matched inventory item ID';

ALTER TABLE dental_prescriptions 
ADD COLUMN IF NOT EXISTS `is_replaced` BOOLEAN DEFAULT FALSE 
COMMENT 'TRUE if prescribed item was replaced';

ALTER TABLE dental_prescriptions 
ADD COLUMN IF NOT EXISTS `replacement_notes` TEXT 
COMMENT 'Notes about item replacement';

-- Pricing
ALTER TABLE dental_prescriptions 
ADD COLUMN IF NOT EXISTS `unit_price` DECIMAL(10,2) DEFAULT 0 
COMMENT 'Actual price from inventory';

ALTER TABLE dental_prescriptions 
ADD COLUMN IF NOT EXISTS `total_price` DECIMAL(10,2) DEFAULT 0 
COMMENT 'unit_price * quantity';

-- Billing reference
ALTER TABLE dental_prescriptions 
ADD COLUMN IF NOT EXISTS `transaction_id` VARCHAR(100) NULL 
COMMENT 'Reference to pending_txn transaction';

-- Dispensing tracking
ALTER TABLE dental_prescriptions 
ADD COLUMN IF NOT EXISTS `dispensed_by` VARCHAR(50) NULL;

ALTER TABLE dental_prescriptions 
ADD COLUMN IF NOT EXISTS `dispensed_at` DATETIME NULL;

ALTER TABLE dental_prescriptions 
ADD COLUMN IF NOT EXISTS `payment_verified_by` VARCHAR(50) NULL;

ALTER TABLE dental_prescriptions 
ADD COLUMN IF NOT EXISTS `payment_verified_at` DATETIME NULL;
```

---

### 4. UPDATE BACKEND ROUTES 🔧

**File:** `backend/routes/dental.js`

**Add Routes:**
```javascript
// Oral Care Shop routes
app.get('/oral-care-shop/prescriptions/pending/:facilityId', dental.getPendingPrescriptions);
app.get('/oral-care-shop/prescriptions/billed/:facilityId', dental.getBilledPrescriptions);
app.put('/oral-care-shop/prescriptions/:prescriptionId/match-inventory', dental.matchInventory);
app.post('/oral-care-shop/prescriptions/:prescriptionId/generate-bill', dental.generatePrescriptionBill);
app.put('/oral-care-shop/prescriptions/:prescriptionId/verify-payment', dental.verifyPrescriptionPayment);
app.put('/oral-care-shop/prescriptions/:prescriptionId/dispense', dental.dispensePrescription);
```

---

### 5. CREATE BACKEND CONTROLLERS 🆕

**File:** `backend/controller/dental.js`

**Add Functions:**

#### A. getPendingPrescriptions
```javascript
exports.getPendingPrescriptions = async (req, res) => {
  const { facilityId } = req.params;
  
  const stmt = `
    SELECT 
      dp.*,
      pr.firstname, pr.surname, pr.phoneNo,
      u.firstname as dentist_firstname, u.lastname as dentist_lastname
    FROM dental_prescriptions dp
    LEFT JOIN patientrecords pr ON dp.patient_id = pr.patient_id
    LEFT JOIN users u ON dp.prescribed_by = u.id
    WHERE dp.facilityId = :facilityId 
      AND dp.billing_status = 'pending_billing'
    ORDER BY dp.prescribed_date DESC
  `;
  
  // Execute query and return results
};
```

#### B. matchInventory
```javascript
exports.matchInventory = async (req, res) => {
  const { prescriptionId } = req.params;
  const { inventory_item_id, is_replaced, replacement_notes, unit_price } = req.body;
  
  const stmt = `
    UPDATE dental_prescriptions 
    SET 
      inventory_item_id = :inventory_item_id,
      is_replaced = :is_replaced,
      replacement_notes = :replacement_notes,
      unit_price = :unit_price,
      total_price = unit_price * quantity
    WHERE prescription_id = :prescriptionId
  `;
  
  // Execute update
};
```

#### C. generatePrescriptionBill
```javascript
exports.generatePrescriptionBill = async (req, res) => {
  const { prescriptionId } = req.params;
  
  // 1. Get all medications for this prescription
  // 2. Calculate total
  // 3. Generate bill using /payment/request
  // 4. Update prescription billing_status to 'billed'
  // 5. Store transaction_id
};
```

#### D. verifyPrescriptionPayment
```javascript
exports.verifyPrescriptionPayment = async (req, res) => {
  const { prescriptionId } = req.params;
  const { verified_by } = req.body;
  
  // 1. Get transaction_id from prescription
  // 2. Check payment status in pending_txn
  // 3. If paid, update billing_status to 'paid'
  // 4. Record who verified and when
};
```

#### E. dispensePrescription
```javascript
exports.dispensePrescription = async (req, res) => {
  const { prescriptionId } = req.params;
  const { dispensed_by } = req.body;
  
  // 1. Verify payment status is 'paid'
  // 2. Update billing_status to 'dispensed'
  // 3. Record who dispensed and when
  // 4. Update inventory (reduce stock)
};
```

---

### 6. UPDATE NAVIGATION 🔧

**File:** `frontend/src/components/nav/nav-modules.jsx`

**Add Oral Care Shop Module:**
```javascript
{
  name: 'Oral Care Shop',
  icon: 'fa-shopping-bag',
  path: '/me/oral-care-shop',
  subItems: [
    { name: 'Pending Prescriptions', path: '/me/oral-care-shop/pending' },
    { name: 'Billed Prescriptions', path: '/me/oral-care-shop/billed' },
    { name: 'Dispensing', path: '/me/oral-care-shop/dispensing' },
    { name: 'Inventory', path: '/me/oral-care-shop/inventory' }
  ]
}
```

---

### 7. INVENTORY INTEGRATION 🔧

**Existing Inventory System:**
- Table: `drugs` or `inventory`
- Fields: `id`, `drug_name`, `selling_price`, `quantity_in_stock`, etc.

**Integration Points:**
- Search inventory by drug name
- Get item details (price, stock)
- Update stock after dispensing
- Track inventory movements

---

## 📊 PRESCRIPTION STATUS FLOW

```
pending_billing → billed → paid → dispensed
     ↓              ↓         ↓        ↓
  Created      Bill Gen   Payment  Dispensed
  by Dentist   at Shop    at Cash  at Shop
```

---

## 🎨 UI MOCKUPS

### Dentist View (Simplified)
```
┌─────────────────────────────────────┐
│ Create Prescription                  │
├─────────────────────────────────────┤
│ [Drug Selection Table]               │
│ - Amoxicillin 500mg | TDS | 7 days  │
│ - Ibuprofen 400mg   | TDS | 5 days  │
│                                      │
│ [+ Add Medication]                   │
│                                      │
│ Notes: _________________________    │
│                                      │
│ [Cancel] [Save Prescription]         │
└─────────────────────────────────────┘

Success Message:
"Prescription created successfully!
Patient should go to Oral Care Shop for billing."
```

### Oral Care Shop - Pending Prescriptions
```
┌─────────────────────────────────────────────────────┐
│ Pending Prescriptions                                │
├─────────────────────────────────────────────────────┤
│ Search: [_____________] [Filter by Date ▼]          │
│                                                      │
│ ┌──────────────────────────────────────────────┐   │
│ │ RX-123456 | John Doe | Dr. Smith | 04/03/26 │   │
│ │ 2 medications                                 │   │
│ │ [Process Prescription]                        │   │
│ └──────────────────────────────────────────────┘   │
│                                                      │
│ ┌──────────────────────────────────────────────┐   │
│ │ RX-123457 | Jane Smith | Dr. Jones | 04/03/26│   │
│ │ 3 medications                                 │   │
│ │ [Process Prescription]                        │   │
│ └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Oral Care Shop - Process Prescription
```
┌─────────────────────────────────────────────────────┐
│ Process Prescription - RX-123456                     │
│ Patient: John Doe | Prescribed by: Dr. Smith        │
├─────────────────────────────────────────────────────┤
│                                                      │
│ Prescribed Medications:                              │
│                                                      │
│ 1. Amoxicillin 500mg - TDS - 7 days (Qty: 21)      │
│    Inventory Match: [Amoxicillin 500mg Caps ▼]     │
│    ✓ In Stock | Price: ₦50/unit | Total: ₦1,050   │
│    [ ] Replace with different item                  │
│                                                      │
│ 2. Ibuprofen 400mg - TDS - 5 days (Qty: 15)        │
│    Inventory Match: [Not found in inventory]        │
│    ⚠ Not in stock                                   │
│    [Search Replacement ▼]                           │
│    → Selected: Ibuprofen 600mg (₦30/unit)          │
│    Note: Using 600mg instead of 400mg               │
│    Total: ₦450                                      │
│                                                      │
│ ─────────────────────────────────────────────────  │
│ Total Amount: ₦1,500                                │
│                                                      │
│ [Cancel] [Generate Bill]                            │
└─────────────────────────────────────────────────────┘

After Generate Bill:
"Bill generated successfully!
Transaction ID: RX-1772617250317
Send patient to cashier for payment."
```

### Oral Care Shop - Dispensing
```
┌─────────────────────────────────────────────────────┐
│ Dispensing - RX-123456                               │
│ Patient: John Doe                                    │
├─────────────────────────────────────────────────────┤
│                                                      │
│ Payment Status: ✓ PAID (₦1,500)                    │
│ Receipt No: RX-1772617250317                        │
│                                                      │
│ Items to Dispense:                                   │
│ ☐ Amoxicillin 500mg Caps × 21                      │
│ ☐ Ibuprofen 600mg Tabs × 15                        │
│                                                      │
│ [Verify All Items] [Dispense & Print Receipt]       │
└─────────────────────────────────────────────────────┘
```

---

## 🔄 IMPLEMENTATION STEPS

### Phase 1: Remove Billing from Prescription Form (30 mins)
1. Update `PrescriptionForm.jsx`
2. Remove billing step
3. Change success message
4. Test prescription creation

### Phase 2: Update Database (15 mins)
1. Run `update_dental_prescriptions_table.sql`
2. Verify new columns exist
3. Test prescription saving with new fields

### Phase 3: Create Backend Routes & Controllers (2 hours)
1. Add routes to `backend/routes/dental.js`
2. Implement controller functions in `backend/controller/dental.js`
3. Test each endpoint with Postman

### Phase 4: Create Oral Care Shop UI (4 hours)
1. Create folder structure
2. Build PendingPrescriptions component
3. Build PrescriptionBilling component (shop version)
4. Build PrescriptionDispensing component
5. Add navigation

### Phase 5: Integration & Testing (2 hours)
1. Test complete workflow end-to-end
2. Test inventory matching
3. Test replacement flow
4. Test payment verification
5. Test dispensing

**Total Estimated Time: 8-9 hours**

---

## ✅ ACCEPTANCE CRITERIA

### Dentist Side
- [ ] Can create prescription without billing
- [ ] Prescription saves with status 'pending_billing'
- [ ] Success message directs patient to shop
- [ ] No billing component shown

### Oral Care Shop Side
- [ ] Can view all pending prescriptions
- [ ] Can match prescribed items with inventory
- [ ] Can replace items not in stock
- [ ] Can generate bill with actual prices
- [ ] Bill goes to pending_txn table
- [ ] Can verify payment status
- [ ] Can dispense only after payment verified
- [ ] Inventory updates after dispensing

### Patient Experience
- [ ] Clear instructions at each step
- [ ] Knows where to go for payment
- [ ] Knows where to return for pickup
- [ ] Receives dispensing receipt

---

## 🚨 CRITICAL NOTES

1. **No Billing at Prescription Creation** - This is the key change
2. **Inventory Matching is Manual** - Shop staff must match/replace items
3. **Payment Happens at Cashier** - Not at shop
4. **Dispensing Requires Payment Verification** - Payment gate
5. **Inventory Updates** - Stock reduces after dispensing, not after billing

---

## 📝 FILES TO MODIFY

### Frontend
- ✅ `frontend/src/components/dental/prescriptions/PrescriptionForm.jsx` - Remove billing
- 🆕 `frontend/src/components/oral-care-shop/PendingPrescriptions.jsx` - New
- 🆕 `frontend/src/components/oral-care-shop/PrescriptionBilling.jsx` - New
- 🆕 `frontend/src/components/oral-care-shop/PrescriptionDispensing.jsx` - New
- 🆕 `frontend/src/components/oral-care-shop/OralCareShopDashboard.jsx` - New
- ✅ `frontend/src/components/nav/nav-modules.jsx` - Add navigation

### Backend
- ✅ `backend/routes/dental.js` - Add shop routes
- ✅ `backend/controller/dental.js` - Add shop controllers
- ✅ `backend/sql/update_dental_prescriptions_table.sql` - Update table

---

## 🎯 NEXT STEPS

**Immediate:**
1. Confirm this plan matches your requirements
2. Prioritize which phase to start with
3. Decide if we implement all at once or incrementally

**Questions to Clarify:**
1. Should we keep the old PrescriptionBilling component or delete it?
2. Do you want inventory management in the shop module?
3. Should shop staff be able to edit quantities?
4. What happens if patient doesn't pick up prescription?

---

**Status:** AWAITING APPROVAL TO PROCEED

**Last Updated:** March 4, 2026
