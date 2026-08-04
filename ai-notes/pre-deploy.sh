#!/bin/bash
# Pre-Deployment Verification Script

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
