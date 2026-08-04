# Security System Testing Guide

**Quick guide to test the new JWT authentication and authorization system**

---

## 🚀 Quick Start Test

### 1. Start the Application

```bash
# Terminal 1: Backend
cd backend
npm start

# Terminal 2: Frontend
cd frontend
npm run dev
```

### 2. Test Login

1. Open browser to `http://localhost:3000` (or your frontend port)
2. Should redirect to `/auth` (login page)
3. Enter credentials:
   - Username: `admin` (or your username)
   - Password: your password
4. Click "Login"
5. Should redirect to `/me` (dashboard)

### 3. Verify Token Storage

1. Open browser DevTools (F12)
2. Go to Application → Local Storage
3. Should see:
   - `accessToken`: JWT token string
   - `refreshToken`: Refresh token string
   - `user`: User object JSON
   - `permissions`: Permissions object JSON

### 4. Check Redux State

1. Install Redux DevTools extension (if not installed)
2. Open Redux DevTools
3. Check `state.newAuth`:
   ```javascript
   {
     isAuthenticated: true,
     user: { username, role, facilityId, ... },
     token: "...",
     refreshToken: "...",
     permissions: { inventory: {...}, users: {...} },
     loading: false,
     error: null
   }
   ```

---

## 🧪 Detailed Tests

### Test 1: Valid Login

**Steps**:
1. Go to login page
2. Enter valid credentials
3. Click login

**Expected**:
- Loading spinner appears
- Redirects to dashboard
- Token stored in localStorage
- User data in Redux state
- No errors shown

**Verify**:
```javascript
// In browser console
localStorage.getItem('accessToken') // Should return token
localStorage.getItem('user') // Should return user JSON
```

---

### Test 2: Invalid Login

**Steps**:
1. Go to login page
2. Enter invalid password
3. Click login

**Expected**:
- Error message appears: "Invalid credentials" or similar
- No redirect
- No token stored
- User stays on login page

---

### Test 3: Account Lockout

**Steps**:
1. Try to login with wrong password 5 times
2. Try 6th time

**Expected**:
- After 5 failed attempts: "Account locked for 15 minutes"
- Cannot login even with correct password
- Must wait 15 minutes or unlock in database

**Unlock Account** (if needed):
```sql
UPDATE users 
SET failed_login_attempts = 0, 
    account_locked_until = NULL 
WHERE username = 'your_username';
```

---

### Test 4: Token Expiry & Refresh

**Option A: Wait 1 hour**
1. Login successfully
2. Wait 1 hour
3. Try to access a protected page
4. Should auto-refresh token
5. Page loads successfully

**Option B: Manual expiry**
1. Login successfully
2. In browser console:
   ```javascript
   // Set token to expire soon
   localStorage.setItem('accessToken', 'expired_token');
   ```
3. Refresh page or navigate
4. Should redirect to login

---

### Test 5: Logout

**Steps**:
1. Login successfully
2. Click logout (or call logout action)
3. Check localStorage

**Expected**:
- Redirects to `/auth`
- All tokens cleared from localStorage
- Redux state reset
- Cannot access protected pages

**Verify**:
```javascript
// In browser console
localStorage.getItem('accessToken') // Should be null
localStorage.getItem('user') // Should be null
```

---

### Test 6: Session Persistence

**Steps**:
1. Login successfully
2. Refresh the page (F5)
3. Check if still logged in

**Expected**:
- User stays logged in
- Dashboard loads
- No redirect to login
- Token still valid

---

### Test 7: Protected API Endpoint

**Steps**:
1. Login successfully
2. Open browser console
3. Try to fetch protected endpoint:
   ```javascript
   fetch('http://localhost:5000/inventory/items', {
     headers: {
       'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
     }
   })
   .then(r => r.json())
   .then(console.log)
   ```

**Expected**:
- Returns data if user has permission
- Returns 403 if no permission
- Returns 401 if token invalid

---

### Test 8: Permission Checks

**Steps**:
1. Login as admin
2. Navigate to inventory
3. Check if all buttons visible

**Expected**:
- Admin sees all buttons (Create, Edit, Delete, Approve)
- Regular user sees limited buttons
- Buttons hidden based on permissions

**Test Different Roles**:
```sql
-- Create test users with different roles
INSERT INTO users (username, password, role, facilityId) 
VALUES 
  ('store_keeper', '$2b$10$...', 'store_keeper', 1),
  ('inventory_manager', '$2b$10$...', 'inventory_manager', 1);
```

---

### Test 9: Rate Limiting

**Steps**:
1. Try to login 6 times quickly (within 15 minutes)
2. Check response

**Expected**:
- First 5 attempts: Normal response
- 6th attempt: "Too many requests, please try again later"
- Status code: 429

**Test API Rate Limit**:
```javascript
// In browser console
for (let i = 0; i < 101; i++) {
  fetch('http://localhost:5000/inventory/items', {
    headers: {
      'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
    }
  }).then(r => console.log(i, r.status));
}
```

**Expected**:
- First 100 requests: 200 OK
- 101st request: 429 Too Many Requests

---

### Test 10: Audit Logging

**Steps**:
1. Login successfully
2. Perform some actions (create item, update, delete)
3. Check database

**Verify**:
```sql
-- Check activity log
SELECT * FROM user_activity_log 
WHERE user_id = YOUR_USER_ID 
ORDER BY created_at DESC 
LIMIT 10;

-- Should see entries for:
-- - login
-- - create_item
-- - update_item
-- - delete_item
```

---

### Test 11: Session Management

**Steps**:
1. Login from browser
2. Check database for active session

**Verify**:
```sql
-- View active sessions
SELECT 
  us.id,
  u.username,
  us.ip_address,
  us.user_agent,
  us.created_at,
  us.last_activity
FROM user_sessions us
JOIN users u ON us.user_id = u.id
WHERE us.is_active = TRUE;
```

**Expected**:
- One active session for your user
- IP address matches your IP
- User agent matches your browser

---

### Test 12: Multiple Sessions

**Steps**:
1. Login from Chrome
2. Login from Firefox (same user)
3. Check database

**Expected**:
- Two active sessions in database
- Both sessions work independently
- Logout from one doesn't affect the other

---

## 🔍 Database Verification

### Check User Permissions

```sql
-- View user's role and permissions
SELECT 
  u.username,
  ur.role_name,
  rp.module,
  rp.resource,
  rp.action
FROM users u
JOIN user_roles ur ON u.role = ur.role_code
JOIN role_permissions rp ON ur.id = rp.role_id
WHERE u.username = 'admin'
ORDER BY rp.module, rp.resource, rp.action;
```

### Check Failed Login Attempts

```sql
-- View failed login attempts
SELECT 
  username,
  failed_login_attempts,
  account_locked_until,
  last_login
FROM users
WHERE failed_login_attempts > 0;
```

### Check Active Sessions

```sql
-- View all active sessions
SELECT 
  u.username,
  us.ip_address,
  us.created_at,
  us.last_activity,
  TIMESTAMPDIFF(MINUTE, us.last_activity, NOW()) as minutes_idle
FROM user_sessions us
JOIN users u ON us.user_id = u.id
WHERE us.is_active = TRUE;
```

### Check Recent Activity

```sql
-- View recent user activity
SELECT 
  u.username,
  ual.action,
  ual.resource,
  ual.details,
  ual.created_at
FROM user_activity_log ual
JOIN users u ON ual.user_id = u.id
ORDER BY ual.created_at DESC
LIMIT 20;
```

---

## 🐛 Common Issues & Solutions

### Issue: Cannot login, no error shown

**Check**:
1. Backend server running?
2. Database connection working?
3. Check browser console for errors
4. Check backend logs

**Solution**:
```bash
# Check backend logs
cd backend
npm start
# Look for errors in console
```

---

### Issue: "Token expired" immediately

**Check**:
```bash
# Verify JWT_SECRET in backend/.env
cat backend/.env | grep JWT_SECRET
```

**Solution**:
```bash
# Set JWT_SECRET if missing
echo "JWT_SECRET=your-super-secret-key-change-this" >> backend/.env
echo "JWT_EXPIRES_IN=1h" >> backend/.env
echo "JWT_REFRESH_EXPIRES_IN=7d" >> backend/.env
```

---

### Issue: "Permission denied" for admin

**Check**:
```sql
-- Verify admin role
SELECT u.username, u.role, ur.role_name 
FROM users u 
LEFT JOIN user_roles ur ON u.role = ur.role_code 
WHERE u.username = 'admin';
```

**Solution**:
```sql
-- Update user role to admin
UPDATE users SET role = 'admin' WHERE username = 'admin';
```

---

### Issue: CORS errors

**Check**: Browser console shows CORS error

**Solution**:
```javascript
// In backend/app.js
const corsOptions = {
  origin: ['http://localhost:3000', 'http://localhost:5173'],
  credentials: true
};
app.use(cors(corsOptions));
```

---

### Issue: Rate limit triggered too easily

**Solution**:
```javascript
// In backend/middleware/rateLimit.js
// Increase limits for development
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10, // Increase from 5 to 10
  // ...
});
```

---

## ✅ Test Checklist

### Authentication
- [ ] Login with valid credentials
- [ ] Login with invalid credentials
- [ ] Login with locked account
- [ ] Logout
- [ ] Token refresh
- [ ] Session persistence

### Authorization
- [ ] Access with permission
- [ ] Access without permission (403)
- [ ] Admin can access everything
- [ ] Different roles see different features

### Security
- [ ] Rate limiting works
- [ ] Account lockout works
- [ ] Audit logging works
- [ ] Session tracking works
- [ ] Token expiry works

### UI
- [ ] Login form works
- [ ] Error messages show
- [ ] Loading states work
- [ ] Redirects work
- [ ] Permission-based buttons show/hide

---

## 📊 Performance Tests

### Test Token Refresh Performance

```javascript
// In browser console
console.time('token-refresh');
fetch('http://localhost:5000/auth/refresh', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ 
    refreshToken: localStorage.getItem('refreshToken') 
  })
})
.then(r => r.json())
.then(data => {
  console.timeEnd('token-refresh');
  console.log('New token:', data.token);
});
```

**Expected**: < 100ms

---

### Test API Response Time

```javascript
// In browser console
console.time('api-call');
fetch('http://localhost:5000/inventory/items', {
  headers: {
    'Authorization': `Bearer ${localStorage.getItem('accessToken')}`
  }
})
.then(r => r.json())
.then(data => {
  console.timeEnd('api-call');
  console.log('Items:', data.results.length);
});
```

**Expected**: < 500ms

---

## 🎯 Success Criteria

All tests should pass:
- ✅ Login works with valid credentials
- ✅ Login fails with invalid credentials
- ✅ Account locks after 5 failed attempts
- ✅ Token refresh works automatically
- ✅ Logout clears all data
- ✅ Session persists on page refresh
- ✅ Protected endpoints require token
- ✅ Permission checks work correctly
- ✅ Rate limiting prevents abuse
- ✅ Audit logging tracks all actions

---

## 📞 Need Help?

If any test fails:
1. Check backend logs
2. Check browser console
3. Check database tables
4. Review documentation
5. Check this guide's troubleshooting section

---

**Document Version**: 1.0  
**Last Updated**: March 8, 2026  
**Status**: Ready for Testing
