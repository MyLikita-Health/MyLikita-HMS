# Payment Phase 2 - Quick Start Guide

## Overview

Phase 2 adds deposit recording, refund processing, and balance reconciliation to the retainership system.

---

## Quick Setup

### 1. Run Database Migration

```bash
cd backend/sql
node run_deposits_refunds_migration.js
```

Expected output:
```
✅ Migration completed successfully!
Created tables:
  - retainership_refunds
  - retainership_deposits
Added columns to patientrecords:
  - last_deposit_date
  - last_deposit_amount
```

### 2. Restart Backend Server

```bash
cd backend
npm start
```

---

## Testing Deposit Recording

### Using API (Postman/cURL)

```bash
POST http://localhost:46990/account/deposit

Headers:
Authorization: Bearer YOUR_TOKEN

Body:
{
  "patient_id": "PAT123",
  "patient_name": "John Doe",
  "organization_id": "ORG456",
  "organization_name": "ABC Corp",
  "amount": 100000,
  "modeOfPayment": "BANK",
  "notes": "Monthly retainer fee - March 2026"
}
```

### Expected Response

```json
{
  "success": true,
  "receiptNo": "DEP-1709971200000",
  "newBalance": 150000,
  "message": "Deposit recorded successfully"
}
```

### Verify in Database

```sql
-- Check transactions table
SELECT * FROM transactions 
WHERE receiptNo LIKE 'DEP-%' 
ORDER BY createdAt DESC 
LIMIT 2;

-- Should see 2 entries:
-- 1. Debit Cash/Bank (400021 or 400022)
-- 2. Credit Patient Deposits (500022)

-- Check patient balance
SELECT patient_name, balance, last_deposit_date, last_deposit_amount
FROM patientrecords 
WHERE id = 'PAT123';

-- Check audit table
SELECT * FROM retainership_deposits 
ORDER BY created_at DESC 
LIMIT 1;
```

---

## Testing Refund Processing

### Using API

```bash
POST http://localhost:46990/account/refund

Headers:
Authorization: Bearer YOUR_TOKEN

Body:
{
  "patient_id": "PAT123",
  "patient_name": "John Doe",
  "organization_id": "ORG456",
  "amount": 10000,
  "modeOfPayment": "CASH",
  "reason": "Retainership cancelled - patient relocated",
  "approvedBy": "MGR001"
}
```

### Expected Response

```json
{
  "success": true,
  "receiptNo": "REF-1709971200000",
  "newBalance": 40000,
  "message": "Refund processed successfully"
}
```

### Test Insufficient Balance

```bash
POST http://localhost:46990/account/refund

Body:
{
  "patient_id": "PAT123",
  "amount": 999999,  # More than balance
  ...
}
```

Expected error:
```json
{
  "error": "Insufficient balance for refund",
  "balance": 50000,
  "requested": 999999
}
```

### Verify in Database

```sql
-- Check transactions table
SELECT * FROM transactions 
WHERE receiptNo LIKE 'REF-%' 
ORDER BY createdAt DESC 
LIMIT 2;

-- Should see 2 entries:
-- 1. Debit Patient Deposits (500022)
-- 2. Credit Cash/Bank (400021 or 400022)

-- Check patient balance (should be reduced)
SELECT patient_name, balance
FROM patientrecords 
WHERE id = 'PAT123';

-- Check refunds audit table
SELECT * FROM retainership_refunds 
ORDER BY created_at DESC 
LIMIT 1;
```

---

## Testing Balance Reconciliation

### Using API

```bash
GET http://localhost:46990/account/balance-reconciliation?facilityId=FAC001&showDiscrepancies=false

Headers:
Authorization: Bearer YOUR_TOKEN
```

### Expected Response

```json
{
  "success": true,
  "summary": {
    "total_patients": 50,
    "matched": 45,
    "mismatched": 5,
    "total_patient_balance": 5000000,
    "total_accounting_balance": 4950000,
    "total_discrepancy": 50000
  },
  "details": [
    {
      "patient_id": "PAT123",
      "patient_name": "John Doe",
      "patient_type": "Retainership",
      "patient_balance": 50000,
      "accounting_balance": 48000,
      "discrepancy": 2000,
      "status": "MISMATCH"
    },
    ...
  ]
}
```

### Show Only Discrepancies

```bash
GET http://localhost:46990/account/balance-reconciliation?facilityId=FAC001&showDiscrepancies=true
```

---

## Testing Balance History

### Using API

```bash
GET http://localhost:46990/account/balance-history/PAT123?from=2026-01-01&to=2026-03-31&limit=50

Headers:
Authorization: Bearer YOUR_TOKEN
```

### Expected Response

```json
{
  "success": true,
  "patient_id": "PAT123",
  "patient_name": "John Doe",
  "current_balance": 50000,
  "history": [
    {
      "transaction_date": "2026-03-09",
      "description": "Consultation - Dr. Smith",
      "transaction_type": "Service Consumption",
      "amount": -5000,
      "balance_after": 50000,
      "receiptNo": "TXN001",
      "modeOfPayment": "BILL",
      "enteredBy": "USR789",
      "createdAt": "2026-03-09T10:30:00"
    },
    {
      "transaction_date": "2026-03-01",
      "description": "Deposit: ABC Corp - Monthly retainer",
      "transaction_type": "Deposit",
      "amount": 100000,
      "balance_after": 55000,
      "receiptNo": "DEP-1709280000000",
      "modeOfPayment": "BANK",
      "enteredBy": "USR789",
      "createdAt": "2026-03-01T09:00:00"
    }
  ]
}
```

---

## Using Frontend Components

### 1. Deposit Form

```jsx
import DepositForm from './components/account/DepositForm';

// In your component
const [showDepositForm, setShowDepositForm] = useState(false);

{showDepositForm && (
  <DepositForm
    onClose={() => setShowDepositForm(false)}
    onSuccess={(data) => {
      console.log('Deposit recorded:', data);
      // Refresh patient list or balance
    }}
    selectedPatient={selectedPatient}  // Optional
  />
)}
```

### 2. Refund Form

```jsx
import RefundForm from './components/account/RefundForm';

{showRefundForm && (
  <RefundForm
    onClose={() => setShowRefundForm(false)}
    onSuccess={(data) => {
      console.log('Refund processed:', data);
      // Refresh patient list or balance
    }}
    selectedPatient={selectedPatient}  // Optional
  />
)}
```

### 3. Balance Reconciliation

```jsx
import BalanceReconciliation from './components/account/BalanceReconciliation';

// In your routing or dashboard
<Route path="/account/reconciliation" component={BalanceReconciliation} />
```

---

## Common Scenarios

### Scenario 1: New Organization Deposit

```
1. Organization pays ₦500,000 retainer fee
2. Open Deposit Form
3. Enter patient details
4. Enter organization details
5. Amount: 500000
6. Mode: BANK
7. Notes: "Q1 2026 Retainer Fee"
8. Submit

Result:
- Receipt: DEP-1709971200000
- Patient balance: +₦500,000
- Accounting: Debit Bank, Credit Patient Deposits
```

### Scenario 2: Patient Cancels Retainership

```
1. Patient requests refund of remaining balance
2. Check current balance: ₦150,000
3. Get manager approval
4. Open Refund Form
5. Amount: 150000
6. Mode: BANK
7. Reason: "Retainership cancelled - patient relocated"
8. Approved By: MGR001
9. Submit

Result:
- Receipt: REF-1709971200000
- Patient balance: -₦150,000 (now 0)
- Accounting: Debit Patient Deposits, Credit Bank
```

### Scenario 3: Monthly Reconciliation

```
1. Open Balance Reconciliation dashboard
2. Review summary statistics
3. Check for discrepancies
4. If discrepancies found:
   - Filter by "Show Discrepancies Only"
   - Export to Excel
   - Investigate each mismatch
   - Fix historical data if needed
5. Verify total matches
```

---

## Verification Queries

### Check Deposit Accounting

```sql
-- For a specific deposit receipt
SELECT 
  transaction_date,
  description,
  acct,
  debit,
  credit,
  modeOfPayment
FROM transactions
WHERE receiptNo = 'DEP-1709971200000'
ORDER BY transaction_id;

-- Should show:
-- Row 1: acct=400021/400022, debit=100000, credit=0
-- Row 2: acct=500022, debit=0, credit=100000
```

### Check Refund Accounting

```sql
-- For a specific refund receipt
SELECT 
  transaction_date,
  description,
  acct,
  debit,
  credit,
  modeOfPayment
FROM transactions
WHERE receiptNo = 'REF-1709971200000'
ORDER BY transaction_id;

-- Should show:
-- Row 1: acct=500022, debit=10000, credit=0
-- Row 2: acct=400021/400022, debit=0, credit=10000
```

### Verify Balance Matches Accounting

```sql
-- Patient balance
SELECT id, patient_name, balance 
FROM patientrecords 
WHERE id = 'PAT123';

-- Accounting balance
SELECT 
  patient_id,
  SUM(credit - debit) as accounting_balance
FROM transactions
WHERE acct = '500022'
  AND patient_id = 'PAT123'
GROUP BY patient_id;

-- These should match!
```

---

## Troubleshooting

### Issue: Deposit not creating accounting entries

**Check:**
1. Is `createAccountingEntry` function imported?
2. Are transactions being committed?
3. Check backend logs for errors

**Fix:**
```bash
# Check backend logs
tail -f backend/logs/app.log

# Verify function exists
grep -n "createAccountingEntry" backend/controller/account.js
```

### Issue: Balance not updating

**Check:**
1. Is UPDATE query executing?
2. Is patient_id correct?
3. Check database permissions

**Fix:**
```sql
-- Manually verify update
UPDATE patientrecords 
SET balance = balance + 100000 
WHERE id = 'PAT123';

-- Check result
SELECT balance FROM patientrecords WHERE id = 'PAT123';
```

### Issue: Reconciliation shows discrepancies

**Cause:** Historical data not in accounting system

**Fix:**
```sql
-- Run migration script for existing balances
-- See PAYMENT_PHASE2_COMPLETE.md for migration SQL
```

---

## Performance Tips

### For Large Datasets

1. **Use Date Ranges**
   ```
   Balance history: Limit to 3-6 months
   Reconciliation: Run monthly, not daily
   ```

2. **Index Optimization**
   ```sql
   CREATE INDEX idx_transactions_patient_acct 
   ON transactions(patient_id, acct);
   
   CREATE INDEX idx_deposits_patient 
   ON retainership_deposits(patient_id, deposit_date);
   ```

3. **Batch Processing**
   ```
   For bulk deposits: Process in batches of 100
   For reconciliation: Run during off-peak hours
   ```

---

## Next Steps

1. Test all scenarios above
2. Train staff on new features
3. Run initial reconciliation
4. Fix any historical discrepancies
5. Set up monthly reconciliation schedule
6. Monitor for issues
7. Collect user feedback

---

## Support

**Documentation:**
- PAYMENT_PHASE2_COMPLETE.md - Full implementation details
- PAYMENT_PHASE2_PLAN.md - Original plan
- PAYMENT_SYSTEM_STATUS.md - Overall system status

**API Reference:**
- POST /account/deposit
- POST /account/refund
- GET /account/balance-reconciliation
- GET /account/balance-history/:patientId

**Database Tables:**
- transactions - All accounting entries
- retainership_deposits - Deposit audit trail
- retainership_refunds - Refund audit trail
- patientrecords - Patient balances

---

**Ready to test!** 🚀
