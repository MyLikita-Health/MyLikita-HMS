# Dental Lab Billing - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Database Setup (1 minute)

```bash
# Run the migration script
mysql -u root -p dental_db < backend/sql/dental_lab_billing_schema.sql
```

**Verify:**
```sql
SELECT COUNT(*) FROM dental_lab_pricing;
-- Should return 55 (25 orthodontic + 30 prosthetic items)
```

### Step 2: Start Servers (1 minute)

**Backend:**
```bash
cd backend
npm start
# Running on http://localhost:5000
```

**Frontend:**
```bash
cd frontend
npm run dev
# Running on http://localhost:5173
```

### Step 3: Create Your First Lab Job (2 minutes)

1. **Navigate to Dental Module**
   - Login to the system
   - Go to Dental Module → Lab Section

2. **Create Orthodontic Job**
   - Click "New Orthodontic Job"
   - Patient info auto-fills from selected patient
   - Fill in doctor name (required)
   - Set due date (required)

3. **Select Components**
   - Check items you need:
     - ✅ Hawley Retainer - Upper (₦15,000)
     - ✅ Labial Bow (₦3,000)
     - ✅ Adams Clasps (2) (₦4,000)
   
4. **Review Cost**
   - Cost calculator shows: ₦22,000
   - Breakdown by category displayed

5. **Create Job**
   - Click "Create Job & Generate Bill"
   - Job card number generated: ORTHO-1709876543210
   - Bill ready for cashier

### Step 4: Process Payment (1 minute)

1. **Go to Cashier Module**
   - Find pending bill: "Orthodontic Lab Work [LAB-JOB:ORTHO-1]"
   - Amount: ₦22,000

2. **Process Payment**
   - Select payment method (Cash/POS/Bank)
   - Complete payment

3. **Automatic Updates**
   - ✅ Job status: pending_payment → paid
   - ✅ Payment gates enabled
   - ✅ Lab can start work

### Step 5: Lab Workflow

**Lab Technician:**
1. View job details
2. Verify payment status (must be "paid")
3. Start work → Update status to "in_progress"
4. Complete work → Update status to "completed"
5. Deliver to patient → Update status to "delivered"

---

## 📋 Common Tasks

### Create Prosthetic Job

```javascript
// Same as orthodontic but with:
1. Shade information (tooth shade, mould, guide)
2. Different component options (crowns, bridges, dentures)
3. Higher price range
```

### Check Payment Status

**API:**
```bash
GET /dental-lab/orthodontic/1/payment-status
```

**Response:**
```json
{
  "payment_status": "paid",
  "amount_paid": 22000,
  "total_cost": 22000,
  "can_start_work": true,
  "can_deliver": true
}
```

### Update Job Status

**API:**
```bash
PUT /dental-lab/orthodontic/1/status-with-gates
```

**Body:**
```json
{
  "status": "in_progress",
  "updated_by": "TECH001"
}
```

---

## 💡 Key Features

### 1. Automatic Cost Calculation
- Select components → System calculates total
- Real-time pricing from database
- Grouped breakdown by category

### 2. Payment Gates
- **can_start_work**: Requires full payment
- **can_deliver**: Requires full payment
- System enforces gates automatically

### 3. Payment Detection
- Bill description includes: `[LAB-JOB:ORTHO-1]`
- System auto-detects and updates job
- No manual linking required

### 4. Payment Tracking
- All payments recorded in `dental_lab_payments`
- Supports partial payments
- Full payment history

---

## 🎯 Pricing Examples

### Orthodontic Items
| Item | Price |
|------|-------|
| Hawley Retainer - Upper | ₦15,000 |
| Wraparound - Upper | ₦18,000 |
| Expansion Plate | ₦25,000 |
| Labial Bow | ₦3,000 |
| Adams Clasps (2) | ₦4,000 |
| Z-Spring | ₦2,500 |
| Expansion Screw | ₦5,000 |

### Prosthetic Items
| Item | Price |
|------|-------|
| Complete Denture - Upper | ₦50,000 |
| Complete Denture - Both | ₦95,000 |
| Acrylic Partial - Upper | ₦35,000 |
| Cast Partial - Upper | ₦80,000 |
| PFM Crown | ₦25,000 |
| Zirconia Crown | ₦45,000 |
| PFM Bridge - 3 Unit | ₦70,000 |
| Porcelain Veneer | ₦30,000 |

---

## 🔧 Troubleshooting

### Issue: Cost calculator not loading
**Solution:**
```sql
-- Check pricing data
SELECT COUNT(*) FROM dental_lab_pricing;
-- If 0, re-run migration script
```

### Issue: Payment not updating job
**Solution:**
1. Check bill description includes `[LAB-JOB:ORTHO-1]`
2. Verify payment was processed successfully
3. Check `dental_lab_payments` table for record

### Issue: Cannot start work after payment
**Solution:**
```sql
-- Check payment status
SELECT payment_status, can_start_work, amount_paid, total_cost
FROM dental_lab_orthodontic_jobs
WHERE id = 1;

-- If paid but gates not enabled, update manually
UPDATE dental_lab_orthodontic_jobs
SET can_start_work = TRUE, can_deliver = TRUE
WHERE id = 1 AND payment_status = 'paid';
```

---

## 📚 Additional Resources

- **Complete Guide:** `DENTAL_LAB_COMPLETE_GUIDE.md`
- **Testing Guide:** `DENTAL_LAB_BILLING_TEST_GUIDE.md`
- **Status Report:** `DENTAL_LAB_BILLING_STATUS.md`
- **Implementation Summary:** `DENTAL_LAB_IMPLEMENTATION_SUMMARY.md`

---

## ✅ Success Checklist

- [ ] Database migration completed
- [ ] Pricing data loaded (55 items)
- [ ] Backend server running
- [ ] Frontend server running
- [ ] Created first orthodontic job
- [ ] Processed payment successfully
- [ ] Job status updated automatically
- [ ] Payment gates working
- [ ] Lab can start work after payment

---

## 🎉 You're Ready!

The dental lab billing system is now fully operational. Start creating lab jobs and processing payments!

**Need Help?** Check the troubleshooting section or refer to the complete guide.

