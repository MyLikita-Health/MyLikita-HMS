# API Security & Authentication Framework

## Critical Security Issue

**CURRENT STATE:** Backend APIs are unprotected - anyone with the API URL can access endpoints without authentication.

**RISK LEVEL:** 🔴 CRITICAL

**IMPACT:**
- Unauthorized data access
- Data manipulation
- Security breaches
- Compliance violations
- No audit trail

---

## Proposed Solution: Comprehensive API Security Framework

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    API REQUEST FLOW                          │
└─────────────────────────────────────────────────────────────┘

Client Request
     ↓
[1] Authentication Middleware (JWT Token Validation)
     ↓
[2] Session Validation (Active session check)
     ↓
[3] Permission Middleware (RBAC check)
     ↓
[4] Rate Limiting (Prevent abuse)
     ↓
[5] Audit Logging (Track all requests)
     ↓
Controller/Handler
     ↓
Response
```

---

## 1. JWT-Based Authentication

### Token Structure

```javascript
{
  header: {
    alg: "HS256",
    typ: "JWT"
  },
  payload: {
    userId: 123,
    username: "john.doe",
    role: "doctor",
    facilityId: 1,
    permissions: {...},
    iat: 1234567890,  // Issued at
    exp: 1234571490   // Expires at (1 hour)
  },
  signature: "..."
}
```

### Token Management

**Access Token:**
- Short-lived (1 hour)
- Sent with every API request
- Stored in memory (not localStorage for security)

**Refresh Token:**
- Long-lived (7 days)
- Stored in httpOnly cookie
- Used to get new access token
- Can be revoked

---

## 2. Middleware Implementation

### File Structure

```
backend/
├── middleware/
│   ├── authenticate.js       # JWT validation
│   ├── permissions.js        # RBAC checks
│   ├── rateLimit.js         # Rate limiting
│   ├── auditLog.js          # Activity logging
│   └── errorHandler.js      # Centralized error handling
```

### 2.1 Authentication Middleware

**File:** `backend/middleware/authenticate.js`

```javascript
const jwt = require('jsonwebtoken');
const db = require('../models');
const { QueryTypes } = db.Sequelize;

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRES_IN = '1h';

/**
 * Generate JWT token
 */
const generateToken = (user) => {
  return jwt.sign(
    {
      userId: user.id,
      username: user.username,
      role: user.role,
      facilityId: user.facilityId,
      permissions: user.permissions || {}
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
};

/**
 * Generate refresh token
 */
const generateRefreshToken = (user) => {
  return jwt.sign(
    { userId: user.id, type: 'refresh' },
    JWT_SECRET,
    { expiresIn: '7d' }
  );
};

/**
 * Authenticate middleware - Validates JWT token
 */
const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'No token provided. Authentication required.'
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer '

    // Verify token
    const decoded = jwt.verify(token, JWT_SECRET);

    // Check if user still exists and is active
    const [user] = await db.sequelize.query(
      `SELECT id, username, role, facilityId, status 
       FROM users 
       WHERE id = :userId AND status = 'active'`,
      {
        replacements: { userId: decoded.userId },
        type: QueryTypes.SELECT
      }
    );

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'User not found or inactive'
      });
    }

    // Check if session is still valid
    const [session] = await db.sequelize.query(
      `SELECT id FROM user_sessions 
       WHERE user_id = :userId 
       AND session_token = :token 
       AND is_active = TRUE 
       AND expires_at > NOW()`,
      {
        replacements: { userId: user.id, token },
        type: QueryTypes.SELECT
      }
    );

    if (!session) {
      return res.status(401).json({
        success: false,
        message: 'Session expired or invalid'
      });
    }

    // Update last activity
    await db.sequelize.query(
      `UPDATE user_sessions 
       SET last_activity = NOW() 
       WHERE id = :sessionId`,
      {
        replacements: { sessionId: session.id },
        type: QueryTypes.UPDATE
      }
    );

    // Attach user to request
    req.user = {
      id: user.id,
      username: user.username,
      role: user.role,
      facilityId: user.facilityId,
      permissions: decoded.permissions
    };

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expired',
        code: 'TOKEN_EXPIRED'
      });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token'
      });
    }

    console.error('Authentication error:', error);
    return res.status(500).json({
      success: false,
      message: 'Authentication failed'
    });
  }
};

/**
 * Optional authentication - Doesn't fail if no token
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      const decoded = jwt.verify(token, JWT_SECRET);
      
      const [user] = await db.sequelize.query(
        `SELECT id, username, role, facilityId FROM users WHERE id = :userId`,
        {
          replacements: { userId: decoded.userId },
          type: QueryTypes.SELECT
        }
      );

      if (user) {
        req.user = {
          id: user.id,
          username: user.username,
          role: user.role,
          facilityId: user.facilityId,
          permissions: decoded.permissions
        };
      }
    }
    
    next();
  } catch (error) {
    // Continue without authentication
    next();
  }
};

module.exports = {
  authenticate,
  optionalAuth,
  generateToken,
  generateRefreshToken,
  JWT_SECRET
};
```

### 2.2 Permission Middleware

**File:** `backend/middleware/permissions.js`

```javascript
const db = require('../models');
const { QueryTypes } = db.Sequelize;

/**
 * Check if user has specific permission
 */
const checkPermission = (module, resource, action) => {
  return async (req, res, next) => {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Authentication required'
        });
      }

      // Check permission in database
      const [permission] = await db.sequelize.query(
        `SELECT rp.granted
         FROM users u
         JOIN user_roles ur ON u.role = ur.role_code
         JOIN role_permissions rp ON ur.id = rp.role_id
         WHERE u.id = :userId
         AND rp.module = :module
         AND rp.resource = :resource
         AND rp.action = :action
         AND rp.granted = TRUE`,
        {
          replacements: { userId, module, resource, action },
          type: QueryTypes.SELECT
        }
      );

      if (!permission) {
        // Log unauthorized attempt
        await logUnauthorizedAttempt(userId, module, resource, action, req);

        return res.status(403).json({
          success: false,
          message: 'Insufficient permissions',
          required: { module, resource, action }
        });
      }

      next();
    } catch (error) {
      console.error('Permission check error:', error);
      return res.status(500).json({
        success: false,
        message: 'Permission check failed'
      });
    }
  };
};

/**
 * Check if user has any of the specified permissions
 */
const checkAnyPermission = (permissions) => {
  return async (req, res, next) => {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Authentication required'
        });
      }

      // Build OR conditions for multiple permissions
      const conditions = permissions.map((p, index) => 
        `(rp.module = :module${index} AND rp.resource = :resource${index} AND rp.action = :action${index})`
      ).join(' OR ');

      const replacements = { userId };
      permissions.forEach((p, index) => {
        replacements[`module${index}`] = p.module;
        replacements[`resource${index}`] = p.resource;
        replacements[`action${index}`] = p.action;
      });

      const [permission] = await db.sequelize.query(
        `SELECT rp.granted
         FROM users u
         JOIN user_roles ur ON u.role = ur.role_code
         JOIN role_permissions rp ON ur.id = rp.role_id
         WHERE u.id = :userId
         AND (${conditions})
         AND rp.granted = TRUE
         LIMIT 1`,
        {
          replacements,
          type: QueryTypes.SELECT
        }
      );

      if (!permission) {
        return res.status(403).json({
          success: false,
          message: 'Insufficient permissions'
        });
      }

      next();
    } catch (error) {
      console.error('Permission check error:', error);
      return res.status(500).json({
        success: false,
        message: 'Permission check failed'
      });
    }
  };
};

/**
 * Check if user belongs to specific role(s)
 */
const requireRole = (...roles) => {
  return (req, res, next) => {
    const userRole = req.user?.role;

    if (!userRole || !roles.includes(userRole)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient role privileges',
        required: roles,
        current: userRole
      });
    }

    next();
  };
};

/**
 * Check if user belongs to specific facility
 */
const requireFacility = (req, res, next) => {
  const userFacilityId = req.user?.facilityId;
  const requestFacilityId = req.body.facilityId || req.query.facilityId || req.params.facilityId;

  if (userFacilityId != requestFacilityId) {
    return res.status(403).json({
      success: false,
      message: 'Access denied: Facility mismatch'
    });
  }

  next();
};

/**
 * Log unauthorized access attempts
 */
const logUnauthorizedAttempt = async (userId, module, resource, action, req) => {
  try {
    await db.sequelize.query(
      `INSERT INTO user_activity_log 
       (user_id, action, module, resource_type, ip_address, user_agent)
       VALUES (:userId, :action, :module, :resource, :ip, :userAgent)`,
      {
        replacements: {
          userId,
          action: `UNAUTHORIZED_${action}`,
          module,
          resource,
          ip: req.ip || req.connection.remoteAddress,
          userAgent: req.headers['user-agent']
        },
        type: QueryTypes.INSERT
      }
    );
  } catch (error) {
    console.error('Error logging unauthorized attempt:', error);
  }
};

module.exports = {
  checkPermission,
  checkAnyPermission,
  requireRole,
  requireFacility
};
```

### 2.3 Rate Limiting Middleware

**File:** `backend/middleware/rateLimit.js`

```javascript
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');
const redis = require('redis');

// Create Redis client (optional, falls back to memory)
let redisClient;
try {
  redisClient = redis.createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379
  });
} catch (error) {
  console.warn('Redis not available, using memory store for rate limiting');
}

/**
 * General API rate limiter
 */
const apiLimiter = rateLimit({
  store: redisClient ? new RedisStore({ client: redisClient }) : undefined,
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: {
    success: false,
    message: 'Too many requests, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false
});

/**
 * Strict rate limiter for sensitive operations
 */
const strictLimiter = rateLimit({
  store: redisClient ? new RedisStore({ client: redisClient }) : undefined,
  windowMs: 15 * 60 * 1000,
  max: 10, // Only 10 requests per 15 minutes
  message: {
    success: false,
    message: 'Too many attempts, please try again later'
  }
});

/**
 * Login rate limiter
 */
const loginLimiter = rateLimit({
  store: redisClient ? new RedisStore({ client: redisClient }) : undefined,
  windowMs: 15 * 60 * 1000,
  max: 5, // 5 login attempts per 15 minutes
  skipSuccessfulRequests: true,
  message: {
    success: false,
    message: 'Too many login attempts, please try again after 15 minutes'
  }
});

module.exports = {
  apiLimiter,
  strictLimiter,
  loginLimiter
};
```

### 2.4 Audit Logging Middleware

**File:** `backend/middleware/auditLog.js`

```javascript
const db = require('../models');
const { QueryTypes } = db.Sequelize;

/**
 * Log all API requests
 */
const auditLog = (options = {}) => {
  return async (req, res, next) => {
    const startTime = Date.now();

    // Capture original res.json
    const originalJson = res.json.bind(res);

    res.json = function(data) {
      const duration = Date.now() - startTime;

      // Log asynchronously (don't block response)
      logRequest(req, res, data, duration, options).catch(err => {
        console.error('Audit log error:', err);
      });

      return originalJson(data);
    };

    next();
  };
};

/**
 * Log request details
 */
const logRequest = async (req, res, responseData, duration, options) => {
  try {
    const userId = req.user?.id || null;
    const action = `${req.method} ${req.path}`;
    const module = extractModule(req.path);
    const resourceType = extractResourceType(req.path);
    const resourceId = req.params.id || null;

    // Only log if configured
    if (options.logAll || shouldLog(req.method, res.statusCode)) {
      await db.sequelize.query(
        `INSERT INTO user_activity_log 
         (user_id, action, module, resource_type, resource_id, ip_address, user_agent, 
          request_method, request_path, response_status, response_time)
         VALUES (:userId, :action, :module, :resourceType, :resourceId, :ip, :userAgent,
                 :method, :path, :status, :duration)`,
        {
          replacements: {
            userId,
            action,
            module,
            resourceType,
            resourceId,
            ip: req.ip || req.connection.remoteAddress,
            userAgent: req.headers['user-agent'],
            method: req.method,
            path: req.path,
            status: res.statusCode,
            duration
          },
          type: QueryTypes.INSERT
        }
      );
    }
  } catch (error) {
    console.error('Error logging request:', error);
  }
};

/**
 * Determine if request should be logged
 */
const shouldLog = (method, statusCode) => {
  // Log all write operations
  if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(method)) {
    return true;
  }

  // Log failed requests
  if (statusCode >= 400) {
    return true;
  }

  return false;
};

/**
 * Extract module from path
 */
const extractModule = (path) => {
  const parts = path.split('/').filter(Boolean);
  return parts[0] || 'unknown';
};

/**
 * Extract resource type from path
 */
const extractResourceType = (path) => {
  const parts = path.split('/').filter(Boolean);
  return parts[1] || 'unknown';
};

module.exports = {
  auditLog
};
```

---

## 3. Route Protection Pattern

### Example: Inventory Routes

**File:** `backend/routes/inventory.js`

```javascript
const { authenticate } = require('../middleware/authenticate');
const { checkPermission, requireFacility } = require('../middleware/permissions');
const { apiLimiter, strictLimiter } = require('../middleware/rateLimit');
const { auditLog } = require('../middleware/auditLog');

module.exports = (app) => {
  const inventory = require('../controller/inventory');

  // Apply global middleware to all inventory routes
  app.use('/inventory', authenticate);
  app.use('/inventory', requireFacility);
  app.use('/inventory', apiLimiter);
  app.use('/inventory', auditLog());

  // =====================================================
  // ITEMS MANAGEMENT
  // =====================================================
  
  // View items - requires 'view' permission
  app.get('/inventory/items', 
    checkPermission('inventory', 'items', 'view'),
    inventory.getItems
  );

  // Create item - requires 'create' permission
  app.post('/inventory/items',
    checkPermission('inventory', 'items', 'create'),
    inventory.createItem
  );

  // Update item - requires 'edit' permission
  app.put('/inventory/items/:id',
    checkPermission('inventory', 'items', 'edit'),
    inventory.updateItem
  );

  // Delete item - requires 'delete' permission
  app.delete('/inventory/items/:id',
    checkPermission('inventory', 'items', 'delete'),
    strictLimiter, // Extra protection for delete
    inventory.deleteItem
  );

  // =====================================================
  // REQUISITIONS
  // =====================================================
  
  // View requisitions
  app.get('/inventory/requisitions',
    checkPermission('inventory', 'requisitions', 'view'),
    inventory.getRequisitions
  );

  // Create requisition
  app.post('/inventory/requisitions',
    checkPermission('inventory', 'requisitions', 'create'),
    inventory.createRequisition
  );

  // Approve requisition - requires 'approve' permission
  app.post('/inventory/requisitions/:id/approve',
    checkPermission('inventory', 'requisitions', 'approve'),
    inventory.approveRequisition
  );

  // Issue requisition - requires 'issue' permission
  app.post('/inventory/requisitions/:id/issue',
    checkPermission('inventory', 'requisitions', 'issue'),
    inventory.issueRequisition
  );
};
```

---

## 4. Frontend Integration

### 4.1 API Client with Token Management

**File:** `frontend/src/utils/apiClient.js`

```javascript
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000';

// Create axios instance
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Token storage (in memory for security)
let accessToken = null;

/**
 * Set access token
 */
export const setAccessToken = (token) => {
  accessToken = token;
};

/**
 * Get access token
 */
export const getAccessToken = () => {
  return accessToken;
};

/**
 * Clear access token
 */
export const clearAccessToken = () => {
  accessToken = null;
};

/**
 * Request interceptor - Add token to all requests
 */
apiClient.interceptors.request.use(
  (config) => {
    if (accessToken) {
      config.headers.Authorization = `Bearer ${accessToken}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

/**
 * Response interceptor - Handle token expiration
 */
apiClient.interceptors.response.use(
  (response) => {
    return response;
  },
  async (error) => {
    const originalRequest = error.config;

    // If token expired, try to refresh
    if (error.response?.status === 401 && 
        error.response?.data?.code === 'TOKEN_EXPIRED' &&
        !originalRequest._retry) {
      
      originalRequest._retry = true;

      try {
        // Call refresh token endpoint
        const response = await axios.post(`${API_BASE_URL}/auth/refresh`, {}, {
          withCredentials: true // Send httpOnly cookie
        });

        const { accessToken: newToken } = response.data;
        setAccessToken(newToken);

        // Retry original request with new token
        originalRequest.headers.Authorization = `Bearer ${newToken}`;
        return apiClient(originalRequest);
      } catch (refreshError) {
        // Refresh failed, logout user
        clearAccessToken();
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  }
);

export default apiClient;
```

### 4.2 Updated Redux Actions

**File:** `frontend/src/redux/actions/inventory-api.js`

```javascript
import apiClient from '../../utils/apiClient';

export const _get = async (url) => {
  try {
    const response = await apiClient.get(url);
    return response.data;
  } catch (error) {
    handleApiError(error);
    throw error;
  }
};

export const _post = async (url, data) => {
  try {
    const response = await apiClient.post(url, data);
    return response.data;
  } catch (error) {
    handleApiError(error);
    throw error;
  }
};

export const _put = async (url, data) => {
  try {
    const response = await apiClient.put(url, data);
    return response.data;
  } catch (error) {
    handleApiError(error);
    throw error;
  }
};

export const _delete = async (url) => {
  try {
    const response = await apiClient.delete(url);
    return response.data;
  } catch (error) {
    handleApiError(error);
    throw error;
  }
};

const handleApiError = (error) => {
  if (error.response?.status === 403) {
    // Permission denied
    alert('You do not have permission to perform this action');
  } else if (error.response?.status === 429) {
    // Rate limit exceeded
    alert('Too many requests. Please try again later');
  } else if (error.response?.status === 401) {
    // Unauthorized - will be handled by interceptor
    console.log('Authentication required');
  }
};
```

---

## 5. Login Flow with Token Generation

**File:** `backend/controller/auth.js`

```javascript
const { generateToken, generateRefreshToken } = require('../middleware/authenticate');
const db = require('../models');
const { QueryTypes } = db.Sequelize;
const bcrypt = require('bcrypt');

exports.login = async (req, res) => {
  try {
    const { username, password } = req.body;

    // Get user with permissions
    const [user] = await db.sequelize.query(
      `SELECT u.*, ur.role_name
       FROM users u
       LEFT JOIN user_roles ur ON u.role = ur.role_code
       WHERE u.username = :username AND u.status = 'active'`,
      {
        replacements: { username },
        type: QueryTypes.SELECT
      }
    );

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password);

    if (!isValidPassword) {
      // Log failed attempt
      await logFailedLogin(user.id, req);
      
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Get user permissions
    const permissions = await getUserPermissions(user.id);

    // Generate tokens
    const accessToken = generateToken({ ...user, permissions });
    const refreshToken = generateRefreshToken(user);

    // Create session
    await db.sequelize.query(
      `INSERT INTO user_sessions 
       (user_id, session_token, ip_address, user_agent, expires_at)
       VALUES (:userId, :token, :ip, :userAgent, DATE_ADD(NOW(), INTERVAL 1 HOUR))`,
      {
        replacements: {
          userId: user.id,
          token: accessToken,
          ip: req.ip || req.connection.remoteAddress,
          userAgent: req.headers['user-agent']
        },
        type: QueryTypes.INSERT
      }
    );

    // Set refresh token as httpOnly cookie
    res.cookie('refreshToken', refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
    });

    // Return access token and user info
    res.json({
      success: true,
      accessToken,
      user: {
        id: user.id,
        username: user.username,
        firstname: user.firstname,
        lastname: user.lastname,
        role: user.role,
        facilityId: user.facilityId,
        permissions
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed'
    });
  }
};

const getUserPermissions = async (userId) => {
  const permissions = await db.sequelize.query(
    `SELECT rp.module, rp.resource, rp.action
     FROM users u
     JOIN user_roles ur ON u.role = ur.role_code
     JOIN role_permissions rp ON ur.id = rp.role_id
     WHERE u.id = :userId AND rp.granted = TRUE`,
    {
      replacements: { userId },
      type: QueryTypes.SELECT
    }
  );

  // Convert to nested object structure
  const permissionsObj = {};
  permissions.forEach(p => {
    if (!permissionsObj[p.module]) {
      permissionsObj[p.module] = {};
    }
    if (!permissionsObj[p.module][p.resource]) {
      permissionsObj[p.module][p.resource] = {};
    }
    permissionsObj[p.module][p.resource][p.action] = true;
  });

  return permissionsObj;
};
```

---

## 6. Migration Strategy

### Phase 1: Add Middleware (Week 1)
1. Create middleware files
2. Add JWT dependencies
3. Test middleware independently

### Phase 2: Protect Critical Routes (Week 2)
1. Start with authentication only
2. Add to inventory routes
3. Add to user management routes
4. Add to financial routes

### Phase 3: Add Permission Checks (Week 3)
1. Implement RBAC database tables
2. Add permission middleware
3. Apply to all routes

### Phase 4: Frontend Integration (Week 4)
1. Update API client
2. Handle token refresh
3. Update all API calls
4. Test end-to-end

---

## 7. Environment Variables

**File:** `.env`

```bash
# JWT Configuration
JWT_SECRET=your-super-secret-key-change-this-in-production
JWT_EXPIRES_IN=1h
REFRESH_TOKEN_EXPIRES_IN=7d

# Redis (optional, for rate limiting)
REDIS_HOST=localhost
REDIS_PORT=6379

# Security
NODE_ENV=production
CORS_ORIGIN=https://yourdomain.com
```

---

## 8. Testing

### Test Authentication

```bash
# Login
curl -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'

# Use token
curl -X GET http://localhost:5000/inventory/items \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# Without token (should fail)
curl -X GET http://localhost:5000/inventory/items
```

---

## 9. Benefits

✅ **Security:** All endpoints protected  
✅ **Scalability:** Works for all modules  
✅ **Flexibility:** Easy to add new permissions  
✅ **Audit Trail:** Complete activity logging  
✅ **Rate Limiting:** Prevents abuse  
✅ **Token Refresh:** Seamless user experience  
✅ **Future-Proof:** Ready for new modules  

---

## 10. Next Steps

1. **Review & Approve** this framework
2. **Install Dependencies:**
   ```bash
   npm install jsonwebtoken bcrypt express-rate-limit
   ```
3. **Create Middleware Files**
4. **Update Routes** with authentication
5. **Test Thoroughly**
6. **Deploy to Production**

---

**This framework will secure ALL your APIs - existing and future modules!**
