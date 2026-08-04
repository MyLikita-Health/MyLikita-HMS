# Services List Population Fix - Complete

## Issue
The services list in the ServicesImproved component was not populating because:
1. Component was trying to use Redux state (`revAccHeads`) which wasn't being populated
2. The `fetchServices()` function existed but was never called
3. Services should come from `service_definitions` table, not old revenue account heads
4. FacilityId in database is empty string `''` - services populated with empty facilityId

## Solution

### 1. Updated ServicesImproved Component
**File**: `frontend/src/components/account/ServicesImproved.jsx`

Changes made:
- Removed dependency on Redux `revAccHeads` and `getRevAccHeads` action
- Updated `fetchServices()` to call the correct endpoint: `GET /services/available/:facilityId`
- Added handling for empty facilityId (uses empty string as fallback)
- Added proper data mapping from `service_definitions` format to component format:
  - `service_name` → `description`
  - `base_price` → `price`
  - `category` → `title`
- Called `fetchServices()` in the main `useEffect` hook
- Removed unused imports (`FaPlus`, `dispatch`, `getRevAccHeads`, `_convertArrOfObjToArr`)
- Added extensive console logging for debugging

### 2. Populated Service Definitions Table
**Script**: `backend/sql/populate_services.js`

Populated 20 common healthcare services:
- Consultations (General, Specialist, Emergency)
- Laboratory tests (FBC, Malaria, Urine, Blood Sugar)
- Radiology (Chest X-Ray, Ultrasounds)
- Admissions (General Ward, Private Ward)
- Nursing services (Dressing, Injection, IV Therapy)
- Therapy (Physiotherapy)
- Surgery (Minor, Major)
- Accommodation (Bed Space)

### 3. Backend Endpoint
**Existing endpoint**: `GET /services/available/:facilityId`
- Located in `backend/routes/services.js`
- Controller: `backend/controller/services.js`
- Queries `service_definitions` table
- Supports filtering by category and search
- Returns active services only

## Data Flow

1. Component loads → `fetchServices()` called
2. API call to `/services/available/:facilityId`
3. Backend queries `service_definitions` table
4. Returns services with: `id`, `service_code`, `service_name`, `category`, `department`, `base_price`, `description`
5. Frontend maps to expected format: `description`, `price`, `title`, etc.
6. Services populate in Typeahead dropdown

## Testing

Services should now appear in the dropdown when:
1. Patient is selected
2. Service Type is chosen (Single/Group)
3. User clicks on "Select Service" field
4. Services are searchable by name

## Files Modified
- `frontend/src/components/account/ServicesImproved.jsx` - Fixed service fetching with empty facilityId handling
- `backend/sql/populate_services.js` - Created (service population script)
- `backend/sql/check_and_populate_services.sql` - Created (SQL reference)
- `backend/sql/test_services_api.js` - Created (testing script)

## Database
- Table: `service_definitions`
- Records: 20 services populated
- FacilityId: Empty string `''` (matches user facilityId format)
- All services marked as `is_active = TRUE`

## Debugging
Check browser console for these logs:
- "Fetching services for facilityId: ..."
- "Services API response: ..."
- "Mapped services count: ..."

If services still don't appear, check:
1. Browser console for API errors
2. Network tab for `/services/available/` request
3. Backend logs for query errors
4. Verify backend server is running on port 46990
