# Payment System - Quick Reference Guide

## Overview

The payment system now uses proper double-entry bookkeeping. Every payment creates balanced accounting entries that appear in financial reports.

---

## Payment Flow

```
User Action → Review.jsx → POST /account/pay-bill → casherPayBill() → transactions table → Financial Reports
```

---

## Payment Modes

### 1. CASH
```
Debit:  Cash (400021)        ₦X,XXX
Credit: Revenue (20XXX)      ₦X,XXX
```

### 2. POS
```
Debit:  Bank (400022)        ₦X,XXX
Credit: Revenue (20XXX)      ₦X,XXX
```

### 3. BANK
```
Debit:  Bank (400022)        ₦X,XXX
Credit: Revenue (20XXX)      ₦X,XXX
```

### 4. POS_AND_CASH (Split Payment)
```
Debit:  Cash (400021)        ₦3,000
Debit:  Bank (400022)        ₦5,000
Credit: Revenue (20XXX)      ₦8,000
```

### 5. BANK_AND_CASH (Split Payment)
```
Debit:  Cash (400021)        ₦2,000
Debit:  Bank (400022)        ₦6,000
Credit: Revenue (20XXX)      ₦8,000
```

### 6. BILL (Intelligent Routing)

**For Retainership/Family Patients:**
```
Debit:  Patient Deposits (500022)  ₦X,XXX
Credit: Revenue (20XXX)             ₦X,XXX
+ Updates patient balance
```

**For Credit Patients:**
```
Debit:  Accounts Receivable (400023)  ₦X,XXX
Credit: Revenue (20XXX)                ₦X,XXX
```

---

## Service Types & Revenue Accounts

| Service Type | Revenue Account | Description |
|-------------|----------------|-------------|
| REGISTRATION | 20001 | Patient registration fees |
| CONSULTATION | 20002 | Doctor consultation fees |
| LAB | 20003 | Laboratory test fees |
| PHARMACY | 20004 | Medication sales |
| DENTAL | 20005 | Dental procedures |
| SHOP | 20006 | Oral care products |

---

## Account Codes

### Assets (Debit ↑)
- **400021** - Cash
- **400022** - Bank/POS
- **400023** - Accounts Receivable
- **400024** - Inventory

### Liabilities (Credit ↑)
- **500021** - Accounts Payable
- **500022** - Patient Deposits

### Revenue (Credit ↑)
- **20001** - Registration
- **20002** - Consultation
- **20003** - Laboratory
- **20004** - Pharmacy
- **20005** - Dental
- **20006** - Shop

### Expenses (Debit ↑)
- **700001** - COGS
- **800003** - Discount Expense

---

## Validation Rules

### Split Payments
- POS amount + Cash amount MUST equal Total
- Bank amount + Cash amount MUST equal Total
- Returns error if mismatch

### BILL Mode
- Checks patient type (Retainership/Family vs Credit)
- For Retainership: Validates balance ≥ amount
- Returns error if insufficient balance

### General
- All amounts must be positive
- facilityId is required
- userId is required
- Patient ID is required for BILL mode

---

## Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Insufficient balance" | Retainership balance < amount | Add deposit or use different payment mode |
| "Split payment amounts do not match total" | POS + Cash ≠ Total | Adjust split amounts |
| "Missing facilityId" | No facility ID provided | Check request body |
| "Transaction failed" | Database error | Check logs and database connection |

---

## Testing Quick Commands

### Check Recent Payments
```sql
SELECT * FROM transactions 
WHERE transaction_date = CURDATE() 
ORDER BY createdAt DESC 
LIMIT 10;
```

### Check Patient Balance
```sql
SELECT patient_name, patient_type, balance 
FROM patientrecords 
WHERE id = 'PATIENT_ID';
```

### Verify Double-Entry
```sql
-- Should be 0 (balanced)
SELECT SUM(debit) - SUM(credit) as check_balance
FROM transactions
WHERE receiptNo = 'RECEIPT_NO';
```

### Check Revenue Today
```sql
SELECT 
  acct,
  SUM(credit - debit) as revenue
FROM transactions
WHERE acct LIKE '200%'
  AND transaction_date = CURDATE()
GROUP BY acct;
```

---

## Common Scenarios

### Scenario 1: Cash Payment for Consultation
```
Patient: John Doe
Service: Consultation
Amount: ₦5,000
Mode: CASH

Result:
- Debit Cash (400021): ₦5,000
- Credit Consultation Revenue (20002): ₦5,000
```

### Scenario 2: Split Payment for Pharmacy
```
Patient: Jane Smith
Service: Pharmacy
Amount: ₦8,000
Mode: POS_AND_CASH
POS: ₦5,000
Cash: ₦3,000

Result:
- Debit Cash (400021): ₦3,000
- Debit Bank (400022): ₦5,000
- Credit Pharmacy Revenue (20004): ₦8,000
```

### Scenario 3: BILL Mode - Retainership
```
Patient: ABC Corp Employee
Service: Lab Test
Amount: ₦3,000
Mode: BILL
Patient Balance: ₦50,000

Result:
- Debit Patient Deposits (500022): ₦3,000
- Credit Lab Revenue (20003): ₦3,000
- Patient Balance: ₦50,000 → ₦47,000
```

### Scenario 4: BILL Mode - Credit Patient
```
Patient: XYZ Company
Service: Dental
Amount: ₦10,000
Mode: BILL
Patient Type: Corporate

Result:
- Debit Accounts Receivable (400023): ₦10,000
- Credit Dental Revenue (20005): ₦10,000
```

### Scenario 5: Payment with Discount
```
Patient: John Doe
Service: Registration
Amount: ₦2,000
Discount: ₦500
Mode: CASH

Result:
- Debit Cash (400021): ₦1,500
- Credit Registration Revenue (20001): ₦1,500
- Debit Discount Expense (800003): ₦500
- Credit Registration Revenue (20001): ₦500
```

---

## Financial Reports Impact

### Trial Balance
Shows all accounts with their balances:
- Assets (Debit side)
- Liabilities (Credit side)
- Revenue (Credit side)
- Expenses (Debit side)

### Balance Sheet
Shows financial position:
- **Assets**: Cash, Bank, Receivables, Inventory
- **Liabilities**: Payables, Patient Deposits
- **Equity**: Retained Earnings

### Profit & Loss
Shows profitability:
- **Revenue**: All service revenue
- **Expenses**: COGS, Discounts
- **Net Profit**: Revenue - Expenses

### Cash Flow
Shows cash movements:
- Operating activities (service payments)
- Cash inflows and outflows

---

## API Endpoint

### POST /account/pay-bill

**Request Body:**
```json
{
  "patient_name": "John Doe",
  "patient_id": "PAT123",
  "client_acc": "CLI456",
  "facilityId": "FAC001",
  "userId": "USR789",
  "formSelect": {
    "modeOfPayment": "CASH",
    "amount": 5000,
    "discountAmount": 0,
    "posAmount": 0,
    "cashAmount": 0,
    "bankAmount": 0
  },
  "txArr": [
    {
      "transaction_id": "TXN001",
      "service_type": "CONSULTATION",
      "description": "Doctor Consultation",
      "amount": 5000,
      "head": "20002"
    }
  ],
  "status": "paid"
}
```

**Response (Success):**
```json
{
  "success": true,
  "results": [...]
}
```

**Response (Error):**
```json
{
  "error": "Insufficient balance",
  "balance": 1000,
  "required": 5000
}
```

---

## Helper Functions

Located in: `backend/controller/helpers/accounting.js`

### createAccountingEntry()
Creates a double-entry transaction.

### createSplitPaymentEntry()
Handles split payments (POS+Cash, Bank+Cash).

### createDiscountEntry()
Records discount as expense.

### getSourceAccount()
Maps payment mode to account code.

### getRevenueAccount()
Maps service type to revenue account.

### getPatientInfo()
Retrieves patient balance and type.

### updatePatientBalance()
Updates patient balance after service.

---

## Troubleshooting

### Payment Not Appearing in Reports
1. Check transaction_date matches report date range
2. Verify facilityId matches
3. Check account codes are correct

### Balance Not Updating
1. Verify patient_id is correct
2. Check updatePatientBalance() was called
3. Query patientrecords table directly

### Split Payment Failing
1. Verify POS + Cash = Total
2. Check all amounts are positive
3. Ensure modeOfPayment is correct

### BILL Mode Not Working
1. Check patient_type field
2. Verify balance is sufficient
3. Check getPatientInfo() returns data

---

## Best Practices

1. **Always validate input** before processing
2. **Use transactions** for atomic operations
3. **Log errors** for debugging
4. **Check balances** before BILL mode
5. **Verify double-entry** (debits = credits)
6. **Test in development** before production
7. **Monitor financial reports** for accuracy

---

## Support Files

- **PAYMENT_SYSTEM_STATUS.md** - Current status
- **PAYMENT_PHASE1_COMPLETE.md** - Implementation details
- **PAYMENT_PHASE1_QUICK_START.md** - Testing guide
- **RETAINERSHIP_ANALYSIS.md** - Retainership system
- **ACCOUNTING_SYSTEM_ANALYSIS.md** - Overall accounting

---

## Currency

All amounts are in Nigerian Naira (₦).

---

**Last Updated:** March 9, 2026
