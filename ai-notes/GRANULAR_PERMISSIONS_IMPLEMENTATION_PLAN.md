# Granular Permissions System - Full Implementation Plan

## Overview

Implement a complete granular permissions system to replace the legacy `accessTo` and `functionality` fields with a modern, scalable, role-based permission architecture.

---

## Phase 1: Database Schema ✓ (Already Exists)

The schema files already exist:
- `backend/sql/security_and_user_management_schema.sql`
- `backend/sql/seed_roles_and_permissions.sql`

We need to verify these are installed in the database.

---

## Phase 2: Seed Permissions Data

Create comprehensive permissions for all modules:

### Modules to Cover:
1. **Billing/Accounts** - Payments, bills, deposits, refunds, reports
2. **Inventory** - Items, stock, requisitions, GRN, suppliers
3. **Dental** - Patients, procedures, treatment plans, appointments
4. **Users** - User management, roles, permissions
5. **Records** - Patient records, bed allocation
6. **Pharmacy** - Drug sales, dispensary, suppliers
7. **Laboratory** - Tests, results, analysis
8. **Admin** - System settings, facilities

---

## Phase 3: Backend Implementation

### 3.1 Permission Loading on Login
- Fetch user permissions after authentication
- Store in session/token
- Return with user object

### 3.2 Permission Middleware
- Check permissions on protected routes
- Validate module.resource.action format

### 3.3 Permission API Endpoints
- Get user permissions
- Assign permissions to users
- Manage role permissions

---

## Phase 4: Frontend Implementation

### 4.1 Permission Storage
- Store permissions in localStorage
- Load on app initialization
- Clear on logout

### 4.2 Permission Helper Updates
- Already exists in `permissionHelper.js`
- Add more module-specific helpers

### 4.3 Component Updates
- Replace `canUseThis()` with `hasPermission()`
- Update all menu components
- Update all feature guards

---

## Phase 5: User Management UI

### 5.1 Role Assignment
- UI to assign roles to users
- View role permissions

### 5.2 Permission Assignment
- UI to assign individual permissions
- Permission matrix view
- Bulk operations

---

## Phase 6: Migration

### 6.1 Data Migration
- Map existing `functionality` to new permissions
- Assign permissions based on current access
- Preserve existing user access

### 6.2 Backward Compatibility
- Support both systems during transition
- Gradual migration path

---

## Implementation Steps

### Step 1: Verify/Install Database Schema
### Step 2: Seed All Module Permissions
### Step 3: Update Login to Return Permissions
### Step 4: Update Frontend to Store Permissions
### Step 5: Migrate Account Menu (Pilot)
### Step 6: Add Permission Management UI
### Step 7: Migrate Remaining Modules
### Step 8: Data Migration Script
### Step 9: Testing & Validation
### Step 10: Documentation

---

## Timeline

- **Phase 1-2:** Database setup (1-2 hours)
- **Phase 3:** Backend implementation (2-3 hours)
- **Phase 4:** Frontend implementation (3-4 hours)
- **Phase 5:** UI development (4-5 hours)
- **Phase 6:** Migration (2-3 hours)
- **Total:** 12-17 hours

---

## Let's Start!

Ready to begin full implementation?
