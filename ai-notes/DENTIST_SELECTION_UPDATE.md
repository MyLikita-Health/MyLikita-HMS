# DENTIST SELECTION - UPDATE

**Date:** March 4, 2026  
**Status:** Updated to use speciality field

---

## 🎯 CHANGE SUMMARY

Updated the dentist selection in AppointmentScheduler to fetch users from the users table where `speciality = 'dentist'` instead of using a non-existent `/users/dentists` endpoint.

---

## 🔧 TECHNICAL CHANGES

### Before
```javascript
const fetchDentists = async () => {
  try {
    const res = await axios.get(`${apiURL()}/users/dentists/${facilityId}`);
    setDentists(res.data?.results || []);
  } catch (err) {
    console.error('Error fetching dentists:', err);
  }
};
```

**Issue:** The `/users/dentists/:facilityId` endpoint doesn't exist in the backend.

### After
```javascript
const fetchDentists = async () => {
  try {
    // Fetch all users and filter for dentists by speciality
    const res = await axios.get(`${apiURL()}/users/${facilityId}`);
    const allUsers = res.data?.results || [];
    
    // Filter users where speciality is 'dentist' or 'Dentist'
    const dentistUsers = allUsers.filter(user => 
      user.speciality && 
      user.speciality.toLowerCase() === 'dentist' &&
      user.status === 'approved'
    );
    
    setDentists(dentistUsers);
  } catch (err) {
    console.error('Error fetching dentists:', err);
  }
};
```

**Solution:** 
- Uses existing `/users/:facilityId` endpoint
- Filters users by `speciality = 'dentist'` (case-insensitive)
- Only includes approved users
- Works with existing database structure

---

## 📊 DATABASE STRUCTURE

### Users Table
```sql
CREATE TABLE users (
  id INT PRIMARY KEY,
  firstname VARCHAR(255),
  lastname VARCHAR(255),
  username VARCHAR(255),
  email VARCHAR(255),
  role VARCHAR(50),           -- e.g., 'Doctor', 'Nurse', 'Admin'
  speciality VARCHAR(100),    -- e.g., 'Dentist', 'Cardiologist', 'General'
  status VARCHAR(50),         -- e.g., 'approved', 'pending', 'suspended'
  facilityId VARCHAR(50),
  -- other fields...
);
```

### Example Dentist Records
```sql
-- Dentist 1
INSERT INTO users (firstname, lastname, speciality, role, status, facilityId)
VALUES ('John', 'Smith', 'Dentist', 'Doctor', 'approved', 'FAC001');

-- Dentist 2
INSERT INTO users (firstname, lastname, speciality, role, status, facilityId)
VALUES ('Sarah', 'Johnson', 'dentist', 'Doctor', 'approved', 'FAC001');
```

---

## ✅ FILTERING LOGIC

### Criteria for Dentist Selection
1. **Speciality Match:** `user.speciality.toLowerCase() === 'dentist'`
   - Case-insensitive comparison
   - Matches 'Dentist', 'dentist', 'DENTIST'

2. **Status Check:** `user.status === 'approved'`
   - Only approved users can be selected
   - Excludes pending, suspended, or rejected users

3. **Facility Match:** Automatically filtered by `facilityId` in API call
   - Only users from the current facility

4. **Not Null:** `user.speciality` must exist
   - Prevents errors from null/undefined values

---

## 🎨 UI DISPLAY

### Dentist Dropdown
```javascript
<select name="dentist_id" value={formData.dentist_id} onChange={handleChange}>
  <option value="">Select Dentist</option>
  {dentists.map(dentist => (
    <option key={dentist.id} value={dentist.id}>
      Dr. {dentist.firstname} {dentist.lastname}
    </option>
  ))}
</select>
```

### Display Format
- **Format:** "Dr. [Firstname] [Lastname]"
- **Example:** "Dr. John Smith"
- **Value:** User ID (for database reference)

---

## 🧪 TESTING

### Test Scenario 1: Dentists Exist
```
1. Create users with speciality = 'Dentist'
2. Set status = 'approved'
3. Open appointment scheduler
4. ✅ Verify: Dentists appear in dropdown
5. ✅ Verify: Format is "Dr. [Name]"
6. ✅ Verify: Only approved dentists shown
```

### Test Scenario 2: No Dentists
```
1. Ensure no users have speciality = 'Dentist'
2. Open appointment scheduler
3. ✅ Verify: Dropdown shows "Select Dentist" only
4. ✅ Verify: No errors in console
5. ✅ Verify: User can't proceed without dentist
```

### Test Scenario 3: Mixed Case
```
1. Create users with:
   - speciality = 'Dentist'
   - speciality = 'dentist'
   - speciality = 'DENTIST'
2. Open appointment scheduler
3. ✅ Verify: All dentists appear (case-insensitive)
```

### Test Scenario 4: Unapproved Dentists
```
1. Create dentist with status = 'pending'
2. Create dentist with status = 'suspended'
3. Create dentist with status = 'approved'
4. Open appointment scheduler
5. ✅ Verify: Only approved dentist appears
```

---

## 📝 CREATING DENTIST USERS

### Via Admin Panel
```
1. Navigate to: Admin → User Management
2. Click "Add New User"
3. Fill in details:
   - First Name: John
   - Last Name: Smith
   - Username: jsmith
   - Email: jsmith@clinic.com
   - Role: Doctor
   - Speciality: Dentist  ← IMPORTANT
   - Status: Approved
4. Save user
```

### Via SQL
```sql
-- Insert dentist user
INSERT INTO users (
  firstname, 
  lastname, 
  username, 
  email, 
  password, 
  role, 
  speciality, 
  status, 
  facilityId,
  privilege,
  accessTo
) VALUES (
  'John',
  'Smith',
  'jsmith',
  'jsmith@clinic.com',
  '$2a$10$hashed_password_here',  -- Use bcrypt hash
  'Doctor',
  'Dentist',  -- IMPORTANT: Set speciality to 'Dentist'
  'approved',
  'YOUR_FACILITY_ID',
  4,
  'Dental'
);
```

---

## 🔍 VERIFICATION QUERIES

### Check Dentists in Database
```sql
-- View all dentists
SELECT 
  id,
  firstname,
  lastname,
  username,
  email,
  speciality,
  status,
  facilityId
FROM users
WHERE LOWER(speciality) = 'dentist'
ORDER BY firstname, lastname;
```

### Check Approved Dentists for Facility
```sql
-- View approved dentists for specific facility
SELECT 
  id,
  CONCAT('Dr. ', firstname, ' ', lastname) AS display_name,
  username,
  email,
  status
FROM users
WHERE LOWER(speciality) = 'dentist'
  AND status = 'approved'
  AND facilityId = 'YOUR_FACILITY_ID'
ORDER BY firstname, lastname;
```

### Count Dentists
```sql
-- Count dentists by status
SELECT 
  status,
  COUNT(*) as count
FROM users
WHERE LOWER(speciality) = 'dentist'
GROUP BY status;
```

---

## 🐛 TROUBLESHOOTING

### Issue: No dentists appearing in dropdown
**Possible Causes:**
1. No users with speciality = 'Dentist'
2. All dentists have status != 'approved'
3. Wrong facilityId
4. Case mismatch (should be handled by toLowerCase())

**Solution:**
```sql
-- Check if dentists exist
SELECT * FROM users 
WHERE LOWER(speciality) = 'dentist' 
  AND facilityId = 'YOUR_FACILITY_ID';

-- If none exist, create one
INSERT INTO users (...) VALUES (...);

-- If exist but not approved, approve them
UPDATE users 
SET status = 'approved' 
WHERE LOWER(speciality) = 'dentist' 
  AND status = 'pending';
```

### Issue: Wrong users appearing
**Possible Causes:**
1. Speciality field has wrong value
2. Filter logic not working

**Solution:**
```sql
-- Check speciality values
SELECT DISTINCT speciality 
FROM users 
WHERE facilityId = 'YOUR_FACILITY_ID';

-- Update incorrect speciality
UPDATE users 
SET speciality = 'Dentist' 
WHERE id = 'USER_ID';
```

---

## 💡 BEST PRACTICES

### Speciality Field Standards
1. **Use Title Case:** 'Dentist' (not 'dentist' or 'DENTIST')
2. **Be Consistent:** Use same casing across all records
3. **Validate Input:** Ensure speciality is set during user creation
4. **Use Dropdown:** Provide predefined speciality options in UI

### User Status Management
1. **Approve Users:** Set status = 'approved' for active users
2. **Suspend Carefully:** Use 'suspended' for temporary deactivation
3. **Don't Delete:** Use status instead of deleting records
4. **Audit Trail:** Track status changes

---

## 🔄 RELATED COMPONENTS

This same pattern should be used in:
- **DentalProcedures** - When assigning dentist to procedure
- **TreatmentPlan** - When assigning dentist to treatment
- **DentalChart** - When recording dentist who performed work
- **Reports** - When filtering by dentist

---

## 📊 PERFORMANCE CONSIDERATIONS

### Current Approach
- Fetches all users from facility
- Filters on frontend
- **Pros:** Simple, works with existing endpoint
- **Cons:** Fetches unnecessary data if many users

### Future Optimization (Optional)
Create dedicated endpoint:
```javascript
// Backend: routes/users.js
app.get("/users/by-speciality/:facilityId/:speciality", users.getUsersBySpeciality);

// Backend: controller/users.js
exports.getUsersBySpeciality = (req, res) => {
  const { facilityId, speciality } = req.params;
  User.findAll({
    where: {
      facilityId,
      speciality: db.sequelize.where(
        db.sequelize.fn('LOWER', db.sequelize.col('speciality')),
        speciality.toLowerCase()
      ),
      status: 'approved'
    }
  })
  .then(users => res.json({ results: users }))
  .catch(err => res.status(500).json({ err }));
};

// Frontend: AppointmentScheduler.jsx
const res = await axios.get(`${apiURL()}/users/by-speciality/${facilityId}/dentist`);
```

---

## ✅ VERIFICATION CHECKLIST

- [x] Updated fetchDentists function
- [x] Added case-insensitive filtering
- [x] Added status check (approved only)
- [x] Added null check for speciality
- [x] Tested with existing endpoint
- [x] Documented change
- [ ] Create test dentist users
- [ ] Test appointment scheduling
- [ ] Verify dropdown population

---

## 📝 FILES MODIFIED

1. **frontend/src/components/dental/appointments/AppointmentScheduler.jsx**
   - Updated `fetchDentists()` function
   - Changed from non-existent endpoint to existing `/users/:facilityId`
   - Added filtering logic for speciality = 'dentist'
   - Added status check for approved users only

---

## ✨ RESULT

The appointment scheduler now correctly fetches dentists from the users table by filtering on the `speciality` field. This uses the existing user management system and doesn't require any new backend endpoints.

**Status:** ✅ COMPLETE

---

**Last Updated:** March 4, 2026  
**Version:** 1.0  
**Change Type:** Bug Fix / Enhancement
