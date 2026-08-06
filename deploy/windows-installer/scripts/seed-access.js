/**
 * seed-access.js — Phase 3E offline installer helper
 *
 * Called by postinstall.cmd after migrations complete. Computes the
 * correct accessTo string for the seeded default admin based on the
 * facility's CURRENT type and assigned specialties.
 *
 * Usage:
 *   node seed-access.js <facilityId>
 *
 * Output (stdout): the accessTo string (e.g. "Dashboard,Records,...")
 * Exit code 0 on success, 1 on failure.
 */

// On the installed server, this script lives in C:\MyLikita\scripts\
// and the config is at ..\backend\config\facilityTypes.js
const { getAccessToString, resolveEffectiveModules } = require('../backend/config/facilityTypes');

// During development, this script lives in deploy/windows-installer/scripts/
// and the config is at ../../../../backend/config/facilityTypes.js.
// The relative path above works on the installed server; if running from the
// source tree, override by calling from the repo root:
//   node deploy/windows-installer/scripts/seed-access.js
const mysql = require('mysql2/promise');

const facilityId = process.argv[2] || '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a';

(async () => {
  // Read .env for DB credentials
  const path = require('path');
  const fs = require('fs');
  const envPath = path.resolve(__dirname, '..', '..', 'backend', '.env');
  const env = {};
  if (fs.existsSync(envPath)) {
    fs.readFileSync(envPath, 'utf8').split(/\r?\n/).forEach((line) => {
      const m = line.match(/^\s*([A-Za-z0-9_]+)=(.*)$/);
      if (m) env[m[1]] = m[2].trim();
    });
  }

  const conn = await mysql.createConnection({
    host: env.DB_HOST || 'localhost',
    port: parseInt(env.DB_PORT || '3306', 10),
    user: env.DB_USER || 'root',
    password: env.DB_PASSWORD || '',
    database: env.DB_NAME || 'mylikita_db',
  });

  try {
    // 1. Get facility type
    const [rows] = await conn.execute(
      'SELECT type FROM hospitals WHERE id = ? LIMIT 1',
      [facilityId]
    );
    if (!rows.length) {
      console.error('Facility not found:', facilityId);
      process.exit(1);
    }
    const facilityType = rows[0].type || 'hospital';

    let accessTo = '';

    // 2. If hospital or clinic, resolve specialties → modules
    if (facilityType === 'hospital' || facilityType === 'clinic') {
      const [specRows] = await conn.execute(
        `SELECT s.slug FROM hospital_specialties hs
         JOIN specialties s ON s.id = hs.specialty_id
         WHERE hs.facility_id = ?`,
        [facilityId]
      );
      const slugs = specRows.map((r) => r.slug);
      accessTo = resolveEffectiveModules(facilityType, slugs).join(',');
    } else {
      // Static types: use the registry directly
      accessTo = getAccessToString(facilityType, []);
    }

    if (!accessTo) {
      console.error('Could not resolve modules for type:', facilityType);
      process.exit(1);
    }

    // 3. Update all admin users in this facility
    const [result] = await conn.execute(
      `UPDATE users SET accessTo = ?, updatedAt = NOW()
       WHERE facilityId = ?
         AND (role IN ('admin','Administrator','super_admin') OR privilege >= 4)`,
      [accessTo, facilityId]
    );

    console.error(`Updated ${result.affectedRows} admin(s) with ${accessTo.split(',').length} modules: ${accessTo}`);
    console.log(accessTo);
    process.exit(0);
  } finally {
    await conn.end();
  }
})().catch((err) => {
  console.error('seed-access error:', err.message);
  process.exit(1);
});
