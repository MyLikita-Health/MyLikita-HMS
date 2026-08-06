# MyLikita — Self-Contained Windows Offline Installer

> **End-user documentation:** give the client
> [`OFFLINE_INSTALLATION_GUIDE.md`](./OFFLINE_INSTALLATION_GUIDE.md) — a
> step-by-step, non-technical guide to installing and running MyLikita on
> their Windows server. For clients who want a printable tick-list, hand over
> [`DEPLOYMENT_CHECKLIST.md`](./DEPLOYMENT_CHECKLIST.md). For a condensed
> one-pager, print [`QUICK_START_CARD.html`](./QUICK_START_CARD.html) (browser
> → Print → PDF) or hand over [`QUICK_START_CARD.md`](./QUICK_START_CARD.md).
> This README is the developer's build/support doc.

Produces a **single `.exe`** the client downloads, double-clicks, and is done.
Everything is embedded in the installer: Node.js, MySQL, NSSM, the backend,
prebuilt `node_modules`, the built React frontend, and the database dump.
No internet is required on the client machine during or after install.

```
MyLikita-Setup-1.0.0.exe   ← the ONLY file the client needs
```

---

## What the installer does (zero user input)

1. Extracts to `C:\MyLikita\` (backend, frontend, runtimes, scripts).
2. **Silently installs MySQL** from the embedded ZIP build:
   `mysqld --initialize-insecure` → registers `MyLikitaMySQL` Windows service →
   starts it → sets a random root password → creates `mylikita_db`.
   - If another MySQL already occupies port 3306, it auto-picks 3307–3311
     and stores the choice in `.env` (`DB_PORT`).
3. Imports `prime-db.sql` into a fresh database (skipped if data already
   exists, so reinstalls never wipe patient data) and marks the baseline
   migration in `SequelizeMeta` (mirrors `backend/entrypoint.sh`). The dump
   is a MariaDB 10.4 export, so before importing it is sanitized for
   MySQL 8: the removed `NO_AUTO_CREATE_USER` sql_mode flag is stripped
   (would otherwise abort the import with error 1231) and the dump's own
   `CREATE DATABASE prime` / `USE prime` lines are dropped so everything
   lands in the configured database. The import runs with `--force` and a
   relaxed `sql_mode`/`FOREIGN_KEY_CHECKS=0` init command — the same
   approach `backend/entrypoint.sh` uses in production.
4. Runs pending Sequelize migrations after the import (mirrors the cloud
   `entrypoint.sh`), so offline schema always matches cloud schema — including
   the facility-onboarding columns. The seeded facility is then marked
   `deployment_type='offline'`, `onboarding_status='pending'`, which triggers
   the post-login first-run claim wizard (`/onboarding/claim`) on first login.
   On reinstall the claim is never reset (guarded UPDATE).
5. Writes `backend\.env` with auto-generated credentials (MySQL password,
   JWT secret). On reinstall it **reuses** the existing `.env`/database.
6. **Bakes the server's LAN IP** into the frontend bundle, so every staff
   browser on the network reaches the API correctly.
7. Registers the backend as an auto-start Windows service (**NSSM**) and
   opens the firewall port (46990).
8. Verifies the app answers on `http://localhost:46990/`, writes
   `C:\MyLikita\CREDENTIALS.txt`, and shows the access URL on the final page.

The whole flow is logged to `C:\MyLikita\logs\install.log` — send this file
to support if anything fails. `C:\MyLikita\scripts\reconfigure.cmd` re-runs
the configuration after a failure.

---

## Build prerequisites (your machine — Windows)

- Windows 10/11 x64
- **Inno Setup 6** → https://jrsoftware.org/isinfo.php (ISCC.exe, checked into PATH or installed to the default location)
- Internet access the first time (downloads Node/MySQL/NSSM into `dist\cache`, cached for later builds)
- Git (or just run the whole build from a checkout of this repo)

## Build

```cmd
deploy\windows-installer\build-installer.bat
```

Output: `deploy\windows-installer\dist\output\MyLikita-Setup-<version>.exe`

What the build does:

1. Downloads (cached): `node-v20.19.0-win-x64.zip` (20.19+ is required by the
   frontend's Vite 7 build), `mysql-8.0.42-winx64.zip`, `nssm-2.24.zip`.
2. Builds the frontend with `VITE_API_URL=http://__MYLIKITA_SERVER_IP__:46990`
   (a placeholder the installer replaces with the real LAN IP at install time;
   the existing `frontend/.env.production` is backed up and restored).
3. Copies the backend and runs `npm install --omit=dev` **with the embedded
   Node 20** so native modules (`bcrypt`, …) match the runtime that ships.
4. Compiles the installer with ISCC.

Version / runtime overrides (edit the top of `build-installer.bat`):

| Variable          | Default    | Notes                                   |
|-------------------|------------|-----------------------------------------|
| `VERSION`         | `1.0.0`    | App + output file version               |
| `NODE_VERSION`    | `v20.19.0` | Must match the Node used to build `node_modules` (Vite 7 needs ≥ 20.19) |
| `MYSQL_VERSION`   | `8.0.42`   | Keep in 8.0.x (backend expects `mysql_native_password`) |
| `NSSM_VERSION`    | `2.24`     |                                         |

> **Puppeteer note:** the build sets `PUPPETEER_SKIP_DOWNLOAD=1` and the
> installer writes `PUPPETEER_SKIP_DOWNLOAD=true` into `.env`, so no Chromium
> is bundled. If PDF features that depend on Puppeteer's bundled Chromium are
> needed offline, install Chrome/Edge on the client and set
> `PUPPETEER_EXECUTABLE_PATH` in `backend\.env`.

---

## Testing checklist (do this before shipping)

Test on a **clean Windows VM** (fresh OS, nothing installed):

1. Copy `MyLikita-Setup-1.0.0.exe` to the VM. Double-click → accept UAC.
2. Walk through the wizard. No configuration prompts should appear.
3. When it finishes: note the URL on the final page.
4. Verify `http://localhost:46990/` shows the MyLikita login page.
5. From a second machine on the same LAN, open `http://<SERVER_IP>:46990/`.
6. Log in, register a patient, create a bill — exercise DB writes.
7. **Reboot the VM.** Confirm (without logging in) the app is reachable again
   (`nssm status MyLikita` shows `SERVICE_RUNNING`).
8. Reinstall the same installer on top — confirm patient data is preserved.
9. Simulate a conflict: install a regular MySQL on 3306 first, then run the
   installer — it must pick a free port and still work.
10. Uninstall via Control Panel → confirm the `MyLikita` service is removed
    but the MySQL data stays (by design).

Common failure paths and their logs:

| Symptom                                      | Look at                                |
|----------------------------------------------|----------------------------------------|
| “Required file not found”                    | `logs\install.log` (which file)        |
| MySQL init fails                             | `logs\install.log` (mysqld output)     |
| “Database import failed”                     | `logs\install.log` (mysql errors — see the MySQL 8 sanitization note in step 3) |
| Login page loads but API errors              | `logs\out.log` / `err.log` (NSSM)      |
| Other PCs can't open the page                | Windows Firewall rule “MyLikita”, server IP |

---

## Layout after install

```
C:\MyLikita\
  backend\            ← app.js + node_modules + .env (generated)
  frontend\dist\      ← built React app (IP baked in)
  runtime\node\       ← embedded Node.js
  runtime\mysql\      ← embedded MySQL (ZIP build)
  runtime\nssm\       ← nssm.exe
  mysql-data\         ← MySQL data directory (my.ini + DB data)
  database\prime-db.sql
  scripts\            ← postinstall / reconfigure / update-ip / uninstall
  logs\install.log, out.log, err.log
  CREDENTIALS.txt     ← access URL + where credentials live
```

## Day-to-day ops

```cmd
nssm start MyLikita       :: start the app service
nssm stop MyLikita        :: stop it
nssm restart MyLikita     :: restart after an update
:: MySQL service: MyLikitaMySQL   (net start/stop MyLikitaMySQL)
```

If the server's IP changes after install, run
`C:\MyLikita\scripts\update-ip.cmd` (as Administrator) to re-bake the IP into
the frontend and restart the service.

## Building in CI (GitHub Actions)

A workflow at `.github/workflows/build-installer.yml` builds the installer on a
Windows runner whenever you push a version tag:

```bash
git tag v1.2.3
git push origin v1.2.3
```

The workflow:

1. Installs Inno Setup 6 on the runner.
2. Caches the Node/MySQL/NSSM downloads (`dist/cache`) between runs.
3. Runs `build-installer.bat` with the version taken from the tag
   (`v1.2.3` → `1.2.3`; the `MYLIKITA_VERSION` env var overrides the default
   `1.0.0` inside the script).
4. **Smoke-tests the installer**: a second job extracts the built `.exe`
   (7-Zip — preinstalled on the runner) and verifies the whole bundle is
   inside it — `backend/app.js` + `node_modules`, `frontend/dist` (including
   the server-IP placeholder), the Node/MySQL/NSSM runtimes, `prime-db.sql`,
   and `scripts/postinstall.cmd` — and that the `.exe` is over 100 MB.
5. **Install-tests the installer (final pre-ship check)**: a third job runs
   the `.exe` headlessly on a Windows Server VM (`windows-latest` runners are
   Windows Server 2022/2025 and run elevated) with
   `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-`. This exercises the real
   post-install path end to end: MySQL init from the embedded ZIP, the
   `prime-db.sql` import, `.env` writing, NSSM service registration, the
   firewall rule, and app startup. It fails closed on the `install.log`
   COMPLETED marker, the `MyLikitaMySQL` + `MyLikita` services being
   Running, and `http://localhost:46990/` returning the MyLikita login page.
   (The .exe exit code alone is not trusted — under `/VERYSILENT` the
   installer exits 0 even if the internal post-install script fails.) The
   install + backend logs are uploaded as a `install-diagnostics` artifact
   for debugging.
6. **Logs in end to end**: the same job then `POST /auth/login` with the
   seeded user `admin` / `123456` (the dump's bcrypt hash — verified to
   match that password) and asserts a 3-segment JWT comes back, then
   **verifies the JWT signature** with the `JWT_SECRET` from the installed
   `backend\.env` using the embedded Node + bundled `jsonwebtoken`. This
   proves the full stack — MySQL → Sequelize → bcrypt → JWT signing — not
   just static HTML.
7. **Reinstall test (phase 2)**: the same job then runs the installer a
   **second time** over the same VM to prove upgrades never lose data.
   Before the reinstall it writes a marker row (`reinstall_marker`) into the
   database and snapshots the table count. After the reinstall it asserts:
   the `install.log` shows the *skip import* message (the DB was NOT
   re-imported), the marker row still exists, the table count did not
   shrink, the seeded `admin` user still exists, both services are still
   Running, and `POST /auth/login` still returns a JWT. This is the real
   guarantee behind the “reinstalls preserve patient data” promise.
8. Only if all tests pass does it attach the `.exe` to the GitHub Release
   created for the tag — so a broken installer is never published.

> The build script is CI-safe: when `CI` is set (GitHub sets it automatically)
> the `pause` prompts are skipped so the job never hangs.

You can also trigger a manual build from the Actions tab (without a tag) — the
version then defaults to `0.0.0`.

### Nightly cache pre-warm

A second workflow at `.github/workflows/prewarm-cache.yml` runs nightly (and
on demand from the Actions tab) to keep the ~350 MB runtime cache warm on the
default branch. It reuses the **exact same cache key** as the release build
and runs `build-installer.bat` in **download-only mode**
(`MYLIKITA_DOWNLOAD_ONLY=1`), which fetches the Node/MySQL/NSSM ZIPs into
`dist\cache` and exits before extract/build — so it needs neither Inno Setup
nor a frontend build. Because a cache saved on the default branch can be
restored by any ref (including tag pushes), tagged releases start from a warm
cache and build in seconds instead of re-downloading 350 MB. If a runtime
version is bumped in `build-installer.bat`, the key's `hashFiles` component
changes, the nightly run misses, re-downloads, and re-warms automatically —
the release build can never silently restore a stale cache.

## Updating a client to a new version

Ship a new `MyLikita-Setup-x.y.z.exe`. The installer:
- keeps `backend\.env` and all MySQL data (`.env*` is excluded from the
  bundle, DB import is skipped when tables exist),
- removes/registers the NSSM service automatically.

So the update is the same double-click as a first install.

## Architecture recap

```
Browser (staff PC)  ──http──▶  C:\MyLikita backend (Node, port 46990)
                                   ├─ serves frontend/dist (React)
                                   └─ talks to local MySQL (3306/3307..)
```
