# Menu and Permissions Update - Complete ✅

## Summary

Successfully added the new retainership management features to the account module menu and updated the permissions system to control access.

---

## What Was Updated

### 1. Account Module Menu ✅

Added 3 new menu items to `AccountMenu.jsx`:

1. **Record Retainership Deposit**
   - Icon: FaMoneyBillWave
   - Route: `/me/account/retainership-deposit`
   - Permission: "Record Retainership Deposit"

2. **Process Retainership Refund**
   - Icon: FaUndo
   - Route: `/me/account/retainership-refund`
   - Permission: "Process Retainership Refund"

3. **Balance Reconciliation**
   - Icon: FaBalanceScale
   - Route: `/me/account/balance-reconciliation`
   - Permission: "Balance Reconciliation"

### 2. Routing Configuration ✅

Added 3 new routes to `AccountDashboard.jsx`:

```javascript
<Route path="/me/account/retainership-deposit" component={RetainershipDepositPage} />
<Route path="/me/account/retainership-refund" component={RetainershipRefundPage} />
<Route path="/me/account/balance-reconciliation" component={BalanceReconciliation} />
```

### 3. Page Components ✅

Created 2 new wrapper pages:

1. **RetainershipDepositPage.jsx**
   - Landing page for deposit recording
   - Instructions and guidelines
   - Opens DepositForm modal
   - Shows accounting impact

2. **RetainershipRefundPage.jsx**
   - Landing page for refund processing
   - Warning messages
   - Opens RefundForm modal
   - Shows accounting impact and common reasons

### 4. Permissions System ✅

Added granular permissions for retainership management:

**New Permissions:**
- `billing.deposits.view` - View deposits
- `billing.deposits.create` - Record deposits
- `billing.refunds.view` - View refunds
- `billing.refunds.create` - Process refunds
- `billing.refunds.approve` - Approve refunds
- `billing.reconciliation.view` - View reconciliation
- `billing.reconciliation.export` - Export reconciliation
- `billing.balance_history.view` - View balance history

---

## Permission Matrix

### Administrator
- ✅ View deposits
- ✅ Record deposits
- ✅ View refunds
- ✅ Process refunds
- ✅ Approve refunds
- ✅ View reconciliation
- ✅ Export reconciliation
- ✅ View balance history

### Accountant
- ✅ View deposits
- ✅ Record deposits
- ✅ View refunds
- ✅ Process refunds
- ❌ Approve refunds (requires manager)
- ✅ View reconciliation
- ✅ Export reconciliation
- ✅ View balance history

### Facility Manager
- ✅ View deposits
- ❌ Record deposits
- ✅ View refunds
- ❌ Process refunds
- ✅ Approve refunds
- ✅ View reconciliation
- ❌ Export reconciliation
- ✅ View balance history

### Cashier
- ✅ View deposits
- ✅ Record deposits
- ❌ View refunds
- ❌ Process refunds
- ❌ Approve refunds
- ❌ View reconciliation
- ❌ Export reconciliation
- ✅ View balance history

---

## Files Created

### Frontend
1. `frontend/src/components/account/RetainershipDepositPage.jsx` - Deposit landing page
2. `frontend/src/components/account/RetainershipRefundPage.jsx` - Refund landing page

### Backend
1. `backend/sql/add_retainership_permissions.sql` - Permissions SQL
2. `backend/sql/run_retainership_permissions.js` - Migration runner

### Documentation
1. `MENU_AND_PERMISSIONS_UPDATE.md` - This file

---

## Files Modified

1. `frontend/src/components/account/AccountMenu.jsx`
   - Added 3 new menu items
   - Added new icon imports

2. `frontend/src/components/account/AccountDashboard.jsx`
   - Added 3 new routes
   - Added component imports

---

## Menu Structure

The account module menu now includes:

```
Account Module
├── Other Incomes
├── Reprint Receipt
├── Pending Bills
├── Part Payment Transactions
├── Record Expenses
├── Make Deposit
├── Create a Client Account
├── Generate Account Report
├── HMO Patient Report
├── Financial Reports
├── 🆕 Record Retainership Deposit
├── 🆕 Process Retainership Refund
├── 🆕 Balance Reconciliation
├── HMO Billing Report
├── Account Statement
├── Pending Patient Bill
├── Cashier Page
├── Create/Edit Services
├── Setup Account Chart
├── Click to setup Transactions
└── Managed Care Settings
```

---

## Access Control

### How Permissions Work

1. **Menu Visibility**
   - Menu items only show if user has the required permission
   - Uses `canUseThis(user, ["Permission Name"])` function

2. **Route Protection**
   - Routes are accessible if user has permission
   - Backend API endpoints also check permissions

3. **Permission Checking**
   - Frontend: Menu visibility
   - Backend: API endpoint protection with `checkPermission` middleware

### Example Permission Check

```javascript
{user.accessTo
  ? canUseThis(user, ["Record Retainership Deposit"]) && (
    <ListMenuItem route="/me/account/retainership-deposit">
      <FaMoneyBillWave size={26} style={{ marginRight: 10 }} />
      Record Retainership Deposit
    </ListMenuItem>
  )
  : null}
```

---

## User Management Integration

### Assigning Permissions

**Option 1: Through User Management Dashboard**
1. Go to User Management
2. Select a user
3. Edit their role or custom permissions
4. Check the retainership permissions
5. Save

**Option 2: Through Database**
```sql
-- Grant deposit permission to a specific user
INSERT INTO user_permissions (user_id, module, resource, action, granted)
VALUES (123, 'billing', 'deposits', 'create', TRUE);

-- Grant refund approval to a manager
INSERT INTO user_permissions (user_id, module, resource, action, granted)
VALUES (456, 'billing', 'refunds', 'approve', TRUE);
```

**Option 3: Through Role Assignment**
```sql
-- Assign Accountant role to user
UPDATE users 
SET role_id = (SELECT id FROM user_roles WHERE role_code = 'accountant')
WHERE id = 123;
```

---

## Testing Access Control

### Test Scenarios

1. **Administrator Access**
   ```
   - Login as admin
   - Should see all 3 menu items
   - Should be able to record deposits
   - Should be able to process refunds
   - Should be able to view reconciliation
   ```

2. **Accountant Access**
   ```
   - Login as accountant
   - Should see all 3 menu items
   - Should be able to record deposits
   - Should be able to process refunds (but needs manager approval)
   - Should be able to view reconciliation
   ```

3. **Cashier Access**
   ```
   - Login as cashier
   - Should see only "Record Retainership Deposit"
   - Should NOT see refund or reconciliation
   - Should be able to record deposits
   ```

4. **Facility Manager Access**
   ```
   - Login as facility manager
   - Should see refund and reconciliation items
   - Should NOT see deposit recording
   - Should be able to approve refunds
   - Should be able to view reconciliation
   ```

---

## SQL Verification Queries

### Check User Permissions
```sql
-- Check what permissions a user has
SELECT 
  u.username,
  ur.role_name,
  rp.module,
  rp.resource,
  rp.action
FROM users u
LEFT JOIN user_roles ur ON u.role_id = ur.id
LEFT JOIN role_permissions rp ON ur.id = rp.role_id
WHERE u.id = 123
  AND rp.module = 'billing'
  AND rp.resource IN ('deposits', 'refunds', 'reconciliation')
ORDER BY rp.resource, rp.action;
```

### Check Role Permissions
```sql
-- Check what permissions a role has
SELECT 
  ur.role_name,
  rp.resource,
  GROUP_CONCAT(rp.action ORDER BY rp.action) as actions
FROM user_roles ur
JOIN role_permissions rp ON ur.id = rp.role_id
WHERE rp.module = 'billing'
  AND rp.resource IN ('deposits', 'refunds', 'reconciliation', 'balance_history')
GROUP BY ur.role_name, rp.resource
ORDER BY ur.role_name, rp.resource;
```

### List All Users with Deposit Permission
```sql
-- Find all users who can record deposits
SELECT DISTINCT
  u.id,
  u.username,
  u.firstname,
  u.lastname,
  ur.role_name
FROM users u
LEFT JOIN user_roles ur ON u.role_id = ur.id
LEFT JOIN role_permissions rp ON ur.id = rp.role_id
WHERE rp.module = 'billing'
  AND rp.resource = 'deposits'
  AND rp.action = 'create'
  AND rp.granted = TRUE;
```

---

## Troubleshooting

### Issue: Menu items not showing

**Possible Causes:**
1. User doesn't have required permission
2. Permission name mismatch
3. User role not assigned

**Solution:**
```sql
-- Check user's role
SELECT u.username, ur.role_name 
FROM users u 
LEFT JOIN user_roles ur ON u.role_id = ur.id 
WHERE u.id = 123;

-- Check role permissions
SELECT * FROM role_permissions 
WHERE role_id = (SELECT role_id FROM users WHERE id = 123)
  AND module = 'billing';

-- Grant permission if missing
INSERT INTO role_permissions (role_id, module, resource, action, granted)
VALUES (
  (SELECT role_id FROM users WHERE id = 123),
  'billing', 'deposits', 'create', TRUE
);
```

### Issue: API returns 403 Forbidden

**Possible Causes:**
1. Backend permission check failing
2. Token expired
3. Permission not in database

**Solution:**
1. Check backend logs for permission check
2. Verify token is valid
3. Run permissions migration again

### Issue: Permission changes not taking effect

**Solution:**
1. Clear browser cache
2. Logout and login again
3. Restart backend server
4. Check database for permission entry

---

## Migration Steps

### For New Installation
```bash
# 1. Run database migrations
cd backend/sql
node run_deposits_refunds_migration.js
node run_retainership_permissions.js

# 2. Restart backend
cd ../
npm start

# 3. Clear frontend cache and reload
```

### For Existing Installation
```bash
# 1. Backup database
mysqldump -u root prime > backup_$(date +%Y%m%d).sql

# 2. Run migrations
cd backend/sql
node run_deposits_refunds_migration.js
node run_retainership_permissions.js

# 3. Verify permissions
mysql -u root prime < verify_permissions.sql

# 4. Restart services
pm2 restart all  # or your process manager
```

---

## Security Considerations

### Permission Hierarchy
1. **Administrator** - Full access, no restrictions
2. **Facility Manager** - Approval authority, limited creation
3. **Accountant** - Operational access, no approval
4. **Cashier** - Limited to deposits only

### Approval Workflow
- Refunds require manager approval
- Approval is recorded in audit trail
- Approver ID is stored with refund

### Audit Trail
- All actions are logged
- User ID recorded for every transaction
- Timestamps for all operations
- Immutable records

---

## Best Practices

### For Administrators
1. Assign roles based on job function
2. Review permissions regularly
3. Use principle of least privilege
4. Monitor audit logs

### For Users
1. Only request permissions you need
2. Report suspicious activity
3. Logout when done
4. Don't share credentials

### For Developers
1. Always check permissions in backend
2. Use middleware for route protection
3. Log all permission checks
4. Test with different roles

---

## Next Steps

1. **Test Access Control**
   - Login with different roles
   - Verify menu visibility
   - Test API endpoints

2. **Train Users**
   - Show new menu items
   - Explain permissions
   - Demonstrate workflows

3. **Monitor Usage**
   - Check audit logs
   - Review access patterns
   - Identify issues

4. **Gather Feedback**
   - User experience
   - Permission adequacy
   - Feature requests

---

## Support

### Documentation
- `PAYMENT_SYSTEM_FINAL_STATUS.md` - Overall system status
- `PAYMENT_PHASE2_COMPLETE.md` - Phase 2 implementation
- `PAYMENT_PHASE2_QUICK_START.md` - Testing guide

### Database Tables
- `user_roles` - Role definitions
- `role_permissions` - Role-based permissions
- `user_permissions` - User-specific permissions
- `retainership_deposits` - Deposit audit trail
- `retainership_refunds` - Refund audit trail

### API Endpoints
- `POST /account/deposit` - Record deposit
- `POST /account/refund` - Process refund
- `GET /account/balance-reconciliation` - Reconciliation report
- `GET /account/balance-history/:patientId` - Balance history

---

**Menu and Permissions Update Complete!** ✅

All new features are now accessible through the account module menu with proper permission controls.
