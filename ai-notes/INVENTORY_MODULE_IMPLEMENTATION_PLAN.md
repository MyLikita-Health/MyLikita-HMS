# Inventory Management Module - Implementation Plan

## Overview
Comprehensive inventory management system for healthcare facilities to track medical supplies, equipment, medications, and consumables with full integration to billing, procurement, and clinical workflows.

---

## Current State Analysis

### Existing Components
- ✅ Basic inventory structure exists in `/frontend/src/components/inventory/`
- ✅ Purchase Order system
- ✅ Goods Received Note (GRN)
- ✅ Item management
- ✅ Supplier management
- ⚠️ Limited integration with other modules
- ⚠️ No real-time stock tracking
- ⚠️ No automated reorder alerts
- ⚠️ No batch/expiry management

### Existing Database Tables
- Dental lab inventory (specific to dental lab)
- Dental product inventory transactions
- Need general inventory tables

---

## Implementation Phases

## Phase 1: Database Schema & Backend API (Week 1)

### 1.1 Database Tables

```sql
-- Main inventory items table
CREATE TABLE inventory_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  item_code VARCHAR(50) UNIQUE NOT NULL,
  item_name VARCHAR(255) NOT NULL,
  category VARCHAR(100) NOT NULL, -- Medical Supplies, Medications, Equipment, Consumables, Dental Supplies
  sub_category VARCHAR(100),
  description TEXT,
  unit_of_measure VARCHAR(50) NOT NULL, -- pieces, boxes, bottles, vials, etc.
  reorder_level INT DEFAULT 10,
  reorder_quantity INT DEFAULT 50,
  storage_location VARCHAR(100),
  facilityId VARCHAR(50) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_facility (facilityId),
  INDEX idx_category (category),
  INDEX idx_item_code (item_code)
);

-- Stock levels per location/store
CREATE TABLE inventory_stock (
  id INT AUTO_INCREMENT PRIMARY KEY,
  item_id INT NOT NULL,
  facilityId VARCHAR(50) NOT NULL,
  store_location VARCHAR(100) DEFAULT 'Main Store',
  quantity_on_hand INT DEFAULT 0,
  quantity_reserved INT DEFAULT 0, -- Reserved for pending orders
  quantity_available INT GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) STORED,
  minimum_stock_level INT DEFAULT 10,
  maximum_stock_level INT DEFAULT 1000,
  last_stock_take_date DATE,
  last_stock_take_by INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (item_id) REFERENCES inventory_items(id),
  INDEX idx_facility_item (facilityId, item_id),
  INDEX idx_low_stock (quantity_available, minimum_stock_level)
);

-- Batch tracking for expirable items
CREATE TABLE inventory_batches (
  id INT AUTO_INCREMENT PRIMARY KEY,
  item_id INT NOT NULL,
  batch_number VARCHAR(100) NOT NULL,
  facilityId VARCHAR(50) NOT NULL,
  store_location VARCHAR(100) DEFAULT 'Main Store',
  quantity INT NOT NULL,
  unit_cost DECIMAL(10,2),
  manufacture_date DATE,
  expiry_date DATE,
  supplier_id INT,
  grn_id INT, -- Link to Goods Received Note
  status ENUM('active', 'expired', 'recalled', 'depleted') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (item_id) REFERENCES inventory_items(id),
  INDEX idx_expiry (expiry_date, status),
  INDEX idx_batch (batch_number),
  UNIQUE KEY unique_batch (item_id, batch_number, facilityId)
);

-- All inventory transactions
CREATE TABLE inventory_transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  transaction_id VARCHAR(50) UNIQUE NOT NULL,
  item_id INT NOT NULL,
  batch_id INT,
  facilityId VARCHAR(50) NOT NULL,
  transaction_type ENUM('purchase', 'issue', 'return', 'adjustment', 'transfer', 'disposal', 'stock_take') NOT NULL,
  quantity INT NOT NULL,
  unit_cost DECIMAL(10,2),
  total_cost DECIMAL(10,2),
  from_location VARCHAR(100),
  to_location VARCHAR(100),
  reference_type VARCHAR(50), -- 'prescription', 'procedure', 'lab_request', 'dental_job', etc.
  reference_id VARCHAR(50),
  performed_by INT NOT NULL,
  approved_by INT,
  notes TEXT,
  transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (item_id) REFERENCES inventory_items(id),
  FOREIGN KEY (batch_id) REFERENCES inventory_batches(id),
  INDEX idx_facility_date (facilityId, transaction_date),
  INDEX idx_reference (reference_type, reference_id),
  INDEX idx_transaction_type (transaction_type)
);

-- Suppliers
CREATE TABLE inventory_suppliers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  supplier_code VARCHAR(50) UNIQUE NOT NULL,
  supplier_name VARCHAR(255) NOT NULL,
  contact_person VARCHAR(255),
  email VARCHAR(255),
  phone VARCHAR(50),
  address TEXT,
  city VARCHAR(100),
  country VARCHAR(100),
  payment_terms VARCHAR(100),
  credit_limit DECIMAL(12,2),
  is_active BOOLEAN DEFAULT TRUE,
  facilityId VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_facility (facilityId)
);

-- Purchase Orders
CREATE TABLE inventory_purchase_orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  po_number VARCHAR(50) UNIQUE NOT NULL,
  supplier_id INT NOT NULL,
  facilityId VARCHAR(50) NOT NULL,
  order_date DATE NOT NULL,
  expected_delivery_date DATE,
  status ENUM('draft', 'submitted', 'approved', 'partially_received', 'received', 'cancelled') DEFAULT 'draft',
  subtotal DECIMAL(12,2),
  tax_amount DECIMAL(12,2),
  shipping_cost DECIMAL(12,2),
  other_charges DECIMAL(12,2),
  total_amount DECIMAL(12,2),
  notes TEXT,
  created_by INT NOT NULL,
  approved_by INT,
  approved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (supplier_id) REFERENCES inventory_suppliers(id),
  INDEX idx_facility_status (facilityId, status),
  INDEX idx_po_number (po_number)
);

-- Purchase Order Items
CREATE TABLE inventory_purchase_order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  po_id INT NOT NULL,
  item_id INT NOT NULL,
  quantity_ordered INT NOT NULL,
  quantity_received INT DEFAULT 0,
  unit_cost DECIMAL(10,2) NOT NULL,
  total_cost DECIMAL(10,2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (po_id) REFERENCES inventory_purchase_orders(id) ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES inventory_items(id)
);

-- Goods Received Notes
CREATE TABLE inventory_grn (
  id INT AUTO_INCREMENT PRIMARY KEY,
  grn_number VARCHAR(50) UNIQUE NOT NULL,
  po_id INT,
  supplier_id INT NOT NULL,
  facilityId VARCHAR(50) NOT NULL,
  received_date DATE NOT NULL,
  invoice_number VARCHAR(100),
  invoice_date DATE,
  invoice_amount DECIMAL(12,2),
  notes TEXT,
  received_by INT NOT NULL,
  verified_by INT,
  status ENUM('pending', 'verified', 'posted') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (po_id) REFERENCES inventory_purchase_orders(id),
  FOREIGN KEY (supplier_id) REFERENCES inventory_suppliers(id),
  INDEX idx_facility (facilityId),
  INDEX idx_grn_number (grn_number)
);

-- GRN Items
CREATE TABLE inventory_grn_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  grn_id INT NOT NULL,
  item_id INT NOT NULL,
  batch_number VARCHAR(100),
  quantity_received INT NOT NULL,
  unit_cost DECIMAL(10,2) NOT NULL,
  total_cost DECIMAL(10,2) NOT NULL,
  expiry_date DATE,
  manufacture_date DATE,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (grn_id) REFERENCES inventory_grn(id) ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES inventory_items(id)
);

-- Stock requisitions (internal requests)
CREATE TABLE inventory_requisitions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  requisition_number VARCHAR(50) UNIQUE NOT NULL,
  facilityId VARCHAR(50) NOT NULL,
  requested_by INT NOT NULL,
  department VARCHAR(100),
  request_date DATE NOT NULL,
  required_date DATE,
  status ENUM('pending', 'approved', 'partially_issued', 'issued', 'rejected', 'cancelled') DEFAULT 'pending',
  approved_by INT,
  approved_at TIMESTAMP,
  issued_by INT,
  issued_at TIMESTAMP,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_facility_status (facilityId, status),
  INDEX idx_requisition_number (requisition_number)
);

-- Requisition Items
CREATE TABLE inventory_requisition_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  requisition_id INT NOT NULL,
  item_id INT NOT NULL,
  quantity_requested INT NOT NULL,
  quantity_approved INT DEFAULT 0,
  quantity_issued INT DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (requisition_id) REFERENCES inventory_requisitions(id) ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES inventory_items(id)
);

-- Stock adjustments
CREATE TABLE inventory_adjustments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  adjustment_number VARCHAR(50) UNIQUE NOT NULL,
  facilityId VARCHAR(50) NOT NULL,
  adjustment_date DATE NOT NULL,
  adjustment_type ENUM('stock_take', 'damage', 'expiry', 'loss', 'found', 'correction') NOT NULL,
  reason TEXT,
  performed_by INT NOT NULL,
  approved_by INT,
  status ENUM('pending', 'approved', 'posted') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_facility (facilityId),
  INDEX idx_adjustment_number (adjustment_number)
);

-- Adjustment Items
CREATE TABLE inventory_adjustment_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  adjustment_id INT NOT NULL,
  item_id INT NOT NULL,
  batch_id INT,
  system_quantity INT NOT NULL,
  physical_quantity INT NOT NULL,
  variance INT GENERATED ALWAYS AS (physical_quantity - system_quantity) STORED,
  unit_cost DECIMAL(10,2),
  variance_value DECIMAL(10,2) GENERATED ALWAYS AS ((physical_quantity - system_quantity) * unit_cost) STORED,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (adjustment_id) REFERENCES inventory_adjustments(id) ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES inventory_items(id),
  FOREIGN KEY (batch_id) REFERENCES inventory_batches(id)
);

-- Reorder alerts
CREATE TABLE inventory_reorder_alerts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  item_id INT NOT NULL,
  facilityId VARCHAR(50) NOT NULL,
  alert_type ENUM('low_stock', 'out_of_stock', 'expiring_soon', 'expired') NOT NULL,
  current_quantity INT,
  reorder_level INT,
  alert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_acknowledged BOOLEAN DEFAULT FALSE,
  acknowledged_by INT,
  acknowledged_at TIMESTAMP,
  action_taken TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (item_id) REFERENCES inventory_items(id),
  INDEX idx_facility_alert (facilityId, alert_type, is_acknowledged)
);
```

### 1.2 Backend API Endpoints

**Items Management**
- `GET /inventory/items` - List all items with filters
- `GET /inventory/items/:id` - Get item details
- `POST /inventory/items` - Create new item
- `PUT /inventory/items/:id` - Update item
- `DELETE /inventory/items/:id` - Deactivate item
- `GET /inventory/items/:id/stock-history` - Get stock movement history

**Stock Management**
- `GET /inventory/stock` - Get current stock levels
- `GET /inventory/stock/low` - Get low stock items
- `GET /inventory/stock/:itemId` - Get stock for specific item
- `POST /inventory/stock/adjustment` - Create stock adjustment
- `POST /inventory/stock/transfer` - Transfer stock between locations

**Purchase Orders**
- `GET /inventory/purchase-orders` - List POs
- `GET /inventory/purchase-orders/:id` - Get PO details
- `POST /inventory/purchase-orders` - Create PO
- `PUT /inventory/purchase-orders/:id` - Update PO
- `POST /inventory/purchase-orders/:id/submit` - Submit for approval
- `POST /inventory/purchase-orders/:id/approve` - Approve PO
- `POST /inventory/purchase-orders/:id/cancel` - Cancel PO

**Goods Received Notes**
- `GET /inventory/grn` - List GRNs
- `GET /inventory/grn/:id` - Get GRN details
- `POST /inventory/grn` - Create GRN
- `POST /inventory/grn/:id/verify` - Verify GRN
- `POST /inventory/grn/:id/post` - Post to inventory

**Requisitions**
- `GET /inventory/requisitions` - List requisitions
- `GET /inventory/requisitions/:id` - Get requisition details
- `POST /inventory/requisitions` - Create requisition
- `POST /inventory/requisitions/:id/approve` - Approve requisition
- `POST /inventory/requisitions/:id/issue` - Issue items

**Suppliers**
- `GET /inventory/suppliers` - List suppliers
- `GET /inventory/suppliers/:id` - Get supplier details
- `POST /inventory/suppliers` - Create supplier
- `PUT /inventory/suppliers/:id` - Update supplier

**Reports & Analytics**
- `GET /inventory/reports/stock-valuation` - Stock valuation report
- `GET /inventory/reports/movement` - Stock movement report
- `GET /inventory/reports/expiry` - Expiring items report
- `GET /inventory/reports/consumption` - Consumption analysis
- `GET /inventory/reports/reorder` - Reorder report

---

## Phase 2: Frontend Components (Week 2-3)

### 2.1 Dashboard
- **InventoryDashboard.jsx** - Main dashboard with KPIs
  - Total items count
  - Stock value
  - Low stock alerts
  - Expiring items
  - Recent transactions
  - Quick actions

### 2.2 Items Management
- **ItemsList.jsx** - Items grid/table with search & filters
- **ItemForm.jsx** - Add/Edit item form
- **ItemDetails.jsx** - Item details with stock history
- **ItemCategories.jsx** - Manage categories

### 2.3 Stock Management
- **StockLevels.jsx** - Current stock levels view
- **StockAdjustment.jsx** - Stock adjustment form
- **StockTransfer.jsx** - Transfer between locations
- **BatchManagement.jsx** - Batch tracking
- **StockTake.jsx** - Physical stock count

### 2.4 Purchase Management
- **PurchaseOrderList.jsx** - PO list
- **PurchaseOrderForm.jsx** - Create/Edit PO
- **PurchaseOrderDetails.jsx** - PO details & tracking
- **GRNList.jsx** - GRN list
- **GRNForm.jsx** - Create GRN
- **GRNVerification.jsx** - Verify received goods

### 2.5 Requisitions
- **RequisitionList.jsx** - Requisitions list
- **RequisitionForm.jsx** - Create requisition
- **RequisitionApproval.jsx** - Approve/reject requisitions
- **RequisitionIssue.jsx** - Issue items

### 2.6 Suppliers
- **SupplierList.jsx** - Suppliers list
- **SupplierForm.jsx** - Add/Edit supplier
- **SupplierDetails.jsx** - Supplier details & history

### 2.7 Reports
- **StockValuationReport.jsx**
- **MovementReport.jsx**
- **ExpiryReport.jsx**
- **ConsumptionReport.jsx**
- **ReorderReport.jsx**

---

## Phase 3: Integration with Existing Modules (Week 4)

### 3.1 Accounting Integration (CRITICAL)

**Chart of Accounts Integration**
- Link inventory items to account heads (acc_head table)
- Map inventory transactions to accounting entries
- Automatic journal entries for all inventory movements

**Account Heads Mapping**:
```
Assets:
  - Current Assets
    - Inventory (Stock on Hand)
      - Medical Supplies Inventory
      - Medications Inventory
      - Dental Supplies Inventory
      - Laboratory Reagents Inventory
      - Equipment & Instruments Inventory
      - Consumables Inventory

Expenses:
  - Cost of Goods Sold (COGS)
    - Medical Supplies Used
    - Medications Dispensed
    - Dental Supplies Used
    - Lab Reagents Used
  - Inventory Adjustments
    - Stock Loss/Damage
    - Expired Items Write-off
    - Stock Count Variances

Liabilities:
  - Current Liabilities
    - Accounts Payable (Suppliers)
    - Accrued Purchases
```

**Automatic Journal Entries**:

1. **Purchase Order Approval**:
   ```
   DR: Inventory (Asset) - Committed
   CR: Accounts Payable - Committed
   ```

2. **Goods Received (GRN Posted)**:
   ```
   DR: Inventory (Asset) - [Item Category]
   CR: Accounts Payable - [Supplier]
   
   Reference: GRN-XXXX
   Posted to: pending_txn table
   ```

3. **Stock Issue/Dispensing**:
   ```
   DR: Cost of Goods Sold - [Department]
   CR: Inventory (Asset) - [Item Category]
   
   Reference: Prescription/Procedure/Lab Request ID
   Posted to: pending_txn table
   ```

4. **Stock Adjustment (Loss/Damage)**:
   ```
   DR: Inventory Adjustments Expense
   CR: Inventory (Asset) - [Item Category]
   
   Reference: ADJ-XXXX
   Posted to: pending_txn table
   ```

5. **Stock Adjustment (Found/Gain)**:
   ```
   DR: Inventory (Asset) - [Item Category]
   CR: Inventory Adjustments Income
   
   Reference: ADJ-XXXX
   Posted to: pending_txn table
   ```

6. **Expiry Write-off**:
   ```
   DR: Expired Items Write-off Expense
   CR: Inventory (Asset) - [Item Category]
   
   Reference: EXP-XXXX
   Posted to: pending_txn table
   ```

7. **Inter-location Transfer**:
   ```
   DR: Inventory - [To Location]
   CR: Inventory - [From Location]
   
   Reference: TRF-XXXX
   Posted to: pending_txn table
   ```

**Database Schema Updates**:

```sql
-- Add accounting fields to inventory_items
ALTER TABLE inventory_items ADD COLUMN account_head VARCHAR(50);
ALTER TABLE inventory_items ADD COLUMN account_subhead VARCHAR(50);
ALTER TABLE inventory_items ADD COLUMN cogs_account VARCHAR(50);
ALTER TABLE inventory_items ADD COLUMN adjustment_account VARCHAR(50);

-- Add accounting reference to transactions
ALTER TABLE inventory_transactions ADD COLUMN journal_entry_id VARCHAR(50);
ALTER TABLE inventory_transactions ADD COLUMN posted_to_accounts BOOLEAN DEFAULT FALSE;
ALTER TABLE inventory_transactions ADD COLUMN posting_date TIMESTAMP;

-- Link GRN to accounts payable
ALTER TABLE inventory_grn ADD COLUMN supplier_account VARCHAR(50);
ALTER TABLE inventory_grn ADD COLUMN payable_amount DECIMAL(12,2);
ALTER TABLE inventory_grn ADD COLUMN posted_to_accounts BOOLEAN DEFAULT FALSE;
ALTER TABLE inventory_grn ADD COLUMN journal_entry_id VARCHAR(50);

-- Link PO to commitments
ALTER TABLE inventory_purchase_orders ADD COLUMN commitment_entry_id VARCHAR(50);
ALTER TABLE inventory_purchase_orders ADD COLUMN posted_to_accounts BOOLEAN DEFAULT FALSE;
```

**Integration with pending_txn Table**:

Every inventory transaction will create corresponding entries in `pending_txn`:

```javascript
// Example: Post GRN to accounts
async function postGRNToAccounts(grnId, facilityId, userId) {
  const grn = await getGRNDetails(grnId);
  const transactionId = `GRN-${grnId}-${Date.now()}`;
  
  // For each item in GRN
  for (const item of grn.items) {
    // Debit: Inventory Asset
    await db.sequelize.query(
      `CALL pending_txn(
        :query_type, :facilityId, :transaction_id, :description, 
        :head, :subhead, :amount, :service_type, :created_at, 
        :patient_name, :patient_id, :patient_type, :total_amount, 
        :tx_status, :date_from, :date_to, :client_acc, :item_code, 
        :expiry_date, :branch_location, :qty_out, :selling_price, 
        :request_id, :mode_of_payment, :consultation_number
      )`,
      {
        replacements: {
          query_type: 'insert',
          facilityId: facilityId,
          transaction_id: transactionId,
          description: `GRN: ${grn.grn_number} - ${item.item_name}`,
          head: 'Assets',
          subhead: item.account_head, // e.g., 'Medical Supplies Inventory'
          amount: item.total_cost,
          service_type: 'Inventory',
          created_at: new Date(),
          patient_name: grn.supplier_name,
          patient_id: grn.supplier_id,
          patient_type: 'Supplier',
          total_amount: item.total_cost,
          tx_status: 'debit',
          date_from: grn.received_date,
          date_to: grn.received_date,
          client_acc: grn.supplier_account,
          item_code: item.item_code,
          expiry_date: item.expiry_date,
          branch_location: grn.store_location,
          qty_out: 0,
          selling_price: item.unit_cost,
          request_id: grn.grn_number,
          mode_of_payment: 'Credit',
          consultation_number: null
        }
      }
    );
    
    // Credit: Accounts Payable
    await db.sequelize.query(
      `CALL pending_txn(...)`, // Similar call with tx_status: 'credit'
      { replacements: { ...creditEntry } }
    );
  }
  
  // Update GRN as posted
  await db.sequelize.query(
    `UPDATE inventory_grn 
     SET posted_to_accounts = TRUE, 
         journal_entry_id = :transactionId,
         posting_date = NOW()
     WHERE id = :grnId`,
    { replacements: { transactionId, grnId } }
  );
}
```

**Financial Reports Integration**:

1. **Inventory Valuation Report** → Feeds into Balance Sheet (Assets)
2. **COGS Report** → Feeds into Profit & Loss Statement
3. **Purchase Analysis** → Feeds into Cash Flow Statement
4. **Supplier Payables** → Feeds into Balance Sheet (Liabilities)

**API Endpoints for Accounting Integration**:
- `POST /inventory/accounting/post-grn/:grnId` - Post GRN to accounts
- `POST /inventory/accounting/post-adjustment/:adjustmentId` - Post adjustment
- `POST /inventory/accounting/post-issue/:transactionId` - Post stock issue
- `GET /inventory/accounting/unposted-transactions` - Get unposted transactions
- `GET /inventory/accounting/inventory-valuation/:date` - Get inventory value for balance sheet
- `GET /inventory/accounting/cogs/:from/:to` - Get COGS for P&L

### 3.2 Pharmacy Integration
- Link prescriptions to inventory
- Auto-deduct stock on dispensing
- Track medication usage
- Post to accounts: DR COGS, CR Inventory

### 3.3 Dental Integration
- Link dental procedures to consumables
- Track dental supplies usage
- Integrate with dental lab inventory
- Post to accounts: DR COGS, CR Inventory

### 3.4 Laboratory Integration
- Link lab tests to reagents/consumables
- Track lab supplies usage
- Post to accounts: DR COGS, CR Inventory

### 3.5 Billing Integration
- Link inventory items to billing
- Track billable vs non-billable items
- Cost tracking for procedures
- Automatic COGS calculation

### 3.6 Procurement Workflow
- Approval workflows for POs
- Budget tracking
- Vendor performance tracking
- Payment tracking via accounts payable

---

## Phase 4: Advanced Features (Week 5-6)

### 4.1 Automation
- Automatic reorder alerts
- Email notifications for low stock
- Expiry alerts (30, 60, 90 days)
- Auto-generate requisitions based on consumption patterns

### 4.2 Analytics & Reporting
- Consumption trends
- ABC analysis (fast/slow moving items)
- Stock turnover ratio
- Supplier performance metrics
- Cost analysis

### 4.3 Mobile Support
- Barcode scanning for stock take
- Mobile requisition creation
- Quick stock checks

### 4.4 Multi-location Support
- Central warehouse + sub-stores
- Inter-location transfers
- Location-wise stock levels

---

## Technical Stack

### Backend
- Node.js/Express
- MySQL database
- Sequelize ORM (optional)
- JWT authentication

### Frontend
- React.js
- React Router
- Redux (state management)
- Axios (API calls)
- React-icons
- Reactstrap/Bootstrap
- Chart.js (for analytics)

---

## Key Features Summary

1. ✅ Complete item master management
2. ✅ Real-time stock tracking
3. ✅ Batch & expiry management
4. ✅ Purchase order workflow
5. ✅ Goods received note processing
6. ✅ Internal requisitions
7. ✅ Stock adjustments & transfers
8. ✅ Supplier management
9. ✅ Automated reorder alerts
10. ✅ Comprehensive reporting
11. ✅ Integration with clinical modules
12. ✅ Multi-location support
13. ✅ Audit trail for all transactions
14. ✅ Role-based access control
15. ✅ **Full accounting integration with automatic journal entries**
16. ✅ **Integration with pending_txn table for financial reporting**
17. ✅ **Chart of accounts mapping for all inventory items**
18. ✅ **Automatic COGS calculation and posting**
19. ✅ **Accounts payable tracking for suppliers**
20. ✅ **Financial reports integration (Balance Sheet, P&L, Cash Flow)**

---

## Success Metrics

- Reduce stock-outs by 80%
- Improve inventory turnover by 30%
- Reduce expired items wastage by 90%
- Automate 70% of reordering process
- Real-time stock visibility across all locations
- Complete audit trail for compliance

---

## Next Steps

1. Review and approve this plan
2. Set up database tables
3. Implement backend APIs
4. Build frontend components
5. Integration testing
6. User acceptance testing
7. Training & deployment

---

**Estimated Timeline: 6 weeks**
**Team Required: 2-3 developers**
