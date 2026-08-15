/**
 * seed-access.js — Phase 3E/5 offline installer helper
 *
 * Called by postinstall.cmd after migrations complete. Computes the
 * correct accessTo string for the seeded default admin based on the
 * facility's CURRENT type and assigned specialties, then applies the
 * LICENSE plan ceiling when a signed license file is present (Phase 5):
 * the license row's plan modules are intersected with the type modules.
 *
 * Usage:
 *   node seed-access.js <facilityId> [licenseFilePath]
 *
 * Output (stdout): the accessTo string (e.g. "Dashboard,Records,...")
 * Exit code 0 on success, 1 on failure.
 */

// On the installed server, this script lives in C:\MyLikita\scripts\
// and the config is at ..\backend\config\facilityTypes.js. During
// development it lives in deploy/windows-installer/scripts/ and the config
// is at ../../../../backend/config/facilityTypes.js — try both layouts.
const path = require('path');
const fs = require('fs');
function resolveFacilityTypes() {
  const candidates = [
    path.resolve(__dirname, '..', 'backend', 'config', 'facilityTypes.js'), // installed server (C:\MyLikita\scripts)
    path.resolve(__dirname, '..', '..', '..', 'backend', 'config', 'facilityTypes.js'), // source tree (dental/deploy/windows-installer/scripts)
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) return require(c);
  }
  throw new Error('Could not locate backend/config/facilityTypes.js');
}
const { getAccessToString, resolveEffectiveModules } = resolveFacilityTypes();

// mysql2 resolves on the installed server (bundled runtime) and in the
// source tree (backend/node_modules) — try the default resolution first,
// then the backend's own node_modules.
function resolveMysql2() {
  try {
    return require('mysql2/promise');
  } catch (_) {
    // Installed server (C:\MyLikita\scripts) needs ..\backend\node_modules;
    // the source tree (deploy/windows-installer/scripts) needs ..\..\..\backend
    // (i.e. backend/node_modules at the repo root). Try both layouts.
    const candidates = [
      path.resolve(__dirname, '..', 'backend', 'node_modules'),
      path.resolve(__dirname, '..', '..', '..', 'backend', 'node_modules'),
    ];
    for (const dir of candidates) {
      if (fs.existsSync(path.join(dir, 'mysql2'))) {
        const { createRequire } = require('module');
        const req = createRequire(path.join(dir, 'noop.js'));
        return req('mysql2/promise');
      }
    }
    throw new Error('Could not locate backend/node_modules (mysql2)');
  }
}
const mysql = resolveMysql2();

const facilityId = process.argv[2] || '1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a';
const licenseFileArg = process.argv[3];

(async () => {
  // Read .env for DB credentials (installed-server layout, then source tree)
  const envCandidates = [
    path.resolve(__dirname, '..', 'backend', '.env'), // installed server (C:\MyLikita\scripts → C:\MyLikita\backend\.env)
    path.resolve(__dirname, '..', '..', '..', 'backend', '.env'), // source tree
  ];
  const envPath = envCandidates.find((c) => fs.existsSync(c)) || envCandidates[0];
  const env = {};
  if (fs.existsSync(envPath)) {
    fs.readFileSync(envPath, 'utf8').split(/\r?\n/).forEach((line) => {
      const m = line.match(/^\s*([A-Za-z0-9_]+)=(.*)$/);
      if (m) env[m[1]] = m[2].trim();
    });
  }

  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || env.DB_PORT || '3306', 10),
    user: process.env.DB_USER || env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || env.DB_PASSWORD || '',
    database: process.env.DB_NAME || env.DB_NAME || 'mylikita_db',
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

    // 3. Phase 5: apply the license plan ceiling when a signed license file
    //    is present (default: backend/data/license.json — the reinstall-
    //    preserved copy). The license payload is verified with the embedded
    //    PUBLIC key (no internet needed) and its plan's modules are
    //    intersected with the type modules, mirroring applyPlanCeiling.
    // Dual-layout license file: installed server (C:\MyLikita\backend\data\license.json)
    // vs source tree (dental/backend/data/license.json).
    const licensePath = licenseFileArg || [
      path.resolve(__dirname, '..', 'backend', 'data', 'license.json'),
      path.resolve(__dirname, '..', '..', '..', 'backend', 'data', 'license.json'),
    ].find((p) => fs.existsSync(p)) || path.resolve(__dirname, '..', '..', '..', 'backend', 'data', 'license.json');
    let licensedModules = null;
    if (fs.existsSync(licensePath)) {
      try {
        const crypto = require('crypto');
        const licensePayload = JSON.parse(fs.readFileSync(licensePath, 'utf8'));
        // NEVER trust plan_id from an unsigned file — verify with the shipped
        // public key first (mirrors licenseService.canonicalPayload exactly).
        if (licensePayload && licensePayload.signature && licensePayload.plan_id) {
          const { signature, ...rest } = licensePayload;
          const canonical = JSON.stringify(Object.keys(rest).sort().reduce((acc, k) => {
            acc[k] = rest[k];
            return acc;
          }, {}));
          const publicKeyCandidates = [
            path.resolve(__dirname, '..', 'backend', 'config', 'license-public.pem'),
            path.resolve(__dirname, '..', '..', '..', 'backend', 'config', 'license-public.pem'),
          ];
          const pubPath = publicKeyCandidates.find((p) => fs.existsSync(p));
          if (!pubPath) {
            console.error('seed-access: shipped public key not found — skipping license ceiling (full type modules).');
          } else {
            const verifier = crypto.createVerify('RSA-SHA256');
            verifier.update(canonical);
            verifier.end();
            const ok = verifier.verify(fs.readFileSync(pubPath, 'utf8'), signature, 'base64');
            if (!ok) {
              console.error('seed-access: license signature INVALID — ignoring license ceiling (full type modules).');
            } else {
              const [planRows] = await conn.execute(
                'SELECT features FROM subscription_plans WHERE id = ? LIMIT 1',
                [licensePayload.plan_id]
              );
              if (planRows.length && planRows[0].features) {
                const features = typeof planRows[0].features === 'string'
                  ? JSON.parse(planRows[0].features)
                  : planRows[0].features;
                if (Array.isArray(features && features.modules) && features.modules.length) {
                  licensedModules = features.modules;
                }
              }
            }
          }
        }
      } catch (licenseErr) {
        console.error('seed-access: license file present but unreadable — applying type modules only:', licenseErr.message);
      }
    }

    if (licensedModules) {
      const typeSet = new Set(accessTo.split(','));
      const keep = new Set(['Dashboard', 'Admin']); // locked facility stays usable
      for (const m of typeSet) {
        if (licensedModules.includes(m) || keep.has(m)) keep.add(m);
      }
      accessTo = [...keep].join(',');
      console.error(`Applied license plan ceiling — ${accessTo.split(',').length} modules.`);
    } else {
      console.error('No license file found — using full type module set (fresh install / trial).');
    }

    // 4. Update all admin users in this facility
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
