# Accounting & Financial Reports Implementation Plan

## Executive Summary

This document provides a comprehensive analysis of the existing accounting module and a detailed implementation plan for generating standard financial reports including Trial Balance, Balance Sheet, Profit & Loss Account, Cash Flow Statement, and Statement of Financial Position.

## Current System Analysis

### Database Structure

#### Core Accounting Tables

1. **`account` table** - Chart of Accounts
   - Stores account heads with hierarchical structure
   - Fields: `head`, `subhead`, `description`, `balance`, `price`, `facilityId`
   - Hierarchical structure: Main heads (10000) → Sub heads → Detail accounts

2. **`transactions` table** - All Financial Transactions
   - Records all debit/credit transactions
   - Fields: `acct`, `debit`, `credit`, `description`, `receiptDateSN`, `modeOfPayment`, `enteredBy`, `client_acct`, `patient_id`, `transaction_date`, `facilityId`
   - Links to account heads via `acct` field

3. **`account_entries` table** - Detailed Transaction Entries
   - Granular transaction records
   - Fields: `acct`, `dr`, `cr`, `reference_no`, `description`, `quantity`, `client_id`, `txn_status`, `facilityId`

4. **`trial_balance` view** - Aggregated View
   - Virtual view combining transactions with account descriptions
   - Pre-calculates debits, credits, and account classifications
   - Used for reporting queries

5. **`patientfileno` table** - Customer/Client Accounts
   - Tracks customer balances (receivables/payables)
   - Fields: `accountNo`, `accName`, `balance`, `accountType`, `facilityId`

6. **`suppliersinfo` table** - Supplier Accounts
   - Tracks supplier balances (payables/receivables)
   - Fields: `id`, `supplier_name`, `balance`, `facilityId`


### Account Classification System

The system uses a hierarchical account code structure:

```
10000 - Main Account Heads
  ├── 20000 - Revenue/Income
  │   ├── 20001 - Service Revenue
  │   ├── 20002 - Product Sales
  │   └── 200XX - Other Revenue
  │
  ├── 30000 - Cost of Goods Sold (COGS)
  │   ├── 30001 - Drug Purchases
  │   ├── 30002 - Inventory Costs
  │   └── 300XX - Other COGS
  │
  ├── 40000 - Assets
  │   ├── 400021 - Cash
  │   ├── 400022 - Bank
  │   ├── 400023 - Receivables
  │   ├── 400025 - Petty Cash
  │   └── 40001 - Fixed Assets
  │
  └── 50000 - Liabilities & Equity
      ├── 500011 - Payables
      ├── 50002 - Equity
      └── 500XX - Other Liabilities
```

### Existing Functionality

#### Available Reports (Partial)
1. **Daily Summary** - Revenue, expenses, purchases
2. **User Summary** - Per-user transaction summary
3. **Supplier Reports** - Payables, payment history
4. **Customer Reports** - Receivables, credit balances
5. **Expense Reports** - Categorized expenses
6. **Trial Balance** (Basic) - Account-wise debit/credit totals

#### Missing Reports (To Be Implemented)
1. ✗ Complete Trial Balance with opening/closing balances
2. ✗ Balance Sheet (Statement of Financial Position)
3. ✗ Profit & Loss Account (Income Statement)
4. ✗ Cash Flow Statement
5. ✗ Statement of Changes in Equity


## Implementation Plan

### Phase 1: Database Schema Enhancement (Week 1)

#### 1.1 Create Opening Balances Table

```sql
CREATE TABLE IF NOT EXISTS account_opening_balances (
  id INT PRIMARY KEY AUTO_INCREMENT,
  facilityId VARCHAR(100) NOT NULL,
  fiscal_year INT NOT NULL,
  fiscal_period VARCHAR(20) NOT NULL COMMENT 'e.g., 2024-Q1, 2024-01',
  account_code VARCHAR(100) NOT NULL,
  opening_balance DECIMAL(15,2) DEFAULT 0,
  debit_total DECIMAL(15,2) DEFAULT 0,
  credit_total DECIMAL(15,2) DEFAULT 0,
  closing_balance DECIMAL(15,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_facility_year (facilityId, fiscal_year),
  INDEX idx_account (account_code),
  UNIQUE KEY unique_period_account (facilityId, fiscal_period, account_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### 1.2 Create Fiscal Periods Table

```sql
CREATE TABLE IF NOT EXISTS fiscal_periods (
  id INT PRIMARY KEY AUTO_INCREMENT,
  facilityId VARCHAR(100) NOT NULL,
  period_name VARCHAR(50) NOT NULL COMMENT 'e.g., FY2024, Q1-2024',
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_closed BOOLEAN DEFAULT FALSE,
  closed_by VARCHAR(100),
  closed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_facility (facilityId),
  INDEX idx_dates (start_date, end_date),
  UNIQUE KEY unique_facility_period (facilityId, period_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### 1.3 Enhance Account Table

```sql
ALTER TABLE account 
ADD COLUMN IF NOT EXISTS account_type ENUM('asset', 'liability', 'equity', 'revenue', 'expense', 'cogs') 
  COMMENT 'Account classification for financial statements',
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS parent_code VARCHAR(100) COMMENT 'For hierarchical reporting',
ADD COLUMN IF NOT EXISTS display_order INT DEFAULT 0,
ADD INDEX idx_account_type (account_type),
ADD INDEX idx_parent (parent_code);
```


### Phase 2: Stored Procedures for Financial Reports (Week 2)

#### 2.1 Trial Balance Procedure

```sql
DELIMITER $$

CREATE PROCEDURE get_trial_balance(
  IN in_facilityId VARCHAR(100),
  IN in_from_date DATE,
  IN in_to_date DATE
)
BEGIN
  -- Get opening balances
  WITH opening_balances AS (
    SELECT 
      account_code,
      opening_balance
    FROM account_opening_balances
    WHERE facilityId = in_facilityId
      AND fiscal_period = (
        SELECT period_name 
        FROM fiscal_periods 
        WHERE facilityId = in_facilityId 
          AND start_date <= in_from_date 
        ORDER BY start_date DESC 
        LIMIT 1
      )
  ),
  -- Get period transactions
  period_transactions AS (
    SELECT 
      acct as account_code,
      SUM(debit) as total_debit,
      SUM(credit) as total_credit
    FROM transactions
    WHERE facilityId = in_facilityId
      AND DATE(transaction_date) BETWEEN in_from_date AND in_to_date
    GROUP BY acct
  )
  -- Combine and calculate
  SELECT 
    a.head as account_code,
    a.description as account_name,
    a.subhead as parent_code,
    a.account_type,
    COALESCE(ob.opening_balance, 0) as opening_balance,
    COALESCE(pt.total_debit, 0) as period_debit,
    COALESCE(pt.total_credit, 0) as period_credit,
    COALESCE(ob.opening_balance, 0) + COALESCE(pt.total_debit, 0) - COALESCE(pt.total_credit, 0) as closing_balance
  FROM account a
  LEFT JOIN opening_balances ob ON a.head = ob.account_code
  LEFT JOIN period_transactions pt ON a.head = pt.account_code
  WHERE a.facilityId = in_facilityId
    AND a.is_active = TRUE
  ORDER BY a.head;
END$$

DELIMITER ;
```


#### 2.2 Balance Sheet Procedure

```sql
DELIMITER $$

CREATE PROCEDURE get_balance_sheet(
  IN in_facilityId VARCHAR(100),
  IN in_as_of_date DATE
)
BEGIN
  -- Assets
  SELECT 
    'ASSETS' as section,
    a.description as account_name,
    a.head as account_code,
    SUM(COALESCE(t.debit, 0) - COALESCE(t.credit, 0)) as balance
  FROM account a
  LEFT JOIN transactions t ON a.head = t.acct 
    AND t.facilityId = in_facilityId
    AND DATE(t.transaction_date) <= in_as_of_date
  WHERE a.facilityId = in_facilityId
    AND a.account_type = 'asset'
    AND a.is_active = TRUE
  GROUP BY a.head, a.description
  
  UNION ALL
  
  -- Liabilities
  SELECT 
    'LIABILITIES' as section,
    a.description as account_name,
    a.head as account_code,
    SUM(COALESCE(t.credit, 0) - COALESCE(t.debit, 0)) as balance
  FROM account a
  LEFT JOIN transactions t ON a.head = t.acct 
    AND t.facilityId = in_facilityId
    AND DATE(t.transaction_date) <= in_as_of_date
  WHERE a.facilityId = in_facilityId
    AND a.account_type = 'liability'
    AND a.is_active = TRUE
  GROUP BY a.head, a.description
  
  UNION ALL
  
  -- Equity
  SELECT 
    'EQUITY' as section,
    a.description as account_name,
    a.head as account_code,
    SUM(COALESCE(t.credit, 0) - COALESCE(t.debit, 0)) as balance
  FROM account a
  LEFT JOIN transactions t ON a.head = t.acct 
    AND t.facilityId = in_facilityId
    AND DATE(t.transaction_date) <= in_as_of_date
  WHERE a.facilityId = in_facilityId
    AND a.account_type = 'equity'
    AND a.is_active = TRUE
  GROUP BY a.head, a.description
  
  ORDER BY section, account_code;
END$$

DELIMITER ;
```


#### 2.3 Profit & Loss Statement Procedure

```sql
DELIMITER $$

CREATE PROCEDURE get_profit_loss_statement(
  IN in_facilityId VARCHAR(100),
  IN in_from_date DATE,
  IN in_to_date DATE
)
BEGIN
  -- Revenue
  SELECT 
    'REVENUE' as section,
    a.description as account_name,
    a.head as account_code,
    SUM(COALESCE(t.credit, 0) - COALESCE(t.debit, 0)) as amount
  FROM account a
  LEFT JOIN transactions t ON a.head = t.acct 
    AND t.facilityId = in_facilityId
    AND DATE(t.transaction_date) BETWEEN in_from_date AND in_to_date
  WHERE a.facilityId = in_facilityId
    AND a.account_type = 'revenue'
    AND a.is_active = TRUE
  GROUP BY a.head, a.description
  
  UN amount
  FROM account a
  LEFT JOIN transactions t ON a.head = t.acct 
    AND t.facilityId = in_facilityId
    AND DATE(t.transaction_date) BETWEEN in_from_date AND in_to_date
  WHERE a.facilityId = in_facilityId
    AND a.account_type = 'expense'
    AND a.is_active = TRUE
  GROUP BY a.head, a.description
  
  ORDER BY section, account_code;
END$$

DELIMITER ;
```

ERE a.facilityId = in_facilityId
    AND a.account_type = 'cogs'
    AND a.is_active = TRUE
  GROUP BY a.head, a.description
  
  UNION ALL
  
  -- Operating Expenses
  SELECT 
    'EXPENSES' as section,
    a.description as account_name,
    a.head as account_code,
    SUM(COALESCE(t.debit, 0) - COALESCE(t.credit, 0)) ast, 0) - COALESCE(t.credit, 0)) as amount
  FROM account a
  LEFT JOIN transactions t ON a.head = t.acct 
    AND t.facilityId = in_facilityId
    AND DATE(t.transaction_date) BETWEEN in_from_date AND in_to_date
  WH  SELECT 
    'COST_OF_GOODS_SOLD' as section,
    a.description as account_name,
    a.head as account_code,
    SUM(COALESCE(t.debiION ALL
  
  -- Cost of Goods Sold
