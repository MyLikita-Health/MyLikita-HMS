# Payment System Phase 2 - Implementation Plan

## Overview

Phase 1 successfully implemented proper double-entry bookkeeping for service payments. Phase 2 will complete the retainership system by adding deposit recording, refund processing, and balance reconciliation.

---

## Phase 2 Goals

1. ✅ Service consumption properly debits Patient Deposits (Phase 1)
2. ❌ Deposit recording creates proper accounting entries
3. ❌ Refund processing with accounting
4. ❌ Balance reconciliation tools
5. ❌ Balance history and audit trail

---

## Task 1: Deposit Recording Endpoint

### Priority: HIGH

### Endpoint
`POST /account/deposit`

### Purpose
Record deposits from organizations or patients into retainership accounts.

### Request Body
```json
{
  "patient_id": "PAT123",
  "patient_name": "John Doe",
  "organization_id": "ORG456",
  "organization_name": "ABC Corp",
  "amount": 100000,
  "modeOfPayment": "BANK",
  "facilityId": "FAC001",
  "userId": "USR789",
  "notes": "Monthly retainer fee - March 2026"
}
```

### Accounting Logic
```javascript
// Create accounting entry
await createAccountingEntry(db, {
  facilityId,
  description: `Deposit: ${patient_name} - ${organization_name}`,
  debitAccount: getSourceAccount(modeOfPayment), // 400021 or 400022
  creditAccount: '500022', // Patient Deposits Liability
  amount,
  userId,
  receiptNo: `DEP-${Date.now()}`,
  patientId: patient_id,
  clientAcc: organization_id,
  modeOfPayment
});

// Update patient balance
await db.sequelize.query(
  `UPDATE patientrecords 
   SET balance = balance + :amount,
       last_deposit_date = NOW(),
       last_deposit_amount = :amount
   WHERE id = :patient_id`,
  { replacements: { amount, patient_id } }
);
```

### Response
```json
{
  "success": true,
  "receiptNo": "DEP-1709971200000",
  "newBalance": 150000,
  "message": "Deposit recorded successfully"
}
```

### Implementation Steps
1. Create controller function in `backend/controller/account.js`
2. Add route in `backend/routes/account.js`
3. Add API client function in `frontend/src/utils/apiClient.js`
4. Create UI component for deposit recording
5. Test with different payment modes
6. Verify accounting entries
7. Verify balance updates

---

## Task 2: Refund Processing Endpoint

### Priority: HIGH

### Endpoint
`POST /account/refund`

### Purpose
Process refunds to patients or organizations when retainership is cancelled or overpaid.

### Request Body
```json
{
  "patient_id": "PAT123",
  "patient_name": "John Doe",
  "organization_id": "ORG456",
  "amount": 10000,
  "modeOfPayment": "BANK",
  "facilityId": "FAC001",
  "userId": "USR789",
  "reason": "Retainership cancelled",
  "approvedBy": "MGR001"
}
```

### Accounting Logic
```javascript
// Validate balance
const patientInfo = await getPatientInfo(db, patient_id);
if (patientInfo.balance < amount) {
  return res.status(400).json({
    error: 'Insufficient balance for refund',
    balance: patientInfo.balance,
    requested: amount
  });
}

// Create accounting entry
await createAccountingEntry(db, {
  facilityId,
  description: `Refund: ${patient_name} - ${reason}`,
  debitAccount: '500022', // Patient Deposits Liability
  creditAccount: getSourceAccount(modeOfPayment), // 400021 or 400022
  amount,
  userId,
  receiptNo: `REF-${Date.now()}`,
  patientId: patient_id,
  clientAcc: organization_id,
  modeOfPayment
});

// Update patient balance
await db.sequelize.query(
  `UPDATE patientrecords 
   SET balance = balance - :amount
   WHERE id = :patient_id`,
  { replacements: { amount, patient_id } }
);

// Record refund in audit table
await db.sequelize.query(
  `INSERT INTO retainership_refunds 
   (patient_id, organization_id, amount, reason, approved_by, 
    transaction_id, refund_date, facilityId)
   VALUES (:patient_id, :organization_id, :amount, :reason, 
           :approvedBy, :receiptNo, NOW(), :facilityId)`,
  {
    replacements: {
      patient_id,
      organization_id,
      amount,
      reason,
      approvedBy,
      receiptNo: `REF-${Date.now()}`,
      facilityId
    }
  }
);
```

### Response
```json
{
  "success": true,
  "receiptNo": "REF-1709971200000",
  "newBalance": 40000,
  "message": "Refund processed successfully"
}
```

### Implementation Steps
1. Create refunds audit table (if not exists)
2. Create controller function
3. Add route
4. Add API client function
5. Create UI component with approval workflow
6. Test refund scenarios
7. Verify accounting entries
8. Verify balance updates

---

## Task 3: Balance Reconciliation Report

### Priority: MEDIUM

### Endpoint
`GET /account/balance-reconciliation`

### Purpose
Compare patient balances with accounting entries to identify discrepancies.

### Query Parameters
```
?facilityId=FAC001
&patientType=Retainership
&showDiscrepancies=true
```

### Logic
```javascript
// Get patient balances
const patientBalances = await db.sequelize.query(
  `SELECT 
     id,
     patient_name,
     patient_type,
     balance as patient_balance,
     retainership_organization_id
   FROM patientrecords
   WHERE patient_type IN ('Retainership', 'Family')
     AND facilityId = :facilityId
   ORDER BY patient_name`,
  { replacements: { facilityId }, type: QueryTypes.SELECT }
);

// Get accounting balances
const accountingBalances = await db.sequelize.query(
  `SELECT 
     patient_id,
     SUM(credit - debit) as accounting_balance
   FROM transactions
   WHERE acct = '500022'
     AND facilityId = :facilityId
     AND patient_id IS NOT NULL
   GROUP BY patient_id`,
  { replacements: { facilityId }, type: QueryTypes.SELECT }
);

// Compare and identify discrepancies
const reconciliation = patientBalances.map(patient => {
  const accounting = accountingBalances.find(
    a => a.patient_id === patient.id
  );
  
  const accountingBalance = accounting ? accounting.accounting_balance : 0;
  const discrepancy = patient.patient_balance - accountingBalance;
  
  return {
    patient_id: patient.id,
    patient_name: patient.patient_name,
    patient_type: patient.patient_type,
    patient_balance: patient.patient_balance,
    accounting_balance: accountingBalance,
    discrepancy,
    status: Math.abs(discrepancy) < 0.01 ? 'OK' : 'MISMATCH'
  };
});

// Filter if requested
if (showDiscrepancies) {
  return reconciliation.filter(r => r.status === 'MISMATCH');
}

return reconciliation;
```

### Response
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
    }
  ]
}
```

### Implementation Steps
1. Create controller function
2. Add route
3. Add API client function
4. Create UI component with table view
5. Add export to Excel functionality
6. Add fix discrepancy action
7. Test with sample data

---

## Task 4: Balance History

### Priority: MEDIUM

### Endpoint
`GET /account/balance-history/:patientId`

### Purpose
Show all balance changes for a patient with audit trail.

### Query Parameters
```
?from=2026-01-01
&to=2026-03-31
&limit=50
```

### Logic
```javascript
const history = await db.sequelize.query(
  `SELECT 
     transaction_date,
     description,
     CASE 
       WHEN acct = '500022' AND debit > 0 THEN 'Service Consumption'
       WHEN acct = '500022' AND credit > 0 THEN 'Deposit'
       ELSE 'Other'
     END as transaction_type,
     CASE 
       WHEN acct = '500022' AND debit > 0 THEN -debit
       WHEN acct = '500022' AND credit > 0 THEN credit
       ELSE 0
     END as amount,
     receiptNo,
     modeOfPayment,
     enteredBy,
     createdAt
   FROM transactions
   WHERE patient_id = :patientId
     AND acct = '500022'
     AND transaction_date BETWEEN :from AND :to
   ORDER BY transaction_date DESC, createdAt DESC
   LIMIT :limit`,
  {
    replacements: { patientId, from, to, limit },
    type: QueryTypes.SELECT
  }
);

// Calculate running balance
let runningBalance = 0;
const historyWithBalance = history.reverse().map(item => {
  runningBalance += item.amount;
  return {
    ...item,
    balance_after: runningBalance
  };
}).reverse();

return historyWithBalance;
```

### Response
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

### Implementation Steps
1. Create controller function
2. Add route
3. Add API client function
4. Create UI component with timeline view
5. Add filters (date range, transaction type)
6. Add export functionality
7. Test with sample data

---

## Task 5: Balance Transfer (Optional)

### Priority: LOW

### Endpoint
`POST /account/transfer-balance`

### Purpose
Transfer balance between patients (useful for family accounts).

### Request Body
```json
{
  "from_patient_id": "PAT123",
  "to_patient_id": "PAT456",
  "amount": 10000,
  "facilityId": "FAC001",
  "userId": "USR789",
  "reason": "Transfer to family member"
}
```

### Accounting Logic
```javascript
// Validate source balance
const fromPatient = await getPatientInfo(db, from_patient_id);
if (fromPatient.balance < amount) {
  return res.status(400).json({ error: 'Insufficient balance' });
}

// Create accounting entries (2 transactions)
// 1. Debit from source
await createAccountingEntry(db, {
  facilityId,
  description: `Balance transfer from ${fromPatient.patient_name}`,
  debitAccount: '500022',
  creditAccount: '500022',
  amount,
  userId,
  receiptNo: `TRF-${Date.now()}`,
  patientId: from_patient_id,
  modeOfPayment: 'TRANSFER'
});

// 2. Credit to destination
await createAccountingEntry(db, {
  facilityId,
  description: `Balance transfer to ${toPatient.patient_name}`,
  debitAccount: '500022',
  creditAccount: '500022',
  amount,
  userId,
  receiptNo: `TRF-${Date.now()}`,
  patientId: to_patient_id,
  modeOfPayment: 'TRANSFER'
});

// Update balances
await db.sequelize.query(
  `UPDATE patientrecords 
   SET balance = balance - :amount 
   WHERE id = :from_patient_id`,
  { replacements: { amount, from_patient_id } }
);

await db.sequelize.query(
  `UPDATE patientrecords 
   SET balance = balance + :amount 
   WHERE id = :to_patient_id`,
  { replacements: { amount, to_patient_id } }
);
```

---

## Database Changes

### New Table: retainership_refunds
```sql
CREATE TABLE IF NOT EXISTS retainership_refunds (
  id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id VARCHAR(50) NOT NULL,
  organization_id VARCHAR(50),
  amount DECIMAL(10,2) NOT NULL,
  reason TEXT,
  approved_by VARCHAR(50),
  transaction_id VARCHAR(100),
  refund_date DATETIME,
  facilityId VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_patient (patient_id),
  INDEX idx_org (organization_id),
  INDEX idx_date (refund_date)
);
```

### New Columns (Optional)
```sql
ALTER TABLE patientrecords 
ADD COLUMN last_deposit_date DATETIME,
ADD COLUMN last_deposit_amount DECIMAL(10,2);
```

---

## UI Components

### 1. Deposit Recording Form
**Location:** `frontend/src/components/account/DepositForm.jsx`

**Features:**
- Patient/Organization selection
- Amount input
- Payment mode selection
- Notes field
- Receipt generation

### 2. Refund Processing Form
**Location:** `frontend/src/components/account/RefundForm.jsx`

**Features:**
- Patient selection with balance display
- Amount input with validation
- Reason field
- Approval workflow
- Receipt generation

### 3. Balance Reconciliation Report
**Location:** `frontend/src/components/account/BalanceReconciliation.jsx`

**Features:**
- Summary statistics
- Detailed table view
- Filter by discrepancy
- Export to Excel
- Fix discrepancy action

### 4. Balance History View
**Location:** `frontend/src/components/account/BalanceHistory.jsx`

**Features:**
- Timeline view
- Date range filter
- Transaction type filter
- Running balance display
- Export functionality

---

## Testing Plan

### Deposit Recording Tests
- [ ] Record cash deposit
- [ ] Record bank deposit
- [ ] Verify accounting entry (Debit Cash/Bank, Credit Patient Deposits)
- [ ] Verify balance update
- [ ] Generate receipt
- [ ] Test with different patient types

### Refund Processing Tests
- [ ] Process refund with sufficient balance
- [ ] Reject refund with insufficient balance
- [ ] Verify accounting entry (Debit Patient Deposits, Credit Cash/Bank)
- [ ] Verify balance update
- [ ] Test approval workflow
- [ ] Generate receipt

### Balance Reconciliation Tests
- [ ] Run reconciliation report
- [ ] Identify discrepancies
- [ ] Export to Excel
- [ ] Fix discrepancy
- [ ] Verify after fix

### Balance History Tests
- [ ] View full history
- [ ] Filter by date range
- [ ] Filter by transaction type
- [ ] Verify running balance calculation
- [ ] Export history

---

## Success Criteria

- [ ] Deposits create proper accounting entries
- [ ] Refunds create proper accounting entries
- [ ] Balance reconciliation identifies all discrepancies
- [ ] Balance history shows complete audit trail
- [ ] All tests pass
- [ ] Financial reports show correct balances
- [ ] Patient balances match accounting

---

## Timeline Estimate

| Task | Estimated Time |
|------|---------------|
| Deposit Recording | 4 hours |
| Refund Processing | 4 hours |
| Balance Reconciliation | 6 hours |
| Balance History | 4 hours |
| Testing | 4 hours |
| Documentation | 2 hours |
| **Total** | **24 hours** |

---

## Dependencies

- Phase 1 must be complete ✅
- Database access
- Frontend components
- API client setup
- Testing environment

---

## Risks & Mitigation

### Risk 1: Historical Data Mismatch
**Mitigation:** Create migration script to sync historical data

### Risk 2: Concurrent Balance Updates
**Mitigation:** Use database transactions and row locking

### Risk 3: Refund Approval Workflow
**Mitigation:** Implement proper authorization checks

---

## Next Steps

1. Review this plan with team
2. Get approval for database changes
3. Start with Task 1 (Deposit Recording)
4. Test thoroughly in development
5. Deploy to staging
6. User acceptance testing
7. Deploy to production

---

**Ready to start Phase 2!**
