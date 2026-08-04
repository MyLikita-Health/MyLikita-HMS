# DICOM Integration Strategy - Recommendation & Implementation

## Executive Summary

**RECOMMENDATION: Integrate with OHIF Viewer (Hybrid Approach)**

Use OHIF Viewer for DICOM viewing while maintaining your app's workflow, billing, and reporting capabilities.

---

## Option Comparison

### Option 1: Build In-App DICOM Viewer ❌ NOT RECOMMENDED

#### Pros:
- Full control over UI/UX
- Seamless integration
- No external dependencies

#### Cons:
- **Massive development effort** (6-12 months)
- Complex DICOM standard (3000+ pages)
- Requires specialized medical imaging expertise
- Ongoing maintenance burden
- Regulatory compliance complexity
- Performance optimization challenges
- Limited features compared to mature solutions

#### Estimated Cost:
- Development: 6-12 months (1-2 developers)
- Maintenance: Ongoing
- Risk: High (medical imaging is complex)

---

### Option 2: Integrate OHIF Viewer ✅ RECOMMENDED

#### Pros:
- **Production-ready** (used by major hospitals)
- **FDA cleared** for diagnostic use
- Rich feature set (MPR, 3D, measurements, annotations)
- Active community & regular updates
- Modern tech stack (React, Cornerstone.js)
- Extensible plugin architecture
- **Fast implementation** (2-4 weeks)
- Lower maintenance burden

#### Cons:
- External dependency
- Requires DICOM Web (DICOMweb) server
- Some customization limitations
- Learning curve for configuration

#### Estimated Cost:
- Development: 2-4 weeks
- Maintenance: Minimal
- Risk: Low (proven solution)

---

## Recommended Architecture: Hybrid Approach

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Your Application                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Patient    │  │  Radiology   │  │   Billing    │      │
│  │   Records    │  │   Workflow   │  │   System     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│                    ┌───────▼────────┐                        │
│                    │  DICOM Metadata│                        │
│                    │    Database    │                        │
│                    └───────┬────────┘                        │
└────────────────────────────┼──────────────────────────────────┘
                             │
                    ┌────────▼─────────┐
                    │  Orthanc Server  │  ◄── DICOM Storage
                    │  (DICOMweb API)  │      & PACS
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │   OHIF Viewer    │  ◄── Embedded iframe
                    │  (React App)     │      or new tab
                    └──────────────────┘
```

### Component Breakdown

1. **Your Application** (Main System)
   - Patient management
   - Radiology workflow (requests, appointments, reports)
   - Billing integration
   - User authentication
   - Metadata storage

2. **Orthanc** (DICOM Server)
   - Open-source DICOM server
   - Stores DICOM files
   - Provides DICOMweb API
   - Lightweight & easy to deploy
   - Handles DICOM networking (C-STORE, C-FIND, etc.)

3. **OHIF Viewer** (Viewer)
   - Embedded in your app via iframe or new window
   - Connects to Orthanc via DICOMweb
   - Handles all DICOM rendering
   - Provides measurement tools, annotations, etc.

---

## Implementation Plan

### Phase 1: Infrastructure Setup (Week 1)

#### 1.1 Install Orthanc Server

```bash
# Docker installation (recommended)
docker run -p 4242:4242 -p 8042:8042 \
  -v orthanc-db:/var/lib/orthanc/db \
  -e ORTHANC_NAME="MyLikita PACS" \
  jodogne/orthanc-plugins
```

#### 1.2 Configure Orthanc

```json
// orthanc.json
{
  "Name": "MyLikita PACS",
  "RemoteAccessAllowed": true,
  "AuthenticationEnabled": true,
  "RegisteredUsers": {
    "radiology": "password123"
  },
  "DicomWeb": {
    "Enable": true,
    "Root": "/dicom-web/",
    "EnableWado": true,
    "WadoRoot": "/wado",
    "Ssl": false,
    "QidoCaseSensitive": false
  },
  "StorageDirectory": "/var/lib/orthanc/db",
  "IndexDirectory": "/var/lib/orthanc/db",
  "MaximumStorageSize": 0,
  "MaximumPatientCount": 0
}
```

#### 1.3 Deploy OHIF Viewer

```bash
# Option A: Use hosted OHIF (easiest)
# Point to: https://viewer.ohif.org/

# Option B: Self-host OHIF
git clone https://github.com/OHIF/Viewers.git
cd Viewers
yarn install
yarn run build
# Deploy to your server
```

---

### Phase 2: Database Schema Updates (Week 1)

#### Add DICOM-specific fields to radiology_images table

```sql
ALTER TABLE radiology_images
ADD COLUMN dicom_study_uid VARCHAR(255),
ADD COLUMN dicom_series_uid VARCHAR(255),
ADD COLUMN dicom_instance_uid VARCHAR(255),
ADD COLUMN orthanc_id VARCHAR(255),
ADD COLUMN modality VARCHAR(10), -- CT, MR, XR, US, etc.
ADD COLUMN is_dicom BOOLEAN DEFAULT FALSE,
ADD INDEX idx_study_uid (dicom_study_uid),
ADD INDEX idx_series_uid (dicom_series_uid),
ADD INDEX idx_orthanc (orthanc_id);

-- Create DICOM studies table for better organization
CREATE TABLE radiology_dicom_studies (
  id VARCHAR(255) PRIMARY KEY,
  examination_id VARCHAR(255),
  patient_id VARCHAR(255),
  study_instance_uid VARCHAR(255) UNIQUE,
  study_date DATE,
  study_time TIME,
  study_description TEXT,
  modality VARCHAR(10),
  number_of_series INT DEFAULT 0,
  number_of_instances INT DEFAULT 0,
  orthanc_study_id VARCHAR(255),
  facilityId VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (examination_id) REFERENCES radiology_examinations(id),
  FOREIGN KEY (patient_id) REFERENCES patientrecords(id),
  INDEX idx_study_uid (study_instance_uid),
  INDEX idx_patient (patient_id),
  INDEX idx_exam (examination_id)
);
```

---

### Phase 3: Backend Integration (Week 2)

#### 3.1 Create Orthanc API Client

```javascript
// backend/services/orthancClient.js
const axios = require('axios');

const ORTHANC_URL = process.env.ORTHANC_URL || 'http://localhost:8042';
const ORTHANC_USER = process.env.ORTHANC_USER || 'radiology';
const ORTHANC_PASSWORD = process.env.ORTHANC_PASSWORD || 'password123';

const orthancClient = axios.create({
  baseURL: ORTHANC_URL,
  auth: {
    username: ORTHANC_USER,
    password: ORTHANC_PASSWORD
  }
});

module.exports = {
  // Upload DICOM file
  uploadDicom: async (fileBuffer) => {
    const response = await orthancClient.post('/instances', fileBuffer, {
      headers: { 'Content-Type': 'application/dicom' }
    });
    return response.data;
  },

  // Get study metadata
  getStudy: async (studyId) => {
    const response = await orthancClient.get(`/studies/${studyId}`);
    return response.data;
  },

  // Get patient studies
  getPatientStudies: async (patientId) => {
    const response = await orthancClient.get(`/patients/${patientId}/studies`);
    return response.data;
  },

  // Delete study
  deleteStudy: async (studyId) => {
    await orthancClient.delete(`/studies/${studyId}`);
  },

  // Get DICOM tags
  getStudyTags: async (studyId) => {
    const response = await orthancClient.get(`/studies/${studyId}/simplified-tags`);
    return response.data;
  }
};
```

#### 3.2 Create DICOM Upload Endpoint

```javascript
// backend/controller/radiology-dicom.js
const multer = require('multer');
const orthancClient = require('../services/orthancClient');
const db = require('../models');

// Configure multer for DICOM upload
const upload = multer({
  storage: multer.memoryStorage(),
  fileFilter: (req, file, cb) => {
    // Accept DICOM files
    if (file.mimetype === 'application/dicom' || 
        file.originalname.endsWith('.dcm')) {
      cb(null, true);
    } else {
      cb(new Error('Only DICOM files are allowed'));
    }
  },
  limits: { fileSize: 500 * 1024 * 1024 } // 500MB max
});

exports.uploadDicom = async (req, res) => {
  try {
    const { examinationId, patientId } = req.body;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    // Upload to Orthanc
    const orthancResponse = await orthancClient.uploadDicom(file.buffer);
    
    // Extract metadata
    const studyId = orthancResponse.ParentStudy;
    const studyTags = await orthancClient.getStudyTags(studyId);

    // Store metadata in database
    const study = await db.sequelize.query(
      `INSERT INTO radiology_dicom_studies 
       (id, examination_id, patient_id, study_instance_uid, 
        study_date, study_description, modality, orthanc_study_id, facilityId)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE 
       number_of_instances = number_of_instances + 1`,
      {
        replacements: [
          studyTags.StudyInstanceUID,
          examinationId,
          patientId,
          studyTags.StudyInstanceUID,
          studyTags.StudyDate,
          studyTags.StudyDescription || '',
          studyTags.Modality || '',
          studyId,
          req.user.facilityId
        ]
      }
    );

    res.json({
      success: true,
      studyId: studyId,
      studyInstanceUID: studyTags.StudyInstanceUID
    });

  } catch (error) {
    console.error('DICOM upload error:', error);
    res.status(500).json({ error: 'Failed to upload DICOM file' });
  }
};

exports.getStudyViewerUrl = async (req, res) => {
  try {
    const { studyInstanceUID } = req.params;

    // Generate OHIF viewer URL
    const ohifUrl = `${process.env.OHIF_VIEWER_URL}/viewer?StudyInstanceUIDs=${studyInstanceUID}`;

    res.json({
      success: true,
      viewerUrl: ohifUrl
    });

  } catch (error) {
    res.status(500).json({ error: 'Failed to generate viewer URL' });
  }
};

exports.getPatientStudies = async (req, res) => {
  try {
    const { patientId } = req.params;

    const studies = await db.sequelize.query(
      `SELECT * FROM radiology_dicom_studies 
       WHERE patient_id = ? 
       ORDER BY study_date DESC`,
      {
        replacements: [patientId],
        type: db.sequelize.QueryTypes.SELECT
      }
    );

    res.json({ success: true, studies });

  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch studies' });
  }
};

module.exports.upload = upload;
```

#### 3.3 Add Routes

```javascript
// backend/routes/radiology-dicom.js
const express = require('express');
const router = express.Router();
const dicomController = require('../controller/radiology-dicom');
const { authenticate } = require('../middleware/authenticate');

router.post('/upload', 
  authenticate, 
  dicomController.upload.single('dicom'),
  dicomController.uploadDicom
);

router.get('/studies/:studyInstanceUID/viewer-url', 
  authenticate,
  dicomController.getStudyViewerUrl
);

router.get('/patients/:patientId/studies',
  authenticate,
  dicomController.getPatientStudies
);

module.exports = router;
```

---

### Phase 4: Frontend Integration (Week 2-3)

#### 4.1 DICOM Upload Component

```jsx
// frontend/src/components/radiology/dicom/DicomUploader.jsx
import React, { useState } from 'react';
import { post } from '../../../utils/apiClient';
import { _customNotify, _warningNotify } from '../../utils/helpers';

const DicomUploader = ({ examinationId, patientId, onUploadComplete }) => {
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);

  const handleFileSelect = async (e) => {
    const files = Array.from(e.target.files);
    
    if (files.length === 0) return;

    setUploading(true);

    try {
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        const formData = new FormData();
        formData.append('dicom', file);
        formData.append('examinationId', examinationId);
        formData.append('patientId', patientId);

        await post('/radiology/dicom/upload', formData, {
          headers: { 'Content-Type': 'multipart/form-data' },
          onUploadProgress: (progressEvent) => {
            const percentCompleted = Math.round(
              ((i + progressEvent.loaded / progressEvent.total) / files.length) * 100
            );
            setProgress(percentCompleted);
          }
        });
      }

      _customNotify(`Successfully uploaded ${files.length} DICOM file(s)`);
      if (onUploadComplete) onUploadComplete();

    } catch (error) {
      console.error('Upload error:', error);
      _warningNotify('Failed to upload DICOM files');
    } finally {
      setUploading(false);
      setProgress(0);
    }
  };

  return (
    <div className="dicom-uploader">
      <input
        type="file"
        accept=".dcm,application/dicom"
        multiple
        onChange={handleFileSelect}
        disabled={uploading}
        style={{ display: 'none' }}
        id="dicom-file-input"
      />
      
      <label 
        htmlFor="dicom-file-input" 
        className="btn btn-primary"
        style={{ cursor: uploading ? 'not-allowed' : 'pointer' }}
      >
        {uploading ? `Uploading... ${progress}%` : 'Upload DICOM Files'}
      </label>

      {uploading && (
        <div className="progress mt-2">
          <div 
            className="progress-bar" 
            style={{ width: `${progress}%` }}
          >
            {progress}%
          </div>
        </div>
      )}
    </div>
  );
};

export default DicomUploader;
```

#### 4.2 DICOM Viewer Component

```jsx
// frontend/src/components/radiology/dicom/DicomViewer.jsx
import React, { useState, useEffect } from 'react';
import { get } from '../../../utils/apiClient';

const DicomViewer = ({ studyInstanceUID, patientId }) => {
  const [viewerUrl, setViewerUrl] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadViewerUrl();
  }, [studyInstanceUID]);

  const loadViewerUrl = async () => {
    try {
      const response = await get(
        `/radiology/dicom/studies/${studyInstanceUID}/viewer-url`
      );
      setViewerUrl(response.data.viewerUrl);
    } catch (error) {
      console.error('Failed to load viewer URL:', error);
    } finally {
      setLoading(false);
    }
  };

  const openInNewTab = () => {
    window.open(viewerUrl, '_blank', 'width=1200,height=800');
  };

  if (loading) {
    return <div>Loading viewer...</div>;
  }

  return (
    <div className="dicom-viewer-container">
      <div className="viewer-controls mb-3">
        <button 
          className="btn btn-primary"
          onClick={openInNewTab}
        >
          Open in Full Screen
        </button>
      </div>

      {/* Embedded viewer */}
      <div className="viewer-frame">
        <iframe
          src={viewerUrl}
          width="100%"
          height="800px"
          frameBorder="0"
          title="DICOM Viewer"
        />
      </div>
    </div>
  );
};

export default DicomViewer;
```

#### 4.3 Study List Component

```jsx
// frontend/src/components/radiology/dicom/StudyList.jsx
import React, { useState, useEffect } from 'react';
import { get } from '../../../utils/apiClient';
import DicomViewer from './DicomViewer';

const StudyList = ({ patientId }) => {
  const [studies, setStudies] = useState([]);
  const [selectedStudy, setSelectedStudy] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStudies();
  }, [patientId]);

  const loadStudies = async () => {
    try {
      const response = await get(`/radiology/dicom/patients/${patientId}/studies`);
      setStudies(response.data.studies);
    } catch (error) {
      console.error('Failed to load studies:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div>Loading studies...</div>;

  return (
    <div className="study-list">
      <h4>DICOM Studies</h4>
      
      {studies.length === 0 ? (
        <p>No DICOM studies found for this patient.</p>
      ) : (
        <div className="row">
          <div className="col-md-4">
            <div className="list-group">
              {studies.map(study => (
                <button
                  key={study.id}
                  className={`list-group-item list-group-item-action ${
                    selectedStudy?.id === study.id ? 'active' : ''
                  }`}
                  onClick={() => setSelectedStudy(study)}
                >
                  <div className="d-flex w-100 justify-content-between">
                    <h6 className="mb-1">{study.study_description}</h6>
                    <small>{study.modality}</small>
                  </div>
                  <small>{new Date(study.study_date).toLocaleDateString()}</small>
                </button>
              ))}
            </div>
          </div>

          <div className="col-md-8">
            {selectedStudy ? (
              <DicomViewer 
                studyInstanceUID={selectedStudy.study_instance_uid}
                patientId={patientId}
              />
            ) : (
              <div className="text-center text-muted p-5">
                Select a study to view
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default StudyList;
```

---

### Phase 5: Configuration (Week 3)

#### 5.1 Environment Variables

```bash
# backend/.env
ORTHANC_URL=http://localhost:8042
ORTHANC_USER=radiology
ORTHANC_PASSWORD=your_secure_password
OHIF_VIEWER_URL=https://viewer.ohif.org
# Or self-hosted: http://localhost:3000
```

#### 5.2 OHIF Configuration (if self-hosting)

```javascript
// ohif-config.js
window.config = {
  routerBasename: '/',
  servers: {
    dicomWeb: [
      {
        name: 'Orthanc',
        wadoUriRoot: 'http://localhost:8042/wado',
        qidoRoot: 'http://localhost:8042/dicom-web',
        wadoRoot: 'http://localhost:8042/dicom-web',
        qidoSupportsIncludeField: false,
        imageRendering: 'wadors',
        thumbnailRendering: 'wadors',
        requestOptions: {
          auth: 'radiology:password123'
        }
      }
    ]
  }
};
```

---

## Deployment Considerations

### Production Setup

1. **Orthanc**: Deploy on dedicated server or container
2. **OHIF**: Can use hosted version or self-host
3. **Storage**: Use network storage (NAS/SAN) for DICOM files
4. **Backup**: Regular backups of Orthanc database
5. **Security**: HTTPS, authentication, firewall rules

### Scalability

- Orthanc can handle 100,000+ studies
- For larger scale, consider Orthanc clustering
- Use CDN for OHIF static files
- Implement caching for frequently accessed studies

---

## Cost Analysis

### Option 1: Build In-App
- Development: $50,000 - $100,000
- Maintenance: $20,000/year
- Total Year 1: $70,000 - $120,000

### Option 2: OHIF Integration
- Development: $5,000 - $10,000
- Orthanc hosting: $100-500/month
- OHIF hosting: Free (use hosted) or $50/month
- Maintenance: $2,000/year
- Total Year 1: $8,200 - $14,000

**Savings: $56,000 - $106,000 in Year 1**

---

## Conclusion

**Use OHIF Viewer with Orthanc backend**. This gives you:

✅ Professional DICOM viewing in 2-3 weeks
✅ 90% cost savings vs building in-app
✅ FDA-cleared, production-ready solution
✅ Full control over workflow and billing
✅ Easy maintenance and updates
✅ Proven reliability

Start with the hybrid approach and you can always customize OHIF later if needed.
