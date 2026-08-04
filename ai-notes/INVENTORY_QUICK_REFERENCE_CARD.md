# Inventory Module - Quick Reference Card

## 🚀 Getting Started

### Installation
```bash
# 1. Install packages
cd backend && npm install xlsx csv-parser csv-writer pdfkit multer

# 2. Run migrations (in order)
mysql -u root prime < backend/sql/add_inventory_locations.sql
node backend/sql/run_add_location_to_grn.js
mysql -u root prime < backend/sql/add_barcode_to_items.sql
mysql -u root prime < backend/sql/add_disposal_tracking.sql
mysql -u root prime < backend/sql/add_filter_presets.sql

# 3. Restart backend
npm start
```

---

## 📋 Menu Structure

```
Inventory Management
├── Dashboard
├── Items Management          [Export Excel]
├── Stock Levels
├── Purchase Orders
├── Goods Received Notes
├── Requisitions
├── Suppliers
├── Locations                 [NEW]
├── Barcode Management        [NEW]
├── Advanced Analytics        [NEW]
├── Auto Reorder              [NEW]
├── Expiry Management         [NEW]
├── Stock Adjustments
├── Stock Transfers
├── Reports & Analytics       [Export PDF]
└── Import Items              [NEW]
```

---

## 🎯 Key Features

### 1. Location Management
- **Path**: Inventory → Locations
- **Actions**: Create, Edit, View, Deactivate
- **Types**: Store, Warehouse, Pharmacy, Clinic, Lab
- **Use**: Track stock across multiple locations

### 2. Barcode Integration
- **Path**: Inventory → Barcode Management
- **Actions**: Generate, Scan, Bulk Generate
- **Formats**: EAN13, UPC, CODE128, QR, CUSTOM
- **Use**: Fast item lookup and data entry

### 3. Advanced Analytics
- **Path**: Inventory → Advanced Analytics
- **KPIs**: Stock Value, Turnover Rate, Stockout Rate, Expiry Risk
- **Charts**: Category Distribution, Top Movers
- **Use**: Data-driven decision making

### 4. Auto Reorder
- **Path**: Inventory → Auto Reorder
- **Features**: Consumption analysis, Stockout prediction, Auto-PO
- **Priority**: CRITICAL, HIGH, MEDIUM, LOW
- **Use**: Never run out of stock

### 5. Expiry Management
- **Path**: Inventory → Expiry Management
- **Features**: Expiry tracking, Disposal workflow, FIFO/FEFO
- **Alerts**: 180 days, 90 days, 30 days, Expired
- **Use**: Reduce wastage

### 6. Reports
- **Path**: Inventory → Reports & Analytics
- **Types**: Valuation, Movement, Consumption, Reorder, Expiry, Supplier
- **Export**: Excel, PDF
- **Use**: Management reporting

### 7. Export & Import
- **Export**: Items Management → Export Excel
- **Import**: Inventory → Import Items
- **Formats**: Excel (.xlsx, .xls), CSV
- **Use**: Bulk operations, data backup

---

## 🔄 Common Workflows

### Create New Item
1. Items Management → Add New Item
2. Fill required fields (code, name, category, unit)
3. Set stock levels (min, reorder, max)
4. Save

### Receive Stock (GRN)
1. Goods Received Notes → Create GRN
2. Select supplier and PO
3. Select location
4. Enter received quantities
5. Approve GRN (posts to stock + accounting)

### Issue Stock
1. Stock Levels → Select item
2. Click Issue
3. Enter quantity and reference
4. Confirm (posts to accounting)

### Transfer Stock
1. Stock Transfers → Create Transfer
2. Select from/to locations
3. Select items and quantities
4. Approve transfer

### Bulk Import Items
1. Import Items → Download Template
2. Fill in Excel
3. Upload file
4. Review results

### Generate Report
1. Reports & Analytics → Select report type
2. Set filters (date, category, location)
3. Generate Report
4. Export to Excel/PDF

---

## 📊 Reports Quick Reference

| Report | Purpose | Key Metrics |
|--------|---------|-------------|
| **Valuation** | Stock value by category | Total value, Item count, Avg cost |
| **Movement** | Transaction history | Quantity in/out, Running balance |
| **Consumption** | Usage patterns | Daily avg, Total consumed, Trend |
| **Reorder** | Items to reorder | Current stock, Reorder level, Status |
| **Expiry** | Expiring items | Days to expiry, Quantity, Value |
| **Supplier** | Supplier performance | GRN count, Total value, Avg delivery |

---

## 🔍 Search & Filters

### Global Search
- **Path**: Advanced Search → Global Search
- **Searches**: Items, Batches, Suppliers, POs, GRNs
- **Use**: Find anything quickly

### Advanced Filters
- **Path**: Advanced Search → Advanced Filters
- **Criteria**: Stock level, Category, Location, Status
- **Save**: Create filter presets
- **Use**: Complex queries

---

## 📈 Analytics KPIs

| KPI | Formula | Good Range |
|-----|---------|------------|
| **Stock Value** | Σ(qty × cost) | Depends on business |
| **Turnover Rate** | COGS / Avg Inventory | 4-6 times/year |
| **Stockout Rate** | Items below min / Total | < 5% |
| **Expiry Risk** | Items expiring soon | < 2% of value |

---

## 🎨 Status Colors

| Color | Meaning | Action |
|-------|---------|--------|
| 🔴 Red | Critical/Expired | Immediate action |
| 🟠 Orange | Warning/Low | Action needed |
| 🟡 Yellow | Caution/Medium | Monitor |
| 🟢 Green | Good/Adequate | No action |
| 🔵 Blue | Info/Excess | Review |

---

## 🔐 Accounting Integration

### GRN Approval
```
Debit:  Inventory (Asset)        $1,000
Credit: Accounts Payable (Liability)  $1,000
```

### Stock Issue
```
Debit:  COGS (Expense)           $500
Credit: Inventory (Asset)        $500
```

### Stock Adjustment (Increase)
```
Debit:  Inventory (Asset)        $100
Credit: Adjustment Account       $100
```

---

## 🚨 Alerts & Notifications

| Alert | Trigger | Action |
|-------|---------|--------|
| **Low Stock** | Below reorder level | Create PO |
| **Critical Stock** | Below minimum | Urgent PO |
| **Expiring Soon** | < 90 days | Plan usage |
| **Expired** | Past expiry | Dispose |
| **Stockout** | Zero stock | Emergency order |

---

## 📱 API Endpoints

### Items
```
GET    /inventory/items
POST   /inventory/items
PUT    /inventory/items/:id
DELETE /inventory/items/:id
```

### Export/Import
```
GET  /inventory/export/items/excel?facilityId={id}
GET  /inventory/export/items/csv?facilityId={id}
GET  /inventory/export/report/pdf?facilityId={id}&reportType={type}
GET  /inventory/export/template
POST /inventory/import/items
```

### Reports
```
GET /inventory/reports/valuation?facilityId={id}
GET /inventory/reports/movement?facilityId={id}
GET /inventory/reports/consumption?facilityId={id}
GET /inventory/reports/reorder?facilityId={id}
GET /inventory/reports/expiry?facilityId={id}
GET /inventory/reports/supplier?facilityId={id}
```

---

## 🛠️ Troubleshooting

### Common Issues

**"Location not found"**
- Create locations first (Inventory → Locations)
- Ensure location is active

**"Barcode not found"**
- Generate barcodes (Barcode Management)
- Check barcode format

**"Import failed"**
- Check template format
- Verify required fields
- Check for duplicates

**"Accounting entry failed"**
- Verify pending_txn procedure exists
- Check database logs

**"Export not working"**
- Check popup blocker
- Verify facilityId
- Try different browser

---

## 📞 Quick Help

### Documentation
- `INVENTORY_PHASE_3_COMPLETE_FINAL.md` - Complete overview
- `INVENTORY_EXPORT_IMPORT_QUICK_START.md` - Export/import guide
- `INVENTORY_FRAMEWORK_FEATURES_COMPLETE.md` - Technical details

### Support
1. Check documentation first
2. Review error messages
3. Check backend logs
4. Contact system administrator

---

## ✅ Daily Checklist

### Morning
- [ ] Check low stock alerts
- [ ] Review expiring items
- [ ] Check pending GRNs
- [ ] Review pending requisitions

### During Day
- [ ] Process GRNs as received
- [ ] Issue stock as requested
- [ ] Update stock adjustments
- [ ] Generate reports as needed

### End of Day
- [ ] Verify all GRNs posted
- [ ] Check stockout items
- [ ] Review day's transactions
- [ ] Export backup (weekly)

---

## 🎯 Best Practices

### Stock Management
✅ Set realistic min/max levels
✅ Use FIFO/FEFO rotation
✅ Regular stock counts
✅ Prompt GRN processing
✅ Monitor expiry dates

### Data Quality
✅ Use consistent naming
✅ Standard categories
✅ Unique item codes
✅ Complete descriptions
✅ Accurate stock levels

### Reporting
✅ Weekly valuation report
✅ Monthly consumption analysis
✅ Regular supplier review
✅ Expiry monitoring
✅ Reorder list review

---

**Version**: 1.0
**Last Updated**: March 7, 2026
**Status**: Production Ready
**Print**: Keep this card handy for quick reference!
