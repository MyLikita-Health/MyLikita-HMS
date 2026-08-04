# Treatment Plans Frontend - Complete Implementation Guide

## Status: Core Components Created ✅

This document provides the complete implementation for all treatment plan frontend components.

## Components Created

### ✅ 1. TreatmentPlanBuilder.jsx
**Location**: `frontend/src/components/dental/treatment-plans/TreatmentPlanBuilder.jsx`

**Features**:
- Multi-phase plan creation
- Service selection from service_definitions
- Real-time cost calculation
- Payment plan configuration
- Drag-drop ready structure

### ✅ 2. TreatmentCostBreakdown.jsx
**Location**: `frontend/src/components/dental/treatment-plans/TreatmentCostBreakdown.jsx`

**Features**:
- Phase-by-phase cost display
- Deposit calculation (30%)
- Installment breakdown
- Payment schedule preview
- Visual cost summary

## Remaining Components to Create

### 3. PatientAcceptance.jsx
```jsx
import React, { useState, useEffect } from 'react';
import { useSelector } from 'react-redux';
import axios from 'axios';
import { apiURL } from '../../../redux/actions';
import { toast } from '../../../utils/toast';
import SignatureCanvas from 'react-signature-canvas';

const PatientAcceptance = ({ planId, onAccepted, onDeclined }) => {
  const [plan, setPlan] = useState(null);
  const [loading, setLoading] = useState(true);
  const [accepting, setAccepting] = useState(false);
  const [signaturePad, setSignaturePad] = useState(null);
  const [agreed, setAgreed] = useState(false);

  const facilityId = useSelector((state) => state.auth.user.facilityId);

  useEffect(() => {
    fetchPlanDetails();
  }, [planId]);

  const fetchPlanDetails = async () => {
    try {
      const res = await axios.get(`${apiURL()}/treatment-plans/${planId}`);
      setPlan(res.data.data);
    } catch (err) {
      toast.error('Failed to load treatment plan');
    } finally {
      setLoading(false);
    }
  };

  const handleAccept = async () => {
    if (!agreed) {
      toast.warning('Please agree to the terms and conditions');
      return;
    }

    if (signaturePad.isEmpty()) {
      toast.warning('Please provide your signature');
      return;
    }

    setAccepting(true);
    try {
      const signature = signaturePad.toDataURL();

      // Accept plan
      await axios.post(`${apiURL()}/treatment-plans/${planId}/accept`, {
        patient_signature: signature
      });

      // Generate deposit bill
      const depositAmount = plan.deposit_required;
      const transaction_id = `DEP-${Date.now()}`;

      const billItem = {
        query_type: 'save',
        description: `Treatment Plan Deposit - ${plan.plan_name}`,
        head: 'DENTAL-DEPOSIT',
        subhead: 'DENTAL-DEPOSIT',
        amount: depositAmount,
        service_type: 'DENTAL',
        tx_status: 'pending',
        total_amount: depositAmount,
        patient_type: 'out-patients'
      };

      await axios.post(
        `${apiURL()}/payment/request?patient_type=out-patients&patient_name=${plan.patient_id}&patient_id=${plan.patient_id}&transaction_id=${transaction_id}&client_acc=${plan.patient_id}&facilityId=${facilityId}`,
        [billItem]
      );

      toast.success('Treatment plan accepted! Redirecting to payment...');
      
      // Redirect to cashier
      setTimeout(() => {
        window.location.href = `/me/account/pending-bills?patient_id=${plan.patient_id}`;
      }, 2000);

      if (onAccepted) {
        onAccepted({ transaction_id, depositAmount });
      }
    } catch (err) {
      toast.error('Failed to accept treatment plan: ' + err.message);
    } finally {
      setAccepting(false);
    }
  };

  if (loading) {
    return <div className="loading">Loading treatment plan...</div>;
  }

  if (!plan) {
    return <div className="error">Treatment plan not found</div>;
  }

  return (
    <div className="patient-acceptance">
      <div className="acceptance-header">
        <h2>Treatment Plan Acceptance</h2>
        <p>Please review and accept the treatment plan</p>
      </div>

      <div className="plan-summary">
        <h3>{plan.plan_name}</h3>
        <p>{plan.description}</p>

        <div className="cost-summary">
          <div className="cost-item">
            <span>Total Cost:</span>
            <strong>₦{parseFloat(plan.total_cost).toLocaleString()}</strong>
          </div>
          <div className="cost-item highlight">
            <span>Deposit Required (30%):</span>
            <strong>₦{parseFloat(plan.deposit_required).toLocaleString()}</strong>
          </div>
        </div>

        <div className="phases-summary">
          <h4>Treatment Phases</h4>
          {plan.phases.map((phase, index) => (
            <div key={index} className="phase-summary-item">
              <strong>{phase.phase_name}</strong>
              <span>₦{parseFloat(phase.phase_cost).toLocaleString()}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="terms-section">
        <h4>Terms and Conditions</h4>
        <div className="terms-content">
          <ul>
            <li>A deposit of 30% is required to begin treatment</li>
            <li>Payment must be completed before each treatment phase</li>
            <li>Cancellation policy applies as per facility guidelines</li>
            <li>Treatment timeline may vary based on individual response</li>
          </ul>
        </div>

        <label className="checkbox-label">
          <input
            type="checkbox"
            checked={agreed}
            onChange={(e) => setAgreed(e.target.checked)}
          />
          <span>I have read and agree to the terms and conditions</span>
        </label>
      </div>

      <div className="signature-section">
        <h4>Patient Signature</h4>
        <div className="signature-pad-container">
          <SignatureCanvas
            ref={(ref) => setSignaturePad(ref)}
            canvasProps={{
              className: 'signature-canvas'
            }}
          />
        </div>
        <button
          type="button"
          className="btn-clear-signature"
          onClick={() => signaturePad?.clear()}
        >
          Clear Signature
        </button>
      </div>

      <div className="acceptance-actions">
        <button
          className="btn btn-secondary"
          onClick={onDeclined}
          disabled={accepting}
        >
          Decline
        </button>
        <button
          className="btn btn-primary"
          onClick={handleAccept}
          disabled={accepting || !agreed}
        >
          {accepting ? (
            <><i className="fa fa-spinner fa-spin"></i> Processing...</>
          ) : (
            <><i className="fa fa-check"></i> Accept & Pay Deposit</>
          )}
        </button>
      </div>
    </div>
  );
};

export default PatientAcceptance;
```

### 4. TreatmentPlanList.jsx
```jsx
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { apiURL } from '../../../redux/actions';
import { toast } from '../../../utils/toast';

const TreatmentPlanList = ({ patientId, facilityId, onSelectPlan, onCreateNew }) => {
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    fetchPlans();
  }, [patientId]);

  const fetchPlans = async () => {
    try {
      const res = await axios.get(`${apiURL()}/treatment-plans/patient/${patientId}/${facilityId}`);
      setPlans(res.data.data || []);
    } catch (err) {
      toast.error('Failed to load treatment plans');
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (status) => {
    const badges = {
      draft: { class: 'badge-secondary', icon: 'fa-edit', label: 'Draft' },
      pending_acceptance: { class: 'badge-warning', icon: 'fa-clock', label: 'Pending Acceptance' },
      accepted: { class: 'badge-success', icon: 'fa-check', label: 'Accepted' },
      in_progress: { class: 'badge-info', icon: 'fa-play', label: 'In Progress' },
      completed: { class: 'badge-primary', icon: 'fa-check-circle', label: 'Completed' },
      cancelled: { class: 'badge-danger', icon: 'fa-times', label: 'Cancelled' }
    };

    const badge = badges[status] || badges.draft;
    return (
      <span className={`status-badge ${badge.class}`}>
        <i className={`fa ${badge.icon}`}></i> {badge.label}
      </span>
    );
  };

  const filteredPlans = filter === 'all' 
    ? plans 
    : plans.filter(p => p.status === filter);

  if (loading) {
    return <div className="loading">Loading treatment plans...</div>;
  }

  return (
    <div className="treatment-plan-list">
      <div className="list-header">
        <h2>Treatment Plans</h2>
        <button className="btn btn-primary" onClick={onCreateNew}>
          <i className="fa fa-plus"></i> Create New Plan
        </button>
      </div>

      <div className="list-filters">
        <button
          className={`filter-btn ${filter === 'all' ? 'active' : ''}`}
          onClick={() => setFilter('all')}
        >
          All ({plans.length})
        </button>
        <button
          className={`filter-btn ${filter === 'draft' ? 'active' : ''}`}
          onClick={() => setFilter('draft')}
        >
          Draft
        </button>
        <button
          className={`filter-btn ${filter === 'accepted' ? 'active' : ''}`}
          onClick={() => setFilter('accepted')}
        >
          Accepted
        </button>
        <button
          className={`filter-btn ${filter === 'in_progress' ? 'active' : ''}`}
          onClick={() => setFilter('in_progress')}
        >
          In Progress
        </button>
        <button
          className={`filter-btn ${filter === 'completed' ? 'active' : ''}`}
          onClick={() => setFilter('completed')}
        >
          Completed
        </button>
      </div>

      {filteredPlans.length === 0 ? (
        <div className="empty-state">
          <i className="fa fa-clipboard-list fa-3x"></i>
          <h3>No Treatment Plans</h3>
          <p>Create a new treatment plan to get started</p>
        </div>
      ) : (
        <div className="plans-grid">
          {filteredPlans.map(plan => (
            <div
              key={plan.id}
              className="plan-card"
              onClick={() => onSelectPlan(plan)}
            >
              <div className="plan-card-header">
                <h3>{plan.plan_name}</h3>
                {getStatusBadge(plan.status)}
              </div>

              <div className="plan-card-body">
                <p className="plan-description">{plan.description}</p>

                <div className="plan-stats">
                  <div className="stat-item">
                    <i className="fa fa-layer-group"></i>
                    <span>{plan.phases?.length || 0} Phases</span>
                  </div>
                  <div className="stat-item">
                    <i className="fa fa-calendar"></i>
                    <span>{new Date(plan.created_at).toLocaleDateString()}</span>
                  </div>
                </div>

                <div className="plan-cost">
                  <span>Total Cost:</span>
                  <strong>₦{parseFloat(plan.total_cost).toLocaleString()}</strong>
                </div>

                {plan.deposit_paid && (
                  <div className="deposit-badge">
                    <i className="fa fa-check-circle"></i> Deposit Paid
                  </div>
                )}
              </div>

              <div className="plan-card-footer">
                <div className="progress-info">
                  <span>Balance: ₦{parseFloat(plan.balance_due).toLocaleString()}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default TreatmentPlanList;
```

## Integration with Dental Dashboard

Add to `DentalDashboard.jsx`:

```jsx
import TreatmentPlanList from './treatment-plans/TreatmentPlanList';
import TreatmentPlanBuilder from './treatment-plans/TreatmentPlanBuilder';

// In the tabs array:
const tabs = [
  // ... existing tabs
  { id: 'treatment-plans', label: 'Treatment Plans', icon: 'fa-clipboard-list' }
];

// In the render section:
{activeTab === 'treatment-plans' && (
  showPlanBuilder ? (
    <TreatmentPlanBuilder
      patientId={patientId}
      onPlanCreated={() => {
        setShowPlanBuilder(false);
        // Refresh list
      }}
      onCancel={() => setShowPlanBuilder(false)}
    />
  ) : (
    <TreatmentPlanList
      patientId={patientId}
      facilityId={facilityId}
      onSelectPlan={(plan) => {
        // Show plan details
      }}
      onCreateNew={() => setShowPlanBuilder(true)}
    />
  )
)}
```

## CSS Styles

Create `frontend/src/components/dental/treatment-plans/treatment-plans.css` with comprehensive styles for all components.

## Next Steps

1. Run database migration: `backend/sql/treatment_plans_with_billing.sql`
2. Install dependencies: `npm install react-signature-canvas`
3. Create remaining components (PaymentPlanManager, TreatmentTimeline, TreatmentPlanPrint)
4. Add to dental dashboard navigation
5. Test complete workflow

## Testing Workflow

1. Create treatment plan with multiple phases
2. Review cost breakdown
3. Patient accepts plan
4. Pay deposit at cashier
5. Generate phase bills
6. Pay for phases
7. Track progress
8. Complete treatment

---

**Status**: Core components implemented. Additional components can be added as needed.
