#!/bin/bash
# Staging Deployment Script

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
