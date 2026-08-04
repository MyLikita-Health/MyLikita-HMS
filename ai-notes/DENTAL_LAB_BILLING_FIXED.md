# Dental Lab Billing Integration - FIXED

## Issue Summary
When creating dental lab jobs (orthodontic or prosthetic), the system was attempting to insert billing records into a non-existent `bills` table, causing a database error:
```
Table 'prime.bills' doesn't exist
```

## Root Cause
The dental lab controller was trying to use a `bills` table that doesn't exist in the database. The existing billing system uses the `pending_txn` table instead.

## Solution Implemented

### 1. Database Migration
- Added `bill_description` column to both job tables:
  - `dental_lab_orthodontic_jobs`
  - `dental_lab_prosthetic_jobs`
- Migration file: `backend/sql/add_bill_description_to_lab_jobs.sql`
- Migration script: `backend/sql/run_lab_billing_migration.js`

### 2. Controller Updates
Updated both `createOrthodonticJobWithBilling` and `createProstheticJobWithBilling` functions in `backend/controller/dental-lab.js`:

#### Changes Made:
1. **Removed duplicate variable declarations** - Fixed code that was declaring `transaction_id`, `itemsDesc`, and `teethInfo` twice
2. **Integrated with existing billing system** - Now inserts into `pending_txn` table instead of non-existent `bills` table
3. **Proper field mapping** - Uses correct field names from `pending_txn` table:
   - `facilityId`
   - `transaction_id`
   - `patient_id`
   - `patient_name`
   - `amount`
   - `description`
   - `service_type` (set to 'DENTAL')
   - `head` (set to '400001')
   - `subhead` (set to '400001')
   - `total_amount`
   - `tx_status` (set to 'pending')

4. **Enhanced job tracking** - Stores both `bill_transaction_id` and `bill_description` in job records
5. **Better error handling** - Handles cases where patient_id might be 0 (for hospital/walk-in clients)

### 3. Bill Description Format
Bills now include comprehensive information:
```
Orthodontic Lab Work: BITE PLANE - Teeth: 11, 12, 21 [LAB-JOB:ORTHO-123]
```
or
```
Prosthetic Lab Work: CROWN - Teeth: 16 [LAB-JOB:PROS-456]
```

The `[LAB-JOB:ORTHO-123]` tag allows the billing system to track which job the payment is for.

## How It Works Now

### Job Creation Flow:
1. User creates a lab job through the frontend
2. Backend creates job record in appropriate table (orthodontic or prosthetic)
3. Backend generates unique transaction ID (e.g., `LAB-ORTHO-1772769522823`)
4. Backend inserts billing record into `pending_txn` table with status 'pending'
5. Backend updates job record with transaction ID and bill description
6. Frontend receives success response with transaction ID

### Payment Flow:
1. Cashier views pending bills (from `pending_txn` table)
2. Cashier processes payment using existing billing system
3. Payment handler in `account.js` updates job payment status
4. Job status changes from 'pending_payment' to 'paid'
5. Lab can now start work on the job

## Integration with Existing Billing System
The dental lab billing now properly integrates with the existing `casherPayBill` function in `backend/controller/account.js`, which already handles:
- Recording transactions
- Updating payment status
- Updating job payment fields
- Recording payment history

## Testing
To test the fix:
1. Create a new orthodontic or prosthetic job
2. Verify job is created successfully
3. Check that bill appears in pending transactions
4. Process payment through cashier interface
5. Verify job status updates to 'paid'

## Files Modified
- `backend/controller/dental-lab.js` - Fixed billing integration
- `backend/sql/add_bill_description_to_lab_jobs.sql` - Database migration
- `backend/sql/run_lab_billing_migration.js` - Migration runner script

## Status
✅ Database migration completed
✅ Controller updated with no duplicates
✅ No syntax errors
✅ Integrated with existing billing system (pending_txn table)
✅ Ready for testing

## Next Steps
1. **Restart backend server** to load updated controller:
   ```bash
   cd backend
   npm restart
   # or
   pm2 restart backend
   ```

2. **Test job creation**:
   - Create a new orthodontic job
   - Create a new prosthetic job
   - Verify jobs are created successfully
   - Check that bills appear in pending transactions

3. **Test payment processing**:
   - Go to cashier/billing interface
   - Find the pending lab job bills
   - Process payment
   - Verify job status updates to 'paid'

4. **Verify integration**:
   - Check that transaction IDs are stored in job records
   - Verify bill descriptions include job details and teeth information
   - Confirm payment updates job payment status

## Important Notes
- The system now uses `pending_txn` table (not `bills` table)
- Transaction IDs follow format: `LAB-ORTHO-{timestamp}` or `LAB-PROS-{timestamp}`
- Bill descriptions include job type, teeth info, and job ID for tracking
- Patient ID can be 0 for hospital/walk-in clients
- Service type is set to 'DENTAL' for proper categorization
