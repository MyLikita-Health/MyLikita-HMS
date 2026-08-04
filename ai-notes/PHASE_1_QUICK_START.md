# Phase 1: Database Foundation - Quick Start

## Overview

Phase 1 creates the database foundation for financial reporting by:
- Creating 2 new tables for opening balances and fiscal periods
- Adding 5 columns to existing tables for account classification
- Classifying all existing accounts by type
- Calculating opening balances for the current fiscal year

## Files Created

### SQL Migration Files
1. `backend/sql/financial_reports_schema.sql` - Creates tables and columns
2. `backend/sql/classify_accounts.sql` - Classifies existing accounts
3. `backend/sql/setup_opening_balances.sql` - Calculates opening balances

### Migration Runner
4. `backend/sql/run_financial_reports_migration.js` - Executes all migrations

## Running the Migration

### Step 1: Verify Prerequisites

Ensure you have:
- MySQL running locally
- Database name: `prime`
- User: `root` with no password
- Node.js installed

### Step 2: Run Migration

```bash
cd backend
node sql/run_financial_reports_migration.js
```

### Step 3: Review Output

The script will:
1. Execute all 3 SQL files in order
2. Display results from each file
3. Verify the migration was successful
4. Show summary statistics

Expected output:
```
======================================================================
FINANCIAL REPORTS MIGRATION - PHASE 1
======================================================================

Executing: financial_reports_schema.sql
✓ financial_reports_schema.sql executed successfully

Executing: classify_accounts.sql
✓ classify_accounts.sql executed successfully

Executing: setup_opening_balances.sql
✓ setup_opening_balances.sql executed successfully

======================================================================
Verifying Migration Results
======================================================================

✓ Tables Created:
  - account_opening_balances
  - fiscal_periods

✓ Columns Added to account table:
  - account_type
  - is_active
  - parent_code
  - display_order
  - is_control_account

✓ Account Classification:
┌─────────┬──────────────┬───────┐
│ (index) │ account_type │ count │
├─────────┼──────────────┼───────┤
│    0    │   'asset'    │  XX   │
│    1    │ 'liability'  │  XX   │
│    2    │   'equity'   │  XX   │
│    3    │  'revenue'   │  XX   │
│    4    │    'cogs'    │  XX   │
│    5    │  'expense'   │  XX   │
└─────────┴──────────────┴───────┘

✓ Opening Balances Created:
┌─────────┬───────────────┬────────────────┬──────────────┐
│ (index) │ periods_count │ accounts_count │ total_records│
├─────────┼───────────────┼────────────────┼──────────────┤
│    0    │      17       │      XX        │     XXX      │
└─────────┴───────────────┴────────────────┴──────────────┘

✓ Fiscal Periods Created:
┌─────────┬─────────────┬───────┐
│ (index) │ period_type │ count │
├─────────┼─────────────┼───────┤
│    0    │  'yearly'   │   1   │
│    1    │ 'quarterly' │   4   │
│    2    │  'monthly'  │  12   │
└─────────┴─────────────┴───────┘

======================================================================
✓ ALL MIGRATIONS COMPLETED SUCCESSFULLY!
======================================================================
```

## What Was Created

### 1. New Tables

#### account_opening_balances
Stores opening balances for each account in each fiscal period.

Columns:
- `facilityId` - Facility identifier
- `fiscal_year` - Year (e.g., 2026)
- `fiscal_period` - Period name (e.g., FY2026, 2026-Q1, 2026-01)
- `account_code` - Account code (links to account.head)
- `opening_balance` - Balance at start of period
- `debit_total` - Total debits in period
- `credit_total` - Total credits in period
- `closing_balance` - Balance at end of period

#### fiscal_periods
Manages accounting periods.

Columns:
- `facilityId` - Facility identifier
- `period_name` - Period name (e.g., FY2026, Q1-2026)
- `period_type` - Type (monthly, quarterly, yearly)
- `start_date` - Period start date
- `end_date` - Period end date
- `is_closed` - Whether period is closed
- `closed_by` - User who closed the period
- `closed_at` - When period was closed

### 2. Enhanced account Table

New columns added:
- `account_type` - Classification (asset, liability, equity, revenue, expense, cogs)
- `is_active` - Whether account is active
- `parent_code` - Parent account for hierarchy
- `display_order` - Order for report display
- `is_control_account` - Whether this is a summary account

### 3. Enhanced transactions Table

New column added:
- `cash_flow_category` - Category for cash flow statement (operating, investing, financing, non-cash)

## Verification Steps

### Check Account Classification

```sql
SELECT 
  account_type,
  COUNT(*) as count,
  GROUP_CONCAT(DISTINCT SUBSTRING(head, 1, 2) ORDER BY head) as prefixes
FROM account
WHERE facilityId IS NOT NULL
GROUP BY account_type;
```

Expected: All accounts should be classified into one of 6 types.

### Check Unclassified Accounts

```sql
SELECT head, description, 'NEEDS CLASSIFICATION' as status
FROM account
WHERE account_type IS NULL
  AND facilityId IS NOT NULL;
```

Expected: Should return 0 rows (or very few that need manual classification).

### Check Opening Balances

```sql
SELECT 
  fiscal_period,
  COUNT(DISTINCT account_code) as accounts,
  SUM(opening_balance) as total_opening,
  SUM(closing_balance) as total_closing
FROM account_opening_balances
WHERE fiscal_year = YEAR(CURDATE())
GROUP BY fiscal_period
ORDER BY fiscal_period;
```

Expected: Should show balances for yearly, quarterly, and monthly periods.

### Check Fiscal Periods

```sql
SELECT 
  period_name,
  period_type,
  start_date,
  end_date,
  is_closed
FROM fiscal_periods
ORDER BY start_date;
```

Expected: Should show 17 periods (1 yearly + 4 quarterly + 12 monthly).

## Troubleshooting

### Issue: "Table already exists"
**Solution**: Tables have safe creation with `IF NOT EXISTS`. This is normal if running migration multiple times.

### Issue: "Column already exists"
**Solution**: Script checks for existing columns before adding. This is normal if running migration multiple times.

### Issue: "No accounts classified"
**Solution**: Check that your account table has data and facilityId is not NULL.

### Issue: "No opening balances created"
**Solution**: Check that:
1. Account table has `is_active = TRUE`
2. Transactions table has historical data
3. facilityId matches between account and transactions

### Issue: "Connection refused"
**Solution**: Ensure MySQL is running:
```bash
# macOS
brew services start mysql

# Check status
mysql -u root -e "SELECT 1"
```

## Manual Verification Queries

### View Sample Opening Balances

```sql
SELECT 
  aob.fiscal_period,
  aob.account_code,
  a.description,
  a.account_type,
  aob.opening_balance,
  aob.debit_total,
  aob.credit_total,
  aob.closing_balance
FROM account_opening_balances aob
JOIN account a ON a.head = aob.account_code AND a.facilityId = aob.facilityId
WHERE aob.fiscal_year = YEAR(CURDATE())
  AND aob.fiscal_period = CONCAT('FY', YEAR(CURDATE()))
ORDER BY ABS(aob.closing_balance) DESC
LIMIT 20;
```

### View Account Hierarchy

```sql
SELECT 
  a.head,
  a.description,
  a.account_type,
  a.parent_code,
  p.description as parent_description,
  a.is_control_account
FROM account a
LEFT JOIN account p ON p.head = a.parent_code AND p.facilityId = a.facilityId
WHERE a.facilityId IS NOT NULL
  AND a.is_active = TRUE
ORDER BY a.account_type, a.display_order, a.head;
```

### Check Trial Balance Readiness

```sql
SELECT 
  a.account_type,
  COUNT(*) as accounts,
  SUM(CASE WHEN aob.opening_balance IS NOT NULL THEN 1 ELSE 0 END) as with_opening_balance
FROM account a
LEFT JOIN account_opening_balances aob 
  ON aob.account_code = a.head 
  AND aob.facilityId = a.facilityId
  AND aob.fiscal_year = YEAR(CURDATE())
WHERE a.facilityId IS NOT NULL
  AND a.is_active = TRUE
GROUP BY a.account_type;
```

Expected: All accounts should have opening balances.

## Next Steps

After successful Phase 1 completion:

1. ✅ Review verification results
2. ✅ Check for unclassified accounts (manually classify if needed)
3. ✅ Verify opening balances match expectations
4. ⏭️ Proceed to Phase 2: Create stored procedures for financial reports

## Phase 2 Preview

Phase 2 will create 5 stored procedures:
1. `get_trial_balance()` - Generate trial balance report
2. `get_balance_sheet()` - Generate balance sheet
3. `get_profit_loss()` - Generate P&L statement
4. `get_cash_flow()` - Generate cash flow statement
5. `close_fiscal_period()` - Close accounting periods

## Support

If you encounter issues:
1. Check the error message in the migration output
2. Review the troubleshooting section above
3. Run manual verification queries
4. Check MySQL error logs if needed

## Rollback (if needed)

To rollback Phase 1 changes:

```sql
-- Drop new tables
DROP TABLE IF EXISTS account_opening_balances;
DROP TABLE IF EXISTS fiscal_periods;

-- Remove added columns
ALTER TABLE account 
  DROP COLUMN IF EXISTS account_type,
  DROP COLUMN IF EXISTS is_active,
  DROP COLUMN IF EXISTS parent_code,
  DROP COLUMN IF EXISTS display_order,
  DROP COLUMN IF EXISTS is_control_account;

ALTER TABLE transactions
  DROP COLUMN IF EXISTS cash_flow_category;
```

**Note**: Only rollback if absolutely necessary. The changes are non-destructive and don't modify existing data.
