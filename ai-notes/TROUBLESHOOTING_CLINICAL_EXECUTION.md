# Troubleshooting Clinical Execution Issues

## Issue 1: Timeline Shows No Dates

### Symptoms
- Timeline section is blank
- No "Started", "Est. Completion", or "Completed" dates showing

### Causes & Solutions

#### Cause 1: Dates Not Set During Plan Creation
**Check:** Look at the treatment plan in the database
```sql
SELECT start_date, estimated_completion_date, actual_completion_date 
FROM dental_treatment_plans 
WHERE plan_id = 'YOUR_PLAN_ID';
```

**Solution:** These dates are optional and may not be set initially. The system now shows:
"Timeline dates will be set when treatment begins"

**To Fix:** You can manually set dates:
```sql
UPDATE dental_treatment_plans
SET start_date = CURDATE(),
    estimated_completion_date = DATE_ADD(CURDATE(), INTERVAL 30 DAY)
WHERE plan_id = 'YOUR_PLAN_ID';
```

#### Cause 2: Dates Are NULL in Database
**Solution:** This is normal for new plans. Dates will be set when:
- `start_date` - When first phase is started
- `estimated_completion_date` - Can be set in TreatmentPlanBuilder (future enhancement)
- `actual_completion_date` - When all procedures are completed

---

## Issue 2: No Phases Showing

### Symptoms
- "No phases defined for this treatment plan" message
- Empty phases section
- Nothing to click on

### Diagnostic Steps

#### Step 1: Check Browser Console
Open browser console (F12) and look for:
```
Treatment Plan Data: {...}
Plan: {...}
Phases: []  <-- If this is empty, phases weren't created
```

#### Step 2: Check Database
```sql
-- Check if phases exist
SELECT * FROM dental_treatment_plan_phases 
WHERE plan_id = 'YOUR_PLAN_ID';

-- Check if procedures exist
SELECT * FROM dental_treatment_plan_procedures 
WHERE plan_id = 'YOUR_PLAN_ID';
```

### Causes & Solutions

#### Cause 1: Plan Created Without Phases
**Symptom:** Database query returns 0 rows

**Why:** The treatment plan was created but phases weren't saved

**Solution:** Recreate the treatment plan with phases, OR manually add phases:

```sql
-- Add a phase
INSERT INTO dental_treatment_plan_phases
(plan_id, phase_number, phase_name, description, phase_cost, 
 payment_required, order_index, status)
VALUES 
('YOUR_PLAN_ID', 1, 'Phase 1: Initial Treatment', 'Description here', 50000, 
 'before_phase', 0, 'ready');

-- Get the phase_id from the insert
SET @phase_id = LAST_INSERT_ID();

-- Add procedures to the phase
INSERT INTO dental_treatment_plan_procedures
(phase_id, plan_id, service_name, tooth_number, unit_cost, quantity, 
 total_cost, order_index, status)
VALUES
(@phase_id, 'YOUR_PLAN_ID', 'Root Canal', '14', 50000, 1, 50000, 0, 'planned');
```

#### Cause 2: API Not Returning Phases
**Symptom:** Console shows `Phases: undefined` or `Phases: null`

**Check Backend Response:**
```bash
# Test the API directly
curl http://localhost:5000/treatment-plans/YOUR_PLAN_ID
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "plan_id": "TP-20260305-1234",
    "plan_name": "Treatment Plan Name",
    "phases": [
      {
        "id": 1,
        "phase_name": "Phase 1",
        "status": "ready",
        "procedures": [...]
      }
    ]
  }
}
```

**Solution:** If phases are missing from response, check backend controller:
- File: `backend/controller/treatment-plans.js`
- Function: `getTreatmentPlanDetails`
- Ensure it's querying and returning phases

#### Cause 3: Frontend Not Parsing Phases
**Symptom:** API returns phases but they don't show

**Check:** Look at console logs in TreatmentPlanOverview
```javascript
console.log('Phases:', res.data.data.phases);
```

**Solution:** Verify the phases array is being set:
```javascript
setPhases(res.data.data.phases || []);
```

---

## Issue 3: Can't Click on Phases

### Symptoms
- Phases are showing but not clickable
- No hover effect
- Nothing happens when clicking

### Causes & Solutions

#### Cause 1: Phase Status is 'pending'
**Check Phase Status:**
```sql
SELECT phase_name, status FROM dental_treatment_plan_phases 
WHERE plan_id = 'YOUR_PLAN_ID';
```

**Why:** Only phases with status 'ready' or 'in_progress' are clickable

**Solution:** Update phase status:
```sql
UPDATE dental_treatment_plan_phases
SET status = 'ready'
WHERE plan_id = 'YOUR_PLAN_ID' AND phase_number = 1;
```

**Automatic Status Change:** Phase status should change to 'ready' when:
- Deposit is paid (for first phase)
- Previous phase is completed (for subsequent phases)
- Phase payment is made (if payment_required = 'before_phase')

#### Cause 2: CSS Class Not Applied
**Check:** Inspect element in browser and look for class `clickable`

**Solution:** Verify the condition in TreatmentPlanOverview.jsx:
```javascript
const canExecute = phase.status === 'ready' || phase.status === 'in_progress';
className={`phase-card ${phase.status} ${canExecute ? 'clickable' : ''}`}
```

---

## Issue 4: Procedures Not Showing in Phase

### Symptoms
- Phase opens but shows "No procedures defined"
- Empty procedures list

### Diagnostic Steps

#### Check Database
```sql
SELECT * FROM dental_treatment_plan_procedures 
WHERE phase_id = YOUR_PHASE_ID;
```

### Solutions

#### If No Procedures Exist
Add procedures manually:
```sql
INSERT INTO dental_treatment_plan_procedures
(phase_id, plan_id, service_name, tooth_number, description, 
 unit_cost, quantity, total_cost, order_index, status)
VALUES
(YOUR_PHASE_ID, 'YOUR_PLAN_ID', 'Root Canal', '14', 
 'Complete root canal therapy', 50000, 1, 50000, 0, 'planned');
```

#### If Procedures Exist But Don't Show
Check the API endpoint:
```bash
curl http://localhost:5000/treatment-plans/YOUR_PLAN_ID/phases/YOUR_PHASE_ID/procedures
```

---

## Issue 5: Progress Not Updating

### Symptoms
- Complete a procedure but progress stays at 0%
- Phase progress doesn't change
- Plan progress doesn't update

### Diagnostic Steps

#### Check Backend Logs
Look for errors in:
- `updatePhaseProgress` function
- `updatePlanProgress` function

#### Check Database Values
```sql
-- Check procedure status
SELECT id, service_name, status, completed_date 
FROM dental_treatment_plan_procedures 
WHERE plan_id = 'YOUR_PLAN_ID';

-- Check phase progress
SELECT phase_name, procedures_total, procedures_completed, 
       clinical_progress_percentage 
FROM dental_treatment_plan_phases 
WHERE plan_id = 'YOUR_PLAN_ID';

-- Check plan progress
SELECT procedures_total, procedures_completed, 
       clinical_progress_percentage 
FROM dental_treatment_plans 
WHERE plan_id = 'YOUR_PLAN_ID';
```

### Solutions

#### Manually Trigger Progress Update
```sql
-- Update phase progress
UPDATE dental_treatment_plan_phases p
SET procedures_total = (
    SELECT COUNT(*) FROM dental_treatment_plan_procedures 
    WHERE phase_id = p.id
),
procedures_completed = (
    SELECT COUNT(*) FROM dental_treatment_plan_procedures 
    WHERE phase_id = p.id AND status = 'completed'
),
clinical_progress_percentage = (
    SELECT (COUNT(CASE WHEN status = 'completed' THEN 1 END) * 100.0 / COUNT(*))
    FROM dental_treatment_plan_procedures 
    WHERE phase_id = p.id
)
WHERE plan_id = 'YOUR_PLAN_ID';

-- Update plan progress
UPDATE dental_treatment_plans t
SET procedures_total = (
    SELECT COUNT(*) FROM dental_treatment_plan_procedures 
    WHERE plan_id = t.plan_id
),
procedures_completed = (
    SELECT COUNT(*) FROM dental_treatment_plan_procedures 
    WHERE plan_id = t.plan_id AND status = 'completed'
),
clinical_progress_percentage = (
    SELECT (COUNT(CASE WHEN status = 'completed' THEN 1 END) * 100.0 / COUNT(*))
    FROM dental_treatment_plan_procedures 
    WHERE plan_id = t.plan_id
)
WHERE plan_id = 'YOUR_PLAN_ID';
```

---

## Quick Diagnostic Checklist

### For Empty Phases Issue:
- [ ] Check browser console for "Phases:" log
- [ ] Query database for phases: `SELECT * FROM dental_treatment_plan_phases WHERE plan_id = ?`
- [ ] Test API endpoint: `curl http://localhost:5000/treatment-plans/PLAN_ID`
- [ ] Verify phases array in API response
- [ ] Check if phases were created during plan creation

### For Timeline Issue:
- [ ] Query database: `SELECT start_date, estimated_completion_date FROM dental_treatment_plans WHERE plan_id = ?`
- [ ] Check if dates are NULL (this is normal for new plans)
- [ ] Verify message "Timeline dates will be set when treatment begins" shows

### For Clickability Issue:
- [ ] Check phase status: `SELECT phase_name, status FROM dental_treatment_plan_phases WHERE plan_id = ?`
- [ ] Verify status is 'ready' or 'in_progress'
- [ ] Check if deposit was paid
- [ ] Inspect element for 'clickable' CSS class

---

## Common SQL Queries for Debugging

```sql
-- Get complete plan overview
SELECT 
    p.plan_id,
    p.plan_name,
    p.status as plan_status,
    p.total_cost,
    p.total_paid,
    p.deposit_paid,
    COUNT(DISTINCT ph.id) as phase_count,
    COUNT(pr.id) as procedure_count,
    SUM(CASE WHEN pr.status = 'completed' THEN 1 ELSE 0 END) as completed_procedures
FROM dental_treatment_plans p
LEFT JOIN dental_treatment_plan_phases ph ON p.plan_id = ph.plan_id
LEFT JOIN dental_treatment_plan_procedures pr ON ph.id = pr.phase_id
WHERE p.plan_id = 'YOUR_PLAN_ID'
GROUP BY p.plan_id;

-- Get phase details
SELECT 
    ph.phase_number,
    ph.phase_name,
    ph.status,
    ph.phase_cost,
    COUNT(pr.id) as procedure_count,
    SUM(CASE WHEN pr.status = 'completed' THEN 1 ELSE 0 END) as completed_count
FROM dental_treatment_plan_phases ph
LEFT JOIN dental_treatment_plan_procedures pr ON ph.id = pr.phase_id
WHERE ph.plan_id = 'YOUR_PLAN_ID'
GROUP BY ph.id
ORDER BY ph.phase_number;

-- Get procedure details
SELECT 
    ph.phase_name,
    pr.service_name,
    pr.status,
    pr.completed_date,
    pr.performed_by
FROM dental_treatment_plan_procedures pr
JOIN dental_treatment_plan_phases ph ON pr.phase_id = ph.id
WHERE pr.plan_id = 'YOUR_PLAN_ID'
ORDER BY ph.phase_number, pr.order_index;
```

---

## Need More Help?

1. Check browser console (F12) for errors
2. Check backend logs for errors
3. Run the SQL queries above to verify data
4. Check that migration was run: `node backend/sql/run_clinical_execution_migration.js`
5. Verify backend is running and accessible
6. Test API endpoints directly with curl or Postman

---

## Most Common Issue: No Phases Created

**If you see "No phases defined for this treatment plan":**

This means the treatment plan was created without phases. To fix:

1. **Option A:** Create a new treatment plan (recommended)
   - Use TreatmentPlanBuilder
   - Add at least one phase
   - Add procedures to the phase
   - Save

2. **Option B:** Manually add phases to existing plan
   - Use the SQL INSERT statements above
   - Add phase first, then procedures
   - Update phase status to 'ready'

The system requires at least one phase with at least one procedure for clinical execution to work.
