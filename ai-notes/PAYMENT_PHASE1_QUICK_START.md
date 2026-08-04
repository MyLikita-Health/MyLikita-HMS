# Payment System Phase 1 - Quick Start Guide

## What Changed

The payment system now uses proper double-entry bookkeeping, posting directly to the `transactions` table instead of `pending_txn`. This means all payments will now appear in financial reports.

---

## Testing the Changes

### 1. Test Regular Cash Payment

1. Go to Account Review page
2. Select a pending transaction
3. Click "Pay now"
4. Select payment mode: **CASH**
5. Enter amount
6. Submit

**Expected Result:**
- Payment successful
- Check `transactions` table:
  ```sql
  SELECT * FROM transactions 
  WHERE receiptNo = 'YOUR_RECEIPT_NO' 
  ORDER BY transaction_id DESC LIMIT 2;
  ```
- Should see 2 entries:
  - Debit: 400021 (Cash)
  - Credit: 20XXX (Revenue)

---

### 2. Test BILL Mode - Retainership Patient

1. Select a transaction for a retainership patient
2. Click "Pay now"
3. Select payment mode: **BILL** (or "Add to Bill")
4. Submit

**Expected Result:**
- Payment successful
- Check `transactions` table - should see:
  - Debit: 500022 (Patient Deposits)
  - Credit: 20XXX (Revenue)
- Check patient balance:
  ```sql
  SELECT balance FROM patientrecords WHERE id = 'PATIENT_ID';
  ```
- Balance should be reduced

---

### 3. Test BILL Mode - Credit Patient

1. Select a transaction for a non-retainership patient
2. Click "Pay now"
3. Select payment mode: **BILL**
4. Submit

**Expected Result:**
- Payment successful
- Check `transactions` table - should see:
  - Debit: 400023 (Accounts Receivable)
  - Credit: 20XXX (Revenue)

---

### 4. Test Split Payment (POS and Cash)

1. Select a transaction
2. Click "Pay now"
3. Select payment mode: **POS and Cash**
4. Enter POS amount: 5000
5. Enter Cash amount: 3000
6. Total should be: 8000
7. Submit

**Expected Result:**
- Payment successful
- Check `transactions` table - should see 3 entries:
  - Debit: 400021 (Cash) - 3000
  - Debit: 400022 (Bank/POS) - 5000
  - Credit: 20XXX (Revenue) - 8000

---

### 5. Test Discount

1. Select a transaction
2. Click "Pay now"
3. Select a discount from dropdown
4. Discount should be applied to amount
5. Submit

**Expected Result:**
- Payment successful
- Check `transactions` table - should see 4 entries:
  - Debit: 400021 (Cash) - discounted amount
  - Credit: 20XXX (Revenue) - discounted amount
  - Debit: 800003 (Discount Expense) - discount amount
  - Credit: 20XXX (Revenue) - discount amount

---

## Verify in Financial Reports

### Trial Balance
```
Go to: Financial Reports → Trial Balance
Date Range: Today

Expected to see:
- Cash (400021) - Debit balance
- Bank (400022) - Debit balance (if POS/Bank payments)
- Accounts Receivable (400023) - Debit balance (if BILL mode)
- Patient Deposits (500022) - Credit balance (if retainership)
- Revenue accounts (20XXX) - Credit balance
- Discount Expense (800003) - Debit balance (if discounts)
```

### Balance Sheet
```
Go to: Financial Reports → Balance Sheet
As of: Today

Expected to see:
Assets:
- Cash
- Bank
- Accounts Receivable

Liabilities:
- Patient Deposits

Equity:
- Retained Earnings (includes revenue)
```

### Profit & Loss
```
Go to: Financial Reports → Profit & Loss
Date Range: This month

Expected to see:
Revenue:
- Registration Revenue
- Consultation Revenue
- Laboratory Revenue
- Pharmacy Revenue
- Dental Revenue
- Shop Revenue

Expenses:
- Discount Expense (if any)

Net Profit = Total Revenue - Total Expenses
```

---

## Troubleshooting

### Issue: Payment fails with "Insufficient balance"
**Cause:** Retainership patient doesn't have enough balance
**Solution:** Add deposit to patient account first

### Issue: Split payment fails with "amounts do not match total"
**Cause:** POS amount + Cash amount ≠ Total amount
**Solution:** Ensure split amounts add up to total

### Issue: Transactions not appearing in reports
**Cause:** Wrong date range selected
**Solution:** Check transaction_date in transactions table and adjust report date range

### Issue: Duplicate entries in transactions table
**Cause:** Payment submitted multiple times
**Solution:** Check for duplicate receiptNo values

---

## SQL Queries for Verification

### Check Recent Payments
```sql
SELECT 
  transaction_date,
  description,
  acct,
  debit,
  credit,
  receiptNo,
  modeOfPayment,
  patient_id
FROM transactions
WHERE transaction_date = CURDATE()
ORDER BY createdAt DESC
LIMIT 20;
```

### Check Patient Balance
```sql
SELECT 
  id,
  patient_name,
  patient_type,
  balance
FROM patientrecords
WHERE id = 'PATIENT_ID';
```

### Check Accounts Receivable
```sql
SELECT 
  SUM(debit - credit) as total_receivable
FROM transactions
WHERE acct = '400023'
  AND facilityId = 'YOUR_FACILITY_ID';
```

### Check Revenue by Service Type
```sql
SELECT 
  acct,
  description,
  SUM(credit - debit) as total_revenue
FROM transactions
WHERE acct LIKE '200%'
  AND transaction_date BETWEEN '2026-03-01' AND '2026-03-31'
GROUP BY acct
ORDER BY acct;
```

---

## Account Codes Reference

### Assets (Debit increases)
- 400021 - Cash
- 400022 - Bank/POS
- 400023 - Accounts Receivable
- 400024 - Inventory

### Liabilities (Credit increases)
- 500021 - Accounts Payable
- 500022 - Patient Deposits

### Revenue (Credit increases)
- 20001 - Registration
- 20002 - Consultation
- 20003 - Laboratory
- 20004 - Pharmacy
- 20005 - Dental
- 20006 - Shop

### Expenses (Debit increases)
- 700001 - COGS
- 800003 - Discount Expense

---

## Next Steps

1. Test all payment scenarios above
2. Verify entries in transactions table
3. Check financial reports for accuracy
4. Monitor for any errors in production
5. Train cashiers on new BILL mode behavior

---

## Support

If you encounter issues:
1. Check browser console for errors
2. Check backend logs for errors
3. Verify database entries
4. Review this guide for expected behavior
