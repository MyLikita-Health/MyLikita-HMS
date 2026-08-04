# Inventory Export & Import - Quick Start Guide

## Overview

The inventory module now supports full data export and import capabilities, making it easy to:
- Export inventory data to Excel or CSV
- Import bulk items from spreadsheets
- Export reports to PDF
- Download templates for data entry

---

## Export Features

### 1. Export All Items to Excel

**From Items Management:**
1. Navigate to Inventory → Items Management
2. Click the "Export Excel" button (green button next to "Add New Item")
3. File downloads automatically as `inventory_items.xlsx`

**What's Included:**
- Item code, name, category
- Unit of measure, description
- Stock levels (min, reorder, max, current)
- Barcode information
- Active status

**Use Cases:**
- Backup inventory data
- Share with external systems
- Offline analysis in Excel
- Reporting to management

---

### 2. Export Reports to PDF

**From Reports & Analytics:**
1. Navigate to Inventory → Reports & Analytics
2. Select filters (date range, category, location)
3. Click "Generate Report" for any report type
4. Once report displays, click "Export PDF"
5. PDF opens in new tab for download

**Available Reports:**
- Stock Valuation Report
- Movement Report
- Consumption Analysis
- Reorder Report
- Expiry Report
- Supplier Performance

**Use Cases:**
- Management presentations
- Audit documentation
- Printed reports
- Email distribution

---

### 3. Export Items to CSV

**Via API:**
```
GET /inventory/export/items/csv?facilityId={your-facility-id}
```

**Use Cases:**
- Import into other systems
- Data analysis tools
- Database migrations
- Integration with ERP systems

---

## Import Features

### 1. Download Import Template

**Steps:**
1. Navigate to Inventory → Import Items
2. Click "Download Template" button
3. Template downloads as `inventory_import_template.xlsx`

**Template Includes:**
- Sample data (2 rows)
- All required columns
- Proper formatting
- Column descriptions

**Template Columns:**
- `item_code` (Required) - Unique identifier
- `item_name` (Required) - Item name
- `category` (Optional) - Default: "General"
- `unit_of_measure` (Optional) - Default: "Units"
- `description` (Optional)
- `minimum_stock_level` (Optional) - Default: 0
- `reorder_level` (Optional) - Default: 0
- `maximum_stock_level` (Optional) - Default: 0

---

### 2. Prepare Your Data

**Required Fields:**
- `item_code` - Must be unique
- `item_name` - Cannot be empty

**Optional Fields:**
- All other fields have defaults
- Leave blank to use defaults

**Tips:**
- Use consistent category names
- Use standard units (Tablets, Boxes, Liters, etc.)
- Keep item codes short and meaningful
- Avoid special characters in item codes

**Example Data:**
```
item_code | item_name           | category        | unit_of_measure | minimum_stock_level
MED001    | Paracetamol 500mg   | Medicines       | Tablets         | 100
SUP001    | Surgical Gloves     | Supplies        | Boxes           | 50
DEN001    | Dental Cement       | Dental Supplies | Tubes           | 20
```

---

### 3. Import Items

**Steps:**
1. Navigate to Inventory → Import Items
2. Click "Select File to Import"
3. Choose your Excel (.xlsx, .xls) or CSV file
4. Click "Import Items" button
5. Wait for processing (progress bar shows)
6. Review results

**What Happens:**
- File is validated
- Each row is checked for:
  - Required fields
  - Duplicate item codes
  - Valid data types
- Valid items are imported
- Errors are reported with row numbers

---

### 4. Review Import Results

**Success Summary:**
- Total records processed
- Successfully imported count
- Error count

**Error Details Table:**
Shows for each error:
- Row number in your file
- Item code and name
- Error message

**Success Details Table:**
Shows imported items:
- Row number
- Item code and name
- Category assigned

**Common Errors:**
- "Missing required fields" - item_code or item_name is empty
- "Item code already exists" - Duplicate in database
- "Invalid data type" - Wrong format for numeric fields

---

## Step-by-Step: Bulk Import Workflow

### Scenario: Import 50 new dental supplies

**Step 1: Download Template**
1. Go to Import Items
2. Click "Download Template"
3. Open in Excel

**Step 2: Prepare Data**
1. Delete sample rows
2. Add your 50 items
3. Fill required columns (item_code, item_name)
4. Fill optional columns (category, unit, stock levels)
5. Save file

**Step 3: Validate Data**
- Check no duplicate item codes
- Check all required fields filled
- Check numeric fields are numbers
- Check no special characters

**Step 4: Import**
1. Go to Import Items
2. Select your file
3. Click Import
4. Wait for completion

**Step 5: Review Results**
- Check success count (should be 50)
- If errors, note row numbers
- Fix errors in Excel
- Re-import failed rows

**Step 6: Verify**
1. Go to Items Management
2. Search for imported items
3. Verify data is correct
4. Set up stock levels if needed

---

## Tips & Best Practices

### For Export

**Excel Export:**
- Use for data backup (weekly recommended)
- Use for offline analysis
- Use for sharing with non-technical users

**CSV Export:**
- Use for system integrations
- Use for database migrations
- Use for data analysis tools

**PDF Export:**
- Use for management reports
- Use for audit documentation
- Use for printed materials

### For Import

**Before Import:**
- Always download and use the template
- Test with small batch first (5-10 items)
- Keep original file as backup
- Validate data in Excel first

**During Import:**
- Don't close browser during upload
- Wait for completion message
- Don't refresh page

**After Import:**
- Review all errors
- Fix and re-import failed rows
- Verify data in Items Management
- Update stock levels if needed

**Data Quality:**
- Use consistent naming conventions
- Use standard categories
- Use standard units of measure
- Keep item codes meaningful
- Avoid special characters

---

## Troubleshooting

### Export Issues

**"No data to export"**
- Check you have items in inventory
- Check facilityId is correct
- Try refreshing page

**"Download failed"**
- Check browser download settings
- Check popup blocker
- Try different browser

**"PDF not opening"**
- Check PDF reader installed
- Check popup blocker
- Try "Save As" instead

### Import Issues

**"No file uploaded"**
- Ensure file is selected
- Check file size (< 10MB recommended)
- Try different file

**"Invalid file format"**
- Only .xlsx, .xls, .csv supported
- Check file extension
- Try saving as .xlsx

**"All items failed"**
- Check template format matches
- Check column names are correct
- Check required fields filled
- Try with template file first

**"Some items failed"**
- Review error details table
- Fix errors in Excel
- Re-import failed rows only

**"Duplicate item codes"**
- Check existing items first
- Use unique item codes
- Or update existing items instead

---

## Advanced Usage

### Bulk Update Workflow

To update existing items:
1. Export current items to Excel
2. Modify data in Excel
3. Delete items from database (if needed)
4. Import updated file

**Note:** Import doesn't update existing items, only creates new ones.

### Integration with Other Systems

**Export for ERP:**
1. Export to CSV
2. Map columns to ERP format
3. Import into ERP system

**Import from Supplier:**
1. Get supplier catalog (Excel/CSV)
2. Map to template format
3. Add item codes
4. Import into system

### Scheduled Exports

For regular backups:
1. Use API endpoint in cron job
2. Schedule daily/weekly
3. Save to backup location
4. Rotate old backups

**Example cron:**
```bash
# Daily at 2 AM
0 2 * * * curl "http://your-server/inventory/export/items/excel?facilityId=YOUR_ID" -o /backup/inventory_$(date +\%Y\%m\%d).xlsx
```

---

## API Reference

### Export Endpoints

**Export Items to Excel:**
```
GET /inventory/export/items/excel?facilityId={id}
Response: Excel file download
```

**Export Items to CSV:**
```
GET /inventory/export/items/csv?facilityId={id}
Response: CSV file download
```

**Export Report to PDF:**
```
GET /inventory/export/report/pdf?facilityId={id}&reportType={type}
Response: PDF file download
Types: valuation, movement, consumption, reorder, expiry, supplier
```

**Download Template:**
```
GET /inventory/export/template
Response: Excel template file
```

### Import Endpoint

**Import Items:**
```
POST /inventory/import/items
Content-Type: multipart/form-data
Body:
  - file: Excel or CSV file
  - facilityId: Your facility ID
  - userId: Your user ID

Response:
{
  "success": true,
  "imported": 45,
  "errors": 5,
  "total": 50,
  "details": {
    "imported": [...],
    "errors": [...]
  }
}
```

---

## Support

### Common Questions

**Q: Can I import items with stock levels?**
A: No, import only creates items. Use GRN to add stock.

**Q: Can I update existing items via import?**
A: No, import only creates new items. Update manually or delete and re-import.

**Q: What's the maximum file size?**
A: No hard limit, but recommend < 10MB (~ 10,000 items).

**Q: Can I import multiple categories at once?**
A: Yes, just use different category values in the category column.

**Q: Can I import barcodes?**
A: Not yet, use Barcode Management after import.

### Getting Help

If you encounter issues:
1. Check this guide first
2. Review error messages carefully
3. Try with template file
4. Check backend logs
5. Contact system administrator

---

## Summary

**Export Capabilities:**
- ✅ Excel export (all items with stock)
- ✅ CSV export (all items)
- ✅ PDF export (reports)
- ✅ Template download

**Import Capabilities:**
- ✅ Excel import (.xlsx, .xls)
- ✅ CSV import
- ✅ Validation and error handling
- ✅ Duplicate detection
- ✅ Detailed results

**Use Cases:**
- ✅ Bulk item creation
- ✅ Data backup and restore
- ✅ System integration
- ✅ Offline data entry
- ✅ Report distribution

---

**Last Updated**: March 7, 2026
**Version**: 1.0
**Status**: Production Ready
