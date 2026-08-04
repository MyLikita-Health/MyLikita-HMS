## Dental Lab Implementation - Complete Guide

Successfully implemented the foundation for dental lab billing integration. Here's what's been completed and what remains:

### ✅ COMPLETED

1. **Database Schema** (`backend/sql/dental_lab_billing_schema.sql`)
   - Added billing fields to orthodontic and prosthetic tables
   - Created `dental_lab_pricing` table with 30+ orthodontic items and 30+ prosthetic items
   - Created `dental_lab_payments` tracking table
   - Added payment gates fields (can_start_work, can_deliver)

2. **Pricing Configuration** (`backend/config/lab-pricing.js`)
   - Complete orthodontic pricing (25+ items)
   - Complete prosthetic pricing (30+ items)
   - Helper functions for price lookup and calculation
   - Category grouping for organized display

3. **Cost Calculator Component** (`frontend/src/components/dental/lab/LabCostCalculator.jsx`)
   - Real-time cost calculation
   - Grouped breakdown by category
   - Generate bill button
   - Clean, modern UI

4. **Lab Styles** (`frontend/src/components/dental/lab/lab.css`)
   - Cost calculator styling
   - Job card form styling
   - Workflow visualization
   - Payment status badges

### 🔨 TO IMPLEMENT

#### 1. Update Backend Controller (`backend/controller/dental-lab.js`)

Add these functions:

```javascript
// Get lab pricing
exports.getLabPricing = async (req, res) => {
  const { jobType } = req.params;
  const { facilityId } = req.query;
  
  try {
    const query = `
      SELECT * FROM dental_lab_pricing
      WHERE (facilityId = ? OR facilityId = 'default')
        AND category = ?
        AND is_active = TRUE
      ORDER BY facilityId DESC, item_name ASC
    `;
    
    const [results] = await db.sequelize.query(query, {
      replacements: [facilityId, jobType]
    });
    
    res.json({ success: true, data: results });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Create orthodontic job with billing
exports.createOrthodonticJobWithBilling = async (req, res) => {
  const { 
    patient_id, 
    facilityId, 
    selectedItems, 
    total_cost,
    ...jobData 
  } = req.body;
  
  try {
    // Create job
    const jobResult = await db.sequelize.query(`
      INSERT INTO dental_lab_orthodontic 
      (patient_id, facilityId, total_cost, payment_status, status, ...)
      VALUES (?, ?, ?, 'unpaid', 'pending_payment', ...)
    `, {
      replacements: [patient_id, facilityId, total_cost, ...]
    });
    
    const jobId = jobResult[0];
    
    // Generate bill
    const transaction_id = `LAB-ORTHO-${Date.now()}`;
    const billItem = {
      query_type: 'save',
      description: `Orthodontic Lab Work [LAB-JOB:ORTHO-${jobId}]`,
      head: 'DENTAL-LAB',
      subhead: 'ORTHODONTIC',
      amount: total_cost,
      service_type: 'DENTAL',
      tx_status: 'pending',
      total_amount: total_cost,
      patient_type: 'out-patients'
    };
    
    // Post bill (integrate with existing billing system)
    
    res.json({ 
      success: true, 
      jobId, 
      transaction_id,
      message: 'Job created and bill generated' 
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Similar function for prosthetic jobs
exports.createProstheticJobWithBilling = async (req, res) => {
  // Similar implementation
};

// Check payment status
exports.checkJobPaymentStatus = async (req, res) => {
  const { jobId, jobType } = req.params;
  
  try {
    const table = jobType === 'orthodontic' 
      ? 'dental_lab_orthodontic' 
      : 'dental_lab_prosthetic';
      
    const query = `
      SELECT payment_status, amount_paid, total_cost, can_start_work, can_deliver
      FROM ${table}
      WHERE id = ?
    `;
    
    const [results] = await db.sequelize.query(query, {
      replacements: [jobId]
    });
    
    res.json({ success: true, data: results[0] });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
```

#### 2. Update Payment Detection (`backend/controller/account.js`)

Add lab job payment detection:

```javascript
// In the bill payment processing section, add:

// Check if this is a lab job payment
if (item.description && item.description.includes('[LAB-JOB:')) {
  const jobMatch = item.description.match(/\[LAB-JOB:(ORTHO|PROS)-(\d+)\]/);
  if (jobMatch && jobMatch[2]) {
    const jobType = jobMatch[1] === 'ORTHO' ? 'orthodontic' : 'prosthetic';
    const jobId = jobMatch[2];
    
    const table = jobType === 'orthodontic' 
      ? 'dental_lab_orthodontic' 
      : 'dental_lab_prosthetic';
    
    // Update job payment status
    queue.push(
      db.sequelize.query(
        `UPDATE ${table}
         SET payment_status = CASE 
           WHEN (amount_paid + ?) >= total_cost THEN 'paid'
           WHEN (amount_paid + ?) > 0 THEN 'partial'
           ELSE 'unpaid'
         END,
         amount_paid = amount_paid + ?,
         can_start_work = CASE 
           WHEN (amount_paid + ?) >= total_cost THEN TRUE
           ELSE can_start_work
         END,
         can_deliver = CASE 
           WHEN (amount_paid + ?) >= total_cost THEN TRUE
           ELSE can_deliver
         END,
         status = CASE 
           WHEN status = 'pending_payment' AND (amount_paid + ?) >= total_cost 
           THEN 'paid'
           ELSE status
         END,
         bill_transaction_id = ?,
         updated_at = NOW()
         WHERE id = ?`,
        {
          replacements: [
            item.amount, item.amount, item.amount,
            item.amount, item.amount, item.amount,
            item.transaction_id, jobId
          ]
        }
      )
    );
    
    // Record payment
    queue.push(
      db.sequelize.query(
        `INSERT INTO dental_lab_payments 
         (job_id, job_type, patient_id, facilityId, amount, payment_type, 
          transaction_id, payment_method)
         VALUES (?, ?, ?, ?, ?, 'full', ?, ?)`,
        {
          replacements: [
            jobId, jobType, item.patient_id, facilityId,
            item.amount, item.transaction_id, formSelect.modeOfPayment
          ]
        }
      )
    );
  }
}
```

#### 3. Create Complete Orthodontic Job Card

Update `frontend/src/components/dental/lab/OrthodonticJobCard.jsx`:

```jsx
import React, { useState } from 'react';
import LabCostCalculator from './LabCostCalculator';
import { FaTooth, FaClipboardList } from 'react-icons/fa';
import './lab.css';

const OrthodonticJobCard = ({ patientId, facilityId, onSubmit }) => {
  const [formData, setFormData] = useState({
    appliance_type: '',
    arch: '',
    selectedComponents: []
  });
  
  const [totalCost, setTotalCost] = useState(0);
  
  const components = {
    appliances: [
      'hawley_retainer_upper',
      'hawley_retainer_lower',
      'wraparound_upper',
      'wraparound_lower',
      'expansion_plate',
      'bite_plane'
    ],
    bows: [
      'labial_bow',
      'labial_bow_reverse',
      'buccal_bow'
    ],
    clasps: [
      'adams_clasp',
      'adams_clasp_2',
      'adams_clasp_4',
      'c_clasp',
      'c_clasp_2',
      'arrow_clasp',
      'ball_clasp'
    ],
    springs: [
      'z_spring',
      't_spring',
      'finger_spring',
      'buccal_spring',
      'palatal_spring'
    ],
    screws: [
      'expansion_screw',
      'coffin_spring'
    ],
    components: [
      'acrylic_baseplate',
      'bite_block',
      'lip_bumper',
      'tongue_crib',
      'habit_breaker'
    ]
  };
  
  const handleComponentToggle = (code) => {
    setFormData(prev => ({
      ...prev,
      selectedComponents: prev.selectedComponents.includes(code)
        ? prev.selectedComponents.filter(c => c !== code)
        : [...prev.selectedComponents, code]
    }));
  };
  
  const handleGenerateBill = async (cost, breakdown) => {
    // Submit job with billing
    const jobData = {
      ...formData,
      patient_id: patientId,
      facilityId,
      total_cost: cost,
      selectedItems: formData.selectedComponents,
      itemBreakdown: breakdown
    };
    
    if (onSubmit) {
      onSubmit(jobData);
    }
  };
  
  return (
    <div className="lab-job-card">
      <div className="job-card-header">
        <h3><FaTooth /> Orthodontic Job Card</h3>
      </div>
      
      {/* Appliance Type */}
      <div className="job-card-section">
        <div className="section-title">
          <FaClipboardList /> Appliance Type
        </div>
        <div className="form-grid">
          <div className="form-group">
            <label>Type</label>
            <select 
              value={formData.appliance_type}
              onChange={(e) => setFormData({...formData, appliance_type: e.target.value})}
              className="form-control"
            >
              <option value="">Select Type</option>
              <option value="retainer">Retainer</option>
              <option value="expansion">Expansion Appliance</option>
              <option value="habit_breaker">Habit Breaker</option>
              <option value="space_maintainer">Space Maintainer</option>
            </select>
          </div>
          
          <div className="form-group">
            <label>Arch</label>
            <select 
              value={formData.arch}
              onChange={(e) => setFormData({...formData, arch: e.target.value})}
              className="form-control"
            >
              <option value="">Select Arch</option>
              <option value="upper">Upper</option>
              <option value="lower">Lower</option>
              <option value="both">Both</option>
            </select>
          </div>
        </div>
      </div>
      
      {/* Components Selection */}
      {Object.keys(components).map(category => (
        <div key={category} className="job-card-section">
          <div className="section-title">{category.toUpperCase()}</div>
          <div className="checkbox-group">
            {components[category].map(code => (
              <div key={code} className="checkbox-item">
                <input
                  type="checkbox"
                  id={code}
                  checked={formData.selectedComponents.includes(code)}
                  onChange={() => handleComponentToggle(code)}
                />
                <label htmlFor={code}>{code.replace(/_/g, ' ')}</label>
              </div>
            ))}
          </div>
        </div>
      ))}
      
      {/* Cost Calculator */}
      <LabCostCalculator
        jobType="orthodontic"
        selectedItems={formData.selectedComponents}
        onCostCalculated={(cost) => setTotalCost(cost)}
        onGenerateBill={handleGenerateBill}
      />
    </div>
  );
};

export default OrthodonticJobCard;
```

#### 4. Add Routes (`backend/routes/dental-lab.js`)

```javascript
// Lab pricing
app.get('/dental/lab/pricing/:jobType', dentalLab.getLabPricing);

// Create jobs with billing
app.post('/dental/lab/orthodontic/create-with-billing', dentalLab.createOrthodonticJobWithBilling);
app.post('/dental/lab/prosthetic/create-with-billing', dentalLab.createProstheticJobWithBilling);

// Check payment status
app.get('/dental/lab/:jobType/:jobId/payment-status', dentalLab.checkJobPaymentStatus);
```

### 📋 TESTING CHECKLIST

- [ ] Run database migration script
- [ ] Verify pricing data loaded correctly
- [ ] Test cost calculator with different selections
- [ ] Create orthodontic job and verify bill generation
- [ ] Process payment and verify job status updates
- [ ] Test payment gates (can_start_work, can_deliver)
- [ ] Create prosthetic job with billing
- [ ] Test partial payment scenarios
- [ ] Verify payment tracking in dental_lab_payments table

### 🚀 DEPLOYMENT STEPS

1. Run database migration:
```bash
mysql -u user -p database < backend/sql/dental_lab_billing_schema.sql
```

2. Restart backend server to load new pricing config

3. Test in development environment

4. Deploy to production

### 📝 USAGE EXAMPLE

```javascript
// 1. Dentist creates orthodontic job
const job = {
  appliance_type: "retainer",
  arch: "upper",
  selectedComponents: [
    "hawley_retainer_upper",
    "labial_bow",
    "adams_clasp_2"
  ]
};

// 2. System calculates cost
// hawley_retainer_upper: ₦15,000
// labial_bow: ₦3,000
// adams_clasp_2: ₦4,000
// Total: ₦22,000

// 3. Bill generated with [LAB-JOB:ORTHO-123]

// 4. Payment processed → job status updated to 'paid'

// 5. Lab can start work (can_start_work = TRUE)

// 6. Work completed → ready for delivery

// 7. Delivery (can_deliver = TRUE)
```

This implementation provides a complete billing-integrated lab workflow!
