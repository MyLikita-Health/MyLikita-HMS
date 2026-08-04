# Radiology Database Fixes - Complete

## Issues Fixed

### 1. Table Name Mismatch
**Problem**: Code was referencing `radiology_dicom_images` but the actual table name is `radiology_images`

**Error**:
```
DatabaseError [SequelizeDatabaseError]: Table 'prime.radiology_dicom_images' doesn't exist
```

**Solution**: 
- Fixed in `backend/controller/radiology-examinations.js`
- Changed `SELECT * FROM radiology_dicom_images` to `SELECT * FROM radiology_images`

### 2. Column Name Mismatch in Report Templates
**Problem**: Seed script was using old column names that don't exist in the schema

**Error**:
```
DatabaseError [SequelizeDatabaseError]: Unknown column 'findings_template' in 'field list'
```

**Columns Used (Wrong)**:
- `findings_template`
- `impression_template`
- `recommendations_template`

**Actual Schema Columns**:
- `template_content` (TEXT) - Full template with placeholders
- `sections` (JSON) - Structured sections object

**Solution**:
- Updated `backend/sql/seed_radiology_sample_data.sql`
- Changed INSERT statements to use correct columns
- Added proper JSON structure for `sections` field
- Kept `template_content` for backward compatibility

### 3. API Endpoint Mismatch
**Problem**: Frontend was calling `/radiology/reports/templates` but backend route is `/radiology/report-templates`

**Error**:
```
GET http://localhost:46990/radiology/reports/templates?facilityId=... 404 (Not Found)
```

**Solution**:
- Fixed in `frontend/src/components/radiology/reports/ReportEditor.jsx`
- Fixed in `frontend/src/components/radiology/reports/ReportTemplates.jsx`
- Changed all occurrences from `/radiology/reports/templates` to `/radiology/report-templates`
- Updated GET, POST, PUT, and DELETE calls

### 4. Missing GET Template by ID Endpoint
**Problem**: Frontend trying to fetch single template by ID but endpoint didn't exist

**Error**:
```
GET http://localhost:46990/radiology/report-templates/:id 404 (Not Found)
```

**Solution**:
- Added `getTemplateById` method in `backend/controller/radiology-reports.js`
- Added route `app.get('/radiology/report-templates/:id')` in `backend/routes/radiology-reports.js`

### 5. Frontend Using Wrong Template Field Names
**Problem**: Frontend components were trying to access `findings_template`, `impression_template`, `recommendations_template` which don't exist in the schema

**Solution**:
- Updated `ReportEditor.jsx` to parse `sections` JSON and use correct fields
- Updated `ReportTemplates.jsx` form to use `template_content`, `findings`, `impression`, `recommendations`
- Updated template display to parse and show `sections` JSON correctly
- Fixed category values to match schema ENUM (lowercase with hyphens)

## Sample Data Loaded

Successfully seeded the database with:
- **44 Procedures** (20 new + 24 existing)
- **3 Requests** (sample radiology requests)
- **3 Appointments** (today's schedule)
- **8 Equipment** (X-ray, CT, MRI, Ultrasound units)
- **2 Templates** (report templates with correct schema)

## Files Modified

1. `backend/sql/seed_radiology_sample_data.sql`
   - Fixed report template INSERT statements
   - Added `sections` JSON field
   - Added `is_default` flag

2. `backend/sql/run_radiology_seed.js` (NEW)
   - Created node script to run seed data
   - Includes verification queries
   - Shows data counts after seeding

3. `backend/controller/radiology-reports.js`
   - Added `getTemplateById` method for fetching single template

4. `backend/routes/radiology-reports.js`
   - Added GET route for `/radiology/report-templates/:id`

5. `frontend/src/components/radiology/reports/ReportEditor.jsx`
   - Fixed API endpoint from `/radiology/reports/templates` to `/radiology/report-templates`
   - Updated `handleTemplateSelect()` to parse `sections` JSON correctly
   - Now uses `template_content` and `sections.findings/impression/recommendations`

6. `frontend/src/components/radiology/reports/ReportTemplates.jsx`
   - Fixed API endpoint from `/radiology/reports/templates` to `/radiology/report-templates`
   - Updated form state to use correct field names
   - Changed form fields to match schema: `category`, `template_content`, `findings`, `impression`, `recommendations`
   - Updated `handleSubmit()` to build `sections` JSON object
   - Updated `handleEdit()` to parse `sections` JSON when loading template
   - Fixed template display to parse and show `sections` correctly
   - Updated category values to lowercase with hyphens (x-ray, ct-scan, etc.)

## Database Schema Reference

### radiology_report_templates Table Structure
```sql
CREATE TABLE radiology_report_templates (
  id VARCHAR(255) PRIMARY KEY,
  template_name VARCHAR(255) NOT NULL,
  procedure_id VARCHAR(255),
  category VARCHAR(100),
  template_content TEXT,              -- Full template text
  sections JSON,                      -- Structured sections
  is_default BOOLEAN DEFAULT FALSE,
  facilityId VARCHAR(255) NOT NULL,
  created_by VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### radiology_images Table Structure
```sql
CREATE TABLE radiology_images (
  id VARCHAR(255) PRIMARY KEY,
  examination_id VARCHAR(255) NOT NULL,
  image_number INT DEFAULT 1,
  image_type ENUM('dicom', 'jpeg', 'png', 'pdf') DEFAULT 'dicom',
  file_path VARCHAR(500),
  file_size BIGINT,
  image_view VARCHAR(100),
  body_part VARCHAR(100),
  thumbnail_path VARCHAR(500),
  upload_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  uploaded_by VARCHAR(255),
  is_key_image BOOLEAN DEFAULT FALSE,
  annotations JSON,
  facilityId VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Testing

To verify the fixes:

1. **Run the seed script**:
   ```bash
   node backend/sql/run_radiology_seed.js
   ```

2. **Check the dashboard**:
   - Navigate to Radiology Dashboard
   - Verify statistics are loading
   - Check that no database errors appear in console

3. **Test API endpoints**:
   ```bash
   # Get procedures
   curl http://localhost:46990/radiology/procedures?facilityId=1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a
   
   # Get templates
   curl http://localhost:46990/radiology/report-templates?facilityId=1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a
   
   # Get examination images (will return empty array until images are uploaded)
   curl http://localhost:46990/radiology/examinations/{exam-id}/images
   ```

## Next Steps

1. ✅ Database schema matches code
2. ✅ Sample data loaded successfully
3. ✅ No more table/column mismatch errors
4. 🔄 Test dashboard with real data
5. 🔄 Verify all API endpoints return data correctly
6. 🔄 Test image upload functionality when ready

## Status

✅ **COMPLETE** - All database errors fixed and sample data loaded successfully.
