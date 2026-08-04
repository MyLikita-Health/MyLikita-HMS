# HR Module Phase 3 - Quick Start Guide
## Payroll Management

---

## WHAT'S NEW IN PHASE 3

Phase 3 adds complete payroll management to the HR module:

### Payroll Features
- Create and manage salary structures
- Process payroll for employees
- Generate payslips
- Request and approve salary advances
- Track payroll history
- Generate payroll reports

---

## ACCESSING THE FEATURES

### From the Frontend

1. **Navigate to HR Module**
   - Click on HR in the main menu
   - You'll see the HR Dashboard

2. **Payroll Features**
   - Click "Payroll" in the left menu
   - Options:
     - **Payroll Dashboard**: Process payroll and view records
     - **Salary Structure**: Manage salary structures
     - **Payslips**: Generate and view payslips
     - **Salary Advance**: Request and approve advances

---

## CREATING SALARY STRUCTURE

### Step 1: Open Salary Structure
```
HR → Payroll → Salary Structure
```

### Step 2: Select Designation
- Choose a designation from dropdown
- View current structure if exists

### Step 3: Create New Structure
- Click "Create Structure" button
- Fill the form:
  - **Base Salary**: Monthly base salary
  - **Effective From**: Start date
  - **Effective To**: End date (optional)
  - **Components**: Add earnings and deductions

### Step 4: Add Components
- Click "Add Component" button
- Select component from dropdown
- Enter amount OR percentage
- Click "Remove" to delete component
- Click "Create Structure" to save

### Example Structure
```
Base Salary: ₦100,000
Components:
- Housing Allowance: ₦20,000 (Earning)
- Transport Allowance: 5% (Earning)
- Tax: 10% (Deduction)
- Insurance: ₦5,000 (Deduction)
```

---

## PROCESSING PAYROLL

### Step 1: Open Payroll Dashboard
```
HR → Payroll
```

### Step 2: Select Month
- Choose payroll month using month picker
- Dashboard auto-loads data for that month

### Step 3: View Summary
- See statistics:
  - Total Employees
  - Total Gross Salary
  - Total Deductions
  - Total Net Salary

### Step 4: Process Payroll
- Click "Process Payroll" button
- System calculates salary for all active employees
- Shows processing results
- Updates payroll records

### Step 5: View Records
- See all payroll records in table
- Shows: Employee ID, Base, Gross, Deductions, Net, Status
- Status: Draft, Processed, Paid, Cancelled

---

## GENERATING PAYSLIPS

### Step 1: Open Payslips
```
HR → Payroll → Payslips
```

### Step 2: Select Payroll
- See list of processed payrolls
- Shows: Employee ID, Month, Net Salary, Status

### Step 3: Generate Payslip
- Click "View" button for desired payroll
- System generates payslip
- Shows preview on right side

### Step 4: View Payslip
- Employee information
- Earnings breakdown
- Deductions breakdown
- Net salary calculation

### Step 5: Print Payslip
- Click "Print" button
- Use browser print dialog
- Save as PDF or print to paper

---

## REQUESTING SALARY ADVANCE

### Step 1: Open Salary Advance
```
HR → Payroll → Salary Advance
```

### Step 2: View Requests
- See all salary advance requests
- Shows statistics:
  - Pending Requests
  - Approved Requests
  - Paid Requests
  - Total Amount

### Step 3: Submit Request
- Click "Request Advance" button
- Fill the form:
  - **Employee**: Select employee
  - **Amount**: Advance amount
  - **Repayment Months**: Number of months to repay
  - **Reason**: Reason for advance

### Step 4: Submit
- Click "Submit Request"
- Request status: Pending
- Wait for approval

### Step 5: Approve Request (HR Only)
- See pending requests in table
- Click "Approve" button
- Status changes to "Approved"
- Amount will be deducted from future payroll

---

## API ENDPOINTS

### Salary Components

```bash
# Get salary components
GET /hr/payroll/components

# Create salary component
POST /hr/payroll/components
{
  "name": "Housing Allowance",
  "type": "Earning",
  "is_fixed": true,
  "amount": 20000,
  "description": "Monthly housing allowance"
}
```

### Salary Structures

```bash
# Create salary structure
POST /hr/payroll/structures
{
  "designation_id": 1,
  "base_salary": 100000,
  "effective_from": "2026-03-01",
  "effective_to": null,
  "components": [
    {
      "component_id": 1,
      "amount": 20000,
      "percentage": null
    },
    {
      "component_id": 2,
      "amount": null,
      "percentage": 5
    }
  ]
}

# Get salary structure
GET /hr/payroll/structures/1?date=2026-03-01
```

### Payroll Processing

```bash
# Process payroll
POST /hr/payroll/process
{
  "payroll_month": "2026-03-01",
  "employee_ids": [1, 2, 3]  // Optional - process all if not provided
}

# Get payroll records
GET /hr/payroll?payroll_month=2026-03-01&status=Processed&page=1&limit=50

# Get payroll summary
GET /hr/payroll/summary?start_date=2026-03-01&end_date=2026-03-31
```

### Payslips

```bash
# Generate payslip
POST /hr/payroll/1/payslip
```

### Salary Advances

```bash
# Request salary advance
POST /hr/payroll/advance/request
{
  "employee_id": 1,
  "amount": 50000,
  "reason": "Medical emergency",
  "repayment_months": 3
}

# Approve salary advance
PUT /hr/payroll/advance/1/approve
{
  "approved_by": 2
}
```

---

## COMMON TASKS

### Task 1: Set Up Salary Structure
1. Go to HR → Payroll → Salary Structure
2. Select designation
3. Click "Create Structure"
4. Enter base salary
5. Add components (allowances, deductions)
6. Click "Create Structure"

### Task 2: Process Monthly Payroll
1. Go to HR → Payroll
2. Select payroll month
3. Click "Process Payroll"
4. Review results
5. Records show in table

### Task 3: Generate Payslip
1. Go to HR → Payroll → Payslips
2. Click "View" on desired payroll
3. Payslip appears on right
4. Click "Print" to print/save

### Task 4: Request Salary Advance
1. Go to HR → Payroll → Salary Advance
2. Click "Request Advance"
3. Select employee
4. Enter amount and reason
5. Click "Submit Request"

### Task 5: Approve Salary Advance
1. Go to HR → Payroll → Salary Advance
2. See pending requests
3. Click "Approve" button
4. Status changes to "Approved"

---

## SALARY CALCULATION EXAMPLE

### Input
```
Base Salary: ₦100,000
Components:
- Housing Allowance: ₦20,000 (Earning)
- Transport Allowance: 5% of base (Earning)
- Tax: 10% of gross (Deduction)
- Insurance: ₦5,000 (Deduction)
```

### Calculation
```
Base Salary:           ₦100,000
+ Housing Allowance:   ₦20,000
+ Transport (5%):      ₦5,000
= Gross Salary:        ₦125,000

- Tax (10%):           ₦12,500
- Insurance:           ₦5,000
= Total Deductions:    ₦17,500

= Net Salary:          ₦107,500
```

---

## TROUBLESHOOTING

### Issue: "No salary structure found"
**Solution**: Create salary structure for the designation first. Go to Salary Structure and create one.

### Issue: Payroll not processing
**Solution**: Ensure all employees have salary structures. Check that employees are marked as "Active".

### Issue: Payslip not generating
**Solution**: Payroll must be in "Processed" status. Process payroll first, then generate payslip.

### Issue: Can't approve salary advance
**Solution**: You need HR Manager role. Contact your administrator.

### Issue: Salary calculation incorrect
**Solution**: Check salary structure components. Verify percentages and amounts are correct.

---

## PERMISSIONS REQUIRED

To use Phase 3 features, you need these permissions:

### Payroll
- `hr.view_payroll` - View payroll records
- `hr.process_payroll` - Process payroll
- `hr.view_reports` - View payroll reports

### Salary Structure
- `hr.manage_salary_structure` - Create/edit salary structures

### Payslips
- `hr.view_payslips` - View payslips
- `hr.generate_payslips` - Generate payslips

### Salary Advances
- `hr.view_salary_advances` - View salary advances
- `hr.approve_salary_advances` - Approve advances (HR only)

---

## NEXT STEPS

After Phase 3, Phase 4 will add:
- Performance management
- Training programs
- Recruitment workflow
- HR analytics and reports

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
