# Database Migration Guide - Treatment Plans

## 🚨 Issue

You encountered this error:
```
Unknown column 'description' in 'field list'
```

This means the database tables for Treatment Plans haven't been created yet.

---

## ✅ Solution: Run the Migration

Choose the method that works best for you:

---

## Method 1: Automated Node.js Script (Easiest) ⭐

This is the easiest and safest method.

### Steps:

1. Open Terminal and navigate to backend:
   ```bash
   cd backend
   ```

2. Run the migration script:
   ```bash
   node sql/run_treatment_plans_migration.js
   ```

3. You should see:
   ```
   🚀 Starting Treatment Plans Database Migration...
   📡 Connecting to database...
   ✅ Connected to database: prime
   📄 Reading SQL file...
   ⚙️  Executing migration...
   ✅ Migration executed successfully!
   🔍 Verifying tables...
   ✅ Tables created:
      ✓ dental_treatment_plans
      ✓ dental_treatment_plan_phases
      ✓ dental_treatment_plan_procedures
      ✓ dental_treatment_payment_schedule
      ✓ dental_treatment_payments
   🎉 Migration completed successfully!
   ```

4. Restart your backend server:
   ```bash
   # Stop the current server (Ctrl+C)
   # Then start it again
   npm start
   ```

5. Try creating a treatment plan again!

---

## Method 2: MySQL Command Line

If you prefer using MySQL directly:

### Steps:

1. Open Terminal

2. Navigate to backend directory:
   ```bash
   cd backend
   ```

3. Run the migration:
   ```bash
   mysql -u root -p prime < sql/treatment_plans_with_billing.sql
   ```
   
   If you have a password, enter it when prompted. If not, just press Enter.

4. Verify tables were created:
   ```bash
   mysql -u root -p prime -e "SHOW TABLES LIKE 'dental_treatment%';"
   ```

---

## Method 3: MySQL Workbench (GUI)

If you prefer a graphical interface:

### Steps:

1. Open MySQL Workbench
2. Connect to your local MySQL server
3. Select the `prime` database from the left sidebar
4. Click on "SQL Editor" or press Ctrl+T (Cmd+T on Mac)
5. Open the file: `backend/sql/treatment_plans_with_billing.sql`
   - Or copy and paste its contents
6. Click the lightning bolt icon (⚡) to execute
7. Check the output panel for success messages

---

## Method 4: phpMyAdmin (Web Interface)

If you're using phpMyAdmin:

### Steps:

1. Open phpMyAdmin in your browser (usually http://localhost/phpmyadmin)
2. Click on `prime` database in the left sidebar
3. Click on the "SQL" tab at the top
4. Copy the entire contents of `backend/sql/treatment_plans_with_billing.sql`
5. Paste into the SQL text area
6. Click "Go" button at the bottom
7. You should see success messages

---

## Method 5: Sequel Pro (Mac Only)

If you're using Sequel Pro:

### Steps:

1. Open Sequel Pro
2. Connect to localhost (127.0.0.1)
3. Select `prime` database
4. Click "Query" tab
5. Copy contents of `backend/sql/treatment_plans_with_billing.sql`
6. Paste into the query window
7. Click "Run All" button
8. Check for success messages

---

## Verification

After running the migration, verify it worked:

### Check Tables Exist:

```sql
SHOW TABLES LIKE 'dental_treatment%';
```

You should see 5 tables:
```
dental_treatment_plans
dental_treatment_plan_phases
dental_treatment_plan_procedures
dental_treatment_payment_schedule
dental_treatment_payments
```

### Check Table Structure:

```sql
DESCRIBE dental_treatment_plans;
```

You should see columns including:
- id
- plan_id
- patient_id
- facilityId
- plan_name
- description ← This is the column that was missing!
- status
- priority
- total_cost
- deposit_required
- ... and more

---

## After Migration

1. **Restart Backend Server**:
   ```bash
   # Stop current server (Ctrl+C or Cmd+C)
   cd backend
   npm start
   ```

2. **Test the Feature**:
   - Go to Dental Module
   - Select a patient
   - Click "Treatment Plans" tab
   - Click "Create New Plan"
   - Fill in the form
   - Add phases and procedures
   - Click "Create Treatment Plan"

3. **It Should Work Now!** ✅

---

## Troubleshooting

### Error: "Access denied for user"
**Solution**: Check your MySQL username and password in `backend/config/config.json`

### Error: "Unknown database 'prime'"
**Solution**: Create the database first:
```sql
CREATE DATABASE prime;
```

### Error: "Can't connect to MySQL server"
**Solution**: Make sure MySQL is running:
```bash
# Mac (if using Homebrew)
brew services start mysql

# Or check if it's running
ps aux | grep mysql
```

### Error: "Table already exists"
**Solution**: This is fine! The migration uses `CREATE TABLE IF NOT EXISTS`, so it won't overwrite existing tables. But if you're still getting the "Unknown column" error, the table might have been created with an old schema. You can:

1. Drop the tables and recreate:
   ```sql
   DROP TABLE IF EXISTS dental_treatment_payments;
   DROP TABLE IF EXISTS dental_treatment_payment_schedule;
   DROP TABLE IF EXISTS dental_treatment_plan_procedures;
   DROP TABLE IF EXISTS dental_treatment_plan_phases;
   DROP TABLE IF EXISTS dental_treatment_plans;
   ```
   Then run the migration again.

2. Or add the missing column manually:
   ```sql
   ALTER TABLE dental_treatment_plans 
   ADD COLUMN description TEXT AFTER plan_name;
   ```

---

## What the Migration Creates

### 5 Tables:

1. **dental_treatment_plans** - Main treatment plan records
   - Stores plan details, costs, payment info
   - Tracks deposit and payment status

2. **dental_treatment_plan_phases** - Treatment phases
   - Breaks treatment into manageable phases
   - Each phase has its own cost and payment requirements

3. **dental_treatment_plan_procedures** - Procedures per phase
   - Individual procedures within each phase
   - Links to service definitions for pricing

4. **dental_treatment_payment_schedule** - Installment tracking
   - Manages monthly installment payments
   - Tracks due dates and payment status

5. **dental_treatment_payments** - Payment history
   - Complete record of all payments
   - Links to transaction IDs

### Indexes for Performance:
- Fast lookups by patient, facility, status
- Optimized queries for payment schedules
- Efficient phase and procedure searches

---

## Need More Help?

If you're still having issues:

1. Check the backend console for detailed error messages
2. Verify MySQL is running: `mysql --version`
3. Check database connection in `backend/config/config.json`
4. Make sure you have permission to create tables
5. Try the automated Node.js script (Method 1) - it provides detailed error messages

---

## Summary

**Quick Command** (if you have MySQL command line):
```bash
cd backend
node sql/run_treatment_plans_migration.js
```

That's it! The migration will create all necessary tables and you'll be ready to use the Treatment Plans feature.

---

**Last Updated**: March 5, 2026
**Status**: Ready to run
**Estimated Time**: < 1 minute
