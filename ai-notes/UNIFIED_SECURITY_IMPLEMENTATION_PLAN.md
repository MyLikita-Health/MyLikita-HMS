# Unified Security & User Management Implementation Plan

## Executive Summary

This plan combines the **User Management System Modernization** and **API Security & Authentication Framework** into a single, cohesive implementation that will:

1. Secure all API endpoints with JWT authentication
2. Implement Role-Based Access Control (RBAC)
3. Modernize user management interface
4. Provide complete audit trail
5. Work for all modules (existing and future)

**Timeline:** 8 weeks  
**Priority:** CRITICAL  
**Risk Level:** High (unprotected APIs)

---

## Implementation Overview

```
┌─────────────────────────────────────────────────────────────┐
│              UNIFIED IMPLEMENTATION PHASES                   │
└─────────────────────────────────────────────────────────────┘

Week 1-2: Foundation (Database + Core Security)
Week 3-4: Authentication & Authorization
Week 5-6: User Management UI + Role Management
Week 7: Integration & Testing
Week 8: Deployment & Training
```

---

## Phase 1: Foundation & Database (Week 1-2)

### Week 1: Database Schema & Quick Wins

#### Day 1-2: Database Schema Creation
**Priority:** CRITICAL

**Tasks:**
- [ ] Create database migration script
- [ ] Add new security tables
- [ ] Add user management tables
- [ ] Test migrations on dev environment

**Deliverables:**
- `backend/sql/security_and_user_management_schema.sql`

**Tables to Create:**
1. `user_roles` (enhanced)
2. `role_permissions`
3. `user_departments`
4. `user_activity_log`
5. `user_sessions`
6. `password_history`
7. `permission_modules`
8. `permission_resources`

#### Day 3-4: Quick Wins Implementation
**Priority:** HIGH

**Tasks:**
- [ ] Fix user status values (remove trailing spaces)
- [ ] Add department_id to users table
- [ ] Create default roles and permissions
- [ ] Seed permission data

**SQL Scripts:**
```sql
-- Fix status values
UPDATE users SET status = TRIM(status);
ALTER TABLE users MODIFY status ENUM('active', 'pending', 'suspended', 'locked') DEFAULT 'pending';

-- Add department
ALTER TABLE users ADD COLUMN department_id INT;
ALTER TABLE users ADD FOREIGN KEY (department_id) REFERENCES departments(id);
```

#### Day 5: Install Dependencies
**Priority:** CRITICAL

**Backend Dependencies:**
```bash
cd backend
npm install jsonwebtoken bcrypt express-rate-limit redis rate-limit-redis
```

**Frontend Dependencies:**
```bash
cd frontend
npm install axios jwt-decode
```

### Week 2: Core Middleware Development

#### Day 1-2: Authentication Middleware
**Priority:** CRITICAL

**Tasks:**
- [ ] Create `backend/middleware/authenticate.js`
- [ ] Implement JWT token generation
- [ ] Implement JWT token validation
- [ ] Implement refresh token logic
- [ ] Create session management functions

**Files to Create:**
- `backend/middleware/authenticate.js`
- `backend/utils/tokenManager.js`

#### Day 3: Permission Middleware
**Priority:** CRITICAL

**Tasks:**
- [ ] Create `backend/middleware/permissions.js`
- [ ] Implement `checkPermission()` function
- [ ] Implement `checkAnyPermission()` function
- [ ] Implement `requireRole()` function
- [ ] Implement `requireFacility()` function

**Files to Create:**
- `backend/middleware/permissions.js`

#### Day 4: Supporting Middleware
**Priority:** HIGH

**Tasks:**
- [ ] Create `backend/middleware/rateLimit.js`
- [ ] Create `backend/middleware/auditLog.js`
- [ ] Create `backend/middleware/errorHandler.js`
- [ ] Create `backend/middleware/validation.js`

#### Day 5: Testing & Documentation
**Priority:** HIGH

**Tasks:**
- [ ] Unit test all middleware
- [ ] Create middleware documentation
- [ ] Test token generation/validation
- [ ] Test permission checks

---

## Phase 2: Authentication & Authorization (Week 3-4)

### Week 3: Authentication Implementation

#### Day 1-2: Auth Controller & Routes
**Priority:** CRITICAL

**Tasks:**
- [ ] Update `backend/controller/auth.js`
- [ ] Implement login with JWT
- [ ] Implement logout
- [ ] Implement token refresh
- [ ] Implement password change

**Endpoints to Create/Update:**
- `POST /auth/login` - Login with JWT
- `POST /auth/logout` - Logout and invalidate session
- `POST /auth/refresh` - Refresh access token
- `POST /auth/change-password` - Change password
- `GET /auth/me` - Get current user info

#### Day 3: Frontend API Client
**Priority:** CRITICAL

**Tasks:**
- [ ] Create `frontend/src/utils/apiClient.js`
- [ ] Implement axios interceptors
- [ ] Implement token storage (memory)
- [ ] Implement automatic token refresh
- [ ] Update all API action files

**Files to Create/Update:**
- `frontend/src/utils/apiClient.js`
- `frontend/src/redux/actions/inventory-api.js`
- `frontend/src/redux/actions/api.js`

#### Day 4-5: Protect Critical Routes
**Priority:** CRITICAL

**Tasks:**
- [ ] Protect inventory routes
- [ ] Protect user management routes
- [ ] Protect financial/billing routes
- [ ] Protect dental routes
- [ ] Test protected routes

**Pattern to Apply:**
```javascript
app.use('/inventory', authenticate);
app.use('/inventory', requireFacility);
app.use('/inventory', apiLimiter);
```

### Week 4: Permission System Implementation

#### Day 1-2: Permission Seeding
**Priority:** HIGH

**Tasks:**
- [ ] Create default roles
- [ ] Create permission matrix
- [ ] Seed permissions for inventory module
- [ ] Seed permissions for user management
- [ ] Seed permissions for other modules

**Script to Create:**
- `backend/sql/seed_roles_and_permissions.sql`

**Default Roles:**
- Administrator
- Facility Manager
- Inventory Manager
- Store Keeper
- Department Staff
- Doctor
- Nurse
- Accountant
- Cashier

#### Day 3-4: Apply Permission Checks
**Priority:** HIGH

**Tasks:**
- [ ] Add permission checks to inventory routes
- [ ] Add permission checks to requisition routes
- [ ] Add permission checks to user routes
- [ ] Add permission checks to financial routes

**Example:**
```javascript
app.post('/inventory/requisitions/:id/approve',
  authenticate,
  checkPermission('inventory', 'requisitions', 'approve'),
  approveRequisition
);
```

#### Day 5: Permission Testing
**Priority:** HIGH

**Tasks:**
- [ ] Test permission checks
- [ ] Test unauthorized access
- [ ] Test role-based access
- [ ] Document permission matrix

---

## Phase 3: User Management UI (Week 5-6)

### Week 5: Role Management Interface

#### Day 1-2: Role Management Backend
**Priority:** HIGH

**Tasks:**
- [ ] Create `backend/controller/roles.js`
- [ ] Implement CRUD for roles
- [ ] Implement permission assignment
- [ ] Create role cloning function

**Endpoints:**
- `GET /roles` - List all roles
- `POST /roles` - Create role
- `PUT /roles/:id` - Update role
- `DELETE /roles/:id` - Delete role
- `GET /roles/:id/permissions` - Get role permissions
- `PUT /roles/:id/permissions` - Update role permissions
- `POST /roles/:id/clone` - Clone role

#### Day 3-5: Role Management UI
**Priority:** HIGH

**Tasks:**
- [ ] Create `RoleManagement.jsx`
- [ ] Create `RoleForm.jsx`
- [ ] Create `PermissionMatrix.jsx`
- [ ] Add to admin navigation

**Components:**
- Role list with search/filter
- Role creation/edit form
- Permission matrix (checkboxes)
- Role assignment interface

### Week 6: Enhanced User Management

#### Day 1-2: User Management Backend
**Priority:** HIGH

**Tasks:**
- [ ] Update `backend/controller/users.js`
- [ ] Add department assignment
- [ ] Add permission loading
- [ ] Add activity log endpoints
- [ ] Add session management endpoints

**New Endpoints:**
- `GET /users/:id/permissions` - Get user permissions
- `GET /users/:id/activity` - Get user activity log
- `GET /users/:id/sessions` - Get active sessions
- `DELETE /users/:id/sessions/:sessionId` - Force logout
- `PUT /users/:id/department` - Assign department

#### Day 3-5: Enhanced User Management UI
**Priority:** HIGH

**Tasks:**
- [ ] Update `Users.jsx` component
- [ ] Update `NewUser.jsx` form
- [ ] Create `UserProfile.jsx`
- [ ] Create `ActiveSessions.jsx`
- [ ] Create `ActivityLog.jsx`

**Features:**
- Enhanced user list with filters
- Department assignment
- Role assignment with permission preview
- Bulk operations
- Activity log viewer
- Session management

---

## Phase 4: Integration & Testing (Week 7)

### Day 1-2: Frontend Integration
**Priority:** CRITICAL

**Tasks:**
- [ ] Update login flow
- [ ] Update all API calls to use new client
- [ ] Add permission checks in UI
- [ ] Test token refresh
- [ ] Handle authentication errors

**UI Permission Checks:**
```javascript
{hasPermission('inventory', 'requisitions', 'approve') && (
  <Button onClick={handleApprove}>Approve</Button>
)}
```

### Day 3-4: End-to-End Testing
**Priority:** CRITICAL

**Test Scenarios:**
1. Login/Logout flow
2. Token refresh
3. Permission-based access
4. Role changes
5. Session management
6. Audit logging
7. Rate limiting
8. Error handling

### Day 5: Security Audit
**Priority:** CRITICAL

**Tasks:**
- [ ] Review all protected routes
- [ ] Test unauthorized access attempts
- [ ] Verify audit logging
- [ ] Check for security vulnerabilities
- [ ] Performance testing

---

## Phase 5: Deployment & Training (Week 8)

### Day 1-2: Production Preparation
**Priority:** CRITICAL

**Tasks:**
- [ ] Create production migration scripts
- [ ] Set up environment variables
- [ ] Configure Redis (if using)
- [ ] Set up SSL certificates
- [ ] Create backup procedures

### Day 3: Deployment
**Priority:** CRITICAL

**Tasks:**
- [ ] Run database migrations
- [ ] Deploy backend changes
- [ ] Deploy frontend changes
- [ ] Verify all systems operational
- [ ] Monitor for errors

### Day 4-5: Training & Documentation
**Priority:** HIGH

**Tasks:**
- [ ] Create user documentation
- [ ] Create admin documentation
- [ ] Train administrators
- [ ] Train department heads
- [ ] Create video tutorials

---

## Detailed Task Breakdown

### Database Migration Script

**File:** `backend/sql/security_and_user_management_schema.sql`


```sql
-- Enhanced user_roles table
CREATE TABLE IF NOT EXISTS user_roles (
  id INT PRIMARY KEY AUTO_INCREMENT,
  role_name VARCHAR(50) UNIQUE NOT NULL,
  role_code VARCHAR(20) UNIQUE NOT NULL,
  description TEXT,
  is_system_role BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_role_code (role_code),
  INDEX idx_active (is_active)
);

-- Role permissions table
CREATE TABLE IF NOT EXISTS role_permissions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  role_id INT NOT NULL,
  module VARCHAR(50) NOT NULL,
  resource VARCHAR(50) NOT NULL,
  action VARCHAR(20) NOT NULL,
  granted BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (role_id) REFERENCES user_roles(id) ON DELETE CASCADE,
  UNIQUE KEY unique_permission (role_id, module, resource, action),
  INDEX idx_role_module (role_id, module),
  INDEX idx_module_resource (module, resource)
);

-- User departments (many-to-many)
CREATE TABLE IF NOT EXISTS user_departments (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  department_id INT NOT NULL,
  is_primary BOOLEAN DEFAULT FALSE,
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  assigned_by INT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (assigned_by) REFERENCES users(id),
  UNIQUE KEY unique_user_dept (user_id, department_id),
  INDEX idx_user (user_id),
  INDEX idx_department (department_id)
);

-- User activity log
CREATE TABLE IF NOT EXISTS user_activity_log (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT,
  action VARCHAR(100) NOT NULL,
  module VARCHAR(50),
  resource_type VARCHAR(50),
  resource_id INT,
  request_method VARCHAR(10),
  request_path VARCHAR(255),
  response_status INT,
  response_time INT,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_user_action (user_id, created_at),
  INDEX idx_module (module, created_at),
  INDEX idx_action (action, created_at)
);

-- User sessions
CREATE TABLE IF NOT EXISTS user_sessions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  session_token VARCHAR(500) NOT NULL,
  refresh_token VARCHAR(500),
  ip_address VARCHAR(45),
  user_agent TEXT,
  last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_token (session_token(255)),
  INDEX idx_user_active (user_id, is_active),
  INDEX idx_expires (expires_at)
);

-- Password history
CREATE TABLE IF NOT EXISTS password_history (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  changed_by INT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (changed_by) REFERENCES users(id),
  INDEX idx_user (user_id, changed_at)
);

-- Fix existing users table
ALTER TABLE users MODIFY status ENUM('active', 'pending', 'suspended', 'locked') DEFAULT 'pending';
UPDATE users SET status = TRIM(status);
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS failed_login_attempts INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS locked_until TIMESTAMP NULL;
```

---

## Permission Matrix Template

### Inventory Module Permissions

| Resource | View | Create | Edit | Delete | Approve | Issue | Export |
|----------|------|--------|------|--------|---------|-------|--------|
| Items | ✓ | ✓ | ✓ | Admin | - | - | ✓ |
| Stock | ✓ | - | - | - | - | - | ✓ |
| Requisitions | ✓ | ✓ | - | - | Manager | Keeper | ✓ |
| Purchase Orders | ✓ | Manager | Manager | - | Manager | - | ✓ |
| GRN | ✓ | Keeper | Keeper | - | Manager | - | ✓ |
| Suppliers | ✓ | Manager | Manager | Admin | - | - | ✓ |
| Reports | ✓ | - | - | - | - | - | ✓ |

**Legend:**
- ✓ = All roles
- Manager = Inventory Manager only
- Keeper = Store Keeper only
- Admin = Administrator only

---

## File Structure

```
backend/
├── middleware/
│   ├── authenticate.js          ✅ NEW
│   ├── permissions.js           ✅ NEW
│   ├── rateLimit.js            ✅ NEW
│   ├── auditLog.js             ✅ NEW
│   ├── errorHandler.js         ✅ NEW
│   └── validation.js           ✅ NEW
├── controller/
│   ├── auth.js                 🔄 UPDATE
│   ├── users.js                🔄 UPDATE
│   ├── roles.js                ✅ NEW
│   └── permissions.js          ✅ NEW
├── routes/
│   ├── auth.js                 🔄 UPDATE
│   ├── users.js                🔄 UPDATE
│   ├── roles.js                ✅ NEW
│   ├── inventory.js            🔄 UPDATE (add middleware)
│   └── [all other routes]      🔄 UPDATE (add middleware)
├── sql/
│   ├── security_and_user_management_schema.sql  ✅ NEW
│   ├── seed_roles_and_permissions.sql           ✅ NEW
│   └── migrate_existing_users.sql               ✅ NEW
└── utils/
    ├── tokenManager.js         ✅ NEW
    └── permissionHelper.js     ✅ NEW

frontend/
├── utils/
│   ├── apiClient.js            ✅ NEW
│   └── permissionHelper.js     ✅ NEW
├── components/
│   ├── admin/
│   │   ├── Users.jsx           🔄 UPDATE
│   │   ├── NewUser.jsx         🔄 UPDATE
│   │   ├── UserProfile.jsx     ✅ NEW
│   │   ├── RoleManagement.jsx  ✅ NEW
│   │   ├── RoleForm.jsx        ✅ NEW
│   │   ├── PermissionMatrix.jsx ✅ NEW
│   │   ├── ActiveSessions.jsx  ✅ NEW
│   │   └── ActivityLog.jsx     ✅ NEW
│   └── auth/
│       └── Login.jsx           🔄 UPDATE
└── redux/
    └── actions/
        ├── api.js              🔄 UPDATE
        └── auth.js             🔄 UPDATE
```

---

## Environment Variables

**File:** `backend/.env`

```bash
# JWT Configuration
JWT_SECRET=your-super-secret-key-minimum-32-characters-long
JWT_EXPIRES_IN=1h
REFRESH_TOKEN_SECRET=another-super-secret-key-for-refresh-tokens
REFRESH_TOKEN_EXPIRES_IN=7d

# Session Configuration
SESSION_TIMEOUT=30m
MAX_CONCURRENT_SESSIONS=3

# Password Policy
PASSWORD_MIN_LENGTH=8
PASSWORD_REQUIRE_UPPERCASE=true
PASSWORD_REQUIRE_LOWERCASE=true
PASSWORD_REQUIRE_NUMBER=true
PASSWORD_REQUIRE_SPECIAL=true
PASSWORD_EXPIRY_DAYS=90
PASSWORD_HISTORY_COUNT=5

# Account Lockout
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION=15m

# Rate Limiting
RATE_LIMIT_WINDOW=15m
RATE_LIMIT_MAX_REQUESTS=100
RATE_LIMIT_LOGIN_MAX=5

# Redis (optional)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Security
NODE_ENV=production
CORS_ORIGIN=https://yourdomain.com
ALLOWED_IPS=

# Audit
AUDIT_LOG_RETENTION_DAYS=365
```

---

## Testing Checklist

### Authentication Tests
- [ ] Login with valid credentials
- [ ] Login with invalid credentials
- [ ] Login with locked account
- [ ] Token expiration handling
- [ ] Token refresh flow
- [ ] Logout functionality
- [ ] Concurrent session handling
- [ ] Password change
- [ ] Failed login attempts tracking

### Authorization Tests
- [ ] Access with valid permission
- [ ] Access without permission (403)
- [ ] Access without authentication (401)
- [ ] Role-based access
- [ ] Facility-based access
- [ ] Permission inheritance
- [ ] Role change effects

### User Management Tests
- [ ] Create user
- [ ] Update user
- [ ] Delete user
- [ ] Assign role
- [ ] Assign department
- [ ] View user activity
- [ ] Manage sessions
- [ ] Bulk operations

### Security Tests
- [ ] SQL injection attempts
- [ ] XSS attempts
- [ ] CSRF protection
- [ ] Rate limiting
- [ ] Brute force protection
- [ ] Token tampering
- [ ] Session hijacking

---

## Rollback Plan

### If Issues Arise

**Phase 1 Rollback:**
```sql
-- Drop new tables
DROP TABLE IF EXISTS password_history;
DROP TABLE IF EXISTS user_sessions;
DROP TABLE IF EXISTS user_activity_log;
DROP TABLE IF EXISTS user_departments;
DROP TABLE IF EXISTS role_permissions;
DROP TABLE IF EXISTS user_roles;

-- Restore users table
ALTER TABLE users MODIFY status VARCHAR(20);
```

**Phase 2-3 Rollback:**
- Remove middleware from routes
- Revert to old authentication
- Keep database changes for future retry

**Phase 4-5 Rollback:**
- Revert frontend changes
- Keep backend changes
- Gradual re-deployment

---

## Success Metrics

### Week 2
- ✅ All middleware created and tested
- ✅ Database schema deployed
- ✅ Dependencies installed

### Week 4
- ✅ All critical routes protected
- ✅ Permission system functional
- ✅ Token refresh working

### Week 6
- ✅ User management UI complete
- ✅ Role management functional
- ✅ Activity logging working

### Week 8
- ✅ System deployed to production
- ✅ All users trained
- ✅ Documentation complete
- ✅ Zero security incidents

---

## Risk Mitigation

### High Risks

**Risk 1: Breaking Existing Functionality**
- **Mitigation:** Phased rollout, extensive testing
- **Contingency:** Rollback plan ready

**Risk 2: User Resistance**
- **Mitigation:** Training, documentation, support
- **Contingency:** Extended support period

**Risk 3: Performance Impact**
- **Mitigation:** Optimize middleware, use Redis
- **Contingency:** Scale infrastructure

**Risk 4: Data Migration Issues**
- **Mitigation:** Test on staging, backup data
- **Contingency:** Restore from backup

---

## Communication Plan

### Stakeholders
- Executive Management
- IT Team
- Department Heads
- End Users

### Communication Schedule

**Week 1:** Kickoff meeting, share plan  
**Week 2:** Progress update, demo middleware  
**Week 4:** Mid-point review, demo authentication  
**Week 6:** User preview, gather feedback  
**Week 7:** Final testing, user acceptance  
**Week 8:** Go-live announcement, training sessions

---

## Post-Implementation

### Week 9-10: Monitoring & Support
- Monitor system performance
- Track security incidents
- Gather user feedback
- Fix any issues
- Optimize as needed

### Week 11-12: Optimization
- Review audit logs
- Optimize slow queries
- Improve UI based on feedback
- Add requested features
- Update documentation

---

## Budget Estimate

### Development Time
- Backend Development: 120 hours
- Frontend Development: 80 hours
- Testing: 40 hours
- Documentation: 20 hours
- Training: 20 hours
**Total:** 280 hours

### Infrastructure
- Redis server (optional): $20/month
- SSL certificates: $100/year
- Backup storage: $50/month

### Training
- Video production: 20 hours
- Training sessions: 10 hours
- Documentation: 10 hours

---

## Conclusion

This unified implementation plan provides:

✅ **Complete Security** - All APIs protected  
✅ **Modern User Management** - RBAC with granular permissions  
✅ **Audit Trail** - Complete activity logging  
✅ **Scalability** - Works for all modules  
✅ **Future-Proof** - Easy to extend  
✅ **Professional** - Industry-standard practices

**Next Step:** Review and approve this plan, then begin Phase 1 immediately.

---

**Document Version:** 1.0  
**Date:** March 8, 2026  
**Status:** Ready for Implementation  
**Estimated Completion:** 8 weeks from start date
