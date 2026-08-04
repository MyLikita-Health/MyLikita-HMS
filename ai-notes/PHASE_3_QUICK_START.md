# Phase 3: Backend API - Quick Start

## Overview

Phase 3 creates the Node.js/Express API layer for financial reports. This connects the stored procedures from Phase 2 to the frontend through RESTful endpoints.

## Prerequisites

✅ Phase 1 complete (Database foundation)
✅ Phase 2 complete (Stored procedures)

## Files Created

1. `backend/controller/financial-reports.js` - Controller functions (7 endpoints)
2. `backend/routes/financial-reports.js` - API routes with authentication
3. `backend/app.js` - Updated to register routes
4. `frontend/src/utils/apiClient.js` - Updated with financial reports API methods

## API Endpoints

### 1. Trial Balance
**GET** `/financial-reports/trial-balance/:from/:to/:facilityId`

**Parameters**:
- `from` - Start date (YYYY-MM-DD)
- `to` - End date (YYYY-MM-DD)
- `facilityId` - Facility identifier

**Response**:
```json
{
  "success": true,
  "data": {
    "period": { "from": "2026-01-01", "to": "2026-03-31" },
    "facilityId": "facility1",
    "accounts": [
      {
        "account_code": "400021",
        "account_name": "Cash in Hand",
        "account_type": "asset",
        "opening_balance": 100000,
        "period_debit": 50000,
        "period_credit": 30000,
        "closing_balance": 120000
      }
    ],
    "totals": {
      "opening_balance": 100000,
      "period_debit": 50000,
      "period_credit": 50000,
      "closing_balance": 100000
    },
    "isBalanced": true,
    "accountCount": 25
  }
}
```

**Permission**: `billing.reports.view`

### 2. Balance Sheet
**GET** `/financial-reports/balance-sheet/:asOfDate/:facilityId`

**Parameters**:
- `asOfDate` - Report date (YYYY-MM-DD)
- `facilityId` - Facility identifier

**Response**:
```json
{
  "success": true,
  "data": {
    "asOfDate": "2026-03-31",
    "facilityId": "facility1",
    "assets": {
      "current": [...],
      "fixed": [...],
      "total": 1220000
    },
    "liabilities": {
      "current": [...],
      "longTerm": [...],
      "total": 30000
    },
    "equity": {
      "items": [...],
      "total": 1190000
    },
    "totals": {
      "assets": 1220000,
      "liabilities": 30000,
      "equity": 1190000,
      "liabilitiesAndEquity": 1220000
    },
    "isBalanced": true
  }
}
```

**Permission**: `billing.reports.view`

### 3. Profit & Loss
**GET** `/financial-reports/profit-loss/:from/:to/:facilityId`

**Parameters**:
- `from` - Start date (YYYY-MM-DD)
- `to` - End date (YYYY-MM-DD)
- `facilityId` - Facility identifier

**Response**:
```json
{
  "success": true,
  "data": {
    "period": { "from": "2026-01-01", "to": "2026-03-31" },
    "facilityId": "facility1",
    "revenue": {
      "accounts": [...],
      "total": 250000
    },
    "cogs": {
      "accounts": [...],
      "total": 80000
    },
    "grossProfit": {
      "amount": 170000,
      "margin": 68
    },
    "expenses": {
      "accounts": [...],
      "total": 80000
    },
    "netProfit": {
      "amount": 90000,
      "margin": 36
    }
  }
}
```

**Permission**: `billing.reports.view`

### 4. Cash Flow
**GET** `/financial-reports/cash-flow/:from/:to/:facilityId`

**Parameters**:
- `from` - Start date (YYYY-MM-DD)
- `to` - End date (YYYY-MM-DD)
- `facilityId` - Facility identifier

**Response**:
```json
{
  "success": true,
  "data": {
    "period": { "from": "2026-01-01", "to": "2026-03-31" },
    "facilityId": "facility1",
    "operating": {
      "activities": [...],
      "total": 100000
    },
    "investing": {
      "activities": [...],
      "total": -50000
    },
    "financing": {
      "activities": [...],
      "total": 30000
    },
    "summary": {
      "openingCash": 40000,
      "netCashFlow": 80000,
      "closingCash": 120000
    }
  }
}
```

**Permission**: `billing.reports.view`

### 5. Fiscal Periods
**GET** `/financial-reports/periods/:facilityId`

**Parameters**:
- `facilityId` - Facility identifier

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "period_name": "FY2026",
      "period_type": "yearly",
      "start_date": "2026-01-01",
      "end_date": "2026-12-31",
      "is_closed": false,
      "closed_by": null,
      "closed_at": null,
      "notes": null
    }
  ]
}
```

**Permission**: `billing.reports.view`

### 6. Close Period
**POST** `/financial-reports/close-period`

**Body**:
```json
{
  "facilityId": "facility1",
  "periodName": "2026-Q1",
  "notes": "Q1 closing - all transactions verified"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Period 2026-Q1 closed successfully",
  "data": {
    "status": "SUCCESS",
    "period_closed": "2026-Q1",
    "period_start": "2026-01-01",
    "period_end": "2026-03-31",
    "closed_by": "admin",
    "closed_at": "2026-03-08T10:30:00.000Z"
  }
}
```

**Permission**: `billing.reports.manage`

### 7. Report Summary
**GET** `/financial-reports/summary/:facilityId`

**Parameters**:
- `facilityId` - Facility identifier

**Response**:
```json
{
  "success": true,
  "data": {
    "period": { "from": "2026-03-01", "to": "2026-03-31" },
    "summary": {
      "revenue": 250000,
      "expenses": 160000,
      "netProfit": 90000,
      "profitMargin": 36
    }
  }
}
```

**Permission**: `billing.reports.view`

## Testing the API

### Using cURL

```bash
# Get access token first
TOKEN="your_jwt_token_here"

# Trial Balance
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:46990/financial-reports/trial-balance/2026-01-01/2026-03-31/facility1

# Balance Sheet
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:46990/financial-reports/balance-sheet/2026-03-31/facility1

# Profit & Loss
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:46990/financial-reports/profit-loss/2026-01-01/2026-03-31/facility1

# Cash Flow
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:46990/financial-reports/cash-flow/2026-01-01/2026-03-31/facility1

# Close Period
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"facilityId":"facility1","periodName":"2026-Q1","notes":"Q1 closed"}' \
  http://localhost:46990/financial-reports/close-period
```

### Using Frontend API Client

```javascript
import { financialReportsAPI } from './utils/apiClient';

// Trial Balance
const trialBalance = await financialReportsAPI.getTrialBalance(
  'facility1',
  '2026-01-01',
  '2026-03-31'
);

// Balance Sheet
const balanceSheet = await financialReportsAPI.getBalanceSheet(
  'facility1',
  '2026-03-31'
);

// Profit & Loss
const profitLoss = await financialReportsAPI.getProfitLoss(
  'facility1',
  '2026-01-01',
  '2026-03-31'
);

// Cash Flow
const cashFlow = await financialReportsAPI.getCashFlow(
  'facility1',
  '2026-01-01',
  '2026-03-31'
);

// Fiscal Periods
const periods = await financialReportsAPI.getFiscalPeriods('facility1');

// Close Period
const result = await financialReportsAPI.closeFiscalPeriod({
  facilityId: 'facility1',
  periodName: '2026-Q1',
  notes: 'Q1 closing'
});

// Summary
const summary = await financialReportsAPI.getReportSummary('facility1');
```

## Authentication & Permissions

All endpoints require:
1. Valid JWT token (authentication)
2. Appropriate permissions (authorization)

### Required Permissions

**View Reports**:
- Permission: `billing.reports.view`
- Endpoints: All GET endpoints

**Manage Reports**:
- Permission: `billing.reports.manage`
- Endpoints: POST /close-period

### Adding Permissions

If permissions don't exist, add them to the database:

```sql
-- Add report permissions
INSERT INTO permissions (module, resource, action, description)
VALUES 
  ('billing', 'reports', 'view', 'View financial reports'),
  ('billing', 'reports', 'manage', 'Manage financial reports and close periods');

-- Assign to roles (example: Admin role)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
  r.id,
  p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'Admin'
  AND p.module = 'billing'
  AND p.resource = 'reports';
```

## Error Handling

### Common Errors

**400 Bad Request**:
```json
{
  "success": false,
  "message": "Missing required parameters: from, to, facilityId"
}
```

**401 Unauthorized**:
```json
{
  "success": false,
  "message": "No token provided"
}
```

**403 Forbidden**:
```json
{
  "success": false,
  "message": "Insufficient permissions"
}
```

**404 Not Found**:
```json
{
  "success": false,
  "message": "Fiscal period not found"
}
```

**500 Internal Server Error**:
```json
{
  "success": false,
  "message": "Failed to generate trial balance",
  "error": "Error details..."
}
```

## Performance Considerations

### Response Times
- Trial Balance: ~100-500ms (depends on account count)
- Balance Sheet: ~100-300ms
- Profit & Loss: ~100-300ms
- Cash Flow: ~200-500ms

### Optimization Tips
1. Use date ranges wisely (shorter = faster)
2. Close old periods to reduce data
3. Add database indexes if needed
4. Consider caching for frequently accessed reports

## Troubleshooting

### Issue: "No token provided"
**Solution**: Ensure JWT token is in Authorization header:
```javascript
headers: {
  'Authorization': `Bearer ${token}`
}
```

### Issue: "Insufficient permissions"
**Solution**: Check user has `billing.reports.view` permission

### Issue: "Failed to generate report"
**Solution**: 
1. Check Phase 1 and 2 completed
2. Verify stored procedures exist
3. Check database connection
4. Review server logs

### Issue: "Period not found"
**Solution**: Verify period exists in fiscal_periods table

## Next Steps

After Phase 3 completion:

1. ✅ Test all endpoints with Postman/cURL
2. ✅ Verify permissions work correctly
3. ✅ Check error handling
4. ⏭️ Proceed to Phase 4: Frontend UI components

## Phase 4 Preview

Phase 4 will create React components:
- Financial Reports Dashboard
- Trial Balance viewer with export
- Balance Sheet viewer with export
- Profit & Loss viewer with export
- Cash Flow viewer with export
- Period management interface

**Estimated Time**: 4-5 days

## Support

For issues:
1. Check server logs: `backend/log/`
2. Verify database connection
3. Test stored procedures directly
4. Check authentication middleware
5. Review permission configuration
