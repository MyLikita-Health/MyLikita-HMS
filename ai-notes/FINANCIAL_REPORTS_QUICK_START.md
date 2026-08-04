# Financial Reports Implementation - Quick Start Guide

## Overview

This guide provides a streamlined implementation plan for generating standard financial reports:
- Trial Balance
- Balance Sheet (Statement of Financial Position)
- Profit & Loss Account (Income Statement)
- Cash Flow Statement

## Current System Status

### ✅ What Exists
- Basic transaction recording (`transactions` table)
- Account chart (`account` table)
- Trial balance view (partial)
- Daily/monthly summaries
- Customer/Supplier balances

### ❌ What's Missing
- Opening balances tracking
- Fiscal period management
- Complete financial statement procedures
- Account type classification
- Cash flow tracking

## Implementation Phases

### Phase 1: Database Setup (2-3 days)

**File**: `backend/sql/financial_reports_schema.sql`

Create three new tables:
1. `account_opening_balances` - Track period opening balances
2. `fiscal_periods` - Manage accounting periods
3. Enhance `account` table with `account_type` field

### Phase 2: Stored Procedures (3-4 days)

**File**: `backend/sql/financial_reports_procedures.sql`

Create 5 stored procedures:
1. `get_trial_balance(facilityId, from_date, to_date)`
2. `get_balance_sheet(facilityId, as_of_date)`
3. `get_profit_loss(facilityId, from_date, to_date)`
4. `get_cash_flow(facilityId, from_date, to_date)`
5. `close_fiscal_period(facilityId, period_name)`


### Phase 3: Backend API (2-3 days)

**File**: `backend/controller/financial-reports.js`

Add controller functions:
```javascript
exports.getTrialBalance = async (req, res) => {
  const { facilityId, from, to } = req.params;
  // Call stored procedure
  // Format and return data
};

exports.getBalanceSheet = async (req, res) => {
  const { facilityId, asOfDate } = req.params;
  // Call stored procedure
  // Calculate totals
  // Return formatted data
};

exports.getProfitLoss = async (req, res) => {
  const { facilityId, from, to } = req.params;
  // Call stored procedure
  // Calculate gross profit, net profit
  // Return formatted data
};

exports.getCashFlow = async (req, res) => {
  const { facilityId, from, to } = req.params;
  // Call stored procedure
  // Categorize cash flows
  // Return formatted data
};
```

**File**: `backend/routes/financial-reports.js`

Add routes with permissions:
```javascript
app.get('/financial-reports/trial-balance/:from/:to/:facilityId', 
  authenticate,
  checkPermission('billing', 'reports', 'view'),
  financialReports.getTrialBalance
);

app.get('/financial-reports/balance-sheet/:asOfDate/:facilityId',
  authenticate,
  checkPermission('billing', 'reports', 'view'),
  financialReports.getBalanceSheet
);

app.get('/financial-reports/profit-loss/:from/:to/:facilityId',
  authenticate,
  checkPermission('billing', 'reports', 'view'),
  financialReports.getProfitLoss
);

app.get('/financial-reports/cash-flow/:from/:to/:facilityId',
  authenticate,
  checkPermission('billing', 'reports', 'view'),
  financialReports.getCashFlow
);
```


### Phase 4: Frontend Components (4-5 days)

**File**: `frontend/src/components/financial-reports/FinancialReportsDashboard.jsx`

Main dashboard with report selection and date range picker.

**File**: `frontend/src/components/financial-reports/TrialBalance.jsx`

Display trial balance with:
- Account hierarchy
- Opening balances
- Period debits/credits
- Closing balances
- Export to Excel/PDF

**File**: `frontend/src/components/financial-reports/BalanceSheet.jsx`

Display balance sheet with:
- Assets section (Current + Fixed)
- Liabilities section (Current + Long-term)
- Equity section
- Total calculations
- Export functionality

**File**: `frontend/src/components/financial-reports/ProfitLoss.jsx`

Display P&L with:
- Revenue section
- COGS section
- Gross Profit calculation
- Operating Expenses
- Net Profit calculation
- Comparative periods
- Export functionality

**File**: `frontend/src/components/financial-reports/CashFlow.jsx`

Display cash flow with:
- Operating activities
- Investing activities
- Financing activities
- Net cash flow
- Export functionality


## Key Implementation Details

### Account Type Mapping

Update existing accounts with proper types:

```sql
-- Revenue accounts (20000 series)
UPDATE account SET account_type = 'revenue' 
WHERE head LIKE '20%' AND facilityId = ?;

-- COGS accounts (30000 series)
UPDATE account SET account_type = 'cogs' 
WHERE head LIKE '30%' AND facilityId = ?;

-- Asset accounts (40000 series)
UPDATE account SET account_type = 'asset' 
WHERE head LIKE '40%' AND facilityId = ?;

-- Liability accounts (50000 series)
UPDATE account SET account_type = 'liability' 
WHERE head LIKE '50%' AND facilityId = ?;

-- Expense accounts
UPDATE account SET account_type = 'expense' 
WHERE parent_account = 'Expenses' AND facilityId = ?;
```

### Opening Balances Setup

For first-time setup, calculate opening balances:

```sql
INSERT INTO account_opening_balances 
  (facilityId, fiscal_year, fiscal_period, account_code, opening_balance)
SELECT 
  facilityId,
  YEAR(CURDATE()) as fiscal_year,
  CONCAT(YEAR(CURDATE()), '-01') as fiscal_period,
  acct as account_code,
  SUM(debit - credit) as opening_balance
FROM transactions
WHERE facilityId = ?
  AND DATE(transaction_date) < '2024-01-01'
GROUP BY facilityId, acct;
```

### Fiscal Period Management

Create fiscal periods:

```sql
INSERT INTO fiscal_periods (facilityId, period_name, start_date, end_date)
VALUES 
  (?, 'FY2024-Q1', '2024-01-01', '2024-03-31'),
  (?, 'FY2024-Q2', '2024-04-01', '2024-06-30'),
  (?, 'FY2024-Q3', '2024-07-01', '2024-09-30'),
  (?, 'FY2024-Q4', '2024-10-01', '2024-12-31');
```


## Testing Checklist

### Trial Balance
- [ ] Shows all active accounts
- [ ] Opening balances are correct
- [ ] Period debits/credits match transactions
- [ ] Closing balances calculated correctly
- [ ] Total debits = Total credits
- [ ] Export to Excel works
- [ ] Date range filtering works

### Balance Sheet
- [ ] Assets section complete
- [ ] Liabilities section complete
- [ ] Equity section complete
- [ ] Assets = Liabilities + Equity
- [ ] Retained earnings calculated
- [ ] Export functionality works
- [ ] As-of-date filtering works

### Profit & Loss
- [ ] Revenue section complete
- [ ] COGS section complete
- [ ] Gross profit calculated
- [ ] Operating expenses listed
- [ ] Net profit calculated
- [ ] Period comparison works
- [ ] Export functionality works

### Cash Flow
- [ ] Operating activities categorized
- [ ] Investing activities categorized
- [ ] Financing activities categorized
- [ ] Net cash flow calculated
- [ ] Opening/closing cash balances match
- [ ] Export functionality works

## Timeline Summary

- **Week 1**: Database schema + Account type mapping
- **Week 2**: Stored procedures + Testing
- **Week 3**: Backend API + Routes
- **Week 4**: Frontend components
- **Week 5**: Testing + Bug fixes
- **Week 6**: User training + Documentation

**Total Duration**: 6 weeks

## Next Steps

1. Review and approve this plan
2. Create database migration scripts
3. Set up development environment
4. Begin Phase 1 implementation
5. Schedule weekly progress reviews

