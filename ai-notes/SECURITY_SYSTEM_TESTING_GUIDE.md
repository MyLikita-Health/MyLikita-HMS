# Security System - Complete Testing & Integration Guide

**Date**: March 8, 2026  
**Phase**: 4 - Integration & Testing  
**Status**: Ready for Testing

---

## Overview

This guide provides comprehensive testing procedures for the complete security system including JWT authentication, RBAC, session management, and audit logging.

---

## Pre-Testing Checklist

### Database Setup
- [ ] Run `backend/sql/security_and_user_management_schema.sql`
- [ ] Run `backend/sql/seed_roles_and_permissions.sql`
- [ ] Verify tables exist: `user_roles`, `role_permissions`, `user_sessions`, `user_activity_log`
- [ ] Verify at least one admin user exists

### Backend Setup
- [ ] Environment variables set in `backend/.env`:
  ```bash
  JWT_SECRET=your-secret-key-minimum-32-characters
  JWT_EXPIRES_IN=1h
  REFRESH_TOKEN_SECRET=another-secret-key
  REFRESH_TOKEN_EXPIRES_IN=7d
  ```
- [ ] Dependencies installed: `jsonwebtoken`, `bcrypt`, `express-rate-limit`
- [ ] Backend server running on port 46990

### Frontend Setup
- [ ] Dependencies installed: `axios`, `jwt-decode`
- [ ] Frontend running on port 3000 or 5173
- [ ] Redux store configured with `newAuth` reducer

---

## Day 1-2: Frontend Integration Testing

### Test 1: Login Flow

#### Test Case 1.1: Successful Login
```javascript
// Steps:
1. Navigate to /auth
2. Enter valid credentials (username: admin, password: your-password)
3. Click Login

// Expected Results:
✓ User redirected to /me/welcome
✓ Access token stored in localStorage
✓ Refresh token stored in localStorage
✓ User data stored in localStorage
✓ Permissions stored in localStorage
✓ Redux state updated (newAuth.isAuthenticated = true)
✓ User info displayed in navbar

// Verify in Browser Console:
localStorage.getItem('accessToken')
localStorage.getItem('refreshToken')
localStorage.getItem('user')
localStorage.getItem('permissions')
```

#### Test Case 1.2: Failed Login
```javascript
// Steps:
1. Navigate to /auth
2. Enter invalid credentials
3. Click Login

// Expected Results:
✓ Error message displayed
✓ User remains on login page
✓ No tokens stored
✓ Redux state unchanged (isAuthenticated = false)
```

#### Test Case 1.3: Account Lockout
```javascript
// Steps:
1. Attempt login with wrong password 5 times

// Expected Results:
✓ After 5 attempts, account locked for 15 minutes
✓ Error message: "Account locked. Try again in X minutes"
✓ Database: users.account_locked_until set
✓ Database: users.failed_login_attempts = 5
```

### Test 2: Token Refresh

#### Test Case 2.1: Automatic Token Refresh
```javascript
// Steps:
1. Login successfully
2. Wait for token to expire (or manually expire it)
3. Make an API call

// Expected Results:
✓ Token automatically refreshed before expiry
✓ New access token stored
✓ API call succeeds
✓ No redirect to login

// Verify in Network Tab:
- Look for POST /auth/refresh request
- Check response contains new token
```

#### Test Case 2.2: Expired Refresh Token
```javascript
// Steps:
1. Login successfully
2. Manually expire refresh token (or wait 7 days)
3. Make an API call

// Expected Results:
✓ Refresh fails
✓ User redirected to /auth
✓ Tokens cleared from localStorage
✓ Redux state reset
```

### Test 3: Permission-Based UI

#### Test Case 3.1: Admin User
```javascript
// Steps:
1. Login as admin
2. Navigate to /me/inventory
3. Check visible buttons/actions

// Expected Results:
✓ All buttons visible (Create, Edit, Delete, Approve)
✓ All menu items visible
✓ No permission denied messages
```

#### Test Case 3.2: Limited User
```javascript
// Steps:
1. Login as store_keeper
2. Navigate to /me/inventory
3. Check visible buttons/actions

// Expected Results:
✓ Only permitted buttons visible
✓ Create/Edit buttons hidden if no permission
✓ Approve button hidden
✓ Permission-based menu filtering works
```

#### Test Case 3.3: Permission Check Examples
```javascript
// In any component:
import { inventoryPermissions } from '../../utils/permissionHelper';

// Test these return correct values:
console.log(inventoryPermissions.canCreateItems()); // true/false
console.log(inventoryPermissions.canApproveRequisitions()); // true/false
console.log(inventoryPermissions.canViewReports()); // true/false
```

### Test 4: API Client Integration

#### Test Case 4.1: Inventory API
```javascript
import { inventoryAPI } from '../../utils/apiClient';

// Test these work:
const items = await inventoryAPI.getItems({ facilityId: 1 });
const item = await inventoryAPI.getItemById(1);
const created = await inventoryAPI.createItem(data);
```

#### Test Case 4.2: User API
```javascript
import { userAPI } from '../../utils/apiClient';

// Test these work:
const users = await userAPI.getUsers(1);
const sessions = await userAPI.getSessions(userId);
const activity = await userAPI.getActivity(userId);
const permissions = await userAPI.getPermissions(userId);
```

#### Test Case 4.3: Role API
```javascript
import { roleAPI } from '../../utils/apiClient';

// Test these work:
const roles = await roleAPI.getAllRoles();
const role = await roleAPI.getRoleById(1);
const permissions = await roleAPI.getAvailablePermissions();
```

### Test 5: Error Handling

#### Test Case 5.1: 401 Unauthorized
```javascript
// Steps:
1. Login successfully
2. Manually clear access token from localStorage
3. Make an API call

// Expected Results:
✓ API call fails with 401
✓ User redirected to /auth
✓ Error message displayed
```

#### Test Case 5.2: 403 Forbidden
```javascript
// Steps:
1. Login as limited user
2. Try to access admin-only endpoint

// Expected Results:
✓ API call fails with 403
✓ Error message: "Permission denied"
✓ User stays on current page
```

#### Test Case 5.3: 429 Rate Limit
```javascript
// Steps:
1. Make 100+ API calls rapidly

// Expected Results:
✓ After limit, requests fail with 429
✓ Error message: "Too many requests"
✓ Requests succeed after wait period
```

---

## Day 3-4: End-to-End Testing

### Test Scenario 1: Complete User Journey

```
1. User Registration
   → Navigate to /signup
   → Fill registration form
   → Submit
   → Verify user created with status='pending'

2. Admin Approval
   → Login as admin
   → Navigate to /me/admin/users
   → Find pending user
   → Click Approve
   → Verify user status='active'

3. User Login
   → Logout admin
   → Login as new user
   → Verify successful login
   → Verify correct permissions loaded

4. Use System
   → Navigate to permitted modules
   → Perform permitted actions
   → Verify actions succeed

5. Session Management
   → Admin views user sessions
   → Admin terminates a session
   → Verify user logged out on that device

6. Activity Tracking
   → Admin views user activity
   → Verify all actions logged
   → Verify timestamps correct
```

### Test Scenario 2: Permission Changes

```
1. Initial State
   → User has 'store_keeper' role
   → Can view items, create requisitions
   → Cannot approve requisitions

2. Role Change
   → Admin changes user role to 'inventory_manager'
   → User logs out and back in
   → Verify new permissions loaded

3. Verify New Permissions
   → User can now approve requisitions
   → User can create purchase orders
   → UI buttons updated accordingly
```

### Test Scenario 3: Multi-Session Management

```
1. Login on Device 1 (Chrome)
   → Login successfully
   → Note session ID

2. Login on Device 2 (Firefox)
   → Login with same user
   → Verify both sessions active

3. View Sessions
   → Navigate to user profile
   → View active sessions
   → Verify both sessions listed

4. Terminate Session
   → Terminate Device 1 session
   → Verify Device 1 logged out
   → Verify Device 2 still active
```

### Test Scenario 4: Audit Trail

```
1. Perform Actions
   → Create inventory item
   → Update item
   → Delete item
   → Approve requisition

2. Check Audit Log
   → Navigate to activity log
   → Verify all actions logged
   → Verify correct timestamps
   → Verify correct user_id
   → Verify correct resource_type and resource_id

3. Filter Audit Log
   → Filter by module (inventory)
   → Filter by action (create)
   → Verify filters work
```

---

## Day 5: Security Audit

### Security Test 1: SQL Injection

```bash
# Test login with SQL injection attempts
curl -X POST http://localhost:46990/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin'\'' OR 1=1--","password":"anything"}'

# Expected: Login fails, no SQL error exposed
```

### Security Test 2: XSS Prevention

```javascript
// Test creating item with XSS payload
const xssPayload = '<script>alert("XSS")</script>';
await inventoryAPI.createItem({
  name: xssPayload,
  description: xssPayload
});

// Expected: Payload stored as text, not executed
// Verify in UI: Script tags visible as text, not executed
```

### Security Test 3: CSRF Protection

```bash
# Test making request without proper origin
curl -X POST http://localhost:46990/inventory/items \
  -H "Authorization: Bearer TOKEN" \
  -H "Origin: http://malicious-site.com" \
  -d '{"name":"Test"}'

# Expected: Request blocked by CORS
```

### Security Test 4: Token Tampering

```javascript
// Steps:
1. Login successfully
2. Get access token from localStorage
3. Modify token payload (change user_id)
4. Make API request with modified token

// Expected:
✓ Request fails with 401
✓ Error: "Invalid token"
✓ User logged out
```

### Security Test 5: Brute Force Protection

```bash
# Test rapid login attempts
for i in {1..10}; do
  curl -X POST http://localhost:46990/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"wrong"}'
done

# Expected:
✓ After 5 attempts, account locked
✓ Rate limiting kicks in
✓ Subsequent requests blocked
```

### Security Test 6: Permission Bypass Attempts

```bash
# Test accessing admin endpoint as regular user
curl -X GET http://localhost:46990/roles \
  -H "Authorization: Bearer REGULAR_USER_TOKEN"

# Expected: 403 Forbidden

# Test modifying another user's data
curl -X PUT http://localhost:46990/users/access/update \
  -H "Authorization: Bearer USER_TOKEN" \
  -d '{"id":999,"role":"admin"}'

# Expected: 403 Forbidden or validation error
```

### Security Test 7: Session Hijacking Prevention

```javascript
// Steps:
1. Login on Device A
2. Copy session token
3. Try to use token on Device B (different IP)

// Expected:
✓ Token works (sessions are portable)
✓ But activity logged with different IP
✓ Admin can see suspicious activity
```

---

## Performance Testing

### Test 1: Token Refresh Performance

```javascript
// Measure token refresh time
console.time('tokenRefresh');
await apiClient.get('/auth/me');
console.timeEnd('tokenRefresh');

// Expected: < 200ms
```

### Test 2: Permission Check Performance

```javascript
// Measure permission check time
console.time('permissionCheck');
const canApprove = inventoryPermissions.canApproveRequisitions();
console.timeEnd('permissionCheck');

// Expected: < 1ms (cached in memory)
```

### Test 3: API Response Time

```javascript
// Measure API call with auth
console.time('apiCall');
await inventoryAPI.getItems({ facilityId: 1 });
console.timeEnd('apiCall');

// Expected: < 500ms
```

### Test 4: Concurrent Requests

```javascript
// Test multiple simultaneous requests
const promises = [];
for (let i = 0; i < 10; i++) {
  promises.push(inventoryAPI.getItems({ facilityId: 1 }));
}
await Promise.all(promises);

// Expected: All succeed, no race conditions
```

---

## Database Verification

### Check 1: User Sessions

```sql
-- View active sessions
SELECT 
  u.username,
  us.ip_address,
  us.created_at,
  us.last_activity,
  us.is_active
FROM user_sessions us
JOIN users u ON us.user_id = u.id
WHERE us.is_active = TRUE;

-- Expected: See all active sessions
```

### Check 2: Activity Log

```sql
-- View recent activity
SELECT 
  u.username,
  ual.action,
  ual.module,
  ual.resource_type,
  ual.created_at
FROM user_activity_log ual
JOIN users u ON ual.user_id = u.id
ORDER BY ual.created_at DESC
LIMIT 20;

-- Expected: See logged activities
```

### Check 3: Role Permissions

```sql
-- View role permissions
SELECT 
  ur.role_name,
  rp.module,
  rp.resource,
  rp.action
FROM role_permissions rp
JOIN user_roles ur ON rp.role_id = ur.id
WHERE ur.role_code = 'inventory_manager'
ORDER BY rp.module, rp.resource, rp.action;

-- Expected: See all permissions for role
```

### Check 4: Failed Login Attempts

```sql
-- View users with failed attempts
SELECT 
  username,
  failed_login_attempts,
  account_locked_until,
  last_login
FROM users
WHERE failed_login_attempts > 0
ORDER BY failed_login_attempts DESC;

-- Expected: See lockout status
```

---

## Common Issues & Solutions

### Issue 1: Token Not Refreshing

**Symptoms:**
- User logged out after 1 hour
- No refresh request in network tab

**Solution:**
```javascript
// Check apiClient.js interceptor
// Verify refreshAccessToken() is called
// Check JWT_SECRET in .env
```

### Issue 2: Permissions Not Loading

**Symptoms:**
- All permission checks return false
- localStorage.getItem('permissions') is null

**Solution:**
```javascript
// Check login response includes permissions
// Verify storePermissions() is called
// Check role_permissions table has data
```

### Issue 3: CORS Errors

**Symptoms:**
- API calls fail with CORS error
- Network tab shows preflight failed

**Solution:**
```javascript
// In backend/app.js
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:5173'],
  credentials: true
}));
```

### Issue 4: Rate Limiting Too Aggressive

**Symptoms:**
- Normal usage triggers rate limit
- 429 errors frequently

**Solution:**
```javascript
// Adjust rate limits in backend/middleware/rateLimit.js
// Increase windowMs or max values
```

---

## Testing Checklist

### Authentication
- [ ] Login with valid credentials works
- [ ] Login with invalid credentials fails
- [ ] Account lockout after 5 failed attempts
- [ ] Token refresh works automatically
- [ ] Logout clears all tokens
- [ ] Session persists across page refresh

### Authorization
- [ ] Admin can access all features
- [ ] Limited users see only permitted features
- [ ] Permission checks work in UI
- [ ] API enforces permissions
- [ ] Role changes take effect after re-login

### Session Management
- [ ] Multiple sessions supported
- [ ] Session list shows all active sessions
- [ ] Terminate session works
- [ ] Session timeout works
- [ ] Last activity tracked

### Audit Logging
- [ ] All actions logged
- [ ] Correct user_id recorded
- [ ] Correct timestamps
- [ ] Correct resource information
- [ ] Activity log filterable

### Security
- [ ] SQL injection prevented
- [ ] XSS prevented
- [ ] CSRF protected
- [ ] Token tampering detected
- [ ] Brute force protected
- [ ] Rate limiting works

### Performance
- [ ] Token refresh < 200ms
- [ ] Permission checks < 1ms
- [ ] API calls < 500ms
- [ ] Concurrent requests work
- [ ] No memory leaks

---

## Production Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Security audit complete
- [ ] Performance acceptable
- [ ] Database migrations ready
- [ ] Environment variables set
- [ ] SSL certificates installed

### Deployment
- [ ] Backup database
- [ ] Run migrations
- [ ] Deploy backend
- [ ] Deploy frontend
- [ ] Verify connectivity
- [ ] Test login flow

### Post-Deployment
- [ ] Monitor error logs
- [ ] Monitor performance
- [ ] Check audit logs
- [ ] Verify rate limiting
- [ ] Test from different devices
- [ ] User acceptance testing

---

## Monitoring & Maintenance

### Daily Checks
- [ ] Check error logs
- [ ] Review failed login attempts
- [ ] Check rate limit hits
- [ ] Monitor API response times

### Weekly Checks
- [ ] Review audit logs
- [ ] Check session counts
- [ ] Review permission usage
- [ ] Check for suspicious activity

### Monthly Checks
- [ ] Security audit
- [ ] Performance review
- [ ] Update dependencies
- [ ] Review and update permissions

---

## Summary

This testing guide covers:
✅ Frontend integration testing  
✅ End-to-end scenarios  
✅ Security audit procedures  
✅ Performance testing  
✅ Database verification  
✅ Common issues & solutions  
✅ Production deployment checklist  
✅ Monitoring & maintenance  

Follow this guide to ensure your security system is production-ready and secure.

---

**Document Version**: 1.0  
**Last Updated**: March 8, 2026  
**Status**: Ready for Testing ✅
