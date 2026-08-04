# DICOM Modality Integration Guide
## Automatic Image Acquisition from Radiology Machines

---

## Overview

Modern radiology machines (CT, MRI, X-Ray, Ultrasound) support DICOM networking protocols that enable:
1. **Worklist (MWL)**: Machines fetch patient/exam info from your system
2. **Storage (C-STORE)**: Machines automatically send images to your PACS
3. **Query/Retrieve (C-FIND/C-MOVE)**: Query and retrieve images from machines

**Feasibility: ✅ HIGHLY DOABLE** - This is standard practice in hospitals worldwide.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Your Application (MyLikita)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Create     │  │   Schedule   │  │   Billing    │          │
│  │   Request    │  │  Appointment │  │   System     │          │
│  └──────┬───────┘  └──────┬───────┘  └──────────────┘          │
│         │                  │                                     │
│         └──────────────────┴──────────────┐                     │
│                                            │                     │
│                    ┌───────────────────────▼──────────┐         │
│                    │  Radiology Worklist Database     │         │
│                    │  (radiology_worklist table)      │         │
│                    └───────────────────┬──────────────┘         │
└────────────────────────────────────────┼──────────────────────────┘
                                         │
                    ┌────────────────────▼──────────────┐
                    │      Orthanc PACS Server          │
                    │  ┌─────────────────────────────┐  │
                    │  │  DICOM Worklist Plugin      │  │ ◄── Modality fetches
                    │  │  (Serves MWL to machines)   │  │     worklist
                    │  └─────────────────────────────┘  │
                    │  ┌─────────────────────────────┐  │
                    │  │  DICOM Storage (C-STORE)    │  │ ◄── Modality sends
                    │  │  (Receives images)          │  │     images
                    │  └─────────────────────────────┘  │
                    │  ┌─────────────────────────────┐  │
                    │  │  Auto-routing Rules         │  │
                    │  │  (Match to requests)        │  │
                    │  └─────────────────────────────┘  │
                    └────────────────┬──────────────────┘
                                     │
                    ┌────────────────▼──────────────┐
                    │   Webhook/Notification        │
                    │   (Images received event)     │
                    └────────────────┬──────────────┘
                                     │
                    ┌────────────────▼──────────────┐
                    │   Your App Backend            │
                    │   - Update request status     │
                    │   - Notify radiologist        │
                    │   - Auto-create billing       │
                    └───────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: DICOM Worklist (MWL) - Machines Fetch Patient Info

#### 1.1 Database Schema for Worklist

```sql
-- Worklist items that machines will fetch
CREATE TABLE radiology_worklist (
  id VARCHAR(255) PRIMARY KEY,
  request_id VARCHAR(255),
  patient_id VARCHAR(255),
  
  -- DICOM Required Fields
  accession_number VARCHAR(100) UNIQUE, -- Unique exam identifier
  patient_name VARCHAR(255),
  patient_id_dicom VARCHAR(100), -- Patient ID for DICOM
  patient_birth_date DATE,
  patient_sex CHAR(1),
  
  -- Study Information
  study_instance_uid VARCHAR(255) UNIQUE,
  study_description TEXT,
  modality VARCHAR(10), -- CT, MR, XR, US, etc.
  scheduled_procedure_step_id VARCHAR(100),
  
  -- Scheduling
  scheduled_date DATE,
  scheduled_time TIME,
  scheduled_station_ae_title VARCHAR(50), -- Machine AE Title
  scheduled_station_name VARCHAR(100),
  
  -- Procedure
  requested_procedure_id VARCHAR(100),
  requested_procedure_description TEXT,
  requested_procedure_code VARCHAR(50),
  
  -- Physician
  referring_physician_name VARCHAR(255),
  performing_physician_name VARCHAR(255),
  
  -- Status
  status ENUM('scheduled', 'in-progress', 'completed', 'cancelled') DEFAULT 'scheduled',
  
  -- Metadata
  facilityId VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (request_id) REFERENCES radiology_requests(id),
  FOREIGN KEY (patient_id) REFERENCES patientrecords(id),
  INDEX idx_accession (accession_number),
  INDEX idx_scheduled (scheduled_date, scheduled_time),
  INDEX idx_status (status)
);

-- Machine/Modality configuration
CREATE TABLE radiology_modalities (
  id VARCHAR(255) PRIMARY KEY,
  modality_name VARCHAR(100),
  modality_type VARCHAR(50), -- CT, MR, XR, US, etc.
  ae_title VARCHAR(50) UNIQUE, -- DICOM Application Entity Title
  ip_address VARCHAR(50),
  port INT DEFAULT 104,
  manufacturer VARCHAR(100),
  model VARCHAR(100),
  location VARCHAR(100),
  is_active BOOLEAN DEFAULT TRUE,
  supports_worklist BOOLEAN DEFAULT TRUE,
  supports_storage BOOLEAN DEFAULT TRUE,
  supports_mpps BOOLEAN DEFAULT FALSE, -- Modality Performed Procedure Step
  facilityId VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.2 Backend: Generate Worklist Items

```javascript
// backend/controller/radiology-worklist.js
const db = require('../models');
const { v4: uuidv4 } = require('uuid');
const moment = require('moment');

/**
 * Create worklist item when appointment is scheduled
 */
exports.createWorklistItem = async (req, res) => {
  try {
    const {
      requestId,
      appointmentId,
      patientId,
      procedureId,
      scheduledDate,
      scheduledTime,
      modalityAETitle,
      referringPhysician
    } = req.body;

    // Get patient details
    const [patient] = await db.sequelize.query(
      `SELECT id, surname, firstname, DOB, Gender, accountNo 
       FROM patientrecords WHERE id = ?`,
      { replacements: [patientId], type: db.sequelize.QueryTypes.SELECT }
    );

    // Get procedure details
    const [procedure] = await db.sequelize.query(
      `SELECT procedure_name, procedure_code, category 
       FROM radiology_procedures WHERE id = ?`,
      { replacements: [procedureId], type: db.sequelize.QueryTypes.SELECT }
    );

    // Generate unique identifiers
    const accessionNumber = `ACC${Date.now()}`;
    const studyInstanceUID = `1.2.840.${Date.now()}.${Math.random().toString().slice(2, 10)}`;
    const scheduledProcedureStepId = `SPS${Date.now()}`;

    // Create worklist item
    const worklistId = uuidv4();
    await db.sequelize.query(
      `INSERT INTO radiology_worklist 
       (id, request_id, patient_id, accession_number, patient_name, 
        patient_id_dicom, patient_birth_date, patient_sex, 
        study_instance_uid, study_description, modality, 
        scheduled_procedure_step_id, scheduled_date, scheduled_time, 
        scheduled_station_ae_title, requested_procedure_description, 
        requested_procedure_code, referring_physician_name, 
        status, facilityId)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      {
        replacements: [
          worklistId,
          requestId,
          patientId,
          accessionNumber,
          `${patient.surname}^${patient.firstname}`, // DICOM format: Last^First
          patient.accountNo || patient.id,
          patient.DOB,
          patient.Gender === 'Male' ? 'M' : 'F',
          studyInstanceUID,
          procedure.procedure_name,
          procedure.category.toUpperCase(), // CT, MR, XR, etc.
          scheduledProcedureStepId,
          scheduledDate,
          scheduledTime,
          modalityAETitle,
          procedure.procedure_name,
          procedure.procedure_code,
          referringPhysician,
          'scheduled',
          req.user.facilityId
        ]
      }
    );

    // Export to Orthanc worklist format
    await exportToOrthancWorklist(worklistId);

    res.json({
      success: true,
      worklistId,
      accessionNumber,
      studyInstanceUID
    });

  } catch (error) {
    console.error('Worklist creation error:', error);
    res.status(500).json({ error: 'Failed to create worklist item' });
  }
};

/**
 * Export worklist to Orthanc format (JSON file)
 */
async function exportToOrthancWorklist(worklistId) {
  const [worklist] = await db.sequelize.query(
    `SELECT * FROM radiology_worklist WHERE id = ?`,
    { replacements: [worklistId], type: db.sequelize.QueryTypes.SELECT }
  );

  const worklistJson = {
    "0008,0050": worklist.accession_number, // Accession Number
    "0010,0010": worklist.patient_name, // Patient Name
    "0010,0020": worklist.patient_id_dicom, // Patient ID
    "0010,0030": moment(worklist.patient_birth_date).format('YYYYMMDD'), // Birth Date
    "0010,0040": worklist.patient_sex, // Sex
    "0020,000d": worklist.study_instance_uid, // Study Instance UID
    "0032,1060": worklist.requested_procedure_description, // Requested Procedure
    "0040,0100": [{ // Scheduled Procedure Step Sequence
      "0008,0060": worklist.modality, // Modality
      "0040,0001": worklist.scheduled_station_ae_title, // Scheduled Station AE Title
      "0040,0002": moment(`${worklist.scheduled_date} ${worklist.scheduled_time}`).format('YYYYMMDDHHmmss'), // Scheduled Procedure Step Start
      "0040,0003": worklist.scheduled_station_name || "", // Scheduled Station Name
      "0040,0006": worklist.performing_physician_name || "", // Scheduled Performing Physician
      "0040,0007": worklist.study_description, // Scheduled Procedure Step Description
      "0040,0009": worklist.scheduled_procedure_step_id // Scheduled Procedure Step ID
    }]
  };

  // Write to Orthanc worklist directory
  const fs = require('fs').promises;
  const path = require('path');
  const worklistDir = process.env.ORTHANC_WORKLIST_DIR || '/var/lib/orthanc/worklists';
  const filename = `${worklist.accession_number}.json`;
  
  await fs.writeFile(
    path.join(worklistDir, filename),
    JSON.stringify(worklistJson, null, 2)
  );
}
```

#### 1.3 Orthanc Worklist Configuration

```json
// orthanc-worklist.json
{
  "Worklists": {
    "Enable": true,
    "Database": "/var/lib/orthanc/worklists"
  }
}
```

---

### Phase 2: Automatic Image Reception (C-STORE)

#### 2.1 Configure Orthanc to Accept Images

```json
// orthanc.json
{
  "DicomAet": "MYLIKITA_PACS",
  "DicomPort": 4242,
  
  "DicomModalities": {
    "CT_SCANNER_1": ["CT_SCANNER", "192.168.1.100", 104],
    "MRI_MACHINE": ["MRI_SIEMENS", "192.168.1.101", 104],
    "XRAY_ROOM_1": ["XRAY_1", "192.168.1.102", 104],
    "ULTRASOUND_1": ["US_GE", "192.168.1.103", 104]
  },
  
  "UnknownSopClassAccepted": true,
  
  "StableAge": 60,
  
  "LuaScripts": ["/etc/orthanc/auto-routing.lua"]
}
```

#### 2.2 Auto-Routing Script (Lua)

```lua
-- /etc/orthanc/auto-routing.lua
-- Automatically process incoming DICOM images

function OnStoredInstance(instanceId, tags, metadata, origin)
    -- Extract DICOM tags
    local studyInstanceUID = tags['StudyInstanceUID']
    local accessionNumber = tags['AccessionNumber']
    local patientID = tags['PatientID']
    local modality = tags['Modality']
    
    -- Log the reception
    print('Received DICOM instance: ' .. instanceId)
    print('Study UID: ' .. studyInstanceUID)
    print('Accession: ' .. accessionNumber)
    
    -- Notify your application via webhook
    local http = require('socket.http')
    local json = require('json')
    
    local payload = json.encode({
        event = 'dicom_received',
        instanceId = instanceId,
        studyInstanceUID = studyInstanceUID,
        accessionNumber = accessionNumber,
        patientID = patientID,
        modality = modality,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    })
    
    local response, status = http.request{
        url = 'http://your-app-backend:46990/api/radiology/dicom/webhook',
        method = 'POST',
        headers = {
            ['Content-Type'] = 'application/json',
            ['Content-Length'] = #payload,
            ['Authorization'] = 'Bearer YOUR_WEBHOOK_SECRET'
        },
        source = ltn12.source.string(payload)
    }
    
    if status == 200 then
        print('Webhook notification sent successfully')
    else
        print('Webhook notification failed: ' .. status)
    end
end
```

#### 2.3 Webhook Handler in Your Backend

```javascript
// backend/controller/radiology-dicom-webhook.js
const db = require('../models');

/**
 * Handle incoming DICOM webhook from Orthanc
 */
exports.handleDicomReceived = async (req, res) => {
  try {
    const {
      instanceId,
      studyInstanceUID,
      accessionNumber,
      patientID,
      modality
    } = req.body;

    console.log('DICOM received webhook:', req.body);

    // Find matching worklist item
    const [worklist] = await db.sequelize.query(
      `SELECT * FROM radiology_worklist 
       WHERE accession_number = ? OR study_instance_uid = ?`,
      {
        replacements: [accessionNumber, studyInstanceUID],
        type: db.sequelize.QueryTypes.SELECT
      }
    );

    if (!worklist) {
      console.warn('No matching worklist found for accession:', accessionNumber);
      return res.json({ success: true, message: 'No matching worklist' });
    }

    // Update worklist status
    await db.sequelize.query(
      `UPDATE radiology_worklist 
       SET status = 'completed' 
       WHERE id = ?`,
      { replacements: [worklist.id] }
    );

    // Update examination status
    await db.sequelize.query(
      `UPDATE radiology_examinations 
       SET status = 'completed' 
       WHERE request_id = ?`,
      { replacements: [worklist.request_id] }
    );

    // Update request status
    await db.sequelize.query(
      `UPDATE radiology_requests 
       SET status = 'completed' 
       WHERE id = ?`,
      { replacements: [worklist.request_id] }
    );

    // Create DICOM study record
    await db.sequelize.query(
      `INSERT INTO radiology_dicom_studies 
       (id, examination_id, patient_id, study_instance_uid, 
        modality, orthanc_study_id, facilityId)
       VALUES (?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE 
       number_of_instances = number_of_instances + 1`,
      {
        replacements: [
          studyInstanceUID,
          worklist.request_id,
          worklist.patient_id,
          studyInstanceUID,
          modality,
          instanceId,
          worklist.facilityId
        ]
      }
    );

    // Send notification to radiologist
    await notifyRadiologist(worklist.request_id, studyInstanceUID);

    // Auto-create billing if not exists
    await autoCreateBilling(worklist.request_id);

    res.json({ success: true, message: 'DICOM processed successfully' });

  } catch (error) {
    console.error('Webhook processing error:', error);
    res.status(500).json({ error: 'Failed to process webhook' });
  }
};

async function notifyRadiologist(requestId, studyUID) {
  // Get assigned radiologist
  const [request] = await db.sequelize.query(
    `SELECT radiologist_id FROM radiology_requests WHERE id = ?`,
    { replacements: [requestId], type: db.sequelize.QueryTypes.SELECT }
  );

  if (request && request.radiologist_id) {
    // Send notification (email, SMS, in-app)
    // Implementation depends on your notification system
    console.log(`Notifying radiologist ${request.radiologist_id} about study ${studyUID}`);
  }
}

async function autoCreateBilling(requestId) {
  // Check if billing already exists
  const [existing] = await db.sequelize.query(
    `SELECT id FROM radiology_billing WHERE request_id = ?`,
    { replacements: [requestId], type: db.sequelize.QueryTypes.SELECT }
  );

  if (existing) return;

  // Get request details
  const [request] = await db.sequelize.query(
    `SELECT r.*, p.base_price, p.revenue_account_head, p.revenue_account_subhead
     FROM radiology_requests r
     JOIN radiology_procedures p ON r.procedure_id = p.id
     WHERE r.id = ?`,
    { replacements: [requestId], type: db.sequelize.QueryTypes.SELECT }
  );

  // Create billing entry
  const transactionId = `RAD${Date.now()}`;
  
  await db.sequelize.query(
    `INSERT INTO pending_txn 
     (transaction_id, description, head, subhead, amount, service_type,
      patient_name, patient_id, patient_type, total_amount, client_acc,
      tx_status, transaction_date, facilityId)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?)`,
    {
      replacements: [
        transactionId,
        `Radiology: ${request.procedure_name}`,
        request.revenue_account_head || 'RADIOLOGY',
        request.revenue_account_subhead || 'RADIOLOGY',
        request.base_price,
        'RADIOLOGY',
        request.patient_name,
        request.patient_id,
        'outpatient',
        request.base_price,
        request.patient_id,
        'pending',
        request.facilityId
      ]
    }
  );

  console.log(`Auto-created billing for request ${requestId}`);
}
```

---

### Phase 3: Machine Configuration

#### 3.1 Configure Modality to Use Your PACS

On each radiology machine (CT, MRI, X-Ray, etc.):

1. **Worklist Configuration:**
   ```
   Worklist Server AE Title: MYLIKITA_PACS
   Worklist Server IP: 192.168.1.50
   Worklist Server Port: 4242
   ```

2. **Storage Configuration:**
   ```
   PACS AE Title: MYLIKITA_PACS
   PACS IP: 192.168.1.50
   PACS Port: 4242
   Auto-send: Enabled
   ```

3. **Test Connection:**
   - Most machines have "Echo" or "Verify" button
   - Test worklist fetch
   - Test image send

---

### Phase 4: Workflow Integration

#### 4.1 Complete Workflow

```
1. Doctor creates radiology request in your app
   ↓
2. Receptionist schedules appointment
   ↓
3. System creates worklist item
   ↓
4. Technician starts machine, fetches worklist
   ↓
5. Machine shows patient info (from worklist)
   ↓
6. Technician performs scan
   ↓
7. Machine auto-sends images to Orthanc
   ↓
8. Orthanc triggers webhook to your app
   ↓
9. Your app:
   - Updates request status
   - Notifies radiologist
   - Creates billing
   ↓
10. Radiologist views images in OHIF
    ↓
11. Radiologist creates report
    ↓
12. Doctor views report and images
```

---

## Alternative: Manual Upload Support

For machines without DICOM networking or for external studies:

```javascript
// Support both automatic and manual upload
exports.uploadDicom = async (req, res) => {
  const { source } = req.body; // 'modality' or 'manual'
  
  if (source === 'manual') {
    // Handle manual upload (from file)
    // Same as before
  } else {
    // Handle automatic upload (from modality)
    // Via webhook
  }
};
```

---

## Network Requirements

### Firewall Rules
```bash
# Allow DICOM traffic
sudo ufw allow 4242/tcp  # Orthanc DICOM port
sudo ufw allow 8042/tcp  # Orthanc Web UI

# Allow from specific modality IPs only (recommended)
sudo ufw allow from 192.168.1.100 to any port 4242
sudo ufw allow from 192.168.1.101 to any port 4242
```

### Network Topology
```
Radiology Machines (192.168.1.100-110)
    ↓
Hospital LAN
    ↓
Orthanc Server (192.168.1.50:4242)
    ↓
Your App Backend (192.168.1.51:46990)
```

---

## Testing & Validation

### Test Tools

1. **DICOM Test Tools:**
   - dcm4che toolkit
   - DICOM Worklist SCU
   - StoreSCU for testing image send

2. **Test Commands:**
```bash
# Test worklist query
findscu -c MYLIKITA_PACS@192.168.1.50:4242 -k 0008,0050="ACC*"

# Test image send
storescu -c MYLIKITA_PACS@192.168.1.50:4242 test.dcm

# Test echo (connectivity)
echoscu MYLIKITA_PACS 192.168.1.50 4242
```

---

## Monitoring & Troubleshooting

### Logging
```javascript
// Log all DICOM events
const winston = require('winston');

const dicomLogger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'dicom-events.log' })
  ]
});

// Log worklist queries
dicomLogger.info('Worklist query', { 
  modality: 'CT_SCANNER_1', 
  timestamp: new Date() 
});

// Log image reception
dicomLogger.info('Image received', { 
  studyUID: '1.2.3.4.5', 
  accession: 'ACC123' 
});
```

### Dashboard Metrics
- Worklist queries per day
- Images received per modality
- Average time from scan to image availability
- Failed transmissions

---

## Security Considerations

1. **Network Isolation**: Keep DICOM network separate from public internet
2. **Authentication**: Use AE Title verification
3. **Encryption**: Use DICOM TLS for sensitive data
4. **Access Control**: Limit which modalities can connect
5. **Audit Logging**: Log all DICOM transactions

---

## Cost & Timeline

### Implementation Timeline
- **Week 1**: Database schema, worklist generation
- **Week 2**: Orthanc configuration, webhook handler
- **Week 3**: Machine configuration, testing
- **Week 4**: Integration testing, go-live

### Hardware Requirements
- Orthanc Server: 4GB RAM, 500GB+ storage
- Network: Gigabit LAN minimum
- Backup: NAS or cloud storage for DICOM files

### Vendor Coordination
- Work with modality vendors for configuration
- May need vendor support for initial setup
- Most modern machines support standard DICOM

---

## Conclusion

**Feasibility: ✅ HIGHLY DOABLE**

This is standard practice in modern hospitals. The combination of:
- DICOM Worklist (MWL) for patient info
- DICOM Storage (C-STORE) for automatic image transfer
- Orthanc as middleware
- Webhooks for real-time notifications

...provides a robust, automated workflow that eliminates manual file uploads while maintaining full integration with your existing system.

**Recommendation**: Start with manual upload support, then add modality integration as machines are configured. This allows gradual rollout and testing.
