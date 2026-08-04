# Department Stock Tracking - Implementation Guide

## Overview
The inventory system now tracks stock issued to departments as separate locations. This allows you to see exactly what each department currently has in their possession.

## How It Works

### Concept: Departments as Locations
Departments are treated as inventory locations, just like "Main Store" or "Pharmacy". When a requisition is issued, stock is transferred from Main Store to the department location.

### Stock Flow
```
Main Store → Department Location
   (via Requisition Issue)
```

**Example:**
```
Before Issue:
- Main Store: 100 units
- Dental Department: 0 units

After Issuing 20 units to Dental:
- Main Store: 80 units
- Dental Department: 20 units
```

---

## Implementation Changes

### 1. Database Changes

**File:** `backend/sql/add_department_locations.sql`

Created department locations:
- Pharmacy Department
- Dental Department
- Laboratory Department
- Nursing Department
- Theater Department
- Emergency Department
- Radiology Department

**Migration:**
```bash
mysql -u root prime < backend/sql/add_department_locations.sql
```

### 2. Requisition Issue Process Updated

**File:** `backend/controller/inventory-requisitions.js`

**Old Behavior:**
- Deducted from stock
- No destination tracking

**New Behavior:**
- Deducts from "Main Store"
- Adds to "{Department} Department" location
- Creates transfer transaction (not just issue)
- Full audit trail maintained

**Transaction Type Changed:**
- Old: `issue` (one-way)
- New: `transfer` (from → to)

### 3. New UI Component

**File:** `frontend/src/components/inventory/StockByLocation.jsx`

Features:
- Location dropdown selector
- Summary cards (Total Units, Total Value, Low Stock Count)
- Stock items table
- Status badges
- Real-time filtering

---

## Using the System

### Step 1: Run Migration

```bash
mysql -u root prime < backend/sql/add_department_locations.sql
```

This creates department locations for all facilities.

### Step 2: Issue Requisitions

When you issue a requisition:
1. Stock is deducted from Main Store
2. Stock is added to Department location
3. Transaction recorded as transfer

**Example:**
```
Requisition: REQ-123
Department: Dental
Item: Paracetamol 500mg
Quantity: 50

Result:
- Main Store: -50 units
- Dental Department: +50 units
- Transaction: Transfer from Main Store to Dental Department
```

### Step 3: View Department Stock

Navigate to: **Inventory → Stock by Location**

1. Select location from dropdown
2. View summary cards
3. See all items in that location
4. Check stock status

---

## Viewing Department Stock

### Location Selector

**Available Locations:**
- Main Store (warehouse)
- Pharmacy (dispensary)
- Dental Department (department)
- Laboratory Department (department)
- Nursing Department (department)
- Theater Department (department)
- Emergency Department (department)
- Radiology Department (department)

### Summary Cards

**Total Units**
- Sum of all item quantities in location
- Shows physical count

**Total Value**
- Sum of (quantity × unit cost) for all items
- Shows monetary value

**Low Stock Items**
- Count of items below minimum level
- Warning indicator

### Stock Items Table

**Columns:**
- Item Code
- Item Name
- Category
- On Hand (physical quantity)
- Available (available for use)
- Reserved (allocated but not issued)
- Min Level (minimum stock level)
- Unit (unit of measure)
- Status (badge: Normal/Low Stock/Out of Stock)

---

## Department Stock Management

### Viewing What Dental Has

1. Go to Inventory → Stock by Location
2. Select "Dental Department" from dropdown
3. View all items currently in Dental
4. See quantities and values

### Checking Multiple Departments

Simply change the location dropdown to view different departments:
- Pharmacy Department
- Laboratory Department
- Nursing Department
- etc.

### Tracking Stock Movement

**Transaction History:**
- Go to Inventory → Reports → Movement Report
- Filter by location: "Dental Department"
- See all transfers in/out

---

## Inter-Department Transfers

Departments can transfer items between each other using the Stock Transfer feature.

**Example: Dental → Pharmacy Transfer**

1. Go to Inventory → Stock Transfer
2. From Location: Dental Department
3. To Location: Pharmacy Department
4. Select item and quantity
5. Submit transfer

**Result:**
- Dental Department: -quantity
- Pharmacy Department: +quantity
- Transaction recorded

---

## Reports & Analytics

### Department Consumption Report

**Location:** Inventory → Reports → Consumption Report

**Filter by:**
- Department (location)
- Date range
- Item category

**Shows:**
- What was issued to department
- Consumption patterns
- Cost analysis

### Stock Valuation by Department

**Location:** Inventory → Reports → Valuation Report

**Filter by:**
- Location (select department)

**Shows:**
- Total value of stock in department
- Item-by-item breakdown
- Cost allocation

---

## Setting Department Stock Levels

### Minimum Stock Levels

You can set minimum stock levels for each department:

1. Go to Inventory → Locations
2. Edit department location
3. For each item, set minimum level
4. System will alert when below minimum

### Reorder Rules

Configure automatic reorder for departments:
- Set reorder level
- Set reorder quantity
- System generates requisitions automatically

---

## Best Practices

### For Department Heads

1. **Regular Stock Checks**
   - Review department stock weekly
   - Identify slow-moving items
   - Request transfers if needed

2. **Requisition Planning**
   - Check current stock before requesting
   - Request realistic quantities
   - Plan for lead times

3. **Stock Returns**
   - Return unused items to Main Store
   - Use stock transfer feature
   - Keep department lean

### For Store Keepers

1. **Issue Promptly**
   - Process approved requisitions quickly
   - Verify physical stock matches system
   - Update system in real-time

2. **Monitor Department Levels**
   - Check department stock regularly
   - Identify overstocking
   - Facilitate inter-department transfers

3. **Audit Regularly**
   - Physical count vs system
   - Reconcile discrepancies
   - Update stock records

### For Inventory Managers

1. **Analyze Consumption**
   - Review department usage patterns
   - Optimize stock allocation
   - Adjust par levels

2. **Cost Control**
   - Monitor department stock values
   - Identify waste
   - Implement controls

3. **Policy Enforcement**
   - Set department stock limits
   - Enforce requisition approval
   - Audit compliance

---

## Troubleshooting

### Issue: Department not showing in location dropdown

**Cause:** Department location not created

**Solution:**
```bash
mysql -u root prime < backend/sql/add_department_locations.sql
```

### Issue: No stock showing for department

**Cause:** No requisitions issued yet, or issued before migration

**Solution:**
- Issue new requisitions (will transfer to department)
- Old requisitions won't show (issued before tracking)

### Issue: Stock shows in Main Store but not department

**Cause:** Requisition issued before migration

**Solution:**
- Use Stock Transfer to move from Main Store to Department
- Or issue new requisition

### Issue: Department stock value incorrect

**Cause:** Missing cost information in batches

**Solution:**
- Update batch costs
- Recalculate valuation

---

## API Endpoints

### Get Stock by Location
```
GET /inventory/stock?facilityId=1&location=Dental Department
```

### Get All Locations
```
GET /inventory/locations?facilityId=1
```

### Transfer Stock
```
POST /inventory/transfers
Body: {
  item_id, from_location, to_location, quantity, facilityId, performed_by
}
```

---

## Database Schema

### inventory_locations
```sql
- id
- location_name (e.g., "Dental Department")
- location_type (e.g., "department")
- description
- is_active
- facilityId
```

### inventory_stock
```sql
- id
- item_id
- facilityId
- store_location (e.g., "Dental Department")
- quantity_on_hand
- quantity_available
- quantity_reserved
- minimum_stock_level
```

### inventory_transactions
```sql
- transaction_id
- item_id
- facilityId
- transaction_type ("transfer")
- quantity
- from_location ("Main Store")
- to_location ("Dental Department")
- reference_type ("requisition")
- reference_id (requisition ID)
```

---

## Benefits

### Accountability
- Know exactly what each department has
- Track department consumption
- Identify waste and overuse

### Cost Control
- Allocate costs to departments
- Monitor department budgets
- Optimize stock distribution

### Efficiency
- Reduce stockouts in departments
- Enable inter-department sharing
- Minimize duplicate stock

### Compliance
- Audit trail for all movements
- Department-level reporting
- Regulatory compliance

---

## Future Enhancements

Potential improvements:
- Department stock limits
- Auto-replenishment for departments
- Department consumption forecasting
- Mobile app for department stock checks
- Barcode scanning for transfers
- Department stock alerts
- Budget integration
- Approval workflow for transfers

---

## Quick Reference

### View Department Stock
```
Inventory → Stock by Location → Select Department
```

### Issue to Department
```
Inventory → Requisitions → Approve → Issue
(Automatically transfers to department)
```

### Transfer Between Departments
```
Inventory → Stock Transfer → From/To Department
```

### Department Reports
```
Inventory → Reports → Filter by Location
```

### Check Transaction History
```
Inventory → Reports → Movement Report → Filter by Department
```

---

## Migration Checklist

- [ ] Run department locations migration
- [ ] Verify locations created in database
- [ ] Test requisition issue (should transfer to department)
- [ ] Check Stock by Location view
- [ ] Verify department stock shows correctly
- [ ] Test inter-department transfer
- [ ] Review transaction history
- [ ] Train department staff
- [ ] Update SOPs
- [ ] Communicate changes to users
