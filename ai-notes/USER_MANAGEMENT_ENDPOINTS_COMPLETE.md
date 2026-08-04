# User Management Endpoints - Complete

**Date**: March 8, 2026  
**Status**: ✅ Complete

---

## Summary

All requested user management endpoints have been implemented and are ready to use.

---

## Endpoints Implemented

### 1. Get User Permissions
```http
GET /users/:id/permissions
Authorization: Bearer {token}
Permission: Self or Admin

Response:
{
  "success": true,
  "permissions": {
    "inventory": {
      "items": ["view", "create", "edit"],
      "stock": ["view", "adjust"]
    },
    "dental": {
      "patients": ["view", "create"]
    }
  },
  "role": "inventory_manager"
}
```

**Features:**
- Returns all permissions for a user based on their role
- Grouped by module and resource
- Users can view their own permissions
- Admins can view any user's permissions

---

### 2. Get Active Sessions
```http
GET /users/:userId/sessions
Authorization: Bearer {token}

Response:
{
  "success": true,
  "sessions": [
    {
      "id": 1,
      "ip_address": "192.168.1.1",
      "user_agent": "Mozilla/5.0...",
      "created_at": "2026-03-08T10:00:00Z",
      "last_activity": "2026-03-08T12:30:00Z",
      "is_active": true
    }
  ]
}
```

**Features:**
- Lists all active sessions for a user
- Shows IP address, user agent, timestamps
- Already implemented (existing endpoint)

---

### 3. Terminate Session
```http
DELETE /users/:userId/sessions/:sessionId
Authorization: Bearer {token}

Response:
{
  "success": true,
  "message": "Session terminated successfully"
}
```

**Features:**
- Force logout a specific session
- Invalidates the session token
- Useful for security (terminate suspicious sessions)
- Already implemented (existing endpoint)

---

### 4. Get User Activity Log
```http
GET /users/:userId/activity?limit=50
Authorization: Bearer {token}

Response:
{
  "success": true,
  "activities": [
    {
      "id": 1,
      "user_id": 5,
      "action": "create",
      "module": "inventory",
      "resource_type": "items",
      "resource_id": 123,
      "created_at": "2026-03-08T12:00:00Z"
    }
  ]
}
```

**Features:**
- Returns recent user actions
- Limit parameter (default 50)
- Users can view their own activity
- Admins can view any user's activity
- Already implemented (existing endpoint)

---

### 5. Assign Department
```http
PUT /users/:id/department
Authorization: Bearer {token}
Permission: users.users.edit

Body:
{
  "departmentId": 5,
  "isPrimary": true
}

Response:
{
  "success": true,
  "message": "Department assigned successfully"
}
```

**Features:**
- Assigns user to a department
- Supports primary department flag
- Works with both user_departments table and legacy users.department column
- Auto-detects table structure

---

### 6. Get User Departments
```http
GET /users/:id/departments
Authorization: Bearer {token}

Response:
{
  "success": true,
  "departments": [
    {
      "id": 1,
      "department_id": 5,
      "department_name": "Pharmacy",
      "is_primary": true,
      "assigned_at": "2026-03-08T10:00:00Z"
    }
  ]
}
```

**Features:**
- Returns all departments assigned to a user
- Shows primary department
- Works with both table structures
- Includes department names

---

## Frontend API Client

All endpoints are available in the `userAPI` object:

```javascript
import { userAPI } from '../../utils/apiClient';

// Get user permissions
const perms = await userAPI.getPermissions(userId);

// Get active sessions
const sessions = await userAPI.getSessions(userId);

// Terminate session
await userAPI.terminateSession(userId, sessionId);

// Get activity log
const activity = await userAPI.getActivity(userId, 50);

// Assign department
await userAPI.assignDepartment(userId, {
  departmentId: 5,
  isPrimary: true
});

// Get user departments
const depts = await userAPI.getDepartments(userId);
```

---

## Permission Requirements

### Get User Permissions
- Self: User can view their own permissions
- Admin: Can view any user's permissions

### Get Sessions
- Self: User can view their own sessions
- Admin: Can view any user's sessions

### Terminate Session
- Self: User can terminate their own sessions
- Admin: Can terminate any user's sessions

### Get Activity Log
- Self: User can view their own activity
- Admin: Can view any user's activity

### Assign Department
- Permission: `users.users.edit`
- Only admins or users with edit permission

### Get Departments
- Self: User can view their own departments
- Admin: Can view any user's departments

---

## Database Compatibility

### user_departments Table
If the `user_departments` table exists:
- Uses many-to-many relationship
- Supports multiple departments per user
- Supports primary department flag
- Tracks assignment history

### Legacy users.department Column
If `user_departments` table doesn't exist:
- Falls back to `users.department` column
- Single department per user
- Backward compatible

---

## Usage Examples

### View User Permissions in UI
```javascript
const UserPermissionsView = ({ userId }) => {
  const [permissions, setPermissions] = useState({});
  
  useEffect(() => {
    const loadPermissions = async () => {
      const response = await userAPI.getPermissions(userId);
      setPermissions(response.data.permissions);
    };
    loadPermissions();
  }, [userId]);
  
  return (
    <div>
      {Object.entries(permissions).map(([module, resources]) => (
        <div key={module}>
          <h4>{module}</h4>
          {Object.entries(resources).map(([resource, actions]) => (
            <div key={resource}>
              <strong>{resource}:</strong> {actions.join(', ')}
            </div>
          ))}
        </div>
      ))}
    </div>
  );
};
```

### Assign Department
```javascript
const assignDepartment = async (userId, departmentId) => {
  try {
    await userAPI.assignDepartment(userId, {
      departmentId,
      isPrimary: true
    });
    alert('Department assigned successfully');
  } catch (error) {
    alert('Failed to assign department');
  }
};
```

### View User Activity
```javascript
const UserActivityLog = ({ userId }) => {
  const [activity, setActivity] = useState([]);
  
  useEffect(() => {
    const loadActivity = async () => {
      const response = await userAPI.getActivity(userId, 100);
      setActivity(response.data.activities);
    };
    loadActivity();
  }, [userId]);
  
  return (
    <Table>
      <thead>
        <tr>
          <th>Action</th>
          <th>Module</th>
          <th>Resource</th>
          <th>Time</th>
        </tr>
      </thead>
      <tbody>
        {activity.map(log => (
          <tr key={log.id}>
            <td>{log.action}</td>
            <td>{log.module}</td>
            <td>{log.resource_type}</td>
            <td>{new Date(log.created_at).toLocaleString()}</td>
          </tr>
        ))}
      </tbody>
    </Table>
  );
};
```

---

## Testing

### Test Get Permissions
```bash
curl -X GET http://localhost:46990/users/1/permissions \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Test Assign Department
```bash
curl -X PUT http://localhost:46990/users/1/department \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"departmentId": 5, "isPrimary": true}'
```

### Test Get Departments
```bash
curl -X GET http://localhost:46990/users/1/departments \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Files Modified

### Backend
- ✅ `backend/controller/users.js` - Added 3 new functions
- ✅ `backend/routes/users.js` - Added 3 new routes

### Frontend
- ✅ `frontend/src/utils/apiClient.js` - Added 3 new methods to userAPI

---

## Summary

✅ All 6 endpoints implemented  
✅ 3 endpoints already existed (sessions, activity)  
✅ 3 new endpoints added (permissions, department assignment, get departments)  
✅ Frontend API client updated  
✅ Permission checks in place  
✅ Backward compatible with legacy database structure  
✅ Production ready  

The user management system now has complete functionality for:
- Permission viewing
- Session management
- Activity tracking
- Department assignment

---

**Document Version**: 1.0  
**Last Updated**: March 8, 2026  
**Status**: Complete ✅
