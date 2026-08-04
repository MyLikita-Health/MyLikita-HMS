# User Management Dashboard - Granular Permissions Update

## Summary

Updated the User Management Dashboard to integrate with the granular permissions system, allowing administrators to assign roles from the database when creating or editing users.

---

## Changes Made

### 1. Frontend Updates

#### UserManagementDashboard.jsx

**Added State:**
```javascript
const [availableRoles, setAvailableRoles] = useState([]);
const [rolePermissions, setRolePermissions] = useState({});
```

**Added Function:**
```javascript
const fetchAvailableRoles = async () => {
  try {
    const response = await userAPI.getRoles();
    if (response.data && response.data.roles) {
      setAvailableRoles(response.data.roles);
    }
  } catch (err) {
    // Fallback to default roles if API fails
    setAvailableRoles([...defaultRoles]);
  }
};
```

**Updated Role Dropdown:**
- Changed from hardcoded roles to dynamic roles from database
- Shows role name and description
- Displays selected role information

**Before:**
```javascript
<option value="staff">Staff</option>
<option value="admin">Administrator</option>
<option value="inventory_manager">Inventory Manager</option>
// ... hardcoded options
```

**After:**
```javascript
<option value="">Select a role...</option>
{availableRoles.map(role => (
  <option key={role.code} value={role.code}>
    {role.name} - {role.description}
  </option>
))}
```

#### apiClient.js

**Added Function:**
```javascript
getRoles: () => roleAPI.getAllRoles()
```

This allows `userAPI.getRoles()` to fetch roles from the backend.

---

### 2. Backend Updates

#### routes/users.js

**Added Route:**
```javascript
app.get("/roles", authenticate, users.getAllRoles);
```

#### controller/users.js

**Added Function:**
```javascript
exports.getAllRoles = async (req, res) => {
  // Check if roles table exists
  // If exists, fetch from database
  // If not, return default roles
  // Returns: { success: true, roles: [...] }
};
```

**Features:**
- Checks if `roles` table exists
- Fetches active roles from database
- Falls back to default roles if table doesn't exist
- Returns roles with code, name, and description

---

## How It Works

### Creating a User

1. User clicks "Create User" button
2. Modal opens with form
3. `fetchAvailableRoles()` is called
4. Roles are fetched from `/roles` endpoint
5. Role dropdown is populated with available roles
6. User selects a role from dropdown
7. Form is submitted with selected role code
8. Backend creates user with assigned role

### Editing a User

1. User clicks "Edit" button on user row
2. `loadUserForEdit()` fetches user details
3. Form is populated with current user data
4. Role dropdown shows current role
5. User can change role selection
6. Form is submitted with updated role
7. Backend updates user with new role

### Role Assignment Flow

```
Frontend                    Backend                     Database
   │                           │                            │
   ├─ fetchAvailableRoles() ──>│                            │
   │                           ├─ getAllRoles() ──────────>│
   │                           │                            │
   │                           │<─── roles table ──────────┤
   │<─── roles array ──────────┤                            │
   │                           │                            │
   ├─ User selects role        │                            │
   │                           │                            │
   ├─ Submit form ────────────>│                            │
   │                           ├─ createUser/updateUser ──>│
   │                           │                            │
   │                           │<─── user created ─────────┤
   │<─── success ──────────────┤                            │
```

---

## Available Roles

When the granular permissions system is installed, these roles are available:

| Code | Name | Description |
|------|------|-------------|
| `admin` | Administrator | Full system access |
| `accountant` | Accountant | Full billing access |
| `billing_manager` | Billing Manager | Billing operations |
| `cashier` | Cashier | Payment processing |
| `doctor` | Doctor | Clinical access |
| `nurse` | Nurse | Nursing care |
| `pharmacist` | Pharmacist | Pharmacy operations |
| `lab_tech` | Lab Technician | Laboratory operations |
| `inventory_manager` | Inventory Manager | Inventory management |
| `receptionist` | Receptionist | Registration & appointments |
| `facility_manager` | Facility Manager | Facility oversight |

---

## Backward Compatibility

The system maintains full backward compatibility:

1. **If roles table doesn't exist:**
   - Backend returns default roles
   - Frontend displays default roles
   - System continues to work

2. **Legacy role field:**
   - Still stored in `users.role` field
   - Can be used by legacy code
   - No breaking changes

3. **Module access (accessTo):**
   - Still available in form
   - Still stored in database
   - Can be used alongside roles

4. **Functionality access:**
   - Still available in form
   - Still stored in database
   - Can be used alongside roles

---

## Testing Checklist

### Before Installation
- [ ] User Management Dashboard loads
- [ ] Can create users with hardcoded roles
- [ ] Can edit users
- [ ] Role dropdown shows default options

### After Installation
- [ ] Run `node backend/sql/run_granular_permissions_setup.js`
- [ ] Restart backend server
- [ ] User Management Dashboard loads
- [ ] Role dropdown shows database roles
- [ ] Can create user with database role
- [ ] Can edit user and change role
- [ ] User's role is saved correctly
- [ ] Login with new user works
- [ ] Permissions are applied correctly

---

## API Endpoints

### GET /roles

**Description:** Get all available roles

**Authentication:** Required

**Response:**
```json
{
  "success": true,
  "roles": [
    {
      "id": 1,
      "code": "admin",
      "name": "Administrator",
      "description": "Full system access",
      "is_active": true
    },
    ...
  ]
}
```

**Fallback (if table doesn't exist):**
```json
{
  "success": true,
  "roles": [
    {
      "code": "admin",
      "name": "Administrator",
      "description": "Full system access"
    },
    ...
  ]
}
```

---

## Files Modified

1. **frontend/src/components/users/UserManagementDashboard.jsx**
   - Added `availableRoles` state
   - Added `fetchAvailableRoles()` function
   - Updated role dropdown to use dynamic roles
   - Added role description display

2. **frontend/src/utils/apiClient.js**
   - Added `getRoles()` function to `userAPI`

3. **backend/routes/users.js**
   - Added `GET /roles` endpoint

4. **backend/controller/users.js**
   - Added `getAllRoles()` function

---

## Benefits

### For Administrators
- Easy role selection from dropdown
- See role descriptions
- No need to remember role codes
- Consistent role naming

### For Developers
- Centralized role management
- Database-driven roles
- Easy to add new roles
- No hardcoded values

### For System
- Scalable role system
- Easy to extend
- Backward compatible
- No breaking changes

---

## Future Enhancements

### Phase 1 (Current)
- ✅ Dynamic role dropdown
- ✅ Fetch roles from database
- ✅ Backward compatibility

### Phase 2 (Next)
- [ ] Show role permissions in modal
- [ ] Permission preview for selected role
- [ ] Custom permission assignment
- [ ] Role-based permission matrix

### Phase 3 (Future)
- [ ] Role management UI
- [ ] Create/edit/delete roles
- [ ] Assign permissions to roles
- [ ] Clone roles
- [ ] Role templates

---

## Example Usage

### Creating a User with Role

```javascript
// User fills form
const formData = {
  username: 'john.doe',
  password: 'SecurePass123',
  firstname: 'John',
  lastname: 'Doe',
  email: 'john@example.com',
  role: 'accountant', // Selected from dropdown
  privilege: 3,
  accessTo: ['Accounts', 'Reports'],
  functionality: ['Generate Account Report', 'Record Expenses']
};

// Submit form
await userAPI.createUser(formData);

// Backend creates user with role
// User can now login
// Permissions are applied based on role
```

### Editing a User's Role

```javascript
// Load user for editing
const user = await userAPI.getUserDetails(userId);

// User changes role in dropdown
formData.role = 'billing_manager'; // Changed from 'accountant'

// Submit form
await userAPI.updateUserDetails(userId, formData);

// User's role is updated
// New permissions are applied on next login
```

---

## Troubleshooting

### Roles not loading
1. Check if backend is running
2. Check if `/roles` endpoint is accessible
3. Check browser console for errors
4. Verify authentication token is valid

### Role dropdown is empty
1. Check if `fetchAvailableRoles()` is called
2. Check API response in Network tab
3. Verify fallback roles are defined
4. Check for JavaScript errors

### Selected role not saving
1. Check form submission
2. Verify role code is correct
3. Check backend logs
4. Verify database update

### Permissions not working after role change
1. User needs to logout and login again
2. Permissions are loaded on login
3. Check if permissions are in localStorage
4. Verify role-permission mappings in database

---

## Related Documentation

- [Granular Permissions Complete Guide](GRANULAR_PERMISSIONS_COMPLETE_GUIDE.md)
- [Permissions Quick Reference](PERMISSIONS_QUICK_REFERENCE.md)
- [Installation Checklist](INSTALLATION_CHECKLIST.md)
- [Account Menu Migration](ACCOUNT_MENU_MIGRATION_COMPLETE.md)

---

## Conclusion

The User Management Dashboard has been successfully updated to integrate with the granular permissions system. Administrators can now:

- Select roles from a dynamic dropdown
- See role descriptions
- Assign database-driven roles to users
- Maintain backward compatibility

The system is ready for testing and production use.

**Status:** ✅ Update Complete

**Date:** 2026-03-09

**Updated By:** AI Assistant
