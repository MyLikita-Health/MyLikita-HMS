# HR Module Phase 2 - Quick Start Guide
## Attendance & Leave Management

---

## WHAT'S NEW IN PHASE 2

Phase 2 adds complete attendance tracking and leave management to the HR module:

### Attendance Features
- Mark employee attendance with check-in/out times
- Track attendance status (Present, Absent, Late, Half Day, On Leave)
- Generate employee and department attendance reports
- Bulk mark attendance for multiple employees
- View attendance statistics and summaries

### Leave Features
- Submit leave requests with balance validation
- Approve/reject leave requests
- Track leave balance by type and year
- View leave calendar with approved leaves
- Automatic leave balance updates

---

## ACCESSING THE FEATURES

### From the Frontend

1. **Navigate to HR Module**
   - Click on HR in the main menu
   - You'll see the HR Dashboard

2. **Attendance Features**
   - Click "Attendance" in the left menu
   - Options:
     - **Mark Attendance**: Record attendance for employees
     - **Attendance Report**: View detailed attendance reports

3. **Leave Features**
   - Click "Leave" in the left menu
   - Options:
     - **Leave Request**: Submit new leave requests
     - **Leave Approval**: Approve/reject pending requests (HR only)
     - **Leave Balance**: View leave balance by employee
     - **Leave Calendar**: View approved leaves on calendar

---

## MARKING ATTENDANCE

### Step 1: Open Attendance Tracker
```
HR → Attendance → Mark Attendance
```

### Step 2: Fill the Form
- **Employee**: Select employee from dropdown
- **Date**: Select attendance date
- **Check In Time**: Optional - time employee arrived
- **Check Out Time**: Optional - time employee left
- **Status**: Select from (Present, Absent, Late, Half Day, On Leave)
- **Remarks**: Optional - add notes

### Step 3: Submit
- Click "Mark Attendance" button
- Record will be created or updated if already exists

### Bulk Marking
- Use the "Bulk Mark Attendance" endpoint to mark multiple employees at once
- Send array of attendance records

---

## SUBMITTING LEAVE REQUEST

### Step 1: Open Leave Request
```
HR → Leave → Leave Request
```

### Step 2: Check Leave Balance
- View your available leave balance by type
- Shows: Allocated, Used, Carried Forward, Available

### Step 3: Submit Request
- Click "New Leave Request" button
- Fill the form:
  - **Leave Type**: Select type (Annual, Sick, Casual, etc.)
  - **Start Date**: First day of leave
  - **End Date**: Last day of leave
  - **Reason**: Reason for leave
- System automatically calculates number of days
- System validates available balance

### Step 4: Submit
- Click "Submit Request"
- Request status will be "Pending"
- Wait for approval from HR/Department Head

---

## APPROVING LEAVE REQUESTS

### Step 1: Open Leave Approval
```
HR → Leave → Leave Approval
```

### Step 2: View Pending Requests
- See all pending leave requests
- Shows: Employee, Leave Type, Dates, Days, Reason

### Step 3: Approve or Reject
- **Approve**: Click "Approve" button
  - Leave balance will be automatically updated
  - Status changes to "Approved"
  
- **Reject**: Click "Reject" button
  - Enter rejection reason in modal
  - Status changes to "Rejected"
  - Leave balance remains unchanged

---

## VIEWING LEAVE BALANCE

### Step 1: Open Leave Balance
```
HR → Leave → Leave Balance
```

### Step 2: Select Employee and Year
- Choose employee from dropdown
- Select year (2024, 2025, 2026, 2027)

### Step 3: View Balance
- See balance cards for each leave type
- Shows:
  - Allocated days
  - Carried forward days
  - Used days
  - Available days
  - Percentage available (progress bar)

### Step 4: Summary Table
- Detailed table with all leave types
- Shows all balance information
- Color-coded percentage indicators

---

## VIEWING LEAVE CALENDAR

### Step 1: Open Leave Calendar
```
HR → Leave → Leave Calendar
```

### Step 2: Navigate Months
- Use "Previous" and "Next" buttons to navigate
- Calendar shows current month by default

### Step 3: View Approved Leaves
- Approved leaves are highlighted in blue
- Employee ID shown on leave days
- Click on leave day to see details

### Step 4: Leave Summary
- Below calendar shows all leaves for the month
- Shows: Employee, Leave Type, Dates, Days, Reason

---

## GENERATING ATTENDANCE REPORT

### Step 1: Open Attendance Report
```
HR → Attendance → Attendance Report
```

### Step 2: Set Filters
- **Employee**: Select employee
- **Start Date**: Report start date
- **End Date**: Report end date

### Step 3: Generate Report
- Click "Generate Report" button
- System calculates statistics

### Step 4: View Results
- **Statistics Cards**: Shows totals
  - Total Days
  - Present
  - Absent
  - Late
  - Half Day
  - Attendance Percentage

- **Detailed Table**: Shows each day's record
  - Date
  - Check In Time
  - Check Out Time
  - Status
  - Remarks

---

## API ENDPOINTS

### Attendance Endpoints

```bash
# Mark attendance
POST /hr/attendance/mark
{
  "employee_id": 1,
  "attendance_date": "2026-03-11",
  "check_in_time": "09:00",
  "check_out_time": "17:00",
  "status": "Present",
  "remarks": "Regular"
}

# Get attendance records
GET /hr/attendance?page=1&limit=50&status=Present

# Get employee report
GET /hr/attendance/employee/1/report?start_date=2026-03-01&end_date=2026-03-31

# Get department report
GET /hr/attendance/department/1/report?start_date=2026-03-01&end_date=2026-03-31

# Bulk mark attendance
POST /hr/attendance/bulk
{
  "attendance_records": [
    {"employee_id": 1, "attendance_date": "2026-03-11", "status": "Present"},
    {"employee_id": 2, "attendance_date": "2026-03-11", "status": "Absent"}
  ]
}

# Get summary
GET /hr/attendance/summary?start_date=2026-03-01&end_date=2026-03-31
```

### Leave Endpoints

```bash
# Get leave types
GET /hr/leave/types

# Get leave balance
GET /hr/leave/balance/1?year=2026

# Submit leave request
POST /hr/leave/request
{
  "employee_id": 1,
  "leave_type_id": 1,
  "start_date": "2026-03-15",
  "end_date": "2026-03-17",
  "reason": "Personal leave"
}

# Get leave requests
GET /hr/leave/requests?status=Pending&page=1&limit=50

# Approve leave request
PUT /hr/leave/request/1/approve
{
  "approved_by": 2
}

# Reject leave request
PUT /hr/leave/request/1/reject
{
  "rejection_reason": "Insufficient notice"
}

# Update leave balance
PUT /hr/leave/balance/1/1
{
  "year": 2026,
  "allocated": 20,
  "carried_forward": 5
}

# Get leave calendar
GET /hr/leave/calendar?start_date=2026-03-01&end_date=2026-03-31
```

---

## COMMON TASKS

### Task 1: Mark Today's Attendance
1. Go to HR → Attendance
2. Click "Mark Attendance"
3. Select employee
4. Date auto-fills with today
5. Select status
6. Click "Mark Attendance"

### Task 2: Request Leave
1. Go to HR → Leave → Leave Request
2. Check your leave balance
3. Click "New Leave Request"
4. Select leave type
5. Enter dates and reason
6. Click "Submit Request"

### Task 3: Approve Leave Requests
1. Go to HR → Leave → Leave Approval
2. See all pending requests
3. Click "Approve" or "Reject"
4. If rejecting, enter reason
5. Done - balance updates automatically

### Task 4: Check Attendance Report
1. Go to HR → Attendance → Attendance Report
2. Select employee
3. Set date range
4. Click "Generate Report"
5. View statistics and details

### Task 5: View Leave Calendar
1. Go to HR → Leave → Leave Calendar
2. Navigate to desired month
3. See all approved leaves
4. View leave summary below

---

## TROUBLESHOOTING

### Issue: "Insufficient leave balance"
**Solution**: Check available balance in Leave Balance section. You may need to request more leave or wait for carry-forward.

### Issue: Leave request not showing in calendar
**Solution**: Calendar only shows "Approved" leaves. Check Leave Approval to approve pending requests.

### Issue: Attendance not updating
**Solution**: Check if attendance already exists for that date. System will update existing records.

### Issue: Can't approve leave requests
**Solution**: You need HR Manager role. Contact your administrator.

---

## PERMISSIONS REQUIRED

To use Phase 2 features, you need these permissions:

### Attendance
- `hr.view_attendance` - View attendance records
- `hr.mark_attendance` - Mark attendance
- `hr.view_reports` - View attendance reports

### Leave
- `hr.view_leave` - View leave requests
- `hr.approve_leave` - Approve/reject leave (HR only)
- `hr.view_reports` - View leave reports

---

## NEXT STEPS

After Phase 2, Phase 3 will add:
- Payroll management
- Salary structure
- Payslip generation
- Salary advances
- Tax calculations

---

## SUPPORT

For issues or questions:
1. Check this guide
2. Review API documentation
3. Contact HR Administrator
4. Check system logs

---

**Version**: 1.0  
**Last Updated**: March 2026  
**Status**: Ready for Use
