# Security Implementation - Quick Start Guide

## 🚀 Get Started in 5 Steps

### Step 1: Install Dependencies (5 minutes)

```bash
# Backend dependencies
cd backend
npm install jsonwebtoken bcrypt express-rate-limit

# Frontend dependencies  
cd ../frontend
npm install axios jwt-decode --legacy-peer-deps
```

### Step 2: Run Database Migrations (2 minutes)

```bash
# From project root
mysql -u root prime < backend/sql/security_and_user_management_schema.sql
mysql -u root prime < backend/sql/seed_roles_and_permissions.sql
mysql -u root prime < backend/sql/migrate_existing_users.sql
```

### Step 3: Verify Installation (1 minute)

```bash
# Check if tables were created
mysql -u root prime -e "SELECT COUNT(*) as roles FROM user_roles"
mysql -u root prime -e "SELECT COUNT(*) as permissions FROM role_permissions"
mysql -u root prime -e "SELECT COUNT(*) as users FROM users"
```

Expected output:
- roles: 16
- permissions: 100+
- users: (your existing user count)

### Step 4: Test Login (2 minutes)

The login endpoint has been updated to use JWT tokens. Test it:

```bash
curl -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"your_username","password":"your_password"}'
```

You should receive:
```json
{
  "success": true,
  "token": "Bearer eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "user": { ... }
}
```

### Step 5: Update Frontend (Next)

The frontend needs to be updated to use the new authentication system. This will be done in Week 2.

---

## 📋 What's Been Implemented

### ✅ Backend (Complete)
- JWT authentication with access & refresh tokens
- Session management in database
- Account lockout after 5 failed attempts
- Role-based permissions (RBAC)
- Activity logging (audit trail)
- Rate limiting (prevent abuse)
- 6 new database tables
- 16 default roles
- 100+ permissions

### ⏳ Frontend (Pending)
- API client with token interceptors
- Automatic token refresh
- Permission-based UI rendering
- Session management UI
- Activity log viewer

---

## 🔐 New Authentication Flow

### Old Flow (Insecure)
```
1. User logs in
2. Server returns JWT token
3. Token stored in Redux
4. No session tracking
5. No permission checks
6. No audit logging
```

### New Flow (Secure)
```
1. User logs in
2. Server validates credentials
3. Server creates session in database
4. Server returns access token + refresh token
5. Frontend stores tokens
6. Every request includes token
7. Server validates token + session
8. Server checks permissions
9. Server logs activity
10. Token auto-refreshes before expiry
```

---

## 🎯 Permission System

### How It Works

Permissions are structured as: **Module → Resource → Action**

Example:
- Module: `inventory`
- Resource: `requisitions`
- Action: `approve`

### Checking Permissions in Code

**Backend (Middleware):**
```javascript
const { checkPermission } = require('../middleware/permissions');

app.post('/inventory/requisitions/:id/approve',
  authenticate,
  checkPermission('inventory', 'requisitions', 'approve'),
  controller.approveRequisition
);
```

**Backend (Manual Check):**
```javascript
const { hasPermission } = require('../middleware/permissions');

const canApprove = await hasPermission(
  userId, 
  'inventory', 
  'requisitions', 
  'approve'
);
```

**Frontend (Coming in Week 2):**
```javascript
{hasPermission('inventory', 'requisitions', 'approve') && (
  <Button onClick={handleApprove}>Approve</Button>
)}
```

---

## 🛡️ Security Features

### 1. Account Lockout
- 5 failed login attempts = 15 minute lockout
- Automatic unlock after timeout
- Prevents brute force attacks

### 2. Session Management
- All sessions tracked in database
- Can view active sessions
- Can force logout from any device
- Sessions expire after 1 hour

### 3. Rate Limiting
- Login: 5 attempts per 15 minutes
- API: 100 requests per 15 minutes
- Write operations: 30 per 15 minutes
- Read operations: 200 per 15 minutes

### 4. Audit Trail
- Every action logged
- User, timestamp, IP address
- Request/response tracking
- Response time monitoring

### 5. Token Security
- Access token: 1 hour expiry
- Refresh token: 7 day expiry
- Tokens stored in database
- Can invalidate any token

---

## 📊 Default Roles & Permissions

### Administrative Roles
- **Administrator** - Full system access
- **Facility Manager** - Facility-wide management
- **Department Head** - Department management

### Clinical Roles
- **Doctor** - Clinical access
- **Dentist** - Dental procedures
- **Nurse** - Nursing care
- **Lab Technician** - Lab operations
- **Radiologist** - Radiology

### Inventory Roles
- **Inventory Manager** - Full inventory management
- **Store Keeper** - Stock operations
- **Requisition Approver** - Approve requests
- **Department Staff** - Create requisitions

### Financial Roles
- **Accountant** - Financial management
- **Cashier** - Payment collection
- **Billing Officer** - Invoice generation

### Front Desk
- **Receptionist** - Appointments, registration

---

## 🔧 Configuration

### Environment Variables

Create/update `backend/.env`:

```bash
# JWT Secrets (CHANGE THESE IN PRODUCTION!)
JWT_SECRET=your-super-secret-key-minimum-32-characters-long
REFRESH_TOKEN_SECRET=another-super-secret-key-for-refresh-tokens

# Token Expiry
JWT_EXPIRES_IN=1h
REFRESH_TOKEN_EXPIRES_IN=7d

# Account Lockout
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION=15

# Rate Limiting
RATE_LIMIT_WINDOW=15
RATE_LIMIT_MAX_REQUESTS=100
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
curl -X GET http://localhost:5000/users/1 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Test Token Refresh
```bash
curl -X POST http://localhost:5000/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"YOUR_REFRESH_TOKEN"}'
```

### Test Logout
```bash
curl -X POST http://localhost:5000/auth/logout \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 🐛 Troubleshooting

### "User not found or not approved"
- Check user status in database: `SELECT status FROM users WHERE username='...'`
- Status should be 'approved' or 'active'
- Fix: `UPDATE users SET status='active' WHERE username='...'`

### "Account is locked"
- User exceeded 5 failed login attempts
- Wait 15 minutes or manually unlock:
  ```sql
  UPDATE users SET failed_login_attempts=0, locked_until=NULL WHERE username='...'
  ```

### "Token expired"
- Access tokens expire after 1 hour
- Use refresh token to get new access token
- Or login again

### "Permission denied"
- User doesn't have required permission
- Check user role: `SELECT role FROM users WHERE id=...`
- Check role permissions: `SELECT * FROM role_permissions WHERE role_id=...`
- Assign permission if needed

### "Session expired or invalid"
- Session was terminated or expired
- Login again to create new session

---

## 📚 API Endpoints

### Authentication
- `POST /auth/login` - Login with username/password
- `POST /auth/logout` - Logout current session
- `POST /auth/refresh` - Refresh access token
- `GET /auth/me` - Get current user info

### Session Management
- `GET /users/:userId/sessions` - Get active sessions
- `DELETE /users/:userId/sessions/:sessionId` - Terminate session

### Activity Log
- `GET /users/:userId/activity` - Get user activity log

---

## 🎯 Next Steps (Week 2)

1. **Update Route Files** - Add authentication middleware to all routes
2. **Create Frontend API Client** - Axios with token interceptors
3. **Update Redux Actions** - Use new API client
4. **Add Permission Checks** - Hide/show UI based on permissions
5. **Create Session Manager** - View/manage active sessions
6. **Create Activity Viewer** - View audit logs

---

## 💡 Tips

1. **Always use HTTPS in production** - Tokens should never be sent over HTTP
2. **Change JWT secrets** - Use strong, random secrets in production
3. **Monitor failed logins** - Set up alerts for suspicious activity
4. **Review audit logs** - Regularly check for unusual patterns
5. **Update permissions** - Adjust as your needs change
6. **Test thoroughly** - Test all permission combinations

---

## 🆘 Need Help?

1. Check `PHASE_1_WEEK_1_COMPLETE.md` for detailed implementation info
2. Check `UNIFIED_SECURITY_IMPLEMENTATION_PLAN.md` for full plan
3. Review SQL files for database structure
4. Check middleware files for implementation details

---

**Status**: Week 1 Complete ✅  
**Next**: Week 2 - Route Protection & Frontend Integration  
**Timeline**: 8 weeks total
