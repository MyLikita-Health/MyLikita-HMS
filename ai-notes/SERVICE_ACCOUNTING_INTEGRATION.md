# Service Definitions & Account Chart Integration

## Current Status

The `service_definitions` table is NOT currently integrated with the account chart. This means:

1. Services don't have revenue account mappings
2. Bills created from services use hardcoded account codes ('SERVICE')
3. Financial reports may not accurately reflect service revenue by category

## Required Changes

### 1. Database Schema Update

Run the migration to add revenue account fields to `service_definitions`:

```bash
mysql -u root prime < backend/sql/add_revenue_account_to_services.sql
```

This adds:
- `revenue_account_head` - Links to acc_head.head
- `revenue_account_subhead` - Links to acc_head.subhead

### 2. Update Service Population Script

Modify `backend/sql/populate_services.js` to include revenue accounts when creating services:

```javascript
const services = [
  {
    id: generateId(),
    service_code: 'CONS_GEN',
    service_name: 'General Consultation',
    category: 'consultation',
    base_price: 5000.00,
    revenue_account_head: '4',      // Revenue
    revenue_account_subhead: '401',  // Consultation Revenue
    facilityId: ''
  },
  // ... more services
];
```

### 3. Update createPendingBills Function

The function at `backend/controller/account.js:4390` needs to:

1. Fetch service details from `service_definitions` including revenue accounts
2. Use the service's revenue account instead of hardcoded 'SERVICE'

Current code:
```javascript
head: accHead || 'SERVICE',
subhead: accHead || 'SERVICE',
```

Should be:
```javascript
head: service.revenue_account_head || 'SERVICE',
subhead: service.revenue_account_subhead || 'SERVICE',
```

### 4. Update ServicesImproved Component

The frontend component should pass service account information when creating bills.

## Account Chart Structure

Typical revenue account structure:
```
4 - Revenue (Head)
├── 401 - Consultation Revenue
├── 402 - Laboratory Revenue
├── 403 - Radiology Revenue
├── 404 - Pharmacy Revenue
├── 405 - Surgery Revenue
├── 406 - Admission Revenue
├── 407 - Therapy Revenue
└── 499 - Other Revenue
```

## Implementation Steps

1. ✅ Create migration SQL file
2. ⏳ Run migration on database
3. ⏳ Update populate_services.js with account mappings
4. ⏳ Modify createPendingBills to use service accounts
5. ⏳ Update frontend to pass service IDs instead of just names
6. ⏳ Test bill creation with proper account mapping
7. ⏳ Verify financial reports show correct revenue categorization

## Testing

After implementation:

1. Create a bill for a consultation service
2. Check `pending_txn` table - should have correct head/subhead
3. Pay the bill
4. Check `txn` table - should have correct revenue account
5. Run Trial Balance report - should show revenue in correct categories
6. Run P&L report - should categorize revenue by service type

## Benefits

- Accurate financial reporting by service category
- Proper revenue recognition in accounting system
- Ability to track performance by service line
- Compliance with accounting standards
- Better integration between operations and finance
