#!/bin/bash
# Code Quality and Security Review Script

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
grep -n "TODO\|FIXME\|HACK" backend/controller/radiology-*.js backend/routes/radiology-*.js backend/services/orthancClient.js 2>/dev/null || echo "None found"

echo -e "\nConsole.log statements:"
grep -n "console.log" backend/controller/radiology-*.js backend/routes/radiology-*.js backend/services/orthancClient.js 2>/dev/null || echo "None found"

# Check security
echo -e "\n=== Security Review ==="
echo "Checking for hardcoded secrets..."
grep -n "password\|secret\|token" backend/controller/radiology-*.js backend/routes/radiology-*.js 2>/dev/null | grep -v "// " || echo "None found"

echo -e "\nChecking for dangerous functions..."
grep -n "eval\|exec" backend/controller/radiology-*.js backend/routes/radiology-*.js 2>/dev/null || echo "None found"

echo -e "\n=== Code Review Complete ==="
