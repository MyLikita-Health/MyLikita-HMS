# Developer Quick Reference - Security System

## 🚀 Quick Start

### Backend: Protect a Route

```javascript
// Import middleware
const { authenticate, requireRole } = require('../middleware/authenticate');
const { checkPermission } = require('../middleware/permissions');
const { writeLimiter } = require('../middleware/rateLimit');

// Protect route with authentication only
app.get('/api/data', authenticate, controller.getData);

// Protect with permission check
app.post('/inventory/items',
  authenticate,
  writeLimiter,
  checkPermission('inventory', 'items', 'create'),
  controller.createItem
);

// Protect with role check
app.delete('/users/:id',
  authenticate,
  requireRole('admin', 'facility_manager'),
  controller.deleteUser
);
```

### Frontend: Make API Call

```javascript
import { inventoryAPI } from '../utils/apiClient';

// Automatic authentication, token refresh, error handling
const response = await inventoryAPI.getItems();
const items = response.data.results;
```

### Frontend: Check Permission

```javascript
import { hasPermission, inventoryPermissions } from '../utils/permissionHelper';

// Method 1: Direct check
if (hasPermission('inventory', 'requisitions', 'approve')) {
  // Show button
}

// Method 2: Module helper
if (inventoryPermissions.canApproveRequisitions()) {
  // Show button
}

// Method 3: Component guard
<PermissionGuard module="inventory" resource="requisitions" action="approve">
  <Button>Approve</Button>
</PermissionGuard>
```

---

## 📋 Common Tasks

### Add New Permission

1. **Add to database:**
```sql
INSERT INTO role_permissions (role_id, module, resource, action, granted)
VALUES (
  (SELECT id FROM user_roles WHERE role_code = 'inventory_manager'),
  'inventory',
  'transfers',
  'approve',
  TRUE
);
```

2. **Use in backend:**
```javascript
app.post('/inventory/transfers/:id/approve',
  authenticate,
  checkPermission('inventory', 'transfers', 'approve'),
  controller.approveTransfer
);
```

3. **Check in frontend:**
```javascript
if (hasPermission('inventory', 'transfers', 'approve')) {
  // Show approve button
}
```

### Create New Role

```sql
-- 1. Create role
INSERT INTO user_roles (role_name, role_code, description, is_system_role)
VALUES ('Warehouse Manager', 'warehouse_manager', 'Manages warehouse operations', FALSE);

-- 2. Assign permissions
INSERT INTO role_permissions (role_id, module, resource, action, granted)
SELECT 
  (SELECT id FROM user_roles WHERE role_code = 'warehouse_manager'),
  'inventory',
  'stock',
  'view',
  TRUE;

-- 3. Assign to user
UPDATE users SET role = 'warehouse_manager' WHERE id = 123;
```

### Log Manual Activity

```javascript
const { logManualActivity } = require('../middleware/auditLog');

await logManualActivity(
  userId,
  'Approved requisition',
  'inventory',
  { resourceType: 'requisition', resourceId: reqId }
);
```

---

## 🔐 Authentication Flow

### Login
```javascript
// Frontend
import { login } from '../redux/actions/authActions';

const result = await dispatch(login({ username, password }));
if (result.success) {
  // Redirect to dashboard
}
```

### Logout
```javascript
// Frontend
import { logout } from '../redux/actions/authActions';

dispatch(logout()); // Clears tokens and redirects to login
```

### Check if Authenticated
```javascript
import { isAuthenticated } from '../redux/actions/authActions';

if (isAuthenticated()) {
  // User is logged in
}
```

---

## 📊 Permission Structure

```
Module → Resource → Action

Examples:
- inventory → items → view
- inventory → items → create
- inventory → requisitions → approve
- users → users → delete
- finance → reports → export
```

### Available Modules
- `inventory` - Inventory management
- `users` - User management
- `clinical` - Clinical operations
- `finance` - Financial operations
- `dental` - Dental operations
- `lab` - Laboratory operations

### Common Actions
- `view` - Read access
- `create` - Create new records
- `edit` - Update existing records
- `delete` - Delete records
- `approve` - Approve requests
- `issue` - Issue items
- `export` - Export data

---

## 🛠️ API Client Functions

### Authentication
```javascript
import { authAPI } from '../utils/apiClient';

await authAPI.login({ username, password });
await authAPI.logout();
await authAPI.refresh(refreshToken);
await authAPI.me();
```

### Users
```javascript
import { userAPI } from '../utils/apiClient';

await userAPI.getUsers(facilityId);
await userAPI.createUser(userData);
await userAPI.updateUser(userData);
await userAPI.deleteUser(id, facilityId);
await userAPI.getSessions(userId);
await userAPI.getActivity(userId, limit);
```

### Inventory
```javascript
import { inventoryAPI } from '../utils/apiClient';

await inventoryAPI.getItems(params);
await inventoryAPI.createItem(data);
await inventoryAPI.getRequisitions(params);
await inventoryAPI.approveRequisition(id, data);
await inventoryAPI.issueRequisition(id, data);
```

---

## 🎯 Permission Helpers

### Inventory
```javascript
import { inventoryPermissions } from '../utils/permissionHelper';

inventoryPermissions.canViewItems()
inventoryPermissions.canCreateItems()
inventoryPermissions.canEditItems()
inventoryPermissions.canDeleteItems()
inventoryPermissions.canViewStock()
inventoryPermissions.canAdjustStock()
inventoryPermissions.canTransferStock()
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
inventoryPermissions.canViewSuppliers()
inventoryPermissions.canCreateSuppliers()
inventoryPermissions.canEditSuppliers()
inventoryPermissions.canDeleteSuppliers()
inventoryPermissions.canViewReports()
inventoryPermissions.canExportReports()
```

### Users
```javascript
import { userPermissions } from '../utils/permissionHelper';

userPermissions.canViewUsers()
userPermissions.canCreateUsers()
userPermissions.canEditUsers()
userPermissions.canDeleteUsers()
userPermissions.canApproveUsers()
userPermissions.canSuspendUsers()
userPermissions.canViewRoles()
userPermissions.canViewActivityLog()
userPermissions.canViewSessions()
userPermissions.canTerminateSessions()
```

---

## 🔧 Middleware Options

### Authenticate
```javascript
const { authenticate, optionalAuth, requireFacility, requireRole } = require('../middleware/authenticate');

// Required authentication
app.get('/api/data', authenticate, controller.getData);

// Optional authentication (user data attached if logged in)
app.get('/api/public', optionalAuth, controller.getPublicData);

// Require facility access
app.get('/users/:facilityId', authenticate, requireFacility, controller.getUsers);

// Require specific role
app.delete('/users/:id', authenticate, requireRole('admin'), controller.deleteUser);
```

### Permissions
```javascript
const { checkPermission, checkAnyPermission } = require('../middleware/permissions');

// Single permission
app.post('/inventory/items',
  authenticate,
  checkPermission('inventory', 'items', 'create'),
  controller.createItem
);

// Any of multiple permissions
app.get('/reports',
  authenticate,
  checkAnyPermission([
    { module: 'inventory', resource: 'reports', action: 'view' },
    { module: 'finance', resource: 'reports', action: 'view' }
  ]),
  controller.getReports
);
```

### Rate Limiting
```javascript
const { authLimiter, writeLimiter, readLimiter, apiLimiter } = require('../middleware/rateLimit');

// Auth endpoints (5 req/15min)
app.post('/auth/login', authLimiter, controller.login);

// Write operations (30 req/15min)
app.post('/inventory/items', authenticate, writeLimiter, controller.createItem);

// Read operations (200 req/15min)
app.get('/inventory/items', authenticate, readLimiter, controller.getItems);

// General API (100 req/15min)
app.use('/api', apiLimiter);
```

### Audit Logging
```javascript
const { auditLog } = require('../middleware/auditLog');

// Log all requests
app.use('/inventory', auditLog());

// Log only errors
app.use('/api', auditLog({ logSuccess: false, logErrors: true }));

// Exclude specific paths
app.use('/api', auditLog({ excludePaths: ['/health', '/ping'] }));
```

---

## 🐛 Troubleshooting

### "Token expired"
- Token expires after 1 hour
- Should auto-refresh 30 seconds before expiry
- If refresh fails, user is redirected to login

### "Permission denied" (403)
- User doesn't have required permission
- Check user role and permissions in database
- Verify permission is assigned to role

### "Unauthorized" (401)
- No token provided or invalid token
- User needs to login
- Check if token is being sent in Authorization header

### "Too many requests" (429)
- Rate limit exceeded
- Wait for rate limit window to reset (15 minutes)
- Check if legitimate traffic or abuse

### "Account locked"
- 5 failed login attempts
- Wait 15 minutes or admin can unlock:
```sql
UPDATE users SET failed_login_attempts=0, locked_until=NULL WHERE id=123;
```

---

## 📝 Environment Variables

```bash
# Backend .env
JWT_SECRET=your-super-secret-key-minimum-32-characters-long
JWT_EXPIRES_IN=1h
REFRESH_TOKEN_SECRET=another-super-secret-key-for-refresh-tokens
REFRESH_TOKEN_EXPIRES_IN=7d
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION=15
```

```bash
# Frontend .env
REACT_APP_API_URL=http://localhost:5000
```

---

## 🔍 Useful Queries

### Check User Permissions
```sql
SELECT 
  ur.role_name,
  rp.module,
  rp.resource,
  rp.action
FROM users u
JOIN user_roles ur ON u.role = ur.role_code
JOIN role_permissions rp ON ur.id = rp.role_id
WHERE u.id = 123 AND rp.granted = TRUE;
```

### View Active Sessions
```sql
SELECT 
  u.username,
  us.ip_address,
  us.last_activity,
  us.expires_at
FROM user_sessions us
JOIN users u ON us.user_id = u.id
WHERE us.is_active = TRUE AND us.expires_at > NOW();
```

### View Recent Activity
```sql
SELECT 
  u.username,
  ual.action,
  ual.module,
  ual.created_at
FROM user_activity_log ual
JOIN users u ON ual.user_id = u.id
ORDER BY ual.created_at DESC
LIMIT 50;
```

### Check Failed Login Attempts
```sql
SELECT 
  username,
  failed_login_attempts,
  locked_until
FROM users
WHERE failed_login_attempts > 0
ORDER BY failed_login_attempts DESC;
```

---

## 📚 Documentation Links

- **Complete Plan**: `UNIFIED_SECURITY_IMPLEMENTATION_PLAN.md`
- **Quick Start**: `SECURITY_QUICK_START.md`
- **Frontend Guide**: `FRONTEND_API_CLIENT_COMPLETE.md`
- **Phase 1 Summary**: `PHASE_1_COMPLETE_SUMMARY.md`

---

## 💡 Tips

1. **Always use the API client** - Don't make raw axios calls
2. **Check permissions in UI** - Hide features user can't access
3. **Use component guards** - Declarative permission checks
4. **Log important actions** - Use manual activity logging
5. **Test with different roles** - Verify permissions work correctly
6. **Monitor failed logins** - Watch for suspicious activity
7. **Keep tokens secure** - Never log or expose tokens
8. **Use HTTPS in production** - Tokens should never go over HTTP

---

**Quick Reference Version**: 1.0  
**Last Updated**: March 8, 2026  
**Status**: Production Ready
