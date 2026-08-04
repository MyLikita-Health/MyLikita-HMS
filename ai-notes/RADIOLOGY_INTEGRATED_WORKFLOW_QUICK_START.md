# Radiology Integrated Workflow - Quick Start Guide

## What's New?

The radiology request form now supports:
- ✅ Creating requests for new patients (no pre-registration needed)
- ✅ Selecting multiple procedures at once
- ✅ Visual cart showing procedures and prices
- ✅ Automatic billing creation
- ✅ Automatic appointment creation when payment is made

## How to Use

### Creating a Request for a New Patient

1. **Navigate**: Radiology → Patient Requests → New Request

2. **Select Patient Type**: Click "New Patient"

3. **Enter Patient Details**:
   - Surname (required)
   - First Name (required)
   - Middle Name (optional)
   - Date of Birth (required)
   - Gender (required)
   - Phone (required)
   - Email (optional)

4. **Select Procedures**:
   - Type in the search box to find procedures
   - Click on a procedure to add it to cart
   - Add as many procedures as needed
   - View the cart on the right side

5. **Enter Clinical Details**:
   - Priority (Routine/Urgent/Emergency/STAT)
   - Requested Date
   - Clinical Indication (required)
   - Clinical Notes (optional)
   - Special Instructions (optional)

6. **Submit**: Click "Submit Request & Create Bill"

7. **Result**: 
   - Patient is created automatically
   - Requests are created for each procedure
   - Bills are created
   - Pending transaction is created for cashier

### Creating a Request for an Existing Patient

1. **Navigate**: Radiology → Patient Requests → New Request

2. **Select Patient Type**: Click "Existing Patient"

3. **Search Patient**: 
   - Type patient name, phone, or ID
   - Select from dropdown

4. **Select Procedures**: (same as above)

5. **Enter Clinical Details**: (same as above)

6. **Submit**: Click "Submit Request & Create Bill"

### Processing Payment (Cashier)

1. **Navigate**: Account Module → Pending Transactions

2. **Find Transaction**: 
   - Look for "Radiology: [Procedure Names]"
   - Amount shows total for all procedures

3. **Process Payment**:
   - Select payment method
   - Complete transaction

4. **Automatic Actions**:
   - Appointments are created automatically
   - Appointment date is set to today
   - Request status changes to "Scheduled"
   - Patient can proceed to radiology department

### Viewing Appointments

1. **Navigate**: Radiology → Appointments

2. **View**: All appointments created from paid requests

3. **Continue**: Normal workflow (examination → report → finalize)

## Cart Features

### Adding Procedures
- Search by name or category
- Click to add to cart
- Duplicate prevention

### Viewing Cart
- Right sidebar shows all selected procedures
- Each item shows:
  - Procedure name
  - Category
  - Price in Nigerian Naira (₦)
- Total amount calculated automatically

### Removing Procedures
- Click trash icon next to procedure
- Cart updates immediately
- Total recalculates

## Tips

1. **Multiple Procedures**: Add all procedures the patient needs in one request
2. **New Patients**: No need to register patient first, do it in the request form
3. **Clinical Indication**: Be specific to help radiologist understand the need
4. **Priority**: Use STAT or Emergency for urgent cases
5. **Payment**: Patient must pay at cashier before examination can be done

## Workflow Summary

```
Request → Bill → Payment → Appointment → Examination → Report
```

**Before**: Patient had to be registered first, single procedure per request, manual appointment creation

**Now**: Create patient in request form, multiple procedures at once, automatic appointment creation

## Common Questions

**Q: Can I add procedures after submitting?**
A: No, but you can create a new request for additional procedures.

**Q: What if patient doesn't pay immediately?**
A: The pending transaction stays in the system until paid. Appointment is only created after payment.

**Q: Can I edit the cart after submission?**
A: No, verify the cart before submitting. You can cancel and create a new request if needed.

**Q: What happens if I add the same procedure twice?**
A: The system prevents duplicates and shows an alert.

**Q: Can I select appointment time?**
A: Currently, appointment date is set to current date. Time slot selection may be added in future.

## Example Scenario

**Patient**: John Doe (new patient)
**Procedures**: Chest X-Ray (₦15,000) + Abdominal Ultrasound (₦20,000)
**Total**: ₦35,000

**Steps**:
1. Doctor creates request with both procedures
2. System creates patient record, 2 requests, 2 bills, 1 pending transaction
3. Patient goes to cashier
4. Cashier processes ₦35,000 payment
5. System automatically creates 2 appointments for today
6. Patient proceeds to radiology for both examinations

## Need Help?

- Check the cart before submitting
- Verify patient details for new patients
- Ensure clinical indication is clear
- Contact IT support if you encounter errors

---

**Status**: Ready to use! Start creating integrated radiology requests now.
