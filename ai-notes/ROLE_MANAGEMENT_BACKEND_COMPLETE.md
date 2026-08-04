# Role Management Backend - Complete

**Date**: March 8, 2026  
**Status**: ✅ Backend Complete - Ready for Frontend

---

## What Was Implemented

### Backend Components

#### 1. Controller (`backend/controller/roles.js`)
Complete CRUD operations for role management:
- `getAllRoles()` - Get all active roles
- `getRoleById()` - Get role with permissions
- `createRole()` - Create new role
- `updateRole()` - Update role details
- `deleteRole()` - Delete role (with safety checks)
- `getRolePermissions()` - Get permissions for a role
- `updateRolePermissions()` - Update role permissions
- `cloneRole()` - Clone existing role with permissions
- `getAvailablePermissions()` - Get all available permissions

#### 2. Routes (`backend/routes/roles.js`)
All endpoints protected with authentication and permissions:
- `GET /roles` - List all roles
- `GET /roles/:id` - Get role details
- `POST /roles` - Create role
- `PUT /roles/:id` - Update role
- `DELETE /roles/:id` - Delete role
- `GET /roles/:id/permissions` - Get role permissions
- `PUT /roles/:id/permissions` - Update permissions
- `POST /roles/:id/clone` - Clone role
- `GET /roles/available/permissions` - Get permission structure

#### 3. API Client (`frontend/src/utils/apiClient.js`)
Added `roleAPI` with 9 methods for frontend use

#### 4. App Registration (`backend/app.js`)
Routes registered and active

---

## API Endpoints

### Get All Roles
```http
GET /roles
Authorization: Bearer {token}
Permission: users.roles.view

Response:
{
  "results": [
    {
      "id": 1,
      "role_name": "Administrator",
      "role_code": "admin",
      "description": "Full system access",
      "is_system_role": true,
      "is_active": true,
      "created_at": "2026-03-08T...",
      "updated_at": "2026-03-08T..."
    }
  ]
}
```

### Get Role By ID
```http
GET /roles/:id
Authorization: Bearer {token}
Permission: users.roles.view

Response:
{
  "result": {
    "id": 1,
    "role_name": "Administrator",
    "role_code": "admin",
    "description": "Full system access",
    "is_system_role": true,
    "is_active": true,
    "permissions": [
      {
        "id": 1,
        "module": "inventory",
        "resource": "items",
        "action": "view",
        "granted": true
      }
    ]
  }
}
```

### Create Role
```http
POST /roles
Authorization: Bearer {token}
Permission: users.roles.create

Body:
{
  "role_name": "Custom Manager",
  "role_code": "custom_manager",
  "description": "Custom role description"
}

Response:
{
  "message": "Role created successfully",
  "roleId": 10
}
```

### Update Role
```http
PUT /roles/:id
Authorization: Bearer {token}
Permission: users.roles.edit

Body:
{
  "role_name": "Updated Name",
  "description": "Updated description",
  "is_active": true
}

Response:
{
  "message": "Role updated successfully"
}
```

### Delete Role
```http
DELETE /roles/:id
Authorization: Bearer {token}
Permission: users.roles.delete

Response:
{
  "message": "Role deleted successfully"
}

Notes:
- Cannot delete system roles
- Cannot delete roles assigned to users
```

### Update Role Permissions
```http
PUT /roles/:id/permissions
Authorization: Bearer {token}
Permission: users.roles.edit

Body:
{
  "permissions": [
    {
      "module": "inventory",
      "resource": "items",
      "action": "view",
      "granted": true
    },
    {
      "module": "inventory",
      "resource": "items",
      "action": "create",
      "granted": true
    }
  ]
}

Response:
{
  "message": "Permissions updated successfully"
}
```

### Clone Role
```http
POST /roles/:id/clone
Authorization: Bearer {token}
Permission: users.roles.create

Body:
{
  "role_name": "Cloned Role",
  "role_code": "cloned_role"
}

Response:
{
  "message": "Role cloned successfully",
  "roleId": 11
}
```

### Get Available Permissions
```http
GET /roles/available/permissions
Authorization: Bearer {token}
Permission: users.roles.view

Response:
{
  "permissions": {
    "inventory": {
      "items": ["view", "create", "edit", "delete"],
      "stock": ["view", "adjust", "transfer"],
      "requisitions": ["view", "create", "approve", "issue"]
    },
    "dental": {
      "patients": ["view", "create", "edit", "delete"],
      "procedures": ["view", "create", "edit", "delete"]
    },
    "billing": {
      "accounts": ["view", "create", "edit", "delete"],
      "transactions": ["view", "create", "edit"]
    },
    "users": {
      "users": ["view", "create", "edit", "delete", "approve", "suspend"],
      "roles": ["view", "create", "edit", "delete"]
    }
  }
}
```

---

## Safety Features

### System Role Protection
- System roles (is_system_role = TRUE) cannot be:
  - Modified
  - Deleted
  - Have permissions changed

### User Assignment Check
- Roles assigned to users cannot be deleted
- Must reassign users first

### Permission Requirements
All endpoints require appropriate permissions:
- View: `users.roles.view`
- Create: `users.roles.create`
- Edit: `users.roles.edit`
- Delete: `users.roles.delete`

---

## Frontend Usage

```javascript
import { roleAPI } from '../../utils/apiClient';

// Get all roles
const roles = await roleAPI.getAllRoles();

// Get role with permissions
const role = await roleAPI.getRoleById(1);

// Create role
await roleAPI.createRole({
  role_name: 'New Role',
  role_code: 'new_role',
  description: 'Description'
});

// Update role
await roleAPI.updateRole(1, {
  role_name: 'Updated Name',
  description: 'Updated description'
});

// Update permissions
await roleAPI.updateRolePermissions(1, [
  { module: 'inventory', resource: 'items', action: 'view', granted: true },
  { module: 'inventory', resource: 'items', action: 'create', granted: true }
]);

// Clone role
await roleAPI.cloneRole(1, {
  role_name: 'Cloned Role',
  role_code: 'cloned_role'
});

// Get available permissions
const permissions = await roleAPI.getAvailablePermissions();

// Delete role
await roleAPI.deleteRole(1);
```

---

## Testing

### Test with cURL

```bash
# Get all roles
curl -X GET http://localhost:46990/roles \
  -H "Authorization: Bearer YOUR_TOKEN"

# Create role
curl -X POST http://localhost:46990/roles \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "role_name": "Test Role",
    "role_code": "test_role",
    "description": "Test description"
  }'

# Get available permissions
curl -X GET http://localhost:46990/roles/available/permissions \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Next Steps

### Frontend Components to Create

1. **RoleManagement.jsx** - Main dashboard
   - List all roles
   - Search/filter
   - Create/edit/delete buttons
   - Role assignment

2. **RoleForm.jsx** - Create/Edit form
   - Role name, code, description
   - Active status toggle
   - Save/cancel buttons

3. **PermissionMatrix.jsx** - Permission editor
   - Checkbox grid (modules × resources × actions)
   - Select all/none per module
   - Visual grouping
   - Save permissions

4. **Integration**
   - Add to admin sidebar
   - Add route to admin/index.jsx
   - Add permission helpers

---

## Database Schema

### user_roles Table
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

### role_permissions Table
```sql
CREATE TABLE role_permissions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  role_id INT NOT NULL,
  module VARCHAR(50) NOT NULL,
  resource VARCHAR(50) NOT NULL,
  action VARCHAR(20) NOT NULL,
  granted BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (role_id) REFERENCES user_roles(id) ON DELETE CASCADE,
  UNIQUE KEY unique_permission (role_id, module, resource, action)
);
```

---

## Summary

✅ Backend API complete with 9 endpoints  
✅ All endpoints protected with authentication & permissions  
✅ Safety checks for system roles and user assignments  
✅ API client methods added to frontend  
✅ Routes registered in app.js  
✅ Ready for frontend UI development  

The backend is production-ready. You can now build the frontend components or test the API endpoints directly.

---

**Document Version**: 1.0  
**Last Updated**: March 8, 2026  
**Status**: Backend Complete ✅
