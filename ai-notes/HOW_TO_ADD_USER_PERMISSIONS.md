# How to Add Privileges/Permissions for Users

## Overview

Your system uses a role-based permission system with the ability to assign custom permissions to individual users. This guide explains how to manage user access based on the current UI capabilities.

---

## Current UI Capabilities

The User Management Dashboard now supports:

✅ **Creating new users** with role, privilege level, and module access  
✅ **Editing existing users** - Change role, privilege, modules, and personal info  
✅ **Viewing user sessions** and activity logs  
✅ **Approving pending users**  
✅ **Suspending active users**  

All user management operations can now be performed through the UI!

---

## Method 1: Create or Edit User (via UI)

### Creating a New User:

1. **Navigate to User Management Dashboard**
   ```
   Admin Module → User Management
   OR
   Direct URL: /me/admin/users
   ```

2. **Click "Create User" Button**

3. **Fill in the Form:**

   **Basic Information:**
   - Username (required)
   - Password (required)
   - First Name (required)
   - Last Name (required)
   - Email (optional)
   - Phone (optional)

   **Role Selection:**
   - Administrator
   - Accountant
   - Billing Manager
   - Cashier
   - Dentist
   - Dental Assistant
   - Doctor
   - Nurse
   - Lab Technician
   - Inventory Manager
   - Store Keeper
   - Staff

   **Privilege Level (1-5):**
   - Level 1: View Only
   - Level 2: View & Create
   - Level 3: View, Create & Edit
   - Level 4: Full Operations (including delete)
   - Level 5: Administrative Access

   **Module Access:**
   - Check the modules the user can access:
     - Dashboard, Records, Doctors, Pharmacy
     - Dental, Dental Lab, Oral Care Shop
     - Nurse, Laboratory, Inventory
     - Accounts, Theater, Admin, Maintenance

4. **Click "Create User"**

5. **Approve the User** (if you have approval permissions)
   - Find the newly created user in the list
   - Click the "Approve" button (unlock icon)

### Editing an Existing User:

1. **Navigate to User Management Dashboard**

2. **Find the User** you want to edit
   - Use the search box to find by name, username, email, or role
   - Use filters to narrow down by role or status

3. **Click the Edit Button** (pencil icon) next to the user

4. **Update the Information:**
   - First Name, Last Name
   - Email, Phone
   - **Role** - Change to any available role
   - **Privilege Level** - Change from 1-5
   - **Module Access** - Add or remove modules
   - Password (leave blank to keep current password)
   - Username (cannot be changed)

5. **Click "Update User"**

6. **User must logout and login** to see the changes take effect

---

## Method 2: Modify User via SQL (Alternative)

If you prefer SQL or need to perform bulk operations, you can still use SQL queries:

### Update User Role:

```sql
-- Change user's role
UPDATE users 
SET role = 'accountant' 
WHERE username = 'john.doe';

-- Available roles:
-- 'admin', 'accountant', 'billing_manager', 'cashier'
-- 'dentist', 'dental_assistant', 'doctor', 'nurse'
-- 'lab_technician', 'inventory_manager', 'store_keeper', 'staff'
```

### Update Privilege Level:

```sql
-- Change user's privilege level (1-5)
UPDATE users 
SET privilege = 3 
WHERE username = 'john.doe';

-- Privilege levels:
-- 1 = View Only
-- 2 = View & Create
-- 3 = View, Create & Edit
-- 4 = Full Operations
-- 5 = Administrative Access
```

### Update Module Access:

```sql
-- Update modules user can access (stored as JSON array)
UPDATE users 
SET accessTo = '["Dashboard","Records","Accounts","Inventory"]'
WHERE username = 'john.doe';

-- Available modules:
-- Dashboard, Records, Doctors, Pharmacy, Dental, Dental Lab,
-- Oral Care Shop, Nurse, Laboratory, Inventory, Accounts,
-- Theater, Admin, Maintenance
```

### Complete User Update Example:

```sql
-- Update role, privilege, and modules for a user
UPDATE users 
SET 
  role = 'accountant',
  privilege = 3,
  accessTo = '["Dashboard","Accounts","Inventory","Records"]'
WHERE username = 'john.doe';
```

---

## Method 3: Granular Permissions (New Security System)

For the new security system with granular permissions:

### Assign a Role:

```sql
-- Assign Accountant role to a user
INSERT INTO user_roles (user_id, role_id, assigned_by, assigned_at)
VALUES (
  (SELECT id FROM users WHERE username = 'john.doe'),
  (SELECT id FROM roles WHERE name = 'Accountant'),
  (SELECT id FROM users WHERE username = 'admin'),
  NOW()
);
```

### Grant Specific Permissions:

```sql
-- Grant deposit creation permission
INSERT INTO user_permissions (user_id, permission_id, granted_by, granted_at)
VALUES (
  (SELECT id FROM users WHERE username = 'john.doe'),
  (SELECT id FROM permissions WHERE name = 'billing.deposits.create'),
  (SELECT id FROM users WHERE username = 'admin'),
  NOW()
);
```

### Bulk Permission Assignment:

```sql
-- Grant all retainership permissions at once
INSERT INTO user_permissions (user_id, permission_id, granted_by, granted_at)
SELECT 
  (SELECT id FROM users WHERE username = 'john.doe'),
  p.id,
  (SELECT id FROM users WHERE username = 'admin'),
  NOW()
FROM permissions p
WHERE p.name IN (
  'billing.deposits.view',
  'billing.deposits.create',
  'billing.refunds.view',
  'billing.refunds.create',
  'billing.balance_history.view',
  'billing.retainership.view',
  'billing.retainership.manage'
);
```

---

## Common User Configurations

### Cashier Configuration:

```sql
UPDATE users 
SET 
  role = 'cashier',
  privilege = 2,
  accessTo = '["Dashboard","Accounts"]'
WHERE username = 'cashier1';
```

**Permissions:**
- Can record deposits
- Can process payments
- Can view balance history
- Cannot approve refunds

### Accountant Configuration:

```sql
UPDATE users 
SET 
  role = 'accountant',
  privilege = 3,
  accessTo = '["Dashboard","Accounts","Inventory","Records"]'
WHERE username = 'accountant1';
```

**Permissions:**
- Full retainership management
- All deposit and refund operations (except approval)
- Financial reports
- Reconciliation

### Dentist Configuration:

```sql
UPDATE users 
SET 
  role = 'dentist',
  privilege = 4,
  accessTo = '["Dashboard","Dental","Dental Lab","Records","Pharmacy"]'
WHERE username = 'dr.smith';
```

**Permissions:**
- Full dental module access
- Treatment planning
- Procedure execution
- Prescription writing

### Inventory Manager Configuration:

```sql
UPDATE users 
SET 
  role = 'inventory_manager',
  privilege = 4,
  accessTo = '["Dashboard","Inventory","Pharmacy","Laboratory"]'
WHERE username = 'inv.manager';
```

**Permissions:**
- Full inventory management
- Stock adjustments
- Purchase orders
- GRN approval

---

## Verification Queries

### Check User's Current Settings:

```sql
-- View user's complete configuration
SELECT 
  id,
  username,
  firstname,
  lastname,
  role,
  privilege,
  accessTo,
  status,
  last_login
FROM users
WHERE username = 'john.doe';
```

### Check Role-Based Permissions:

```sql
-- Check permissions from assigned roles
SELECT 
  u.username,
  r.name as role_name,
  p.name as permission_name,
  p.description
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
JOIN role_permissions rp ON r.id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE u.username = 'john.doe';
```

### Check Direct Permissions:

```sql
-- Check directly assigned permissions
SELECT 
  u.username,
  p.name as permission_name,
  p.description,
  up.granted_at,
  granter.username as granted_by
FROM user_permissions up
JOIN users u ON up.user_id = u.id
JOIN permissions p ON up.permission_id = p.id
LEFT JOIN users granter ON up.granted_by = granter.id
WHERE u.username = 'john.doe';
```

### List All Users by Role:

```sql
-- Find all users with a specific role
SELECT 
  username,
  CONCAT(firstname, ' ', lastname) as full_name,
  role,
  privilege,
  status,
  last_login
FROM users
WHERE role = 'accountant'
ORDER BY lastname, firstname;
```

---

## Available Permissions Reference

### Retainership & Billing Permissions:

| Permission Name | Description |
|----------------|-------------|
| `billing.deposits.view` | View deposit records |
| `billing.deposits.create` | Record new deposits |
| `billing.refunds.view` | View refund requests |
| `billing.refunds.create` | Create refund requests |
| `billing.refunds.approve` | Approve refund requests |
| `billing.reconciliation.view` | View reconciliation reports |
| `billing.reconciliation.export` | Export reconciliation data |
| `billing.balance_history.view` | View balance history |
| `billing.retainership.view` | View retainership dashboard |
| `billing.retainership.manage` | Manage retainership plans |

### User Management Permissions:

| Permission Name | Description |
|----------------|-------------|
| `users.view` | View user list |
| `users.create` | Create new users |
| `users.edit` | Edit user details |
| `users.delete` | Delete users |
| `users.approve` | Approve pending users |
| `users.suspend` | Suspend users |
| `sessions.view` | View user sessions |
| `sessions.terminate` | Terminate sessions |
| `activity.view` | View activity logs |

---

## Troubleshooting

### Issue: User can't see menu items

**Cause:** User doesn't have the module in their `accessTo` array

**Solution:**
```sql
-- Add module to user's access
UPDATE users 
SET accessTo = JSON_ARRAY_APPEND(accessTo, '$', 'Accounts')
WHERE username = 'john.doe';

-- Or replace entire array
UPDATE users 
SET accessTo = '["Dashboard","Accounts","Inventory"]'
WHERE username = 'john.doe';
```

### Issue: User can't perform actions

**Cause:** Privilege level too low

**Solution:**
```sql
-- Increase privilege level
UPDATE users 
SET privilege = 3  -- View, Create & Edit
WHERE username = 'john.doe';
```

### Issue: Permission changes not taking effect

**Solutions:**
1. User must logout and login again
2. Clear browser cache
3. Restart backend server (if using cached permissions)

### Issue: User status is "pending"

**Solution:**
```sql
-- Approve user via SQL
UPDATE users 
SET status = 'active'
WHERE username = 'john.doe';

-- Or use UI: Click the unlock icon next to the user
```

---

## Best Practices

### 1. Use Appropriate Privilege Levels
- Don't give Level 5 unless necessary
- Match privilege to job requirements
- Review periodically

### 2. Limit Module Access
- Only grant access to needed modules
- Reduces confusion and errors
- Improves security

### 3. Document Custom Configurations
- Keep track of why users have specific settings
- Review during audits
- Update when roles change

### 4. Regular Audits
```sql
-- Find users with high privileges
SELECT username, role, privilege, status
FROM users
WHERE privilege >= 4
ORDER BY privilege DESC, username;

-- Find inactive users with access
SELECT username, role, status, last_login
FROM users
WHERE status = 'active'
  AND (last_login IS NULL OR last_login < DATE_SUB(NOW(), INTERVAL 90 DAY))
ORDER BY last_login;
```

### 5. Test Before Production
- Create test user
- Verify menu visibility
- Test operations
- Check permissions

---

## Quick Reference Scripts

### Grant Full Retainership Access:

```sql
UPDATE users 
SET 
  role = 'accountant',
  privilege = 3,
  accessTo = JSON_ARRAY_APPEND(
    JSON_ARRAY_APPEND(accessTo, '$', 'Dashboard'),
    '$', 'Accounts'
  )
WHERE username = 'USERNAME_HERE';
```

### Grant Cashier Access:

```sql
UPDATE users 
SET 
  role = 'cashier',
  privilege = 2,
  accessTo = '["Dashboard","Accounts"]'
WHERE username = 'USERNAME_HERE';
```

### Grant Dentist Access:

```sql
UPDATE users 
SET 
  role = 'dentist',
  privilege = 4,
  accessTo = '["Dashboard","Dental","Dental Lab","Records","Pharmacy"]'
WHERE username = 'USERNAME_HERE';
```

### Suspend a User:

```sql
UPDATE users 
SET status = 'suspended'
WHERE username = 'USERNAME_HERE';
```

### Reactivate a User:

```sql
UPDATE users 
SET status = 'active'
WHERE username = 'USERNAME_HERE';
```

---

## Future UI Enhancements

The following features are planned for future implementation:

- Bulk user operations (approve/suspend multiple users)
- User import/export
- Advanced filtering and search
- Role assignment interface with permission preview
- Permission assignment UI for granular control
- User activity analytics dashboard

---

## Support

For more information, see:
- `backend/sql/security_and_user_management_schema.sql` - Database schema
- `backend/sql/seed_roles_and_permissions.sql` - Default roles
- `backend/sql/add_retainership_permissions.sql` - Retainership permissions
- `frontend/src/components/users/UserManagementDashboard.jsx` - UI component

---

**Remember:** Users must logout and login again for permission changes to take effect!
