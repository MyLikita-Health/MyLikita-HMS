# Radiology Payment Timeout Fix

## Issue
Payment processing at cashier was timing out when paying for radiology services. The server log showed:
```
Payment Request: {patient_id: '8-1',modeOfPayment: 'CASH',amount: 116000,status: 'paid'}
```
But the request kept loading until timeout with no response.

## Root Cause
The payment trigger in `backend/controller/account.js` (around line 1116-1130) had two issues:

1. **Wrong parameter**: It was checking for `item.service_id` which doesn't exist in the pending_txn table
2. **Wrong parameter passed**: It was calling `onPaymentComplete(item.service_id, facilityId)` instead of using `transaction_id`

## Files Modified

### 1. backend/controller/account.js (Line ~1116-1133)

**Before:**
```javascript
// Trigger radiology appointment creation if payment is for radiology services
if (!isBillMode) {
  for (const item of txArr) {
    if (item.service_type === 'radiology' && item.service_id) {  // ❌ Wrong field
      try {
        const radiologyBilling = require('./radiology-billing');
        const appointmentResult = await radiologyBilling.onPaymentComplete(item.service_id, facilityId);  // ❌ Wrong parameter
        console.log('[Account] Radiology appointment creation result:', appointmentResult);
      } catch (error) {
        console.error('[Account] Error creating radiology appointments:', error);
      }
    }
  }
}
```

**After:**
```javascript
// Trigger radiology appointment creation if payment is for radiology services
if (!isBillMode) {
  for (const item of txArr) {
    console.log('[Account] Checking item:', item.service_type, item.transaction_id);
    if (item.service_type === 'radiology' && item.transaction_id) {  // ✅ Correct field
      try {
        console.log('[Account] Triggering radiology appointment creation for transaction:', item.transaction_id);
        const radiologyBilling = require('./radiology-billing');
        const appointmentResult = await radiologyBilling.onPaymentComplete(item.transaction_id, facilityId);  // ✅ Correct parameter
        console.log('[Account] Radiology appointment creation result:', appointmentResult);
      } catch (error) {
        console.error('[Account] Error creating radiology appointments:', error);
      }
    }
  }
}
```

### 2. backend/controller/radiology-billing.js

**Updated `onPaymentComplete` function:**
- Changed parameter name from `pendingTxnId` to `transactionId` for clarity
- Added comprehensive logging to track execution flow
- Added final success log after all appointments created

**Key changes:**
```javascript
exports.onPaymentComplete = async (transactionId, facilityId) => {  // ✅ Renamed parameter
  try {
    console.log(`[Radiology] Payment completed for transaction_id: ${transactionId}`);
    
    // Find all billing records linked to this transaction
    const [billings] = await db.sequelize.query(
      `SELECT b.*, r.procedure_id, r.patient_id, r.id as request_id
       FROM radiology_billing b
       LEFT JOIN radiology_requests r ON b.request_id = r.id
       WHERE b.pending_txn_id = ? AND b.facilityId = ?`,
      { replacements: [transactionId, facilityId] }
    );
    
    // ... rest of the function
    
    console.log(`[Radiology] Successfully created ${appointmentIds.length} appointment(s)`);  // ✅ Added final log
    return {
      success: true,
      message: `Created ${appointmentIds.length} appointment(s)`,
      appointmentIds
    };
  } catch (error) {
    console.error('[Radiology] Error in onPaymentComplete:', error);
    return { success: false, error: error.message };
  }
};
```

## How It Works Now

### Payment Flow:
1. **Request Creation**: Multiple procedures are created with individual `pending_txn` entries, all sharing the same `transaction_id`
2. **Billing Records**: Each procedure has a billing record linked to the shared `transaction_id` via `pending_txn_id`
3. **Payment Processing**: When cashier processes payment:
   - Account module loops through `txArr` (pending transactions)
   - Checks if `service_type === 'radiology'`
   - Calls `onPaymentComplete(transaction_id, facilityId)` with the correct transaction ID
4. **Appointment Creation**: `onPaymentComplete` function:
   - Finds all billing records with matching `pending_txn_id`
   - Creates appointments for each request
   - Updates request status to 'scheduled'
   - Updates billing status to 'paid'

## Data Structure

### pending_txn table (for radiology):
```javascript
{
  transaction_id: 'shared-uuid-for-all-procedures',  // ✅ Same for all procedures in one bill
  description: 'Radiology: Chest X-Ray',
  service_type: 'radiology',
  patient_name: 'John Doe',
  patient_id: '8-1',
  amount: 58000,
  // ... other fields
}
```

### radiology_billing table:
```javascript
{
  id: 'billing-uuid',
  request_id: 'request-uuid',
  pending_txn_id: 'shared-uuid-for-all-procedures',  // ✅ Links to transaction_id
  payment_status: 'pending' → 'paid',
  // ... other fields
}
```

## Testing

To test the fix:
1. Create a radiology request with multiple procedures (e.g., 2-3 procedures)
2. Go to cashier and process payment
3. Check server logs for:
   ```
   [Account] Payment completed, checking for radiology services...
   [Account] Checking item: radiology <transaction-id>
   [Account] Triggering radiology appointment creation for transaction: <transaction-id>
   [Radiology] Payment completed for transaction_id: <transaction-id>
   [Radiology] Found X billing record(s), creating appointments...
   [Radiology] Created appointment <appointment-id> for request <request-id>
   [Radiology] Successfully created X appointment(s)
   ```
4. Verify appointments are created in `radiology_appointments` table
5. Verify billing records updated to 'paid' status
6. Verify request status updated to 'scheduled'

## Next Steps
- Test complete workflow end-to-end
- Verify appointments appear in radiology appointments list
- Test with both new and existing patients
- Test with single and multiple procedures

## Related Files
- `backend/controller/account.js` - Payment processing
- `backend/controller/radiology-billing.js` - Appointment creation trigger
- `backend/controller/radiology-requests.js` - Request and billing creation
- `frontend/src/components/radiology/requests/RequestFormEnhanced.jsx` - Request form
- `frontend/src/components/account/Review.jsx` - Payment page
