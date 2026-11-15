# MediLinka frontend — code deployment (build · artifact · headers · API proxy)

The companion to [`medilinka-subdomain-checklist.md`](./medilinka-subdomain-checklist.md).
That document puts the **hostname** in front of the app (DNS, Apache, TLS); this one
ships the **build** behind it and covers the four things that silently break a
MediLinka deploy:

1. the build-time environment variables,
2. the artifact and the order it is uploaded in,
3. the cache headers, and
4. the API proxy (or `VITE_API_URL`) that makes the app actually talk to the
   backend from the new origin.

---

## 0. The one thing to understand first

MediLinka is **not** a separate frontend. Both hostnames serve the same `dist/`,
and the SPA decides which product it is at runtime from `window.location.hostname`
(`frontend/src/utils/appSurface.js`):

| Hostname | Surface |
|---|---|
| `medilinka.mylikita.com` | MediLinka — telemedicine + patient portal |
| `app.mylikita.com` | HMS — hospital management system |
| anything else (hospital server, IP, staging host) | HMS, unless listed in `VITE_MEDILINKA_HOSTS` |

Consequences:

- **Deploying MediLinka deploys the HMS build too.** There are not two artifacts
  and there is no MediLinka-only bundle; the same files in `/var/www/app.mylikita.com`
  must be live on both hosts, or the two products drift.
- `/me` routes are served on **both** surfaces by design (a doctor who signs in
  on either host must reach their workspace). The hostname changes the front
  door, the branding and the public routes — not the access rules. API role and
  tenant checks remain the gate.
- Sessions are per origin. A staff member signed in on `app.mylikita.com` is not
  signed in on `medilinka.mylikita.com`. That is intended; do not "fix" it by
  sharing cookies.

---

## 1. Build environment variables

Only these `VITE_*` variables are read by the app (grep `VITE_` in `frontend/src`):

| Variable | Default when unset | Set it when | Notes |
|---|---|---|---|
| `VITE_API_URL` | `window.location.origin`, then `http://localhost:46990` | **layout B** (Apache serves `dist/`), or any deploy where the API is on another origin | Baked into the bundle. Must be the API origin **as-is** — see §4 |
| `VITE_MEDILINKA_HOSTS` | `medilinka.mylikita.com` | staging/preview hosts that should render MediLinka | Comma separated, exact hostnames, lowercase |
| `VITE_HMS_URL` | `https://app.mylikita.com` | the HMS is on another hostname | Target of "Hospital management system" and cross-surface redirects |
| `VITE_MEDILINKA_URL` | `https://medilinka.mylikita.com` | same | Target when the HMS host is asked for `/signup/doctor`, `/signup/patient` |
| `VITE_PATIENT_PORTAL_HOSTS` | flagship `app.mylikita.com` | extra hosts that should expose the patient portal | The MediLinka surface always exposes it, regardless of this list |
| `VITE_SOCKET_PATH` | `/socket.io` | almost never | In production the backend pins `/socket.io`; do not diverge |
| `VITE_OFFLINE` | unset | offline/on-premise installs | `true` forces same-origin API even if `VITE_API_URL` is set |
| `VITE_APP_SURFACE` | unset | **local dev only** | Honoured only when `import.meta.env.DEV` is true. Setting it in a production build does nothing — the hostname decides |

All `VITE_*` values are compiled into the public bundle. **Never put a secret,
token or key in one.**

Example production command (layout B, API on another origin):

```bash
cd frontend
npm install --legacy-peer-deps
VITE_API_URL=https://server.mylikita.com/prime \
VITE_HMS_URL=https://app.mylikita.com \
VITE_MEDILINKA_URL=https://medilinka.mylikita.com \
npm run build
```

`npm install --legacy-peer-deps` is required: plain `npm install` fails on the
`ckeditor4-react` peer range. The repo Dockerfile does exactly this.

**Node version:** Vite 7.3.3 declares `engines: ^20.19.0 || >=22.12.0`. The
Dockerfile pins `node:21-alpine`; a host build must be on 20.19+, 21 or 22.12+.

**Do not** set `NODE_ENV=production` by hand for the build; Vite derives
prod/dev from `vite build` vs `vite dev`, and `import.meta.env.PROD` drives the
service-worker registration in `src/registerServiceWorker.js`.

---

## 2. Artifact

`npm run build` writes `frontend/dist/`:

```
dist/
  index.html                 # shell (has the MediLinka pre-paint script)
  assets/                    # content-hashed JS/CSS/fonts — safe to cache forever
  sw.js                      # service worker, manifest injected per build
  version.json               # { "build": "<id>", "ts": "..." } — drives UpdateBanner
  manifest.json              # HMS PWA manifest
  manifest.medilinka.json    # MediLinka PWA manifest (swapped by index.html)
  icons/                     # favicons + the blue and teal marks
  icon512_rounded.png, icon512_rounded_teal.png, icon512_maskable*.png
  BrowserPrint-*.min.js      # Zebra printing (HMS)
  _redirects                 # Netlify-style SPA fallback; harmless on Apache
  vite.svg
```

Upload rules:

- Upload **`assets/` first**, then `index.html`, `sw.js` and `version.json`.
  A client that has fetched the new `index.html` before the new hashed assets
  exist gets 404s and a blank screen.
- `version.json` and `sw.js` must come from the **same** build as `index.html`.
  The build id in `version.json` is the only way to tell two artifacts apart —
  record it in the release note.
- Never upload `node_modules/`, `src/`, `.env*`, source maps or `cypress/`.
- The deploy target is `/var/www/app.mylikita.com`. The same directory is what
  `medilinka.mylikita.com` will point at — deploy once, both hosts pick it up.

Container alternative: `frontend/Dockerfile` builds and serves the same `dist/`
with nginx and an SPA fallback. It does **not** accept build args, so for a
layout-B deploy with `VITE_API_URL` build on the host (or add the arg) rather
than relying on the image. If you want a container on this Apache VPS, run the
container on an internal port and proxy it from Apache — the same as layout A.

---

## 3. Cache headers

The shell is versioned by the service worker and by `/version.json`, so the
split between "cache forever" and "never cache" is load-bearing.

| Path | Header | Why |
|---|---|---|
| `/assets/*` | `Cache-Control: public, immutable, max-age=31536000` | Filenames carry a content hash |
| `/` and `/index.html` | `Cache-Control: no-cache` | Must revalidate so a new deploy is picked up |
| `/sw.js` | `Cache-Control: no-cache` | The worker itself must never be served stale, and it must be at the **root** scope |
| `/version.json` | `Cache-Control: no-cache` | `UpdateBanner` polls it to offer the one-click reload |
| `/manifest.json`, `/manifest.medilinka.json` | `Cache-Control: no-cache` | The hostname swap happens in `index.html`; a cached manifest keeps the old branding |
| `/brand/*`, `icon512_*.png` | `Cache-Control: public, max-age=86400` | Stable names, occasionally-redrawn assets (never `/icons/*`: Apache aliases it) |

Apache (layout B) — add inside the `<VirtualHost>` block for the shell files:

```apache
# Hashed build output — cache forever.
<LocationMatch "^/assets/">
    Header set Cache-Control "public, immutable, max-age=31536000"
    Header unset ETag
</LocationMatch>

# Shell documents — always revalidate.
<LocationMatch "^/(index\.html|sw\.js|version\.json|manifest\.json|manifest\.medilinka\.json)$">
    Header set Cache-Control "no-cache"
</LocationMatch>

# Icons — short cache (names are stable but content can change).
<LocationMatch "^/(icons/|icon512_)">
    Header set Cache-Control "public, max-age=86400"
</LocationMatch>
```

Requires `mod_headers` (`sudo a2enmod headers`). If `app.mylikita.com` already
sets these headers, copy the block verbatim — a mismatched pair is how one host
ends up stuck on an old build while the other updates.

---

## 4. The API proxy (layout B) — read this before copying the Apache sample

`resolveApiBase()` (`src/utils/apiBase.js`) resolves the API origin in this
order: `VITE_API_URL` → `window.location.origin` → `http://localhost:46990`.
With no `VITE_API_URL`, a static-hosted build calls **its own origin**.

That is the trap: the staff API is mounted at **root** paths, not under `/api`:

- root-mounted: `/auth/*`, `/onboarding/*`, `/facility/*`, `/plans`, `/socket.io/`, `/uploads/*`
- under `/api`: the patient/portal tree (`/api/users/*`, `/api/patient/*`, …)

The sample `medilinka.mylikita.com` vhost in the subdomain checklist
proxies only `/api/` and `/socket.io/`. Copied as-is onto a static build, the
page returns `200`, the MediLinka landing renders, and **every sign-in returns
404** — because `/auth/login` is asked of the static Apache host.

Two correct options:

**Option A (recommended) — bake the API origin.** Build with `VITE_API_URL` set
to the backend origin the `app` host uses, and let Apache serve files only:

```apache
<VirtualHost *:80>
    ServerName medilinka.mylikita.com

    DocumentRoot /var/www/app.mylikita.com

    <Directory /var/www/app.mylikita.com>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
        FallbackResource /index.html
    </Directory>

    <LocationMatch "^/assets/">
        Header set Cache-Control "public, immutable, max-age=31536000"
        Header unset ETag
    </LocationMatch>
    <LocationMatch "^/(index\.html|sw\.js|version\.json|manifest\.json|manifest\.medilinka\.json)$">
        Header set Cache-Control "no-cache"
    </LocationMatch>

    ErrorLog  ${APACHE_LOG_DIR}/medilinka-error.log
    CustomLog ${APACHE_LOG_DIR}/medilinka-access.log combined
</VirtualHost>
```

No `/api` or `/socket.io` proxy is needed: the bundle calls `VITE_API_URL`
directly, including the WebSocket (`io(API_BASE_URL)`). The backend already
allows `*.mylikita.com` origins in `backend/app.js` (`ALLOWED_ORIGINS`), so no
CORS change is needed for the subdomain. A different domain (e.g.
`medilinka.example.org`) must be added there, or the browser blocks every call.

**Server-issued patient links.** The backend chooses the link origin per
facility (`backend/services/patientLinkOrigin.js`): a telemedicine practice's
letters and appointment confirmations use `MEDILINKA_URL` (default
`https://medilinka.mylikita.com`), everything else uses `APP_URL`; setting
`LETTER_APP_URL` pins every patient link to one origin and skips that lookup.
Two public routes therefore have to answer on the MediLinka host —
`/api/patient/letters/:token` and `/appointments/public/confirm/:token`. Option
A above proxies neither, so either add the `/api/` proxy location from the
subdomain checklist to this block, or set `MEDILINKA_URL` to the API origin
instead.

**Point `VITE_API_URL` at the origin as-is.** Do not add a path rewrite and do
not strip `/api`: the backend serves staff routes at the root **and** the
patient routes under `/api`, so any rewriting breaks one of the two. If the API
really is mounted under a prefix (the cloud deployment uses
`https://server.mylikita.com/prime`), use that full prefix — requests are
`${VITE_API_URL}/auth/login` and `${VITE_API_URL}/api/patient/...`.

**Option B — same-origin.** Keep `VITE_API_URL` unset and proxy, from the
MediLinka vhost, **every** location the `app` vhost proxies — root `/auth/`,
`/onboarding/`, `/facility/`, `/plans`, plus `/api/`, `/socket.io/`, `/uploads/`
with the WebSocket `RewriteRule`. Copy the block rather than retyping it; a
missed prefix is the 404 above.

Either way, confirm afterwards:

```bash
# 1. Which API origin did the build bake in? Run on the server.
#    Empty output means "same-origin" (option B) is in effect.
grep -rhoE 'https://[a-z0-9.-]*mylikita\.[a-z]+(/prime)?' /var/www/app.mylikita.com/assets/*.js | sort -u | head

# 2. The app can reach that API from the new origin. 400/401 are fine — the
#    point is that it is neither a 404 (wrong base) nor a CORS failure.
API=https://server.mylikita.com/prime          # <-- your baked-in value
curl -s -o /dev/null -w 'api=%{http_code}\n' -X POST \
  -H 'Content-Type: application/json' -d '{}' "$API/auth/login"
curl -s -o /dev/null -w 'preflight=%{http_code}\n' -X OPTIONS \
  -H 'Origin: https://medilinka.mylikita.com' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type' "$API/auth/login"
```

Under option B (same-origin) the check moves to the MediLinka host itself:
`POST https://medilinka.mylikita.com/auth/login` must return 400/401, **not** the
static-file 404 that means the proxy is missing a root path.

---

## 5. Host-scoped behaviours to know

- `frontend/index.html` runs a pre-paint script that matches **exactly**
  `medilinka.mylikita.com` to swap the title, PWA manifest, theme colour and the
  teal icons. A staging host listed in `VITE_MEDILINKA_HOSTS` renders the
  MediLinka SPA but keeps the MyLikita tab, icon and install prompt. Accept it
  for staging, or extend that condition when a second permanent hostname exists.
- The service worker is per origin, so the HMS worker on `app.mylikita.com`
  cannot serve the MediLinka host. Nothing to clear after cutover.
- The telemedicine practice shell (teal navbar, "Practice"/"Settings") is chosen
  from `plan.facilityType`, not from the hostname. A hospital doctor signing in
  on MediLinka still gets the hospital shell — by design, see §0.

---

## 6. Verification (beyond the subdomain checklist §7)

The automated half of this section is packaged as
[`medilinka-go-live-check.sh`](./medilinka-go-live-check.sh): point it at the
deployed host (`HOST=… API=… ./medilinka-go-live-check.sh`) and it runs the curl
checks below, prints pass/fail per check, and then prints the manual doctor and
patient walkthrough. It exits non-zero on any failed check.

1. `https://medilinka.mylikita.com/` shows the MediLinka landing (teal, Patient
   and Doctor tabs) — not the HMS login.
2. `https://app.mylikita.com/` is unchanged, and `/version.json` on both hosts
   reports the **same** build id.
3. Doctor tab → sign in → `/me/telemedicine` loads its Today panel (proves the
   API base and CORS).
4. Hard-refresh on `/me/telemedicine` keeps you there (proves the SPA fallback).
5. Patient portal `/patient` loads and a booking reaches the doctor's Visits tab.
6. DevTools → Application → Manifest says **MediLinka**; Console shows no CORS,
   mixed-content or 404 on `/socket.io/`.
7. `curl -sI .../sw.js` is `no-cache` and `curl -sI .../assets/<file>` is
   `immutable`.

---

## 7. Rollback

- **Code:** redeploy the previous `dist/` (identified by its `version.json`
  build id) — assets first, then the shell. The service worker picks the older
  cache name on next load; users get the `UpdateBanner` instead of a blank page.
- **Host:** if the surface itself is wrong, point the hostname back at the HMS
  with a `302` as described in the subdomain checklist §8. The certificate and
  DNS record can stay.
- Keep at least the last two artifacts on disk; a rollback should be a file swap,
  not a rebuild.

---

## 8. Done criteria

- [ ] `VITE_API_URL` (or the copied proxy) verified from the new origin
- [ ] Same build id on both hosts
- [ ] `assets/` immutable, shell + `sw.js` + `version.json` + manifests `no-cache`
- [ ] MediLinka landing on `/`, hospital landing untouched on the HMS host
- [ ] Doctor sign-in and `/me/telemedicine` work on the new origin
- [ ] Patient portal happy path works on the new origin
- [ ] Manifest shows MediLinka; console clean
- [ ] Previous artifact retained for rollback
