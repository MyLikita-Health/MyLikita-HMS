# DENTAL MODULE - COMPLETE IMPLEMENTATION GUIDE

## Overview
This guide provides step-by-step instructions to implement all missing dental features with proper billing integration and modern UI using your existing color scheme.

---

## PHASE 1: SETUP & FOUNDATION (Day 1)

### 1.1 Install Required Dependencies

```bash
cd frontend
npm install @fullcalendar/react @fullcalendar/daygrid @fullcalendar/timegrid @fullcalendar/interaction
npm install react-dnd react-dnd-html5-backend
npm install chart.js react-chartjs-2
npm install react-pdf @react-pdf/renderer
npm install socket.io-client
npm install formik yup
npm install react-select
npm install react-toastify
```

### 1.2 File Structure

Create the following directory structure:

```
frontend/src/components/dental/
├── appointments/
│   ├── AppointmentCalendar.jsx ✅ CREATED
│   ├── AppointmentScheduler.jsx ✅ CREATED
│   ├── AppointmentDetails.jsx ✅ CREATED
│   ├── DentistScheduleManager.jsx
│   ├── FollowUpScheduler.jsx
│   └── appointments.css ✅ CREATED
├── prescriptions/
│   ├── PrescriptionForm.jsx
│   ├── PrescriptionList.jsx
│   ├── MedicationDatabase.jsx
│   ├── PrescriptionPrint.jsx
│   └── prescriptions.css
├── procedures/
│   ├── ProcedureCatalog.jsx
│   ├── ProcedureSelector.jsx
│   ├── ProcedureCatalogManager.jsx
│   ├── EnhancedProcedures.jsx
│   └── procedures.css
├── treatment-plans/
│   ├── TreatmentPlanBuilder.jsx
│   ├── TreatmentTimeline.jsx
│   ├── TreatmentCostBreakdown.jsx
│   └── treatment-plans.css
├── documents/
│   ├── DocumentUpload.jsx
│   ├── ImageGallery.jsx
│   ├── XRayViewer.jsx
│   └── documents.css
├── billing/
│   ├── DentalBillingIntegration.jsx ✅ CREATED
│   ├── BillingHistory.jsx
│   └── billing.css
├── reports/
│   ├── DentalAnalyticsDashboard.jsx
│   ├── ProductionReport.jsx
│   └── reports.css
├── shared/
│   ├── dental-theme.css ✅ CREATED
│   ├── LoadingSpinner.jsx
│   ├── ErrorBoundary.jsx
│   └── helpers.js
└── lab/ (update existing)
    ├── CompleteOrthodonticForm.jsx
    ├── CompleteProstheticForm.jsx
    └── JobWorkflow.jsx
```

---

## PHASE 2: CRITICAL FEATURES IMPLEMENTATION

### 2.1 Prescription Module (Priority 1)

#### File: `frontend/src/components/dental/prescriptions/PrescriptionForm.jsx`

```jsx
import React, { useState, useEffect } from 'react';
import { useSelector } from 'react-redux';
import axios from 'axios';
import { apiURL } from '../../../redux/actions';
import Select from 'react-select';
import '../shared/dental-theme.css';
import './prescriptions.css';

const PrescriptionForm = ({ patientId, visitId, onSuccess }) => {
  const [medications, setMedications] = useState([]);
  const [selectedMeds, setSelectedMeds] = useState([]);
  const [prescriptionItems, setPrescriptionItems] = useState([{
    medication_name: '',
    dosage: '',
    frequency: '',
    duration: '',
    quantity: '',
    instructions: ''
  }]);
  const [loading, setLoading] = useState(false);
  
  const facilityId = useSelector((state) => state.auth.user.facilityId);
  const userId = useSelector((state) => state.auth.user.id);

  useEffect(() => {
    fetchMedications();
  }, []);

  const fetchMedications = async () => {
    try {
      // Fetch from existing drugs/pharmacy module
      const res = await axios.get(`${apiURL()}/drugs/list/${facilityId}`);
      const meds = res.data?.results || [];
      setMedications(meds.map(m => ({
        value: m.drug_name,
        label: `${m.drug_name} - ${m.strength || ''}`,
        ...m
      })));
    } catch (err) {
      console.error('Error fetching medications:', err);
    }
  };

  const addMedication = () => {
    setPrescriptionItems([...prescriptionItems, {
      medication_name: '',
      dosage: '',
      frequency: '',
      duration: '',
      quantity: '',
      instructions: ''
    }]);
  };

  const removeMedication = (index) => {
    setPrescriptionItems(prescriptionItems.filter((_, i) => i !== index));
  };

  const handleMedicationChange = (index, field, value) => {
    const updated = [...prescriptionItems];
    updated[index][field] = value;
    setPrescriptionItems(updated);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const prescription_id = `RX-${Date.now()}`;
      
      for (const item of prescriptionItems) {
        await axios.post(`${apiURL()}/dental/prescriptions/new`, {
          prescription_id,
          patient_id: patientId,
          visit_id: visitId,
          facilityId,
          ...item,
          prescribed_by: userId,
          prescribed_date: new Date().toISOString().split('T')[0],
          status: 'active'
        });
      }

      alert('Prescription created successfully!');
      if (onSuccess) onSuccess();
    } catch (err) {
      console.error('Error creating prescription:', err);
      alert('Failed to create prescription');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="prescription-form">
      <div className="card">
        <div className="card-header">
          <h3><i className="fa fa-prescription"></i> New Prescription</h3>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="card-body">
            {prescriptionItems.map((item, index) => (
              <div key={index} className="prescription-item">
                <div className="item-header">
                  <h4>Medication {index + 1}</h4>
                  {prescriptionItems.length > 1 && (
                    <button
                      type="button"
                      className="btn btn-danger btn-sm"
                      onClick={() => removeMedication(index)}
                    >
                      <i className="fa fa-trash"></i> Remove
                    </button>
                  )}
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Medication Name *</label>
                    <Select
                      options={medications}
                      onChange={(selected) => {
                        handleMedicationChange(index, 'medication_name', selected.value);
                        handleMedicationChange(index, 'dosage', selected.strength || '');
                      }}
                      placeholder="Search medication..."
                      isClearable
                    />
                  </div>

                  <div className="form-group">
                    <label>Dosage *</label>
                    <input
                      type="text"
                      value={item.dosage}
                      onChange={(e) => handleMedicationChange(index, 'dosage', e.target.value)}
                      className="form-control"
                      placeholder="e.g., 500mg"
                      required
                    />
                  </div>
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Frequency *</label>
                    <select
                      value={item.frequency}
                      onChange={(e) => handleMedicationChange(index, 'frequency', e.target.value)}
                      className="form-control"
                      required
                    >
                      <option value="">Select...</option>
                      <option value="Once daily">Once daily</option>
                      <option value="Twice daily">Twice daily</option>
                      <option value="Three times daily">Three times daily</option>
                      <option value="Four times daily">Four times daily</option>
                      <option value="Every 4 hours">Every 4 hours</option>
                      <option value="Every 6 hours">Every 6 hours</option>
                      <option value="Every 8 hours">Every 8 hours</option>
                      <option value="As needed">As needed</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Duration *</label>
                    <input
                      type="text"
                      value={item.duration}
                      onChange={(e) => handleMedicationChange(index, 'duration', e.target.value)}
                      className="form-control"
                      placeholder="e.g., 7 days"
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label>Quantity</label>
                    <input
                      type="text"
                      value={item.quantity}
                      onChange={(e) => handleMedicationChange(index, 'quantity', e.target.value)}
                      className="form-control"
                      placeholder="e.g., 21 tablets"
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label>Instructions</label>
                  <textarea
                    value={item.instructions}
                    onChange={(e) => handleMedicationChange(index, 'instructions', e.target.value)}
                    className="form-control"
                    rows="2"
                    placeholder="Take with food, avoid alcohol, etc."
                  />
                </div>
              </div>
            ))}

            <button
              type="button"
              className="btn btn-secondary"
              onClick={addMedication}
            >
              <i className="fa fa-plus"></i> Add Another Medication
            </button>
          </div>

          <div className="card-footer">
            <button
              type="submit"
              className="btn btn-primary btn-lg"
              disabled={loading}
            >
              {loading ? (
                <><i className="fa fa-spinner fa-spin"></i> Creating...</>
              ) : (
                <><i className="fa fa-check"></i> Create Prescription</>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default PrescriptionForm;
```

#### Backend Route Addition

Add to `backend/routes/dental.js`:

```javascript
// Prescriptions
app.post('/dental/prescriptions/new', dental.createPrescription);
app.get('/dental/prescriptions/:patientId/:facilityId', dental.getPrescriptions);
app.put('/dental/prescriptions/:id', dental.updatePrescription);
app.get('/dental/prescriptions/print/:prescriptionId', dental.printPrescription);
```

#### Backend Controller Addition

Add to `backend/controller/dental.js`:

```javascript
// =====================================================
// PRESCRIPTIONS
// =====================================================

exports.createPrescription = (req, res) => {
  const { prescription_id, patient_id, visit_id, facilityId, medication_name, dosage, frequency, duration, quantity, instructions, prescribed_by, prescribed_date, status } = req.body;

  const stmt = `INSERT INTO dental_prescriptions 
    (prescription_id, patient_id, visit_id, facilityId, medication_name, dosage, frequency, duration, quantity, instructions, prescribed_by, prescribed_date, status) 
    VALUES (:prescription_id, :patient_id, :visit_id, :facilityId, :medication_name, :dosage, :frequency, :duration, :quantity, :instructions, :prescribed_by, :prescribed_date, :status)`;

  db.sequelize
    .query(stmt, {
      replacements: { prescription_id, patient_id, visit_id, facilityId, medication_name, dosage, frequency, duration, quantity, instructions, prescribed_by, prescribed_date, status }
    })
    .then(results => res.status(201).json({ success: true, message: 'Prescription created', results }))
    .catch(err => res.status(500).json({ success: false, error: err.message }));
};

exports.getPrescriptions = (req, res) => {
  const { patientId, facilityId } = req.params;

  const stmt = `SELECT * FROM dental_prescriptions 
    WHERE patient_id = :patientId AND facilityId = :facilityId 
    ORDER BY prescribed_date DESC`;

  db.sequelize
    .query(stmt, {
      replacements: { patientId, facilityId }
    })
    .then(results => res.json({ success: true, results: results[0] }))
    .catch(err => res.status(500).json({ success: false, error: err.message }));
};
```

---

## PHASE 3: INTEGRATION CHECKLIST

### 3.1 Billing Integration Points

1. **Procedure Billing**
   - When procedure is completed → Post to `/post-charges`
   - Update procedure `payment_status` to 'paid'
   - Link to patient account

2. **Lab Job Billing**
   - When lab job is delivered → Post to `/post-charges`
   - Category: 'Dental Lab Services'
   - Update job `payment_status`

3. **Oral Care Shop**
   - Already integrated with `/oral-care/sales/new`
   - Updates inventory automatically

4. **Appointment Deposits**
   - Optional deposit on booking
   - Post to `/account/deposit`
   - Deduct from final bill

### 3.2 Color Scheme Usage

Use these CSS variables throughout:

```css
--dental-primary: #007bff;        /* Primary actions, headers */
--dental-primary-light: #e8e8ff;  /* Hover states, backgrounds */
--dental-success: #2ecc71;        /* Success messages, completed */
--dental-warning: #f39c12;        /* Warnings, pending */
--dental-danger: #e74c3c;         /* Errors, cancelled */
--dental-info: #3498db;           /* Info messages */
```

### 3.3 API Integration Pattern

Standard pattern for all components:

```javascript
import { useSelector } from 'react-redux';
import axios from 'axios';
import { apiURL } from '../../../redux/actions';

const facilityId = useSelector((state) => state.auth.user.facilityId);
const userId = useSelector((state) => state.auth.user.id);

// Always include facilityId and userId in requests
await axios.post(`${apiURL()}/endpoint`, {
  ...data,
  facilityId,
  created_by: userId
});
```

---

## PHASE 4: TESTING CHECKLIST

### 4.1 Appointment System
- [ ] Create appointment
- [ ] View calendar
- [ ] Drag-drop reschedule
- [ ] Confirm appointment
- [ ] Check-in patient
- [ ] Complete appointment
- [ ] Cancel appointment
- [ ] Auto follow-up scheduling
- [ ] Notification sending

### 4.2 Prescriptions
- [ ] Create prescription
- [ ] Search medications
- [ ] Print prescription
- [ ] View history
- [ ] Update status

### 4.3 Billing Integration
- [ ] Post procedure charges
- [ ] Apply discounts
- [ ] Multiple payment methods
- [ ] View billing history
- [ ] Generate receipts

### 4.4 Lab Module
- [ ] Create orthodontic job
- [ ] Create prosthetic job
- [ ] Update job status
- [ ] Assign technician
- [ ] Print job card
- [ ] Track inventory

---

## PHASE 5: DEPLOYMENT

### 5.1 Pre-Deployment Checklist

- [ ] All components use dental-theme.css
- [ ] All API calls include facilityId
- [ ] Error handling implemented
- [ ] Loading states added
- [ ] Responsive design tested
- [ ] Billing integration tested
- [ ] Print functionality works
- [ ] Notifications configured

### 5.2 Database Migration

Run SQL scripts in order:

```bash
cd backend/sql
./install_dental_modules.sh
```

### 5.3 Environment Variables

Add to `.env`:

```
DENTAL_MODULE_ENABLED=true
DENTAL_NOTIFICATIONS_ENABLED=true
DENTAL_AUTO_FOLLOWUP=true
```

---

## QUICK START COMMANDS

```bash
# Install dependencies
cd frontend && npm install

# Start development
npm run dev

# Build for production
npm run build

# Run backend
cd backend && npm start
```

---

## SUPPORT & DOCUMENTATION

- Backend API: `backend/DENTAL_API_COMPLETE.md`
- Database Schema: `backend/sql/DENTAL_QUICK_REFERENCE.md`
- Frontend Components: This guide
- Gap Analysis: `FRONTEND_IMPLEMENTATION_GAP_ANALYSIS.md`

---

## NEXT STEPS

1. ✅ Review this guide
2. Install dependencies
3. Implement Phase 1 (Appointments) - PARTIALLY DONE
4. Implement Phase 2 (Prescriptions) - CODE PROVIDED
5. Test billing integration
6. Deploy to staging
7. User acceptance testing
8. Production deployment

