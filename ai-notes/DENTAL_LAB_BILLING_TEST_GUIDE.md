# Dental Lab Billing - Testing Guide

## Overview
Complete testing guide for the dental lab billing integration system.

## Prerequisites

1. **Database Setup**
```bash
# Run the billing schema migration
mysql -u root -p dental_db < backend/sql/dental_lab_billing_schema.sql
```

2. **Verify Tables**
```sql
-- Check orthodontic jobs table
DESCRIBE dental_lab_orthodontic_jobs;

-- Check prosthetic jobs table
DESCRIBE dental_lab_prosthetic_jobs;

-- Check pricing table
SELECT COUNT(*) FROM dental_lab_pricing;
-- Should return 55 rows (25 orthodontic + 30 prosthetic)

-- Check payments table
DESCRIBE dental_lab_payments;
```

3. **Backend Server**
```bash
cd backend
npm start
# Server should be running on port 5000
```

4. **Frontend Server**
```bash
cd frontend
npm run dev
# Frontend should be running on port 5173
```

## Test Scenarios

### Scenario 1: Create Orthodontic Job with Billing

**Steps:**
1. Navigate to Dental Module → Lab Section
2. Click "New Orthodontic Job"
3. Fill in patient information
4. Fill in doctor information (required)
5. Set due date (required)
6. Select components:
   - Hawley Retainer - Upper (₦15,000)
   - Labial Bow (₦3,000)
   - Adams Clasps (2) (₦4,000)
7. Verify cost calculator shows:
   - Subtotal: ₦22,000
   - Total: ₦22,000
8. Click "Create Job & Generate Bill"

**Expected Results:**
- Job created successfully
- Job card number generated (e.g., ORTHO-1709876543210)
- Bill data returned with transaction ID
- Job status: `pending_payment`
- Payment status: `unpaid`
- `can_start_work`: FALSE
- `can_deliver`: FALSE

**API Endpoint:**
```
POST /dental-lab/orthodontic/create-with-billing
```

**Request Body:**
```json
{
  "patient_id": "PAT123",
  "patient_name": "John Doe",
  "facilityId": "FAC001",
  "doctor_name": "Dr. Smith",
  "doctor_id": "DOC001",
  "due_date": "2026-03-12",
  "selectedComponents": [
    "hawley_retainer_upper",
    "labial_bow",
    "adams_clasp_2"
  ],
  "total_cost": 22000,
  "created_by": "USER001"
}
```

**Response:**
```json
{
  "success": true,
  "jobId": 1,
  "job_card_no": "ORTHO-1709876543210",
  "transaction_id": "LAB-ORTHO-1709876543210",
  "billData": {
    "description": "Orthodontic Lab Work: Hawley Retainer - Upper, Labial Bow, Adams Clasps (2) [LAB-JOB:ORTHO-1]",
    "head": "DENTAL-LAB",
    "subhead": "ORTHODONTIC",
    "amount": 22000,
    "service_type": "DENTAL"
  },
  "message": "Orthodontic job created. Please generate bill at cashier."
}
```

### Scenario 2: Process Lab Job Payment

**Steps:**
1. Go to Cashier/Billing Module
2. Search for pending transactions
3. Find the lab job bill: "Orthodontic Lab Work [LAB-JOB:ORTHO-1]"
4. Process payment:
   - Amount: ₦22,000
   - Payment method: Cash/POS/Bank
5. Complete payment

**Expected Results:**
- Payment recorded in `service_transaction`
- Job payment status updated to `paid`
- `amount_paid` = 22000
- `can_start_work` = TRUE
- `can_deliver` = TRUE
- Job status changed from `pending_payment` to `paid`
- Payment recorded in `dental_lab_payments` table

**Database Verification:**
```sql
-- Check job status
SELECT job_card_no, payment_status, amount_paid, total_cost, 
       can_start_work, can_deliver, status
FROM dental_lab_orthodontic_jobs
WHERE id = 1;

-- Check payment record
SELECT * FROM dental_lab_payments
WHERE job_id = 1 AND job_type = 'orthodontic';
```

### Scenario 3: Update Job Status with Payment Gates

**Steps:**
1. Lab technician tries to start work on unpaid job
2. System should block with error
3. After payment, lab can start work
4. Update status to `in_progress`
5. Complete work → status `completed`
6. Deliver to patient → status `delivered`

**API Endpoint:**
```
PUT /dental-lab/orthodontic/status-with-gates/1
```

**Request (Before Payment):**
```json
{
  "status": "in_progress",
  "updated_by": "TECH001"
}
```

**Response (Before Payment):**
```json
{
  "success": false,
  "message": "Payment required before lab can start work"
}
```

**Request (After Payment):**
```json
{
  "status": "in_progress",
  "updated_by": "TECH001"
}
```

**Response (After Payment):**
```json
{
  "success": true,
  "message": "Status updated successfully"
}
```

### Scenario 4: Create Prosthetic Job with Billing

**Steps:**
1. Navigate to Dental Module → Lab Section
2. Click "New Prosthetic Job"
3. Fill in patient and doctor information
4. Set due date
5. Fill in shade information:
   - Tooth Shade: A2
   - Tooth Mould No: 23
   - Shade Guide: Vita Classical
6. Select components:
   - PFM Crown (single) (₦25,000)
   - PFM Crown (single) (₦25,000)
   - Temporary Crown (₦5,000)
7. Verify cost: ₦55,000
8. Create job

**Expected Results:**
- Job created with job card number (e.g., PROS-1709876543210)
- Bill generated with [LAB-JOB:PROS-1]
- Status: `pending_payment`

### Scenario 5: Partial Payment

**Steps:**
1. Create job with total cost ₦50,000
2. Process partial payment of ₦25,000
3. Check job status

**Expected Results:**
- `payment_status`: `partial`
- `amount_paid`: 25000
- `can_start_work`: FALSE (requires full payment)
- `can_deliver`: FALSE
- Job status remains `pending_payment`

**Process remaining payment:**
4. Process second payment of ₦25,000

**Expected Results:**
- `payment_status`: `paid`
- `amount_paid`: 50000
- `can_start_work`: TRUE
- `can_deliver`: TRUE
- Job status: `paid`

### Scenario 6: Get All Jobs with Payment Status

**API Endpoint:**
```
GET /dental-lab/jobs/FAC001/all?jobType=orthodontic
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "job_card_no": "ORTHO-1709876543210",
      "patient_name": "John Doe",
      "doctor_name": "Dr. Smith",
      "date_received": "2026-03-05",
      "due_date": "2026-03-12",
      "total_cost": 22000,
      "amount_paid": 22000,
      "payment_status": "paid",
      "status": "in_progress",
      "can_start_work": true,
      "can_deliver": true
    }
  ]
}
```

## Payment Detection Logic

The system detects lab job payments by looking for the pattern `[LAB-JOB:ORTHO-xxx]` or `[LAB-JOB:PROS-xxx]` in the bill description.

**Location:** `backend/controller/account.js` (line ~665)

**Logic:**
```javascript
// Check if this is a lab job payment
if (item.description && item.description.includes('[LAB-JOB:')) {
  const jobMatch = item.description.match(/\[LAB-JOB:(ORTHO|PROS)-(\d+)\]/);
  if (jobMatch && jobMatch[2]) {
    const jobType = jobMatch[1] === 'ORTHO' ? 'orthodontic' : 'prosthetic';
    const jobId = jobMatch[2];
    
    // Update job payment status
    // Update payment gates
    // Record payment in dental_lab_payments
  }
}
```

## Common Issues & Solutions

### Issue 1: Pricing Not Loading
**Symptom:** Cost calculator shows "Loading pricing..." indefinitely

**Solution:**
```sql
-- Verify pricing data exists
SELECT COUNT(*) FROM dental_lab_pricing;

-- If empty, run the schema script again
SOURCE backend/sql/dental_lab_billing_schema.sql;
```

### Issue 2: Payment Not Updating Job Status
**Symptom:** Payment processed but job status remains `unpaid`

**Solution:**
1. Check bill description includes correct identifier:
   - Should be: `[LAB-JOB:ORTHO-1]` or `[LAB-JOB:PROS-1]`
2. Check account.js payment detection logic is active
3. Verify database triggers are working

### Issue 3: Cannot Start Work After Payment
**Symptom:** `can_start_work` remains FALSE after payment

**Solution:**
```sql
-- Manually update if needed
UPDATE dental_lab_orthodontic_jobs
SET can_start_work = TRUE, can_deliver = TRUE
WHERE id = 1 AND payment_status = 'paid';
```

## API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/dental/lab/pricing/:jobType` | Get pricing for orthodontic/prosthetic |
| POST | `/dental-lab/orthodontic/create-with-billing` | Create orthodontic job with billing |
| POST | `/dental-lab/prosthetic/create-with-billing` | Create prosthetic job with billing |
| GET | `/dental-lab/:jobType/:jobId/payment-status` | Check payment status |
| GET | `/dental-lab/:jobType/:jobId/details` | Get job details |
| PUT | `/dental-lab/:jobType/:jobId/status-with-gates` | Update status with payment gate checks |
| GET | `/dental-lab/jobs/:facilityId/all` | Get all jobs with payment status |

## Success Criteria

✅ Job creation generates bill automatically
✅ Payment detection updates job status
✅ Payment gates prevent unauthorized status changes
✅ Cost calculator shows accurate pricing
✅ Partial payments tracked correctly
✅ Full payment enables work and delivery
✅ Payment history recorded in dental_lab_payments

## Next Steps

After successful testing:
1. Create JobWorkflow component for status visualization
2. Create TechnicianAssignment component
3. Create JobCardPrint component for printing
4. Add job search and filtering
5. Add reporting and analytics
6. Implement notifications for due dates
7. Add inventory integration for materials tracking

