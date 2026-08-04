# Next Steps - Action Plan

**Current Status**: Phase 1 Complete ✅  
**Next Phase**: Component Integration & Testing  
**Priority**: High  
**Timeline**: 2-3 weeks

---

## 🎯 Immediate Actions (This Week)

### 1. Test the Security System (2-3 hours)

**Goal**: Verify everything works end-to-end

**Steps**:
```bash
# 1. Start backend server
cd backend
npm start

# 2. Start frontend (in new terminal)
cd frontend
npm run dev

# 3. Test login endpoint
curl -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"your_username","password":"your_password"}'

# Expected: { success: true, token: "Bearer ...", user: {...} }

# 4. Test protected endpoint
curl -X GET http://localhost:5000/inventory/items \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# Expected: List of items or 401 if token invalid
```

**Checklist**:
- [ ] Backend starts without errors
- [ ] Frontend starts without errors
- [ ] Login endpoint returns token
- [ ] Protected endpoint requires token
- [ ] Invalid token returns 401
- [ ] Token refresh works

---

### 2. Update Login Component (2-4 hours)

**Current File**: `frontend/src/components/auth/Login.jsx` (or similar)

**What to Change**:

```javascript
// OLD WAY (remove this)
import axios from 'axios';

const handleLogin = async () => {
  const response = await axios.post('/auth/login', credentials);
  localStorage.setItem('token', response.data.token);
};

// NEW WAY (use this)
import { useDispatch } from 'react-redux';
import { login } from '../redux/actions/authActions';

const dispatch = useDispatch();

const handleLogin = async () => {
  const result = await dispatch(login(credentials));
  
  if (result.success) {
    // Redirect to dashboard
    window.location.href = '/dashboard';
  } else {
    // Show error
    setError(result.error);
  }
};
```

**Full Example**:
```javascript
import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { login } from '../redux/actions/authActions';
import { useHistory } from 'react-router-dom';

const Login = () => {
  const dispatch = useDispatch();
  const history = useHistory();
  const { loading, error } = useSelector(state => state.auth);
  
  const [credentials, setCredentials] = useState({
    username: '',
    password: ''
  });

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    const result = await dispatch(login(credentials));
    
    if (result.success) {
      history.push('/dashboard');
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        value={credentials.username}
        onChange={(e) => setCredentials({...credentials, username: e.target.value})}
        placeholder="Username"
      />
      <input
        type="password"
        value={credentials.password}
        onChange={(e) => setCredentials({...credentials, password: e.target.value})}
        placeholder="Password"
      />
      {error && <div className="error">{error}</div>}
      <button type="submit" disabled={loading}>
        {loading ? 'Logging in...' : 'Login'}
      </button>
    </form>
  );
};

export default Login;
```

**Checklist**:
- [ ] Import new auth actions
- [ ] Use Redux dispatch
- [ ] Handle success/error states
- [ ] Redirect after successful login
- [ ] Show error messages
- [ ] Test login flow

---

### 3. Update Redux Store (1 hour)

**File**: `frontend/src/redux/store.js` (or wherever you configure Redux)

**Add Auth Reducer**:

```javascript
import { createStore, combineReducers, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import authReducer from './reducers/authReducer';
// ... other reducers

const rootReducer = combineReducers({
  auth: authReducer,
  // ... other reducers
});

const store = createStore(rootReducer, applyMiddleware(thunk));

export default store;
```

**Initialize Auth on App Load**:

```javascript
// In your App.jsx or index.jsx
import { useEffect } from 'react';
import { useDispatch } from 'react-redux';
import { initializeAuth } from './redux/actions/authActions';

function App() {
  const dispatch = useDispatch();

  useEffect(() => {
    // Initialize auth from localStorage
    dispatch(initializeAuth());
  }, [dispatch]);

  return (
    // Your app components
  );
}
```

**Checklist**:
- [ ] Add auth reducer to store
- [ ] Initialize auth on app load
- [ ] Test Redux DevTools (if installed)
- [ ] Verify state updates on login

---

## 📋 Week 1 Tasks (Component Integration)

### Priority 1: Core Authentication (Days 1-2)

**Tasks**:
1. ✅ Test security system
2. ✅ Update login component
3. ✅ Update Redux store
4. Update logout functionality
5. Add protected route wrapper
6. Test complete auth flow

**Protected Route Example**:
```javascript
import { useSelector } from 'react-redux';
import { Redirect } from 'react-router-dom';

const ProtectedRoute = ({ component: Component, ...rest }) => {
  const { isAuthenticated } = useSelector(state => state.auth);

  return (
    <Route
      {...rest}
      render={props =>
        isAuthenticated ? (
          <Component {...props} />
        ) : (
          <Redirect to="/auth" />
        )
      }
    />
  );
};
```

### Priority 2: Inventory Components (Days 3-5)

**Files to Update**:
1. `frontend/src/components/inventory/ItemsManagement.jsx`
2. `frontend/src/components/inventory/RequisitionList.jsx`
3. `frontend/src/components/inventory/PurchaseOrders.jsx`
4. `frontend/src/components/inventory/GRNManagement.jsx`

**Pattern to Follow**:

```javascript
// OLD WAY
import axios from 'axios';
const response = await axios.get('/inventory/items');

// NEW WAY
import { inventoryAPI } from '../../utils/apiClient';
const response = await inventoryAPI.getItems();
```

**Add Permission Checks**:

```javascript
import { inventoryPermissions } from '../../utils/permissionHelper';

// In your component
{inventoryPermissions.canCreateItems() && (
  <button onClick={handleCreate}>Create Item</button>
)}

{inventoryPermissions.canApproveRequisitions() && (
  <button onClick={handleApprove}>Approve</button>
)}
```

**Checklist**:
- [ ] Replace all axios calls with API client
- [ ] Add permission checks to buttons
- [ ] Hide features user can't access
- [ ] Test with different user roles
- [ ] Verify error handling works

---

## 📋 Week 2 Tasks (Remaining Routes)

### Priority 1: Protect Dental Routes (Days 1-2)

**File**: `backend/routes/dental.js`

**Pattern**:
```javascript
const { authenticate } = require('../middleware/authenticate');
const { checkPermission } = require('../middleware/permissions');
const { apiLimiter } = require('../middleware/rateLimit');

// Apply global middleware
app.use('/dental', authenticate);
app.use('/dental', apiLimiter);

// Add permission checks
app.post('/dental/appointments',
  checkPermission('dental', 'appointments', 'create'),
  controller.createAppointment
);
```

### Priority 2: Protect Billing Routes (Day 3)

**File**: `backend/routes/account.js` or billing routes

**Pattern**: Same as dental routes

### Priority 3: Protect Clinical Routes (Day 4)

**Files**: Clinical/patient routes

**Pattern**: Same as above

### Priority 4: Test All Routes (Day 5)

**Checklist**:
- [ ] All routes require authentication
- [ ] Permission checks work correctly
- [ ] Rate limiting is active
- [ ] Audit logging is working
- [ ] Error handling is correct

---

## 📋 Week 3 Tasks (UI Enhancement)

### Priority 1: User Management UI (Days 1-3)

**Create/Update**:
1. Enhanced user list with filters
2. Role assignment interface
3. Department assignment
4. Activity log viewer
5. Session management

### Priority 2: Role Management UI (Days 4-5)

**Create**:
1. Role list view
2. Role creation form
3. Permission matrix
4. Role assignment

---

## 🧪 Testing Checklist

### Authentication Tests
- [ ] Login with valid credentials
- [ ] Login with invalid credentials
- [ ] Login with locked account (5 failed attempts)
- [ ] Token refresh (wait 1 hour or manually expire)
- [ ] Logout
- [ ] Session management

### Authorization Tests
- [ ] Access with valid permission
- [ ] Access without permission (should get 403)
- [ ] Access without authentication (should get 401)
- [ ] Different roles see different features
- [ ] Admin can access everything

### UI Tests
- [ ] Buttons hidden when no permission
- [ ] Error messages shown correctly
- [ ] Loading states work
- [ ] Redirects work after login/logout

### API Tests
- [ ] All inventory endpoints work
- [ ] Rate limiting triggers (try 6 logins quickly)
- [ ] Audit logs are created
- [ ] Sessions are tracked

---

## 🐛 Common Issues & Solutions

### Issue 1: "Token expired" immediately after login
**Solution**: Check JWT_SECRET is set correctly in backend .env

### Issue 2: "Permission denied" for admin
**Solution**: Check user role in database matches role_code in user_roles table

### Issue 3: CORS errors
**Solution**: Add frontend URL to CORS whitelist in backend

### Issue 4: Token not being sent
**Solution**: Check API client is initialized and tokens are stored

### Issue 5: Redux state not updating
**Solution**: Verify auth reducer is added to root reducer

---

## 📚 Resources

### Documentation
- **Quick Start**: `SECURITY_QUICK_START.md`
- **Developer Reference**: `DEVELOPER_QUICK_REFERENCE.md`
- **Frontend Guide**: `FRONTEND_API_CLIENT_COMPLETE.md`
- **Implementation Status**: `IMPLEMENTATION_STATUS.md`

### Code Examples
- **API Client Usage**: `frontend/src/utils/apiClient.js`
- **Permission Checks**: `frontend/src/utils/permissionHelper.js`
- **Auth Actions**: `frontend/src/redux/actions/authActions.js`
- **Protected Routes**: `backend/routes/inventory.js`

### Database
- **Check Permissions**: See SQL queries in `DEVELOPER_QUICK_REFERENCE.md`
- **View Sessions**: See SQL queries in documentation
- **Unlock Account**: See SQL queries in documentation

---

## 🎯 Success Criteria

### Week 1 Success
- ✅ Login works with new auth system
- ✅ Inventory components use new API client
- ✅ Permission checks work in UI
- ✅ Token refresh is automatic
- ✅ Error handling works

### Week 2 Success
- ✅ All routes protected
- ✅ All modules have permission checks
- ✅ Rate limiting works
- ✅ Audit logging works
- ✅ No security vulnerabilities

### Week 3 Success
- ✅ User management UI complete
- ✅ Role management UI complete
- ✅ Activity log viewer works
- ✅ Session management works
- ✅ System is production-ready

---

## 💡 Tips for Success

1. **Start Small**: Update login first, then one component at a time
2. **Test Frequently**: Test after each change
3. **Use DevTools**: Redux DevTools and Network tab are your friends
4. **Check Logs**: Backend logs and database activity_log table
5. **Ask Questions**: Refer to documentation when stuck
6. **Take Breaks**: This is a lot of changes, pace yourself

---

## 🚀 Quick Commands

### Start Development
```bash
# Terminal 1: Backend
cd backend && npm start

# Terminal 2: Frontend
cd frontend && npm run dev
```

### Test API
```bash
# Login
curl -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'

# Get items (replace TOKEN)
curl -X GET http://localhost:5000/inventory/items \
  -H "Authorization: Bearer TOKEN"
```

### Check Database
```bash
# View active sessions
mysql -u root prime -e "SELECT * FROM user_sessions WHERE is_active=TRUE"

# View recent activity
mysql -u root prime -e "SELECT * FROM user_activity_log ORDER BY created_at DESC LIMIT 10"

# Check user permissions
mysql -u root prime -e "SELECT * FROM role_permissions WHERE role_id=1"
```

---

## 📞 Need Help?

1. **Check Documentation**: Start with `DEVELOPER_QUICK_REFERENCE.md`
2. **Review Examples**: Look at protected inventory routes
3. **Check Logs**: Backend console and database logs
4. **Test Incrementally**: One change at a time
5. **Verify Database**: Check tables and data

---

## 🎉 You're Ready!

Phase 1 is complete and the foundation is solid. Follow this action plan step by step, and you'll have a fully integrated secure system in 2-3 weeks.

**Start with**: Testing the system and updating the login component.

Good luck! 🚀

---

**Document Version**: 1.0  
**Date**: March 8, 2026  
**Status**: Ready for Action  
**Next Review**: After Week 1 completion
