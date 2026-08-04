# Backend Server Restart Guide

## Issue
The frontend is showing `ERR_CONNECTION_REFUSED` which means the backend server is not running or has crashed.

## Solution: Restart Backend Server

### Option 1: Using npm (if running directly)
```bash
cd backend
npm start
```

### Option 2: Using PM2 (if using process manager)
```bash
# Check if backend is running
pm2 list

# Restart backend
pm2 restart backend

# Or restart all processes
pm2 restart all

# View logs to check for errors
pm2 logs backend
```

### Option 3: Using nodemon (if in development)
```bash
cd backend
npx nodemon app.js
```

## Verify Server is Running

After starting the server, you should see output like:
```
Server running on port 46990
Database connected successfully
```

Check if the server is accessible:
```bash
curl http://localhost:46990/health
```

Or open in browser: http://localhost:46990

## Common Issues

### Port Already in Use
If you get "Port 46990 is already in use":
```bash
# Find process using the port
lsof -i :46990

# Kill the process (replace PID with actual process ID)
kill -9 PID

# Then restart the server
```

### Database Connection Error
If you see database connection errors:
- Check MySQL is running
- Verify database credentials in `backend/config/config.json`
- Ensure `prime` database exists

### Module Not Found Errors
If you see "Cannot find module" errors:
```bash
cd backend
npm install
```

## After Restart

Once the backend is running:
1. Refresh the frontend in your browser
2. Try viewing a job again
3. The job details should now load correctly

## Changes Applied

The backend now includes:
- ✅ Fixed billing integration with `pending_txn` table
- ✅ Added `patient_type` field to bill generation
- ✅ Fixed `getAllJobsWithPaymentStatus` to always include `job_type`
- ✅ Payment handler ready to update job status after payment

## Testing Checklist

After restart, test:
- [ ] Create a new lab job (orthodontic or prosthetic)
- [ ] Verify bill is generated in pending transactions
- [ ] View job details page (should work now)
- [ ] Process payment through cashier
- [ ] Verify job status updates after payment
