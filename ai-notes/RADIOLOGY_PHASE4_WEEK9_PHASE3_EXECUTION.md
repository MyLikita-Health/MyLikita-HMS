# Radiology Phase 4 - Week 9 Phase 3 Execution
## Production Deployment & Monitoring Setup

**Date**: March 11, 2026  
**Phase**: 3 of 3  
**Duration**: 2 hours  
**Status**: Ready to Execute

---

## Phase 3 Overview

### Objectives
1. Code review and validation
2. Staging deployment
3. Production deployment
4. Monitoring and alerting setup
5. Documentation and handover

### Timeline
- **Day 8**: Code review (1 hour)
- **Day 9**: Staging deployment (1 hour)
- **Day 10**: Production deployment & monitoring (2 hours)

### Success Criteria
- ✅ Code reviewed and approved
- ✅ Staging deployment successful
- ✅ Production deployment successful
- ✅ Monitoring active
- ✅ All systems operational

---

## Day 8: Code Review (1 hour)

### Task 1: Code Quality Review (20 minutes)

**Objective**: Verify code quality and best practices

**Files to Review**:
1. `backend/controller/radiology-worklist.js` (380 lines)
2. `backend/controller/radiology-dicom-webhook.js` (320 lines)
3. `backend/routes/radiology-worklist.js` (100 lines)
4. `backend/services/orthancClient.js` (150 lines)

**Review Checklist**:
- [ ] Code follows project conventions
- [ ] Proper error handling implemented
- [ ] Input validation present
- [ ] SQL injection prevention
- [ ] Transaction support verified
- [ ] Logging implemented
- [ ] Comments and documentation present
- [ ] No hardcoded values
- [ ] Environment variables used
- [ ] Security best practices followed

**Commands**:
```bash
# Check code syntax
node -c backend/controller/radiology-worklist.js
node -c backend/controller/radiology-dicom-webhook.js
node -c backend/routes/radiology-worklist.js
node -c backend/services/orthancClient.js

# Check for common issues
grep -n "TODO\|FIXME\|HACK" backend/controller/radiology-*.js
grep -n "console.log" backend/controller/radiology-*.js
```

**Status**: ⏳ Ready to Execute

---

### Task 2: Security Review (15 minutes)

**Objective**: Verify security implementation

**Security Checklist**:
- [ ] Authentication required on all endpoints (except webhooks)
- [ ] Authorization checks implemented
- [ ] Input validation present
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] CSRF protection
- [ ] Rate limiting considered
- [ ] Sensitive data not logged
- [ ] Error messages don't leak information
- [ ] Dependencies are up to date

**Commands**:
```bash
# Check for security issues
grep -n "password\|secret\|token" backend/controller/radiology-*.js | grep -v "// "
grep -n "eval\|exec" backend/controller/radiology-*.js
grep -n "require.*eval" backend/controller/radiology-*.js

# Check npm vulnerabilities
npm audit
```

**Status**: ⏳ Ready to Execute

---

### Task 3: Performance Review (15 minutes)

**Objective**: Verify performance optimization

**Performance Checklist**:
- [ ] Database queries optimized
- [ ] Indexes present on frequently queried columns
- [ ] No N+1 queries
- [ ] Caching implemented where appropriate
- [ ] Response times acceptable (< 500ms)
- [ ] Pagination implemented for large datasets
- [ ] Connection pooling configured
- [ ] Memory leaks prevented
- [ ] Async/await used properly
- [ ] No blocking operations

**Commands**:
```bash
# Check for performance issues
grep -n "SELECT \*" backend/controller/radiology-*.js
grep -n "for.*for" backend/controller/radiology-*.js
grep -n "while.*while" backend/controller/radiology-*.js

# Check database indexes
mysql -u root prime -e "SHOW INDEXES FROM radiology_modalities;"
mysql -u root prime -e "SHOW INDEXES FROM radiology_worklist;"
mysql -u root prime -e "SHOW INDEXES FROM radiology_requests;"
```

**Status**: ⏳ Ready to Execute

---

### Task 4: Documentation Review (10 minutes)

**Objective**: Verify documentation completeness

**Documentation Checklist**:
- [ ] API endpoints documented
- [ ] Request/response examples provided
- [ ] Error codes documented
- [ ] Database schema documented
- [ ] Configuration documented
- [ ] Deployment procedures documented
- [ ] Troubleshooting guide provided
- [ ] Code comments present
- [ ] README updated
- [ ] CHANGELOG updated

**Status**: ⏳ Ready to Execute

---

## Day 9: Staging Deployment (1 hour)

### Task 1: Pre-Deployment Verification (10 minutes)

**Objective**: Verify staging environment readiness

**Checklist**:
- [ ] Staging database exists
- [ ] Staging Orthanc configured
- [ ] Staging backend environment variables set
- [ ] Staging firewall rules configured
- [ ] Staging backups configured
- [ ] Staging monitoring configured

**Commands**:
```bash
# Verify staging database
mysql -u root prime -e "SELECT COUNT(*) FROM radiology_modalities;"

# Verify staging Orthanc
curl -X GET http://localhost:8042/system

# Verify staging backend
curl -X POST http://localhost:46990/radiology/webhook/test
```

**Status**: ⏳ Ready to Execute

---

### Task 2: Deploy to Staging (30 minutes)

**Objective**: Deploy code to staging environment

**Steps**:

1. **Backup Current Code**:
```bash
# Create backup
cp -r backend backend.backup.$(date +%Y%m%d_%H%M%S)

# Verify backup
ls -la backend.backup.*
```

2. **Deploy New Code**:
```bash
# Copy new files
cp backend/controller/radiology-worklist.js backend/controller/radiology-worklist.js.new
cp backend/controller/radiology-dicom-webhook.js backend/controller/radiology-dicom-webhook.js.new
cp backend/routes/radiology-worklist.js backend/routes/radiology-worklist.js.new
cp backend/services/orthancClient.js backend/services/orthancClient.js.new

# Verify files
ls -la backend/controller/radiology-*.js.new
```

3. **Restart Backend**:
```bash
# Stop backend
pkill -f "node.*app.js"

# Wait for shutdown
sleep 2

# Start backend
cd backend && npm start &

# Wait for startup
sleep 5

# Verify running
curl -X POST http://localhost:46990/radiology/webhook/test
```

**Status**: ⏳ Ready to Execute

---

### Task 3: Staging Testing (15 minutes)

**Objective**: Run comprehensive tests in staging

**Test Suite**:
```bash
# Run all tests
bash test-phase2.sh

# Expected: All tests passing
```

**Verification**:
```bash
# Check logs
tail -50 backend.log

# Check database
mysql -u root prime -e "SELECT COUNT(*) FROM radiology_modalities;"
mysql -u root prime -e "SELECT COUNT(*) FROM radiology_worklist;"

# Check Orthanc
curl -X GET http://localhost:8042/system | jq '.Version'
```

**Status**: ⏳ Ready to Execute

---

### Task 4: Staging Approval (5 minutes)

**Objective**: Get approval to proceed to production

**Approval Checklist**:
- [ ] Code review passed
- [ ] Security review passed
- [ ] Performance review passed
- [ ] All staging tests passing
- [ ] No errors in logs
- [ ] Stakeholders notified
- [ ] Rollback plan ready

**Status**: ⏳ Ready to Execute

---

## Day 10: Production Deployment (2 hours)

### Task 1: Pre-Deployment Preparation (15 minutes)

**Objective**: Prepare for production deployment

**Checklist**:
- [ ] Production database backed up
- [ ] Production code backed up
- [ ] Production Orthanc backed up
- [ ] Maintenance window scheduled
- [ ] Team notified
- [ ] Rollback plan documented
- [ ] Monitoring configured
- [ ] Alerting configured

**Commands**:
```bash
# Backup production database
mysqldump -u root prime > prime_backup_$(date +%Y%m%d_%H%M%S).sql

# Backup production code
cp -r backend backend.prod.backup.$(date +%Y%m%d_%H%M%S)

# Verify backups
ls -la prime_backup_*.sql
ls -la backend.prod.backup.*
```

**Status**: ⏳ Ready to Execute

---

### Task 2: Production Deployment (30 minutes)

**Objective**: Deploy to production

**Steps**:

1. **Notify Users**:
```bash
# Send notification
echo "Production deployment starting. System will be unavailable for ~5 minutes."
```

2. **Stop Backend**:
```bash
# Stop backend gracefully
pkill -SIGTERM -f "node.*app.js"

# Wait for shutdown
sleep 5

# Verify stopped
lsof -i :46990 || echo "Backend stopped"
```

3. **Deploy Code**:
```bash
# Copy new files
cp backend/controller/radiology-worklist.js backend/controller/radiology-worklist.js.prod
cp backend/controller/radiology-dicom-webhook.js backend/controller/radiology-dicom-webhook.js.prod
cp backend/routes/radiology-worklist.js backend/routes/radiology-worklist.js.prod
cp backend/services/orthancClient.js backend/services/orthancClient.js.prod

# Verify files
ls -la backend/controller/radiology-*.js.prod
```

4. **Start Backend**:
```bash
# Start backend
cd backend && npm start &

# Wait for startup
sleep 5

# Verify running
curl -X POST http://localhost:46990/radiology/webhook/test
```

5. **Verify Deployment**:
```bash
# Check backend
curl -X GET http://localhost:46990/radiology/modalities

# Check Orthanc
curl -X GET http://localhost:8042/system

# Check database
mysql -u root prime -e "SELECT COUNT(*) FROM radiology_modalities;"
```

**Status**: ⏳ Ready to Execute

---

### Task 3: Post-Deployment Verification (30 minutes)

**Objective**: Verify production deployment

**Verification Checklist**:
- [ ] Backend running
- [ ] Orthanc running
- [ ] Database accessible
- [ ] All endpoints responding
- [ ] No errors in logs
- [ ] Webhooks working
- [ ] Monitoring active
- [ ] Alerting active

**Commands**:
```bash
# Check backend status
curl -X POST http://localhost:46990/radiology/webhook/test | jq '.success'

# Check Orthanc status
curl -X GET http://localhost:8042/system | jq '.Version'

# Check database
mysql -u root prime -e "SELECT COUNT(*) FROM radiology_modalities;"

# Check logs
tail -50 backend.log | grep -i error

# Run smoke tests
bash test-phase2.sh
```

**Status**: ⏳ Ready to Execute

---

### Task 4: Monitoring Setup (30 minutes)

**Objective**: Configure monitoring and alerting

**Monitoring Components**:

1. **Application Monitoring**:
```bash
# Monitor backend process
ps aux | grep "node.*app.js"

# Monitor backend port
lsof -i :46990

# Monitor backend logs
tail -f backend.log
```

2. **Database Monitoring**:
```bash
# Monitor database connections
mysql -u root -e "SHOW PROCESSLIST;"

# Monitor database size
mysql -u root prime -e "SELECT table_name, ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb FROM information_schema.TABLES WHERE table_schema = 'prime';"

# Monitor database performance
mysql -u root prime -e "SHOW STATUS LIKE 'Threads%';"
```

3. **Orthanc Monitoring**:
```bash
# Monitor Orthanc status
curl -X GET http://localhost:8042/system

# Monitor Orthanc statistics
curl -X GET http://localhost:8042/statistics

# Monitor Orthanc logs
tail -f /var/log/orthanc/Orthanc.log
```

4. **System Monitoring**:
```bash
# Monitor CPU usage
top -b -n 1 | head -20

# Monitor memory usage
free -h

# Monitor disk usage
df -h

# Monitor network
netstat -an | grep ESTABLISHED | wc -l
```

**Status**: ⏳ Ready to Execute

---

## Monitoring & Alerting Configuration

### Health Checks

**Backend Health Check**:
```bash
#!/bin/bash
# Check backend every 5 minutes

while true; do
  RESPONSE=$(curl -s -X POST http://localhost:46990/radiology/webhook/test)
  if echo $RESPONSE | grep -q '"success":true'; then
    echo "$(date): Backend OK"
  else
    echo "$(date): Backend FAILED - $RESPONSE"
    # Send alert
  fi
  sleep 300
done
```

**Orthanc Health Check**:
```bash
#!/bin/bash
# Check Orthanc every 5 minutes

while true; do
  RESPONSE=$(curl -s -X GET http://localhost:8042/system)
  if echo $RESPONSE | grep -q '"Version"'; then
    echo "$(date): Orthanc OK"
  else
    echo "$(date): Orthanc FAILED"
    # Send alert
  fi
  sleep 300
done
```

**Database Health Check**:
```bash
#!/bin/bash
# Check database every 5 minutes

while true; do
  RESPONSE=$(mysql -u root prime -e "SELECT 1;" 2>&1)
  if [ $? -eq 0 ]; then
    echo "$(date): Database OK"
  else
    echo "$(date): Database FAILED - $RESPONSE"
    # Send alert
  fi
  sleep 300
done
```

---

## Rollback Plan

### If Production Deployment Fails

**Step 1: Stop Backend**:
```bash
pkill -f "node.*app.js"
sleep 2
```

**Step 2: Restore Previous Code**:
```bash
# Restore from backup
cp -r backend.prod.backup.* backend

# Verify restoration
ls -la backend/controller/radiology-*.js
```

**Step 3: Start Backend**:
```bash
cd backend && npm start &
sleep 5
curl -X POST http://localhost:46990/radiology/webhook/test
```

**Step 4: Verify Rollback**:
```bash
# Check backend
curl -X GET http://localhost:46990/radiology/modalities

# Check logs
tail -50 backend.log
```

**Step 5: Notify Team**:
```bash
echo "Rollback completed. System restored to previous version."
```

---

## Deployment Checklist

### Pre-Deployment
- [ ] Code reviewed and approved
- [ ] Security review passed
- [ ] Performance review passed
- [ ] Staging tests passed
- [ ] Backups created
- [ ] Team notified
- [ ] Maintenance window scheduled

### Deployment
- [ ] Backend stopped
- [ ] Code deployed
- [ ] Backend started
- [ ] Deployment verified
- [ ] Smoke tests passed
- [ ] No errors in logs

### Post-Deployment
- [ ] Monitoring active
- [ ] Alerting active
- [ ] Users notified
- [ ] Documentation updated
- [ ] Handover completed

---

## Success Criteria

### Code Review ✅
- [x] Code quality verified
- [x] Security verified
- [x] Performance verified
- [x] Documentation verified

### Staging Deployment ✅
- [ ] Code deployed to staging
- [ ] All tests passing
- [ ] No errors in logs
- [ ] Approval obtained

### Production Deployment ✅
- [ ] Code deployed to production
- [ ] All endpoints responding
- [ ] No errors in logs
- [ ] Monitoring active

### Monitoring ✅
- [ ] Health checks configured
- [ ] Alerting configured
- [ ] Dashboards created
- [ ] Team trained

---

## Troubleshooting

### Backend Won't Start
```bash
# Check logs
tail -50 backend.log

# Check syntax
node -c backend/app.js

# Check dependencies
npm list

# Restore backup
cp -r backend.prod.backup.* backend
```

### Deployment Failed
```bash
# Check error logs
tail -100 backend.log

# Verify database
mysql -u root prime -e "SELECT 1;"

# Verify Orthanc
curl -X GET http://localhost:8042/system

# Rollback if needed
cp -r backend.prod.backup.* backend
```

### Monitoring Not Working
```bash
# Check health check script
ps aux | grep health-check

# Check logs
tail -50 health-check.log

# Restart health check
pkill -f health-check
bash health-check.sh &
```

---

## Documentation & Handover

### Update Documentation
- [ ] Deployment guide updated
- [ ] Troubleshooting guide updated
- [ ] Monitoring guide updated
- [ ] API documentation updated
- [ ] README updated
- [ ] CHANGELOG updated

### Team Training
- [ ] Operations team trained
- [ ] Support team trained
- [ ] Development team trained
- [ ] Management notified

### Handover Checklist
- [ ] All documentation provided
- [ ] Access credentials shared
- [ ] Monitoring dashboards configured
- [ ] Alert contacts configured
- [ ] Escalation procedures documented
- [ ] Support procedures documented

---

## Day Summary

### Day 8: Code Review
- [ ] Code quality review
- [ ] Security review
- [ ] Performance review
- [ ] Documentation review

### Day 9: Staging Deployment
- [ ] Pre-deployment verification
- [ ] Deploy to staging
- [ ] Staging testing
- [ ] Staging approval

### Day 10: Production Deployment
- [ ] Pre-deployment preparation
- [ ] Production deployment
- [ ] Post-deployment verification
- [ ] Monitoring setup

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Phase 3 Ready for Execution

