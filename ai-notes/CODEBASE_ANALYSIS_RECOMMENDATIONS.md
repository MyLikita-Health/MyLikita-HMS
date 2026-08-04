# MyLikita Dental Practice Management — Codebase Analysis & Recommendations

> **Generated:** July 2, 2026  
> **Scope:** Full-stack dental practice management system (React + Redux frontend, Node.js/Express + MySQL backend)

---

## 1. Project Overview

**MyLikita** is a comprehensive dental practice management system with the following modules:

| Module | Frontend | Backend |
|---|---|---|
| **Dental** | `frontend/src/components/dental/` | Integrated into general controllers |
| **Radiology / DICOM** | `frontend/src/components/radiology/`, `dicom/` | `backend/controller/dicom.js`, `routes/dicom.js` |
| **Dental Lab** | `frontend/src/components/dental-lab/` | `backend/controller/lab.js`, `lab2.js`, `lab3.js` |
| **Pharmacy** | `frontend/src/components/pharmacy/` | `backend/controller/pharmacy.js`, `pharm-new.js` |
| **HR / Payroll** | `frontend/src/components/hr/` | General user controllers |
| **Inventory** | `frontend/src/components/inventory/` | General controllers |
| **Account / Finance** | `frontend/src/components/account/` | `backend/controller/account.js` (3859 lines) |
| **Appointments** | `frontend/src/components/appointments/`, `doc_dash/appointments/` | General controllers |
| **Patient Records** | `frontend/src/components/record/` | `backend/controller/patientrecords.js` |
| **Reports** | `frontend/src/components/reports/` | Various |
| **Admin** | `frontend/src/components/admin/` | General |
| **Retainership** | `frontend/src/components/account/retainership/` | `backend/controller/retainership.js` |
| **Surgery / Theatre** | `frontend/src/components/theatre/` | `backend/controller/surgery.js` |
| **Nursing** | `frontend/src/components/nurse/` | `backend/controller/nursing.js` |

### Tech Stack

| Layer | Technology |
|---|---|
| **Frontend Framework** | React 16.13.1 (from 2020) |
| **State Management** | Redux 4.0.5 + redux-thunk 2.3.0 |
| **Routing** | React Router 5.1.2 |
| **UI Library** | Bootstrap 4.6.2 + reactstrap 8.0.1 |
| **Build Tool** | Vite 7.1 (migrated from react-scripts) |
| **Backend Runtime** | Node.js with Express 4.16 |
| **ORM** | Sequelize 5.18.1 |
| **Database** | MySQL 2 / mysql2 |
| **Auth** | Passport.js + JWT (jsonwebtoken) |
| **Real-time** | Socket.io 4.x |
| **File Uploads** | Multer + Cloudinary |
| **Email** | Nodemailer + email-templates |
| **SMS** | Twilio |
| **PDF** | @react-pdf/renderer, jspdf |
| **DICOM** | dicom-parser, OHIF Viewer integration |
| **Logging** | Morgan + Winston + rotating-file-stream |

---

## 2. 🔴 Critical Issues

### 2.1 Security: Hardcoded JWT Secret

**File:** `backend/config/passserport.js` (line 8)
```js
opts.secretOrKey = 'secret';
```

The JWT signing secret is literally `'secret'` — a well-known default. This means anyone can forge valid JWTs and impersonate any user. **This must be moved to an environment variable immediately.**

### 2.2 Security: Hardcoded Cloudinary Credentials

**File:** `backend/app.js` (lines 51-55)
```js
cloudinary.config({
  cloud_name: 'emaitee',
  api_key: '686693879643855',
  api_secret: 'JxH0QfWz-4k-HsMRQcQmWiM2_Jg',
});
```

Full Cloudinary API credentials are hardcoded in the main app file, committed to the repository. Anyone with access to the repo can upload/delete/manage Cloudinary assets.

### 2.3 Security: Database Credentials in Config

**File:** `backend/config/config.json`

Production database credentials (host, username, password) for both `primedevelopment` and `habeebydevelopment` are stored in plaintext in a config file committed to the repository. AWS RDS endpoints and passwords are exposed.

### 2.4 Security: No Environment Variables (.env)

Despite `dotenv` being a dependency and `.env` being gitignored, the project does NOT use environment variables. All secrets are hardcoded. The `.env` file pattern is gitignored but never utilized.

### 2.5 Security: SQL Injection in Passport Legacy Code

**File:** `backend/config/passserport.js` (commented-out LocalStrategy)
```js
var insertQuery = `INSERT INTO users (email,password) values ('${email}', '${password}')`;
```

While this code is commented out, the pattern indicates SQL injection vulnerabilities may exist in other controllers or could be reintroduced.

---

## 3. 🟠 High-Priority Issues

### 3.1 Almost Zero Test Coverage

The entire project has **1 test file** (`frontend/src/App.test.jsx`) that only checks if the App component renders. No unit tests, integration tests, or API tests exist for:
- 20+ backend controllers
- 15+ Redux reducers
- 200+ React components
- Multiple database models

### 3.2 Massive Commented-Out Code Bloat

Throughout the codebase (especially `backend/app.js`, `backend/config/passserport.js`), large blocks of code are commented out rather than removed:

- `backend/app.js`: ~100+ lines of commented-out code (socket.io setup, HL7 server, cluster config, toobusy middleware, error handlers, winston logger, express-status-monitor)
- `backend/config/passserport.js`: ~90 lines of commented LocalStrategy
- `backend/routes/`: Many route files have commented-out `allowOnly` middleware patterns
- Various controllers have commented-out code blocks

### 3.3 Dual Authentication Systems

Two auth systems run simultaneously:
- **Legacy auth** (`frontend/src/redux/actions/auth.js`, reducers `auth`)
- **New JWT auth** (`frontend/src/redux/actions/authActions.js`, reducers `newAuth`)

Both are initialized in `App.jsx`:
```jsx
dispatch(init(history, location));         // Legacy
dispatch(initializeAuth());                // New JWT
```

This creates confusion, potential security gaps, and maintains unnecessary complexity.

### 3.4 Extremely Large Controller Files

| File | Approx. Lines | Issues |
|---|---|---|
| `backend/controller/account.js` | ~3,859 | Monolithic — does everything related to accounting |
| `backend/controller/users.js` | ~1,000+ | User CRUD, auth, registration all in one file |
| `backend/controller/transactions.js` | ~1,180+ | All transaction types in one file |
| `backend/controller/patientrecords.js` | ~600+ | Patient records + clinical data |

### 3.5 Outdated / Deprecated Dependencies

| Dependency | Version | Issue |
|---|---|---|
| React | 16.13.1 (2019) | 3 major versions behind (React 19 is current) |
| Bootstrap | 4.6.2 | Bootstrap 5 is current, Bootstrap 4 is in LTS |
| jQuery | 3.7.1 | Heavy dependency for a React app; used by Bootstrap |
| Chart.js / react-chartjs-2 | 2.x | React-chartjs-2 v2 is deprecated; v5 is current |
| ag-grid-community | 22.1.1 | Very outdated; current is v32+ |
| redux-logger | 3.0.6 | Deprecated in favor of `redux-logger` alternatives |
| history | 1.17.0 | Extremely old; React Router 5 uses a bundled history |
| react-bootstrap | 0.31.5 | From 2017; current is v2.x |
| react-bootstrap-date-picker | 5.1.0 | Unmaintained since ~2017 |
| validator | 9.4.1 (backend) | Current is v13+ |
| chai, mocha (peer) | Not found | No test framework at all |
| react-custom-scrollbars | 4.2.1 | Unmaintained |
| cucu | 2.1.8 | Only needed if not using `uuid` (which is also a dependency!) |
| firebase | 7.15.0 | Firebase included but appears unused in main app flow |
| request | 2.88.2 | Deprecated since 2020 |
| react-scripts | 5.0.1 | Included but Vite is the build tool — should be removed |

---

## 4. 🟡 Medium-Priority Issues

### 4.1 No TypeScript

The entire codebase is plain JavaScript. For a project of this size (~200+ components, 20+ controllers), TypeScript would provide:
- Type safety and catch bugs at compile time
- Better IDE autocompletion and refactoring
- Self-documenting code

### 4.2 Inconsistent Code Style & No Linting Enforcement

- Backend uses `var` in many files (`backend/utilities/datalogger.js`, `backend/app.js`)
- Mixed use of `require()` (CommonJS) in backend and `import` (ESM) in frontend
- No Prettier configuration
- ESLint configuration exists (`frontend/eslint.config.js`) but likely not enforced
- Inconsistent indentation and formatting

### 4.3 Backend Dockerfile Uses Windows Nano Base Image

```dockerfile
FROM stefanscherer/node-windows:7.6.0-nano as build
```

This is a Windows-based Node.js 7.6.0 image — incredibly outdated (Node 7 was EOL in 2017) and runs on Windows containers, which are less common and more resource-intensive. The frontend Dockerfile is well-structured (multi-stage with Alpine), but the backend's is problematic.

### 4.4 No Input Validation on Many Endpoints

While some endpoints have validation (`backend/validation/register.js`, `login.js`), many controller endpoints directly use request body values without:
- Schema validation (e.g., Joi, express-validator, Zod)
- Type coercion
- Sanitization

### 4.5 No Centralized Error Handling

The error handling middleware in `backend/app.js` is entirely commented out:
```js
// app.use(logErrors)
// app.use(clientErrorHandler)
// app.use(errorHandler)
// app.use(function(req, res, next) { ... 404 handler ... })
```

This means unhandled errors may crash workers or leak stack traces to clients.

### 4.6 Duplicate and Stale Files

- `backend/controller/pharm-new.js` and `backend/controller/pharm-new 2.js` — a copy with a space and "2" suffix
- `backend/controller/saved--lab.js` — likely a backup file
- `backend/controller/Bills.js` — uses ES `import` syntax in a CommonJS project
- Several `.sql` files in `backend/controller/` directory (not in `backend/sql/`)

### 4.7 No CI/CD Pipeline

No GitHub Actions, CircleCI, or similar CI/CD configuration is present. Given Dockerfiles exist, CI/CD would be natural for automated testing and deployment.

### 4.8 Inconsistent API Response Format

Some endpoints return:
```js
res.json({ success: true, data: ... })
```
Others return:
```js
res.status(200).json({ ... })
res.status(400).json({ err: "message" })
res.status(500).json({ error: "message" })
```

No standardized response envelope (e.g., `{ status, message, data, errors }`).

---

## 5. 🔵 Low-Priority / Enhancement Suggestions

### 5.1 Redundant Dependencies
- Both `uuid` and `uuidv4` and `cuid` are dependencies — use only one
- Both `react-bootstrap` (v0.31.5) and `reactstrap` (v8.0.1) are Bootstrap React libraries — consolidate to one
- Both `react-custom-scroll` and `react-custom-scrollbars` are present
- Both PouchDB and SQL/Sequelize are present — PouchDB looks unused (commented out in store.js)

### 5.2 Redux Store Configuration Can Be Simplified
```js
const createStoreWithMiddleware =
  process.env.NODE_ENV === "development"
    ? applyMiddleware(thunk.default || thunk, logger.default || logger)(createStore)
    : applyMiddleware(thunk.default || thunk)(createStore);
```
The `thunk.default || thunk` pattern suggests ESM interop issues that could be cleaned up.

### 5.3 Socket.io Handler Is Commented Out
```js
// const onConnection = (socket) => {
//   registerNotificationHandler(io, socket)
//   registerQueueHandler(io, socket)
//   ...
// }
// io.on('connection', onConnection)
```
Socket.io is configured as a dependency and has handler files (`backend/services/notifications.js`, `backend/services/queue.js`) but the connection handler is commented out in `app.js`.

### 5.4 Mobile Responsiveness
The frontend uses `toggleMobileView(window.innerWidth <= 760)` in App.jsx, but many custom components may not be fully responsive. The UI library (`reactstrap` + Bootstrap 4) supports responsive design but custom components should be audited.

### 5.5 No API Documentation Versioning
Swagger exists (`backend/swagger.json`) but appears to be a single large file and may be out of date with actual endpoints.

### 5.6 Vite Polyfill Overhead
The Vite config includes heavy Node.js polyfills (`stream`, `zlib`, `buffer`, `process`) which bloat the bundle. Many polyfills exist only because of legacy dependencies like React Scripts or old packages.

### 5.7 React 16 `scheduler` Override
```json
"overrides": {
  "scheduler": "0.19.1"
}
```
Pinning the scheduler version can cause subtle React bugs — this should be investigated and removed if possible.

---

## 6. 📊 Improvement Roadmap

### Phase 1: Security & Stability (Critical — Do First)

| # | Task | Impact | Effort |
|---|---|---|---|
| 1 | Move JWT secret, Cloudinary keys, DB passwords to `.env` | 🔴 Critical | 1-2 days |
| 2 | Set up proper environment variable loading with `dotenv` | 🔴 Critical | 2-4 hours |
| 3 | Rotate all exposed secrets (Cloudinary, DB passwords) | 🔴 Critical | 1 hour |
| 4 | Remove hardcoded credentials from config.json, use env vars | 🔴 Critical | 1 day |
| 5 | Implement proper error handling middleware | 🟠 High | 1 day |
| 6 | Add rate limiting (express-rate-limit) | 🟠 High | 2-4 hours |

### Phase 2: Code Quality & Maintainability

| # | Task | Impact | Effort |
|---|---|---|---|
| 7 | Remove all commented-out code via a thorough codebase clean | 🟠 High | 2-3 days |
| 8 | Consolidate dual auth systems into unified JWT auth | 🟠 High | 3-5 days |
| 9 | Add TypeScript incrementally (start with shared types) | 🟡 Medium | Ongoing |
| 10 | Set up ESLint + Prettier and enforce consistency | 🟡 Medium | 1 day |
| 11 | Split large controllers (account.js, transactions.js) | 🟡 Medium | 3-5 days |
| 12 | Remove duplicate/stale files | 🟡 Medium | 1 day |

### Phase 3: Testing & Reliability

| # | Task | Impact | Effort |
|---|---|---|---|
| 13 | Set up test framework (Jest + Supertest) | 🟠 High | 2-3 days |
| 14 | Add unit tests for critical controllers & reducers | 🟠 High | 5-10 days |
| 15 | Add integration tests for key API endpoints | 🟡 Medium | 3-5 days |
| 16 | Set up CI/CD pipeline (GitHub Actions) | 🟡 Medium | 1-2 days |
| 17 | Add input validation with express-validator or Joi | 🟡 Medium | 3-5 days |

### Phase 4: Modernization

| # | Task | Impact | Effort |
|---|---|---|---|
| 18 | Upgrade React 16 → 18 (or 19) | 🟡 Medium | 3-5 days |
| 19 | Upgrade Bootstrap 4 → 5 | 🔵 Low | 2-3 days |
| 20 | Fix backend Dockerfile (use Alpine Node LTS) | 🟡 Medium | 2-4 hours |
| 21 | Audit and remove unused dependencies | 🔵 Low | 1-2 days |
| 22 | Implement API standardization (response envelope) | 🔵 Low | 2-3 days |
| 23 | Set up API documentation auto-generation | 🔵 Low | 1-2 days |

### Phase 5: Features & Performance

| # | Task | Impact | Effort |
|---|---|---|---|
| 24 | Add API caching (Redis) for frequently accessed data | 🔵 Low | 2-3 days |
| 25 | Implement pagination standardization across all list endpoints | 🟡 Medium | 3-5 days |
| 26 | Add request logging middleware with correlation IDs | 🔵 Low | 1 day |
| 27 | Set up monitoring (Sentry or similar for error tracking) | 🟡 Medium | 1-2 days |

---

## 7. 🏗️ Architecture Assessment

### Strengths
- **Well-organized module structure**: Components are organized by domain (dental, pharmacy, lab, etc.)
- **Comprehensive feature set**: Covers nearly all aspects of dental practice management
- **Modern build tooling**: Successfully migrated to Vite (modern, fast)
- **Good use of containerization**: Dockerfiles exist for both frontend and backend
- **Real-time capabilities**: Socket.io integration (even if currently commented out)
- **DICOM integration**: Radiology imaging support with OHIF Viewer and Orthanc
- **Granular permissions system**: Role-based access control with detailed permissions

### Weaknesses
- **Security debt**: Hardcoded secrets are the most critical issue
- **Test debt**: Essentially no automated tests for a large production system
- **Technical debt**: Large amounts of dead code, outdated dependencies
- **Consistency debt**: Inconsistent coding patterns, error handling, and API responses
- **Architecture debt**: Monolithic controllers, dual auth systems

---

## 8. 📝 Quick Wins (Can Be Done in < 1 Hour Each)

1. **Delete commented-out code blocks** in `backend/app.js`, `backend/config/passserport.js`
2. **Remove duplicate files**: `pharm-new 2.js`, `saved--lab.js`
3. **Move `.sql` files** from `backend/controller/` to `backend/sql/`
4. **Remove unused dependencies** from `package.json` (PouchDB, firebase, request)
5. **Fix Dockerfile** base image for backend (use `node:20-alpine`)
6. **Add `.nvmrc`** with Node.js version for the project
7. **Consolidate `uuid` packages**: Remove `uuidv4` and `cuid`, keep only `uuid`
8. **Remove `react-scripts`** from frontend dependencies since Vite is the build tool

---

## 9. 💡 Technology Suggestions

### Recommended Upgrades

| Current | Recommended | Reason |
|---|---|---|
| React 16 | React 18+ | Concurrent features, automatic batching, better hooks |
| Bootstrap 4 | Bootstrap 5 + reactstrap 9 | Modern, no jQuery dependency, better utilities |
| Chart.js 2 | Recharts (already included) or Chart.js 4 | Already have recharts dependency |
| Sequelize 5 | Sequelize 6+ | Better TypeScript support, performance improvements |
| Express 4.16 | Express 4.18+ | Security fixes, better error handling |
| Node.js (various) | LTS (20 or 22) | Consistent environment, latest features |

### New Libraries to Consider

| Purpose | Recommendation |
|---|---|
| **Validation** | Zod (TypeScript-native) or Joi |
| **API Client** | Already using Axios ✓ |
| **Testing** | Vitest (Vite-native) + Testing Library |
| **Error Tracking** | Sentry |
| **API Documentation** | Swagger/OpenAPI auto-generation from Zod schemas |
| **Caching** | Redis with ioredis |
| **Background Jobs** | Bull (Redis-backed) |
| **Monitoring** | PM2 (process manager) + express-status-monitor |

---

*This analysis was generated through automated codebase review. Priority classifications (🔴 Critical, 🟠 High, 🟡 Medium, 🔵 Low) reflect general severity — actual priority should be evaluated based on current deployment status, user base, and business requirements.*
