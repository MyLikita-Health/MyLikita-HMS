# Dental Lab Job Cards - Simplified Version

## Overview
Completely redesigned the job cards to focus on mandatory fields with optional advanced fields hidden by default.

## Key Changes

### Mandatory Fields (Always Visible)
1. **Client Type** - Radio button selection:
   - Patient (with typeahead search)
   - Hospital (with name input)

2. **Type of Job** - Dropdown with predefined job types and prices
   - Prices are automatically linked to job types
   - No manual entry required

3. **Shade** - Dropdown with standard shade options (A1-D4)

4. **Client Phone** - Phone number input (mandatory)

5. **Amount** - Auto-calculated based on job type (read-only, displayed in green)

6. **Receiving Date** - Date picker (defaults to today)

7. **Turnaround Date** - Date picker (mandatory)

### Advanced Fields (Collapsible)
Hidden by default, can be expanded by clicking "Advanced Options" button:
- Doctor Name
- Practice/Clinic Name
- Appliance Type (Orthodontic only)
- Arch (Orthodontic only)
- Tooth Mould No (Prosthetic only)
- Shade Guide Used (Prosthetic only)
- Special Instructions

## Job Types & Pricing

### Orthodontic Job Types
| Job Type | Price |
|----------|-------|
| Hawley Retainer | ₦15,000 |
| Wraparound Retainer | ₦12,000 |
| Expansion Plate | ₦20,000 |
| Bite Plane | ₦18,000 |
| Space Maintainer | ₦15,000 |
| Habit Breaker | ₦16,000 |
| Custom Appliance | ₦25,000 |

### Prosthetic Job Types
| Job Type | Price |
|----------|-------|
| Complete Denture - Upper | ₦50,000 |
| Complete Denture - Lower | ₦50,000 |
| Complete Denture - Both | ₦90,000 |
| Acrylic Partial - Upper | ₦35,000 |
| Acrylic Partial - Lower | ₦35,000 |
| Cast Partial - Upper | ₦60,000 |
| Cast Partial - Lower | ₦60,000 |
| PFM Crown | ₦40,000 |
| Full Ceramic Crown | ₦60,000 |
| Zirconia Crown | ₦80,000 |
| PFM Bridge - 3 Unit | ₦120,000 |
| Ceramic Bridge - 3 Unit | ₦180,000 |
| Porcelain Veneer | ₦50,000 |
| Denture Reline | ₦15,000 |
| Denture Repair | ₦10,000 |

## Features

### Client Type Selection
- **Patient Mode**: 
  - Shows typeahead search
  - Auto-fills phone number from patient record
  - Displays selected patient info
  
- **Hospital Mode**:
  - Shows simple text input for hospital name
  - Requires manual phone number entry

### Auto-Pricing
- Amount is automatically calculated when job type is selected
- Displayed in green with currency formatting
- Read-only field (no manual editing)

### Collapsible Advanced Section
- Clean toggle button with chevron icon
- Smooth expand/collapse animation
- Dashed border indicates optional section
- Hover effect for better UX

### Validation
- Validates client selection (patient or hospital)
- Ensures all mandatory fields are filled
- Shows clear error messages

## UI/UX Improvements

### Visual Hierarchy
1. **Mandatory section** - White background with purple border
2. **Advanced section** - Dashed border, collapsible
3. **Submit button** - Large, prominent at bottom

### Color Coding
- **Amount field**: Green background (#e8f5e9) with green text (#2ecc71)
- **Client type selector**: Purple accent (#007bff) when selected
- **Advanced toggle**: Purple text with hover effect

### Icons
- FaUser - Patient selection
- FaHospital - Hospital selection
- FaSearch - Patient search
- FaChevronDown/Up - Advanced toggle
- FaSave - Submit button

## Files Modified
1. `frontend/src/components/dental/lab/OrthodonticJobCard.jsx` - Complete rewrite
2. `frontend/src/components/dental/lab/ProstheticJobCard.jsx` - Complete rewrite
3. `frontend/src/components/dental/lab/lab.css` - Added new styles

## Benefits
✅ Cleaner, simpler interface
✅ Faster job creation (fewer fields to fill)
✅ Automatic pricing (no errors)
✅ Flexible for both patients and hospitals
✅ Advanced options available when needed
✅ Better mobile responsiveness
✅ Consistent with existing design system

## Testing Checklist
- [ ] Create job for existing patient
- [ ] Create job for hospital
- [ ] Verify auto-pricing works correctly
- [ ] Test advanced section expand/collapse
- [ ] Verify patient search functionality
- [ ] Test form validation
- [ ] Check mobile responsiveness
- [ ] Verify job creation and billing

## Status
✅ **COMPLETE** - Simplified job cards ready for use
