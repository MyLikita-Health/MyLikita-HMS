# Accounting Integration Update

## Overview
Updated inventory management controllers to use proper double-entry bookkeeping by posting directly to the `transactions` table instead of `pending_txn`.

## Problem
The system was using `pending_txn` table (temporary/draft transactions) for accounting entries, which meant:
- Financial reports couldn't see inventory transactions
- Double-entry bookkeeping wasn't properly maintained
- Accounting data was incomplete

## Solution
Updated all inventory controllers to post directly to `transactions` table with proper debit/credit entries.

---

## Files Updated

### 1. backend/controller/inventory-grn.js
**Goods Receipt Note (GRN) - Receiving Inventory**

**Accounting Entry:**
```
When goods are received:
Debit:  Inventory Asset (400024)     ₦X,XXX  [Increase Asset]
Credit: Accounts Payable (500021)    ₦X,XXX  [Increase Liability]
```

**Changes:**
- Removed `CALL pending_txn()` stored procedure calls
- Added direct INSERT into `transactions` table
- Proper double-entry: Debit Inventory, Credit Accounts Payable
- Receipt number format: `GRN-{grn_number}`

---

### 2. backend/controller/inventory-issue.js
**Inventory Issue - Dispensing to Patients/Departments**

**Accounting Entry:**
```
When inventory is issued:
Debit:  Cost of Goods Sold (700001)  ₦X,XXX  [Increase Expense]
Credit: Inventory Asset (400024)     ₦X,XXX  [Decrease Asset]
```

**Changes:**
- Removed `CALL pending_txn()` stored procedure calls
- Added direct INSERT into `transactions` table
- Proper double-entry: Debit COGS, Credit Inventory
- Receipt number format: `ISSUE-{transaction_id}`

---

### 3. backend/controller/inventory-requisitions.js
**Internal Requisitions - Department to Department**

**Accounting Entry:**
```
When requisition is fulfilled:
Debit:  Department Expense (700001)  ₦X,XXX  [Increase Expense]
Credit: Inventory Asset (400024)     ₦X,XXX  [Decrease Asset]
```

**Changes:**
- Removed `CALL pending_txn()` stored procedure calls
- Added direct INSERT into `transactions` table
- Proper double-entry: Debit Department Expense, Credit Inventory
- Receipt number format: `REQ-{requisition_number}`

---

### 4. backend/controller/inventory.js
**Stock Adjustments - Inventory Count Corrections**

**Accounting Entry (Positive Adjustment - Increase):**
```
When inventory increases:
Debit:  Inventory Asset (400024)           ₦X,XXX  [Increase Asset]
Credit: Inventory Adjustment Income (800001) ₦X,XXX  [Income]
```

**Accounting Entry (Negative Adjustment - Decrease):**
```
When inventory decreases:
Debit:  Inventory Adjustment Expense (800002) ₦X,XXX  [Expense]
Credit: Inventory Asset (400024)              ₦X,XXX  [Decrease Asset]
```

**Changes:**
- Removed `CALL pending_txn()` stored procedure call
- Added direct INSERT into `transactions` table
- Proper double-entry with conditional logic for positive/negative adjustments
- Receipt number format: `ADJ-{adjustment_number}`

---

## Account Codes Used

### Assets
- **400024** - Inventory Asset (default)
- Can be customized per item via `item.account_head`

### Liabilities
- **500021** - Accounts Payable (default)
- Can be customized per supplier via `grn.supplier_account`

### Expenses
- **700001** - Cost of Goods Sold / Department Expense (default)
- Can be customized per item via `item.cogs_account`

### Adjustment Accounts
- **800001** - Inventory Adjustment Income (positive adjustments)
- **800002** - Inventory Adjustment Expense (negative adjustments)
- Can be customized per item via `item.adjustment_account`

---

## Impact on Financial Reports

All financial reports now properly include inventory transactions:

### Trial Balance
- Shows inventory asset balances
- Shows accounts payable to suppliers
- Shows COGS and adjustment expenses

### Balance Sheet
- **Assets:** Inventory value
- **Liabilities:** Accounts payable to suppliers

### Profit & Loss
- **Expenses:** COGS from inventory issues
- **Expenses:** Inventory adjustment losses
- **Income:** Inventory adjustment gains

### Cash Flow
- Operating activities include inventory-related cash flows
- Accounts payable changes reflected in financing activities

---

## Data Flow

### Old Flow (Incorrect)
```
Inventory Transaction → pending_txn → (never moved to transactions)
Financial Reports → transactions → (missing inventory data)
```

### New Flow (Correct)
```
Inventory Transaction → transactions (with debit/credit)
Financial Reports → transactions → (includes all inventory data)
```

---

## Testing Checklist

- [ ] Create GRN and verify transactions table has debit/credit entries
- [ ] Issue inventory and verify COGS is debited, Inventory credited
- [ ] Fulfill requisition and verify department expense recorded
- [ ] Perform stock adjustment and verify proper accounting entry
- [ ] Run Trial Balance and verify inventory accounts appear
- [ ] Run Balance Sheet and verify inventory asset value
- [ ] Run P&L and verify COGS appears
- [ ] Verify all entries have matching debit/credit amounts

---

## Notes

1. **pending_txn table** is still used for billing workflow (draft bills before payment)
2. **transactions table** is the source of truth for all accounting and financial reports
3. All inventory transactions now use proper double-entry bookkeeping
4. Receipt numbers are unique and traceable to source documents
5. Status is set to 'completed' for all inventory accounting entries

---

## Next Steps

Consider updating other modules that may still use `pending_txn` for accounting:
- `backend/controller/record.js` - Patient billing
- `backend/controller/dental.js` - Dental procedures
- `backend/controller/account.js` - Payment processing

These should follow the same pattern: use `pending_txn` for draft bills, move to `transactions` when payment is made.
