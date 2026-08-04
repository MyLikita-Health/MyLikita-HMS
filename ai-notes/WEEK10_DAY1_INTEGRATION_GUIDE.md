# Week 10 Day 1 Integration Guide
## Connecting Analytics to the Application

**Status**: Ready to Integrate  
**Time Required**: 30 minutes

---

## Integration Steps

### Step 1: Register Analytics Routes in app.js

Add to `backend/app.js`:

```javascript
// Add after other radiology routes
const radiologyAnalyticsRoutes = require('./routes/radiology-analytics');
app.use('/radiology/analytics', radiologyAnalyticsRoutes);
```

### Step 2: Create Analytics Directory

```bash
mkdir -p frontend/src/components/radiology/analytics
```

### Step 3: Add Analytics to RadiologyRouter

Update `frontend/src/components/radiology/RadiologyRouter.jsx`:

```javascript
import AnalyticsDashboard from './analytics/AnalyticsDashboard';

// Add route
<Route path="/analytics" element={<AnalyticsDashboard />} />
```

### Step 4: Add Navigation Link

Update navigation to include analytics link:

```javascript
<Link to="/radiology/analytics">Analytics</Link>
```

### Step 5: Create Database Procedures

Run the SQL procedures:

```bash
mysql -u root prime < backend/sql/radiology_analytics_procedures.sql
```

### Step 6: Test Endpoints

```bash
# Test dashboard endpoint
curl http://localhost:46990/radiology/analytics/dashboard?facilityId=1&startDate=2026-03-01&endDate=2026-03-11

# Test radiologist metrics
curl http://localhost:46990/radiology/analytics/metrics/radiologist?radiologistId=1&startDate=2026-03-01&endDate=2026-03-11
```

---

## Verification Checklist

- [ ] Routes registered in app.js
- [ ] Analytics directory created
- [ ] Components in place
- [ ] RadiologyRouter updated
- [ ] Navigation link added
- [ ] Database procedures created
- [ ] API endpoints responding
- [ ] Dashboard rendering
- [ ] Metrics displaying
- [ ] Charts rendering

---

## Troubleshooting

### Routes Not Found
```bash
# Check if routes are registered
grep -n "radiology-analytics" backend/app.js

# Restart backend
pkill -f "node.*app.js"
cd backend && npm start &
```

### Database Procedures Error
```bash
# Check procedures
mysql -u root prime -e "SHOW PROCEDURE STATUS WHERE db='prime';"

# Re-run procedures
mysql -u root prime < backend/sql/radiology_analytics_procedures.sql
```

### Dashboard Not Loading
```bash
# Check browser console for errors
# Check network tab for failed requests
# Verify authentication token
# Check API response
curl http://localhost:46990/radiology/analytics/dashboard?facilityId=1&startDate=2026-03-01&endDate=2026-03-11
```

---

## Next Steps

After integration:

1. Run Day 2 tasks
2. Implement productivity metrics
3. Create productivity report
4. Optimize queries

---

**Status**: Ready to Integrate  
**Estimated Time**: 30 minutes  
**Next**: Day 2 Implementation
