# Testing Auto-Generated Item Codes

## Prerequisites

1. Run the database migration:
```bash
mysql -u root prime < backend/sql/add_inventory_categories_table.sql
```

2. Restart backend server:
```bash
cd backend
npm start
```

3. Restart frontend (if needed):
```bash
cd frontend
npm start
```

## Test Scenarios

### Test 1: View Categories
**Endpoint:** `GET /inventory/categories`

**Expected Result:**
```json
{
  "success": true,
  "categories": [
    {
      "id": 1,
      "category_name": "Medications",
      "category_code": "MED",
      "description": "Pharmaceutical medications and drugs"
    },
    ...
  ]
}
```

### Test 2: Generate Item Code
**Endpoint:** `GET /inventory/generate-item-code?category=Medications&facilityId=1`

**Expected Result:**
```json
{
  "success": true,
  "itemCode": "MED-0001"
}
```

**Second Call (same category):**
```json
{
  "success": true,
  "itemCode": "MED-0002"
}
```

### Test 3: Create Item with Auto-Generated Code

1. Open Inventory → Items Management
2. Click "Add New Item"
3. Select "Medications" from Category dropdown
4. Observe: Item Code field auto-populates with "MED-0001"
5. Select a storage location from the dropdown (e.g., "Main Store (warehouse)")
6. Fill in:
   - Item Name: "Paracetamol 500mg"
   - Sub Category: "Analgesics"
   - Unit of Measure: "tablets"
   - Description: "Pain reliever"
7. Click "Create Item"
8. Verify: Item created successfully

### Test 4: Storage Location Dropdown

1. Open "Add New Item" modal
2. Click on Storage Location dropdown
3. Observe: List of locations with types (e.g., "Main Store (warehouse)")
4. Verify: All locations from database are shown
5. Select a location
6. Verify: Location is properly saved with item

### Test 5: Sequential Numbering

1. Create another item with same category
2. Select "Medications" again
3. Observe: Item Code shows "MED-0002"
4. Complete and save
5. Verify: Second item created with MED-0002

### Test 6: Different Categories

1. Create item with "Dental Supplies" category
2. Observe: Item Code shows "DEN-0001"
3. Create item with "Laboratory Reagents"
4. Observe: Item Code shows "LAB-0001"
5. Verify: Each category has independent numbering

### Test 7: Multi-Facility Support

1. Create item for facilityId=1, category="Medications"
2. Note the item code (e.g., MED-0005)
3. Create item for facilityId=2, category="Medications"
4. Verify: Item code starts at MED-0001 for facility 2
5. Each facility has independent counters

### Test 8: Edit Existing Item

1. Click "Edit" on an existing item
2. Observe: Item Code field is disabled
3. Verify: Cannot change item code after creation
4. Change other fields (name, description)
5. Save successfully

### Test 9: Item Code Read-Only

1. Open "Add New Item" modal
2. Try to type in Item Code field
3. Verify: Field is read-only
4. Only way to set code is by selecting category

## Expected Behavior

✅ Item codes auto-generate when category is selected
✅ Format is always XXX-NNNN (3 letters + 4 digits)
✅ Sequential numbering per category
✅ Independent counters per facility
✅ Item code field is read-only
✅ Cannot edit item code after creation
✅ Categories load from database
✅ Storage locations load from database with type information
✅ No duplicate codes possible

## Troubleshooting

### Issue: Categories not loading
**Solution:** Check database migration ran successfully
```bash
mysql -u root prime -e "SELECT * FROM inventory_categories;"
```

### Issue: Locations not loading
**Solution:** Check locations exist in database
```bash
mysql -u root prime -e "SELECT * FROM inventory_locations WHERE facilityId = 1;"
```

If no locations exist, create some:
```bash
mysql -u root prime < backend/sql/add_inventory_locations.sql
```

### Issue: Item code not generating
**Solution:** Check browser console for API errors
- Verify backend is running
- Check network tab for API call
- Verify facilityId is present in user session

### Issue: Duplicate item codes
**Solution:** Check counter table
```bash
mysql -u root prime -e "SELECT * FROM inventory_item_code_counter;"
```

### Issue: Wrong category code
**Solution:** Verify category mapping
```bash
mysql -u root prime -e "SELECT category_name, category_code FROM inventory_categories;"
```

## API Testing with cURL

### Get Categories
```bash
curl http://localhost:5000/inventory/categories
```

### Generate Item Code
```bash
curl "http://localhost:5000/inventory/generate-item-code?category=Medications&facilityId=1"
```

### Create Item
```bash
curl -X POST http://localhost:5000/inventory/items \
  -H "Content-Type: application/json" \
  -d '{
    "item_code": "MED-0001",
    "item_name": "Paracetamol 500mg",
    "category": "Medications",
    "unit_of_measure": "tablets",
    "facilityId": 1
  }'
```

## Success Criteria

- ✅ All 9 test scenarios pass
- ✅ No console errors
- ✅ Item codes follow XXX-NNNN format
- ✅ Sequential numbering works correctly
- ✅ Multi-facility support verified
- ✅ Storage locations dropdown works
- ✅ UI is user-friendly and intuitive
