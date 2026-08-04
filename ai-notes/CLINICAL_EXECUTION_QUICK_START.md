# Clinical Execution Quick Start Guide

## Setup (One-Time)

### 1. Run Database Migration
```bash
cd backend/sql
node run_clinical_execution_migration.js
```

### 2. Restart Backend
```bash
cd backend
npm start
```

## Using the System

### Step 1: Create Treatment Plan
1. Go to Dental Module → Treatment Plans
2. Click "Create Treatment Plan"
3. Add phases and procedures
4. Save the plan

### Step 2: Patient Acceptance
1. Plan opens in acceptance view
2. Patient reviews and signs
3. System generates deposit bill
4. Cashier processes payment

### Step 3: View Overview
1. After deposit payment, click on the plan
2. See two progress cards:
   - **Financial Progress** (green) - Payment status
   - **Clinical Progress** (purple) - Procedures completed
3. View all phases below

### Step 4: Execute Phase
1. Click on a phase with "Ready" or "In Progress" status
2. Click "Start Phase" if not started
3. See all procedures in the phase

### Step 5: Complete Procedures
1. Expand a procedure card
2. Click "Start Procedure"
3. Click "Complete Procedure"
4. Fill in clinical documentation:
   - **Clinical Notes** (required) - What was done
   - **Duration** (optional) - Time taken
   - **Materials** (optional) - Supplies used
   - **Complications** (optional) - Any issues
5. Click "Save & Complete"

### Step 6: Track Progress
1. Return to overview
2. See updated progress bars
3. Phase shows completion percentage
4. Overall plan shows clinical progress

## Quick Tips

### For Dentists
- ✅ Always add clinical notes before completing
- ✅ Document complications immediately
- ✅ Track materials for accurate costing
- ✅ Use multi-select to schedule related procedures

### For Administrators
- ✅ Monitor both financial and clinical progress
- ✅ Ensure payments before starting phases
- ✅ Review clinical notes for quality
- ✅ Use overview for progress tracking

## Status Flow

```
Treatment Plan:
draft → pending_acceptance → accepted → in_progress → completed

Phase:
pending → ready → in_progress → completed

Procedure:
planned → in_progress → completed
```

## Common Scenarios

### Scenario 1: Simple Treatment
1. Create plan with 1 phase, 3 procedures
2. Patient accepts, pays deposit
3. Start phase
4. Complete all 3 procedures
5. Phase auto-completes
6. Plan auto-completes

### Scenario 2: Multi-Phase Treatment
1. Create plan with 3 phases
2. Patient accepts, pays deposit
3. Complete Phase 1 procedures
4. Patient pays for Phase 2
5. Complete Phase 2 procedures
6. Continue until all phases done

### Scenario 3: Installment Payment
1. Create plan with installment payment
2. Patient accepts, pays deposit
3. Start clinical work
4. Patient pays installments monthly
5. Continue clinical work as paid
6. Complete when all paid and done

## Troubleshooting

**Q: Can't start phase?**
- Check if deposit is paid
- Verify phase status is 'ready'

**Q: Can't complete procedure?**
- Clinical notes are required
- Must be in 'in_progress' status

**Q: Progress not updating?**
- Refresh the page
- Check if procedures are completed

**Q: Phase not showing?**
- Verify plan status is 'accepted' or 'in_progress'
- Check if previous phases are completed

## Key Features

✅ **Dual Progress Tracking** - Financial + Clinical
✅ **Phase-by-Phase Execution** - Organized workflow
✅ **Clinical Documentation** - Required notes
✅ **Visual Progress** - Clear indicators
✅ **Multi-Select Scheduling** - Batch appointments
✅ **Material Tracking** - Cost accuracy
✅ **Complication Recording** - Quality control

## Next Steps

After mastering the basics:
1. Explore appointment integration (coming soon)
2. Use clinical session logging
3. Generate progress reports
4. Track materials inventory
5. Analyze completion metrics

## Support

Need help?
- Read TREATMENT_PLAN_CLINICAL_EXECUTION.md for details
- Check browser console for errors
- Verify database migration completed
- Test with sample data first

---

**Remember:** The system tracks BOTH financial and clinical progress. A treatment plan is only truly complete when both are at 100%!
