# Dental Lab Billing System

Complete billing integration for dental lab services with payment gates and workflow automation.

---

## 🚀 Quick Start

### 1. Database Setup

Run the migration script to add billing fields and pricing data:

```bash
mysql -u your_username -p your_database < backend/sql/dental_lab_billing_schema.sql
```

Verify the installation:

```bash
mysql -u your_username -p your_database < backend/sql/test_lab_billing.sql
```

### 2. Backend Setup

The backend is already configured. Just restart the server:

```bash
cd backend
npm restart
```

### 3. Test the API

```bash
# Get orthodontic pricing
curl http://localhost:5000/dental/lab/pricing/orthodontic?facilityId=FAC001

# Get prosthetic pricing
curl http://localhost:5000/dental/lab/pricing/prosthetic?facilityId=FAC001
```

---

## 📋 Features

### 1. Real-time Cost Calculator
- Automatically calculates total cost as items are selected
- Groups items by category for easy review
- Shows detailed breakdown with individual prices

### 2. Payment Gates
- **can_start_work**: Lab can only start work after full payment
- **can_deliver**: Job can only be delivered after full payment
- Prevents work from starting on unpaid jobs

### 3. Automatic Status Updates
- Job status automatically updates based on payment
- Payment detection via bill description identifiers
- Seamless integration with existing billing system

### 4. Comprehensive Job Cards
- Complete patient and doctor information
- Detailed component selection
- Special instructions field
- Shade information (prosthetic)
- Due date tracking

### 5. Payment Tracking
- All payments recorded in dedicated table
- Links payments to jobs and transactions
- Supports partial payments (though gates remain closed)

---

## 🔄 Workflow

### Creating a Lab Job

1. **Open Job Card**
   - Navigate to Dental Module → Lab
   - Click "New Orthodontic Job" or "New Prosthetic Job"

2. **Fill Patient Information**
   - Patient details auto-populated if selected
   - Add/edit age, gender, phone, email

3. **Fill Doctor Information**
   - Enter doctor name (required)
   - Add practice/clinic name

4. **Set Job Details**
   - Date received (defaults to today)
   - Due date (required)
   - Special instructions

5. **Select Components**
   - Check boxes for needed items
   - Cost calculator updates in real-time
   - Review breakdown by category

6. **Create Job**
   - Click "Create Job & Generate Bill"
   - Job card number generated
   - Bill created automatically

### Processing Payment

1. **Cashier Receives Bill**
   - Bill appears in pending transactions
   - Description includes: `[LAB-JOB:ORTHO-123]` or `[LAB-JOB:PROS-456]`

2. **Process Payment**
   - Select payment method (Cash, Bank, POS)
   - Process payment as normal

3. **Automatic Updates**
   - Job payment status → 'paid'
   - Amount paid updated
   - Payment gates opened:
     - `can_start_work = TRUE`
     - `can_deliver = TRUE`
   - Job status → 'paid'
   - Payment recorded in tracking table

### Lab Work

1. **Lab Technician Views Job**
   - Sees job is paid and ready
   - Can start work (gate is open)

2. **Start Work**
   - Update status to 'in_progress'
   - Assign to technician

3. **Complete Work**
   - Update status to 'completed'
   - Ready for delivery

4. **Deliver**
   - Verify payment (gate check)
   - Deliver to dentist
   - Update status to 'delivered'

---

## 💰 Pricing

### Orthodontic Items (25+ items)

| Category | Example Items | Price Range |
|----------|--------------|-------------|
| Appliances | Hawley Retainer, Expansion Plate | ₦15,000 - ₦25,000 |
| Bows | Labial Bow, Buccal Bow | ₦3,000 - ₦3,500 |
| Clasps | Adams Clasp, C-Clasp | ₦1,500 - ₦7,000 |
| Springs | Z-Spring, Finger Spring | ₦2,000 - ₦2,500 |
| Screws | Expansion Screw, Coffin Spring | ₦4,000 - ₦5,000 |
| Components | Acrylic Baseplate, Lip Bumper | ₦3,000 - ₦12,000 |

### Prosthetic Items (30+ items)

| Category | Example Items | Price Range |
|----------|--------------|-------------|
| Complete Dentures | Upper, Lower, Both | ₦50,000 - ₦95,000 |
| Partial Dentures | Acrylic, Cast, Flexible | ₦35,000 - ₦80,000 |
| Crowns | PFM, Ceramic, Zirconia | ₦20,000 - ₦45,000 |
| Bridges | 3-Unit, 4-Unit | ₦60,000 - ₦130,000 |
| Veneers | Porcelain, Composite | ₦15,000 - ₦30,000 |
| Services | Reline, Repair, Night Guard | ₦10,000 - ₦20,000 |

---

## 🔧 API Endpoints

### Get Pricing
```
GET /dental/lab/pricing/:jobType?facilityId=FAC001
```

**Parameters:**
- `jobType`: 'orthodontic' or 'prosthetic'
- `facilityId`: Facility ID (query parameter)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "category": "orthodontic",
      "item_code": "hawley_retainer_upper",
      "item_name": "Hawley Retainer - Upper",
      "unit_price": 15000,
      "description": "Upper arch Hawley retainer"
    }
  ]
}
```

### Create Orthodontic Job with Billing
```
POST /dental-lab/orthodontic/create-with-billing
```

**Body:**
```json
{
  "patient_id": "PAT123",
  "patient_name": "John Doe",
  "doctor_name": "Dr. Smith",
  "facilityId": "FAC001",
  "due_date": "2026-03-15",
  "total_cost": 22000,
  "selectedComponents": ["hawley_retainer_upper", "labial_bow"],
  "created_by": "USER123"
}
```

**Response:**
```json
{
  "success": true,
  "jobId": 123,
  "job_card_no": "ORTHO-1709654321",
  "transaction_id": "LAB-ORTHO-123-1709654321",
  "message": "Orthodontic job created. Bill can now be generated."
}
```

### Create Prosthetic Job with Billing
```
POST /dental-lab/prosthetic/create-with-billing
```

**Body:** (Same structure as orthodontic)

### Check Payment Status
```
GET /dental-lab/:jobType/:jobId/payment-status
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 123,
    "job_card_no": "ORTHO-1709654321",
    "payment_status": "paid",
    "amount_paid": 22000,
    "total_cost": 22000,
    "can_start_work": true,
    "can_deliver": true,
    "status": "paid"
  }
}
```

### Get Job Details
```
GET /dental-lab/:jobType/:jobId/details
```

---

## 🗄️ Database Schema

### dental_lab_orthodontic_jobs (Updated)
```sql
ALTER TABLE dental_lab_orthodontic_jobs
ADD COLUMN total_cost DECIMAL(10,2) DEFAULT 0.00,
ADD COLUMN bill_transaction_id VARCHAR(50),
ADD COLUMN payment_status ENUM('unpaid', 'partial', 'paid') DEFAULT 'unpaid',
ADD COLUMN amount_paid DECIMAL(10,2) DEFAULT 0.00,
ADD COLUMN payment_required BOOLEAN DEFAULT TRUE,
ADD COLUMN can_start_work BOOLEAN DEFAULT FALSE,
ADD COLUMN can_deliver BOOLEAN DEFAULT FALSE;
```

### dental_lab_prosthetic_jobs (Updated)
Same columns as orthodontic table.

### dental_lab_pricing (New)
```sql
CREATE TABLE dental_lab_pricing (
  id INT PRIMARY KEY AUTO_INCREMENT,
  facilityId VARCHAR(50) NOT NULL,
  category ENUM('orthodontic', 'prosthetic') NOT NULL,
  item_code VARCHAR(50) NOT NULL,
  item_name VARCHAR(200) NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_facility_item (facilityId, category, item_code)
);
```

### dental_lab_payments (New)
```sql
CREATE TABLE dental_lab_payments (
  id INT PRIMARY KEY AUTO_INCREMENT,
  job_id INT NOT NULL,
  job_type ENUM('orthodontic', 'prosthetic') NOT NULL,
  patient_id VARCHAR(50) NOT NULL,
  facilityId VARCHAR(50) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  payment_type ENUM('full', 'partial', 'deposit') NOT NULL,
  transaction_id VARCHAR(50),
  payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  payment_method VARCHAR(50),
  notes TEXT
);
```

---

## 🎯 Bill Description Format

All lab job bills MUST include the identifier in the description:

### Orthodontic:
```
Orthodontic Lab Work [LAB-JOB:ORTHO-123]
```

### Prosthetic:
```
Prosthetic Lab Work [LAB-JOB:PROS-456]
```

The system uses this regex pattern to detect lab payments:
```javascript
/\[LAB-JOB:(ORTHO|PROS)-(\d+)\]/
```

---

## 🧪 Testing

### Manual Testing Steps

1. **Create Orthodontic Job**
   ```bash
   # Open dental module
   # Navigate to Lab → New Orthodontic Job
   # Fill form and select items
   # Verify cost calculation
   # Create job
   # Note the job card number
   ```

2. **Verify Bill Generated**
   ```bash
   # Check pending transactions
   # Find bill with [LAB-JOB:ORTHO-xxx]
   # Verify amount matches
   ```

3. **Process Payment**
   ```bash
   # Process payment as cashier
   # Select payment method
   # Complete payment
   ```

4. **Verify Payment Gates**
   ```sql
   SELECT 
     job_card_no,
     payment_status,
     amount_paid,
     total_cost,
     can_start_work,
     can_deliver,
     status
   FROM dental_lab_orthodontic_jobs
   WHERE job_card_no = 'ORTHO-xxx';
   ```

   Expected:
   - payment_status = 'paid'
   - amount_paid = total_cost
   - can_start_work = TRUE
   - can_deliver = TRUE
   - status = 'paid'

5. **Verify Payment Recorded**
   ```sql
   SELECT * FROM dental_lab_payments
   WHERE job_id = xxx;
   ```

### Automated Tests

Run the test SQL script:
```bash
mysql -u user -p database < backend/sql/test_lab_billing.sql
```

---

## 🐛 Troubleshooting

### Issue: Pricing not loading
**Solution:** 
- Verify database migration ran successfully
- Check pricing table has data: `SELECT COUNT(*) FROM dental_lab_pricing;`
- Ensure facilityId is correct

### Issue: Payment not detected
**Solution:**
- Verify bill description includes `[LAB-JOB:ORTHO-xxx]` or `[LAB-JOB:PROS-xxx]`
- Check regex pattern in account.js
- Verify job ID is correct

### Issue: Payment gates not opening
**Solution:**
- Check payment amount equals total cost
- Verify payment was processed successfully
- Check dental_lab_payments table for payment record

### Issue: Cost calculator not updating
**Solution:**
- Check browser console for errors
- Verify API endpoint is accessible
- Check pricing data exists for selected items

---

## 📚 Related Files

### Backend
- `backend/controller/dental-lab.js` - Lab controller with billing functions
- `backend/routes/dental-lab.js` - Lab routes
- `backend/controller/account.js` - Payment detection
- `backend/config/lab-pricing.js` - Pricing configuration
- `backend/sql/dental_lab_billing_schema.sql` - Database migration
- `backend/sql/test_lab_billing.sql` - Test script

### Frontend
- `frontend/src/components/dental/lab/OrthodonticJobCard.jsx` - Ortho job form
- `frontend/src/components/dental/lab/ProstheticJobCard.jsx` - Pros job form
- `frontend/src/components/dental/lab/LabCostCalculator.jsx` - Cost calculator
- `frontend/src/components/dental/lab/lab.css` - Lab styles

### Documentation
- `DENTAL_LAB_COMPLETE_GUIDE.md` - Detailed implementation guide
- `DENTAL_LAB_IMPLEMENTATION_SUMMARY.md` - Implementation summary
- `DENTAL_LAB_BILLING_README.md` - This file

---

## ✨ Features Summary

✅ Real-time cost calculation
✅ Payment gates for workflow control
✅ Automatic status updates
✅ Payment tracking and history
✅ Facility-specific pricing
✅ Comprehensive job cards
✅ Seamless billing integration
✅ Partial payment support
✅ Complete orthodontic workflow
✅ Complete prosthetic workflow

---

## 🎉 Ready to Use!

The dental lab billing system is fully implemented and ready for production use. Follow the Quick Start guide above to get started.

For detailed implementation information, see `DENTAL_LAB_COMPLETE_GUIDE.md`.
