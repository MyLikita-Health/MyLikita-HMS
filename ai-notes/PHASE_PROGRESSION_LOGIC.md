# Phase Progression Logic

## How Phases Become Ready

### Phase 1 (First Phase)
- Becomes `ready` when deposit is paid
- Handled in `account.js` when deposit payment is processed
- Looks for `[PLAN-ID:xxx]` in bill description

### Phase 2+ (Subsequent Phases)
A phase becomes `ready` when BOTH conditions are met:
1. **Previous phase is completed** (all procedures done)
2. **Current phase is paid** (payment_status = 'paid')

## Status Flow

### Phase Status
```
pending → ready → in_progress → completed
```

- **pending**: Waiting for payment OR previous phase completion
- **ready**: Paid AND previous phase done (can be started)
- **in_progress**: Phase has been started
- **completed**: All procedures in phase are completed

### Payment Status
```
unpaid → paid
```

## Automatic Updates

### When Deposit is Paid
**File:** `backend/controller/account.js`
**Trigger:** Bill payment with `[PLAN-ID:xxx]`
**Action:**
- Sets `deposit_paid = TRUE`
- Sets Phase 1 `status = 'ready'`
- Sets plan `status = 'accepted'`

### When Phase Payment is Made
**File:** `backend/controller/account.js`
**Trigger:** Bill payment with `[PHASE-ID:xxx]`
**Action:**
- Sets phase `payment_status = 'paid'`
- Sets phase `status = 'ready'` (immediately)
- Updates plan totals

### When Phase is Completed
**File:** `backend/controller/treatment-plan-clinical.js`
**Function:** `updatePhaseProgress()`
**Trigger:** Last procedure in phase is completed
**Action:**
- Sets current phase `status = 'completed'`
- Checks if next phase is paid
- If next phase is paid, sets next phase `status = 'ready'`

## Troubleshooting

### Phase 2 Not Showing "Start Phase" Button

**Possible Causes:**
1. Phase 2 status is still `pending` (not `ready`)
2. Phase 2 payment hasn't been made
3. Phase 1 is not fully completed

**Check:**
```sql
SELECT 
  phase_number,
  phase_name,
  status,
  payment_status,
  procedures_completed,
  procedures_total
FROM dental_treatment_plan_phases
WHERE plan_id = 'YOUR_PLAN_ID'
ORDER BY phase_number;
```

**Fix Manually:**
```sql
-- If Phase 1 is completed and Phase 2 is paid, but Phase 2 is still pending:
UPDATE dental_treatment_plan_phases
SET status = 'ready'
WHERE plan_id = 'YOUR_PLAN_ID'
  AND phase_number = 2
  AND payment_status = 'paid'
  AND status = 'pending';
```

**Or run the fix script:**
```bash
mysql -u your_user -p your_database < backend/sql/fix_next_phase_ready.sql
```

## Payment Workflow

### Option 1: Pay All Upfront
1. Patient pays deposit (30%) → Phase 1 becomes `ready`
2. Patient pays Phase 2 amount → Phase 2 `payment_status = 'paid'` but `status = 'pending'`
3. Complete Phase 1 → Phase 2 automatically becomes `ready`

### Option 2: Pay Per Phase
1. Patient pays deposit (30%) → Phase 1 becomes `ready`
2. Complete Phase 1 → Phase 2 stays `pending` (not paid yet)
3. Patient pays Phase 2 amount → Phase 2 becomes `ready` (previous phase already done)

## Code References

### Phase Status Check (Frontend)
**File:** `frontend/src/components/dental/treatment-plans/PhaseExecution.jsx`
```javascript
const canStart = phase.status === 'ready' || phase.status === 'pending';
```

### Phase Completion Logic (Backend)
**File:** `backend/controller/treatment-plan-clinical.js`
```javascript
// When phase is completed, check next phase
if (completed === total) {
  // Update next phase to 'ready' if it's paid
  UPDATE dental_treatment_plan_phases
  SET status = 'ready'
  WHERE plan_id = ? AND phase_number = ? 
    AND status = 'pending' AND payment_status = 'paid'
}
```

### Payment Processing (Backend)
**File:** `backend/controller/account.js`
```javascript
// When phase payment is made
UPDATE dental_treatment_plan_phases 
SET payment_status = 'paid',
    status = 'ready'  // Immediately ready if paid
WHERE id = :phase_id
```

## Important Notes

1. **Payment First, Then Work**: A phase must be paid before it can be started
2. **Sequential Execution**: Phases must be completed in order
3. **Automatic Progression**: System automatically makes next phase ready when conditions are met
4. **Manual Override**: Admins can manually update phase status if needed

## Testing Checklist

- [ ] Pay deposit → Phase 1 becomes ready
- [ ] Start Phase 1 → Phase 1 becomes in_progress
- [ ] Complete all Phase 1 procedures → Phase 1 becomes completed
- [ ] Pay Phase 2 before completing Phase 1 → Phase 2 stays pending until Phase 1 done
- [ ] Complete Phase 1 when Phase 2 is paid → Phase 2 automatically becomes ready
- [ ] Pay Phase 2 after completing Phase 1 → Phase 2 immediately becomes ready
- [ ] Try to start Phase 2 when pending → No button shows
- [ ] Try to start Phase 2 when ready → "Start Phase" button shows
