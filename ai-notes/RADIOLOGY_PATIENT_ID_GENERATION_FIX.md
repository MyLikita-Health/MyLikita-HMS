# Radiology Patient ID Generation Fix

## Issue
The radiology integrated workflow was generating patient IDs using a simple incremental pattern (`facilityId-number`), which was inconsistent with the standard patient registration process in the records module.

## Solution
Updated the patient creation logic in `backend/controller/radiology-requests.js` to use the same ID generation pattern as the records module.

## Changes Made

### Patient ID Generation Pattern

**Before**:
```javascript
// Simple incremental ID
const [maxId] = await db.sequelize.query(
  `SELECT MAX(CAST(SUBSTRING_INDEX(id, '-', -1) AS UNSIGNED)) as maxNum 
   FROM patientrecords 
   WHERE id LIKE '${facilityId}-%'`
);
const nextNum = (maxId[0]?.maxNum || 0) + 1;
finalPatientId = `${facilityId}-${nextNum}`;
```

**After**:
```javascript
// Standard accountNo-beneficiaryNo pattern
// Get next accountNo using stored procedure
const [accountResult] = await db.sequelize.query(
  'CALL get_account(:facilityId)',
  { replacements: { facilityId } }
);
accountNo = accountResult[0]['max(accountNo) + 1'];

// Get next beneficiaryNo for this account using stored procedure
const [beneficiaryResult] = await db.sequelize.query(
  'CALL get_beneficiary_no(:accountNo, :facilityId)',
  { replacements: { accountNo, facilityId } }
);
beneficiaryNo = beneficiaryResult[0].beneficiaryNo;

// Generate patient ID in format: accountNo-beneficiaryNo
finalPatientId = `${accountNo}-${beneficiaryNo}`;
```

### Additional Fields

Now includes all standard patient fields:
- `accountNo` - Account number (from stored procedure)
- `beneficiaryNo` - Beneficiary number (from stored procedure)
- `age` - Calculated from date of birth
- `dateCreated` - Current date

### Database Updates

The system now properly updates the `patientfileno` table:
```javascript
// Update patientfileno table to increment beneficiaries count
await db.sequelize.query(
  'UPDATE patientfileno SET beneficiaries = beneficiaries + 1 WHERE accountNo = ?',
  { replacements: [accountNo] }
);
```

## Benefits

1. **Consistency**: Patient IDs generated from radiology match those from regular registration
2. **Account Management**: Proper account and beneficiary tracking
3. **Compatibility**: Works seamlessly with existing patient management systems
4. **Audit Trail**: Maintains proper beneficiary counts in patientfileno table

## Patient ID Format

**Format**: `accountNo-beneficiaryNo`

**Example**: `1-1`, `1-2`, `2-1`, etc.

Where:
- `accountNo` is the account number (incremental per facility)
- `beneficiaryNo` is the beneficiary number (incremental per account)

## Stored Procedures Used

1. **get_account(:facilityId)**
   - Returns the next available account number for the facility
   - Returns: `max(accountNo) + 1`

2. **get_beneficiary_no(:accountNo, :facilityId)**
   - Returns the next beneficiary number for the given account
   - Returns: `beneficiaryNo`

## Testing

### Test Case: Create New Patient via Radiology

1. Navigate to Radiology → Patient Requests → New Request
2. Select "New Patient"
3. Fill in patient details:
   - Surname: TestPatient
   - First Name: John
   - DOB: 1990-01-01
   - Gender: Male
   - Phone: 08012345678
4. Add a procedure
5. Submit request

**Expected Result**:
- Patient created with ID format: `accountNo-beneficiaryNo` (e.g., `5-1`)
- `accountNo` and `beneficiaryNo` fields populated
- `age` calculated from DOB
- `patientfileno` table updated with incremented beneficiary count

**Verify**:
```sql
-- Check patient record
SELECT id, accountNo, beneficiaryNo, surname, firstname, age 
FROM patientrecords 
WHERE surname = 'TestPatient';

-- Check patientfileno update
SELECT accountNo, beneficiaries 
FROM patientfileno 
WHERE accountNo = [accountNo from above];
```

## Files Modified

- `backend/controller/radiology-requests.js`
  - Updated `createRequestWithBilling` function
  - Added accountNo and beneficiaryNo generation
  - Added age calculation
  - Added patientfileno update

## Compatibility

This change is fully backward compatible:
- Existing patients are not affected
- Only new patient creation uses the updated logic
- Existing patient selection continues to work as before

## Status

✅ **COMPLETE** - Patient ID generation now matches the standard registration process.
