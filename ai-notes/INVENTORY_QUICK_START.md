# Inventory Module - Quick Start Guide

## Setup & Installation

### 1. Database Migration
```bash
cd backend/sql
node run_inventory_migration.js
```

This creates:
- 14 inventory tables
- 2 views for reporting
- Sample data (optional)

### 2. Start the Application
```bash
# Backend
cd backend
npm start

# Frontend
cd frontend
npm run dev
```

### 3. Access Inventory Module
- Navigate to: `http://localhost:3000/inventory`
- Or click "Inventory" in the main navigation menu

## Module Overview

### Dashboard
- 6 KPI cards (Total Items, Stock Value, Low Stock, Expiring Soon, Pending POs, Pending Requisitions)
- Recent activity feed
- Quick action buttons

### Main Features

#### 1. Items Management
- Add/Edit/View inventory items
- Set reorder levels and expiry tracking
- Categorize items
- Link to chart of accounts

#### 2. Stock Levels
- Real-time stock monitoring
- Filter by location, category, status
- View stock by location
- Identify low stock and expiring items

#### 3. Purchase Orders
- Create POs with multiple items
- Track PO status (draft, submitted, approved, received)
- Link to suppliers
- Generate GRN from PO

#### 4. Goods Received Notes (GRN)
- Record stock receipts
- Batch tracking
- Expiry date management
- Automatic accounting entries
- Link to purchase orders

#### 5. Requisitions
- Department-based stock requests
- Multi-item requisitions
- Approval workflow
- Issue stock to departments

#### 6. Suppliers
- Manage supplier information
- Track payment terms
- Monitor supplier performance
- Link to chart of accounts

#### 7. Stock Adjustments
- Increase/decrease stock
- Reasons: damaged, expired, lost, found, recount
- Approval workflow
- Automatic accounting entries

#### 8. Stock Transfers
- Move stock between locations
- Track transfer status
- Audit trail

#### 9. Reports & Analytics
- Stock Valuation Report
- Movement Report
- Consumption Analysis
- Reorder Report
- Expiry Report
- Supplier Performance
- Export to Excel/PDF

## Common Workflows

### Workflow 1: Receiving New Stock
1. Go to **Purchase Orders** → Create PO
2. Add items and quantities
3. Submit for approval (click View on the PO, then "Submit for Approval")
4. Approver clicks View on the PO and clicks "Approve" button
5. Once approved, go to **GRN** → Create GRN
6. Select the approved PO from dropdown
7. Enter received quantities and batch details
8. Submit GRN
9. Stock levels automatically updated
10. Accounting entries created in pending_txn

### Workflow 2: Department Requisition
1. Go to **Requisitions** → Create Requisition
2. Select department
3. Add items and quantities
4. Submit requisition
5. Approver reviews and approves
6. Stock issued to department
7. Stock levels automatically updated

### Workflow 3: Stock Adjustment
1. Go to **Stock Adjustments** → Create Adjustment
2. Select item and location
3. Choose adjustment type (increase/decrease)
4. Enter quantity and reason
5. Submit for approval
6. Once approved, stock updated
7. Accounting entries created

### Workflow 4: Stock Transfer
1. Go to **Stock Transfers** → Create Transfer
2. Select item
3. Choose source and destination locations
4. Enter quantity
5. Submit transfer
6. Stock levels updated for both locations

## API Endpoints

### Items
- `GET /inventory/items` - List items
- `POST /inventory/items` - Create item
- `PUT /inventory/items/:id` - Update item
- `GET /inventory/items/:id` - Get item details

### Stock
- `GET /inventory/stock-levels` - Get stock levels
- `GET /inventory/stock-levels/:itemId` - Get item stock by location

### Purchase Orders
- `GET /inventory/purchase-orders` - List POs
- `POST /inventory/purchase-orders` - Create PO
- `GET /inventory/purchase-orders/:id` - Get PO details
- `PUT /inventory/purchase-orders/:id/status` - Update PO status

### GRN
- `GET /inventory/grn` - List GRNs
- `POST /inventory/grn` - Create GRN
- `GET /inventory/grn/:id` - Get GRN details
- `PUT /inventory/grn/:id/approve` - Approve GRN

### Requisitions
- `GET /inventory/requisitions` - List requisitions
- `POST /inventory/requisitions` - Create requisition
- `GET /inventory/requisitions/:id` - Get requisition details
- `PUT /inventory/requisitions/:id/approve` - Approve requisition
- `POST /inventory/requisitions/:id/issue` - Issue stock

### Suppliers
- `GET /inventory/suppliers` - List suppliers
- `POST /inventory/suppliers` - Create supplier
- `PUT /inventory/suppliers/:id` - Update supplier

### Stock Adjustments
- `GET /inventory/stock-adjustment` - List adjustments
- `POST /inventory/stock-adjustment` - Create adjustment
- `PUT /inventory/stock-adjustment/:id/approve` - Approve adjustment

### Stock Transfers
- `GET /inventory/stock-transfer` - List transfers
- `POST /inventory/stock-transfer` - Create transfer
- `PUT /inventory/stock-transfer/:id/complete` - Complete transfer

### Reports
- `GET /inventory/reports/valuation` - Stock valuation
- `GET /inventory/reports/movement` - Stock movements
- `GET /inventory/reports/consumption` - Consumption analysis
- `GET /inventory/reports/reorder` - Reorder report
- `GET /inventory/reports/expiry` - Expiry report
- `GET /inventory/reports/supplier` - Supplier performance

## Database Tables

### Core Tables
- `inventory_items` - Item master data
- `inventory_categories` - Item categories
- `inventory_locations` - Storage locations
- `inventory_stock` - Stock levels by location and batch
- `inventory_suppliers` - Supplier information

### Transaction Tables
- `inventory_purchase_orders` - Purchase orders
- `inventory_po_items` - PO line items
- `inventory_grn` - Goods received notes
- `inventory_grn_items` - GRN line items
- `inventory_requisitions` - Stock requisitions
- `inventory_requisition_items` - Requisition line items
- `inventory_stock_adjustments` - Stock adjustments
- `inventory_stock_transfers` - Stock transfers
- `inventory_stock_movements` - Movement audit trail

### Views
- `inventory_stock_summary` - Stock summary by item
- `inventory_low_stock_items` - Items below reorder level

## Accounting Integration

All inventory transactions create entries in `pending_txn` table:

### GRN Accounting Entry
```
Debit: Inventory Asset Account
Credit: Accounts Payable
```

### Stock Issue Accounting Entry
```
Debit: Department Expense Account
Credit: Inventory Asset Account
```

### Stock Adjustment Accounting Entry
```
Increase:
  Debit: Inventory Asset Account
  Credit: Inventory Adjustment Account

Decrease:
  Debit: Inventory Adjustment Account
  Credit: Inventory Asset Account
```

## Troubleshooting

### Issue: Items not showing
- Check facilityId filter
- Verify database connection
- Check is_active flag

### Issue: Stock levels incorrect
- Review stock movements table
- Check for unapproved adjustments
- Verify FIFO batch selection

### Issue: GRN not creating accounting entries
- Check pending_txn table
- Verify account_head mapping
- Check GRN approval status

### Issue: Reports not generating
- Verify date range filters
- Check data availability
- Review backend logs

## Best Practices

1. **Always use batch tracking** for items with expiry dates
2. **Set reorder levels** for all items to get low stock alerts
3. **Approve transactions promptly** to maintain accurate stock levels
4. **Regular stock takes** using stock adjustment feature
5. **Review expiry reports** weekly to prevent wastage
6. **Monitor supplier performance** monthly
7. **Use requisitions** for all internal stock movements
8. **Document reasons** for all adjustments
9. **Regular backups** of inventory data
10. **Train users** on proper workflows

## Support

For issues or questions:
1. Check this guide first
2. Review backend logs
3. Check browser console for errors
4. Verify database connectivity
5. Contact system administrator

## Version
- Phase 1: Backend API (Complete)
- Phase 2: Frontend UI (Complete)
- Phase 3: Advanced Features (Planned)

Last Updated: 2026-03-06
