# Dental EMR - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Database Setup (2 minutes)
```bash
cd /Users/mac/Documents/projects/mylikita/dental/backend/sql

# Run clinical workflow tables
mysql -u root -p your_database < phase2_clinical_workflow.sql

# Run appointments system
mysql -u root -p your_database < dental_appointments_system.sql
```

### Step 2: Add Redux Reducer (1 minute)
Edit `frontend/src/redux/reducers/index.js`:
```javascript
import dental from './dental';

export default combineReducers({
  // ... existing reducers
  dental,  // Add this line
});
```

### Step 3: Grant User Access (1 minute)
```sql
-- Grant dental access to your user
UPDATE users 
SET accessTo = JSON_ARRAY_APPEND(accessTo, '$', 'Dental') 
WHERE username = 'your-username';
```

### Step 4: Start Application (1 minute)
```bash
# Backend (if not running)
cd backend
npm start

# Frontend (if not running)
cd frontend
npm start
```

### Step 5: Access Dental Module
1. Login to the application
2. Navigate to: `http://localhost:3000/me/dental`
3. You should see the dental module with walk-in queue!

---

## 📋 Quick Test

### Test Walk-in Registration
```bash
curl -X POST http://localhost:3001/dental/walkin/register \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "TEST-001",
    "facilityId": "your-facility-id",
    "chief_complaint": "Tooth pain",
    "priority": "normal"
  }'
```

### Test Appointment Creation
```bash
curl -X POST http://localhost:3001/dental/appointments/create \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "TEST-001",
    "facilityId": "your-facility-id",
    "dentist_id": "your-dentist-id",
    "appointment_type": "consultation",
    "appointment_date": "2026-02-10T10:00:00",
    "duration_minutes": 30,
    "source": "admin"
  }'
```

---

## 🎯 Key URLs

- **Dental Module:** `/me/dental`
- **API Base:** `http://localhost:3001`
- **Documentation:** See `IMPLEMENTATION_COMPLETE.md`

---

## 🆘 Troubleshooting

### Issue: "Dental" not showing in menu
**Solution:** Check user access permissions in database

### Issue: API errors
**Solution:** Verify backend is running on port 3001

### Issue: Components not loading
**Solution:** Check Redux reducer is added to root reducer

### Issue: Database errors
**Solution:** Verify SQL files were executed successfully

---

## 📚 Next Steps

1. ✅ Test walk-in registration
2. ✅ Test medical history form
3. ✅ Test examination recording
4. ✅ Test clinical decision
5. ✅ Test appointment booking
6. ✅ Train staff on new system
7. ✅ Go live!

---

*Quick Start Guide v1.0*
*February 8, 2026*
