# Component Update Example

**Step-by-step guide to update components with new security system**

---

## 📋 Overview

This guide shows how to update an existing component to use:
1. New API client (with JWT tokens)
2. Permission checks
3. Error handling

---

## 🔄 Before & After Comparison

### BEFORE (Old Way)

```javascript
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Button } from 'reactstrap';

const ItemsList = () => {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchItems();
  }, []);

  const fetchItems = async () => {
    setLoading(true);
    try {
      const response = await axios.get('http://localhost:5000/inventory/items');
      setItems(response.data.results);
    } catch (error) {
      console.error('Error fetching items:', error);
      alert('Failed to fetch items');
    }
    setLoading(false);
  };

  const handleCreate = () => {
    // Navigate to create page
  };

  const handleDelete = async (id) => {
    try {
      await axios.delete(`http://localhost:5000/inventory/items/${id}`);
      fetchItems(); // Refresh list
    } catch (error) {
      alert('Failed to delete item');
    }
  };

  return (
    <div>
      <h2>Items List</h2>
      <Button onClick={handleCreate}>Create Item</Button>
      
      {loading ? (
        <p>Loading...</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Quantity</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {items.map(item => (
              <tr key={item.id}>
                <td>{item.name}</td>
                <td>{item.quantity}</td>
                <td>
                  <Button onClick={() => handleDelete(item.id)}>Delete</Button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
};

export default ItemsList;
```

---

### AFTER (New Way)

```javascript
import React, { useState, useEffect } from 'react';
import { Button, Spinner, Alert } from 'reactstrap';
import { inventoryAPI } from '../../utils/apiClient';
import { inventoryPermissions } from '../../utils/permissionHelper';
import { useSelector } from 'react-redux';

const ItemsList = () => {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  
  // Get user from Redux
  const { user } = useSelector(state => state.newAuth);

  useEffect(() => {
    if (inventoryPermissions.canViewItems()) {
      fetchItems();
    }
  }, []);

  const fetchItems = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await inventoryAPI.getItems({ 
        facilityId: user.facilityId 
      });
      setItems(response.data.results);
    } catch (error) {
      console.error('Error fetching items:', error);
      
      if (error.response?.status === 403) {
        setError('You do not have permission to view items');
      } else if (error.response?.status === 401) {
        setError('Session expired. Please login again.');
      } else {
        setError('Failed to fetch items. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = () => {
    // Navigate to create page
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this item?')) {
      return;
    }

    try {
      await inventoryAPI.deleteItem(id);
      fetchItems(); // Refresh list
    } catch (error) {
      if (error.response?.status === 403) {
        alert('You do not have permission to delete items');
      } else {
        alert('Failed to delete item. Please try again.');
      }
    }
  };

  // Check permissions
  const canCreate = inventoryPermissions.canCreateItems();
  const canDelete = inventoryPermissions.canDeleteItems();
  const canView = inventoryPermissions.canViewItems();

  // If user can't view, show message
  if (!canView) {
    return (
      <Alert color="warning">
        You do not have permission to view items.
      </Alert>
    );
  }

  return (
    <div>
      <div className="d-flex justify-content-between align-items-center mb-3">
        <h2>Items List</h2>
        {canCreate && (
          <Button color="primary" onClick={handleCreate}>
            Create Item
          </Button>
        )}
      </div>

      {error && (
        <Alert color="danger" toggle={() => setError(null)}>
          {error}
        </Alert>
      )}
      
      {loading ? (
        <div className="text-center p-5">
          <Spinner color="primary" />
          <p>Loading items...</p>
        </div>
      ) : (
        <table className="table table-striped">
          <thead>
            <tr>
              <th>Name</th>
              <th>Quantity</th>
              {canDelete && <th>Actions</th>}
            </tr>
          </thead>
          <tbody>
            {items.length === 0 ? (
              <tr>
                <td colSpan={canDelete ? 3 : 2} className="text-center">
                  No items found
                </td>
              </tr>
            ) : (
              items.map(item => (
                <tr key={item.id}>
                  <td>{item.name}</td>
                  <td>{item.quantity}</td>
                  {canDelete && (
                    <td>
                      <Button 
                        color="danger" 
                        size="sm"
                        onClick={() => handleDelete(item.id)}
                      >
                        Delete
                      </Button>
                    </td>
                  )}
                </tr>
              ))
            )}
          </tbody>
        </table>
      )}
    </div>
  );
};

export default ItemsList;
```

---

## 🔍 What Changed?

### 1. Imports

```javascript
// BEFORE
import axios from 'axios';

// AFTER
import { inventoryAPI } from '../../utils/apiClient';
import { inventoryPermissions } from '../../utils/permissionHelper';
import { useSelector } from 'react-redux';
```

### 2. Get User from Redux

```javascript
// AFTER
const { user } = useSelector(state => state.newAuth);
```

### 3. API Calls

```javascript
// BEFORE
const response = await axios.get('http://localhost:5000/inventory/items');

// AFTER
const response = await inventoryAPI.getItems({ 
  facilityId: user.facilityId 
});
```

### 4. Error Handling

```javascript
// BEFORE
catch (error) {
  console.error('Error:', error);
  alert('Failed');
}

// AFTER
catch (error) {
  if (error.response?.status === 403) {
    setError('You do not have permission');
  } else if (error.response?.status === 401) {
    setError('Session expired');
  } else {
    setError('Failed. Please try again.');
  }
}
```

### 5. Permission Checks

```javascript
// AFTER
const canCreate = inventoryPermissions.canCreateItems();
const canDelete = inventoryPermissions.canDeleteItems();

// In JSX
{canCreate && <Button>Create</Button>}
{canDelete && <Button>Delete</Button>}
```

---

## 📝 Step-by-Step Update Process

### Step 1: Update Imports

```javascript
// Add these imports
import { inventoryAPI } from '../../utils/apiClient';
import { inventoryPermissions } from '../../utils/permissionHelper';
import { useSelector } from 'react-redux';

// Remove axios import (if not used elsewhere)
// import axios from 'axios';
```

### Step 2: Get User from Redux

```javascript
// Add at top of component
const { user } = useSelector(state => state.newAuth);
```

### Step 3: Replace API Calls

Find all axios calls and replace:

```javascript
// Pattern 1: GET
// BEFORE
axios.get('/inventory/items')
// AFTER
inventoryAPI.getItems({ facilityId: user.facilityId })

// Pattern 2: POST
// BEFORE
axios.post('/inventory/items', data)
// AFTER
inventoryAPI.createItem(data)

// Pattern 3: PUT
// BEFORE
axios.put(`/inventory/items/${id}`, data)
// AFTER
inventoryAPI.updateItem(id, data)

// Pattern 4: DELETE
// BEFORE
axios.delete(`/inventory/items/${id}`)
// AFTER
inventoryAPI.deleteItem(id)
```

### Step 4: Add Permission Checks

```javascript
// Add permission variables
const canView = inventoryPermissions.canViewItems();
const canCreate = inventoryPermissions.canCreateItems();
const canEdit = inventoryPermissions.canEditItems();
const canDelete = inventoryPermissions.canDeleteItems();

// Use in JSX
{canCreate && <Button>Create</Button>}
{canEdit && <Button>Edit</Button>}
{canDelete && <Button>Delete</Button>}
```

### Step 5: Improve Error Handling

```javascript
catch (error) {
  console.error('Error:', error);
  
  if (error.response?.status === 403) {
    setError('You do not have permission to perform this action');
  } else if (error.response?.status === 401) {
    setError('Your session has expired. Please login again.');
    // Will auto-redirect to login
  } else if (error.response?.status === 429) {
    setError('Too many requests. Please wait a moment.');
  } else {
    setError(error.response?.data?.error || 'An error occurred. Please try again.');
  }
}
```

### Step 6: Add Loading States

```javascript
// Add error state
const [error, setError] = useState(null);

// Clear error on new action
const handleAction = async () => {
  setError(null); // Clear previous error
  // ... rest of code
};

// Show error in JSX
{error && (
  <Alert color="danger" toggle={() => setError(null)}>
    {error}
  </Alert>
)}
```

### Step 7: Test

1. Login with different user roles
2. Verify buttons show/hide correctly
3. Try actions without permission (should show error)
4. Check error messages display correctly
5. Verify loading states work

---

## 🎯 Common Patterns

### Pattern 1: List Component

```javascript
const ListComponent = () => {
  const { user } = useSelector(state => state.newAuth);
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (inventoryPermissions.canViewItems()) {
      fetchItems();
    }
  }, []);

  const fetchItems = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await inventoryAPI.getItems({ 
        facilityId: user.facilityId 
      });
      setItems(response.data.results);
    } catch (error) {
      handleError(error);
    } finally {
      setLoading(false);
    }
  };

  const handleError = (error) => {
    if (error.response?.status === 403) {
      setError('Permission denied');
    } else if (error.response?.status === 401) {
      setError('Session expired');
    } else {
      setError('An error occurred');
    }
  };

  return (
    // JSX
  );
};
```

### Pattern 2: Form Component

```javascript
const FormComponent = () => {
  const { user } = useSelector(state => state.newAuth);
  const [formData, setFormData] = useState({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      await inventoryAPI.createItem({
        ...formData,
        facilityId: user.facilityId,
        createdBy: user.id
      });
      
      // Success
      alert('Item created successfully');
      // Reset form or redirect
    } catch (error) {
      if (error.response?.status === 403) {
        setError('You do not have permission to create items');
      } else {
        setError('Failed to create item');
      }
    } finally {
      setLoading(false);
    }
  };

  if (!inventoryPermissions.canCreateItems()) {
    return <Alert color="warning">Permission denied</Alert>;
  }

  return (
    <Form onSubmit={handleSubmit}>
      {/* Form fields */}
      <Button type="submit" disabled={loading}>
        {loading ? 'Creating...' : 'Create Item'}
      </Button>
    </Form>
  );
};
```

### Pattern 3: Detail Component

```javascript
const DetailComponent = ({ itemId }) => {
  const { user } = useSelector(state => state.newAuth);
  const [item, setItem] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchItem();
  }, [itemId]);

  const fetchItem = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await inventoryAPI.getItemById(itemId);
      setItem(response.data.result);
    } catch (error) {
      handleError(error);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdate = async (data) => {
    try {
      await inventoryAPI.updateItem(itemId, data);
      fetchItem(); // Refresh
    } catch (error) {
      handleError(error);
    }
  };

  const handleDelete = async () => {
    if (!window.confirm('Are you sure?')) return;
    
    try {
      await inventoryAPI.deleteItem(itemId);
      // Redirect to list
    } catch (error) {
      handleError(error);
    }
  };

  return (
    <div>
      {/* Item details */}
      {inventoryPermissions.canEditItems() && (
        <Button onClick={() => handleUpdate(item)}>Edit</Button>
      )}
      {inventoryPermissions.canDeleteItems() && (
        <Button onClick={handleDelete}>Delete</Button>
      )}
    </div>
  );
};
```

---

## ✅ Checklist

When updating a component:

- [ ] Import new API client
- [ ] Import permission helpers
- [ ] Get user from Redux
- [ ] Replace all axios calls
- [ ] Add permission checks
- [ ] Improve error handling
- [ ] Add loading states
- [ ] Test with different roles
- [ ] Verify error messages
- [ ] Check button visibility

---

## 🐛 Common Mistakes

### Mistake 1: Hardcoded URLs

```javascript
// ❌ WRONG
axios.get('http://localhost:5000/inventory/items')

// ✅ CORRECT
inventoryAPI.getItems()
```

### Mistake 2: No Permission Checks

```javascript
// ❌ WRONG
<Button onClick={handleDelete}>Delete</Button>

// ✅ CORRECT
{inventoryPermissions.canDeleteItems() && (
  <Button onClick={handleDelete}>Delete</Button>
)}
```

### Mistake 3: Poor Error Handling

```javascript
// ❌ WRONG
catch (error) {
  alert('Error');
}

// ✅ CORRECT
catch (error) {
  if (error.response?.status === 403) {
    setError('Permission denied');
  } else if (error.response?.status === 401) {
    setError('Session expired');
  } else {
    setError('An error occurred');
  }
}
```

### Mistake 4: Not Using User Context

```javascript
// ❌ WRONG
inventoryAPI.getItems({ facilityId: 1 })

// ✅ CORRECT
const { user } = useSelector(state => state.newAuth);
inventoryAPI.getItems({ facilityId: user.facilityId })
```

---

## 📚 API Reference

### Inventory API

```javascript
// Items
inventoryAPI.getItems({ facilityId, categoryId, search })
inventoryAPI.getItemById(id)
inventoryAPI.createItem(data)
inventoryAPI.updateItem(id, data)
inventoryAPI.deleteItem(id)

// Stock
inventoryAPI.getStockLevels({ facilityId })
inventoryAPI.getLowStock(facilityId)
inventoryAPI.getItemStock(itemId)

// Requisitions
inventoryAPI.getRequisitions({ facilityId, status })
inventoryAPI.getRequisitionById(id)
inventoryAPI.createRequisition(data)
inventoryAPI.approveRequisition(id, data)
inventoryAPI.issueRequisition(id, data)

// Purchase Orders
inventoryAPI.getPurchaseOrders({ facilityId, status })
inventoryAPI.createPurchaseOrder(data)
inventoryAPI.approvePurchaseOrder(id, data)

// GRN
inventoryAPI.getGRNs({ facilityId, status })
inventoryAPI.createGRN(data)
inventoryAPI.approveGRN(id, data)

// Suppliers
inventoryAPI.getSuppliers({ facilityId })
inventoryAPI.createSupplier(data)
inventoryAPI.updateSupplier(id, data)
```

### Permission Helpers

```javascript
// Inventory
inventoryPermissions.canViewItems()
inventoryPermissions.canCreateItems()
inventoryPermissions.canEditItems()
inventoryPermissions.canDeleteItems()
inventoryPermissions.canViewStock()
inventoryPermissions.canAdjustStock()
inventoryPermissions.canViewRequisitions()
inventoryPermissions.canCreateRequisitions()
inventoryPermissions.canApproveRequisitions()
inventoryPermissions.canIssueRequisitions()
inventoryPermissions.canViewPurchaseOrders()
inventoryPermissions.canCreatePurchaseOrders()
inventoryPermissions.canApprovePurchaseOrders()
inventoryPermissions.canViewGRN()
inventoryPermissions.canCreateGRN()
inventoryPermissions.canApproveGRN()
```

---

## 🎯 Next Steps

1. Choose a component to update
2. Follow the step-by-step process
3. Test thoroughly
4. Move to next component
5. Repeat until all components updated

---

**Document Version**: 1.0  
**Last Updated**: March 8, 2026  
**Status**: Ready to Use
