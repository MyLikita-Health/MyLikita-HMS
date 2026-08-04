# Inventory Requisition Workflow Guide

## Overview
The requisition system allows departments to request inventory items from the main store. It follows a 3-stage approval workflow with full accounting integration.

## Workflow Stages

### Stage 1: CREATE (Status: pending)
**Who:** Department Staff (Requester)

**Actions:**
1. Navigate to Inventory → Requisitions
2. Click "Create Requisition"
3. Fill in requisition details:
   - Department (Pharmacy, Dental, Laboratory, etc.)
   - Request Date
   - Required Date (when items are needed)
   - Notes (optional)
4. Add items to requisition:
   - Select item
   - Enter quantity requested
   - Add notes (optional)
5. Submit requisition

**Result:**
- Requisition created with status "pending"
- Requisition number generated (e.g., REQ-1234567890)
- Awaits approval from authorized personnel

---

### Stage 2: APPROVE (Status: approved)
**Who:** Inventory Manager / Authorized Approver

**Actions:**
1. View pending requisitions
2. Click "View" on requisition
3. Review requisition details and items
4. For each item, set "Quantity Approved":
   - Can approve full amount requested
   - Can approve partial amount
   - Can approve zero (reject specific item)
5. Click "Approve Requisition"

**Business Rules:**
- Approved quantity can be ≤ requested quantity
- Approver can modify quantities based on:
  - Stock availability
  - Budget constraints
  - Priority of request
  - Department allocation limits

**Result:**
- Requisition status changes to "approved"
- Approved quantities recorded for each item
- Approved by and approved at timestamp recorded
- Ready for issuing

---

### Stage 3: ISSUE (Status: issued)
**Who:** Store Keeper / Inventory Staff

**Actions:**
1. View approved requisitions
2. Click "View" on requisition
3. Review approved quantities
4. Click "Issue Items"
5. System automatically:
   - Checks stock availability
   - Deducts from inventory
   - Creates transaction records
   - Posts to accounting

**Business Rules:**
- Can only issue approved requisitions
- Must have sufficient stock for all items
- If any item has insufficient stock, entire issue fails
- Uses weighted average cost for accounting

**Accounting Impact:**
```
Debit:  Expenses → Cost of Goods Sold (Department Expense)
Credit: Assets → Inventory (Reduce inventory value)
```

**Result:**
- Requisition status changes to "issued"
- Stock quantities reduced
- Transaction records created
- Accounting entries posted
- Issued by and issued at timestamp recorded

---

## Status Flow

```
pending → approved → issued
   ↓         ↓
rejected  rejected
```

**Status Definitions:**
- **pending**: Awaiting approval
- **approved**: Approved and ready to issue
- **rejected**: Denied by approver
- **issued**: Items physically issued and posted

---

## Database Tables

### inventory_requisitions
Main requisition header table:
- id
- requisition_number
- facilityId
- requested_by (user ID)
- approved_by (user ID)
- issued_by (user ID)
- department
- request_date
- required_date
- approved_at
- issued_at
- status
- notes

### inventory_requisition_items
Requisition line items:
- id
- requisition_id
- item_id
- quantity_requested
- quantity_approved
- quantity_issued
- notes

---

## API Endpoints

### Get All Requisitions
```
GET /inventory/requisitions?facilityId=1&status=pending&department=Pharmacy
```

### Get Requisition Details
```
GET /inventory/requisitions/:id
```

### Create Requisition
```
POST /inventory/requisitions
Body: {
  facilityId, requested_by, department, request_date,
  required_date, items: [{item_id, quantity_requested}], notes
}
```

### Approve Requisition
```
POST /inventory/requisitions/:id/approve
Body: {
  approved_by,
  items: [{item_id, quantity_approved}]
}
```

### Issue Requisition
```
POST /inventory/requisitions/:id/issue
Body: {
  issued_by, facilityId
}
```

---

## User Roles & Permissions

### Department Staff (Requester)
- Create requisitions
- View own requisitions
- Cannot approve or issue

### Inventory Manager (Approver)
- View all requisitions
- Approve/reject requisitions
- Modify approved quantities
- Cannot issue (separation of duties)

### Store Keeper (Issuer)
- View approved requisitions
- Issue items
- Cannot approve (separation of duties)

### System Administrator
- Full access to all functions
- Can override any stage

---

## Business Scenarios

### Scenario 1: Full Approval
```
Requested: 100 tablets
Approved:  100 tablets
Issued:    100 tablets
Result: ✅ Complete fulfillment
```

### Scenario 2: Partial Approval
```
Requested: 100 tablets
Approved:  50 tablets (limited stock)
Issued:    50 tablets
Result: ⚠️ Partial fulfillment
```

### Scenario 3: Insufficient Stock at Issue
```
Requested: 100 tablets
Approved:  100 tablets
Available: 30 tablets
Result: ❌ Issue fails, requisition stays "approved"
Action: Wait for stock or reduce approved quantity
```

### Scenario 4: Multi-Item Requisition
```
Item A: Requested 100, Approved 100, Issued 100 ✅
Item B: Requested 50, Approved 30, Issued 30 ⚠️
Item C: Requested 20, Approved 0, Not issued ❌
Result: Mixed fulfillment
```

---

## Accounting Integration

### When Items Are Issued

**Journal Entry Created:**
```
Transaction ID: REQ-{id}-{timestamp}

Entry 1 (Expense):
  Debit:  Expenses / Cost of Goods Sold
  Amount: Quantity × Unit Cost
  
Entry 2 (Inventory Reduction):
  Credit: Assets / Inventory
  Amount: Quantity × Unit Cost
```

**Cost Calculation:**
- Uses weighted average cost from active batches
- If no batch cost available, uses 0
- Total cost = Quantity × Average Unit Cost

**Posted to:** `pending_txn` table via stored procedure

---

## Reports & Analytics

### Key Metrics
- Pending requisitions count
- Average approval time
- Average issue time
- Fulfillment rate (approved/requested)
- Department consumption patterns
- Most requested items

### Available Reports
- Requisitions by department
- Requisitions by status
- Requisitions by date range
- Item consumption by department
- Approval vs requested analysis

---

## Best Practices

### For Requesters
1. Plan ahead - submit requisitions early
2. Be realistic with quantities
3. Provide clear notes for urgent items
4. Check stock levels before requesting
5. Follow up on pending requisitions

### For Approvers
1. Review stock availability before approving
2. Consider department budgets
3. Prioritize urgent requests
4. Communicate partial approvals
5. Approve promptly to avoid delays

### For Issuers
1. Verify physical stock matches system
2. Issue approved items promptly
3. Report discrepancies immediately
4. Maintain FIFO (First In, First Out)
5. Update system in real-time

---

## Troubleshooting

### Issue: Cannot approve requisition
**Cause:** User lacks approval permissions
**Solution:** Contact system administrator for role assignment

### Issue: Cannot issue - insufficient stock
**Cause:** Stock depleted after approval
**Solution:** 
1. Reduce approved quantity
2. Wait for new stock arrival
3. Source from another location

### Issue: Accounting entries not posting
**Cause:** Missing cost information or pending_txn error
**Solution:**
1. Check item has valid cost in batches
2. Verify pending_txn stored procedure exists
3. Check database logs for errors

### Issue: Requisition stuck in pending
**Cause:** No approver assigned or notification missed
**Solution:**
1. Send reminder to approvers
2. Check approval workflow configuration
3. Escalate to manager if urgent

---

## Future Enhancements

Potential improvements:
- Email notifications at each stage
- Mobile app for approvals
- Barcode scanning for issuing
- Auto-approval for low-value items
- Recurring requisitions
- Budget integration
- Multi-level approval workflow
- Partial issuing (issue in batches)
- Return/reversal functionality
