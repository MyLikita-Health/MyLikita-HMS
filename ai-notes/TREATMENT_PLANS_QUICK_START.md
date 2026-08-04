# Treatment Plans - Quick Start Guide

## 🚀 Getting Started in 5 Minutes

This guide will help you quickly test the new Treatment Plans system.

---

## Step 1: Database Setup (2 minutes)

Run the database migration to create the required tables:

```bash
# Navigate to backend directory
cd backend

# Run the SQL migration
mysql -u your_username -p your_database_name < sql/treatment_plans_with_billing.sql

# Or if you're already in mysql:
# source sql/treatment_plans_with_billing.sql
```

Verify tables were created:
```sql
SHOW TABLES LIKE 'dental_treatment%';
```

You should see 5 tables:
- dental_treatment_plans
- dental_treatment_plan_phases
- dental_treatment_plan_procedures
- dental_treatment_payment_schedule
- dental_treatment_payments

---

## Step 2: Access the Feature (30 seconds)

1. Start your backend server (if not running):
   ```bash
   cd backend
   npm start
   ```

2. Start your frontend (if not running):
   ```bash
   cd frontend
   npm run dev
   ```

3. Login to the system
4. Navigate to: **Dental Module** → **Select a Patient**
5. Click the **"Treatment Plans"** tab (with clipboard-list icon)

---

## Step 3: Create Your First Treatment Plan (2 minutes)

### Quick Test Plan

1. Click **"Create New Plan"** button

2. Fill in basic details:
   - **Plan Name**: "Complete Dental Restoration"
   - **Description**: "Full mouth restoration with cleaning and crown"
   - **Priority**: Select "High"

3. Add Phase 1:
   - Click **"Add Phase"**
   - **Phase Name**: "Initial Treatment"
   - **Description**: "Cleaning and examination"
   - Click **"Add Procedure"**
   - Select service: "Dental Cleaning" (or any available service)
   - Quantity: 1

4. Add Phase 2:
   - Click **"Add Phase"** again
   - **Phase Name**: "Restorative Work"
   - **Description**: "Crown placement"
   - Click **"Add Procedure"**
   - Select service: "Porcelain Crown" (or any available service)
   - Quantity: 1

5. Configure Payment:
   - **Payment Plan Type**: Select "Installments"
   - **Number of Installments**: 6

6. Review the cost breakdown on the right side

7. Click **"Create Treatment Plan"**

---

## Step 4: Patient Acceptance (1 minute)

1. Your new plan should appear in the list
2. Click on the plan card
3. Review the plan details
4. Scroll down to **Terms and Conditions**
5. Check the **"I agree"** checkbox
6. Sign in the signature box (draw with your mouse)
7. Click **"Accept & Pay Deposit"**
8. You'll be redirected to the cashier to pay the 30% deposit

---

## Step 5: Payment Management (30 seconds)

After accepting the plan:

1. Go back to the Treatment Plans tab
2. Click on your accepted plan
3. You'll see the **Payment Plan Manager**
4. View:
   - Payment summary
   - Payment schedule (if installments)
   - Payment history

5. Click **"Generate Bill"** for the next installment
6. Pay at the cashier

---

## 🎯 What to Test

### Basic Functionality
- ✅ Create a treatment plan
- ✅ View plan in list
- ✅ Filter by status (Draft, Accepted, etc.)
- ✅ Search for plans

### Patient Acceptance
- ✅ Review plan details
- ✅ Sign on canvas
- ✅ Accept plan
- ✅ Verify deposit bill is generated

### Payment Tracking
- ✅ View payment progress
- ✅ Generate installment bills
- ✅ Track payment history

---

## 📊 Sample Data for Testing

### Test Plan 1: Simple Treatment
```
Plan Name: Basic Dental Care
Priority: Normal
Payment: Full Payment
Phases: 1
- Phase 1: Cleaning and Checkup
  - Dental Cleaning (₦5,000)
  - Dental Examination (₦3,000)
Total: ₦8,000
Deposit: ₦2,400 (30%)
```

### Test Plan 2: Complex Treatment
```
Plan Name: Complete Restoration
Priority: High
Payment: 6 Monthly Installments
Phases: 3
- Phase 1: Initial Treatment (₦30,000)
  - Dental Cleaning (₦5,000)
  - Root Canal (₦25,000)
- Phase 2: Restorative Work (₦53,000)
  - Porcelain Crown (₦45,000)
  - Composite Filling (₦8,000)
- Phase 3: Final Adjustments (₦10,000)
  - Follow-up Examination (₦5,000)
  - Adjustment (₦5,000)
Total: ₦93,000
Deposit: ₦27,900 (30%)
Installment: ₦15,500/month
```

---

## 🔍 Troubleshooting

### Issue: "Cannot GET /treatment-plans/..."
**Solution**: Make sure backend server is running and routes are loaded
```bash
# Check backend logs for:
# "Treatment Plans routes loaded"
```

### Issue: "Failed to load treatment plans"
**Solution**: Verify database tables exist
```sql
SHOW TABLES LIKE 'dental_treatment%';
```

### Issue: Services not showing in dropdown
**Solution**: Make sure you have services in `service_definitions` table
```sql
SELECT * FROM service_definitions WHERE category LIKE '%dental%';
```

### Issue: Signature not saving
**Solution**: Check browser console for errors. Canvas requires mouse events.

---

## 🎨 UI Navigation

### Main Dashboard
```
Dental Module
  └─ Select Patient
      └─ Treatment Plans Tab
          ├─ Treatment Plan List (default view)
          │   ├─ Search bar
          │   ├─ Filter buttons
          │   ├─ Plan cards
          │   └─ Create New Plan button
          │
          ├─ Treatment Plan Builder (when creating)
          │   ├─ Plan details form
          │   ├─ Phases section
          │   ├─ Cost breakdown (sidebar)
          │   └─ Save/Cancel buttons
          │
          ├─ Patient Acceptance (when reviewing)
          │   ├─ Plan summary
          │   ├─ Phases breakdown
          │   ├─ Terms and conditions
          │   ├─ Signature canvas
          │   └─ Accept/Decline buttons
          │
          └─ Payment Plan Manager (after acceptance)
              ├─ Payment summary
              ├─ Payment schedule
              ├─ Payment history
              └─ Generate bill buttons
```

---

## 📱 Status Indicators

### Plan Status
- 🟦 **Draft** - Plan created but not sent to patient
- 🟨 **Pending Acceptance** - Waiting for patient to accept
- 🟩 **Accepted** - Patient accepted, deposit paid
- 🟦 **In Progress** - Treatment is ongoing
- 🟪 **Completed** - All phases complete, fully paid
- 🟥 **Cancelled** - Plan was cancelled

### Payment Status
- 🟨 **Pending** - Payment not yet made
- 🟩 **Paid** - Payment completed
- 🟥 **Overdue** - Payment past due date

### Phase Status
- 🟦 **Pending** - Phase not yet started
- 🟩 **Ready** - Payment made, ready to begin
- 🟦 **In Progress** - Phase is ongoing
- 🟪 **Completed** - Phase finished

---

## 💡 Tips for Testing

1. **Use Real Services**: Make sure your `service_definitions` table has dental services with proper pricing

2. **Test Different Payment Types**:
   - Full payment (patient pays everything upfront)
   - Installments (monthly payments)
   - Phase-by-phase (pay before each phase)

3. **Test Multiple Plans**: Create several plans for the same patient to test filtering and search

4. **Test Signature**: Try clearing and re-signing to ensure canvas works properly

5. **Test Payment Flow**: Follow through to the cashier to ensure bills are generated correctly

6. **Check Database**: After each action, verify data is saved correctly in the database

---

## 🎉 Success Indicators

You'll know everything is working when:

✅ You can create a treatment plan with multiple phases
✅ Cost calculations are accurate
✅ Patient can accept and sign the plan
✅ Deposit bill is generated automatically
✅ Payment progress is tracked correctly
✅ Installment bills can be generated
✅ Payment history is displayed
✅ Plan status updates correctly

---

## 📞 Need Help?

If you encounter issues:

1. Check browser console for JavaScript errors
2. Check backend logs for API errors
3. Verify database tables and data
4. Review the complete documentation in `TREATMENT_PLANS_INTEGRATION_COMPLETE.md`

---

**Happy Testing! 🚀**

The Treatment Plans system is designed to streamline complex dental treatments with flexible payment options. Enjoy exploring the features!
