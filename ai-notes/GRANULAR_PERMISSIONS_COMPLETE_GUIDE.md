# Granular Permissions System - Complete Implementation Guide

## Overview

This guide walks through the complete implementation of the granular permissions system, replacing the legacy `accessTo` and `functionality` fields with a modern role-based permission architecture.

---

## What Was Done

### 1. Database Schema ✓
- Created `permissions` table (master list of all permissions)
- Created `roles` table (system roles)
- Created `role_permissions` table (role-to-permission mapping)
- Created `user_roles` table (user-to-role mapping)
- Created `user_permissions` table (custom user permissions)
- Enhanced `users` table with security columns

**File:** `backend/sql/complete_granular_permissions_schema.sql`

### 2. Comprehensive Permissions Seed ✓
- Seeded 150+ permissions across all modules:
  - Billing (40+ permissions)
  - Inventory (20+ permissions)
  - Dental (20+ permissions)
  - Users (15+ permissions)
  - Records, Pharmacy, Laboratory, Admin
- Created 11 default roles
- Mapped permissions to roles

**File:** `backend/sql/seed_comprehensive_permissions.sql`

### 3. Backend Updates ✓

#### Login Endpoint Updated
- Fetches user permissions from database
- Groups permissions by module and resource
- Returns permissions in login response
- Backward compatible (works even if tables don't exist yet)

**File:** `backend/controller/users.js` - `login()` function

#### Existing Endpoints
- `getUserPermissions()` - Get permissions for a user
- `updateUserDetails()` - Update user with role/permissions
- `getUserById()` - Get user details

### 4. Frontend Updates ✓

#### Permission Storage
- Login action stores permissions in localStorage
- Logout action clears permissions
- Permissions available throughout app

**File:** `frontend/src/redux/actions/auth.js`

#### Permission Helper Functions
- Already exists with comprehensive helpers
- Module-specific helpers (billing, inventory, dental, users)
- Component guards (PermissionGuard, RoleGuard)

**File:** `frontend/src/utils/permissionHelper.js`

### 5. Migration Scripts ✓

#### Installation Script
- Runs schema creation
- Seeds permissions and roles
- Maps role permissions

**File:** `backend/sql/run_granular_permissions_setup.js`

#### User Migration Script
- Maps existing users to new roles
- Handles unmapped roles intelligently
- Grants custom permissions based on functionality

**File:** `backend/sql/migrate_users_to_granular_permissions.sql`

---

## Installation Steps

### Step 1: Install Database Schema

```bash
cd backend/sql
node run_granular_permissions_setup.js
```

This will:
- Create all permission tables
- Seed 150+ permissions
- Create 11 default roles
- Map permissions to roles

### Step 2: Migrate Existing Users

```bash
mysql -u root prime < migrate_users_to_granular_permissions.sql
```

This will:
- Map existing users to appropriate roles
- Grant custom permissions based on functionality
- Show verification reports

### Step 3: Restart Backend

```bash
cd backend
npm restart
```

The login endpoint will now return permissions.

### Step 4: Test Login

1. Login with any user
2. Check browser localStorage - you should see `permissions` key
3. Check browser console - permissions should be logged

---

## How to Use in Components

### Method 1: Using Permission Helpers

```javascript
import { billingPermissions } from '../../utils/permissionHelper';

function MyComponent() {
  if (!billingPermissions.canViewBills()) {
    return <div>Access Denied</div>;
  }
  
  return (
    <div>
      {billingPermissions.canCreateBills() && (
        <button>Create Bill</button>
      )}
    </div>
  );
}
```

### Method 2: Using hasPermission

```javascript
import { hasPermission } from '../../utils/permissionHelper';

function MyComponent() {
  const canView = hasPermission('billing', 'bills', 'view');
  const canCreate = hasPermission('billing', 'bills', 'create');
  
  if (!canView) return <div>Access Denied</div>;
  
  return (
    <div>
      {canCreate && <button>Create Bill</button>}
    </div>
  );
}
```

### Method 3: Using PermissionGuard Component

```javascript
import { PermissionGuard } from '../../utils/permissionHelper';

function MyComponent() {
  return (
    <div>
      <PermissionGuard 
        module="billing" 
        resource="bills" 
        action="view"
        fallback={<div>Access Denied</div>}
      >
        <BillsList />
      </PermissionGuard>
      
      <PermissionGuard 
        module="billing" 
        resource="bills" 
        action="create"
      >
        <button>Create Bill</button>
      </PermissionGuard>
    </div>
  );
}
```

### Method 4: Filter Menu Items

```javascript
import { filterMenuByPermissions } from '../../utils/permissionHelper';

const menuItems = [
  {
    label: 'View Bills',
    route: '/bills',
    permission: { module: 'billing', resource: 'bills', action: 'view' }
  },
  {
    label: 'Create Bill',
    route: '/bills/new',
    permission: { module: 'billing', resource: 'bills', action: 'create' }
  }
];

const filteredMenu = filterMenuByPermissions(menuItems);
```

---

## Migrating Components

### Example: AccountMenu.jsx

**Before (Legacy):**
```javascript
{user.accessTo && canUseThis(user, ["Record Expenses"]) && (
  <ListMenuItem route="/me/account/expenditure">
    Record Expenses
  </ListMenuItem>
)}
```

**After (Granular):**
```javascript
import { billingPermissions } from '../../utils/permissionHelper';

{billingPermissions.canCreateExpenses() && (
  <ListMenuItem route="/me/account/expenditure">
    Record Expenses
  </ListMenuItem>
)}
```

---

## Permission Naming Convention

Format: `module.resource.action`

Examples:
- `billing.bills.view`
- `billing.bills.create`
- `billing.payments.create`
- `inventory.items.edit`
- `dental.appointments.cancel`
- `users.users.approve`

---

## Available Roles

1. **Administrator** - Full system access
2. **Accountant** - Full billing and financial access
3. **Billing Manager** - Billing operations + approvals
4. **Cashier** - Payment processing
5. **Doctor** - Clinical and patient care
6. **Nurse** - Nursing care and vitals
7. **Pharmacist** - Pharmacy operations
8. **Lab Technician** - Laboratory operations
9. **Inventory Manager** - Inventory management
10. **Receptionist** - Patient registration and appointments
11. **Facility Manager** - Facility oversight

---

## Module-Specific Permission Helpers

### Billing Permissions
```javascript
import { billingPermissions } from '../../utils/permissionHelper';

billingPermissions.canViewBills()
billingPermissions.canCreateBills()
billingPermissions.canViewPayments()
billingPermissions.canCreatePayments()
billingPermissions.canViewRetainership()
billingPermissions.canManageRetainership()
billingPermissions.canViewDeposits()
billingPermissions.canCreateDeposits()
billingPermissions.canViewRefunds()
billingPermissions.canCreateRefunds()
billingPermissions.canApproveRefunds()
billingPermissions.canViewReconciliation()
billingPermissions.canCreateExpenses()
// ... and more
```

### Inventory Permissions
```javascript
import { inventoryPermissions } from '../../utils/permissionHelper';

inventoryPermissions.canViewItems()
inventoryPermissions.canCreateItems()
inventoryPermissions.canViewRequisitions()
inventoryPermissions.canApproveRequisitions()
inventoryPermissions.canViewGRN()
inventoryPermissions.canApproveGRN()
// ... and more
```

### User Management Permissions
```javascript
import { userPermissions } from '../../utils/permissionHelper';

userPermissions.canViewUsers()
userPermissions.canCreateUsers()
userPermissions.canEditUsers()
userPermissions.canApproveUsers()
userPermissions.canViewRoles()
// ... and more
```

### Dental Permissions
```javascript
import { dentalPermissions } from '../../utils/permissionHelper';

dentalPermissions.canViewPatients()
dentalPermissions.canCreateTreatmentPlans()
dentalPermissions.canApproveTreatmentPlans()
dentalPermissions.canViewAppointments()
// ... and more
```

---

## Adding New Permissions

### 1. Add to Database

```sql
INSERT INTO permissions (name, description, module, resource, action, is_system) 
VALUES ('billing.invoices.send', 'Send invoices to clients', 'billing', 'invoices', 'send', TRUE);
```

### 2. Map to Roles

```sql
INSERT INTO role_permissions (role_id, permission_id, granted)
SELECT r.id, p.id, TRUE
FROM roles r
CROSS JOIN permissions p
WHERE r.code = 'accountant' AND p.name = 'billing.invoices.send';
```

### 3. Add Helper Function (Optional)

```javascript
// In permissionHelper.js
export const billingPermissions = {
  // ... existing helpers
  canSendInvoices: () => hasPermission('billing', 'invoices', 'send'),
};
```

### 4. Use in Component

```javascript
import { billingPermissions } from '../../utils/permissionHelper';

{billingPermissions.canSendInvoices() && (
  <button onClick={sendInvoice}>Send Invoice</button>
)}
```

---

## Backward Compatibility

The system maintains backward compatibility:

1. **Legacy `accessTo` and `functionality` still work**
   - Existing components using `canUseThis()` continue to function
   - No breaking changes

2. **Gradual Migration**
   - Migrate components one at a time
   - Both systems can coexist

3. **Login Returns Both**
   - Login response includes both legacy fields and new permissions
   - Frontend can use either or both

---

## Next Steps

### Phase 1: Core Modules (Week 1)
- ✓ Account/Billing Module
- Inventory Module
- User Management Module

### Phase 2: Clinical Modules (Week 2)
- Dental Module
- Pharmacy Module
- Laboratory Module

### Phase 3: Supporting Modules (Week 3)
- Records Module
- Admin Module
- Reports Module

### Phase 4: UI Enhancements (Week 4)
- Permission Management UI in User Management
- Role Management UI
- Permission Matrix View
- Bulk Permission Assignment

---

## Troubleshooting

### Permissions Not Loading
1. Check if tables exist: `SHOW TABLES LIKE '%permission%';`
2. Check if permissions are seeded: `SELECT COUNT(*) FROM permissions;`
3. Check if user has role: `SELECT * FROM user_roles WHERE user_id = X;`
4. Check browser localStorage for `permissions` key

### User Has No Permissions
1. Check if user has role assigned
2. Run migration script: `migrate_users_to_granular_permissions.sql`
3. Manually assign role in database

### Permission Not Working
1. Check permission name format: `module.resource.action`
2. Check if permission exists in database
3. Check if role has permission
4. Check if user has role

---

## Support

For questions or issues:
1. Check this guide
2. Review `permissionHelper.js` for available functions
3. Check database tables for permission mappings
4. Review migration scripts for examples

---

## Summary

The granular permissions system is now fully implemented and ready to use. The system provides:

- ✓ 150+ granular permissions across all modules
- ✓ 11 predefined roles with appropriate permissions
- ✓ Backend API returning permissions on login
- ✓ Frontend storing and using permissions
- ✓ Comprehensive helper functions
- ✓ Migration scripts for existing users
- ✓ Backward compatibility with legacy system
- ✓ Easy-to-use component integration

Start migrating components to use the new system for better security and maintainability!
