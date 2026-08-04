# 🚨 URGENT: Run Database Migration

## Error Encountered

You're getting this error because the database tables haven't been created yet:
```
Unknown column 'description' in 'field list'
```

## Quick Fix (Choose One Method)

### Method 1: Using MySQL Command Line (Recommended)

1. Open Terminal
2. Navigate to the backend directory:
   ```bash
   cd backend
   ```

3. Run the migration:
   ```bash
   mysql -u root -p prime < sql/treatment_plans_with_billing.sql
   ```
   
4. When prompted, enter your MySQL password (if you have one, otherwise just press Enter)

### Method 2: Using MySQL Workbench or phpMyAdmin

1. Open MySQL Workbench or phpMyAdmin
2. Connect to your database
3. Select the `prime` database
4. Go to SQL tab
5. Copy and paste the entire contents of `backend/sql/treatment_plans_with_billing.sql`
6. Execute the SQL

### Method 3: Using Sequel Pro (Mac)

1. Open Sequel Pro
2. Connect to localhost
3. Select `prime` database
4. Click "Query" tab
5. Copy and paste the entire contents of `backend/sql/treatment_plans_with_billing.sql`
6. Click "Run All"

## Verify Migration Success

After running the migration, verify the tables were created:

```sql
SHOW TABLES LIKE 'dental_treatment%';
```

You should see 5 tables:
- dental_treatment_plans
- dental_treatment_plan_phases
- dental_treatment_plan_procedures
- dental_treatment_payment_schedule
- dental_treatment_payments

## Then Test Again

1. Restart your backend server (if it's running)
2. Go back to the Treatment Plans tab
3. Try creating a treatment plan again

## Alternative: Direct SQL Commands

If you can't run the SQL file, you can copy the SQL commands directly from `backend/sql/treatment_plans_with_billing.sql` and paste them into your MySQL client.

---

**The migration MUST be run before the Treatment Plans feature will work!**
