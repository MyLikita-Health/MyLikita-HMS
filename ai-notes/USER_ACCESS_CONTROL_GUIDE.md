# User Access Control Guide

## Overview

The system uses a **three-tier access control model** to manage user permissions:

1. **Role** - Defines the user's job function
2. **Privilege Level** - Sets the permission scope (1-5)
3. **Module Access** - Determines which system areas they can access

---

## 1. Roles

Roles define what type of user this is and their primary job function.

### Available Roles:

| Role | Description |
|------|-------------|
| **Administrator** | Full system access, can manage all users and settings |
| **Inventory Manager** | Manages inventory, stock, suppliers, and purchase orders |
| **Store Keeper** | Handles stock receiving, issuing, and basic inventory tasks |
| **Dentist** | Provides dental care, creates treatment plans, procedures |
| **Dental Assistant** | Assists dentists, manages appointments, patient records |
| **Billing Manager** | Manages billing, payments, financial reports |
| **Cashier** | Processes payments, handles transactions |
| **Doctor** | General medical practitioner |
| **Nurse** | Provides nursing care, assists doctors |
| **Lab Technician** | Manages laboratory tests and results |
| **Staff** | General staff with basic access |

---

## 2. Privilege Levels

Privilege levels determine **what actions** a user can perform within their assigned modules.

### Privilege Level Breakdown:

#### **Level 1 - Basic Access (View Only)** 👁️
- Can view data and reports
- Cannot create, edit, or delete anything
- Read-only access
- **Use for:** Trainees, observers, auditors

#### **Level 2 - Standard Access (View & Create)** ✏️
- Can view all data
- Can create new records
- Cannot edit or delete existing records
- **Use for:** Junior staff, data entry personnel

#### **Level 3 - Advanced Access (View, Create & Edit)** 🔧
- Can view all data
- Can create new records
- Can edit existing records
- Cannot delete records
- **Use for:** Regular staff, experienced team members

#### **Level 4 - Full Access (All Operations)** ⚡
- Can view, create, edit, and delete
- Full operational control
- Cannot manage system settings or users
- **Use for:** Department heads, senior staff, managers

#### **Level 5 - Administrative Access (System-wide)** 🔐
- Complete system access
- Can manage users and roles
- Can change system settings
- Can access all modules regardless of module access settings
- **Use for:** System administrators, facility managers

---

## 3. Module Access

Module access determines **which areas** of the system a user can access.

### Available Modules:

| Module | Icon | Description |
|--------|------|-------------|
| **Dashboard** | 📊 | Main dashboard with overview and statistics |
| **Records** | 📋 | Patient records and medical history |
| **Doctors** | 👨‍⚕️ | Doctor management and schedules |
| **Pharmacy** | 💊 | Pharmacy operations and drug dispensing |
| **Dental** | 🦷 | Dental clinic operations |
| **Dental Lab** | 🔬 | Dental laboratory management |
| **Oral Care Shop** | 🛒 | Oral care product sales |
| **Nurse** | 👩‍⚕️ | Nursing station operations |
| **Laboratory** | 🧪 | Medical laboratory tests |
| **Inventory** | 📦 | Inventory and stock management |
| **Accounts** | 💰 | Billing and financial management |
| **Theater** | 🏥 | Operating theater management |
| **Admin** | ⚙️ | System administration |
| **Maintenance** | 🔧 | System maintenance tools |

---

## How It Works Together

### Example 1: Junior Dentist
```
Role: Dentist
Privilege: Level 3 (View, Create & Edit)
Modules: Dashboard, Records, Dental, Pharmacy

Result: Can access dental module, view and edit patient records, 
        create treatment plans, but cannot delete records or 
        access billing/inventory.
```

### Example 2: Inventory Manager
```
Role: Inventory Manager
Privilege: Level 4 (Full Access)
Modules: Dashboard, Inventory, Accounts

Result: Full control over inventory (view, create, edit, delete),
        can manage stock, suppliers, purchase orders, and view
        financial reports.
```

### Example 3: Cashier
```
Role: Cashier
Privilege: Level 2 (View & Create)
Modules: Dashboard, Accounts, Pharmacy

Result: Can process payments and create transactions, but cannot
        edit or delete existing financial records. Can view
        pharmacy prices but cannot modify them.
```

### Example 4: System Administrator
```
Role: Administrator
Privilege: Level 5 (Administrative)
Modules: All modules selected

Result: Complete system access. Can manage users, change settings,
        access all modules, and perform any operation.
```

---

## Best Practices

### 1. Principle of Least Privilege
- Only grant the minimum access needed for the job
- Start with lower privilege levels and increase as needed
- Regularly review and audit user access

### 2. Role-Based Assignment
- Assign roles that match the user's actual job function
- Use consistent privilege levels for similar roles
- Document any exceptions

### 3. Module Access
- Only enable modules the user needs for their daily work
- Don't give access to sensitive modules (Admin, Accounts) unless necessary
- Consider department-specific access

### 4. Regular Reviews
- Review user access quarterly
- Remove access for inactive users
- Update privileges when roles change

---

## Common Access Patterns

### Clinical Staff
```
Dentist:
- Role: Dentist
- Privilege: Level 3-4
- Modules: Dashboard, Records, Dental, Pharmacy, Dental Lab

Dental Assistant:
- Role: Dental Assistant
- Privilege: Level 2-3
- Modules: Dashboard, Records, Dental, Oral Care Shop

Nurse:
- Role: Nurse
- Privilege: Level 2-3
- Modules: Dashboard, Records, Nurse, Pharmacy, Laboratory
```

### Administrative Staff
```
Billing Manager:
- Role: Billing Manager
- Privilege: Level 4
- Modules: Dashboard, Records, Accounts, Pharmacy

Cashier:
- Role: Cashier
- Privilege: Level 2
- Modules: Dashboard, Accounts

Receptionist:
- Role: Staff
- Privilege: Level 2
- Modules: Dashboard, Records, Doctors, Dental (appointments only)
```

### Inventory Staff
```
Inventory Manager:
- Role: Inventory Manager
- Privilege: Level 4
- Modules: Dashboard, Inventory, Accounts

Store Keeper:
- Role: Store Keeper
- Privilege: Level 3
- Modules: Dashboard, Inventory
```

---

## Security Considerations

### High-Risk Combinations to Avoid:
1. **Level 5 privilege without proper training** - Can cause system-wide issues
2. **Cashier with Level 4+ in Accounts** - Can manipulate financial records
3. **Junior staff with Admin module access** - Can change critical settings
4. **Temporary staff with delete permissions** - Risk of data loss

### Recommended Safeguards:
1. Limit Level 5 privileges to 2-3 trusted administrators
2. Require approval for privilege level increases
3. Enable audit logging for all Level 4+ users
4. Implement session timeouts for sensitive modules
5. Regular password changes for administrative accounts

---

## Troubleshooting

### User Can't Access a Module
1. Check if module is in their Module Access list
2. Verify their privilege level is sufficient (minimum Level 1)
3. Confirm their account status is "Active" or "Approved"
4. Check if their session is still valid

### User Can't Perform an Action
1. Check their privilege level:
   - Level 1: View only
   - Level 2: View + Create
   - Level 3: View + Create + Edit
   - Level 4+: All operations
2. Verify the module is in their access list
3. Check if the specific feature requires higher privileges

### User Has Too Much Access
1. Review their role - is it appropriate?
2. Lower their privilege level if possible
3. Remove unnecessary modules from their access
4. Consider creating a more restrictive role

---

## Migration from Legacy System

The system supports both:
- **Legacy System**: Simple role + accessTo modules
- **New System**: Role + Privilege + Module Access + Granular Permissions

### During Transition:
- Existing users continue to work with legacy access
- New users get the enhanced three-tier system
- Gradually migrate existing users to new system
- Both systems work side-by-side

### Privilege Mapping:
```
Legacy Role → New Privilege Level
- Basic User → Level 1-2
- Standard User → Level 3
- Manager → Level 4
- Administrator → Level 5
```

---

## Summary

The three-tier access control provides:
- **Flexibility**: Fine-grained control over user permissions
- **Security**: Principle of least privilege
- **Clarity**: Clear understanding of what users can do
- **Scalability**: Easy to add new roles and modules
- **Auditability**: Track who has access to what

When creating a new user:
1. Select their **Role** based on job function
2. Set **Privilege Level** based on experience and trust
3. Choose **Modules** they need for daily work
4. Review and confirm before saving

Remember: You can always adjust access later, so start conservative and expand as needed.
