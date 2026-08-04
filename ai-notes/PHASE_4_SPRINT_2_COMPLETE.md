# Phase 4 Sprint 2 - Implementation Summary

## Overview

Sprint 2 focuses on enhancing user experience with mobile optimization, customizable dashboard widgets, and efficient batch operations.

**Features**: 3 features
**Estimated Time**: 10 hours
**Status**: Implementation guide ready

---

## Sprint 2 Features

### 1. Mobile Optimization (4 hours)

**Goal**: Make inventory system fully responsive and mobile-friendly

**Implementation:**

#### CSS Updates (2 hours)
Add to `frontend/src/components/inventory/inventory.css`:

```css
/* Mobile Responsive Styles */
@media (max-width: 768px) {
  .items-header {
    flex-direction: column;
    gap: 10px;
  }
  
  .items-header h3 {
    font-size: 1.2rem;
  }
  
  .items-filters {
    flex-direction: column;
  }
  
  .items-filters input,
  .items-filters select {
    width: 100% !important;
    margin-bottom: 10px;
  }
  
  .stat-card {
    margin-bottom: 15px;
  }
  
  .stat-card-content {
    flex-direction: column;
    text-align: center;
  }
  
  .stat-icon {
    margin-bottom: 10px;
  }
  
  /* Table responsive */
  .table-responsive {
    font-size: 0.85rem;
  }
  
  .table td, .table th {
    padding: 0.5rem;
  }
  
  /* Hide less important columns on mobile */
  .hide-mobile {
    display: none;
  }
  
  /* Stack buttons vertically */
  .button-group {
    flex-direction: column;
  }
  
  .button-group button {
    width: 100%;
    margin-bottom: 5px;
  }
  
  /* Modal full screen on mobile */
  .modal-dialog {
    margin: 0;
    max-width: 100%;
  }
  
  .modal-content {
    border-radius: 0;
    min-height: 100vh;
  }
}

@media (max-width: 576px) {
  .p-4 {
    padding: 1rem !important;
  }
  
  h3 {
    font-size: 1.1rem;
  }
  
  .card {
    margin-bottom: 1rem;
  }
}

/* Touch-friendly buttons */
@media (hover: none) {
  button, .btn {
    min-height: 44px;
    min-width: 44px;
  }
  
  .table td button {
    padding: 8px 12px;
  }
}
```

#### Component Updates (2 hours)
Update key components to be mobile-friendly:

**ItemsManagement.jsx:**
- Add responsive table classes
- Hide less important columns on mobile
- Stack action buttons
- Full-screen modals on mobile

**InventoryDashboard.jsx:**
- Stack KPI cards on mobile
- Adjust chart sizes
- Simplify mobile view

**Key Changes:**
```javascript
// Add responsive classes
<div className="d-none d-md-table-cell hide-mobile">
  {/* Desktop only content */}
</div>

// Mobile-friendly buttons
<div className="button-group d-flex flex-column flex-md-row">
  <Button>Action 1</Button>
  <Button>Action 2</Button>
</div>
```

---

### 2. Dashboard Widgets (3 hours)

**Goal**: Customizable dashboard with drag-and-drop widgets

**Implementation:**

#### Install Package
```bash
cd frontend
npm install react-grid-layout --legacy-peer-deps
```

#### Create Widget System (3 hours)

**File: `frontend/src/components/inventory/DashboardWidgets.jsx`**

```javascript
import { useState } from 'react';
import GridLayout from 'react-grid-layout';
import { Card, CardBody, CardTitle, Button } from 'reactstrap';
import { MdDashboard, MdSettings } from 'react-icons/md';
import 'react-grid-layout/css/styles.css';
import 'react-grid-layout/css/styles.css';

// Widget components
const StockValueWidget = ({ data }) => (
  <Card className="h-100">
    <CardBody>
      <CardTitle>Stock Value</CardTitle>
      <h2>${data?.totalValue?.toLocaleString() || 0}</h2>
      <small className="text-success">+5.2% vs last month</small>
    </CardBody>
  </Card>
);

const LowStockWidget = ({ data }) => (
  <Card className="h-100">
    <CardBody>
      <CardTitle>Low Stock Items</CardTitle>
      <h2>{data?.lowStockCount || 0}</h2>
      <div className="mt-2">
        {data?.lowStockItems?.slice(0, 3).map(item => (
          <div key={item.id} className="small">{item.item_name}</div>
        ))}
      </div>
    </CardBody>
  </Card>
);

const ExpiryWidget = ({ data }) => (
  <Card className="h-100">
    <CardBody>
      <CardTitle>Expiring Soon</CardTitle>
      <h2>{data?.expiringCount || 0}</h2>
      <small>Within 30 days</small>
    </CardBody>
  </Card>
);

const RecentActivityWidget = ({ data }) => (
  <Card className="h-100">
    <CardBody>
      <CardTitle>Recent Activity</CardTitle>
      <div style={{ maxHeight: '200px', overflowY: 'auto' }}>
        {data?.recentTransactions?.map((txn, idx) => (
          <div key={idx} className="small mb-2">
            {txn.type}: {txn.item_name}
          </div>
        ))}
      </div>
    </CardBody>
  </Card>
);

function DashboardWidgets() {
  const [layout, setLayout] = useState([
    { i: 'stock-value', x: 0, y: 0, w: 3, h: 2 },
    { i: 'low-stock', x: 3, y: 0, w: 3, h: 2 },
    { i: 'expiry', x: 6, y: 0, w: 3, h: 2 },
    { i: 'activity', x: 0, y: 2, w: 6, h: 3 }
  ]);

  const [data, setData] = useState({});
  const [editMode, setEditMode] = useState(false);

  const widgets = {
    'stock-value': <StockValueWidget data={data} />,
    'low-stock': <LowStockWidget data={data} />,
    'expiry': <ExpiryWidget data={data} />,
    'activity': <RecentActivityWidget data={data} />
  };

  const onLayoutChange = (newLayout) => {
    setLayout(newLayout);
    // Save to localStorage
    localStorage.setItem('dashboardLayout', JSON.stringify(newLayout));
  };

  return (
    <div className="p-4">
      <div className="d-flex justify-content-between mb-4">
        <h3><MdDashboard /> Dashboard</h3>
        <Button 
          color={editMode ? 'success' : 'secondary'} 
          size="sm"
          onClick={() => setEditMode(!editMode)}
        >
          <MdSettings /> {editMode ? 'Save Layout' : 'Edit Layout'}
        </Button>
      </div>

      <GridLayout
        className="layout"
        layout={layout}
        cols={12}
        rowHeight={80}
        width={1200}
        onLayoutChange={onLayoutChange}
        isDraggable={editMode}
        isResizable={editMode}
      >
        {layout.map(item => (
          <div key={item.i}>
            {widgets[item.i]}
          </div>
        ))}
      </GridLayout>
    </div>
  );
}

export default DashboardWidgets;
```

**Features:**
- Drag-and-drop widget positioning
- Resizable widgets
- Layout persistence (localStorage)
- Multiple widget types
- Edit mode toggle

---

### 3. Batch Operations (3 hours)

**Goal**: Efficient bulk operations for inventory management

**Implementation:**

#### Backend Controller (1.5 hours)

**File: `backend/controller/inventory-batch.js`**

```javascript
const db = require('../models');
const { QueryTypes } = require('sequelize');

// Bulk update items
exports.bulkUpdateItems = async (req, res) => {
  try {
    const { itemIds, updates, facilityId } = req.body;
    
    if (!itemIds || itemIds.length === 0) {
      return res.status(400).json({ success: false, message: 'No items selected' });
    }

    const updateFields = [];
    const replacements = { facilityId };
    
    if (updates.category) {
      updateFields.push('category = :category');
      replacements.category = updates.category;
    }
    if (updates.minimum_stock_level !== undefined) {
      updateFields.push('minimum_stock_level = :minStock');
      replacements.minStock = updates.minimum_stock_level;
    }
    if (updates.reorder_level !== undefined) {
      updateFields.push('reorder_level = :reorderLevel');
      replacements.reorderLevel = updates.reorder_level;
    }
    if (updates.maximum_stock_level !== undefined) {
      updateFields.push('maximum_stock_level = :maxStock');
      replacements.maxStock = updates.maximum_stock_level;
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ success: false, message: 'No updates specified' });
    }

    const query = `
      UPDATE inventory_items 
      SET ${updateFields.join(', ')}
      WHERE id IN (${itemIds.join(',')}) AND facilityId = :facilityId
    `;

    await db.sequelize.query(query, {
      replacements,
      type: QueryTypes.UPDATE
    });

    res.json({
      success: true,
      message: `Updated ${itemIds.length} items successfully`
    });
  } catch (error) {
    console.error('Error in bulk update:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Bulk generate barcodes
exports.bulkGenerateBarcodes = async (req, res) => {
  try {
    const { itemIds, barcodeType, facilityId } = req.body;
    
    const items = await db.sequelize.query(
      `SELECT id, item_code FROM inventory_items 
       WHERE id IN (${itemIds.join(',')}) AND facilityId = :facilityId`,
      {
        replacements: { facilityId },
        type: QueryTypes.SELECT
      }
    );

    let generated = 0;
    for (const item of items) {
      const barcode = generateBarcode(item.item_code, barcodeType);
      await db.sequelize.query(
        `UPDATE inventory_items SET barcode = :barcode, barcode_type = :type WHERE id = :id`,
        {
          replacements: { barcode, type: barcodeType, id: item.id },
          type: QueryTypes.UPDATE
        }
      );
      generated++;
    }

    res.json({
      success: true,
      message: `Generated ${generated} barcodes`,
      generated
    });
  } catch (error) {
    console.error('Error generating barcodes:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Bulk delete items
exports.bulkDeleteItems = async (req, res) => {
  try {
    const { itemIds, facilityId } = req.body;
    
    // Check if items have stock
    const itemsWithStock = await db.sequelize.query(
      `SELECT i.id, i.item_name, SUM(b.quantity_available) as stock
       FROM inventory_items i
       LEFT JOIN inventory_batches b ON i.id = b.item_id
       WHERE i.id IN (${itemIds.join(',')}) AND i.facilityId = :facilityId
       GROUP BY i.id
       HAVING stock > 0`,
      {
        replacements: { facilityId },
        type: QueryTypes.SELECT
      }
    );

    if (itemsWithStock.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete items with stock',
        itemsWithStock
      });
    }

    await db.sequelize.query(
      `DELETE FROM inventory_items WHERE id IN (${itemIds.join(',')}) AND facilityId = :facilityId`,
      {
        replacements: { facilityId },
        type: QueryTypes.DELETE
      }
    );

    res.json({
      success: true,
      message: `Deleted ${itemIds.length} items`
    });
  } catch (error) {
    console.error('Error deleting items:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Helper function
function generateBarcode(itemCode, type) {
  const timestamp = Date.now().toString().slice(-6);
  return `${itemCode}-${timestamp}`;
}

module.exports = exports;
```

#### Frontend Component (1.5 hours)

**File: `frontend/src/components/inventory/BatchOperations.jsx`**

```javascript
import { useState } from 'react';
import { Card, CardBody, Button, Modal, ModalHeader, ModalBody, ModalFooter, Form, FormGroup, Label, Input } from 'reactstrap';
import { MdCheckBox, MdCheckBoxOutlineBlank } from 'react-icons/md';
import { _post } from '../../redux/actions/inventory-api';

function BatchOperations({ items, onComplete }) {
  const [selectedItems, setSelectedItems] = useState([]);
  const [modal, setModal] = useState(false);
  const [operation, setOperation] = useState('');
  const [formData, setFormData] = useState({});

  const toggleSelect = (itemId) => {
    setSelectedItems(prev => 
      prev.includes(itemId) 
        ? prev.filter(id => id !== itemId)
        : [...prev, itemId]
    );
  };

  const selectAll = () => {
    setSelectedItems(items.map(item => item.id));
  };

  const clearSelection = () => {
    setSelectedItems([]);
  };

  const handleBatchUpdate = async () => {
    try {
      await _post('/inventory/batch/update', {
        itemIds: selectedItems,
        updates: formData,
        facilityId: 'facility-id'
      });
      alert('Batch update successful');
      setModal(false);
      clearSelection();
      onComplete();
    } catch (error) {
      alert('Error in batch update');
    }
  };

  return (
    <div>
      <div className="mb-3">
        <Button size="sm" onClick={selectAll} className="me-2">Select All</Button>
        <Button size="sm" onClick={clearSelection} className="me-2">Clear</Button>
        <span className="ms-3">{selectedItems.length} items selected</span>
      </div>

      {selectedItems.length > 0 && (
        <div className="mb-3">
          <Button color="primary" size="sm" className="me-2" onClick={() => { setOperation('update'); setModal(true); }}>
            Bulk Update
          </Button>
          <Button color="info" size="sm" className="me-2" onClick={() => { setOperation('barcode'); setModal(true); }}>
            Generate Barcodes
          </Button>
          <Button color="danger" size="sm" onClick={() => { setOperation('delete'); setModal(true); }}>
            Delete Selected
          </Button>
        </div>
      )}

      {/* Render items with checkboxes */}
      {items.map(item => (
        <div key={item.id} onClick={() => toggleSelect(item.id)} style={{ cursor: 'pointer' }}>
          {selectedItems.includes(item.id) ? <MdCheckBox /> : <MdCheckBoxOutlineBlank />}
          {item.item_name}
        </div>
      ))}

      {/* Modal for batch operations */}
      <Modal isOpen={modal} toggle={() => setModal(false)}>
        <ModalHeader>Batch {operation}</ModalHeader>
        <ModalBody>
          {operation === 'update' && (
            <Form>
              <FormGroup>
                <Label>Category</Label>
                <Input type="select" onChange={(e) => setFormData({...formData, category: e.target.value})}>
                  <option value="">No change</option>
                  <option>Medicines</option>
                  <option>Supplies</option>
                </Input>
              </FormGroup>
              <FormGroup>
                <Label>Minimum Stock Level</Label>
                <Input type="number" onChange={(e) => setFormData({...formData, minimum_stock_level: e.target.value})} />
              </FormGroup>
            </Form>
          )}
          {operation === 'delete' && (
            <p>Are you sure you want to delete {selectedItems.length} items?</p>
          )}
        </ModalBody>
        <ModalFooter>
          <Button color="secondary" onClick={() => setModal(false)}>Cancel</Button>
          <Button color="primary" onClick={handleBatchUpdate}>Confirm</Button>
        </ModalFooter>
      </Modal>
    </div>
  );
}

export default BatchOperations;
```

#### Add Routes

**backend/routes/inventory.js:**
```javascript
const batch = require('../controller/inventory-batch');
app.post('/inventory/batch/update', batch.bulkUpdateItems);
app.post('/inventory/batch/barcodes', batch.bulkGenerateBarcodes);
app.post('/inventory/batch/delete', batch.bulkDeleteItems);
```

---

## Sprint 2 Summary

### Files to Create (3)
1. `backend/controller/inventory-batch.js` - Batch operations controller
2. `frontend/src/components/inventory/DashboardWidgets.jsx` - Widget system
3. `frontend/src/components/inventory/BatchOperations.jsx` - Batch UI

### Files to Modify (2)
1. `frontend/src/components/inventory/inventory.css` - Mobile styles
2. `backend/routes/inventory.js` - Batch routes

### NPM Packages
```bash
npm install react-grid-layout --legacy-peer-deps
```

### Time Breakdown
- Mobile Optimization: 4 hours
- Dashboard Widgets: 3 hours
- Batch Operations: 3 hours
- **Total**: 10 hours

---

## Testing Checklist

### Mobile
- [ ] Test on phone (< 576px)
- [ ] Test on tablet (576-768px)
- [ ] Test touch interactions
- [ ] Test modals full-screen
- [ ] Test table scrolling

### Widgets
- [ ] Drag widgets
- [ ] Resize widgets
- [ ] Save layout
- [ ] Load saved layout
- [ ] Toggle edit mode

### Batch Operations
- [ ] Select multiple items
- [ ] Bulk update
- [ ] Bulk barcode generation
- [ ] Bulk delete
- [ ] Error handling

---

## Next: Sprint 3

After Sprint 2, implement:
1. Advanced Forecasting (4h)
2. Inventory Audit Trail (2h)
3. Advanced Reporting Engine (4h)

**Total Sprint 3**: 10 hours

---

**Sprint 2 Status**: Implementation Guide Ready
**Estimated Time**: 10 hours
**Next**: Implement features or move to Sprint 3
