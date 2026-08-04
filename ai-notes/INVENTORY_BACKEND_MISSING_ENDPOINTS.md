# Inventory Backend Missing Endpoints

## Issue Identified ⚠️
The frontend inventory components are calling endpoints that don't exist in the backend, causing 404 errors.

## Missing GET Endpoints

### 1. Stock Adjustments Listing
**Frontend Call**: `GET /inventory/adjustments?facilityId=xxx&type=&status=`
**Backend Status**: ❌ Missing
**Current Backend**: Only has POST endpoints for creating and approving adjustments
**Needed**: GET endpoint to list stock adjustments with filtering

**Required Route**:
```javascript
app.get('/inventory/adjustments', 
  checkPermission('inventory', 'stock', 'view'),
  inventory.getStockAdjustments
);
```

**Required Controller Method**:
```javascript
// In backend/controller/inventory.js
exports.getStockAdjustments = async (req, res) => {
  try {
    const { facilityId, type, status, page = 1, limit = 50 } = req.query;
    
    // Query stock adjustments with filters
    // Return paginated results
    
    res.json({
      success: true,
      results: adjustments,
      pagination: { page, limit, total }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
```

### 2. Stock Transfers Listing
**Frontend Call**: `GET /inventory/transfers?facilityId=xxx&status=`
**Backend Status**: ❌ Missing
**Current Backend**: Only has POST endpoint for creating transfers
**Needed**: GET endpoint to list stock transfers with filtering

**Required Route**:
```javascript
app.get('/inventory/transfers', 
  checkPermission('inventory', 'stock', 'view'),
  inventory.getStockTransfers
);
```

**Required Controller Method**:
```javascript
// In backend/controller/inventory.js
exports.getStockTransfers = async (req, res) => {
  try {
    const { facilityId, status, page = 1, limit = 50 } = req.query;
    
    // Query stock transfers with filters
    // Return paginated results
    
    res.json({
      success: true,
      results: transfers,
      pagination: { page, limit, total }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
```

## Database Tables Required

### Stock Adjustments Table
```sql
CREATE TABLE IF NOT EXISTS stock_adjustments (
  id VARCHAR(36) PRIMARY KEY,
  adjustment_number VARCHAR(50) UNIQUE NOT NULL,
  item_id VARCHAR(36) NOT NULL,
  location_id VARCHAR(36),
  adjustment_type ENUM('increase', 'decrease') NOT NULL,
  quantity DECIMAL(10,2) NOT NULL,
  reason TEXT,
  notes TEXT,
  status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
  adjustment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  adjusted_by VARCHAR(36) NOT NULL,
  approved_by VARCHAR(36),
  approved_at DATETIME,
  facilityId VARCHAR(36) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (item_id) REFERENCES inventory_items(id),
  FOREIGN KEY (location_id) REFERENCES inventory_locations(id),
  FOREIGN KEY (adjusted_by) REFERENCES users(id),
  FOREIGN KEY (approved_by) REFERENCES users(id)
);
```

### Stock Transfers Table
```sql
CREATE TABLE IF NOT EXISTS stock_transfers (
  id VARCHAR(36) PRIMARY KEY,
  transfer_number VARCHAR(50) UNIQUE NOT NULL,
  item_id VARCHAR(36) NOT NULL,
  from_location_id VARCHAR(36) NOT NULL,
  to_location_id VARCHAR(36) NOT NULL,
  quantity DECIMAL(10,2) NOT NULL,
  notes TEXT,
  status ENUM('pending', 'in_transit', 'completed', 'cancelled') DEFAULT 'pending',
  transfer_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  transferred_by VARCHAR(36) NOT NULL,
  received_by VARCHAR(36),
  received_at DATETIME,
  facilityId VARCHAR(36) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (item_id) REFERENCES inventory_items(id),
  FOREIGN KEY (from_location_id) REFERENCES inventory_locations(id),
  FOREIGN KEY (to_location_id) REFERENCES inventory_locations(id),
  FOREIGN KEY (transferred_by) REFERENCES users(id),
  FOREIGN KEY (received_by) REFERENCES users(id)
);
```

## Other Potential Missing Endpoints

### 3. Advanced Reporting (500 Errors)
Some advanced reporting endpoints exist in routes but may have implementation issues:
- `GET /inventory/reporting/schedules` - Returns 500 error
- `GET /inventory/reporting/templates` - May need verification
- `GET /inventory/reporting/history` - May need verification

## Frontend Workaround Applied ✅

Added graceful error handling in frontend components to handle 404 errors:
- `StockAdjustment.jsx` - Shows empty state when endpoint returns 404
- `StockTransfer.jsx` - Shows empty state when endpoint returns 404

## Implementation Priority

### High Priority (Core Functionality)
1. ✅ Stock Adjustments listing endpoint
2. ✅ Stock Transfers listing endpoint

### Medium Priority (Advanced Features)
3. Fix reporting schedules 500 error
4. Verify other advanced reporting endpoints

### Low Priority (Nice to Have)
5. Additional filtering and sorting options
6. Export functionality for adjustments/transfers

## Testing After Implementation

Once the backend endpoints are implemented, test:
1. Stock adjustments listing with filters
2. Stock transfers listing with filters
3. Pagination functionality
4. Permission-based access control
5. Error handling for invalid requests

## Summary

The frontend inventory module is correctly implemented and uses proper API patterns. The 404 errors are due to missing backend GET endpoints for listing stock adjustments and transfers. The frontend now handles these errors gracefully, but the backend needs to implement the missing endpoints for full functionality.