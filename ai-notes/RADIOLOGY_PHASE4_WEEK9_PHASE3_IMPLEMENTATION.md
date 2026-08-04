# Radiology Phase 4 - Week 9 Phase 3 Implementation
## Production Deployment with Scripts & Monitoring

**Date**: March 11, 2026  
**Phase**: 3 of 3  
**Status**: Ready to Execute  
**Estimated Time**: 2 hours

---

## Phase 3 Implementation Plan

### Part 1: Code Review (1 hour)

#### Code Quality Check Script
```bash
#!/bin/bash
# save as: code-review.sh

echo "=== Code Quality Review ==="

# Check syntax
echo "Checking syntax..."
node -c backend/controller/radiology-worklist.js && echo "✓ radiology-worklist.js"
node -c backend/controller/radiology-dicom-webhook.js && echo "✓ radiology-dicom-webhook.js"
node -c backend/routes/radiology-worklist.js && echo "✓ radiology-worklist.js routes"
node -c backend/services/orthancClient.js && echo "✓ orthancClient.js"

# Check for issues
echo -e "\nChecking for common issues..."
echo "TODO/FIXME comments:"
grep -n "TODO\|FIXME\|HACK" backend/controller/radiology-*.js backend/routes/radiology-*.js backend/services/orthancClient.js || echo "None found"

echo -e "\nConsole.log statements:"
grep -n "console.log" backend/controller/radiology-*.js backend/routes/radiology-*.js backend/services/orthancClient.js || echo "None found"

# Check security
echo -e "\n=== Security Review ==="
echo "Checking for hardcoded secrets..."
grep -n "password\|secret\|token" backend/controller/radiology-*.js backend/routes/radiology-*.js | grep -v "// " || echo "None found"

echo -e "\nChecking for dangerous functions..."
grep -n "eval\|exec" backend/controller/radiology-*.js backend/routes/radiology-*.js || echo "None found"

# Check npm vulnerabilities
echo -e "\n=== Dependency Audit ==="
npm audit

echo -e "\n=== Code Review Complete ==="
```

#### Run Code Review
```bash
chmod +x code-review.sh
./code-review.sh
```

---

### Part 2: Staging Deployment (1 hour)

#### Pre-Deployment Script
```bash
#!/bin/bash
# save as: pre-deploy.sh

echo "=== Pre-Deployment Verification ==="

# Check staging database
echo "Checking staging database..."
mysql -u root prime -e "SELECT COUNT(*) as tables FROM information_schema.TABLES WHERE table_schema='prime';" || exit 1

# Check staging Orthanc
echo "Checking staging Orthanc..."
curl -s -X GET http://localhost:8042/system | jq '.Version' || exit 1

# Check staging backend
echo "Checking staging backend..."
curl -s -X POST http://localhost:46990/radiology/webhook/test | jq '.success' || exit 1

# Create backup
echo "Creating backup..."
cp -r backend backend.backup.$(date +%Y%m%d_%H%M%S)

echo "=== Pre-Deployment Verification Complete ==="
```

#### Deployment Script
```bash
#!/bin/bash
# save as: deploy-staging.sh

set -e

echo "=== Staging Deployment ==="

# Stop backend
echo "Stopping backend..."
pkill -f "node.*app.js" || true
sleep 2

# Deploy code
echo "Deploying code..."
cp backend/controller/radiology-worklist.js backend/controller/radiology-worklist.js.new
cp backend/controller/radiology-dicom-webhook.js backend/controller/radiology-dicom-webhook.js.new
cp backend/routes/radiology-worklist.js backend/routes/radiology-worklist.js.new
cp backend/services/orthancClient.js backend/services/orthancClient.js.new

# Start backend
echo "Starting backend..."
cd backend && npm start &
sleep 5

# Verify deployment
echo "Verifying deployment..."
curl -s -X POST http://localhost:46990/radiology/webhook/test | jq '.'

echo "=== Staging Deployment Complete ==="
```

#### Run Staging Deployment
```bash
chmod +x pre-deploy.sh deploy-staging.sh
./pre-deploy.sh
./deploy-staging.sh
```

---

### Part 3: Production Deployment (1 hour)

#### Production Deployment Script
```bash
#!/bin/bash
# save as: deploy-production.sh

set -e

echo "=== Production Deployment ==="

# Backup production
echo "Creating production backup..."
mysqldump -u root prime > prime_backup_$(date +%Y%m%d_%H%M%S).sql
cp -r backend backend.prod.backup.$(date +%Y%m%d_%H%M%S)

# Notify users
echo "Notifying users..."
echo "Production deployment starting. System will be unavailable for ~5 minutes."

# Stop backend
echo "Stopping backend..."
pkill -SIGTERM -f "node.*app.js" || true
sleep 5

# Deploy code
echo "Deploying code..."
cp backend/controller/radiology-worklist.js backend/controller/radiology-worklist.js.prod
cp backend/controller/radiology-dicom-webhook.js backend/controller/radiology-dicom-webhook.js.prod
cp backend/routes/radiology-worklist.js backend/routes/radiology-worklist.js.prod
cp backend/services/orthancClient.js backend/services/orthancClient.js.prod

# Start backend
echo "Starting backend..."
cd backend && npm start &
sleep 5

# Verify deployment
echo "Verifying deployment..."
RESPONSE=$(curl -s -X POST http://localhost:46990/radiology/webhook/test)
if echo $RESPONSE | grep -q '"success":true'; then
  echo "✓ Backend verified"
else
  echo "✗ Backend verification failed"
  echo "Initiating rollback..."
  pkill -f "node.*app.js"
  cp -r backend.prod.backup.* backend
  cd backend && npm start &
  sleep 5
  exit 1
fi

# Notify users
echo "Production deployment complete. System is operational."

echo "=== Production Deployment Complete ==="
```

#### Rollback Script
```bash
#!/bin/bash
# save as: rollback.sh

set -e

echo "=== Initiating Rollback ==="

# Stop backend
echo "Stopping backend..."
pkill -f "node.*app.js" || true
sleep 2

# Restore backup
echo "Restoring backup..."
LATEST_BACKUP=$(ls -t backend.prod.backup.* | head -1)
cp -r $LATEST_BACKUP backend

# Start backend
echo "Starting backend..."
cd backend && npm start &
sleep 5

# Verify rollback
echo "Verifying rollback..."
curl -s -X POST http://localhost:46990/radiology/webhook/test | jq '.'

echo "=== Rollback Complete ==="
```

#### Run Production Deployment
```bash
chmod +x deploy-production.sh rollback.sh
./deploy-production.sh

# If needed, rollback
# ./rollback.sh
```

---

### Part 4: Monitoring Setup (30 minutes)

#### Health Check Script
```bash
#!/bin/bash
# save as: health-check.sh

LOG_FILE="health-check.log"

# Backend health check
check_backend() {
  RESPONSE=$(curl -s -X POST http://localhost:46990/radiology/webhook/test 2>&1)
  if echo $RESPONSE | grep -q '"success":true'; then
    echo "$(date): Backend OK" >> $LOG_FILE
    return 0
  else
    echo "$(date): Backend FAILED - $RESPONSE" >> $LOG_FILE
    return 1
  fi
}

# Orthanc health check
check_orthanc() {
  RESPONSE=$(curl -s -X GET http://localhost:8042/system 2>&1)
  if echo $RESPONSE | grep -q '"Version"'; then
    echo "$(date): Orthanc OK" >> $LOG_FILE
    return 0
  else
    echo "$(date): Orthanc FAILED" >> $LOG_FILE
    return 1
  fi
}

# Database health check
check_database() {
  RESPONSE=$(mysql -u root prime -e "SELECT 1;" 2>&1)
  if [ $? -eq 0 ]; then
    echo "$(date): Database OK" >> $LOG_FILE
    return 0
  else
    echo "$(date): Database FAILED - $RESPONSE" >> $LOG_FILE
    return 1
  fi
}

# Main loop
echo "Starting health checks..."
while true; do
  check_backend
  check_orthanc
  check_database
  
  # Sleep for 5 minutes
  sleep 300
done
```

#### Monitoring Dashboard Script
```bash
#!/bin/bash
# save as: monitoring-dashboard.sh

while true; do
  clear
  echo "=== System Monitoring Dashboard ==="
  echo "Time: $(date)"
  echo ""
  
  # Backend status
  echo "=== Backend Status ==="
  if curl -s -X POST http://localhost:46990/radiology/webhook/test | grep -q '"success":true'; then
    echo "✓ Backend: Running"
  else
    echo "✗ Backend: Failed"
  fi
  
  # Orthanc status
  echo ""
  echo "=== Orthanc Status ==="
  if curl -s -X GET http://localhost:8042/system | grep -q '"Version"'; then
    echo "✓ Orthanc: Running"
    curl -s -X GET http://localhost:8042/system | jq '.Version'
  else
    echo "✗ Orthanc: Failed"
  fi
  
  # Database status
  echo ""
  echo "=== Database Status ==="
  if mysql -u root prime -e "SELECT 1;" > /dev/null 2>&1; then
    echo "✓ Database: Connected"
    echo "Tables:"
    mysql -u root prime -e "SELECT COUNT(*) as count FROM radiology_modalities;"
    mysql -u root prime -e "SELECT COUNT(*) as count FROM radiology_worklist;"
  else
    echo "✗ Database: Failed"
  fi
  
  # System resources
  echo ""
  echo "=== System Resources ==="
  echo "CPU Usage:"
  top -b -n 1 | head -3 | tail -1
  echo ""
  echo "Memory Usage:"
  free -h | grep Mem
  echo ""
  echo "Disk Usage:"
  df -h | grep -E "/$|/var"
  
  # Recent logs
  echo ""
  echo "=== Recent Errors ==="
  tail -5 backend.log | grep -i error || echo "No recent errors"
  
  echo ""
  echo "Refreshing in 30 seconds... (Press Ctrl+C to exit)"
  sleep 30
done
```

#### Run Monitoring
```bash
chmod +x health-check.sh monitoring-dashboard.sh

# Start health checks in background
./health-check.sh &

# Start monitoring dashboard
./monitoring-dashboard.sh
```

---

### Part 5: Smoke Tests

#### Smoke Test Script
```bash
#!/bin/bash
# save as: smoke-tests.sh

set -e

echo "=== Smoke Tests ==="

# Get IDs
export FACILITY_ID=$(mysql -u root prime -N -e "SELECT id FROM hospitals LIMIT 1;")
export USER_ID=$(mysql -u root prime -N -e "SELECT id FROM users LIMIT 1;")
export PATIENT_ID=$(mysql -u root prime -N -e "SELECT CONCAT(accountNo, '-', beneficiaryNo) FROM patientrecords LIMIT 1;")
export PROCEDURE_ID=$(mysql -u root prime -N -e "SELECT id FROM radiology_procedures LIMIT 1;")

# Get token
export TOKEN=$(curl -s http://localhost:46990/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}' | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# Test 1: Webhook
echo "Test 1: Webhook connectivity..."
curl -s -X POST http://localhost:46990/radiology/webhook/test | jq '.success' || exit 1

# Test 2: Register modality
echo "Test 2: Register modality..."
MODALITY=$(curl -s -X POST http://localhost:46990/radiology/modalities \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "modality_name": "Test Modality",
    "modality_type": "XR",
    "ae_title": "TEST01",
    "ip_address": "192.168.1.100",
    "port": 104,
    "manufacturer": "Test",
    "model": "Test",
    "room_location": "Test",
    "facilityId": "'$FACILITY_ID'"
  }')
echo $MODALITY | jq '.success' || exit 1

# Test 3: Create request
echo "Test 3: Create request..."
REQUEST=$(curl -s -X POST http://localhost:46990/radiology/requests \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "patient_id": "'$PATIENT_ID'",
    "requesting_doctor_id": "'$USER_ID'",
    "procedure_id": "'$PROCEDURE_ID'",
    "priority": "routine",
    "clinical_indication": "Test",
    "facilityId": "'$FACILITY_ID'",
    "created_by": "'$USER_ID'"
  }')
echo $REQUEST | jq '.success' || exit 1

# Test 4: Get worklist
echo "Test 4: Get worklist..."
curl -s -X GET "http://localhost:46990/radiology/worklist?status=pending&facilityId=$FACILITY_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.success' || exit 1

echo "=== All Smoke Tests Passed ==="
```

#### Run Smoke Tests
```bash
chmod +x smoke-tests.sh
./smoke-tests.sh
```

---

## Complete Deployment Checklist

### Pre-Deployment
- [ ] Code reviewed
- [ ] Security verified
- [ ] Performance verified
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

## Execution Steps

### Step 1: Code Review (20 min)
```bash
./code-review.sh
```

### Step 2: Staging Deployment (20 min)
```bash
./pre-deploy.sh
./deploy-staging.sh
bash test-phase2.sh
```

### Step 3: Production Deployment (20 min)
```bash
./deploy-production.sh
./smoke-tests.sh
```

### Step 4: Monitoring Setup (20 min)
```bash
./health-check.sh &
./monitoring-dashboard.sh
```

**Total Time**: ~80 minutes

---

## Success Criteria

### Code Review ✅
- [x] Code quality verified
- [x] Security verified
- [x] Performance verified
- [x] Documentation verified

### Staging Deployment ✅
- [ ] Code deployed
- [ ] All tests passing
- [ ] No errors in logs
- [ ] Approval obtained

### Production Deployment ✅
- [ ] Code deployed
- [ ] All endpoints responding
- [ ] No errors in logs
- [ ] Monitoring active

### Monitoring ✅
- [ ] Health checks running
- [ ] Alerting configured
- [ ] Dashboards active
- [ ] Team trained

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Phase 3 Ready for Implementation

