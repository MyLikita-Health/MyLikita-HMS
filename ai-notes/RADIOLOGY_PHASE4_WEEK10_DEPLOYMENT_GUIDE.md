# Week 10 Deployment Guide - Production Ready

**Status**: ✅ READY FOR DEPLOYMENT  
**Date**: March 11, 2026  
**Version**: 1.0.0

## Pre-Deployment Checklist

### Code Quality
- ✅ All files pass syntax validation
- ✅ No compilation errors
- ✅ Error handling complete
- ✅ Input validation implemented
- ✅ Security best practices followed

### Testing
- ✅ API endpoints tested
- ✅ Frontend components tested
- ✅ Database procedures tested
- ✅ Integration tests passed
- ✅ Performance tests passed
- ✅ Security tests passed

### Documentation
- ✅ API documentation complete
- ✅ Deployment guide written
- ✅ User guide created
- ✅ Troubleshooting guide prepared
- ✅ Architecture documented

### Infrastructure
- ✅ Database server ready
- ✅ Backend server ready
- ✅ Frontend server ready
- ✅ File storage configured
- ✅ Backup system ready

## Deployment Steps

### Step 1: Database Migration (10 minutes)

```bash
# Connect to MySQL
mysql -u root -p prime

# Run analytics procedures
SOURCE backend/sql/radiology_analytics_procedures.sql;

# Run productivity procedures
SOURCE backend/sql/radiology_productivity_procedures.sql;

# Run equipment procedures
SOURCE backend/sql/radiology_equipment_procedures.sql;

# Run export schema
SOURCE backend/sql/radiology_export_schema.sql;

# Verify procedures created
SHOW PROCEDURE STATUS WHERE db='prime';
```

### Step 2: Backend Deployment (15 minutes)

```bash
# Navigate to backend directory
cd backend

# Install dependencies (if needed)
npm install

# Verify environment variables
cat .env

# Start backend server
npm start

# Verify server started
curl http://localhost:46990/

# Expected: Welcome message with app info
```

### Step 3: Frontend Deployment (15 minutes)

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies (if needed)
npm install

# Build production bundle
npm run build

# Verify build successful
ls -la dist/

# Deploy to web server
# Copy dist/ contents to web server root
```

### Step 4: Route Registration (5 minutes)

Routes are already registered in `backend/app.js`:
```javascript
app.use('/radiology', require('./routes/radiology-analytics'))
app.use('/radiology', require('./routes/radiology-productivity'))
app.use('/radiology', require('./routes/radiology-equipment'))
app.use('/radiology', require('./routes/radiology-export'))
```

### Step 5: Health Check (10 minutes)

```bash
# Test analytics endpoint
curl -X GET "http://localhost:46990/radiology/analytics/dashboard?facilityId=1&startDate=2026-02-09&endDate=2026-03-11" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test productivity endpoint
curl -X GET "http://localhost:46990/radiology/productivity/metrics?radiologistId=1&startDate=2026-02-09&endDate=2026-03-11" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test equipment endpoint
curl -X GET "http://localhost:46990/radiology/equipment/utilization/1?startDate=2026-02-09&endDate=2026-03-11" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test export endpoint
curl -X POST "http://localhost:46990/radiology/export/analytics" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"facilityId": 1, "dateRange": {"start": "2026-02-09", "end": "2026-03-11"}, "format": "csv"}'
```

### Step 6: Smoke Tests (10 minutes)

```bash
# Test all analytics endpoints
# Test all productivity endpoints
# Test all equipment endpoints
# Test all export endpoints
# Verify response times
# Verify error handling
```

## Rollback Procedure

If deployment fails, follow these steps:

### Step 1: Stop Services
```bash
# Stop backend
pkill -f "node.*app.js"

# Stop frontend (if applicable)
# Depends on your web server
```

### Step 2: Restore Previous Version
```bash
# Restore backend from backup
git checkout HEAD~1 backend/

# Restore frontend from backup
git checkout HEAD~1 frontend/

# Restore database from backup
mysql -u root -p prime < backup_database.sql
```

### Step 3: Restart Services
```bash
# Restart backend
cd backend && npm start

# Restart frontend
# Depends on your web server
```

### Step 4: Verify Rollback
```bash
# Test endpoints
# Verify data integrity
# Check error logs
```

## Post-Deployment Monitoring

### First Hour
- Monitor error logs
- Check API response times
- Verify database connections
- Monitor memory usage
- Check CPU usage

### First Day
- Monitor error rates
- Check user feedback
- Verify data accuracy
- Monitor performance metrics
- Check backup completion

### First Week
- Analyze usage patterns
- Monitor performance trends
- Check for memory leaks
- Verify backup integrity
- Review error logs

## Performance Monitoring

### Key Metrics
- API response time: Target < 500ms
- Frontend load time: Target < 2s
- Database query time: Target < 200ms
- Error rate: Target < 0.1%
- Uptime: Target > 99.9%

### Monitoring Tools
- Application Performance Monitoring (APM)
- Error tracking (Sentry, etc.)
- Log aggregation (ELK, etc.)
- Metrics collection (Prometheus, etc.)
- Uptime monitoring (Pingdom, etc.)

## Troubleshooting

### Backend Issues

**Issue**: Backend won't start
```
Solution:
1. Check Node.js version (v14+)
2. Check npm dependencies
3. Check environment variables
4. Check database connection
5. Check port availability
```

**Issue**: API endpoints return 500 error
```
Solution:
1. Check backend logs
2. Check database connection
3. Check stored procedures
4. Check input validation
5. Check error handling
```

### Frontend Issues

**Issue**: Frontend won't load
```
Solution:
1. Check web server configuration
2. Check file permissions
3. Check CORS settings
4. Check API endpoint URLs
5. Check browser console
```

**Issue**: Components not rendering
```
Solution:
1. Check browser console
2. Check API responses
3. Check component props
4. Check state management
5. Check CSS loading
```

### Database Issues

**Issue**: Procedures not executing
```
Solution:
1. Verify procedures created
2. Check procedure syntax
3. Check parameter types
4. Check database permissions
5. Check connection pooling
```

**Issue**: Slow queries
```
Solution:
1. Check query execution plan
2. Verify indexes exist
3. Check table statistics
4. Monitor slow query log
5. Optimize queries
```

## Backup & Recovery

### Backup Procedure
```bash
# Daily backup
mysqldump -u root -p prime > backup_$(date +%Y%m%d).sql

# Backup file storage
# Store in secure location
# Verify backup integrity
```

### Recovery Procedure
```bash
# Restore from backup
mysql -u root -p prime < backup_YYYYMMDD.sql

# Verify data integrity
# Check record counts
# Verify calculations
```

## Security Checklist

- ✅ Authentication required for all endpoints
- ✅ Authorization enforced
- ✅ Input validation implemented
- ✅ SQL injection prevention
- ✅ XSS prevention
- ✅ CORS configured
- ✅ Rate limiting ready
- ✅ SSL/TLS enabled
- ✅ Secrets management
- ✅ Audit logging

## Support & Escalation

### Level 1 Support
- Check error logs
- Verify configuration
- Test endpoints
- Check database

### Level 2 Support
- Review code
- Check performance metrics
- Analyze database queries
- Review security logs

### Level 3 Support
- Code review
- Architecture review
- Performance optimization
- Security audit

## Success Criteria

✅ All endpoints responding
✅ All data displaying correctly
✅ Performance within targets
✅ No error logs
✅ Users can access features
✅ Exports generating correctly
✅ Schedules working
✅ Mobile responsive

## Sign-Off

- [ ] Database migration complete
- [ ] Backend deployed
- [ ] Frontend deployed
- [ ] Health checks passed
- [ ] Smoke tests passed
- [ ] Performance verified
- [ ] Security verified
- [ ] Documentation complete
- [ ] Team trained
- [ ] Go-live approved

---

**Status**: ✅ READY FOR PRODUCTION  
**Deployment Date**: March 11, 2026  
**Version**: 1.0.0
