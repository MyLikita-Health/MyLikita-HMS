# Inventory Module API Testing Guide

## Prerequisites

1. Start MySQL server
2. Run database migration:
```bash
node backend/sql/run_inventory_migration.js
```
3. Start backend server:
```bash
cd backend
npm start
```

---

## Testing Workflow

### 1. Create Supplier
**POST** `/inventory/suppliers`
```json
{
  "supplier_code": "SUP001",
  "supplier_name": "Medical Supplies Ltd",
  "contact_person": "John Doe",
  "email": "john@medicalsupplies.com",
  "phone": "+234-800-1234-567",
  "address": "123 Medical Street",
  "city": "Lagos",
  "country": "Nigeria",
  "payment_terms": "Net 30",
  "credit_limit": 1000000,
  "account_head": "Accounts Payable",
  "facilityId": "facility1"
}
```

### 2. Create Inventory Items
**POST** `/inventory/items`
```json
{
  "item_code": "MED001",
  "item_name": "Paracetamol 500mg",
  "category": "Medications",
  "sub_category": "Analgesics",
  "description": "Pain relief medication",
  "unit_of_measure": "tablets",
  "reorder_level": 100,
  "reorder_quantity": 500,
  "storage_location": "Main Store",
  "account_head": "Medications Inventory",
  "account_subhead": "Pharmacy Stock",
  "cogs_account": "Medications Dispensed",
  "adjustment_account": "Inventory Adjustments",
  "facilityId": "facility1"
}
```

### 3. Create Purchase Order
**POST** `/inventory/purchase-orders`
```json
{
  "supplier_id": 1,
  "facilityId": "facility1",
  "order_date": "2024-03-06",
  "expected_delivery_date": "2024-03-13",
  "notes": "Urgent order for pharmacy",
  "created_by": 1,
  "items": [
    {
      "item_id": 1,
      "quantity_ordered": 1000,
      "unit_cost": 50,
      "notes": "Bulk order"
    }
  ]
}
```

### 4. Approve Purchase Order
**POST** `/inventory/purchase-orders/1/approve`
```json
{
  "approved_by": 1
}
```

### 5. Create GRN (Goods Received Note)
**POST** `/inventory/grn`
```json
{
  "po_id": 1,
  "supplier_id": 1,
  "facilityId": "facility1",
  "received_date": "2024-03-10",
  "invoice_number": "INV-2024-001",
  "invoice_date": "2024-03-10",
  "invoice_amount": 50000,
  "received_by": 1,
  "notes": "All items received in good condition",
  "items": [
    {
      "item_id": 1,
      "batch_number": "BATCH-2024-001",
      "quantity_received": 1000,
      "unit_cost": 50,
      "expiry_date": "2026-03-10",
      "manufacture_date": "2024-01-15",
      "notes": "Good condition"
    }
  ]
}
```

### 6. Verify GRN
**POST** `/inventory/grn/1/verify`
```json
{
  "verified_by": 1
}
```

### 7. Post GRN to Inventory & Accounts
**POST** `/inventory/grn/1/post`
```json
{
  "facilityId": "facility1",
  "userId": 1
}
```

**Expected Result:**
- Stock levels updated
- Batches created
- Transactions recorded
- Posted to `pending_txn`:
  - DR: Inventory (Asset) - 50,000
  - CR: Accounts Payable - 50,000

### 8. Check Stock Levels
**GET** `/inventory/stock?facilityId=facility1`

**Expected Response:**
```json
{
  "success": true,
  "results": [
    {
      "item_id": 1,
      "item_code": "MED001",
      "item_name": "Paracetamol 500mg",
      "quantity_on_hand": 1000,
      "quantity_available": 1000,
      "stock_status": "Normal"
    }
  ]
}
```

### 9. Create Requisition (Internal Request)
**POST** `/inventory/requisitions`
```json
{
  "facilityId": "facility1",
  "requested_by": 2,
  "department": "Pharmacy",
  "request_date": "2024-03-11",
  "required_date": "2024-03-12",
  "notes": "Stock for pharmacy counter",
  "items": [
    {
      "item_id": 1,
      "quantity_requested": 100,
      "notes": "For daily dispensing"
    }
  ]
}
```

### 10. Approve Requisition
**POST** `/inventory/requisitions/1/approve`
```json
{
  "approved_by": 1,
  "items": [
    {
      "item_id": 1,
      "quantity_approved": 100
    }
  ]
}
```

### 11. Issue Requisition
**POST** `/inventory/requisitions/1/issue`
```json
{
  "issued_by": 1,
  "facilityId": "facility1"
}
```

**Expected Result:**
- Stock deducted: 1000 - 100 = 900
- Posted to `pending_txn`:
  - DR: Department COGS - 5,000 (100 × 50)
  - CR: Inventory - 5,000

### 12. Issue Stock for Clinical Use (Prescription)
**POST** `/inventory/issue`
```json
{
  "item_id": 1,
  "quantity": 10,
  "facilityId": "facility1",
  "reference_type": "prescription",
  "reference_id": "RX-2024-001",
  "patient_id": "PAT001",
  "patient_name": "Jane Smith",
  "performed_by": 3,
  "notes": "Prescription for patient"
}
```

**Expected Result:**
- FIFO batch selection
- Stock deducted: 900 - 10 = 890
- Posted to `pending_txn`:
  - DR: COGS - 500 (10 × 50)
  - CR: Inventory - 500

### 13. Create Stock Adjustment
**POST** `/inventory/adjustments`
```json
{
  "facilityId": "facility1",
  "adjustment_type": "stock_take",
  "reason": "Physical count variance",
  "performed_by": 1,
  "items": [
    {
      "item_id": 1,
      "system_quantity": 890,
      "physical_quantity": 885,
      "unit_cost": 50,
      "notes": "5 tablets damaged"
    }
  ]
}
```

### 14. Approve Stock Adjustment
**POST** `/inventory/adjustments/1/approve`
```json
{
  "approved_by": 1,
  "facilityId": "facility1"
}
```

**Expected Result:**
- Stock adjusted: 890 → 885
- Posted to `pending_txn`:
  - DR: Adjustment Expense - 250 (5 × 50)
  - CR: Inventory - 250

### 15. Transfer Stock Between Locations
**POST** `/inventory/transfers`
```json
{
  "item_id": 1,
  "from_location": "Main Store",
  "to_location": "Pharmacy Counter",
  "quantity": 50,
  "facilityId": "facility1",
  "performed_by": 1,
  "notes": "Transfer to pharmacy counter"
}
```

### 16. Check Low Stock Items
**GET** `/inventory/stock/low/facility1`

### 17. Check Expiring Items
**GET** `/inventory/stock/expiring?facilityId=facility1&days=90`

### 18. Get Stock History
**GET** `/inventory/stock/history/1?from=2024-03-01&to=2024-03-31`

### 19. Get Supplier Performance
**GET** `/inventory/suppliers/performance?facilityId=facility1&from=2024-01-01&to=2024-03-31`

---

## Verification Checklist

After running the tests above, verify:

### Database Tables
```sql
-- Check items
SELECT * FROM inventory_items;

-- Check stock levels
SELECT * FROM inventory_stock;

-- Check batches
SELECT * FROM inventory_batches;

-- Check transactions
SELECT * FROM inventory_transactions;

-- Check GRNs
SELECT * FROM inventory_grn;

-- Check requisitions
SELECT * FROM inventory_requisitions;

-- Check adjustments
SELECT * FROM inventory_adjustments;
```

### Accounting Integration
```sql
-- Check pending_txn entries
SELECT * FROM pending_txn 
WHERE service_type = 'Inventory' 
ORDER BY created_at DESC;

-- Verify debit/credit balance
SELECT 
  tx_status,
  SUM(amount) as total
FROM pending_txn 
WHERE service_type = 'Inventory'
GROUP BY tx_status;
-- Debit and Credit totals should match
```

### Stock Calculations
```sql
-- Verify stock levels match transactions
SELECT 
  i.item_name,
  s.quantity_on_hand,
  (SELECT COALESCE(SUM(
    CASE 
      WHEN t.transaction_type IN ('purchase', 'return') THEN t.quantity
      WHEN t.transaction_type IN ('issue', 'adjustment') THEN -t.quantity
      ELSE 0
    END
  ), 0) FROM inventory_transactions t WHERE t.item_id = i.id) as calculated_stock
FROM inventory_items i
JOIN inventory_stock s ON i.id = s.item_id;
```

---

## Common Test Scenarios

### Scenario 1: Complete Purchase Cycle
1. Create Supplier
2. Create Items
3. Create PO
4. Approve PO
5. Create GRN
6. Verify GRN
7. Post GRN
8. Verify stock increased
9. Verify accounting entries

### Scenario 2: Internal Requisition
1. Create Requisition
2. Approve Requisition
3. Issue Items
4. Verify stock decreased
5. Verify accounting entries

### Scenario 3: Clinical Stock Issue
1. Issue stock for prescription
2. Verify FIFO batch selection
3. Verify stock decreased
4. Verify accounting entries
5. Check if reorder alert created

### Scenario 4: Stock Adjustment
1. Create adjustment
2. Approve adjustment
3. Verify stock corrected
4. Verify accounting entries

### Scenario 5: Stock Transfer
1. Transfer between locations
2. Verify source decreased
3. Verify destination increased
4. Verify transaction recorded

---

## Error Handling Tests

### Test Insufficient Stock
**POST** `/inventory/issue`
```json
{
  "item_id": 1,
  "quantity": 10000,
  "facilityId": "facility1",
  "reference_type": "prescription",
  "reference_id": "RX-TEST",
  "performed_by": 1
}
```
**Expected**: 400 error - Insufficient stock

### Test Duplicate Item Code
**POST** `/inventory/items`
```json
{
  "item_code": "MED001",
  "item_name": "Duplicate Item",
  "category": "Test",
  "facilityId": "facility1"
}
```
**Expected**: 400 error - Item code already exists

### Test Invalid Supplier
**POST** `/inventory/purchase-orders`
```json
{
  "supplier_id": 9999,
  "facilityId": "facility1",
  "order_date": "2024-03-06",
  "created_by": 1,
  "items": []
}
```
**Expected**: Foreign key constraint error

---

## Performance Tests

### Bulk Stock Issue
**POST** `/inventory/issue/bulk`
```json
{
  "facilityId": "facility1",
  "reference_type": "prescription",
  "reference_id": "RX-BULK-001",
  "patient_id": "PAT001",
  "patient_name": "Test Patient",
  "performed_by": 1,
  "items": [
    { "item_id": 1, "quantity": 5 },
    { "item_id": 2, "quantity": 10 },
    { "item_id": 3, "quantity": 3 }
  ]
}
```

---

## Integration Tests

### Test with Pharmacy Module
1. Create prescription in pharmacy
2. Issue stock via inventory
3. Verify stock deducted
4. Verify accounting posted

### Test with Dental Module
1. Create dental procedure
2. Issue dental supplies
3. Verify stock deducted
4. Verify accounting posted

### Test with Lab Module
1. Create lab request
2. Issue lab reagents
3. Verify stock deducted
4. Verify accounting posted

---

## Postman Collection

Import this collection for quick testing:

```json
{
  "info": {
    "name": "Inventory Module API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Items",
      "item": [
        {
          "name": "Get All Items",
          "request": {
            "method": "GET",
            "url": "{{baseUrl}}/inventory/items?facilityId={{facilityId}}"
          }
        },
        {
          "name": "Create Item",
          "request": {
            "method": "POST",
            "url": "{{baseUrl}}/inventory/items",
            "body": {
              "mode": "raw",
              "raw": "{\n  \"item_code\": \"MED001\",\n  \"item_name\": \"Paracetamol 500mg\",\n  \"category\": \"Medications\",\n  \"facilityId\": \"{{facilityId}}\"\n}"
            }
          }
        }
      ]
    }
  ],
  "variable": [
    {
      "key": "baseUrl",
      "value": "http://localhost:46990"
    },
    {
      "key": "facilityId",
      "value": "facility1"
    }
  ]
}
```

---

## Success Criteria

✅ All API endpoints return expected responses
✅ Stock levels calculate correctly
✅ FIFO batch selection works
✅ Accounting entries balance (debit = credit)
✅ Reorder alerts trigger correctly
✅ Transactions link to references
✅ Multi-location tracking works
✅ Supplier performance calculates correctly
✅ Error handling works as expected
✅ Database constraints enforced

---

## Next Steps After Testing

1. Fix any bugs found during testing
2. Optimize slow queries
3. Add indexes if needed
4. Document any edge cases
5. Proceed to Phase 2: Frontend Development
