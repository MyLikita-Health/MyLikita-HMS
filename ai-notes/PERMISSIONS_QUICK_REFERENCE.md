# Permissions System - Quick Reference

## Installation (One-Time Setup)

```bash
# 1. Install schema and seed permissions
cd backend/sql
node run_granular_permissions_setup.js

# 2. Migrate existing users
mysql -u root prime < migrate_users_to_granular_permissions.sql

# 3. Restart backend
cd ../
npm restart
```

---

## Usage in Components

### Import
```javascript
import { 
  hasPermission, 
  billingPermissions, 
  inventoryPermissions,
  userPermissions,
  dentalPermissions 
} from '../../utils/permissionHelper';
```

### Check Single Permission
```javascript
if (hasPermission('billing', 'bills', 'create')) {
  // User can create bills
}
```

### Use Module Helpers
```javascript
if (billingPermissions.canCreateBills()) {
  // User can create bills
}

if (inventoryPermissions.canApproveRequisitions()) {
  // User can approve requisitions
}
```

### Conditional Rendering
```javascript
{billingPermissions.canViewBills() && (
  <ListMenuItem route="/bills">View Bills</ListMenuItem>
)}
```

### Permission Guard Component
```javascript
<PermissionGuard 
  module="billing" 
  resource="bills" 
  action="create"
  fallback={<div>Access Denied</div>}
>
  <CreateBillForm />
</PermissionGuard>
```

---

## Common Permissions

### Billing
```javascript
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
billingPermissions.canCreateExpenses()
billingPermissions.canViewReports()
billingPermissions.canExportReports()
```

### Inventory
```javascript
inventoryPermissions.canViewItems()
inventoryPermissions.canCreateItems()
inventoryPermissions.canViewRequisitions()
inventoryPermissions.canCreateRequisitions()
inventoryPermissions.canApproveRequisitions()
inventoryPermissions.canViewGRN()
inventoryPermissions.canApproveGRN()
inventoryPermissions.canViewSuppliers()
```

### Users
```javascript
userPermissions.canViewUsers()
userPermissions.canCreateUsers()
userPermissions.canEditUsers()
userPermissions.canApproveUsers()
userPermissions.canViewRoles()
userPermissions.canViewActivityLog()
```

### Dental
```javascript
dentalPermissions.canViewPatients()
dentalPermissions.canCreatePatients()
dentalPermissions.canViewTreatmentPlans()
dentalPermissions.canCreateTreatmentPlans()
dentalPermissions.canApproveTreatmentPlans()
dentalPermissions.canViewAppointments()
dentalPermissions.canCreateAppointments()
```

---

## Permission Format

`module.resource.action`

Examples:
- `billing.bills.view`
- `billing.bills.create`
- `inventory.requisitions.approve`
- `dental.appointments.cancel`

---

## Roles

1. **admin** - Full access
2. **accountant** - Full billing access
3. **billing_manager** - Billing operations
4. **cashier** - Payment processing
5. **doctor** - Clinical access
6. **pharmacist** - Pharmacy operations
7. **lab_tech** - Laboratory operations
8. **inventory_manager** - Inventory management
9. **receptionist** - Registration & appointments
10. **facility_manager** - Oversight access

---

## Migration Example

### Before (Legacy)
```javascript
{user.accessTo && canUseThis(user, ["Record Expenses"]) && (
  <ListMenuItem route="/expenses">
    Record Expenses
  </ListMenuItem>
)}
```

### After (Granular)
```javascript
{billingPermissions.canCreateExpenses() && (
  <ListMenuItem route="/expenses">
    Record Expenses
  </ListMenuItem>
)}
```

---

## Debugging

### Check if permissions loaded
```javascript
console.log(localStorage.getItem('permissions'));
```

### Check specific permission
```javascript
import { hasPermission } from '../../utils/permissionHelper';
console.log(hasPermission('billing', 'bills', 'view'));
```

### Check user role
```javascript
import { getCurrentUser } from '../../utils/permissionHelper';
console.log(getCurrentUser().role);
```

---

## Adding New Permission

1. **Add to database:**
```sql
INSERT INTO permissions (name, description, module, resource, action) 
VALUES ('billing.invoices.send', 'Send invoices', 'billing', 'invoices', 'send');
```

2. **Map to role:**
```sql
INSERT INTO role_permissions (role_id, permission_id, granted)
SELECT r.id, p.id, TRUE
FROM roles r, permissions p
WHERE r.code = 'accountant' AND p.name = 'billing.invoices.send';
```

3. **Add helper (optional):**
```javascript
canSendInvoices: () => hasPermission('billing', 'invoices', 'send')
```

4. **Use in component:**
```javascript
{billingPermissions.canSendInvoices() && <button>Send</button>}
```

---

## Files Reference

- **Schema:** `backend/sql/complete_granular_permissions_schema.sql`
- **Seed:** `backend/sql/seed_comprehensive_permissions.sql`
- **Migration:** `backend/sql/migrate_users_to_granular_permissions.sql`
- **Helper:** `frontend/src/utils/permissionHelper.js`
- **Login:** `backend/controller/users.js`
- **Auth Action:** `frontend/src/redux/actions/auth.js`

---

## Need Help?

See `GRANULAR_PERMISSIONS_COMPLETE_GUIDE.md` for detailed documentation.
