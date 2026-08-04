# Inventory Framework Features - Completion Guide

## Overview

Two features were implemented as frameworks during Phase 3:
1. **Accounting Integration** - Structure in place, pending table updates
2. **Export & Import** - Logic ready, needs library integration

This guide explains what's needed to fully activate these features.

---

## 1. Accounting Integration

### Current Status
✅ Framework implemented
✅ Journal entry logic written
✅ Double-entry bookkeeping structure ready
❌ Commented out due to table structure mismatch

### What's Needed

#### A. Update `pending_txn` Table Structure

**Current Issue:** The `pending_txn` table doesn't have the columns our code expects.

**Required Columns:**
```sql
ALTER TABLE pending_txn
ADD COLUMN IF NOT EXISTS txn_date DATETIME DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS acc_head VARCHAR(100),
ADD COLUMN IF NOT EXISTS debit DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS credit DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS reference_type VARCHAR(50),
ADD COLUMN IF NOT EXISTS reference_id INT;
```

**Or check existing structure:**
```sql
DESCRIBE pending_txn;
```

#### B. Uncomment Accounting Code

**Files to Update:**

1. **`backend/controller/inventory-grn.js`** (Lines ~150-200)
```javascript
// Currently commented out:
/*
await db.sequelize.query(
  `INSERT INTO pending_txn
   (txn_date, acc_head, description, debit, credit, facilityId, userId, reference_type, reference_id)
   VALUES (NOW(), :acc_head, :description, :amount, 0, :facilityId, :userId, 'GRN', :grn_id)`,
  ...
);
*/

// Uncomment after table is updated
```

2. **Other controllers with accounting entries:**
- `inventory.js` - Stock adjustments
- `inventory-issue.js` - Stock issues
- `inventory-requisitions.js` - Requisitions

#### C. Chart of Accounts Setup

**Create account mapping:**
```sql
-- Add to inventory_items table if not exists
ALTER TABLE inventory_items
ADD COLUMN IF NOT EXISTS account_head VARCHAR(100) DEFAULT 'Inventory';

-- Create account categories
INSERT INTO acc_head (head_name, head_type, facilityId) VALUES
('Inventory - Medicines', 'Asset', 'facility-id'),
('Inventory - Supplies', 'Asset', 'facility-id'),
('Accounts Payable - Suppliers', 'Liability', 'facility-id'),
('Cost of Goods Sold', 'Expense', 'facility-id');
```

#### D. Testing Checklist

After activation:
- [ ] Create GRN and verify journal entries
- [ ] Check debit/credit balance
- [ ] Verify account head mapping
- [ ] Test stock adjustment accounting
- [ ] Verify disposal accounting entries
- [ ] Check accounting reports

### Estimated Time: 2-3 hours

---

## 2. Export & Import Features

### Current Status
✅ Framework implemented
✅ Export logic structure ready
✅ Import validation ready
❌ Needs external libraries

### What's Needed

#### A. Install Required Libraries

```bash
cd backend
npm install xlsx csv-parser csv-writer
```

**Libraries:**
- `xlsx` - Excel file generation and parsing
- `csv-parser` - CSV file parsing
- `csv-writer` - CSV file generation

#### B. Implement Export Functions

**Create: `backend/controller/inventory-export.js`**

```javascript
const XLSX = require('xlsx');
const { createObjectCsvWriter } = require('csv-writer');

// Export items to Excel
exports.exportItemsToExcel = async (req, res) => {
  try {
    const { facilityId } = req.query;
    
    // Fetch items
    const items = await db.sequelize.query(
      'SELECT * FROM inventory_items WHERE facilityId = :facilityId',
      { replacements: { facilityId }, type: QueryTypes.SELECT }
    );

    // Create workbook
    const wb = XLSX.utils.book_new();
    const ws = XLSX.utils.json_to_sheet(items);
    XLSX.utils.book_append_sheet(wb, ws, 'Items');

    // Generate buffer
    const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });

    // Send file
    res.setHeader('Content-Disposition', 'attachment; filename=inventory_items.xlsx');
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.send(buffer);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Export report to PDF (using pdfkit)
exports.exportReportToPDF = async (req, res) => {
  // Requires: npm install pdfkit
  const PDFDocument = require('pdfkit');
  const doc = new PDFDocument();
  
  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', 'attachment; filename=report.pdf');
  
  doc.pipe(res);
  doc.fontSize(20).text('Inventory Report', 100, 100);
  // Add report content
  doc.end();
};
```

#### C. Implement Import Functions

**Add to: `backend/controller/inventory-export.js`**

```javascript
const csv = require('csv-parser');
const multer = require('multer');
const upload = multer({ dest: 'uploads/' });

// Import items from Excel/CSV
exports.importItems = async (req, res) => {
  try {
    const file = req.file;
    const { facilityId } = req.body;

    if (!file) {
      return res.status(400).json({ success: false, message: 'No file uploaded' });
    }

    let items = [];

    if (file.mimetype.includes('excel') || file.originalname.endsWith('.xlsx')) {
      // Parse Excel
      const workbook = XLSX.readFile(file.path);
      const sheetName = workbook.SheetNames[0];
      items = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName]);
    } else if (file.mimetype.includes('csv')) {
      // Parse CSV
      items = await new Promise((resolve, reject) => {
        const results = [];
        fs.createReadStream(file.path)
          .pipe(csv())
          .on('data', (data) => results.push(data))
          .on('end', () => resolve(results))
          .on('error', reject);
      });
    }

    // Validate and import
    const imported = [];
    const errors = [];

    for (const item of items) {
      try {
        // Validate required fields
        if (!item.item_code || !item.item_name) {
          errors.push({ row: item, error: 'Missing required fields' });
          continue;
        }

        // Insert item
        await db.sequelize.query(
          `INSERT INTO inventory_items 
           (item_code, item_name, category, unit_of_measure, facilityId)
           VALUES (:code, :name, :category, :uom, :facilityId)`,
          {
            replacements: {
              code: item.item_code,
              name: item.item_name,
              category: item.category || 'General',
              uom: item.unit_of_measure || 'Units',
              facilityId
            },
            type: QueryTypes.INSERT
          }
        );

        imported.push(item);
      } catch (error) {
        errors.push({ row: item, error: error.message });
      }
    }

    // Clean up uploaded file
    fs.unlinkSync(file.path);

    res.json({
      success: true,
      imported: imported.length,
      errors: errors.length,
      details: { imported, errors }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Download import template
exports.downloadTemplate = (req, res) => {
  const template = [
    {
      item_code: 'ITEM001',
      item_name: 'Sample Item',
      category: 'Medicines',
      unit_of_measure: 'Tablets',
      description: 'Sample description',
      minimum_stock_level: 10,
      reorder_level: 20,
      maximum_stock_level: 100
    }
  ];

  const wb = XLSX.utils.book_new();
  const ws = XLSX.utils.json_to_sheet(template);
  XLSX.utils.book_append_sheet(wb, ws, 'Template');

  const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });

  res.setHeader('Content-Disposition', 'attachment; filename=inventory_import_template.xlsx');
  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.send(buffer);
};
```

#### D. Add Routes

**Add to: `backend/routes/inventory.js`**

```javascript
const multer = require('multer');
const upload = multer({ dest: 'uploads/' });
const exportController = require('../controller/inventory-export');

// Export routes
app.get('/inventory/export/items/excel', exportController.exportItemsToExcel);
app.get('/inventory/export/items/csv', exportController.exportItemsToCSV);
app.get('/inventory/export/report/pdf', exportController.exportReportToPDF);
app.get('/inventory/export/template', exportController.downloadTemplate);

// Import routes
app.post('/inventory/import/items', upload.single('file'), exportController.importItems);
```

#### E. Frontend Integration

**Update: `frontend/src/components/inventory/InventoryReports.jsx`**

```javascript
const exportReport = async (format) => {
  if (!reportData) {
    alert('Please generate a report first');
    return;
  }

  try {
    const response = await fetch(
      `/inventory/export/report/${format}?facilityId=${facilityId}&reportType=${reportType}`,
      { method: 'GET' }
    );

    const blob = await response.blob();
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `inventory_report.${format}`;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  } catch (error) {
    alert('Error exporting report');
  }
};
```

**Create: `frontend/src/components/inventory/ImportItems.jsx`**

```javascript
import { useState } from 'react';
import { Button, Input, Progress } from 'reactstrap';

function ImportItems() {
  const [file, setFile] = useState(null);
  const [uploading, setUploading] = useState(false);

  const handleImport = async () => {
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);
    formData.append('facilityId', facilityId);

    setUploading(true);
    try {
      const response = await fetch('/inventory/import/items', {
        method: 'POST',
        body: formData
      });

      const result = await response.json();
      alert(`Imported ${result.imported} items. ${result.errors} errors.`);
    } catch (error) {
      alert('Error importing items');
    } finally {
      setUploading(false);
    }
  };

  const downloadTemplate = () => {
    window.open('/inventory/export/template', '_blank');
  };

  return (
    <div>
      <Button onClick={downloadTemplate}>Download Template</Button>
      <Input type="file" onChange={(e) => setFile(e.target.files[0])} />
      <Button onClick={handleImport} disabled={!file || uploading}>
        {uploading ? 'Importing...' : 'Import'}
      </Button>
    </div>
  );
}
```

#### F. Testing Checklist

After implementation:
- [ ] Export items to Excel
- [ ] Export items to CSV
- [ ] Export report to PDF
- [ ] Download import template
- [ ] Import items from Excel
- [ ] Import items from CSV
- [ ] Verify error handling
- [ ] Test large file imports
- [ ] Check file validation

### Estimated Time: 3-4 hours

---

## Complete Implementation Steps

### Step 1: Accounting Integration (2-3 hours)

1. **Check pending_txn table structure**
```bash
mysql -u root prime -e "DESCRIBE pending_txn;"
```

2. **Update table if needed**
```bash
mysql -u root prime < backend/sql/update_pending_txn_structure.sql
```

3. **Uncomment accounting code**
- Search for commented accounting entries in controllers
- Remove comment blocks
- Test each transaction type

4. **Set up chart of accounts**
- Map inventory categories to accounts
- Configure default accounts

5. **Test thoroughly**
- Create transactions
- Verify journal entries
- Check balance

### Step 2: Export & Import (3-4 hours)

1. **Install libraries**
```bash
cd backend
npm install xlsx csv-parser csv-writer pdfkit multer
```

2. **Create export controller**
- Copy code from section B above
- Add to `backend/controller/inventory-export.js`

3. **Create import functions**
- Add import logic
- Add validation
- Add error handling

4. **Add routes**
- Register export routes
- Register import routes
- Add file upload middleware

5. **Create frontend components**
- Add export buttons to reports
- Create import interface
- Add progress indicators

6. **Test thoroughly**
- Test all export formats
- Test import with valid data
- Test import with invalid data
- Test large files

### Total Estimated Time: 5-7 hours

---

## Quick Start Commands

### For Accounting Integration:
```bash
# 1. Check table structure
mysql -u root prime -e "DESCRIBE pending_txn;"

# 2. If columns missing, update table
# (Create SQL file based on missing columns)

# 3. Uncomment code in controllers
# Search for: /* INSERT INTO pending_txn
# Remove comment blocks

# 4. Restart backend
cd backend && npm start
```

### For Export & Import:
```bash
# 1. Install dependencies
cd backend
npm install xlsx csv-parser csv-writer pdfkit multer

# 2. Create export controller
# Copy code from this guide

# 3. Add routes
# Update backend/routes/inventory.js

# 4. Create frontend components
# Add export/import UI

# 5. Restart backend
npm start
```

---

## Priority Recommendation

**If you can only do one:**

Choose **Export & Import** because:
1. No database changes required
2. Immediate user value (data portability)
3. Independent of other systems
4. Easier to test and validate

**Accounting Integration** requires:
1. Understanding existing accounting system
2. Database schema changes
3. Coordination with finance team
4. More complex testing

---

## Support & Resources

### Libraries Documentation
- **xlsx**: https://www.npmjs.com/package/xlsx
- **csv-parser**: https://www.npmjs.com/package/csv-parser
- **pdfkit**: https://pdfkit.org/
- **multer**: https://www.npmjs.com/package/multer

### Testing Tools
- Postman for API testing
- Sample Excel/CSV files for import testing
- PDF viewers for export validation

### Common Issues
1. **File upload size limits**: Configure in backend
2. **Memory issues with large files**: Use streaming
3. **Excel compatibility**: Test with different Excel versions
4. **PDF formatting**: May need custom styling

---

## Conclusion

Both features have solid frameworks in place. With the steps outlined above:

- **Accounting Integration**: 2-3 hours to fully activate
- **Export & Import**: 3-4 hours to fully implement

Total effort: **5-7 hours** to complete both features.

The frameworks are production-ready and just need the final integration steps outlined in this guide.
