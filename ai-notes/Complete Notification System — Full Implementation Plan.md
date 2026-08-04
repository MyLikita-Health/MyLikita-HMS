## Complete Notification System — Full Implementation Plan

### What Already Exists (Leverage These)

- **Socket.io** is already running in `app.js` with facility rooms (`facility_${facilityId}`)
- `backend/services/notifications.js` exists but is primitive (broadcasts to all, no persistence)
- `frontend/src/utils/socket.js` — singleton socket client already set up
- Users table has `accessTo` (array of module permissions) and `role` fields

---

### Layer 1 — Database (Migration)

**3 new tables:**

```sql
-- Notification events (one row per event fired)
sys_notifications (
  id, facilityId, event_type, title, message, icon,
  priority ENUM('low','normal','high','urgent'),
  payload JSON,        -- { patient_id, patient_name, etc. }
  action_url,          -- /me/nurse or /me/records etc.
  created_by, created_at
)

-- Per-user delivery tracking
sys_notification_recipients (
  id, notification_id, user_id, facilityId,
  status ENUM('pending','delivered','accepted'),
  delivered_at, accepted_at
)

-- Admin-configurable rules (which events → which roles)
sys_notification_rules (
  id, facilityId, event_type, label, description,
  target_roles JSON,        -- ["Nurse", "Records"]
  target_permissions JSON,  -- accessTo values like ["Theatre"]
  is_active, sound_enabled, created_at
)
```

---

### Layer 2 — Backend Notification Service

**`backend/services/notificationService.js`** — the single entry point for all notifications:

```javascript
async function send(app, { facilityId, event_type, title, message, icon, priority, payload, action_url, created_by }) {
  // 1. Look up the rule for this event_type
  const rule = await getRule(facilityId, event_type);
  if (!rule || !rule.is_active) return;

  // 2. Find all target users (by role OR by accessTo permission)
  const recipients = await resolveRecipients(facilityId, rule);

  // 3. Save notification to DB
  const notifId = await saveNotification({ facilityId, event_type, title, message, icon, priority, payload, action_url, created_by });

  // 4. Save per-user recipient rows
  for (const user of recipients) {
    await saveRecipient(notifId, user.id, facilityId);
  }

  // 5. Emit via Socket.io to online users in the facility room
  const io = app.get('io');
  for (const user of recipients) {
    io.to(`user_${user.id}`).emit('sys_notification', {
      id: notifId, event_type, title, message, icon, priority,
      payload, action_url, sound: rule.sound_enabled,
    });
  }
}
```

**Recipient resolution logic:**
```javascript
async function resolveRecipients(facilityId, rule) {
  // Query users table: match by role OR by accessTo containing any of target_permissions
  // rule.target_roles = ["Nurse"] → users WHERE role = 'Nurse'
  // rule.target_permissions = ["Theatre"] → users WHERE JSON_CONTAINS(accessTo, '"Theatre"')
  // Combine with OR, deduplicate
}
```

**Default rules seeded on first run** (9 events from your list + extensible):

| event_type | label | target_roles | target_permissions |
|---|---|---|---|
| `new_inpatient_medication` | New Medication for In-Patient | `["Nurse"]` | `["Nurse"]` |
| `patient_added_to_waitlist` | Patient Added to Waiting List | `["Doctors"]` | `["Doctors"]` |
| `patient_added_to_specialist_queue` | Patient Added to Specialist Queue | `[]` | `[]` (resolved dynamically to specific specialist) |
| `new_nursing_task` | New Nursing Task | `["Nurse"]` | `["Nurse"]` |
| `surgery_planned` | Surgery Planned | `[]` | `["Theater"]` |
| `patient_admitted` | Patient Admitted | `["Records"]` | `["Records"]` |
| `await_specialist` | Patient Awaiting Specialist | `["Admin"]` | `["Admin"]` |
| `patient_discharged` | Patient Discharged | `["Records"]` | `["Records"]` |
| `new_bill` | New Bill Created | `["Cashier"]` | `["Accounts"]` |

---

### Layer 3 — Trigger Points (Where to Call `notificationService.send`)

Each of the 9 events maps to an existing backend location:

1. **New medication for in-patient** → `backend/controller/diagnosis.js` `consultationRecord()` — when `prescriptionRequest` is non-empty and patient is admitted
2. **Patient added to waiting list** → `backend/controller/patientrecords.js` or wherever `assignpatient` is called
3. **Patient added to specialist queue** → `backend/controller/diagnosis.js` when `managementPlan.patientStatus = 'await-specialist'`
4. **New nursing task** → `backend/controller/nursing-service-requests.js` `createNursingServiceRequests()` (just built) + `backend/controller/nursingFeatures.js` `manageTask()`
5. **Surgery planned** → `backend/controller/diagnosis.js` when `managementPlan.patientStatus = 'plan-surgery'`
6. **Patient admitted** → `backend/controller/diagnosis.js` when `managementPlan.patientStatus = 'admit'`
7. **Await specialist** → `backend/controller/diagnosis.js` when `managementPlan.patientStatus = 'await-specialist'`
8. **Patient discharged** → `backend/controller/diagnosis.js` when `managementPlan.patientStatus = 'discharge'`
9. **New bill** → `backend/controller/transactions.js` or wherever `pending_txn` is inserted

---

### Layer 4 — Socket.io Enhancement

Currently the server emits to `facility_${facilityId}` rooms (all users in a facility). We need **per-user rooms** so notifications go to specific users:

In `app.js`, when a socket connects and joins a facility room, also join a user room:
```javascript
socket.on('join_facility', (facilityId) => {
  socket.join(`facility_${facilityId}`);
});
// Add this new event:
socket.on('join_user', (userId) => {
  socket.join(`user_${userId}`);
});
```

Frontend: after login, emit both `join_facility` and `join_user`.

---

### Layer 5 — Backend API Routes

```
GET  /notifications?facilityId=&user_id=&status=pending   — fetch unread history
PUT  /notifications/:id/accept                             — mark as accepted
GET  /notifications/unread-count?user_id=&facilityId=     — bell badge count
GET  /admin/notification-rules?facilityId=                 — list rules
PUT  /admin/notification-rules/:id                         — update rule (toggle, change targets)
POST /admin/notification-rules                             — add new rule
```

---

### Layer 6 — Frontend Components

**6.1 `NotificationProvider` (React Context)**

Wraps `AuthenticatedContainer`. On mount:
- Connects socket, joins `user_${userId}` room
- Fetches unread notifications from API (for offline-received ones)
- Listens for `sys_notification` socket event
- Maintains state: `{ queue: [], unreadCount: 0 }`

When a `sys_notification` arrives:
- Add to queue
- Play sound (Web Audio API — a short chime, no external library needed)
- Show the modal popup

**6.2 `NotificationModal` (the persistent popup)**

```
┌─────────────────────────────────────────┐
│  🔔  [URGENT]                           │
│                                         │
│  New Medication for In-Patient          │
│                                         │
│  Dr. Abdurrahman prescribed Amoxicillin │
│  for patient Fatima Musa (Ward 2)       │
│                                         │
│  [View Patient]        [✓ Accept]       │
└─────────────────────────────────────────┘
```

Key behaviors:
- **Does NOT auto-dismiss** — only the Accept button removes it
- If multiple notifications arrive, they **stack** (queue) — each must be accepted individually
- Sound plays on each new notification
- Clicking "View Patient" navigates to `action_url` AND accepts
- On Accept: calls `PUT /notifications/:id/accept`, removes from queue

**6.3 `NotificationBell` (nav bar)**

- Shows bell icon with red badge showing unread count
- Clicking opens `NotificationHistory` panel
- Count updates in real-time via socket + on page load

**6.4 `NotificationHistory` panel**

- Slide-in panel from the right
- Lists all notifications (newest first)
- Unread ones highlighted
- Each has Accept button if not yet accepted
- Filter by type/date

**6.5 Admin: `NotificationRulesManager`**

In `/me/admin` → new "Notifications" tab:
- Table of all rules with toggle (enable/disable)
- Edit target roles/permissions per rule
- Add new custom rules
- Sound on/off per rule

---

### Layer 7 — Sound Implementation

No external library needed. Use the Web Audio API to generate a short notification chime:

```javascript
// frontend/src/utils/notificationSound.js
export function playNotificationSound(priority = 'normal') {
  const ctx = new (window.AudioContext || window.webkitAudioContext)();
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.connect(gain);
  gain.connect(ctx.destination);
  
  // Different tones for different priorities
  const freq = priority === 'urgent' ? 880 : priority === 'high' ? 660 : 440;
  osc.frequency.setValueAtTime(freq, ctx.currentTime);
  osc.frequency.setValueAtTime(freq * 1.2, ctx.currentTime + 0.1);
  
  gain.gain.setValueAtTime(0.3, ctx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5);
  
  osc.start(ctx.currentTime);
  osc.stop(ctx.currentTime + 0.5);
}
```

For urgent notifications, play twice with a short gap.

---

### Layer 8 — Integration Points Summary

| Where to add `notificationService.send()` | File | Condition |
|---|---|---|
| Prescription submitted for in-patient | `diagnosis.js` `consultationRecord` | `patientStatus === 'admit'` AND prescriptions exist |
| Patient assigned to waiting list | `assignpatient.js` or `patientrecords.js` | On new assignment |
| Specialist queue | `diagnosis.js` | `patientStatus === 'await-specialist'` |
| Nursing task created | `nursingFeatures.js` `manageTask` + `nursing-service-requests.js` | On insert |
| Surgery planned | `diagnosis.js` | `patientStatus === 'plan-surgery'` |
| Patient admitted | `diagnosis.js` | `patientStatus === 'admit'` |
| Await specialist | `diagnosis.js` | `patientStatus === 'await-specialist'` |
| Patient discharged | `diagnosis.js` | `patientStatus === 'discharge'` |
| New bill | `transactions.js` or `charges.js` | On `pending_txn` insert |

---

### Implementation Sequence

| Step | What | Files |
|---|---|---|
| 1 | Migration — 3 new tables | `migrations/20260507000001-notification-system.js` |
| 2 | Seed default rules | Same migration |
| 3 | `notificationService.js` | `backend/services/notificationService.js` |
| 4 | Socket.io per-user rooms | `backend/app.js` |
| 5 | Notification API routes + controller | `backend/routes/notifications.js` + `backend/controller/notifications.js` |
| 6 | Wire triggers into existing controllers | `diagnosis.js`, `nursingFeatures.js`, etc. |
| 7 | `notificationSound.js` | `frontend/src/utils/notificationSound.js` |
| 8 | `NotificationProvider` + context | `frontend/src/context/NotificationContext.jsx` |
| 9 | `NotificationModal` | `frontend/src/components/notifications/NotificationModal.jsx` |
| 10 | `NotificationBell` + `NotificationHistory` | `frontend/src/components/notifications/` |
| 11 | Wire `NotificationProvider` into `AuthenticatedContainer` | `frontend/src/routes/AuthenticatedContainer.jsx` |
| 12 | Add bell to nav bar | `frontend/src/components/nav/nav-modules.jsx` |
| 13 | Admin rules manager | `frontend/src/components/admin/NotificationRules.jsx` |

---

Ready to implement? I'll start with Step 1 (migration + seed) and work through all 13 steps. Say **go** and I'll begin.