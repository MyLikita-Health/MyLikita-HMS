# Granular Permissions System - Visual Diagrams

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GRANULAR PERMISSIONS SYSTEM              │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐
│   DATABASE   │
└──────────────┘
       │
       ├─── permissions (Master List)
       │    ├─ billing.bills.view
       │    ├─ billing.bills.create
       │    ├─ billing.payments.create
       │    ├─ inventory.requisitions.approve
       │    └─ ... (150+ permissions)
       │
       ├─── roles (System Roles)
       │    ├─ Administrator
       │    ├─ Accountant
       │    ├─ Cashier
       │    └─ ... (11 roles)
       │
       ├─── role_permissions (Mapping)
       │    ├─ Accountant → billing.bills.view
       │    ├─ Accountant → billing.bills.create
       │    ├─ Cashier → billing.payments.create
       │    └─ ...
       │
       ├─── user_roles (User Assignment)
       │    ├─ User #1 → Accountant
       │    ├─ User #2 → Cashier
       │    └─ ...
       │
       └─── user_permissions (Custom Permissions)
            ├─ User #3 → billing.refunds.approve
            └─ ...

┌──────────────┐
│   BACKEND    │
└──────────────┘
       │
       └─── Login Endpoint
            ├─ Fetch user's role
            ├─ Query role permissions
            ├─ Query custom user permissions
            ├─ Group by module/resource
            └─ Return in login response

┌──────────────┐
│   FRONTEND   │
└──────────────┘
       │
       ├─── Redux Action (auth.js)
       │    ├─ Receive login response
       │    ├─ Store permissions in localStorage
       │    └─ Dispatch LOGIN action
       │
       ├─── Permission Helper (permissionHelper.js)
       │    ├─ Read permissions from localStorage
       │    ├─ Check specific permissions
       │    └─ Return true/false
       │
       └─── Components
            ├─ Import permission helpers
            ├─ Check permissions
            └─ Show/hide features
```

---

## Data Flow

```
┌─────────┐
│  USER   │
└─────────┘
     │
     │ 1. Login (username, password)
     ↓
┌─────────────────┐
│  LOGIN ENDPOINT │
└─────────────────┘
     │
     │ 2. Authenticate
     ↓
┌─────────────────┐
│  FETCH ROLE     │
│  FROM users     │
└─────────────────┘
     │
     │ 3. Query permissions
     ↓
┌──────────────────────────────┐
│  SELECT permissions          │
│  FROM role_permissions       │
│  JOIN roles                  │
│  WHERE role = user.role      │
└──────────────────────────────┘
     │
     │ 4. Group permissions
     ↓
┌──────────────────────────────┐
│  {                           │
│    billing: {                │
│      bills: [view, create],  │
│      payments: [view]        │
│    }                         │
│  }                           │
└──────────────────────────────┘
     │
     │ 5. Return response
     ↓
┌──────────────────────────────┐
│  {                           │
│    success: true,            │
│    token: "...",             │
│    user: {...},              │
│    permissions: {...}        │
│  }                           │
└──────────────────────────────┘
     │
     │ 6. Store in localStorage
     ↓
┌──────────────────────────────┐
│  localStorage.setItem(       │
│    'permissions',            │
│    JSON.stringify(perms)     │
│  )                           │
└──────────────────────────────┘
     │
     │ 7. Component checks permission
     ↓
┌──────────────────────────────┐
│  billingPermissions          │
│    .canCreateBills()         │
└──────────────────────────────┘
     │
     │ 8. Read from localStorage
     ↓
┌──────────────────────────────┐
│  permissions.billing         │
│    .bills.includes('create') │
└──────────────────────────────┘
     │
     │ 9. Return true/false
     ↓
┌──────────────────────────────┐
│  {canCreate && <Button />}   │
└──────────────────────────────┘
```

---

## Permission Hierarchy

```
┌─────────────────────────────────────────────────────────┐
│                      ADMINISTRATOR                       │
│                    (Full Access to All)                  │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────────────┐  ┌────────────────┐  ┌───────────────┐
│   ACCOUNTANT  │  │ FACILITY MGR   │  │ INVENTORY MGR │
│  (Full Billing)│  │  (Oversight)   │  │ (Full Inventory)│
└───────────────┘  └────────────────┘  └───────────────┘
        │                   │                   │
        │                   │                   │
┌───────────────┐  ┌────────────────┐  ┌───────────────┐
│ BILLING MGR   │  │    DOCTOR      │  │   PHARMACIST  │
│ (Billing Ops) │  │  (Clinical)    │  │  (Pharmacy)   │
└───────────────┘  └────────────────┘  └───────────────┘
        │                   │                   │
        │                   │                   │
┌───────────────┐  ┌────────────────┐  ┌───────────────┐
│    CASHIER    │  │     NURSE      │  │   LAB TECH    │
│  (Payments)   │  │  (Nursing)     │  │ (Laboratory)  │
└───────────────┘  └────────────────┘  └───────────────┘
        │
        │
┌───────────────┐
│ RECEPTIONIST  │
│ (Registration)│
└───────────────┘
```

---

## Module Structure

```
┌─────────────────────────────────────────────────────────┐
│                        MODULES                           │
└─────────────────────────────────────────────────────────┘

┌──────────────┐
│   BILLING    │ (40+ permissions)
└──────────────┘
    ├─ accounts (view, create, edit, delete)
    ├─ transactions (view, create, edit)
    ├─ bills (view, create, edit, delete)
    ├─ payments (view, create, edit)
    ├─ reports (view, export)
    ├─ retainership (view, manage)
    ├─ deposits (view, create)
    ├─ refunds (view, create, approve)
    ├─ reconciliation (view, export)
    ├─ balance_history (view)
    ├─ services (view, create, edit, delete)
    ├─ expenses (view, create, edit)
    ├─ account_chart (view, edit)
    ├─ discounts (view, approve, setup)
    └─ managed_care (view, edit)

┌──────────────┐
│  INVENTORY   │ (20+ permissions)
└──────────────┘
    ├─ items (view, create, edit, delete)
    ├─ stock (view, adjust, transfer)
    ├─ requisitions (view, create, approve, issue)
    ├─ purchase_orders (view, create, approve)
    ├─ grn (view, create, approve)
    ├─ suppliers (view, create, edit, delete)
    └─ reports (view, export)

┌──────────────┐
│    DENTAL    │ (20+ permissions)
└──────────────┘
    ├─ patients (view, create, edit, delete)
    ├─ charts (view, create, edit)
    ├─ procedures (view, create, edit)
    ├─ treatment_plans (view, create, edit, approve)
    ├─ appointments (view, create, edit, cancel)
    ├─ prescriptions (view, create)
    └─ lab_orders (view, create)

┌──────────────┐
│    USERS     │ (15+ permissions)
└──────────────┘
    ├─ users (view, create, edit, delete, approve, suspend)
    ├─ roles (view, create, edit, delete)
    ├─ permissions (view, assign)
    ├─ activity_log (view)
    └─ sessions (view, terminate)

┌──────────────┐
│   RECORDS    │ (5+ permissions)
└──────────────┘
    ├─ patients (view, create, edit)
    └─ beds (view, allocate)

┌──────────────┐
│   PHARMACY   │ (10+ permissions)
└──────────────┘
    ├─ sales (view, create)
    ├─ dispensary (view, dispense)
    ├─ store (view, manage)
    └─ suppliers (view, manage)

┌──────────────┐
│  LABORATORY  │ (10+ permissions)
└──────────────┘
    ├─ tests (view, create, setup)
    ├─ registrations (view, create)
    ├─ samples (collect, view)
    ├─ analysis (perform, view)
    └─ results (view, approve)

┌──────────────┐
│    ADMIN     │ (5+ permissions)
└──────────────┘
    ├─ settings (view, edit)
    └─ facilities (view, manage)
```

---

## Permission Check Flow

```
Component needs to check permission
        │
        ↓
┌──────────────────────────────────┐
│ billingPermissions.canCreateBills()│
└──────────────────────────────────┘
        │
        ↓
┌──────────────────────────────────┐
│ hasPermission('billing',         │
│               'bills',           │
│               'create')          │
└──────────────────────────────────┘
        │
        ↓
┌──────────────────────────────────┐
│ Get user from localStorage       │
└──────────────────────────────────┘
        │
        ├─ Is user admin? ──→ YES ──→ Return TRUE
        │
        ↓ NO
┌──────────────────────────────────┐
│ Get permissions from localStorage│
└──────────────────────────────────┘
        │
        ↓
┌──────────────────────────────────┐
│ Check permissions.billing        │
│       .bills.includes('create')  │
└──────────────────────────────────┘
        │
        ├─ Found? ──→ YES ──→ Return TRUE
        │
        ↓ NO
    Return FALSE
```

---

## Role Permission Matrix

```
┌─────────────────┬──────┬────────┬─────────┬─────────┬────────┐
│                 │ View │ Create │  Edit   │ Delete  │ Approve│
├─────────────────┼──────┼────────┼─────────┼─────────┼────────┤
│ ADMINISTRATOR   │  ✓   │   ✓    │    ✓    │    ✓    │   ✓    │
├─────────────────┼──────┼────────┼─────────┼─────────┼────────┤
│ ACCOUNTANT      │  ✓   │   ✓    │    ✓    │    ✓    │   ✓    │
│ (Billing only)  │      │        │         │         │        │
├─────────────────┼──────┼────────┼─────────┼─────────┼────────┤
│ BILLING MANAGER │  ✓   │   ✓    │    ✓    │    ✗    │   ✓    │
│ (Billing only)  │      │        │         │         │        │
├─────────────────┼──────┼────────┼─────────┼─────────┼────────┤
│ CASHIER         │  ✓   │   ✓    │    ✗    │    ✗    │   ✗    │
│ (Payments only) │      │(Payment)│         │         │        │
├─────────────────┼──────┼────────┼─────────┼─────────┼────────┤
│ DOCTOR          │  ✓   │   ✓    │    ✓    │    ✗    │   ✗    │
│ (Clinical only) │      │        │         │         │        │
└─────────────────┴──────┴────────┴─────────┴─────────┴────────┘
```

---

## Migration Timeline

```
Week 1: Installation
├─ Day 1: Run installation scripts
├─ Day 2: Verify with different roles
├─ Day 3: Test login and permissions
└─ Day 4-5: Fix any issues

Week 2: Core Modules
├─ Day 1-2: Migrate AccountMenu
├─ Day 3: Migrate InventoryMenu
└─ Day 4-5: Migrate UserManagement

Week 3: Clinical Modules
├─ Day 1-2: Migrate DentalMenu
├─ Day 3: Migrate PharmacyMenu
└─ Day 4-5: Migrate LabMenu

Week 4: Cleanup & Enhancement
├─ Day 1-2: Remove legacy checks
├─ Day 3: Add permission management UI
└─ Day 4-5: Add role management UI
```

---

## Component Integration

```
┌─────────────────────────────────────────────────────────┐
│                    COMPONENT LAYER                       │
└─────────────────────────────────────────────────────────┘

┌──────────────────┐
│  AccountMenu.jsx │
└──────────────────┘
        │
        │ import { billingPermissions }
        ↓
┌──────────────────────────────────────┐
│  {billingPermissions.canViewBills()  │
│    && <MenuItem />}                  │
└──────────────────────────────────────┘
        │
        ↓
┌──────────────────────────────────────┐
│  permissionHelper.js                 │
│  ├─ hasPermission()                  │
│  ├─ billingPermissions.canViewBills()│
│  └─ Returns true/false               │
└──────────────────────────────────────┘
        │
        ↓
┌──────────────────────────────────────┐
│  localStorage.getItem('permissions') │
│  Returns: {                          │
│    billing: {                        │
│      bills: ['view', 'create']       │
│    }                                 │
│  }                                   │
└──────────────────────────────────────┘
```

---

## Security Flow

```
┌─────────────────────────────────────────────────────────┐
│                     SECURITY LAYERS                      │
└─────────────────────────────────────────────────────────┘

Layer 1: Database
├─ Permissions stored in database
├─ Role-permission mappings
└─ User-role assignments

Layer 2: Backend API
├─ Authentication required
├─ Permissions fetched on login
└─ Token-based session

Layer 3: Frontend Storage
├─ Permissions in localStorage
├─ Cleared on logout
└─ Validated on each check

Layer 4: Component Level
├─ Permission checks before render
├─ Menu items filtered
└─ Features hidden/shown

Layer 5: API Endpoints (Future)
├─ Middleware checks permissions
├─ Validates user has access
└─ Returns 403 if denied
```

---

## Legend

```
✓  = Allowed
✗  = Denied
→  = Flow direction
├─ = Branch
└─ = End of branch
│  = Continuation
```

---

These diagrams provide a visual understanding of the granular permissions system architecture, data flow, and integration points.
