# Phase 2: Stored Procedures - Quick Start

## Overview

Phase 2 creates 5 stored procedures for generating financial reports. These procedures query the database foundation created in Phase 1 to produce standard accounting reports.

## Prerequisites

✅ Phase 1 must be completed:
- Tables created (account_opening_balances, fiscal_periods)
- Accounts classified by type
- Opening balances calculated

## Files Created

1. `backend/sql/financial_reports_procedures.sql` - All 5 stored procedures
2. `backend/sql/run_phase2_procedures.js` - Migration runner with tests

## Stored Procedures

### 1. get_trial_balance
**Purpose**: Generate trial balance for a date range

**Parameters**:
- `p_facility_id` - Facility identifier
- `p_from_date` - Start date
- `p_to_date` - End date

**Returns**: Account code, name, type, opening balance, period debits/credits, closing balance

**Usage**:
```sql
CALL get_trial_balance('facility1', '2026-01-01', '2026-03-31');
```

### 2. get_balance_sheet
**Purpose**: Generate balance sheet as of a specific date

**Parameters**:
- `p_facility_id` - Facility identifier
- `p_as_of_date` - Report date

**Returns**: Assets, Liabilities, Equity with balances and subtypes

**Features**:
- Classifies assets as current or fixed
- Classifies liabilities as current or long-term
- Calculates retained earnings automatically
- Ensures Assets = Liabilities + Equity

**Usage**:
```sql
CALL get_balance_sheet('facility1', '2026-03-31');
```

### 3. get_profit_loss
**Purpose**: Generate profit & loss statement for a date range

**Parameters**:
- `p_facility_id` - Facility identifier
- `p_from_date` - Start date
- `p_to_date` - End date

**Returns**: Revenue, COGS, Expenses with amounts

**Calculations**:
- Total Revenue
- Total COGS
- Gross Profit = Revenue - COGS
- Total Expenses
- Net Profit = Gross Profit - Expenses

**Usage**:
```sql
CALL get_profit_loss('facility1', '2026-01-01', '2026-03-31');
```

### 4. get_cash_flow
**Purpose**: Generate cash flow statement for a date range

**Parameters**:
- `p_facility_id` - Facility identifier
- `p_from_date` - Start date
- `p_to_date` - End date

**Returns**: 
- Cash flows by activity type (Operating, Investing, Financing)
- Opening cash balance
- Net cash flow
- Closing cash balance

**Cash Accounts**: 400021 (Cash), 400022 (Bank), 400025 (Petty Cash)

**Usage**:
```sql
CALL get_cash_flow('facility1', '2026-01-01', '2026-03-31');
```

### 5. close_fiscal_period
**Purpose**: Close a fiscal period and prevent further entries

**Parameters**:
- `p_facility_id` - Facility identifier
- `p_period_name` - Period to close (e.g., '2026-Q1', '2026-01')
- `p_closed_by` - Username of person closing
- `p_notes` - Closing notes

**Actions**:
- Updates closing balances
- Marks period as closed
- Records who closed and when

**Usage**:
```sql
CALL close_fiscal_period('facility1', '2026-Q1', 'admin', 'Q1 closing');
```

## Running the Migration

### Step 1: Ensure Phase 1 is Complete

Verify Phase 1 tables exist:
```sql
SHOW TABLES LIKE 'account_opening_balances';
SHOW TABLES LIKE 'fiscal_periods';
```

### Step 2: Run Migration

```bash
cd backend
node sql/run_phase2_procedures.js
```

### Step 3: Review Output

Expected output:
```
======================================================================
PHASE 2: STORED PROCEDURES MIGRATION
======================================================================

Executing: financial_reports_procedures.sql
✓ Procedures created successfully

======================================================================
Verifying Stored Procedures
======================================================================

✓ Stored Procedures Created:
  - close_fiscal_period (PROCEDURE)
  - get_balance_sheet (PROCEDURE)
  - get_cash_flow (PROCEDURE)
  - get_profit_loss (PROCEDURE)
  - get_trial_balance (PROCEDURE)

✓ All 5 procedures created successfully!

======================================================================
Testing Stored Procedures
======================================================================

Test Facility: facility1
Test Period: 2026-03-01 to 2026-03-08

1. Testing get_trial_balance...
   ✓ Trial Balance: XX accounts

2. Testing get_balance_sheet...
   ✓ Balance Sheet: XX accounts

3. Testing get_profit_loss...
   ✓ Profit & Loss: XX accounts

4. Testing get_cash_flow...
   ✓ Cash Flow: XX activities

======================================================================
✓ PHASE 2 MIGRATION COMPLETED SUCCESSFULLY!
======================================================================
```

## Manual Testing

### Test Trial Balance

```sql
-- Get trial balance for current month
CALL get_trial_balance(
  'your_facility_id',
  DATE_FORMAT(CURDATE(), '%Y-%m-01'),
  LAST_DAY(CURDATE())
);
```

Expected: List of all accounts with opening, debits, credits, closing balances

### Test Balance Sheet

```sql
-- Get balance sheet as of today
CALL get_balance_sheet('your_facility_id', CURDATE());
```

Expected: Assets, Liabilities, Equity sections with balances

### Test Profit & Loss

```sql
-- Get P&L for current quarter
CALL get_profit_loss(
  'your_facility_id',
  DATE_FORMAT(CURDATE() - INTERVAL 3 MONTH, '%Y-%m-01'),
  CURDATE()
);
```

Expected: Revenue, COGS, Expenses with amounts

### Test Cash Flow

```sql
-- Get cash flow for current month
CALL get_cash_flow(
  'your_facility_id',
  DATE_FORMAT(CURDATE(), '%Y-%m-01'),
  LAST_DAY(CURDATE())
);
```

Expected: Operating, Investing, Financing activities with cash flows

## Verification Queries

### Check Procedures Exist

```sql
SELECT ROUTINE_NAME, ROUTINE_TYPE, CREATED
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'prime'
  AND ROUTINE_NAME LIKE 'get_%'
ORDER BY ROUTINE_NAME;
```

### View Procedure Definition

```sql
SHOW CREATE PROCEDURE get_trial_balance;
```

### Check Procedure Parameters

```sql
SELECT 
  PARAMETER_NAME,
  DATA_TYPE,
  PARAMETER_MODE
FROM INFORMATION_SCHEMA.PARAMETERS
WHERE SPECIFIC_SCHEMA = 'prime'
  AND SPECIFIC_NAME = 'get_trial_balance'
ORDER BY ORDINAL_POSITION;
```

## Troubleshooting

### Issue: "Procedure already exists"
**Solution**: Procedures are dropped and recreated. This is normal.

### Issue: "No data returned"
**Solution**: Check that:
1. Phase 1 completed successfully
2. Facility ID is correct
3. Date range contains transactions
4. Accounts are classified

### Issue: "Balance sheet doesn't balance"
**Solution**: 
1. Check retained earnings calculation
2. Verify all accounts are classified
3. Check for unbalanced transactions

### Issue: "Trial balance totals don't match"
**Solution**:
1. Verify opening balances are correct
2. Check transaction data integrity
3. Ensure all transactions are double-entry

## Sample Output

### Trial Balance Sample

```
+---------------+------------------+--------------+------------------+--------------+---------------+------------------+
| account_code  | account_name     | account_type | opening_balance  | period_debit | period_credit | closing_balance  |
+---------------+------------------+--------------+------------------+--------------+---------------+------------------+
| 400021        | Cash in Hand     | asset        |       100,000.00 |    50,000.00 |     30,000.00 |      120,000.00 |
| 400022        | Bank Account     | asset        |       500,000.00 |   200,000.00 |    150,000.00 |      550,000.00 |
| 20001         | Service Revenue  | revenue      |             0.00 |         0.00 |    250,000.00 |     (250,000.00) |
| 30001         | Drug Purchases   | cogs         |             0.00 |    80,000.00 |          0.00 |       80,000.00 |
+---------------+------------------+--------------+------------------+--------------+---------------+------------------+
```

### Balance Sheet Sample

```
ASSETS
  Current Assets
    Cash in Hand                 ₦ 120,000
    Bank Account                 ₦ 550,000
    Accounts Receivable          ₦  50,000
  Total Current Assets           ₦ 720,000
  
  Fixed Assets
    Equipment                    ₦ 500,000
  Total Fixed Assets             ₦ 500,000
  
TOTAL ASSETS                     ₦ 1,220,000

LIABILITIES
  Current Liabilities
    Accounts Payable             ₦  30,000
  Total Current Liabilities      ₦  30,000
  
EQUITY
    Capital                      ₦ 1,000,000
    Retained Earnings            ₦   190,000
  Total Equity                   ₦ 1,190,000
  
TOTAL LIABILITIES + EQUITY       ₦ 1,220,000
```

### Profit & Loss Sample

```
REVENUE
  Service Revenue                ₦ 250,000
Total Revenue                    ₦ 250,000

COST OF GOODS SOLD
  Drug Purchases                 ₦  80,000
Total COGS                       ₦  80,000

GROSS PROFIT                     ₦ 170,000

EXPENSES
  Salaries                       ₦  50,000
  Rent                           ₦  20,000
  Utilities                      ₦  10,000
Total Expenses                   ₦  80,000

NET PROFIT                       ₦  90,000
```

## Performance Notes

- Procedures use indexes created in Phase 1
- Opening balances are pre-calculated (fast retrieval)
- Date range queries are optimized
- Temporary tables used for complex calculations

## Next Steps

After successful Phase 2 completion:

1. ✅ Test all 5 procedures with real data
2. ✅ Verify calculations are correct
3. ✅ Check performance with large datasets
4. ⏭️ Proceed to Phase 3: Backend API implementation

## Phase 3 Preview

Phase 3 will create:
- `backend/controller/financial-reports.js` - Controller functions
- `backend/routes/financial-reports.js` - API routes
- Integration with existing authentication/permissions
- Error handling and validation
- Response formatting

## Support

If you encounter issues:
1. Check the error message in migration output
2. Review troubleshooting section
3. Run manual verification queries
4. Test procedures individually
5. Check MySQL error logs

## Rollback (if needed)

To remove procedures:

```sql
DROP PROCEDURE IF EXISTS get_trial_balance;
DROP PROCEDURE IF EXISTS get_balance_sheet;
DROP PROCEDURE IF EXISTS get_profit_loss;
DROP PROCEDURE IF EXISTS get_cash_flow;
DROP PROCEDURE IF EXISTS close_fiscal_period;
```

**Note**: Procedures can be safely recreated by running the migration again.
