# Week 10 Day 1 Implementation Guide
## Analytics Foundation & Dashboard Metrics

**Date**: March 11, 2026  
**Day**: 1 of 5  
**Duration**: 8 hours  
**Status**: Ready to Execute

---

## Day 1 Overview

Day 1 focuses on building the foundation for analytics and implementing the dashboard metrics system. This includes:

- Creating analytics controller with core functions
- Setting up analytics routes
- Creating analytics service with caching
- Implementing database procedures
- Building the analytics dashboard component

---

## Morning Session (4 hours)

### Task 1: Create Analytics Controller (1 hour)

**File**: `backend/controller/radiology-analytics.js`

**Functions to Implement**:

```javascript
// Dashboard Metrics
async getDashboardMetrics(facilityId, dateRange)
async getRadiologistMetrics(radiologistId, dateRange)
async getEquipmentMetrics(equipmentId, dateRange)
async getTurnaroundTimeMetrics(facilityId, dateRange)

// Helper Functions
calculateAverageTurnaroundTime(cases)
calculateCaseVolume(cases)
calculateCompletionRate(cases)
calculateQualityScore(cases)
```

**Key Features**:
- Error handling with try-catch
- Input validation
- Logging for debugging
- Transaction support
- Performance optimization

**Code Structure**:
```javascript
const { query } = require('../../config/database');
const logger = require('../../utils/logger');

class AnalyticsController {
  // Dashboard Metrics
  static async getDashboardMetrics(facilityId, dateRange) {
    try {
      // Validate inputs
      if (!facilityId) throw new Error('Facility ID required');
      
      // Get metrics from database
      const metrics = await query(
        'CALL sp_get_dashboard_metrics(?, ?, ?)',
        [facilityId, dateRange.start, dateRange.end]
      );
      
      // Return formatted response
      return {
        success: true,
        data: metrics[0],
        timestamp: new Date()
      };
    } catch (error) {
      logger.error('Error getting dashboard metrics:', error);
      throw error;
    }
  }
  
  // Additional functions...
}

module.exports = AnalyticsController;
```

**Estimated Lines**: 250 lines

---

### Task 2: Create Analytics Routes (1 hour)

**File**: `backend/routes/radiology-analytics.js`

**Endpoints to Implement**:

```javascript
// Dashboard
GET    /radiology/analytics/dashboard
GET    /radiology/analytics/dashboard/:radiologistId
GET    /radiology/analytics/dashboard/:equipmentId

// Reports
GET    /radiology/analytics/productivity
GET    /radiology/analytics/equipment
GET    /radiology/analytics/turnaround-time
GET    /radiology/analytics/quality

// Metrics
GET    /radiology/analytics/metrics/radiologist
GET    /radiology/analytics/metrics/equipment
GET    /radiology/analytics/metrics/system
```

**Code Structure**:
```javascript
const express = require('express');
const router = express.Router();
const { authenticate } = require('../../middleware/authenticate');
const AnalyticsController = require('../../controller/radiology-analytics');

// Dashboard endpoints
router.get('/dashboard', authenticate, async (req, res) => {
  try {
    const { facilityId, startDate, endDate } = req.query;
    const metrics = await AnalyticsController.getDashboardMetrics(
      facilityId,
      { start: startDate, end: endDate }
    );
    res.json(metrics);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Additional routes...

module.exports = router;
```

**Estimated Lines**: 100 lines

---

### Task 3: Create Analytics Service (1 hour)

**File**: `backend/services/radiology-analytics.js`

**Functions to Implement**:

```javascript
// Data Aggregation
aggregateDashboardData(metrics)
aggregateProductivityData(radiologistMetrics)
aggregateEquipmentData(equipmentMetrics)

// Caching
getCachedMetrics(key)
setCachedMetrics(key, data, ttl)
invalidateCache(pattern)

// Performance Optimization
optimizeQuery(query)
createIndexes()
```

**Code Structure**:
```javascript
const NodeCache = require('node-cache');
const logger = require('../../utils/logger');

class AnalyticsService {
  constructor() {
    this.cache = new NodeCache({ stdTTL: 300 }); // 5 minute TTL
  }
  
  // Aggregation functions
  aggregateDashboardData(metrics) {
    return {
      totalCases: metrics.reduce((sum, m) => sum + m.cases, 0),
      averageTurnaroundTime: this.calculateAverage(metrics.map(m => m.turnaroundTime)),
      completionRate: this.calculateCompletionRate(metrics),
      qualityScore: this.calculateQualityScore(metrics)
    };
  }
  
  // Caching functions
  getCachedMetrics(key) {
    return this.cache.get(key);
  }
  
  setCachedMetrics(key, data, ttl = 300) {
    this.cache.set(key, data, ttl);
  }
  
  // Helper functions
  calculateAverage(values) {
    return values.reduce((a, b) => a + b, 0) / values.length;
  }
  
  calculateCompletionRate(metrics) {
    const completed = metrics.filter(m => m.status === 'completed').length;
    return (completed / metrics.length) * 100;
  }
  
  calculateQualityScore(metrics) {
    // Implementation based on accuracy, revisions, etc.
    return 95; // Placeholder
  }
}

module.exports = new AnalyticsService();
```

**Estimated Lines**: 150 lines

---

### Task 4: Create Database Procedures (1 hour)

**File**: `backend/sql/radiology_analytics_procedures.sql`

**Procedures to Create**:

```sql
-- Dashboard Metrics Procedure
DELIMITER //
CREATE PROCEDURE sp_get_dashboard_metrics(
  IN p_facility_id INT,
  IN p_start_date DATE,
  IN p_end_date DATE
)
BEGIN
  SELECT
    COUNT(DISTINCT rr.id) as total_cases,
    COUNT(DISTINCT rr.requesting_doctor_id) as total_radiologists,
    COUNT(DISTINCT rm.id) as total_modalities,
    AVG(TIMESTAMPDIFF(MINUTE, rr.created_at, rr.completed_at)) as avg_turnaround_time,
    SUM(CASE WHEN rr.status = 'completed' THEN 1 ELSE 0 END) / COUNT(*) * 100 as completion_rate,
    COUNT(CASE WHEN rr.status = 'pending' THEN 1 END) as pending_cases,
    COUNT(CASE WHEN rr.status = 'in_progress' THEN 1 END) as in_progress_cases
  FROM radiology_requests rr
  LEFT JOIN radiology_modalities rm ON rr.modality_id = rm.id
  WHERE rr.facility_id = p_facility_id
  AND DATE(rr.created_at) BETWEEN p_start_date AND p_end_date;
END //
DELIMITER ;

-- Radiologist Metrics Procedure
DELIMITER //
CREATE PROCEDURE sp_get_radiologist_metrics(
  IN p_radiologist_id INT,
  IN p_start_date DATE,
  IN p_end_date DATE
)
BEGIN
  SELECT
    u.id,
    u.name,
    COUNT(rr.id) as total_cases,
    AVG(TIMESTAMPDIFF(MINUTE, rr.created_at, rr.completed_at)) as avg_turnaround_time,
    SUM(CASE WHEN rr.status = 'completed' THEN 1 ELSE 0 END) / COUNT(*) * 100 as completion_rate,
    COUNT(DISTINCT DATE(rr.created_at)) as working_days
  FROM users u
  LEFT JOIN radiology_requests rr ON u.id = rr.requesting_doctor_id
  WHERE u.id = p_radiologist_id
  AND DATE(rr.created_at) BETWEEN p_start_date AND p_end_date
  GROUP BY u.id, u.name;
END //
DELIMITER ;

-- Equipment Metrics Procedure
DELIMITER //
CREATE PROCEDURE sp_get_equipment_metrics(
  IN p_equipment_id INT,
  IN p_start_date DATE,
  IN p_end_date DATE
)
BEGIN
  SELECT
    rm.id,
    rm.modality_name,
    COUNT(rr.id) as total_cases,
    AVG(TIMESTAMPDIFF(MINUTE, rr.created_at, rr.completed_at)) as avg_case_time,
    SUM(CASE WHEN rr.status = 'completed' THEN 1 ELSE 0 END) / COUNT(*) * 100 as completion_rate,
    COUNT(DISTINCT DATE(rr.created_at)) as working_days
  FROM radiology_modalities rm
  LEFT JOIN radiology_requests rr ON rm.id = rr.modality_id
  WHERE rm.id = p_equipment_id
  AND DATE(rr.created_at) BETWEEN p_start_date AND p_end_date
  GROUP BY rm.id, rm.modality_name;
END //
DELIMITER ;

-- Turnaround Time Metrics Procedure
DELIMITER //
CREATE PROCEDURE sp_get_turnaround_time_metrics(
  IN p_facility_id INT,
  IN p_start_date DATE,
  IN p_end_date DATE
)
BEGIN
  SELECT
    DATE(rr.created_at) as date,
    COUNT(rr.id) as total_cases,
    AVG(TIMESTAMPDIFF(MINUTE, rr.created_at, rr.completed_at)) as avg_turnaround_time,
    MIN(TIMESTAMPDIFF(MINUTE, rr.created_at, rr.completed_at)) as min_turnaround_time,
    MAX(TIMESTAMPDIFF(MINUTE, rr.created_at, rr.completed_at)) as max_turnaround_time,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TIMESTAMPDIFF(MINUTE, rr.created_at, rr.completed_at)) as median_turnaround_time
  FROM radiology_requests rr
  WHERE rr.facility_id = p_facility_id
  AND rr.status = 'completed'
  AND DATE(rr.created_at) BETWEEN p_start_date AND p_end_date
  GROUP BY DATE(rr.created_at)
  ORDER BY DATE(rr.created_at) DESC;
END //
DELIMITER ;
```

**Estimated Lines**: 100 lines

---

## Afternoon Session (4 hours)

### Task 5: Create Analytics Dashboard Component (2 hours)

**File**: `frontend/src/components/radiology/analytics/AnalyticsDashboard.jsx`

**Component Structure**:

```javascript
import React, { useState, useEffect } from 'react';
import { get } from '../../../utils/apiClient';
import KeyMetricsCard from './KeyMetricsCard';
import ChartComponent from './ChartComponent';
import './analytics.css';

const AnalyticsDashboard = () => {
  const [metrics, setMetrics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [dateRange, setDateRange] = useState({
    start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    end: new Date()
  });

  useEffect(() => {
    fetchMetrics();
  }, [dateRange]);

  const fetchMetrics = async () => {
    try {
      setLoading(true);
      const response = await get('/radiology/analytics/dashboard', {
        startDate: dateRange.start.toISOString().split('T')[0],
        endDate: dateRange.end.toISOString().split('T')[0]
      });
      
      if (response.data?.success) {
        setMetrics(response.data.data);
      } else {
        setError('Failed to load metrics');
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div className="loading">Loading analytics...</div>;
  if (error) return <div className="error">{error}</div>;

  return (
    <div className="analytics-dashboard">
      <h1>Radiology Analytics Dashboard</h1>
      
      {/* Date Range Selector */}
      <div className="date-range-selector">
        <input
          type="date"
          value={dateRange.start.toISOString().split('T')[0]}
          onChange={(e) => setDateRange({
            ...dateRange,
            start: new Date(e.target.value)
          })}
        />
        <span>to</span>
        <input
          type="date"
          value={dateRange.end.toISOString().split('T')[0]}
          onChange={(e) => setDateRange({
            ...dateRange,
            end: new Date(e.target.value)
          })}
        />
      </div>

      {/* Key Metrics */}
      <div className="metrics-grid">
        <KeyMetricsCard
          title="Total Cases"
          value={metrics?.total_cases || 0}
          icon="📊"
        />
        <KeyMetricsCard
          title="Avg Turnaround Time"
          value={`${Math.round(metrics?.avg_turnaround_time || 0)} min`}
          icon="⏱️"
        />
        <KeyMetricsCard
          title="Completion Rate"
          value={`${Math.round(metrics?.completion_rate || 0)}%`}
          icon="✅"
        />
        <KeyMetricsCard
          title="Pending Cases"
          value={metrics?.pending_cases || 0}
          icon="⏳"
        />
      </div>

      {/* Charts */}
      <div className="charts-grid">
        <ChartComponent
          title="Cases by Status"
          type="pie"
          data={{
            completed: metrics?.completed_cases || 0,
            pending: metrics?.pending_cases || 0,
            in_progress: metrics?.in_progress_cases || 0
          }}
        />
        <ChartComponent
          title="Turnaround Time Trend"
          type="line"
          data={metrics?.turnaround_time_trend || []}
        />
      </div>
    </div>
  );
};

export default AnalyticsDashboard;
```

**Estimated Lines**: 300 lines

---

### Task 6: Create Supporting Components (1 hour)

**File 1**: `frontend/src/components/radiology/analytics/KeyMetricsCard.jsx`

```javascript
import React from 'react';

const KeyMetricsCard = ({ title, value, icon, trend }) => {
  return (
    <div className="metrics-card">
      <div className="card-icon">{icon}</div>
      <div className="card-content">
        <h3>{title}</h3>
        <p className="card-value">{value}</p>
        {trend && <p className="card-trend">{trend}</p>}
      </div>
    </div>
  );
};

export default KeyMetricsCard;
```

**File 2**: `frontend/src/components/radiology/analytics/ChartComponent.jsx`

```javascript
import React from 'react';
import { LineChart, PieChart, BarChart, Line, Pie, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

const ChartComponent = ({ title, type, data }) => {
  const renderChart = () => {
    switch (type) {
      case 'line':
        return (
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={data}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line type="monotone" dataKey="value" stroke="#8884d8" />
            </LineChart>
          </ResponsiveContainer>
        );
      case 'pie':
        return (
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie data={Object.entries(data).map(([name, value]) => ({ name, value }))} />
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        );
      default:
        return <div>Chart type not supported</div>;
    }
  };

  return (
    <div className="chart-container">
      <h3>{title}</h3>
      {renderChart()}
    </div>
  );
};

export default ChartComponent;
```

**Estimated Lines**: 150 lines

---

### Task 7: Create Styling (30 minutes)

**File**: `frontend/src/components/radiology/analytics/analytics.css`

```css
.analytics-dashboard {
  padding: 20px;
  background-color: #f5f5f5;
}

.analytics-dashboard h1 {
  color: #333;
  margin-bottom: 20px;
}

.date-range-selector {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
  align-items: center;
}

.date-range-selector input {
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.metrics-card {
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  display: flex;
  align-items: center;
  gap: 15px;
}

.card-icon {
  font-size: 32px;
}

.card-content h3 {
  margin: 0;
  color: #666;
  font-size: 14px;
}

.card-value {
  margin: 5px 0 0 0;
  font-size: 24px;
  font-weight: bold;
  color: #333;
}

.card-trend {
  margin: 5px 0 0 0;
  font-size: 12px;
  color: #4CAF50;
}

.charts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 20px;
}

.chart-container {
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.chart-container h3 {
  margin-top: 0;
  color: #333;
}

.loading, .error {
  padding: 20px;
  text-align: center;
  font-size: 16px;
}

.error {
  color: #d32f2f;
  background-color: #ffebee;
  border-radius: 4px;
}
```

**Estimated Lines**: 150 lines

---

### Task 8: Unit Tests (30 minutes)

**File**: `backend/tests/radiology-analytics.test.js`

```javascript
const AnalyticsController = require('../controller/radiology-analytics');
const AnalyticsService = require('../services/radiology-analytics');

describe('Analytics Controller', () => {
  describe('getDashboardMetrics', () => {
    it('should return dashboard metrics', async () => {
      const metrics = await AnalyticsController.getDashboardMetrics(1, {
        start: '2026-03-01',
        end: '2026-03-11'
      });
      
      expect(metrics.success).toBe(true);
      expect(metrics.data).toBeDefined();
      expect(metrics.data.total_cases).toBeDefined();
    });

    it('should throw error without facility ID', async () => {
      expect(async () => {
        await AnalyticsController.getDashboardMetrics(null, {});
      }).rejects.toThrow();
    });
  });
});

describe('Analytics Service', () => {
  describe('aggregateDashboardData', () => {
    it('should aggregate metrics correctly', () => {
      const metrics = [
        { cases: 10, turnaroundTime: 30 },
        { cases: 15, turnaroundTime: 45 }
      ];
      
      const result = AnalyticsService.aggregateDashboardData(metrics);
      
      expect(result.totalCases).toBe(25);
      expect(result.averageTurnaroundTime).toBe(37.5);
    });
  });

  describe('caching', () => {
    it('should cache and retrieve metrics', () => {
      const data = { test: 'data' };
      AnalyticsService.setCachedMetrics('test-key', data);
      
      const cached = AnalyticsService.getCachedMetrics('test-key');
      expect(cached).toEqual(data);
    });
  });
});
```

**Estimated Lines**: 100 lines

---

## Integration Checklist

### Backend Integration
- [ ] Register analytics routes in `backend/app.js`
- [ ] Add analytics controller import
- [ ] Add analytics service import
- [ ] Test all endpoints

### Frontend Integration
- [ ] Add analytics dashboard to navigation
- [ ] Add route in RadiologyRouter
- [ ] Import analytics components
- [ ] Test dashboard rendering

### Database Integration
- [ ] Create analytics procedures
- [ ] Create analytics tables
- [ ] Add indexes for performance
- [ ] Test procedures

---

## Testing Checklist

### Unit Tests
- [ ] Analytics controller functions
- [ ] Analytics service functions
- [ ] Dashboard component rendering
- [ ] Chart component rendering

### Integration Tests
- [ ] API endpoint responses
- [ ] Database procedure execution
- [ ] Data flow from API to component
- [ ] Caching functionality

### Manual Tests
- [ ] Dashboard loads correctly
- [ ] Metrics display accurately
- [ ] Date range filtering works
- [ ] Charts render properly

---

## Performance Optimization

### Database Optimization
- Create indexes on frequently queried columns
- Use stored procedures for aggregation
- Implement query caching

### Frontend Optimization
- Lazy load chart components
- Implement virtual scrolling for large datasets
- Use React.memo for component optimization

### Caching Strategy
- Cache dashboard metrics for 5 minutes
- Cache radiologist metrics for 10 minutes
- Cache equipment metrics for 15 minutes
- Invalidate cache on data updates

---

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Code review approved
- [ ] Security review passed
- [ ] Performance review passed

### Deployment
- [ ] Deploy backend changes
- [ ] Deploy frontend changes
- [ ] Run database procedures
- [ ] Verify all endpoints

### Post-Deployment
- [ ] Monitor error logs
- [ ] Check performance metrics
- [ ] Verify data accuracy
- [ ] Gather user feedback

---

## Success Criteria

### Functionality
- ✅ Dashboard displays all metrics
- ✅ Charts render correctly
- ✅ Date range filtering works
- ✅ Real-time updates functional

### Performance
- ✅ Dashboard loads < 2 seconds
- ✅ Charts render < 1 second
- ✅ API response < 500ms
- ✅ Cache hit rate > 80%

### Quality
- ✅ All unit tests passing
- ✅ All integration tests passing
- ✅ Code review approved
- ✅ Security review passed

---

## Troubleshooting

### Dashboard Not Loading
```bash
# Check API endpoint
curl http://localhost:46990/radiology/analytics/dashboard

# Check browser console for errors
# Check network tab for failed requests
# Verify authentication token
```

### Metrics Not Displaying
```bash
# Check database procedures
CALL sp_get_dashboard_metrics(1, '2026-03-01', '2026-03-11');

# Check data in radiology_requests table
SELECT COUNT(*) FROM radiology_requests;

# Verify date range
```

### Performance Issues
```bash
# Check query performance
EXPLAIN SELECT * FROM radiology_requests WHERE facility_id = 1;

# Check cache hit rate
# Monitor API response times
# Check database connection pool
```

---

## Next Steps

After Day 1 completion:
1. Review code and tests
2. Merge to main branch
3. Deploy to staging
4. Proceed to Day 2 - Productivity & Performance Metrics

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-11  
**Status**: Day 1 Ready for Implementation

---

## Quick Start

To begin Day 1 implementation:

1. Create analytics controller
2. Create analytics routes
3. Create analytics service
4. Create database procedures
5. Create dashboard component
6. Create supporting components
7. Add styling
8. Write unit tests
9. Integrate with app
10. Test all functionality

**Estimated Time**: 8 hours  
**Expected Completion**: End of Day 1

Good luck! 🚀
