#!/bin/bash
# Monitoring Dashboard Script

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
    echo "Modalities:"
    mysql -u root prime -N -e "SELECT COUNT(*) FROM radiology_modalities;"
    echo "Worklist items:"
    mysql -u root prime -N -e "SELECT COUNT(*) FROM radiology_worklist;"
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
  df -h | grep -E "/$|/var" | head -2
  
  # Recent logs
  echo ""
  echo "=== Recent Errors ==="
  if [ -f backend.log ]; then
    tail -5 backend.log | grep -i error || echo "No recent errors"
  else
    echo "No log file found"
  fi
  
  echo ""
  echo "Refreshing in 30 seconds... (Press Ctrl+C to exit)"
  sleep 30
done
