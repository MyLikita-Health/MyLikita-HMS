# Inventory Auto-Generated Item Codes - Implementation Complete

## Overview
Item codes are now automatically generated based on category selection, with a 3-letter category prefix and 4-digit sequential number (e.g., MED-0001, DEN-0042).

## Changes Made

### 1. Database Schema
**File:** `backend/sql/add_inventory_categories_table.sql`

Created two new tables:
- `inventory_categories` - Stores category definitions with 3-letter codes
- `inventory_item_code_counter` - Tracks sequential numbering per category per facility

Default categories included:
- MED (Medications)
- MDC (Medical Supplies)
- EQP (Equipment)
- CON (Consumables)
- DEN (Dental Supplies)
- LAB (Laboratory Reagents)
- SUR (Surgical Supplies)
- DIA (Diagnostic Supplies)
- PPE (Personal Protective Equipment)
- OFF (Office Supplies)

### 2. Backend API
**File:** `backend/controller/inventory.js`

Added two new endpoints:
- `getCategories()` - Fetch all categories from database
- `generateItemCode()` - Auto-generate next item code for a category

**File:** `backend/routes/inventory.js`

Added routes:
- `GET /inventory/categories` - Get all categories
- `GET /inventory/generate-item-code?category=X&facilityId=Y` - Generate item code

### 3. Frontend Updates
**File:** `frontend/src/components/inventory/ItemsManagement.jsx`

Changes:
- Categories now fetched from database instead of hardcoded
- Storage locations now fetched from database and displayed as dropdown
- Item code field is now read-only with auto-generation
- When category is selected, item code is automatically generated
- Item code format: `CATEGORY_CODE-0001` (e.g., MED-0001)
- Storage location shows location name and type (e.g., "Main Store (warehouse)")

## Migration Steps

### Step 1: Run Database Migration
```bash
mysql -u root prime < backend/sql/add_inventory_categories_table.sql
```

This will:
- Create `inventory_categories` table
- Create `inventory_item_code_counter` table
- Insert 10 default categories

### Step 2: Restart Backend Server
```bash
cd backend
npm start
```

### Step 3: Test the Feature

1. Navigate to Inventory → Items Management
2. Click "Add New Item"
3. Select a category from the dropdown
4. Item code will be automatically generated (e.g., MED-0001)
5. Select a storage location from the dropdown
6. Fill in other details and save

## Item Code Format

Format: `XXX-NNNN`
- XXX = 3-letter category code
- NNNN = 4-digit sequential number (padded with zeros)

Examples:
- MED-0001 (First medication)
- MED-0002 (Second medication)
- DEN-0001 (First dental supply)
- LAB-0042 (42nd laboratory reagent)

## Sequential Numbering

- Each category has its own counter
- Counters are per facility (multi-tenant support)
- Numbers increment automatically
- No gaps or duplicates

## Adding New Categories

To add a new category:

```sql
INSERT INTO inventory_categories (category_name, category_code, description)
VALUES ('Category Name', 'ABC', 'Description');
```

Rules:
- `category_code` must be exactly 3 uppercase letters
- `category_code` must be unique
- `category_name` should be descriptive

## Benefits

1. **Consistency** - All item codes follow the same format
2. **Organization** - Easy to identify item type by prefix
3. **No Duplicates** - Sequential numbering prevents conflicts
4. **User-Friendly** - No manual code entry required
5. **Scalable** - Supports up to 9,999 items per category per facility

## Notes

- Item codes cannot be changed after creation (disabled field when editing)
- Categories can be managed in the database
- Each facility has independent counters
- Old items with manual codes are not affected
