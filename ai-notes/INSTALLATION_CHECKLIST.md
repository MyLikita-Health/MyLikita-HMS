# Granular Permissions System - Installation Checklist

Use this checklist to install and verify the granular permissions system.

---

## Pre-Installation

- [ ] Backend is running
- [ ] Database is accessible (MySQL, database: `prime`, user: `root`, no password)
- [ ] You have a backup of the database (recommended)
- [ ] Node.js is installed (for running migration script)

---

## Installation Steps

### Step 1: Install Schema and Seed Permissions

```bash
cd backend/sql
node run_granular_permissions_setup.js
```

**Expected Output:**
```
Connecting to database...
Connected successfully!

Step 1: Creating permissions tables...
✓ Tables created successfully

Step 2: Seeding permissions...
✓ Permissions seeded successfully

============================================================
GRANULAR PERMISSIONS SYSTEM INSTALLED SUCCESSFULLY!
============================================================
```

**Verification:**
- [ ] Script completed without errors
- [ ] Saw success message
- [ ] No database connection errors

**If errors occur:**
- Check database credentials in script
- Ensure MySQL is running
- Check database exists: `mysql -u root -e "SHOW DATABASES LIKE 'prime';"`

---

### Step 2: Verify Tables Created

```bash
mysql -u root prime -e "SHOW TABLES LIKE '%permission%'; SHOW TABLES LIKE '%role%';"
```

**Expected Output:**
```
permissions
role_permissions
roles
user_permissions
user_roles
```

**Verification:**
- [ ] All 5 tables exist
- [ ] No errors displayed

---

### Step 3: Verify Permissions Seeded

```bash
mysql -u root prime -e "SELECT COUNT(*) as total FROM permissions; SELECT COUNT(*) as total FROM roles;"
```

**Expected Output:**
```
total
150+

total
11
```

**Verification:**
- [ ] At least 150 permissions exist
- [ ] 11 roles exist

---

### Step 4: Migrate Existing Users

```bash
cd backend/sql
mysql -u root prime < migrate_users_to_granular_permissions.sql
```

**Expected Output:**
```
User migration complete!
[Table showing users without roles]
[Table showing role distribution]
[Table showing users with custom permissions]
```

**Verification:**
- [ ] Migration completed
- [ ] Role distribution looks reasonable
- [ ] Most users have been assigned roles

**Check specific user:**
```bash
mysql -u root prime -e "SELECT u.username, r.name as role FROM users u JOIN user_roles ur ON u.id = ur.user_id JOIN roles r ON ur.role_id = r.id WHERE u.username = 'YOUR_USERNAME';"
```

---

### Step 5: Restart Backend Server

```bash
cd backend
npm restart
```

**Or if using PM2:**
```bash
pm2 restart backend
```

**Verification:**
- [ ] Backend restarted successfully
- [ ] No startup errors
- [ ] Server is listening on port 46990

---

### Step 6: Test Login

1. **Open browser and navigate to your app**
2. **Login with your credentials**
3. **Open browser console (F12)**
4. **Check localStorage:**

```javascript
// In browser console
console.log(localStorage.getItem('permissions'));
```

**Expected Output:**
```json
{
  "billing": {
    "bills": ["view", "create", "edit"],
    "payments": ["view", "create"],
    ...
  },
  "inventory": {
    ...
  }
}
```

**Verification:**
- [ ] Login successful
- [ ] Permissions object exists in localStorage
- [ ] Permissions object has modules and resources
- [ ] Permissions match your role

---

### Step 7: Test Permission Helpers

**In browser console:**

```javascript
// Import helper (if using React DevTools)
// Or add this to a component temporarily

import { billingPermissions } from './utils/permissionHelper';

console.log('Can view bills:', billingPermissions.canViewBills());
console.log('Can create bills:', billingPermissions.canCreateBills());
console.log('Can approve refunds:', billingPermissions.canApproveRefunds());
```

**Verification:**
- [ ] Helper functions return boolean values
- [ ] Permissions match your role
- [ ] Admin users return true for all

---

### Step 8: Test with Different Roles

**Test with at least 3 different user roles:**

1. **Admin User**
   - [ ] Can see all menu items
   - [ ] All permission checks return true

2. **Accountant User**
   - [ ] Can see all billing menu items
   - [ ] Cannot see admin-only items

3. **Cashier User**
   - [ ] Can see payment-related items
   - [ ] Cannot see expense recording
   - [ ] Cannot see account setup items

---

## Post-Installation Verification

### Database Checks

```sql
-- 1. Check total permissions
SELECT COUNT(*) as total_permissions FROM permissions;
-- Expected: 150+

-- 2. Check total roles
SELECT COUNT(*) as total_roles FROM roles;
-- Expected: 11

-- 3. Check role-permission mappings
SELECT r.name, COUNT(rp.id) as permission_count
FROM roles r
LEFT JOIN role_permissions rp ON r.id = rp.role_id
GROUP BY r.id, r.name;
-- Expected: Each role has multiple permissions

-- 4. Check user-role mappings
SELECT COUNT(*) as users_with_roles FROM user_roles;
-- Expected: Most active users have roles

-- 5. Check specific user
SELECT 
  u.username,
  u.role as legacy_role,
  r.name as new_role,
  COUNT(p.id) as permission_count
FROM users u
LEFT JOIN user_roles ur ON u.id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.id
LEFT JOIN role_permissions rp ON r.id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.id
WHERE u.username = 'YOUR_USERNAME'
GROUP BY u.id, u.username, u.role, r.name;
```

**Verification:**
- [ ] All queries return expected results
- [ ] No NULL values where unexpected
- [ ] Permission counts look reasonable

---

## Troubleshooting

### Issue: Tables not created

**Solution:**
```bash
# Manually run schema
mysql -u root prime < complete_granular_permissions_schema.sql
```

### Issue: Permissions not seeded

**Solution:**
```bash
# Manually run seed
mysql -u root prime < seed_comprehensive_permissions.sql
```

### Issue: User has no permissions after login

**Check:**
```sql
-- Does user have a role?
SELECT * FROM user_roles WHERE user_id = X;

-- If not, assign manually:
INSERT INTO user_roles (user_id, role_id)
SELECT X, id FROM roles WHERE code = 'admin';
```

### Issue: Permission helper returns false for admin

**Check:**
```javascript
// In browser console
const user = JSON.parse(localStorage.getItem('user'));
console.log('User role:', user.role);
// Should be 'admin' or 'Administrator'
```

### Issue: Permissions not in localStorage

**Check:**
1. Backend login response includes permissions
2. Frontend auth action stores permissions
3. Clear localStorage and login again

---

## Rollback Plan

If you need to rollback:

1. **Database is unchanged** - Legacy fields still work
2. **Components still work** - Old permission checks still function
3. **No breaking changes** - System is backward compatible

To disable new system temporarily:
- Don't run migration scripts
- Don't update components
- System continues using legacy permissions

---

## Next Steps After Installation

- [ ] Read `PERMISSIONS_QUICK_REFERENCE.md`
- [ ] Review `ACCOUNT_MENU_MIGRATION_EXAMPLE.md`
- [ ] Start migrating AccountMenu component
- [ ] Test thoroughly with different roles
- [ ] Gradually migrate other components

---

## Success Criteria

Installation is successful when:

- [x] All 5 tables created
- [x] 150+ permissions seeded
- [x] 11 roles created
- [x] Users mapped to roles
- [x] Backend returns permissions on login
- [x] Frontend stores permissions in localStorage
- [x] Permission helpers work correctly
- [x] Different roles see different menu items

---

## Support

If you encounter issues:

1. Check this checklist
2. Review `GRANULAR_PERMISSIONS_COMPLETE_GUIDE.md`
3. Check database with SQL queries above
4. Verify backend logs for errors
5. Check browser console for errors

---

## Completion

Once all checkboxes are marked:

✅ **Granular Permissions System is installed and ready to use!**

You can now:
- Start migrating components
- Assign roles to users
- Customize permissions
- Add new permissions as needed

**Estimated time:** 15-30 minutes for complete installation and verification.
