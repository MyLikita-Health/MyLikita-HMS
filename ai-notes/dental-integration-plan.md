I'll analyze this project thoroughly to understand the current architecture and create a detailed implementation plan for the dental modules. Let me start by exploring the key areas of the codebase.

Now let me explore the frontend structure to understand the navigation and UI components:

Now let me check the navigation component to understand how modules are structured:

Perfect! Now let me check the database schema to understand the table structures:

Now I have a comprehensive understanding of the project. Let me create a detailed implementation plan for the dental modules.

## DETAILED IMPLEMENTATION PLAN FOR DENTAL MODULES

Based on my analysis of your HMS (Hospital Management System) codebase and the dental job cards you provided, here's a comprehensive implementation plan:

---

### **PROJECT OVERVIEW**

You're building three specialized dental modules that will integrate into your existing HMS:

1. **Dental** - Specialized doctor's module for dental practitioners
2. **Dental Lab** - Laboratory module for dental lab work (orthodontics, prosthetics, etc.)
3. **Oral Care Shop** - Pharmacy module specialized for dental products

These modules will share the existing infrastructure but have specialized workflows based on the dental job cards.

---

### **PHASE 1: DATABASE SCHEMA DESIGN**

#### **1.1 Dental Module Tables**

```sql
-- Dental patient records extension
CREATE TABLE `dental_patient_records` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `patient_id` VARCHAR(50) NOT NULL,
  `facilityId` VARCHAR(50) NOT NULL,
  `chief_complaint` TEXT,
  `dental_history` TEXT,
  `last_dental_visit` DATE,
  `oral_hygiene_status` VARCHAR(50),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_dental_patient` (`patient_id`, `facilityId`)
);

-- Dental chart/odontogram
CREATE TABLE `dental_chart` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `patient_id` VARCHAR(50) NOT NULL,
  `facilityId` VARCHAR(50) NOT NULL,
  `tooth_number` INT(2) NOT NULL, -- 1-32 for adult teeth
  `tooth_position` VARCHAR(20), -- Upper/Lower, Left/Right
  `condition` VARCHAR(100), -- Cavity, Missing, Filled, Crown, etc.
  `notes` TEXT,
  `created_by` VARCHAR(50),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_dental_chart` (`patient_id`, `facilityId`)
);

-- Dental procedures/treatments
CREATE TABLE `dental_procedures` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `patient_id` VARCHAR(50) NOT NULL,
  `facilityId` VARCHAR(50) NOT NULL,
  `visit_id` VARCHAR(50),
  `procedure_code` VARCHAR(50),
  `procedure_name` VARCHAR(200),
  `tooth_number` VARCHAR(50), -- Can be multiple teeth
  `procedure_date` DATE,
  `status` VARCHAR(50), -- Planned, In Progress, Completed
  `cost` DECIMAL(10,2),
  `notes` TEXT,
  `created_by` VARCHAR(50),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_dental_procedures` (`patient_id`, `facilityId`)
);

-- Dental treatment plans
CREATE TABLE `dental_treatment_plans` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `patient_id` VARCHAR(50) NOT NULL,
  `facilityId` VARCHAR(50) NOT NULL,
  `plan_name` VARCHAR(200),
  `diagnosis` TEXT,
  `treatment_goals` TEXT,
  `estimated_cost` DECIMAL(10,2),
  `estimated_duration` VARCHAR(50),
  `status` VARCHAR(50), -- Draft, Approved, In Progress, Completed
  `created_by` VARCHAR(50),
  `approved_by` VARCHAR(50),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);
```

#### **1.2 Dental Lab Tables**

```sql
-- Dental lab job cards (Orthodontic)
CREATE TABLE `dental_lab_orthodontic_jobs` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `job_card_no` VARCHAR(50) UNIQUE NOT NULL,
  `facilityId` VARCHAR(50) NOT NULL,
  `patient_id` VARCHAR(50),
  `patient_name` VARCHAR(200),
  `doctor_name` VARCHAR(200),
  `practice_clinic_name` VARCHAR(200),
  `address` TEXT,
  `phone` VARCHAR(50),
  `age` INT(3),
  `gender` VARCHAR(10),
  `dob` DATE,
  `due_date` DATE,
  `delivery_date` DATE,
  
  -- Retainers section
  `retainer_type` VARCHAR(50), -- Full occlusal, Scalloped, Straight
  
  -- Appliance Options
  `appliance_upper` BOOLEAN DEFAULT FALSE,
  `appliance_lower` BOOLEAN DEFAULT FALSE,
  `appliance_both` BOOLEAN DEFAULT FALSE,
  
  -- Bleaching Trays
  `bleaching_soft` BOOLEAN DEFAULT FALSE,
  `bleaching_15mm` BOOLEAN DEFAULT FALSE,
  `bleaching_20mm` BOOLEAN DEFAULT FALSE,
  
  -- Acrylic Design Options
  `anterior_bite_plate` BOOLEAN DEFAULT FALSE,
  `posterior_bite_plate` BOOLEAN DEFAULT FALSE,
  `reverse_incline_bite_plate` BOOLEAN DEFAULT FALSE,
  `horseshoe_palate` BOOLEAN DEFAULT FALSE,
  `scalloped_anteriors` BOOLEAN DEFAULT FALSE,
  `facial_acrylic_labial_bow` BOOLEAN DEFAULT FALSE,
  
  -- Clasps
  `clasps_type` VARCHAR(50), -- C, Arrow, Adams, Occlusal Rest
  `clasps_c` BOOLEAN DEFAULT FALSE,
  `clasps_arrow` BOOLEAN DEFAULT FALSE,
  `clasps_adams` BOOLEAN DEFAULT FALSE,
  `clasps_occlusal_rest` BOOLEAN DEFAULT FALSE,
  
  -- Springs
  `hawley` BOOLEAN DEFAULT FALSE,
  `wraparound` BOOLEAN DEFAULT FALSE,
  `wraparound_without_wires` BOOLEAN DEFAULT FALSE,
  `ocm` BOOLEAN DEFAULT FALSE,
  
  -- Acrylic Color
  `acrylic_color` VARCHAR(50), -- Pink, Clear, etc.
  
  -- Labial Wire
  `labial_wire_size` VARCHAR(20), -- 3-3, 2-2, 4-4, Flat labial bow
  
  -- Auxiliaries
  `finger_springs` BOOLEAN DEFAULT FALSE,
  `spring_helixes` BOOLEAN DEFAULT FALSE,
  `z_spring` BOOLEAN DEFAULT FALSE,
  `molar_retracting_spring` BOOLEAN DEFAULT FALSE,
  `mushroom_spring` BOOLEAN DEFAULT FALSE,
  `buccal_spring` BOOLEAN DEFAULT FALSE,
  
  -- Spring Aligners & Fixed Appliances
  `spring_aligners_modified` BOOLEAN DEFAULT FALSE,
  `spring_aligners_super_modified` BOOLEAN DEFAULT FALSE,
  
  -- Fixed Appliances details
  `fixed_anterior_bite_plate` VARCHAR(50),
  `fixed_lingual_tongue_crib` VARCHAR(50),
  `fixed_nance` VARCHAR(50),
  `fixed_band_loop` VARCHAR(50),
  `fixed_sliding_loop` VARCHAR(50),
  `fixed_lingual_arch` VARCHAR(50),
  `fixed_distal_shoe` VARCHAR(50),
  `fixed_lip_bumper` VARCHAR(50),
  `fixed_bluegrass` VARCHAR(50),
  
  -- Arch Development
  `arch_dev_hyrax_rpe` VARCHAR(50),
  `arch_dev_facemask_hooks` VARCHAR(50),
  `arch_dev_hyrax_rpe_2` VARCHAR(50),
  `arch_dev_maxed_rpe` VARCHAR(50),
  `arch_dev_haas_rpe` VARCHAR(50),
  `arch_dev_niti_rpe` VARCHAR(50),
  `arch_dev_pendex` VARCHAR(50),
  `arch_dev_quad_helix` VARCHAR(50),
  `arch_dev_bi_helix` VARCHAR(50),
  `arch_dev_transpalatal_arch` VARCHAR(50),
  `arch_dev_w_expansion_appliance` VARCHAR(50),
  `arch_dev_schwartz` VARCHAR(50),
  `arch_dev_sagittal` VARCHAR(50),
  `arch_dev_crotat` VARCHAR(50),
  `arch_dev_twin_block` VARCHAR(50),
  `arch_dev_e_arch` VARCHAR(50),
  
  -- Pontic & Shade
  `pontic_shade` VARCHAR(50),
  
  -- Study Models & Nightguards
  `study_models_finished` BOOLEAN DEFAULT FALSE,
  `study_models_unfinished` BOOLEAN DEFAULT FALSE,
  `study_models_duplication` BOOLEAN DEFAULT FALSE,
  
  `nightguards_upper` BOOLEAN DEFAULT FALSE,
  `nightguards_lower` BOOLEAN DEFAULT FALSE,
  `nightguards_hard` BOOLEAN DEFAULT FALSE,
  `nightguards_soft` BOOLEAN DEFAULT FALSE,
  `nightguards_astron` BOOLEAN DEFAULT FALSE,
  
  -- Special Instructions
  `special_instructions` TEXT,
  
  -- Dentist Signature
  `dentist_signature` VARCHAR(200),
  
  `status` VARCHAR(50) DEFAULT 'pending', -- pending, in_progress, completed, delivered
  `created_by` VARCHAR(50),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  KEY `idx_ortho_jobs` (`facilityId`, `status`)
);

-- Dental lab job cards (Prosthetic)
CREATE TABLE `dental_lab_prosthetic_jobs` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `job_card_no` VARCHAR(50) UNIQUE NOT NULL,
  `facilityId` VARCHAR(50) NOT NULL,
  `patient_id` VARCHAR(50),
  `patient_name` VARCHAR(200),
  `doctor_name` VARCHAR(200),
  `practice_clinic_name` VARCHAR(200),
  `address` TEXT,
  `phone` VARCHAR(50),
  `age` INT(3),
  `gender` VARCHAR(10),
  `dob` DATE,
  `due_date` DATE,
  `delivery_date` DATE,
  
  -- Complete Dentures
  `complete_dentures_upper` BOOLEAN DEFAULT FALSE,
  `complete_dentures_lower` BOOLEAN DEFAULT FALSE,
  `complete_dentures_both` BOOLEAN DEFAULT FALSE,
  `complete_dentures_setup_tryin` BOOLEAN DEFAULT FALSE,
  `complete_dentures_brushism_splint` BOOLEAN DEFAULT FALSE,
  `complete_dentures_repair_reline` BOOLEAN DEFAULT FALSE,
  `complete_dentures_immediate_surgical` BOOLEAN DEFAULT FALSE,
  `complete_dentures_overdenture` BOOLEAN DEFAULT FALSE,
  `complete_dentures_finish` BOOLEAN DEFAULT FALSE,
  `complete_dentures_cast_metal_base` BOOLEAN DEFAULT FALSE,
  `complete_dentures_metal_mesh` BOOLEAN DEFAULT FALSE,
  
  -- Partial Dentures
  `partial_dentures_upper` BOOLEAN DEFAULT FALSE,
  `partial_dentures_lower` BOOLEAN DEFAULT FALSE,
  `partial_dentures_both` BOOLEAN DEFAULT FALSE,
  `partial_dentures_setup_tryin` BOOLEAN DEFAULT FALSE,
  `partial_dentures_finish` BOOLEAN DEFAULT FALSE,
  
  -- Custom options
  `custom_tray` BOOLEAN DEFAULT FALSE,
  `base_plate` BOOLEAN DEFAULT FALSE,
  `bite_rim` BOOLEAN DEFAULT FALSE,
  
  -- Teeth extraction options
  `teeth_extracted_from_model` BOOLEAN DEFAULT FALSE,
  `teeth_removed_from_model_final` BOOLEAN DEFAULT FALSE,
  
  -- Extractions diagram (store as JSON or separate table)
  `extractions_upper_arch` TEXT, -- JSON array of tooth numbers
  `extractions_lower_arch` TEXT, -- JSON array of tooth numbers
  
  -- Case Design
  `case_design_follow_doctors` BOOLEAN DEFAULT FALSE,
  `case_design_best_fit_function` BOOLEAN DEFAULT FALSE,
  
  -- Base Material (non-metal)
  `base_material_acrylic_partial` BOOLEAN DEFAULT FALSE,
  `base_material_valplast_partial` BOOLEAN DEFAULT FALSE,
  `base_material_metallic` BOOLEAN DEFAULT FALSE,
  
  -- Tooth Type
  `tooth_type_single_layer` BOOLEAN DEFAULT FALSE,
  `tooth_type_double_layer` BOOLEAN DEFAULT FALSE,
  
  -- Partial Design
  `partial_design_spoon_dentures` BOOLEAN DEFAULT FALSE,
  `partial_design_horseshoe_palate_upper` BOOLEAN DEFAULT FALSE,
  `partial_design_wrought_wire_clasps` BOOLEAN DEFAULT FALSE,
  `partial_design_lingual_apron_lower` BOOLEAN DEFAULT FALSE,
  
  -- Metal Framework
  `metal_framework_chrome_cobalt` BOOLEAN DEFAULT FALSE,
  `metal_framework_vitallium` BOOLEAN DEFAULT FALSE,
  
  -- Ellis Acrylic Partial
  `ellis_acrylic_valplast_partial` BOOLEAN DEFAULT FALSE,
  `ellis_acrylic_cast_metal_only` BOOLEAN DEFAULT FALSE,
  `ellis_acrylic_cast_metal_bite_tryin` BOOLEAN DEFAULT FALSE,
  `ellis_acrylic_cast_metal_setup_tryin` BOOLEAN DEFAULT FALSE,
  
  -- Framework Design
  `framework_design_full_palatal_metal` BOOLEAN DEFAULT FALSE,
  `framework_design_lingual_bar_lower` BOOLEAN DEFAULT FALSE,
  `framework_design_cosmetic_clasp` BOOLEAN DEFAULT FALSE,
  
  -- Nightguards/Splints
  `nightguards_upper` BOOLEAN DEFAULT FALSE,
  `nightguards_lower` BOOLEAN DEFAULT FALSE,
  `nightguards_soft` BOOLEAN DEFAULT FALSE,
  `nightguards_hard_clear_acrylic` BOOLEAN DEFAULT FALSE,
  `nightguards_flexiguard_hardsoft` BOOLEAN DEFAULT FALSE,
  `nightguards_astron_thermoguard` BOOLEAN DEFAULT FALSE,
  `nightguards_sports_guard` BOOLEAN DEFAULT FALSE,
  `nightguards_snore_guard` BOOLEAN DEFAULT FALSE,
  
  -- Other options
  `other_reline` BOOLEAN DEFAULT FALSE,
  `other_rebase` BOOLEAN DEFAULT FALSE,
  `other_simple_repair` BOOLEAN DEFAULT FALSE,
  `other_complex_repair` BOOLEAN DEFAULT FALSE,
  `other_soft_liner` BOOLEAN DEFAULT FALSE,
  `other_add_clasp` BOOLEAN DEFAULT FALSE,
  
  -- Acrylic Shade
  `acrylic_shade_pink` BOOLEAN DEFAULT FALSE,
  `acrylic_shade_dark_pink` BOOLEAN DEFAULT FALSE,
  `acrylic_shade_light_pink` BOOLEAN DEFAULT FALSE,
  `acrylic_shade_clear` BOOLEAN DEFAULT FALSE,
  
  -- Tooth shade & Tooth Mould No
  `tooth_shade` VARCHAR(50),
  `tooth_mould_no` VARCHAR(50),
  `shade_guide_used` VARCHAR(100),
  
  -- Special Instructions
  `special_instructions` TEXT,
  
  -- Dentist Signature
  `dentist_signature` VARCHAR(200),
  
  `status` VARCHAR(50) DEFAULT 'pending',
  `created_by` VARCHAR(50),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (`id`),
  KEY `idx_prosth_jobs` (`facilityId`, `status`)
);

-- Dental lab inventory
CREATE TABLE `dental_lab_inventory` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `facilityId` VARCHAR(50) NOT NULL,
  `item_code` VARCHAR(50),
  `item_name` VARCHAR(200),
  `category` VARCHAR(100), -- Acrylic, Wire, Brackets, Bands, etc.
  `unit_of_measure` VARCHAR(50),
  `quantity_in_stock` DECIMAL(10,2),
  `reorder_level` DECIMAL(10,2),
  `unit_cost` DECIMAL(10,2),
  `supplier` VARCHAR(200),
  `last_purchase_date` DATE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);
```

#### **1.3 Oral Care Shop (Dental Pharmacy) Tables**

```sql
-- Dental products catalog
CREATE TABLE `dental_products` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `facilityId` VARCHAR(50) NOT NULL,
  `product_code` VARCHAR(50) UNIQUE,
  `product_name` VARCHAR(200),
  `category` VARCHAR(100), -- Toothpaste, Mouthwash, Dental Floss, Whitening, etc.
  `brand` VARCHAR(100),
  `description` TEXT,
  `unit_of_sale` VARCHAR(50),
  `price` DECIMAL(10,2),
  `cost` DECIMAL(10,2),
  `quantity_in_stock` DECIMAL(10,2),
  `reorder_level` DECIMAL(10,2),
  `supplier` VARCHAR(200),
  `expiry_date` DATE,
  `status` VARCHAR(50) DEFAULT 'active',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_dental_products` (`facilityId`, `category`)
);

-- Dental product sales
CREATE TABLE `dental_product_sales` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `facilityId` VARCHAR(50) NOT NULL,
  `receipt_no` VARCHAR(50),
  `patient_id` VARCHAR(50),
  `product_id` INT(11),
  `product_name` VARCHAR(200),
  `quantity` DECIMAL(10,2),
  `unit_price` DECIMAL(10,2),
  `total_amount` DECIMAL(10,2),
  `discount` DECIMAL(10,2) DEFAULT 0,
  `payment_method` VARCHAR(50),
  `sold_by` VARCHAR(50),
  `sale_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_dental_sales` (`facilityId`, `receipt_no`)
);
```

---

### **PHASE 2: BACKEND API DEVELOPMENT**

#### **2.1 Controller Structure**

Create new controllers following your existing pattern:

```
backend/controller/
├── dental.js          # Main dental doctor module controller
├── dental-lab.js      # Dental lab controller
├── oral-care.js       # Oral care shop controller
└── dental-helpers.js  # Shared helper functions
```

#### **2.2 Key API Endpoints**

**Dental Module (`dental.js`):**
```javascript
// Patient Management
- POST   /dental/patients/new
- GET    /dental/patients/:patientId/:facilityId
- PUT    /dental/patients/:patientId
- GET    /dental/patients/list/:facilityId

// Dental Chart
- POST   /dental/chart/new
- GET    /dental/chart/:patientId/:facilityId
- PUT    /dental/chart/:id
- DELETE /dental/chart/:id

// Procedures
- POST   /dental/procedures/new
- GET    /dental/procedures/:patientId/:facilityId
- PUT    /dental/procedures/:id
- GET    /dental/procedures/list/:facilityId

// Treatment Plans
- POST   /dental/treatment-plan/new
- GET    /dental/treatment-plan/:patientId/:facilityId
- PUT    /dental/treatment-plan/:id
- POST   /dental/treatment-plan/approve/:id
```

**Dental Lab Module (`dental-lab.js`):**
```javascript
// Orthodontic Jobs
- POST   /dental-lab/orthodontic/new
- GET    /dental-lab/orthodontic/:jobCardNo/:facilityId
- PUT    /dental-lab/orthodontic/:id
- GET    /dental-lab/orthodontic/pending/:facilityId
- GET    /dental-lab/orthodontic/completed/:facilityId
- PUT    /dental-lab/orthodontic/status/:id

// Prosthetic Jobs
- POST   /dental-lab/prosthetic/new
- GET    /dental-lab/prosthetic/:jobCardNo/:facilityId
- PUT    /dental-lab/prosthetic/:id
- GET    /dental-lab/prosthetic/pending/:facilityId
- GET    /dental-lab/prosthetic/completed/:facilityId

// Lab Inventory
- POST   /dental-lab/inventory/new
- GET    /dental-lab/inventory/:facilityId
- PUT    /dental-lab/inventory/:id
- GET    /dental-lab/inventory/low-stock/:facilityId
```

**Oral Care Shop (`oral-care.js`):**
```javascript
// Products
- POST   /oral-care/products/new
- GET    /oral-care/products/:facilityId
- PUT    /oral-care/products/:id
- DELETE /oral-care/products/:id
- GET    /oral-care/products/category/:category/:facilityId

// Sales
- POST   /oral-care/sales/new
- GET    /oral-care/sales/:receiptNo/:facilityId
- GET    /oral-care/sales/daily/:facilityId
- GET    /oral-care/sales/report/:facilityId
```

#### **2.3 Routes Structure**

Create route files:
```
backend/routes/
├── dental.js
├── dental-lab.js
└── oral-care.js
```

Register in `app.js`:
```javascript
require('./routes/dental')(app)
require('./routes/dental-lab')(app)
require('./routes/oral-care')(app)
```

---

### **PHASE 3: FRONTEND DEVELOPMENT**

#### **3.1 Component Structure**

```
frontend/src/components/
├── dental/                    # Main dental module
│   ├── DentalDashboard.jsx
│   ├── DentalPatientList.jsx
│   ├── DentalChart.jsx       # Odontogram/tooth chart
│   ├── DentalProcedures.jsx
│   ├── TreatmentPlan.jsx
│   ├── DentalHistory.jsx
│   └── components/
│       ├── ToothDiagram.jsx  # Visual tooth selector
│       ├── ProcedureForm.jsx
│       └── TreatmentPlanForm.jsx
│
├── dental-lab/                # Dental lab module
│   ├── DentalLabDashboard.jsx
│   ├── OrthodonticJobCard.jsx
│   ├── ProstheticJobCard.jsx
│   ├── JobCardList.jsx
│   ├── LabInventory.jsx
│   └── components/
│       ├── OrthoJobForm.jsx
│       ├── ProstheticJobForm.jsx
│       ├── ToothExtractionDiagram.jsx
│       └── JobCardPrint.jsx
│
└── oral-care/                 # Oral care shop module
    ├── OralCareDashboard.jsx
    ├── ProductCatalog.jsx
    ├── ProductSales.jsx
    ├── SalesHistory.jsx
    └── components/
        ├── ProductForm.jsx
        ├── SalesCart.jsx
        └── ProductCard.jsx
```

#### **3.2 Navigation Integration**

Update `frontend/src/components/nav/nav-modules.jsx`:

```javascript
// Add these new nav items
{user.accessTo
  ? hasAccess(user, ["Dental"]) && (
      <NavItem onClick={toggle}>
        <NavLink to="/me/dental" className="nav">
          <FaTooth size={16} style={{ marginRight: 3 }} />
          Dental
        </NavLink>
      </NavItem>
    )
  : null}

{user.accessTo
  ? hasAccess(user, ["Dental Lab"]) && (
      <NavItem onClick={toggle}>
        <NavLink to="/me/dental-lab" className="nav">
          <GiDentalBraces size={16} style={{ marginRight: 3 }} />
          Dental Lab
        </NavLink>
      </NavItem>
    )
  : null}

{user.accessTo
  ? hasAccess(user, ["Oral Care Shop"]) && (
      <NavItem onClick={toggle}>
        <NavLink to="/me/oral-care" className="nav">
          <FaShoppingCart size={16} style={{ marginRight: 3 }} />
          Oral Care Shop
        </NavLink>
      </NavItem>
    )
  : null}
```

#### **3.3 Routing Setup**

Update `frontend/src/App.jsx` or routing configuration:

```javascript
<Route path="/me/dental" component={Dental} />
<Route path="/me/dental-lab" component={DentalLab} />
<Route path="/me/oral-care" component={OralCare} />
```

---

### **PHASE 4: KEY FEATURES IMPLEMENTATION**

#### **4.1 Dental Module Features**

1. **Interactive Odontogram (Tooth Chart)**
   - Visual representation of all 32 teeth
   - Click to select teeth and mark conditions
   - Color coding for different conditions
   - Historical tracking of tooth conditions

2. **Treatment Planning**
   - Multi-step treatment plans
   - Cost estimation
   - Timeline management
   - Approval workflow

3. **Procedure Tracking**
   - Link procedures to specific teeth
   - Track procedure status
   - Integration with billing

#### **4.2 Dental Lab Features**

1. **Job Card Management**
   - Digital versions of the orthodontic and prosthetic job cards
   - All fields from the physical forms
   - File upload for photos/scans
   - Status tracking (Pending → In Progress → Completed → Delivered)

2. **Tooth Extraction Diagram**
   - Interactive upper and lower arch diagrams
   - Click to mark teeth for extraction
   - Visual representation matching the job cards

3. **Lab Workflow**
   - Queue management
   - Priority handling
   - Technician assignment
   - Quality control checkpoints

#### **4.3 Oral Care Shop Features**

1. **Product Management**
   - Categorized product catalog
   - Stock management
   - Expiry date tracking
   - Reorder alerts

2. **Point of Sale**
   - Quick product search
   - Shopping cart
   - Multiple payment methods
   - Receipt printing

3. **Inventory Integration**
   - Real-time stock updates
   - Purchase order generation
   - Supplier management

---

### **PHASE 5: SHARED COMPONENTS & UTILITIES**

#### **5.1 Reusable Components**

1. **Tooth Selector Component**
   ```javascript
   // Can be used in both Dental and Dental Lab modules
   <ToothSelector
     selectedTeeth={selectedTeeth}
     onToothSelect={handleToothSelect}
     mode="single" // or "multiple"
   />
   ```

2. **Job Card Print Template**
   - PDF generation for job cards
   - Matches physical form layout
   - Include all selected options

3. **Patient Search/Autocomplete**
   - Reuse existing patient search
   - Filter for dental patients

#### **5.2 Redux State Management**

Create new Redux slices:
```
frontend/src/redux/
├── actions/
│   ├── dental.js
│   ├── dental-lab.js
│   └── oral-care.js
└── reducers/
    ├── dental.js
    ├── dental-lab.js
    └── oral-care.js
```

---

### **PHASE 6: INTEGRATION POINTS**

#### **6.1 Integration with Existing Modules**

1. **Patient Records**
   - Link dental records to existing patient records
   - Shared patient demographics
   - Unified patient search

2. **Billing/Accounts**
   - Dental procedures → billing
   - Lab jobs → invoicing
   - Oral care sales → transactions
   - Use existing payment workflows

3. **Appointments**
   - Dental appointment types
   - Lab delivery scheduling
   - Follow-up reminders

4. **Reports**
   - Dental procedure reports
   - Lab productivity reports
   - Oral care sales reports
   - Integration with existing report module

#### **6.2 User Access Control**

Update user roles and permissions:
```javascript
// Add to existing access control
const dentalRoles = [
  'Dental Doctor',
  'Dental Assistant',
  'Dental Lab Technician',
  'Oral Care Pharmacist'
]

// Functionality permissions
const dentalFunctionality = [
  'Dental Dashboard',
  'Dental Patients',
  'Dental Chart',
  'Dental Procedures',
  'Treatment Plans',
  'Dental Lab Jobs',
  'Orthodontic Jobs',
  'Prosthetic Jobs',
  'Lab Inventory',
  'Oral Care Products',
  'Oral Care Sales'
]
```

---

### **PHASE 7: IMPLEMENTATION TIMELINE**

**Week 1-2: Database & Backend Foundation**
- Create database tables
- Implement basic CRUD APIs
- Set up routes and controllers
- Test API endpoints

**Week 3-4: Dental Module Frontend**
- Build dental dashboard
- Implement tooth chart/odontogram
- Create procedure forms
- Treatment plan interface

**Week 5-6: Dental Lab Module**
- Orthodontic job card form
- Prosthetic job card form
- Job tracking dashboard
- Lab inventory management

**Week 7-8: Oral Care Shop**
- Product catalog
- Point of sale interface
- Sales tracking
- Inventory integration

**Week 9-10: Integration & Testing**
- Integrate with existing modules
- User access control
- End-to-end testing
- Bug fixes

**Week 11-12: Polish & Deployment**
- UI/UX refinements
- Performance optimization
- Documentation
- Training materials
- Production deployment

---

### **PHASE 8: TECHNICAL CONSIDERATIONS**

#### **8.1 Data Migration**
- If you have existing dental data, create migration scripts
- Map old data structure to new tables

#### **8.2 Performance**
- Index frequently queried fields
- Optimize tooth chart rendering
- Cache product catalog

#### **8.3 Security**
- Role-based access control
- Audit logging for sensitive operations
- HIPAA compliance considerations

#### **8.4 Scalability**
- Design for multi-facility support
- Consider cloud storage for images/scans
- Plan for mobile access

---

### **SUMMARY**

This implementation plan provides:

1. **Complete database schema** for all three modules
2. **Backend API structure** following your existing patterns
3. **Frontend component architecture** matching your current structure
4. **Integration strategy** with existing HMS modules
5. **Realistic timeline** for development
6. **Technical considerations** for production readiness

The modules will seamlessly integrate with your existing HMS while providing specialized workflows for dental practice, dental lab, and oral care retail operations. All three modules share common infrastructure (patients, billing, users) while maintaining their specialized features based on the job cards you provided.