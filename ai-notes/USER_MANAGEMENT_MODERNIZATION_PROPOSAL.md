# User Management System - Modernization Proposal

## Executive Summary

Based on the review of your current user administration system and the recent inventory/requisition workflows implemented, this document proposes a comprehensive modernization of user management to enforce privileges, improve control, and enhance usability.

---

## Current System Analysis

### Strengths ✅
- Basic user CRUD operations
- Role-based access
- User status management (approved, pending, suspended)
- Search functionality
- Module access control

### Weaknesses ❌
- **No Role-Based Permissions (RBAC)** - Roles exist but permissions are not granular
- **Module Access is Binary** - Users either have full access or no access to modules
- **No Department/Location Assignment** - Users not tied to specific departments
- **No Permission Inheritance** - No role templates or permission sets
- **Limited Audit Trail** - No tracking of who changed what
- **No Session Management** - Can't see active users or force logout
- **Inconsistent Status** - Status values have trailing spaces ('approved ', 'suspended ')
- **No Bulk Operations** - Can't manage multiple users at once
- **No Self-Service** - Users can't update their own profiles
- **No Password Policy** - No enforcement of strong passwords

---

## Proposed Modern User Management System

### Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   USER MANAGEMENT SYSTEM                 │
└─────────────────────────────────────────────────────────┘

┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│    USERS     │───▶│    ROLES     │───▶│ PERMISSIONS  │
└──────────────┘    └──────────────┘    └──────────────┘
       │                    │                    │
       │                    │                    │
       ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ DEPARTMENTS  │    │  FACILITIES  │    │   MODULES    │
└──────────────┘    └──────────────┘    └──────────────┘
```

---

## 1. Role-Based Access Control (RBAC)

### Predefined Roles

#### Clinical Roles
- **Doctor** - Full clinical access, can prescribe, diagnose
- **Nurse** - Patient care, vital signs, medication administration
- **Dentist** - Dental module access, treatment planning
- **Lab Technician** - Laboratory module, test results
- **Radiologist** - Radiology module, imaging reports

#### Administrative Roles
- **Administrator** - Full system access
- **Facility Manager** - Facility-wide management
- **Department Head** - Department-specific management
- **Receptionist** - Front desk, appointments, registration

#### Inventory Roles
- **Inventory Manager** - Full inventory access, approvals
- **Store Keeper** - Stock management, issuing
- **Requisition Approver** - Can approve requisitions
- **Department Staff** - Can create requisitions only

#### Financial Roles
- **Accountant** - Financial reports, billing oversight
- **Cashier** - Payment collection, receipts
- **Billing Officer** - Invoice generation, billing

### Permission Structure

```javascript
{
  module: "inventory",
  permissions: {
    items: {
      view: true,
      create: true,
      edit: true,
      delete: false
    },
    requisitions: {
      view: true,
      create: true,
      approve: false,  // Only Inventory Manager
      issue: false     // Only Store Keeper
    },
    purchaseOrders: {
      view: true,
      create: false,
      approve: false
    },
    reports: {
      view: true,
      export: false
    }
  }
}
```

---

## 2. Database Schema Enhancement

### New Tables

#### user_roles (Enhanced)
```sql
CREATE TABLE user_roles (
  id INT PRIMARY KEY AUTO_INCREMENT,
  role_name VARCHAR(50) UNIQUE NOT NULL,
  role_code VARCHAR(20) UNIQUE NOT NULL,
  description TEXT,
  is_system_role BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### role_permissions
```sql
CREATE TABLE role_permissions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  role_id INT NOT NULL,
  module VARCHAR(50) NOT NULL,
  resource VARCHAR(50) NOT NULL,
  action VARCHAR(20) NOT NULL, -- view, create, edit, delete, approve, etc.
  granted BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (role_id) REFERENCES user_roles(id),
  UNIQUE KEY unique_permission (role_id, module, resource, action)
);
```

#### user_departments
```sql
CREATE TABLE user_departments (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  department_id INT NOT NULL,
  is_primary BOOLEAN DEFAULT FALSE,
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  assigned_by INT,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (assigned_by) REFERENCES users(id)
);
```

#### user_activity_log
```sql
CREATE TABLE user_activity_log (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  action VARCHAR(100) NOT NULL,
  module VARCHAR(50),
  resource_type VARCHAR(50),
  resource_id INT,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_user_action (user_id, created_at),
  INDEX idx_module (module, created_at)
);
```

#### user_sessions
```sql
CREATE TABLE user_sessions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  session_token VARCHAR(255) UNIQUE NOT NULL,
  ip_address VARCHAR(45),
  user_agent TEXT,
  last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_token (session_token),
  INDEX idx_user_active (user_id, is_active)
);
```

#### password_history
```sql
CREATE TABLE password_history (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  changed_by INT,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (changed_by) REFERENCES users(id)
);
```

---

## 3. Modern UI Components

### 3.1 User Management Dashboard

**Features:**
- User list with advanced filtering
- Role-based color coding
- Status indicators
- Quick actions menu
- Bulk operations
- Export functionality

**Filters:**
- Role
- Department
- Status (Active, Pending, Suspended, Locked)
- Facility
- Last login date

### 3.2 User Creation/Edit Form

**Sections:**

**Personal Information**
- First Name, Last Name
- Email, Phone
- Profile Photo Upload
- Employee ID

**Account Information**
- Username (with availability check)
- Password (with strength meter)
- Role (dropdown with descriptions)
- Status

**Access Control**
- Primary Department
- Additional Departments
- Facility Assignment
- Module Access (checkboxes with permissions)

**Settings**
- Email Notifications
- SMS Alerts
- Two-Factor Authentication
- Session Timeout

### 3.3 Role Management Interface

**Features:**
- Create/Edit Roles
- Clone existing roles
- Permission matrix view
- Role assignment history
- User count per role

**Permission Matrix:**
```
Module          | View | Create | Edit | Delete | Approve | Export
----------------|------|--------|------|--------|---------|--------
Inventory       |  ✓   |   ✓    |  ✓   |   ✗    |    ✗    |   ✓
Requisitions    |  ✓   |   ✓    |  ✗   |   ✗    |    ✗    |   ✗
Purchase Orders |  ✓   |   ✗    |  ✗   |   ✗    |    ✗    |   ✗
```

### 3.4 User Profile Page

**Self-Service Features:**
- View own profile
- Update contact information
- Change password
- View activity log
- Manage notifications
- View assigned permissions

### 3.5 Active Sessions Management

**Features:**
- See all active sessions
- View login location and device
- Force logout specific sessions
- Set session timeout
- Monitor concurrent logins

---

## 4. Permission System Implementation

### Permission Check Function

```javascript
// Frontend
const hasPermission = (module, resource, action) => {
  const user = useSelector(state => state.auth.user);
  const permissions = user.permissions || {};
  
  return permissions[module]?.[resource]?.[action] === true;
};

// Usage
{hasPermission('inventory', 'requisitions', 'approve') && (
  <Button onClick={handleApprove}>Approve</Button>
)}
```

### Backend Middleware

```javascript
// backend/middleware/permissions.js
const checkPermission = (module, resource, action) => {
  return async (req, res, next) => {
    const userId = req.user.id;
    
    const hasAccess = await checkUserPermission(
      userId, 
      module, 
      resource, 
      action
    );
    
    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions'
      });
    }
    
    next();
  };
};

// Usage
router.post(
  '/inventory/requisitions/:id/approve',
  authenticate,
  checkPermission('inventory', 'requisitions', 'approve'),
  approveRequisition
);
```

---

## 5. Security Enhancements

### Password Policy
- Minimum 8 characters
- Must contain uppercase, lowercase, number, special character
- Cannot reuse last 5 passwords
- Expires every 90 days
- Account locks after 5 failed attempts

### Two-Factor Authentication (2FA)
- SMS-based OTP
- Email-based OTP
- Authenticator app support
- Backup codes

### Session Management
- Automatic logout after inactivity (30 minutes)
- Single session per user (optional)
- Force logout on password change
- IP-based restrictions (optional)

### Audit Trail
- Log all user actions
- Track permission changes
- Monitor failed login attempts
- Export audit logs

---

## 6. User Workflows

### Workflow 1: Create New User

```
1. Admin clicks "Add User"
2. Fill personal information
3. Select role (permissions auto-populate)
4. Assign department(s)
5. Set initial password
6. Send welcome email
7. User receives credentials
8. User logs in and changes password
9. User profile activated
```

### Workflow 2: Approve Requisition (Permission Check)

```
1. User clicks "Approve" on requisition
2. System checks: hasPermission('inventory', 'requisitions', 'approve')
3. If YES → Show approval modal
4. If NO → Show "Insufficient permissions" message
5. Log attempt in activity log
```

### Workflow 3: Role Change

```
1. Admin changes user role
2. System revokes old permissions
3. System grants new permissions
4. Log role change in audit trail
5. Notify user of role change
6. Force user to re-login
7. User sees new interface based on new role
```

---

## 7. Implementation Phases

### Phase 1: Database & Backend (Week 1-2)
- [ ] Create new database tables
- [ ] Implement permission checking middleware
- [ ] Create role management APIs
- [ ] Add activity logging
- [ ] Implement session management

### Phase 2: Role Management UI (Week 3)
- [ ] Role list component
- [ ] Role creation/edit form
- [ ] Permission matrix component
- [ ] Role assignment interface

### Phase 3: User Management UI (Week 4)
- [ ] Enhanced user list
- [ ] Improved user form
- [ ] Department assignment
- [ ] Bulk operations

### Phase 4: Security Features (Week 5)
- [ ] Password policy enforcement
- [ ] 2FA implementation
- [ ] Session management UI
- [ ] Activity log viewer

### Phase 5: Integration & Testing (Week 6)
- [ ] Integrate with existing modules
- [ ] Add permission checks to all routes
- [ ] User acceptance testing
- [ ] Documentation

---

## 8. Migration Strategy

### Step 1: Data Migration
```sql
-- Migrate existing users to new structure
-- Assign default permissions based on current role
-- Create department assignments
```

### Step 2: Backward Compatibility
- Keep old permission system running
- Gradually migrate modules to new system
- Dual-check permissions during transition

### Step 3: Cutover
- Switch all modules to new system
- Deprecate old permission checks
- Clean up legacy code

---

## 9. Benefits

### For Administrators
- ✅ Granular control over user permissions
- ✅ Easy role management
- ✅ Complete audit trail
- ✅ Bulk user operations
- ✅ Better security

### For Users
- ✅ Clear understanding of their permissions
- ✅ Self-service profile management
- ✅ Better user experience
- ✅ Faster access to authorized features

### For Organization
- ✅ Compliance with security standards
- ✅ Reduced security risks
- ✅ Better accountability
- ✅ Scalable user management
- ✅ Professional system

---

## 10. Quick Wins (Can Implement Immediately)

### Quick Win 1: Fix Status Values
```sql
UPDATE users SET status = TRIM(status);
ALTER TABLE users MODIFY status ENUM('active', 'pending', 'suspended', 'locked') DEFAULT 'pending';
```

### Quick Win 2: Add Department Assignment
```sql
ALTER TABLE users ADD COLUMN department_id INT;
ALTER TABLE users ADD FOREIGN KEY (department_id) REFERENCES departments(id);
```

### Quick Win 3: Activity Logging
```javascript
// Add to all critical actions
logActivity(userId, 'approve_requisition', 'inventory', 'requisition', reqId);
```

### Quick Win 4: Session Timeout
```javascript
// Frontend - Auto logout after 30 minutes
let inactivityTimer;
const resetTimer = () => {
  clearTimeout(inactivityTimer);
  inactivityTimer = setTimeout(logout, 30 * 60 * 1000);
};
```

---

## 11. Cost-Benefit Analysis

### Development Cost
- 6 weeks development time
- Database migration effort
- Testing and QA
- User training

### Benefits
- Reduced security incidents
- Faster user onboarding
- Better compliance
- Improved user satisfaction
- Scalable for growth

### ROI
- Payback period: 3-6 months
- Long-term maintenance reduction
- Reduced support tickets
- Better audit readiness

---

## 12. Recommended Next Steps

1. **Review & Approve** this proposal
2. **Prioritize features** based on urgency
3. **Start with Quick Wins** for immediate impact
4. **Plan Phase 1** implementation
5. **Assign development resources**
6. **Set timeline and milestones**

---

## Conclusion

Modernizing the user management system will provide:
- **Better Security** through granular permissions
- **Improved Control** with role-based access
- **Enhanced Usability** with modern UI
- **Complete Audit Trail** for compliance
- **Scalability** for future growth

This investment will pay dividends in security, efficiency, and user satisfaction.

---

**Document Version:** 1.0  
**Date:** March 8, 2026  
**Status:** Proposal - Awaiting Approval
