#!/bin/bash
# Health Check Script

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
