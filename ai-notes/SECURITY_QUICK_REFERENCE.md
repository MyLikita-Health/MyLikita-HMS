# Security System Quick Reference

**One-page cheat sheet for the new JWT authentication system**

---

## 🚀 Quick Start

### Login
```javascript
import { useDispatch } from 'react-redux';
import { login } from '../redux/actions/authActions';

const dispatch = useDispatch();
const result = await dispatch(login({ username, password }));
```

### Logout
```javascript
import { logout } from '../redux/actions/authActions';
dispatch(logout());
```

### Get Current User
```javascript
import { useSelector } from 'react-redux';
const { user, isAuthenticated } = useSelector(state => state.newAuth);
```

---

## 🔐 API Calls

### Import
```javascript
import { inventoryAPI, userAPI, authAPI } from '../../utils/apiClient';
```

### Inventory
```javascript
// Get items
const response = await inventoryAPI.getItems({ facilityId });
const items = response.data.results;

// Create item
await inventoryAPI.createItem(itemData);

// Update item
await inventoryAPI.updateItem(id, itemData);

// Delete item
await inventoryAPI.deleteItem(id);

// Get requisitions
const reqs = await inventoryAPI.getRequisitions({ facilityId, status });

// Approve requisition
await inventoryAPI.approveRequisition(id, { approvedBy: userId });
```

### Users
```javascript
// Get users
const users = await userAPI.getUsers(facilityId);

// Update user
await userAPI.updateUser(userData);

// Get current user
const me = await authAPI.me();
```

---

## 🔒 Permission Checks

### Import
```javascript
import { inventoryPermissions, hasPermission } from '../../utils/permissionHelper';
```

### Check Permissions
```javascript
// Method 1: Helper functions
if (inventoryPermissions.canCreateItems()) {
  // Show create button
}

// Method 2: Direct check
if (hasPermission('inventory', 'items', 'create')) {
  // Show create button
}

// Method 3: Component guard
import { PermissionGuard } from '../../utils/permissionHelper';

<PermissionGuard module="inventory" resource="items" action="create">
  <button>Create Item</button>
</PermissionGuard>
```

### Available Helpers
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

// Users
userPermissions.canViewUsers()
userPermissions.canCreateUsers()
userPermissions.canEditUsers()
userPermissions.canDeleteUsers()
userPermissions.canApproveUsers()
userPermissions.canSuspendUsers()
```

---

## 🎨 Component Pattern

```javascript
import React, { useState, useEffect } from 'react';
import { useSelector } from 'react-redux';
import { inventoryAPI } from '../../utils/apiClient';
import { inventoryPermissions } from '../../utils/permissionHelper';
import { Button, Spinner, Alert } from 'reactstrap';

const MyComponent = () => {
  const { user } = useSelector(state => state.newAuth);
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (inventoryPermissions.canViewItems()) {
      fetchData();
    }
  }, []);

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await inventoryAPI.getItems({ 
        facilityId: user.facilityId 
      });
      setData(response.data.results);
    } catch (error) {
      if (error.response?.status === 403) {
        setError('Permission denied');
      } else if (error.response?.status === 401) {
        setError('Session expired');
      } else {
        setError('An error occurred');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (itemData) => {
    try {
      await inventoryAPI.createItem(itemData);
      fetchData(); // Refresh
    } catch (error) {
      setError('Failed to create item');
    }
  };

  if (!inventoryPermissions.canViewItems()) {
    return <Alert color="warning">Permission denied</Alert>;
  }

  return (
    <div>
      {error && <Alert color="danger">{error}</Alert>}
      
      {inventoryPermissions.canCreateItems() && (
        <Button onClick={handleCreate}>Create</Button>
      )}

      {loading ? (
        <Spinner />
      ) : (
        <div>
          {/* Render data */}
        </div>
      )}
    </div>
  );
};

export default MyComponent;
```

---

## 🛡️ Error Handling

```javascript
try {
  await inventoryAPI.someAction();
} catch (error) {
  if (error.response?.status === 401) {
    // Unauthorized - token expired
    setError('Session expired. Please login again.');
    // Will auto-redirect to login
  } else if (error.response?.status === 403) {
    // Forbidden - no permission
    setError('You do not have permission to perform this action.');
  } else if (error.response?.status === 429) {
    // Rate limit exceeded
    setError('Too many requests. Please wait a moment.');
  } else if (error.response?.status === 404) {
    // Not found
    setError('Resource not found.');
  } else {
    // Other errors
    setError(error.response?.data?.error || 'An error occurred.');
  }
}
```

---

## 🔄 Protected Routes

```javascript
import ProtectedRoute from './components/common/ProtectedRoute';

<ProtectedRoute path="/me/inventory" component={InventoryDashboard} />
```

---

## 📊 Redux State

```javascript
// Access auth state
const { 
  isAuthenticated,  // boolean
  user,             // user object
  token,            // JWT token
  permissions,      // permissions object
  loading,          // boolean
  error             // error message
} = useSelector(state => state.newAuth);
```

---

## 🗄️ Database Queries

### Check User Permissions
```sql
SELECT u.username, ur.role_name, rp.module, rp.resource, rp.action
FROM users u
JOIN user_roles ur ON u.role = ur.role_code
JOIN role_permissions rp ON ur.id = rp.role_id
WHERE u.username = 'admin';
```

### View Active Sessions
```sql
SELECT u.username, us.ip_address, us.created_at, us.last_activity
FROM user_sessions us
JOIN users u ON us.user_id = u.id
WHERE us.is_active = TRUE;
```

### View Recent Activity
```sql
SELECT u.username, ual.action, ual.resource, ual.created_at
FROM user_activity_log ual
JOIN users u ON ual.user_id = u.id
ORDER BY ual.created_at DESC
LIMIT 20;
```

### Unlock Account
```sql
UPDATE users 
SET failed_login_attempts = 0, 
    account_locked_until = NULL 
WHERE username = 'username';
```

---

## 🧪 Testing

### Test Login
```bash
curl -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'
```

### Test Protected Endpoint
```bash
curl -X GET http://localhost:5000/inventory/items \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Check Token in Browser
```javascript
// In browser console
localStorage.getItem('accessToken')
localStorage.getItem('user')
localStorage.getItem('permissions')
```

---

## 🎯 Common Tasks

### Update Component to Use New API
1. Import API client and permission helpers
2. Get user from Redux
3. Replace axios calls with API client
4. Add permission checks
5. Improve error handling

### Add Permission Check to Button
```javascript
{inventoryPermissions.canCreateItems() && (
  <Button>Create</Button>
)}
```

### Show Different UI Based on Role
```javascript
import { hasRole } from '../../utils/permissionHelper';

{hasRole('admin') && <AdminPanel />}
{hasRole(['inventory_manager', 'store_keeper']) && <InventoryPanel />}
```

### Check if User Can Access Module
```javascript
import { canViewModule } from '../../utils/permissionHelper';

if (canViewModule('inventory')) {
  // Show inventory menu item
}
```

---

## 📞 Troubleshooting

### Token Expired Immediately
```bash
# Check JWT_SECRET in backend/.env
echo "JWT_SECRET=your-secret-key" >> backend/.env
```

### Permission Denied for Admin
```sql
-- Update user role
UPDATE users SET role = 'admin' WHERE username = 'admin';
```

### CORS Errors
```javascript
// In backend/app.js
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:5173'],
  credentials: true
}));
```

---

## 📚 Documentation

- **Full Guide**: `INTEGRATION_COMPLETE_SUMMARY.md`
- **Testing**: `SECURITY_TESTING_GUIDE.md`
- **Examples**: `COMPONENT_UPDATE_EXAMPLE.md`
- **Action Plan**: `NEXT_STEPS_ACTION_PLAN.md`

---

## ⚡ Key Points

1. **Always use API client** - Never use axios directly
2. **Always check permissions** - Hide buttons user can't use
3. **Always handle errors** - Show meaningful messages
4. **Always use user context** - Get from Redux state
5. **Always test with different roles** - Verify permissions work

---

**Version**: 1.0  
**Updated**: March 8, 2026  
**Status**: Ready to Use
