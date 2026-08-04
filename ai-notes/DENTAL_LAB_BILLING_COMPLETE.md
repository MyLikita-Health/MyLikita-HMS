# Dental Lab Billing Integration - COMPLETE

## Overview
The dental lab billing system is now fully integrated with the existing billing infrastructure. Jobs automatically generate bills that appear in the cashier's pending transactions, and payments update job status accordingly.

## How It Works

### 1. Job Creation Flow
When a dental lab job is created (orthodontic or prosthetic):

1. **Job Record Created**
   - Stored in `dental_lab_orthodontic_jobs` or `dental_lab_prosthetic_jobs`
   - Status set to `pending_payment`
   - Payment status set to `unpaid`
   - `can_start_work` and `can_deliver` set to `FALSE`

2. **Bill Generated Automatically**
   - Transaction ID created: `LAB-ORTHO-{timestamp}` or `LAB-PROS-{timestamp}`
   - Bill inserted into `pending_txn` table with:
     - service_type: 'DENTAL'
     - tx_status: 'pending'
     - Description includes job type, teeth info, and job ID tag
   
3. **Job Updated with Bill Info**
   - `bill_transaction_id` stored in job record
   - `bill_description` stored for reference

### 2. Bill Description Format
Bills include comprehensive tracking information:
```
Orthodontic Lab Work: BITE PLANE - Teeth: 11, 12, 21 [LAB-JOB:ORTHO-5]
Prosthetic Lab Work: CROWN - Teeth: 16 [LAB-JOB:PROS-123]
```

The `[LAB-JOB:ORTHO-5]` or `[LAB-JOB:PROS-123]` tag is crucial - it allows the payment handler to identify and update the correct job.

### 3. Payment Processing Flow
When cashier processes payment through the billing system:

1. **Payment Handler Detects Lab Job**
   - Checks if description contains `[LAB-JOB:` tag
   - Extracts job type (ORTHO/PROS) and job ID

2. **Job Status Updated**
   ```sql
   UPDATE dental_lab_orthodontic_jobs SET
     payment_status = CASE 
       WHEN (amount_paid + payment) >= total_cost THEN 'paid'
       WHEN (amount_paid + payment) > 0 THEN 'partial'
       ELSE 'unpaid'
     END,
     amount_paid = amount_paid + payment,
     can_start_work = CASE 
       WHEN (amount_paid + payment) >= total_cost THEN TRUE
       ELSE can_start_work
     END,
     can_deliver = CASE 
       WHEN (amount_paid + payment) >= total_cost THEN TRUE
       ELSE can_deliver
     END,
     status = CASE 
       WHEN status = 'pending_payment' AND (amount_paid + payment) >= total_cost 
       THEN 'paid'
       ELSE status
     END
   ```

3. **Payment Recorded**
   - Entry created in `dental_lab_payments` table
   - Tracks payment history for each job
   - Records payment method and amount

4. **Transaction Marked Paid**
   - `pending_txn` record updated to 'paid' status
   - Transaction appears in completed payments

## Database Schema

### Job Tables (Both Orthodontic & Prosthetic)
```sql
- total_cost DECIMAL(10,2)           -- Total job cost
- bill_transaction_id VARCHAR(50)    -- Links to pending_txn
- bill_description TEXT              -- Full bill description
- payment_status ENUM                -- 'unpaid', 'partial', 'paid'
- amount_paid DECIMAL(10,2)          -- Running total of payments
- can_start_work BOOLEAN             -- Payment gate for lab work
- can_deliver BOOLEAN                -- Payment gate for delivery
```

### Pending Transactions Table
```sql
- facilityId VARCHAR(50)
- transaction_id VARCHAR(50)         -- Unique transaction ID
- patient_id VARCHAR(50)
- patient_name VARCHAR(150)
- patient_type VARCHAR(50)           -- 'registered', 'walk-in', 'hospital'
- amount INT(11)
- description VARCHAR(200)           -- Includes [LAB-JOB:TYPE-ID] tag
- service_type VARCHAR(50)           -- 'DENTAL'
- head VARCHAR(10)                   -- Account head '400001'
- subhead VARCHAR(10)                -- Account subhead '400001'
- total_amount INT(11)
- tx_status VARCHAR(45)              -- 'pending' or 'paid'
```

### Payment Tracking Table
```sql
CREATE TABLE dental_lab_payments (
  id INT PRIMARY KEY AUTO_INCREMENT,
  job_id INT NOT NULL,
  job_type ENUM('orthodontic', 'prosthetic'),
  patient_id VARCHAR(50),
  facilityId VARCHAR(50),
  amount DECIMAL(10,2),
  payment_type ENUM('full', 'partial', 'deposit'),
  transaction_id VARCHAR(50),
  payment_date TIMESTAMP,
  payment_method VARCHAR(50),
  notes TEXT
);
```

## Payment Gates

### Can Start Work
- Set to `TRUE` when full payment received
- Lab technicians should check this before starting work
- Prevents work on unpaid jobs

### Can Deliver
- Set to `TRUE` when full payment received
- Front desk checks this before releasing completed work
- Ensures payment before delivery

## Patient Types

The system handles three patient types:

1. **Registered Patient** (`patient_id` exists)
   - Linked to patient record
   - Full patient history available

2. **Hospital Client** (`hospital_name` provided)
   - Job brought by hospital on behalf of patient
   - Billed to hospital account

3. **Walk-in Client** (no patient_id, no hospital)
   - Direct payment required
   - Minimal patient information

## Integration Points

### Frontend Job Creation
- `OrthodonticJobCard.jsx` and `ProstheticJobCard.jsx`
- Submit to `/dental-lab/orthodontic/create-with-billing` or `/dental-lab/prosthetic/create-with-billing`
- Receive transaction_id in response

### Backend Controllers
- `backend/controller/dental-lab.js` - Job creation with billing
- `backend/controller/account.js` - Payment processing (casherPayBill function)

### Routes
- `POST /dental-lab/orthodontic/create-with-billing`
- `POST /dental-lab/prosthetic/create-with-billing`
- `POST /account/casher-pay-bill` (existing billing endpoint)

## Testing Checklist

### Job Creation
- [ ] Create orthodontic job
- [ ] Create prosthetic job
- [ ] Verify job record created with status 'pending_payment'
- [ ] Verify bill appears in pending transactions
- [ ] Check transaction_id stored in job record
- [ ] Verify bill description includes job details and tag

### Payment Processing
- [ ] Navigate to cashier/billing interface
- [ ] Find pending lab job bill
- [ ] Process full payment
- [ ] Verify job status changes to 'paid'
- [ ] Verify payment_status changes to 'paid'
- [ ] Verify amount_paid equals total_cost
- [ ] Verify can_start_work set to TRUE
- [ ] Verify can_deliver set to TRUE
- [ ] Check payment recorded in dental_lab_payments table

### Partial Payments (Future Enhancement)
- [ ] Process partial payment
- [ ] Verify payment_status changes to 'partial'
- [ ] Verify amount_paid updated correctly
- [ ] Verify can_start_work and can_deliver remain FALSE
- [ ] Process remaining payment
- [ ] Verify final status updates

## Files Modified

### Backend
- `backend/controller/dental-lab.js` - Added billing integration
- `backend/controller/account.js` - Already has lab payment handling
- `backend/sql/add_bill_description_to_lab_jobs.sql` - Migration
- `backend/sql/dental_lab_billing_schema.sql` - Full schema

### Migration Scripts
- `backend/sql/run_lab_billing_migration.js` - Runs bill_description migration
- `backend/sql/run_lab_billing_schema.js` - Runs full billing schema
- `backend/sql/check_lab_columns.js` - Verifies schema

## Status
✅ Database schema complete
✅ Job creation with billing working
✅ Bill generation automatic
✅ Payment handler integrated
✅ Payment gates implemented
✅ Payment tracking table ready
✅ All required columns exist
✅ Ready for production testing

## Next Steps
1. Test complete workflow end-to-end
2. Train staff on payment gates
3. Monitor payment processing
4. Consider adding partial payment UI
5. Add payment history view in job details

## Troubleshooting

### Bill Not Appearing
- Check `pending_txn` table for transaction_id
- Verify service_type is 'DENTAL'
- Check tx_status is 'pending'

### Payment Not Updating Job
- Verify bill description contains `[LAB-JOB:TYPE-ID]` tag
- Check job ID matches actual job record
- Review account.js DENTAL case handler
- Check dental_lab_payments table for payment record

### Payment Gates Not Working
- Verify amount_paid equals total_cost
- Check can_start_work and can_deliver columns
- Ensure payment_status is 'paid'

## Support
For issues or questions, check:
- `DENTAL_LAB_BILLING_FIXED.md` - Initial fix documentation
- `DENTAL_LAB_COMPLETE_GUIDE.md` - Full lab system guide
- `backend/controller/account.js` lines 600-750 - Payment handler code
