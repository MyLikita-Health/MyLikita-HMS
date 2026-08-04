# Inventory Location Integration - Migration Guide

## Overview
This guide helps you add location support to the GRN (Goods Received Notes) system.

---

## What's Being Added

The `inventory_grn` table needs a `location_id` column to store which location stock should be posted to when a GRN is approved.

**Changes:**
- Add `location_id` column to `inventory_grn` table
- Add index for performance
- Update GRN creation to save location
- Update GRN approval to use saved location

---

## Migration Steps

### Step 1: Run the Database Migration

**Option A: Using Node.js Script (Recommended)**
```bash
cd backend/sql
node run_add_location_to_grn.js
```

**Option B: Manual SQL Execution**
```bash
mysql -u root prime < backend/sql/add_location_to_grn.sql
```

### Step 2: Verify Migration

Check that the column was added:
```sql
DESCRIBE inventory_grn;
```

You should see `location_id` column after `supplier_id`.

### Step 3: Restart Backend Server

Stop and restart your backend server to pick up the changes:
```bash
# Stop the server (Ctrl+C)
# Then restart it
cd backend
npm start
```

---

## Testing the Integration

### Test 1: Create GRN with Location

1. Go to Inventory → GRN → Create GRN
2. Select a supplier
3. **Select a location** from the dropdown (new field)
4. Add items and quantities
5. Submit the GRN

**Expected:** GRN created successfully with location saved

### Test 2: Approve GRN

1. Go to the GRN you just created
2. Click "Approve & Post to Stock"
3. Check the stock levels

**Expected:** 
- Stock posted to the selected location
- Batch created with correct location
- Transaction recorded with location details

### Test 3: Verify Stock Location

1. Go to Inventory → Stock Levels
2. Filter by the location you selected
3. Find the item from your GRN

**Expected:** Item shows correct quantity at the selected location

---

## Backward Compatibility

The system handles GRNs created before this migration:

- **Old GRNs (no location_id):** Will default to "Main Store" when approved
- **New GRNs:** Will use the selected location
- **Location parameter:** Can be passed during approval to override

---

## Troubleshooting

### Error: "Unknown column 'g.location_id'"

**Cause:** Migration not run yet

**Solution:** Run the migration script (Step 1 above)

### Error: "Cannot add foreign key constraint"

**Cause:** Referenced location doesn't exist

**Solution:** The migration doesn't add foreign key by default. If you uncommented it, make sure inventory_locations table exists and has data.

### GRN still posting to "Main Store"

**Cause:** Location not selected during GRN creation

**Solution:** 
1. Make sure you select a location when creating the GRN
2. Verify the location dropdown is populated
3. Check that location_id is being sent in the API request

---

## API Changes

### Create GRN Endpoint

**Before:**
```json
POST /inventory/grn
{
  "supplier_id": 1,
  "received_date": "2026-03-07",
  "items": [...]
}
```

**After:**
```json
POST /inventory/grn
{
  "supplier_id": 1,
  "location_id": 5,  // NEW FIELD
  "received_date": "2026-03-07",
  "items": [...]
}
```

### Approve GRN Endpoint

**Before:**
```json
PUT /inventory/grn/:id/approve
{
  "approvedBy": 5,
  "facilityId": "uuid"
}
```

**After (optional location override):**
```json
PUT /inventory/grn/:id/approve
{
  "approvedBy": 5,
  "facilityId": "uuid",
  "location_id": 5  // OPTIONAL: Override GRN's saved location
}
```

---

## Database Schema

### Before Migration
```sql
CREATE TABLE inventory_grn (
  id INT PRIMARY KEY AUTO_INCREMENT,
  grn_number VARCHAR(50),
  po_id INT,
  supplier_id INT,
  -- location_id missing
  facilityId VARCHAR(255),
  ...
);
```

### After Migration
```sql
CREATE TABLE inventory_grn (
  id INT PRIMARY KEY AUTO_INCREMENT,
  grn_number VARCHAR(50),
  po_id INT,
  supplier_id INT,
  location_id INT,  -- NEW COLUMN
  facilityId VARCHAR(255),
  ...
  INDEX idx_grn_location (location_id)
);
```

---

## Rollback (If Needed)

If you need to remove the location_id column:

```sql
ALTER TABLE inventory_grn DROP COLUMN location_id;
```

**Warning:** This will delete all location associations from existing GRNs.

---

## Next Steps

After successful migration:

1. ✅ Test GRN creation with location selection
2. ✅ Test GRN approval and stock posting
3. ✅ Verify stock appears in correct location
4. ✅ Test stock adjustments with locations
5. ✅ Test stock transfers between locations
6. ✅ Generate reports filtered by location

---

## Support

If you encounter issues:

1. Check backend console for error messages
2. Verify database connection
3. Ensure inventory_locations table has data
4. Check that location dropdown is populated in UI
5. Review browser console for frontend errors

---

## Files Modified

- `backend/sql/add_location_to_grn.sql` - Migration SQL
- `backend/sql/run_add_location_to_grn.js` - Migration script
- `backend/controller/inventory-grn.js` - Updated createGRN and approveGRN
- `frontend/src/components/inventory/GRNForm.jsx` - Added location selector

---

## Summary

This migration enables multi-location support for GRN processing, allowing you to:
- Specify which location receives stock from each GRN
- Track stock by location accurately
- Generate location-specific reports
- Manage inventory across multiple storage areas

The system maintains backward compatibility with existing GRNs while enabling new location-aware workflows.
