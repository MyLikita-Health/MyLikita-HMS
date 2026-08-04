# Radiology Detailed Billing Update

## Changes Made

Updated the radiology integrated workflow to create individual line items in `pending_txn` for each procedure, providing detailed receipts at the cashier.

## Key Modifications

### 1. Individual Pending Transaction Entries

**Before**: Single `pending_txn` entry with combined description
```
Radiology: Chest X-Ray, Abdominal Ultrasound - ₦35,000
```

**After**: Separate `pending_txn` entry for each procedure
```
Radiology: Chest X-Ray - ₦15,000
Radiology: Abdominal Ultrasound - ₦20,000
```

### 2. Patient Name Inclusion

**For New Patients**: Uses name from `patientData`
```javascript
patientName = `${patientData.surname} ${patientData.firstname}`.trim();
```

**For Existing Patients**: Fetches name from database
```javascript
const [patientInfo] = await db.sequelize.query(
  'SELECT surname, firstname, middlename FROM patientrecords WHERE id = ?',
  { replacements: [finalPatientId] }
);
patientName = `${patientInfo[0].surname} ${patientInfo[0].firstname}`.trim();
```

### 3. Updated Workflow

```
For each procedure:
  1. Create radiology_request
  2. Create radiology_billing
  3. Create pending_txn (individual entry)
  4. Link billing to pending_txn
```

## Benefits

1. **Detailed Receipts**: Cashier can see each procedure as a separate line item
2. **Better Tracking**: Individual transactions for each procedure
3. **Accurate Reporting**: Revenue reports show procedure-level detail
4. **Patient Clarity**: Patients see itemized billing
5. **Audit Trail**: Each procedure has its own transaction ID

## Database Impact

### pending_txn Table
- **Before**: 1 row for multiple procedures
- **After**: N rows (one per procedure)

### Example: 3 Procedures

**Before**:
| transaction_id | description | amount | patient_name |
|---|---|---|---|
| uuid-1 | Radiology: Proc1, Proc2, Proc3 | 50000 | John Doe |

**After**:
| transaction_id | description | amount | patient_name |
|---|---|---|---|
| uuid-1 | Radiology: Proc1 | 15000 | John Doe |
| uuid-2 | Radiology: Proc2 | 20000 | John Doe |
| uuid-3 | Radiology: Proc3 | 15000 | John Doe |

## Response Structure

Updated API response includes:
```javascript
{
  success: true,
  data: {
    patient_id: "7-1",
    patient_name: "John Doe",
    request_ids: ["req-1", "req-2", "req-3"],
    billing_ids: ["bill-1", "bill-2", "bill-3"],
    pending_txn_ids: ["txn-1", "txn-2", "txn-3"],
    total_amount: 50000,
    procedure_count: 3
  },
  message: "3 request(s) created successfully with billing"
}
```

## Payment Processing

The `onPaymentComplete` function in `radiology-billing.js` already handles individual pending_txn entries correctly:
- Finds billing by `pending_txn_id`
- Creates appointment for that specific procedure
- Updates billing status to 'paid'
- Updates request status to 'scheduled'

## Testing

### Test Case: Multiple Procedures

1. Create request with 3 procedures
2. Verify 3 entries in `pending_txn` table
3. Check cashier view shows 3 line items
4. Process payment for all items
5. Verify 3 appointments created
6. Confirm all billing records updated

### SQL Verification

```sql
-- Check pending transactions
SELECT transaction_id, description, amount, patient_name
FROM pending_txn
WHERE patient_id = '7-1' AND tx_status = 'pending'
ORDER BY transaction_date DESC;

-- Check billing linkage
SELECT b.id, b.pending_txn_id, r.request_number, pr.procedure_name
FROM radiology_billing b
JOIN radiology_requests r ON b.request_id = r.id
JOIN radiology_procedures pr ON r.procedure_id = pr.id
WHERE b.patient_id = '7-1';
```

## Files Modified

- `backend/controller/radiology-requests.js`
  - Modified `createRequestWithBilling` function
  - Added patient name fetching for existing patients
  - Changed from single to multiple pending_txn entries
  - Updated response structure

## Backward Compatibility

✅ Fully compatible with existing code:
- `onPaymentComplete` already handles individual entries
- Account module processes each pending_txn separately
- No changes needed to frontend (already handles response correctly)

## Status

✅ **COMPLETE** - Individual line items now created for detailed billing receipts.
