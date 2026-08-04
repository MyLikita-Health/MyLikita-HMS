#!/bin/bash
# Rollback Script

set -e

echo "=== Initiating Rollback ==="

# Stop backend
echo "Stopping backend..."
pkill -f "node.*app.js" || true
sleep 2

# Restore backup
echo "Restoring backup..."
LATEST_BACKUP=$(ls -t backend.prod.backup.* 2>/dev/null | head -1)
if [ -z "$LATEST_BACKUP" ]; then
  echo "No backup found!"
  exit 1
fi
cp -r $LATEST_BACKUP backend

# Start backend
echo "Starting backend..."
cd backend && npm start &
sleep 5

# Verify rollback
echo "Verifying rollback..."
curl -s -X POST http://localhost:46990/radiology/webhook/test | jq '.'

echo "=== Rollback Complete ==="
