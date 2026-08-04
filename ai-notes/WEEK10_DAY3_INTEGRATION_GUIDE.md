# Week 10 Day 3 - Equipment Tracking Integration Guide

## Quick Start

### 1. Database Setup

Run the equipment procedures:
```bash
mysql -u root prime < backend/sql/radiology_equipment_procedures.sql
```

### 2. Backend Integration

Equipment routes are already registered in `backend/app.js`:
```javascript
app.use('/radiology', require('./routes/radiology-equipment'))
```

### 3. Frontend Integration

Add the EquipmentReport component to your analytics dashboard:

```jsx
import EquipmentReport from './components/radiology/analytics/EquipmentReport';

// In your dashboard component
<EquipmentReport />
```

## API Usage Examples

### Get Equipment Utilization
```bash
curl -X GET "http://localhost:46990/radiology/equipment/utilization/1?startDate=2026-02-09&endDate=2026-03-11" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Get Downtime Analysis
```bash
curl -X GET "http://localhost:46990/radiology/equipment/downtime/1?startDate=2026-02-09&endDate=2026-03-11" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Get Maintenance Schedule
```bash
curl -X GET "http://localhost:46990/radiology/equipment/maintenance/1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Create Maintenance Record
```bash
curl -X POST "http://localhost:46990/radiology/equipment/maintenance" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "equipment_id": 1,
    "maintenance_type": "preventive",
    "scheduled_date": "2026-03-15",
    "description": "Regular maintenance",
    "technician_name": "John Doe"
  }'
```

### Get Equipment Performance
```bash
curl -X GET "http://localhost:46990/radiology/equipment/performance/1?startDate=2026-02-09&endDate=2026-03-11" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Get Facility Equipment Report
```bash
curl -X GET "http://localhost:46990/radiology/equipment/facility-report/1?startDate=2026-02-09&endDate=2026-03-11" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Frontend Component Usage

### Basic Usage
```jsx
import EquipmentReport from './components/radiology/analytics/EquipmentReport';

function AnalyticsDashboard() {
  return (
    <div>
      <EquipmentReport />
    </div>
  );
}
```

### With Custom Date Range
The component includes built-in date range filtering. Users can:
1. Select start and end dates
2. Click "Apply" to refresh data
3. View equipment details for selected equipment

## Component Features

### Equipment List
- Shows all facility equipment
- Displays equipment name, type, and status
- Shows completion rate badge
- Click to select and view details

### Equipment Details
- Utilization metrics (studies, completion rate, turnaround time)
- Performance indicators (uptime, failed studies, downtime)
- Downtime analysis (events, hours, average duration)
- Maintenance history table

### Responsive Design
- Desktop: 2-column layout (list + details)
- Tablet: Stacked layout
- Mobile: Full-width with collapsible sections

## Database Tables Required

Ensure these tables exist:
- `radiology_equipment` - Equipment master data
- `radiology_appointments` - Appointment records
- `equipment_maintenance` - Maintenance records

## Troubleshooting

### No Equipment Data
- Check if equipment records exist in `radiology_equipment` table
- Verify facility_id matches in query

### Maintenance History Empty
- Ensure maintenance records exist in `equipment_maintenance` table
- Check date range includes maintenance records

### Performance Issues
- Verify stored procedures are created
- Check database indexes on equipment_id, facility_id
- Monitor query execution time

## Performance Optimization

### Caching Strategy
- Cache equipment list (5 minutes)
- Cache utilization metrics (10 minutes)
- Cache performance data (15 minutes)

### Query Optimization
- Use date range filtering to limit results
- Leverage stored procedures for complex queries
- Index on equipment_id, facility_id, dates

## Security

### Authentication
- All endpoints require authentication
- Use Bearer token in Authorization header

### Authorization
- Verify user has radiology module access
- Check facility_id matches user's facility

## Next Steps

1. Test all API endpoints
2. Verify database procedures work correctly
3. Test frontend component with sample data
4. Integrate with analytics dashboard
5. Deploy to staging environment

## Support

For issues or questions:
1. Check error messages in browser console
2. Review API response in Network tab
3. Check backend logs for server errors
4. Verify database connectivity

---

**Status**: ✅ READY FOR INTEGRATION  
**Last Updated**: March 11, 2026
