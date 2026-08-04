# Requisition UI Workflow - User Guide

## Visual Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    REQUISITION LIFECYCLE                     │
└─────────────────────────────────────────────────────────────┘

Step 1: CREATE
┌──────────────────────────────────────┐
│  Department Staff                     │
│  ┌────────────────────────────────┐  │
│  │ Click "Create Requisition"     │  │
│  │ Fill in details & add items    │  │
│  │ Submit                          │  │
│  └────────────────────────────────┘  │
│  Status: pending                      │
│  Actions: [View]                      │
└──────────────────────────────────────┘
                 ↓
Step 2: APPROVE
┌──────────────────────────────────────┐
│  Inventory Manager                    │
│  ┌────────────────────────────────┐  │
│  │ Click "Approve" button         │  │
│  │ Review items & stock levels    │  │
│  │ Set approved quantities        │  │
│  │ Submit approval                 │  │
│  └────────────────────────────────┘  │
│  Status: approved                     │
│  Actions: [View] [Approve]            │
└──────────────────────────────────────┘
                 ↓
Step 3: ISSUE
┌──────────────────────────────────────┐
│  Store Keeper                         │
│  ┌────────────────────────────────┐  │
│  │ Click "Issue" button           │  │
│  │ Confirm issue                   │  │
│  │ System deducts stock           │  │
│  │ Posts to accounting            │  │
│  └────────────────────────────────┘  │
│  Status: issued                       │
│  Actions: [View] [Issue]              │
└──────────────────────────────────────┘
                 ↓
              COMPLETE
```

## UI Components

### 1. Requisition List View

**Location:** Inventory → Requisitions

**Columns:**
- Req Number
- Department
- Request Date
- Required Date
- Requested By
- Status (Badge with color)
- Actions (Buttons)

**Action Buttons by Status:**

| Status    | Available Buttons                    |
|-----------|--------------------------------------|
| pending   | [View] [Approve]                     |
| approved  | [View] [Issue]                       |
| issued    | [View]                               |
| rejected  | [View]                               |

**Status Badge Colors:**
- pending → Yellow (warning)
- approved → Green (success)
- rejected → Red (danger)
- issued → Blue (info)

---

### 2. View Modal

**Trigger:** Click "View" button

**Displays:**
- Requisition header information
- Status badge
- Requested by, approved by, issued by
- Notes
- Items table with:
  - Item name & code
  - Qty requested
  - Qty approved
  - Qty issued
  - Unit of measure

**Actions:**
- [Close] button

---

### 3. Approve Modal

**Trigger:** Click "Approve" button (only on pending requisitions)

**Displays:**
- Requisition summary
- Items table with:
  - Item name
  - Quantity requested
  - Available stock (color-coded)
  - Approve quantity input field

**Features:**
- Input fields for each item
- Default value = requested quantity
- Can modify to approve less
- Can set to 0 to reject item
- Shows available stock for reference
- Red text if stock < requested

**Actions:**
- [Cancel] button
- [Approve Requisition] button

**Validation:**
- Approved quantity must be ≤ requested quantity
- Approved quantity must be ≥ 0

---

### 4. Issue Confirmation

**Trigger:** Click "Issue" button (only on approved requisitions)

**Displays:**
- Confirmation dialog:
  "Are you sure you want to issue this requisition? 
   This will deduct items from stock and post to accounting."

**Actions:**
- [Cancel] - No action taken
- [OK] - Proceeds with issuing

**On Success:**
- Success message displayed
- Requisition status changes to "issued"
- Stock quantities reduced
- Accounting entries posted
- List refreshes

**On Error:**
- Error message displayed (e.g., "Insufficient stock for Paracetamol")
- Requisition remains in "approved" status
- No changes made

---

## Step-by-Step User Flows

### Flow 1: Create Requisition (Department Staff)

1. Navigate to Inventory → Requisitions
2. Click "Create Requisition" button
3. Fill in form:
   - Department: Select from dropdown
   - Request Date: Auto-filled (today)
   - Required Date: Select when needed
   - Notes: Optional description
4. Add items:
   - Click "Add Item"
   - Select item from dropdown
   - Enter quantity needed
   - Add notes (optional)
   - Repeat for all items
5. Click "Submit Requisition"
6. Success message appears
7. Requisition appears in list with status "pending"

---

### Flow 2: Approve Requisition (Manager)

1. Navigate to Inventory → Requisitions
2. Filter by status: "Pending"
3. Review requisition in list
4. Click "Approve" button
5. Approve modal opens showing:
   - Requisition details
   - Items with requested quantities
   - Available stock levels
6. For each item:
   - Review requested quantity
   - Check available stock
   - Set approved quantity:
     - Full approval: Keep default (requested qty)
     - Partial approval: Enter lower number
     - Reject item: Enter 0
7. Click "Approve Requisition"
8. Success message appears
9. Requisition status changes to "approved"
10. List refreshes

**Example Approval Scenarios:**

**Scenario A: Full Approval**
```
Item: Paracetamol 500mg
Requested: 100
Available: 500
Approved: 100 ✅
```

**Scenario B: Partial Approval (Limited Stock)**
```
Item: Amoxicillin 250mg
Requested: 200
Available: 80
Approved: 80 ⚠️
```

**Scenario C: Reject Item (Out of Stock)**
```
Item: Ibuprofen 400mg
Requested: 50
Available: 0
Approved: 0 ❌
```

---

### Flow 3: Issue Requisition (Store Keeper)

1. Navigate to Inventory → Requisitions
2. Filter by status: "Approved"
3. Review requisition in list
4. Click "Issue" button
5. Confirmation dialog appears
6. Click "OK" to confirm
7. System processes:
   - Validates stock availability
   - Deducts quantities from stock
   - Creates transaction records
   - Posts accounting entries
8. Success message appears
9. Requisition status changes to "issued"
10. List refreshes

**If Issue Fails:**
- Error message shows which item has insufficient stock
- Requisition remains "approved"
- No changes made to stock or accounting
- Options:
  - Wait for stock replenishment
  - Reduce approved quantity
  - Source from another location

---

## Filters & Search

**Available Filters:**

1. **Department Filter**
   - All Departments
   - Pharmacy
   - Dental
   - Laboratory
   - Nursing
   - Theater

2. **Status Filter**
   - All Status
   - Pending
   - Approved
   - Rejected
   - Issued

**Usage:**
- Select filters from dropdowns
- List automatically refreshes
- Filters can be combined

---

## Permissions & Access Control

### Department Staff
- ✅ Create requisitions
- ✅ View own requisitions
- ❌ Approve requisitions
- ❌ Issue requisitions

### Inventory Manager
- ✅ View all requisitions
- ✅ Approve requisitions
- ✅ Modify approved quantities
- ❌ Issue requisitions (separation of duties)

### Store Keeper
- ✅ View approved requisitions
- ✅ Issue requisitions
- ❌ Approve requisitions (separation of duties)

### System Administrator
- ✅ Full access to all functions
- ✅ Can override any stage

---

## Tips & Best Practices

### For Requesters
1. ✅ Submit requisitions early (before stock runs out)
2. ✅ Be realistic with quantities
3. ✅ Check stock levels first if possible
4. ✅ Provide clear notes for urgent items
5. ✅ Follow up on pending requisitions

### For Approvers
1. ✅ Review available stock before approving
2. ✅ Consider department budgets
3. ✅ Prioritize urgent requests
4. ✅ Communicate partial approvals to requester
5. ✅ Approve promptly to avoid delays

### For Issuers
1. ✅ Verify physical stock matches system
2. ✅ Issue approved items promptly
3. ✅ Report discrepancies immediately
4. ✅ Follow FIFO (First In, First Out)
5. ✅ Update system in real-time

---

## Troubleshooting

### Issue: "Approve" button not showing
**Cause:** Requisition is not in "pending" status
**Solution:** Check requisition status - only pending requisitions can be approved

### Issue: "Issue" button not showing
**Cause:** Requisition is not in "approved" status
**Solution:** Requisition must be approved first before issuing

### Issue: Cannot modify approved quantity
**Cause:** Input field validation
**Solution:** Approved quantity must be between 0 and requested quantity

### Issue: Issue fails with "Insufficient stock"
**Cause:** Stock depleted after approval
**Solution:**
1. Check current stock levels
2. Reduce approved quantity
3. Wait for stock replenishment
4. Source from another location

### Issue: Success message but list not updating
**Cause:** Browser cache or network delay
**Solution:** Refresh the page manually

---

## Keyboard Shortcuts

- `Ctrl + N` - Create new requisition (when on requisitions page)
- `Esc` - Close any open modal
- `Enter` - Submit form (when in modal)

---

## Mobile Responsiveness

The requisition interface is fully responsive:
- Tables scroll horizontally on small screens
- Buttons stack vertically on mobile
- Modals adjust to screen size
- Touch-friendly button sizes

---

## Future Enhancements

Planned improvements:
- 📧 Email notifications at each stage
- 📱 Mobile app for approvals
- 📊 Dashboard with pending counts
- 🔔 Real-time alerts
- 📝 Approval comments/notes
- 🔄 Bulk approval
- 📈 Analytics & reports
- ⏰ SLA tracking
