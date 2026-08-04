# Retainership System Analysis

## Current Implementation

### Database Structure

#### 1. Patient Balance Storage
**Table:** `patientrecords`
**Field:** `balance` (INT(11), DEFAULT 0)

```sql
CREATE TABLE `patientrecords` (
  ...
  `accountType` varchar(50) DEFAULT NULL,  -- Can be 'Single', 'Family', 'Retainership', 'Corporate', 'Insurance'
  `balance` int(11) DEFAULT 0,             -- Patient balance (in Naira, stored as integer)
  ...
)
```

**Key Fields:**
- `accountType` - Identifies patient type ('Retainership', 'Family', 'Single', 'Corporate', 'Insurance')
- `balance` - Current balance available for the patient
- `retainership_organization_id` - Links to retainership organization
- `retainership_plan_id` - Links to retainership plan
- `retainership_expiry_date` - When retainership expires

#### 2. Retainership Tables

**retainership_organizations**
- Stores company/organization details
- Has `retainer_fee` field (monthly fee)
- Billing cycle configuration

**retainership_plans**
- Defines coverage rules
- `covered_services` - JSON array of covered service codes
- `excluded_services` - JSON array of excluded services
- `max_amount_per_visit` - Maximum coverage per visit
- `max_visits_per_month` - Visit limit
- `monthly_cap` - Total monthly coverage limit

**retainership_visits**
- Tracks each visit
- Records `covered_amount` and `uncovered_amount`
- Status: 'pending', 'billed', 'paid'

**retainership_invoices**
- Monthly invoices to organizations
- Aggregates all visits for billing period

---

## How Retainership Works

### Patient Types

1. **Retainership Patient**
   - `accountType` = 'Retainership'
   - Has pre-paid balance in `balance` field
   - Linked to organization and plan
   - Services deducted from balance

2. **Family Patient**
   - `accountType` = 'Family'
   - Also has pre-paid balance
   - Similar to retainership but family-based

3. **Credit Patient (Single/Corporate)**
   - `accountType` = 'Single' or 'Corporate'
   - No pre-paid balance
   - Services create receivables

---

## Balance Flow

### 1. Deposit/Top-up (Adding Balance)

**When organization pays retainer fee or patient makes deposit:**

```
Accounting Entry:
Debit:  Cash/Bank (400021/400022)        ₦100,000
Credit: Patient Deposits Liability (500022) ₦100,000

Database Update:
UPDATE patientrecords 
SET balance = balance + 100000 
WHERE id = 'patient_id'
```

**Current State:**
- Balance is stored in `patientrecords.balance`
- This is a LIABILITY (money owed to patient/organization)
- When services are consumed, balance decreases

### 2. Service Consumption (Using Balance)

**When retainership patient receives service:**

```
Accounting Entry:
Debit:  Patient Deposits Liability (500022)  ₦5,000  [Decrease liability]
Credit: Revenue Account (20XXX)              ₦5,000  [Recognize revenue]

Database Update:
UPDATE patientrecords 
SET balance = balance - 5000 
WHERE id = 'patient_id'
```

**Current State:**
- Balance decreases
- Revenue is recognized
- Liability decreases

### 3. Refund (Returning Balance)

**When patient/organization requests refund:**

```
Accounting Entry:
Debit:  Patient Deposits Liability (500022)  ₦10,000  [Decrease liability]
Credit: Cash/Bank (400021/400022)            ₦10,000  [Decrease asset]

Database Update:
UPDATE patientrecords 
SET balance = balance - 10000 
WHERE id = 'patient_id'
```

---

## Current Issues in Implementation

### Issue 1: Balance is NOT in Accounting System

**Problem:**
- `patientrecords.balance` is just a number in the database
- No corresponding entry in `transactions` table
- Financial reports don't show patient deposits as liabilities

**Impact:**
- Balance Sheet doesn't show Patient Deposits liability
- Can't track total deposits across all patients
- No audit trail for balance changes

### Issue 2: Deposit Transactions Missing

**Problem:**
- When deposits are made, they likely go to `pending_txn` or nowhere
- No proper accounting entry created

**Impact:**
- Cash received not recorded properly
- Liability not recorded
- Balance Sheet inaccurate

---

## Correct Implementation

### 1. When Deposit is Made

**Frontend Flow:**
```
1. Cashier receives ₦100,000 from organization
2. Selects patient/organization
3. Records deposit
```

**Backend Should Do:**
```javascript
// Create accounting entry
await createAccountingEntry(db, {
  facilityId,
  description: `Deposit for ${patient_name} - ${organization_name}`,
  debitAccount: '400021',  // Cash (or 400022 for Bank)
  creditAccount: '500022', // Patient Deposits Liability
  amount: 100000,
  userId,
  receiptNo: `DEP-${timestamp}`,
  patientId: patient_id,
  clientAcc: organization_id,
  modeOfPayment: 'CASH'
});

// Update patient balance
await db.sequelize.query(
  `UPDATE patientrecords 
   SET balance = balance + :amount 
   WHERE id = :patient_id`,
  { replacements: { amount: 100000, patient_id } }
);
```

### 2. When Service is Consumed (BILL Mode)

**This is what we implemented in Phase 1:**

```javascript
// Already implemented correctly!
if (patientInfo.patient_type === 'Retainership' || patientInfo.client_type === 'Family') {
  // Debit Patient Deposits, Credit Revenue
  await createAccountingEntry(db, {
    facilityId,
    description: item.description,
    debitAccount: '500022', // Patient Deposits Liability
    creditAccount: revenueAccount,
    amount: item.amount,
    userId,
    receiptNo,
    patientId: patient_id,
    clientAcc: client_acc,
    modeOfPayment: 'BILL'
  });
  
  // Update balance
  await updatePatientBalance(db, patient_id, item.amount);
}
```

### 3. When Refund is Issued

**Need to implement:**

```javascript
// Create accounting entry
await createAccountingEntry(db, {
  facilityId,
  description: `Refund for ${patient_name}`,
  debitAccount: '500022',  // Patient Deposits Liability
  creditAccount: '400021', // Cash
  amount: refundAmount,
  userId,
  receiptNo: `REF-${timestamp}`,
  patientId: patient_id,
  clientAcc: organization_id,
  modeOfPayment: 'CASH'
});

// Update patient balance
await db.sequelize.query(
  `UPDATE patientrecords 
   SET balance = balance - :amount 
   WHERE id = :patient_id`,
  { replacements: { amount: refundAmount, patient_id } }
);
```

---

## Account Codes

### Assets
- **400021** - Cash
- **400022** - Bank/POS
- **400023** - Accounts Receivable (Credit patients)

### Liabilities
- **500022** - Patient Deposits (Retainership/Family patients)

### Revenue
- **20001** - Registration Revenue
- **20002** - Consultation Revenue
- **20003** - Laboratory Revenue
- **20004** - Pharmacy Revenue
- **20005** - Dental Revenue
- **20006** - Shop Revenue

---

## Balance Reconciliation

### How to Verify Balance Accuracy

**1. Check Patient Balance:**
```sql
SELECT id, patient_name, accountType, balance 
FROM patientrecords 
WHERE accountType IN ('Retainership', 'Family')
  AND balance > 0;
```

**2. Check Accounting Liability:**
```sql
SELECT SUM(credit - debit) as total_liability
FROM transactions
WHERE acct = '500022'  -- Patient Deposits
  AND facilityId = 'YOUR_FACILITY_ID';
```

**3. They Should Match:**
```sql
-- Total patient balances
SELECT SUM(balance) as total_patient_balance
FROM patientrecords
WHERE accountType IN ('Retainership', 'Family')
  AND facilityId = 'YOUR_FACILITY_ID';

-- Should equal

-- Total accounting liability
SELECT SUM(credit - debit) as total_accounting_liability
FROM transactions
WHERE acct = '500022'
  AND facilityId = 'YOUR_FACILITY_ID';
```

---

## Missing Functionality

### 1. Deposit Recording Endpoint

**Need to create:**
- `POST /account/deposit` - Record new deposit
- Should create accounting entry + update balance

### 2. Refund Endpoint

**Need to create:**
- `POST /account/refund` - Process refund
- Should create accounting entry + update balance

### 3. Balance Transfer

**Need to create:**
- `POST /account/transfer-balance` - Transfer between patients
- Useful for family accounts

### 4. Balance History

**Need to create:**
- `GET /account/balance-history/:patientId` - Show all balance changes
- Query transactions table for audit trail

---

## Recommendations

### Immediate (Phase 1 Complete ✅)
- ✅ Service consumption properly debits Patient Deposits
- ✅ Balance is updated when services consumed
- ✅ Validation checks balance before processing

### Short Term (Phase 2)
1. **Create Deposit Endpoint**
   - Record deposits properly in accounting
   - Update patient balance
   - Generate deposit receipt

2. **Create Refund Endpoint**
   - Process refunds with accounting
   - Update patient balance
   - Generate refund receipt

3. **Balance Reconciliation Report**
   - Compare patient balances with accounting
   - Identify discrepancies
   - Fix historical data

### Long Term (Phase 3)
1. **Automated Balance Alerts**
   - Notify when balance low
   - Alert on expiry
   - Monthly statements

2. **Organization Billing**
   - Automated invoice generation
   - Track payments from organizations
   - Reconcile with visits

3. **Coverage Validation**
   - Real-time coverage check
   - Service approval workflow
   - Limit enforcement

---

## Testing Checklist

- [ ] Patient with balance can use BILL mode
- [ ] Balance decreases after service
- [ ] Insufficient balance is rejected
- [ ] Accounting entry created correctly
- [ ] Balance Sheet shows Patient Deposits liability
- [ ] Trial Balance shows correct amounts
- [ ] Family patients work same as Retainership
- [ ] Credit patients create receivables (not deposits)

---

## Summary

**Current State:**
- ✅ Balance stored in `patientrecords.balance`
- ✅ Retainership patients identified by `accountType`
- ✅ Service consumption now properly handled (Phase 1)
- ❌ Deposits not recorded in accounting
- ❌ Refunds not implemented
- ❌ No balance reconciliation

**What Phase 1 Fixed:**
- Service consumption now creates proper accounting entries
- Balance is validated and updated correctly
- Patient Deposits liability is debited when services consumed
- Revenue is recognized properly

**What Still Needs Work:**
- Deposit recording (when money comes in)
- Refund processing (when money goes out)
- Balance reconciliation tools
- Historical data migration
