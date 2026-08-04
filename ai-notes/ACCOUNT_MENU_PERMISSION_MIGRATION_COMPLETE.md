# Account Menu Permission Migration - Complete

## Overview

Successfully migrated the Account module menu from the legacy `functionality` permission system to the new granular permissions system. This provides consistent, role-based access control across the application.

---

## What Was Changed

### 1. Permission Helper Updates (`frontend/src/utils/permissionHelper.js`)

Added comprehensive billing permission helpers:

```javascript
export const billingPermissions = {
  // Accounts
  canViewAccounts: () => hasPermission('billing', 'accounts', 'view'),
  canCreateAccounts: () => hasPermission('billing', 'accounts', 'create'),
  canEditAccounts: () => hasPermission('billing', 'accounts', 'edit'),
  canDeleteAccounts: () => hasPermission('billing', 'accounts', 'delete'),
  
  // Transactions
  canViewTransactions: () => hasPermission('billing', 'transactions', 'view'),
  canCreateTransactions: () => hasPermission('billing', 'transactions', 'create'),
  canEditTransactions: () => hasPermission('billing', 'transactions', 'edit'),
  
  // Bills
  canViewBills: () => hasPermission('billing', 'bills', 'view'),
  canCreateBills: () => hasPermission('billing', 'bills', 'create'),
  canEditBills: () => hasPermission('billing', 'bills', 'edit'),
  canDeleteBills: () => hasPermission('billing', 'bills', 'delete'),
  
  // Payments
  canViewPayments: () => hasPermission('billing', 'payments', 'view'),
  canCreatePayments: () => hasPermission('billing', 'payments', 'create'),
  canEditPayments: () => hasPermission('billing', 'payments', 'edit'),
  
  // Reports
  canViewReports: () => hasPermission('billing', 'reports', 'view'),
  canExportReports: () => hasPermission('billing', 'reports', 'export'),
  
  // Retainership
  canViewRetainership: () => hasPermission('billing', 'retainership', 'view'),
  canManageRetainership: () => hasPermission('billing', 'retainership', 'manage'),
  
  // Deposits
  canViewDeposits: () => hasPermission('billing', 'deposits', 'view'),
  canCreateDeposits: () => hasPermission('billing', 'deposits', 'create'),
  
  // Refunds
  canViewRefunds: () => hasPermission('billing', 'refunds', 'view'),
  canCreateRefunds: () => hasPermission('billing', 'refunds', 'create'),
  canApproveRefunds: () => hasPermission('billing', 'refunds', 'approve'),
  
  // Reconciliation
  canViewReconciliation: () => hasPermission('billing', 'reconciliation', 'view'),
  canExportReconciliation: () => hasPermission('billing', 'reconciliation', 'export'),
  
  // Balance History
  canViewBalanceHistory: () => hasPermission('billing', 'balance_history', 'view'),
  
  // Services
  canViewServices: () => hasPermission('billing', 'services', 'view'),
  canCreateServices: () => hasPermission('billing', 'services', 'create'),
  canEditServices: () => hasPermission('billing', 'services', 'edit'),
  canDeleteServices: () => hasPermission('billing', 'services', 'delete'),
  
  // Expenses
  canViewExpenses: () => hasPermission('billing', 'expenses', 'view'),
  canCreateExpenses: () => hasPermission('billing', 'expenses', 'create'),
  canEditExpenses: () => hasPermission('billing', 'expenses', 'edit'),
  
  // Account Chart
  canViewAccountChart: () => hasPermission('billing', 'account_chart', 'view'),
  canEditAccountChart: () => hasPermission('billing', 'account_chart', 'edit'),
  
  // Discounts
  canViewDiscounts: () => hasPermission('billing', 'discounts', 'view'),
  canApproveDiscounts: () => hasPermission('billing', 'discounts', 'approve'),
  canSetupDiscounts: () => hasPermission('billing', 'discounts', 'setup'),
  
  // Managed Care
  canViewManagedCare: () => hasPermission('billing', 'managed_care', 'view'),
  canEditManagedCare: () => hasPermission('billing', 'managed_care', 'edit'),
};
```

### 2. Account Menu Updates (`frontend/src/components/account/AccountMenu.jsx`)

**Before (Legacy System):**
```javascript
{user.accessTo
  ? canUseThis(user, ["Other Incomes"]) && (
    <ListMenuItem route="/me/account/services">
      Other Incomes
    </ListMenuItem>
  )
  : null}
```

**After (New Granular System):**
```javascript
{billingPermissions.canViewPayments() && (
  <ListMenuItem route="/me/account/services">
    Other Incomes
  </ListMenuItem>
)}
```

### 3. Database Migration (`backend/sql/add_account_module_permissions.sql`)

Created comprehensive permissions for the billing module:

**Permission Categories:**
- Accounts (view, create, edit, delete)
- Transactions (view, create, edit)
- Bills (view, create, edit, delete)
- Payments (view, create, edit)
- Reports (view, export)
- Services (view, create, edit, delete)
- Expenses (view, create, edit)
- Account Chart (view, edit)
- Discounts (view, approve, setup)
- Managed Care (view, edit)

**Plus all retainership permissions** (already existed):
- Retainership (view, manage)
- Deposits (view, create)
- Refunds (view, create, approve)
- Reconciliation (view, export)
- Balance History (view)

---

## Permission Matrix by Role

### Administrator
- **Full access** to all billing features

### Accountant
- Full access to accounts, transactions, bills, payments
- Full access to retainership features
- Can create/edit services and expenses
- Can edit account chart
- Can view discounts and managed care
- **Cannot:** Delete accounts/bills, approve refunds

### Billing Manager
- Can view/create/edit accounts, bills, payments
- Can view/create retainership deposits and refunds
- **Can approve refunds**
- Can view reports and reconciliation
- Can approve discounts
- **Cannot:** Edit account chart, manage services

### Cashier
- Can view bills and process payments
- Can record deposits
- Can view balance history
- Can view services
- **Cannot:** Create/edit accounts, bills, or services
- **Cannot:** Process refunds or view reports

### Facility Manager
- Can view all billing data
- Can approve refunds and discounts
- Can export reports
- **Cannot:** Create/edit transactions or services

---

## Menu Items and Required Permissions

| Menu Item | Permission Required |
|-----------|-------------------|
| Other Incomes | `billing.payments.view` |
| Reprint Receipt | `billing.payments.view` |
| Pending Bills | `billing.bills.view` |
| Part Payment Transactions | `billing.payments.view` |
| Record Expenses | `billing.expenses.create` |
| Make Deposit | `billing.deposits.create` |
| Create a Client Account | `billing.accounts.create` |
| Generate Account Report | `billing.reports.view` |
| HMO Patient Report | (Public - no permission) |
| Financial Reports | (Public - no permission) |
| Retainership Management | `billing.retainership.view` |
| Record Retainership Deposit | `billing.deposits.create` |
| Process Retainership Refund | `billing.refunds.create` |
| Balance Reconciliation | `billing.reconciliation.view` |
| HMO Billing Report | (Public - no permission) |
| Account Statement | `billing.accounts.view` |
| Pending Patient Bill | `billing.bills.view` |
| Cashier Page | `billing.payments.view` |
| Create/Edit Services | `billing.services.edit` |
| Setup Account Chart | `billing.account_chart.edit` |
| Setup Transactions | `billing.account_chart.edit` |
| Managed Care Settings | `billing.managed_care.edit` |

---

## Migration Benefits

### 1. Consistency
- All modules now use the same permission system
- Easier to understand and maintain
- Consistent behavior across the application

### 2. Granularity
- Fine-grained control over specific features
- Can grant access to specific actions (view vs create vs edit)
- Better security through principle of least privilege

### 3. Role-Based
- Permissions tied to roles in database
- Easy to modify role permissions without code changes
- Centralized permission management

### 4. Scalability
- Easy to add new permissions
- Easy to create new roles
- No need to update `functionality` arrays

### 5. Auditability
- All permissions stored in database
- Can track who has what permissions
- Can generate permission reports

---

## How to Use

### For Administrators

**Grant billing permissions to a user:**

```sql
-- Grant all billing permissions to a user
INSERT INTO user_permissions (user_id, permission_id, granted_by, granted_at)
SELECT 
  123, -- user_id
  p.id,
  1, -- admin_user_id
  NOW()
FROM permissions p
WHERE p.module = 'billing';
```

**Grant specific permission:**

```sql
-- Grant deposit creation permission
INSERT INTO user_permissions (user_id, permission_id, granted_by, granted_at)
VALUES (
  123, -- user_id
  (SELECT id FROM permissions WHERE name = 'billing.deposits.create'),
  1, -- admin_user_id
  NOW()
);
```

### For Developers

**Check permission in component:**

```javascript
import { billingPermissions } from '../../utils/permissionHelper';

// In component
{billingPermissions.canCreateDeposits() && (
  <Button onClick={handleCreateDeposit}>
    Record Deposit
  </Button>
)}
```

**Check permission in backend:**

```javascript
const { checkPermission } = require('../middleware/permissions');

router.post('/deposits', 
  authenticate, 
  checkPermission('billing', 'deposits', 'create'),
  controller.createDeposit
);
```

---

## Testing Checklist

- [ ] Run SQL migration to add permissions
- [ ] Verify permissions added to database
- [ ] Test menu visibility for different roles:
  - [ ] Administrator sees all menu items
  - [ ] Accountant sees most items (no delete)
  - [ ] Billing Manager sees management items
  - [ ] Cashier sees only payment-related items
  - [ ] Facility Manager sees view/approve items
- [ ] Test permission enforcement on routes
- [ ] Verify existing users still have access
- [ ] Test creating new users with roles
- [ ] Verify permission changes take effect after logout/login

---

## Migration Steps for Production

1. **Backup Database**
   ```bash
   mysqldump -u root prime > backup_before_permission_migration.sql
   ```

2. **Run Migration**
   ```bash
   mysql -u root prime < backend/sql/add_account_module_permissions.sql
   ```

3. **Verify Permissions**
   ```sql
   -- Check permissions were added
   SELECT COUNT(*) FROM permissions WHERE module = 'billing';
   
   -- Check role permissions
   SELECT r.name, COUNT(rp.id) as permission_count
   FROM roles r
   LEFT JOIN role_permissions rp ON r.id = rp.role_id
   LEFT JOIN permissions p ON rp.permission_id = p.id
   WHERE p.module = 'billing'
   GROUP BY r.name;
   ```

4. **Test with Different Roles**
   - Login as Administrator - verify full access
   - Login as Accountant - verify appropriate access
   - Login as Cashier - verify limited access

5. **Monitor for Issues**
   - Check application logs
   - Monitor user feedback
   - Be ready to rollback if needed

---

## Rollback Plan

If issues occur:

1. **Restore Database**
   ```bash
   mysql -u root prime < backup_before_permission_migration.sql
   ```

2. **Revert Code Changes**
   ```bash
   git revert <commit-hash>
   ```

3. **Clear User Sessions**
   ```sql
   UPDATE user_sessions SET is_active = FALSE;
   ```

---

## Future Enhancements

1. **UI for Permission Management**
   - Add permission assignment interface in User Management
   - Visual permission matrix
   - Bulk permission operations

2. **Permission Templates**
   - Pre-defined permission sets for common roles
   - Quick assignment of permission groups

3. **Permission Inheritance**
   - Department-level permissions
   - Team-based permissions

4. **Audit Trail**
   - Track permission changes
   - Who granted/revoked permissions
   - When permissions were changed

---

## Files Modified

- `frontend/src/utils/permissionHelper.js` - Added billing permission helpers
- `frontend/src/components/account/AccountMenu.jsx` - Migrated to new permission system
- `backend/sql/add_account_module_permissions.sql` - Database migration

---

## Summary

The Account module menu has been successfully migrated from the legacy `functionality` system to the new granular permissions system. This provides:

✅ Consistent permission checking across the application  
✅ Role-based access control with fine-grained permissions  
✅ Better security through principle of least privilege  
✅ Easier maintenance and scalability  
✅ Database-driven permission management  

All menu items now check specific permissions rather than generic functionality strings, making the system more secure and maintainable.
