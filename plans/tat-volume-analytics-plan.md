# TAT & Volume Analytics — Implementation Plan

## Current State

### Lab Analytics (newlab)
**Backend endpoints** (`backend/controller/newlab-analytics.js`):
- `GET /newlab/analytics/volume` — volume by test+category (flat, no time series)
- `GET /newlab/analytics/tat` — avg TAT hours per test (TIMESTAMPDIFF request→authorised)
- `GET /newlab/analytics/revenue` — revenue by category

**Frontend** (`frontend/src/components/newlab/analytics/LabAnalytics.jsx`):
- KPI cards: total tests, revenue, avg TAT, categories
- Volume bar chart by test
- TAT table with hardcoded 24h SLA flag
- Revenue table by category

### Radiology Analytics
**Backend endpoints** (`backend/controller/radiology-analytics.js`):
- `GET /radiology/analytics/dashboard` — metrics via `sp_get_dashboard_metrics` stored procedure
- `GET /radiology/analytics/turnaround-time` — daily TAT via `sp_get_turnaround_time_metrics`
- `GET /radiology/analytics/productivity` — per-radiologist metrics
- `GET /radiology/analytics/equipment` — per-equipment utilization

**Frontend** (`frontend/src/components/radiology/analytics/AnalyticsDashboard.jsx`):
- KPI cards: total cases, avg turnaround, completion rate, pending, radiologists, modalities
- Case status breakdown (completed/in-progress/pending)
- Performance vs targets (completion rate, TAT, in-progress)

---

## What's Missing

### Lab
1. **Daily volume trend** — no time-series chart, only flat totals
2. **Source breakdown** — walk-in vs referral not visualized
3. **Urgency breakdown** — routine vs urgent vs STAT not visualized
4. **TAT percentiles** — only avg, no p50/p90/p95
5. **Configurable SLA** — hardcoded 24h, should be per-facility
6. **Peak hours** — busiest times of day not tracked
7. **Daily TAT trend** — TAT over time not shown

### Radiology
1. **Daily volume trend** — data exists in stored procedure but not charted
2. **Procedure/modality breakdown** — volume by imaging type not shown
3. **TAT by procedure** — only overall TAT, not per-procedure
4. **Radiologist productivity** — backend exists, no frontend view
5. **Referral source analysis** — who's ordering most not tracked

---

## Implementation Plan

### Phase 1: Backend — New Analytics Endpoints

#### 1a. Lab Enhanced Analytics (`backend/controller/newlab-analytics.js`)

**New endpoints to add:**

```js
// Daily volume trend — COUNT requests per day
GET /newlab/analytics/volume-trend?facilityId=&date_from=&date_to=
→ [{ date, total, walk_in, doctor_referral }]

// Source breakdown — walk-in vs referral totals
GET /newlab/analytics/source-breakdown?facilityId=&date_from=&date_to=
→ [{ source, count, revenue }]

// Urgency breakdown — routine vs urgent vs STAT
GET /newlab/analytics/urgency-breakdown?facilityId=&date_from=&date_to=
→ [{ urgency, count }]

// TAT detailed — percentiles (p50, p90, p95) per test
GET /newlab/analytics/tat-detailed?facilityId=&date_from=&date_to=
→ [{ test_name, avg_hours, p50_hours, p90_hours, p95_hours, count }]

// Peak hours — busiest hours of day
GET /newlab/analytics/peak-hours?facilityId=&date_from=&date_to=
→ [{ hour, count }]
```

**SQL patterns:**
- Volume trend: `SELECT DATE(created_at) as date, COUNT(*), SUM(source='walk_in'), SUM(source='doctor_referral') FROM newlab_requests WHERE facilityId=:fid AND DATE(created_at) BETWEEN :from AND :to GROUP BY DATE(created_at)`
- TAT percentiles: Use `PERCENTILE_CONT(0.5)` or window functions for p50/p90/p95
- Peak hours: `SELECT HOUR(created_at) as hour, COUNT(*) FROM newlab_requests WHERE ... GROUP BY HOUR(created_at)`

#### 1b. Radiology Enhanced Analytics (`backend/controller/radiology-analytics.js`)

**New endpoints to add:**

```js
// Daily volume trend
GET /radiology/analytics/volume-trend?facilityId=&startDate=&endDate=
→ [{ date, total, completed, pending }]

// Procedure/modality breakdown
GET /radiology/analytics/procedure-breakdown?facilityId=&startDate=&endDate=
→ [{ procedure_name, category, count, avg_tat }]

// TAT by procedure type
GET /radiology/analytics/tat-by-procedure?facilityId=&startDate=&endDate=
→ [{ procedure_name, avg_tat_minutes, count }]
```

**SQL patterns:**
- Volume trend: Query `radiology_requests` grouped by DATE(created_at)
- Procedure breakdown: JOIN radiology_requests with radiology_procedures, GROUP BY procedure

#### 1c. Routes

**Lab** (`backend/routes/newlab-analytics.js`): Add 5 new routes
**Radiology** (`backend/routes/radiology-analytics.js`): Add 3 new routes

### Phase 2: Frontend — Enhanced Analytics Dashboards

#### 2a. Lab Analytics Enhancement (`frontend/src/components/newlab/analytics/LabAnalytics.jsx`)

**Changes:**
1. Add daily volume trend chart (CSS bar chart, no new dependencies)
2. Add source breakdown (walk-in vs referral) as pie-style visual
3. Add urgency breakdown as horizontal bars
4. Enhance TAT table: add p50/p90/p95 columns, configurable SLA threshold
5. Add peak hours visualization (24-bar heatmap)
6. Add daily TAT trend line

**New API calls to add:**
```js
get(`/newlab/analytics/volume-trend?${params}`)
get(`/newlab/analytics/source-breakdown?${params}`)
get(`/newlab/analytics/urgency-breakdown?${params}`)
get(`/newlab/analytics/tat-detailed?${params}`)
get(`/newlab/analytics/peak-hours?${params}`)
```

#### 2b. Radiology Analytics Enhancement (`frontend/src/components/radiology/analytics/AnalyticsDashboard.jsx`)

**Changes:**
1. Add daily volume trend chart
2. Add procedure/modality breakdown table
3. Add TAT by procedure table
4. Enhance existing TAT display with more detail

**New API calls to add:**
```js
get(`/radiology/analytics/volume-trend?${params}`)
get(`/radiology/analytics/procedure-breakdown?${params}`)
get(`/radiology/analytics/tat-by-procedure?${params}`)
```

### Phase 3: Chart Library

Use **recharts** (already installed, v2.15.4) — used in VitalSignsHistory, PharmacyDashboard, KirsDashboard, inventory modules.

No new dependencies needed.

---

## Files to Modify

### Backend
1. `backend/controller/newlab-analytics.js` — Add 5 new endpoint methods
2. `backend/routes/newlab-analytics.js` — Add 5 new routes
3. `backend/controller/radiology-analytics.js` — Add 3 new endpoint methods
4. `backend/routes/radiology-analytics.js` — Add 3 new routes

### Frontend
5. `frontend/src/components/newlab/analytics/LabAnalytics.jsx` — Major enhancement
6. `frontend/src/components/radiology/analytics/AnalyticsDashboard.jsx` — Enhancement
7. `frontend/src/components/common/analytics/TrendChart.jsx` — New component
8. `frontend/src/components/common/analytics/BreakdownChart.jsx` — New component
9. `frontend/src/components/common/analytics/TATGauge.jsx` — New component
10. `frontend/src/components/common/analytics/PeakHoursHeatmap.jsx` — New component

---

## Verification

1. **Build**: `cd frontend && npx vite build` — must pass
2. **Tests**: `cd frontend && npx vitest run` — no new failures
3. **Backend syntax**: `cd backend && node -e "require('./controller/newlab-analytics')"` — no errors
4. **Manual verification**: Check that existing analytics pages still render correctly
5. **API test**: curl the new endpoints with a test facilityId to verify responses
