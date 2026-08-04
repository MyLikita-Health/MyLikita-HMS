#!/bin/bash
# Production Deployment Script

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
