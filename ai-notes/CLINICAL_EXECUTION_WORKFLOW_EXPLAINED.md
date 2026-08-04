# Clinical Execution Workflow - Complete Explanation

## The Complete Flow (With Example)

### Scenario: Patient needs root canal + crown

---

## PHASE 1: Planning & Payment (Already Working)

### Step 1: Create Treatment Plan
**Dentist creates a plan:**
- **Plan Name:** "Root Canal & Crown Treatment"
- **Phase 1:** Root Canal Treatment
  - Procedure 1: Root canal on tooth #14 (₦50,000)
  - Procedure 2: Temporary filling (₦10,000)
- **Phase 2:** Crown Placement
  - Procedure 3: Crown preparation (₦30,000)
  - Procedure 4: Permanent crown (₦80,000)
- **Total Cost:** ₦170,000
- **Deposit Required:** ₦51,000 (30%)

### Step 2: Patient Acceptance
- Patient reviews the plan
- Patient signs digitally
- System generates deposit bill (₦51,000)
- Plan status: `draft` → `pending_acceptance`

### Step 3: Deposit Payment
- Patient goes to cashier
- Cashier processes ₦51,000 payment
- System detects `[PLAN-ID:TP-20260305-1234]` in bill
- Automatically updates:
  - `deposit_paid` = TRUE
  - `status` = 'accepted'
  - Phase 1 status = 'ready'

---

## PHASE 2: Clinical Execution (NEW SYSTEM)

### Step 4: View Treatment Overview
**Dentist clicks on the treatment plan and sees:**

```
┌─────────────────────────────────────────────────┐
│  Root Canal & Crown Treatment                   │
│  ID: TP-20260305-1234                          │
│  Status: ACCEPTED                               │
└─────────────────────────────────────────────────┘

┌──────────────────────┐  ┌──────────────────────┐
│ 💰 Financial Progress│  │ 🦷 Clinical Progress │
│                      │  │                      │
│ ₦51,000 / ₦170,000  │  │   0 / 4 procedures   │
│ [████░░░░░░] 30%    │  │ [░░░░░░░░░░] 0%     │
│                      │  │                      │
│ Total: ₦170,000     │  │ Total: 4 procedures  │
│ Paid:  ₦51,000      │  │ Done:  0 procedures  │
│ Due:   ₦119,000     │  │ Left:  4 procedures  │
└──────────────────────┘  └──────────────────────┘

📅 Timeline
Started: March 5, 2026
Est. Completion: March 20, 2026

📊 Treatment Phases

┌─────────────────────────────────────────────────┐
│ 1  Phase 1: Root Canal Treatment                │
│    Status: READY  |  ₦60,000  |  0/2 procedures│
│    [Click to execute] →                         │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ 2  Phase 2: Crown Placement                     │
│    Status: PENDING  |  ₦110,000  |  0/2 proc.  │
│    (Waiting for Phase 1 completion)             │
└─────────────────────────────────────────────────┘
```

### Step 5: Execute Phase 1
**Dentist clicks on "Phase 1: Root Canal Treatment"**

The screen changes to show:

```
┌─────────────────────────────────────────────────┐
│ ← Back to Overview                              │
│                                                 │
│ Phase 1: Root Canal Treatment                  │
│ Root canal therapy and temporary restoration   │
│                                                 │
│ [▶ Start Phase]                                │
└─────────────────────────────────────────────────┘

Clinical Progress: [░░░░░░░░░░] 0%
0 of 2 procedures completed

🦷 Procedures in this Phase

┌─────────────────────────────────────────────────┐
│ ☐  Root canal on tooth #14                     │
│    Status: PLANNED  |  Tooth #14  |  ₦50,000   │
│    [Click to expand] ▼                          │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ ☐  Temporary filling                            │
│    Status: PLANNED  |  Tooth #14  |  ₦10,000   │
│    [Click to expand] ▼                          │
└─────────────────────────────────────────────────┘
```

**Dentist clicks "Start Phase":**
- Phase status changes: `ready` → `in_progress`
- Plan status changes: `accepted` → `in_progress`

### Step 6: Start First Procedure
**Dentist expands "Root canal on tooth #14" card:**

```
┌─────────────────────────────────────────────────┐
│ ☑  Root canal on tooth #14                     │
│    Status: PLANNED  |  Tooth #14  |  ₦50,000   │
│    [Expanded] ▲                                 │
│                                                 │
│ Description:                                    │
│ Complete root canal therapy including cleaning, │
│ shaping, and filling of root canals            │
│                                                 │
│ Cost: ₦50,000                                   │
│                                                 │
│ [▶ Start Procedure]                            │
└─────────────────────────────────────────────────┘
```

**Dentist clicks "Start Procedure":**
- Procedure status: `planned` → `in_progress`
- Card turns yellow (in progress color)
- Button changes to "Complete Procedure"

### Step 7: Complete First Procedure
**After performing the root canal, dentist clicks "Complete Procedure":**

A form appears:

```
┌─────────────────────────────────────────────────┐
│ Clinical Documentation                          │
│                                                 │
│ Clinical Notes: *                               │
│ ┌─────────────────────────────────────────────┐│
│ │ Root canal completed successfully. Three    ││
│ │ canals identified and cleaned. Canals       ││
│ │ shaped to size 40/.06 taper. Obturation     ││
│ │ completed with gutta-percha and sealer.     ││
│ │ Patient tolerated procedure well.           ││
│ └─────────────────────────────────────────────┘│
│                                                 │
│ Duration (minutes):                             │
│ [90]                                            │
│                                                 │
│ Materials Used:                                 │
│ ┌─────────────────────────────────────────────┐│
│ │ - Gutta-percha points (size 40)            ││
│ │ - AH Plus sealer                            ││
│ │ - Local anesthesia (2 carpules)            ││
│ └─────────────────────────────────────────────┘│
│                                                 │
│ Complications (if any):                         │
│ ┌─────────────────────────────────────────────┐│
│ │ None                                        ││
│ └─────────────────────────────────────────────┘│
│                                                 │
│ [💾 Save & Complete]  [✖ Cancel]               │
└─────────────────────────────────────────────────┘
```

**Dentist clicks "Save & Complete":**

**What happens automatically:**
1. Procedure status: `in_progress` → `completed`
2. Procedure data saved:
   - `completed_date` = today
   - `clinical_notes` = the notes entered
   - `duration_minutes` = 90
   - `materials_used` = the materials list
   - `performed_by` = current dentist ID
3. Phase progress recalculated:
   - `procedures_completed` = 1
   - `procedures_total` = 2
   - `clinical_progress_percentage` = 50%
4. Plan progress recalculated:
   - `procedures_completed` = 1
   - `procedures_total` = 4
   - `clinical_progress_percentage` = 25%

**Screen updates to show:**

```
Clinical Progress: [█████░░░░░] 50%
1 of 2 procedures completed

┌─────────────────────────────────────────────────┐
│ ✓  Root canal on tooth #14                     │
│    Status: COMPLETED  |  Tooth #14  |  ₦50,000 │
│    Completed: March 5, 2026                     │
│    Performed by: Dr. Smith                      │
│    [Click to view details] ▼                    │
└─────────────────────────────────────────────────┘
```

### Step 8: Complete Second Procedure
**Same process for "Temporary filling":**
1. Expand card
2. Click "Start Procedure"
3. Perform the procedure
4. Click "Complete Procedure"
5. Fill in clinical notes
6. Save & Complete

**After completing both procedures:**
- Phase 1 progress: 100%
- Phase 1 status: `in_progress` → `completed`
- Plan progress: 50% (2 of 4 procedures done)

### Step 9: Back to Overview
**Dentist clicks "Back to Overview":**

```
┌──────────────────────┐  ┌──────────────────────┐
│ 💰 Financial Progress│  │ 🦷 Clinical Progress │
│                      │  │                      │
│ ₦51,000 / ₦170,000  │  │   2 / 4 procedures   │
│ [████░░░░░░] 30%    │  │ [█████░░░░░] 50%    │
└──────────────────────┘  └──────────────────────┘

📊 Treatment Phases

┌─────────────────────────────────────────────────┐
│ 1  Phase 1: Root Canal Treatment                │
│    Status: COMPLETED ✓  |  ₦60,000  |  2/2 ✓   │
│    [████████████] 100%                          │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ 2  Phase 2: Crown Placement                     │
│    Status: READY  |  ₦110,000  |  0/2 proc.    │
│    [Click to execute] →                         │
└─────────────────────────────────────────────────┘
```

### Step 10: Patient Pays for Phase 2
- Patient pays ₦110,000 for Phase 2
- Phase 2 status: `pending` → `ready`
- Financial progress: 95% (₦161,000 / ₦170,000)

### Step 11: Execute Phase 2
**Same process:**
1. Click on Phase 2
2. Start phase
3. Complete "Crown preparation" procedure
4. Complete "Permanent crown" procedure

**After all procedures completed:**
- Plan clinical progress: 100%
- Plan status: `in_progress` → `completed`
- Plan completion date: recorded

---

## Key Points

### 1. **Two Types of Progress**
- **Financial Progress** = How much has been paid
- **Clinical Progress** = How many procedures are done
- Both must reach 100% for true completion

### 2. **Status Flow**
```
Treatment Plan:
draft → pending_acceptance → accepted → in_progress → completed

Phase:
pending → ready → in_progress → completed

Procedure:
planned → in_progress → completed
```

### 3. **Required Documentation**
- You CANNOT complete a procedure without clinical notes
- This ensures quality documentation for every procedure
- Optional: duration, materials, complications

### 4. **Auto-Updates**
- When you complete a procedure, the system automatically:
  - Updates phase progress
  - Updates plan progress
  - Changes statuses when appropriate
  - Records completion dates

### 5. **Visual Feedback**
- Color-coded status badges
- Progress bars that update in real-time
- Cards change color based on status
- Completed items show checkmarks

---

## Why This Matters

**Before:** Treatment plans were just payment trackers. You knew the patient paid, but not if the work was actually done.

**Now:** You track BOTH payment AND clinical work. You can see:
- Which procedures are done vs. planned
- Who performed each procedure
- When it was done
- What materials were used
- Any complications
- Complete clinical documentation

This makes treatment plans actual clinical tools, not just billing documents!

---

## Data Flow

### When Creating a Plan
```
TreatmentPlanBuilder
  ↓
POST /treatment-plans/create
  ↓
Database:
  - dental_treatment_plans (main plan)
  - dental_treatment_plan_phases (phases)
  - dental_treatment_plan_procedures (procedures per phase)
```

### When Viewing Overview
```
TreatmentPlanOverview
  ↓
GET /treatment-plans/:planId
  ↓
Returns:
  - Plan details
  - All phases with procedures
  - Payment info
  - Progress calculations
```

### When Executing Phase
```
PhaseExecution
  ↓
GET /treatment-plans/:planId/phases/:phaseId/procedures
  ↓
Returns all procedures for that phase
```

### When Starting Phase
```
Click "Start Phase"
  ↓
PUT /treatment-plans/:planId/phases/:phaseId/start
  ↓
Updates:
  - Phase status → in_progress
  - Plan status → in_progress (if accepted)
```

### When Completing Procedure
```
Click "Save & Complete"
  ↓
PUT /treatment-plans/:planId/procedures/:procedureId/complete
  ↓
Updates:
  1. Procedure → completed with notes
  2. Phase progress recalculated
  3. Plan progress recalculated
  4. Statuses auto-updated
```

---

## Common Questions

### Q: Can I skip procedures?
A: No, procedures should be completed in order within a phase. However, you can work on multiple phases if they're both ready.

### Q: What if I need to cancel a procedure?
A: Currently not implemented, but you can add a status change to 'cancelled' in the future.

### Q: Can multiple dentists work on the same plan?
A: Yes! Each procedure records who performed it via `performed_by` field.

### Q: What if a procedure has complications?
A: Document them in the "Complications" field when completing the procedure. This creates an audit trail.

### Q: Can I edit clinical notes after completion?
A: Currently no, but this can be added as an enhancement. For now, notes are final once saved.

### Q: How do I know which phase to work on?
A: Only phases with status 'ready' or 'in_progress' are clickable. The overview shows this clearly.

---

## Troubleshooting

### Timeline shows no dates
**Cause:** The plan doesn't have `start_date` or `estimated_completion_date` set.
**Solution:** These should be set when creating the plan or can be added later.

### No phases showing
**Cause:** The phases weren't created with the plan, or the API isn't returning them.
**Solution:** Check that phases were added in TreatmentPlanBuilder and that the GET endpoint returns `phases` array.

### Can't click on phase
**Cause:** Phase status is 'pending' (not ready yet).
**Solution:** Only 'ready' and 'in_progress' phases are clickable. Check payment status.

### Progress not updating
**Cause:** The auto-calculation functions aren't running.
**Solution:** Check backend logs for errors in `updatePhaseProgress` or `updatePlanProgress`.

---

This system transforms treatment plans from administrative documents into active clinical tools that guide dentists through complex treatments while maintaining comprehensive documentation.
