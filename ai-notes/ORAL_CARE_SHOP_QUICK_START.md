# ORAL CARE SHOP - QUICK START GUIDE

**Date:** March 4, 2026

---

## 🚀 GETTING STARTED

### Step 1: Run Database Migration
```bash
mysql -u root -p your_database_name < backend/sql/update_dental_prescriptions_table.sql
```

### Step 2: Grant User Access
In your admin panel, ensure shop staff have "Oral Care Shop" in their access permissions.

### Step 3: Start Testing
Navigate to: `/me/oral-care`

---

## 📋 WORKFLOW OVERVIEW

### For Dentists
1. Open patient record
2. Click "Create Prescription"
3. Add medications
4. Click "Save Prescription"
5. Tell patient: "Go to Oral Care Shop"

### For Shop Staff
1. **Pending Prescriptions Tab**
   - Click "Process Prescription"
   - Match each medication with inventory
   - If not in stock, select replacement
   - Click "Generate Bill"
   - Send patient to cashier

2. **After Patient Pays**
   - Patient returns with receipt
   - Go to "Ready for Dispensing" tab
   - Click "Verify & Dispense"
   - Click "Dispense & Complete"

---

## 🔑 KEY ENDPOINTS

### Backend API
```
GET  /oral-care-shop/prescriptions/pending/:facilityId
GET  /oral-care-shop/prescriptions/billed/:facilityId
GET  /oral-care-shop/prescriptions/:prescriptionId
PUT  /oral-care-shop/prescriptions/:prescriptionId/match-inventory
POST /oral-care-shop/prescriptions/:prescriptionId/generate-bill
PUT  /oral-care-shop/prescriptions/:prescriptionId/verify-payment
PUT  /oral-care-shop/prescriptions/:prescriptionId/dispense
```

### Frontend Routes
```
/me/oral-care - Main dashboard
```

---

## 🎨 UI COMPONENTS

### Main Dashboard
- **Pending Prescriptions** - Prescriptions needing billing
- **Ready for Dispensing** - Prescriptions ready to dispense

### Modals
- **Billing Modal** - Match inventory and generate bill
- **Dispensing Modal** - Verify payment and dispense

---

## 🐛 TROUBLESHOOTING

### "No pending prescriptions"
- Check if dentist created prescription
- Verify prescription has `billing_status = 'pending_billing'`

### "Failed to load prescriptions"
- Check backend is running
- Check database connection
- Verify SQL migration ran successfully

### "Payment not verified"
- Check if patient paid at cashier
- Verify transaction_id matches in `pending_txn` table
- Check `tx_status = 'paid'` in `pending_txn`

### "Cannot match inventory"
- Verify inventory items exist in `drugs` table
- Check `selling_price` is set
- Ensure `facilityId` matches

---

## 📊 DATABASE TABLES

### dental_prescriptions
- `billing_status` - pending_billing | billed | paid | dispensed
- `inventory_item_id` - Matched inventory item
- `is_replaced` - TRUE if replaced
- `unit_price` - Price from inventory
- `total_price` - unit_price × quantity
- `transaction_id` - Reference to pending_txn

### pending_txn
- `transaction_id` - Matches prescription_id
- `tx_status` - pending | paid
- `service_type` - PHARMACY

---

## ✅ TESTING CHECKLIST

Quick test flow:
1. [ ] Create prescription as dentist
2. [ ] See prescription in Pending tab
3. [ ] Match all medications
4. [ ] Generate bill
5. [ ] Pay at cashier
6. [ ] See prescription in Dispensing tab
7. [ ] Verify payment
8. [ ] Dispense prescription

---

## 🎯 SUCCESS INDICATORS

- Prescription form has NO billing step
- Success message mentions "Oral Care Shop"
- Pending prescriptions appear in shop
- Inventory matching works
- Bill generates in pending_txn
- Payment verification works
- Dispensing completes successfully

---

**Need Help?** Check `ORAL_CARE_SHOP_IMPLEMENTATION_COMPLETE.md` for full details.
