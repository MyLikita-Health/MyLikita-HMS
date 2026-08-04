# Radiology Integrated Workflow Implementation Plan

## Overview
Enhance the radiology request workflow to support both new and existing patients, with integrated billing and automatic appointment creation upon payment.

## Workflow Requirements

### 1. Request Form Enhancement
**Patient Selection**:
- Option 1: New Patient
  - Name (required)
  - Age (required)
  - Gender (required)
  - Phone (required)
  - Email (optional)
- Option 2: Existing Patient
  - Current typeahead search (keep as is)

**Procedure Selection**:
- Multi-select procedures
- Add to cart functionality
- Right-side cart preview showing:
  - Procedure name
  - Price per procedure
  - Subtotal
  - Total amount

**Request Details**:
- Clinical indication
- Priority
- Special instructions
- Requesting doctor

### 2. Backend Workflow

**Step 1: Request Submission**
```
IF new patient:
  - Create patient record in patientrecords table
  - Get new patient_id
ELSE:
  - Use existing patient_id

FOR EACH selected procedure:
  - Create radiology_request
  - Create radiology_billing record (status: pending)
  - Link billing to pending_txn (for cashier)
```

**Step 2: Payment at Cashier**
```
WHEN payment is made in account module:
  - Update radiology_billing (status: paid)
  - Update pending_txn (status: completed)
  - Auto-create radiology_appointment (date: current date)
  - Update request status to 'scheduled'
```

**Step 3: Continue Normal Flow**
- Technician performs examination
- Radiologist creates report
- Report finalized
- Patient receives results

## Implementation Tasks

### Backend Changes

#### 1. New Endpoint: Create Request with Billing
**File**: `backend/controller/radiology-requests.js`
**Method**: `createRequestWithBilling`

**Logic**:
1. Validate input
2. Create patient if new
3. Create requests for each procedure
4. Create billing records
5. Create pending_txn entries
6. Return summary

#### 2. Payment Webhook/Trigger
**File**: `backend/controller/account.js` or `radiology-billing.js`
**Method**: `onPaymentComplete`

**Logic**:
1. Listen for payment completion
2. Find related radiology billing
3. Create appointments for paid procedures
4. Update statuses

#### 3. Database Schema Updates
**Table**: `radiology_billing`
- Add `pending_txn_id` column (link to pending_txn)

**Table**: `radiology_requests`
- Add `billing_id` column (link to billing)

### Frontend Changes

#### 1. Enhanced Request Form
**File**: `frontend/src/components/radiology/requests/RequestForm.jsx`

**Features**:
- Patient type toggle (New/Existing)
- New patient form fields
- Multi-procedure selector with search
- Cart component (right sidebar)
- Price calculation
- Submit with billing creation

#### 2. Cart Component
**File**: `frontend/src/components/radiology/requests/ProcedureCart.jsx`

**Features**:
- List selected procedures
- Show prices
- Remove items
- Calculate total
- Display summary

### Integration Points

#### 1. Account Module Integration
**Existing Flow**:
```
Cashier → Account Module → Pending Transactions → Process Payment
```

**Enhanced Flow**:
```
Radiology Request → Creates pending_txn
Cashier → Sees pending transaction
Cashier → Processes payment
System → Triggers appointment creation
```

#### 2. Appointment Auto-Creation
**Trigger**: Payment completion
**Action**: Create appointment with current date
**Status**: scheduled

## Database Schema Changes

### 1. Add Columns

```sql
-- Link billing to pending_txn
ALTER TABLE radiology_billing 
ADD COLUMN pending_txn_id VARCHAR(255),
ADD INDEX idx_pending_txn (pending_txn_id);

-- Link request to billing
ALTER TABLE radiology_requests 
ADD COLUMN billing_id VARCHAR(255),
ADD INDEX idx_billing (billing_id);
```

### 2. Pending Transaction Format

```sql
INSERT INTO pending_txn (
  id, patientId, amount, description, 
  service_type, service_id, status, facilityId
) VALUES (
  uuid(), patient_id, total_amount, 
  'Radiology: [Procedure Names]',
  'radiology', billing_id, 'pending', facilityId
);
```

## API Endpoints

### New Endpoints

1. **POST /radiology/requests/with-billing**
   - Create request(s) with billing
   - Support new patient creation
   - Create pending transactions

2. **POST /radiology/billing/payment-webhook**
   - Handle payment completion
   - Create appointments
   - Update statuses

3. **POST /patientrecords/quick-register**
   - Quick patient registration
   - Minimal required fields
   - Return patient_id

### Modified Endpoints

1. **POST /account/process-payment**
   - Add radiology billing update
   - Trigger appointment creation

## UI/UX Flow

### Request Form Layout

```
┌─────────────────────────────────────────────────────────┐
│ Create Radiology Request                                │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ Patient Type: ○ New Patient  ● Existing Patient        │
│                                                         │
│ [Patient Search/Form]                                   │
│                                                         │
│ Requesting Doctor: [Dropdown]                           │
│                                                         │
│ Select Procedures:                                      │
│ [Search procedures...                    ]              │
│                                                         │
│ ┌─────────────────────┐  ┌──────────────────────────┐ │
│ │ Available           │  │ Cart                     │ │
│ │ Procedures          │  │                          │ │
│ │                     │  │ 1. Chest X-Ray  ₦15,000 │ │
│ │ □ Chest X-Ray       │  │ 2. CT Head      ₦80,000 │ │
│ │ □ CT Head           │  │                          │ │
│ │ □ Ultrasound        │  │ Subtotal:      ₦95,000  │ │
│ │ ...                 │  │ Discount:           ₦0  │ │
│ │                     │  │ Total:         ₦95,000  │ │
│ └─────────────────────┘  └──────────────────────────┘ │
│                                                         │
│ Clinical Indication: [Textarea]                         │
│ Priority: [Dropdown]                                    │
│                                                         │
│ [Cancel]                    [Submit Request & Bill]     │
└─────────────────────────────────────────────────────────┘
```

## Testing Checklist

- [ ] Create request for new patient
- [ ] Create request for existing patient
- [ ] Select multiple procedures
- [ ] View cart with prices
- [ ] Submit creates billing
- [ ] Pending transaction appears in cashier
- [ ] Payment triggers appointment creation
- [ ] Appointment has correct date
- [ ] Request status updates correctly
- [ ] Continue normal workflow

## Benefits

1. **Streamlined Process**: One-stop request and billing
2. **New Patient Support**: No need to pre-register patients
3. **Automatic Appointments**: No manual scheduling after payment
4. **Integrated Billing**: Seamless cashier workflow
5. **Better UX**: Clear cart preview with pricing
6. **Audit Trail**: Complete tracking from request to payment

## Next Steps

1. Create database migration script
2. Implement backend endpoints
3. Create enhanced request form
4. Build cart component
5. Integrate with account module
6. Test complete workflow
7. Document for users
