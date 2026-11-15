# MediLinka subdomain — VPS checklist (DNS · Apache · TLS)

Ordered, copy-paste runbook for putting `medilinka.mylikita.com` in front of the
same application as `app.mylikita.com`. Run each step on the server, in order.
Every step has a check; do not move on until it passes. Nothing here needs the
application code changed or the Node process restarted.

**What this does and does not do**

- Adds the hostname, terminates TLS and forwards traffic.
- Does **not** deploy code. The build, its environment variables, cache headers
  and the API-proxy/`VITE_API_URL` decision live in
  [`medilinka-frontend-deploy.md`](./medilinka-frontend-deploy.md) — run that
  alongside this checklist for a first deploy.
- Does **not** touch the database, sessions, uploads or the `app` host vhost.

**Assumptions**

- Ubuntu/Debian with Apache 2.4 and certbot installed (`apache2 -v`, `certbot --version`).
- Required Apache modules enabled: `proxy`, `proxy_http`, `proxy_wstunnel`,
  `rewrite`, `headers`, `ssl`. Enable any that are missing:
  ```bash
  sudo a2enmod proxy proxy_http proxy_wstunnel rewrite headers ssl
  sudo systemctl restart apache2
  ```
- The VPS is reachable on ports 80 and 443 from the internet.
- `medilinka.mylikita.com` will point at the **same** server as `app.mylikita.com`.

---

## 0. Preflight (read-only)

```bash
# 0.1  Who serves the app today? Find and read the existing vhost.
sudo apachectl -S 2>&1 | grep -i "mylikita\|app\."
sudo find /etc/apache2 -name "*.conf" | xargs grep -l "app\.mylikita\.com" 2>/dev/null

# Read the matched file — note whether it uses ProxyPass or DocumentRoot.
# ProxyPass to :46990 → Layout A (backend serves the SPA)
# DocumentRoot pointing at dist/ → Layout B (Apache serves static files)

# 0.2  Is the API on 46990, and is the SPA served by the backend or by Apache?
curl -s -o /dev/null -w "backend_root=%{http_code}\n" http://127.0.0.1:46990/
curl -s http://127.0.0.1:46990/ | head -c 200; echo

# 0.3  What does the existing cert cover?
sudo certbot certificates | sed -n '1,40p'

# 0.4  Backup the Apache config before touching anything.
sudo tar -czf "/root/apache2-backup-$(date +%F-%H%M).tgz" /etc/apache2
ls -1 /root/apache2-backup-*.tgz | tail -1

# 0.5  Confirm required modules are active.
apache2ctl -M 2>/dev/null | grep -E "proxy|rewrite|headers|ssl|wstunnel"
```

**Decide the layout from 0.1 / 0.2:**

| What you see | Layout | Use |
|---|---|---|
| The `app` vhost has `ProxyPass /` to `127.0.0.1:<port>` and `curl :46990/` returns HTML | **A — backend serves the SPA** | §3A |
| The `app` vhost has `DocumentRoot /…/dist` with a rewrite fallback, `/api` proxied separately | **B — Apache serves static dist** | §3B |

> If your `app` vhost differs from both, copy that vhost and change only
> `ServerName` / `DocumentRoot`. The goal is for the two hosts to be configured
> identically.

---

## 1. DNS

At the registrar / DNS provider for `mylikita.com`:

1. Add a record: type `A`, name `medilinka`, value = the IPv4 of `app.mylikita.com`.
   (If a wildcard `*.mylikita.com` already exists, nothing to add — verify in §1.2.)
2. If the zone is behind Cloudflare: set the record to **DNS only (grey cloud)**
   until §6 finishes. A proxied orange-cloud record can answer the HTTP-01
   challenge itself and make certbot fail.

```bash
# 1.1  Find the address app uses (reused by later checks).
SERVER_IP=$(dig +short app.mylikita.com | head -1)
echo "app resolves to: $SERVER_IP"

# 1.2  Confirm the new name resolves to the same address (may take minutes).
dig +short medilinka.mylikita.com
dig +short @1.1.1.1 medilinka.mylikita.com

# 1.3  Confirm this server actually answers for the name.
curl -sI --resolve "medilinka.mylikita.com:80:$SERVER_IP" http://medilinka.mylikita.com/ | head -3
```

**Pass:** §1.2 returns the same IP as §1.1 (from both resolvers), and §1.3 returns
any HTTP response (404/301 is fine at this stage).

**Fail:** NXDOMAIN → record not saved or wrong zone; wait for TTL and re-check.
Wrong IP → correct the record. Do not continue with a mismatched address.

---

## 2. Open a shell with the values you will reuse

```bash
DOMAIN=medilinka.mylikita.com
APP=app.mylikita.com
UPSTREAM=127.0.0.1:46990          # only needed for layout A / B proxy target
DIST=/var/www/app.mylikita.com    # the static build already deployed for app.mylikita.com
```

---

## 3A. Apache vhost — layout A (backend serves the SPA)

This vhost is HTTP-only on purpose. certbot adds TLS and the redirect in §6;
writing `SSLCertificateFile` lines for a certificate that does not exist yet
makes `apache2ctl configtest` fail.

```bash
sudo tee /etc/apache2/sites-available/medilinka.mylikita.com.conf >/dev/null <<'CONF'
<VirtualHost *:80>
    ServerName medilinka.mylikita.com

    # Pass everything — including WebSocket upgrades — to the Node backend.
    ProxyPreserveHost On
    ProxyRequests Off

    # WebSocket upgrade (live consultations / notifications)
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/?(.*) "ws://127.0.0.1:46990/$1" [P,L]

    ProxyPass        / http://127.0.0.1:46990/
    ProxyPassReverse / http://127.0.0.1:46990/

    RequestHeader set X-Forwarded-Proto "http"
    RequestHeader set X-Real-IP "%{REMOTE_ADDR}s"

    ErrorLog  ${APACHE_LOG_DIR}/medilinka-error.log
    CustomLog ${APACHE_LOG_DIR}/medilinka-access.log combined
</VirtualHost>
CONF
```

If §0.2 showed the backend on a different port, change `46990` before saving.

---

## 3B. Apache vhost — layout B (Apache serves the static build)

Copy `DocumentRoot` **from the `app` vhost you found in §0.1**.
The `/api` proxy below preserves the prefix — if the existing `app` vhost proxies
`/api` differently, match the existing vhost instead of using this sample.

```bash
sudo tee /etc/apache2/sites-available/medilinka.mylikita.com.conf >/dev/null <<'CONF'
<VirtualHost *:80>
    ServerName medilinka.mylikita.com

    DocumentRoot /var/www/app.mylikita.com

    <Directory /var/www/app.mylikita.com>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted

        # SPA fallback — deep links are handled by React Router.
        FallbackResource /index.html
    </Directory>

    # Hashed build output — cache forever.
    <LocationMatch "^/assets/">
        Header set Cache-Control "public, immutable, max-age=31536000"
        Header unset ETag
    </LocationMatch>

    # Shell documents must revalidate so a new deploy is picked up.
    <LocationMatch "^/(index\.html|sw\.js|version\.json|manifest\.json|manifest\.medilinka\.json)$">
        Header set Cache-Control "no-cache"
    </LocationMatch>

    # API proxy — preserve the /api prefix.
    ProxyPreserveHost On
    ProxyRequests Off

    ProxyPass        /api/ http://127.0.0.1:46990/api/
    ProxyPassReverse /api/ http://127.0.0.1:46990/api/

    # WebSocket upgrade for socket.io (live consultations / notifications).
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/socket\.io/(.*) "ws://127.0.0.1:46990/socket.io/$1" [P,L]

    ProxyPass        /socket.io/ http://127.0.0.1:46990/socket.io/
    ProxyPassReverse /socket.io/ http://127.0.0.1:46990/socket.io/

    RequestHeader set X-Forwarded-Proto "http"

    ErrorLog  ${APACHE_LOG_DIR}/medilinka-error.log
    CustomLog ${APACHE_LOG_DIR}/medilinka-access.log combined
</VirtualHost>
CONF
```

Replace `/var/www/app.mylikita.com` with the real path from the `app` vhost if it differs.

---

## 4. Enable the site and validate

```bash
sudo a2ensite medilinka.mylikita.com.conf
sudo apache2ctl configtest
```

**Pass:** `Syntax OK`.

> Serving a static build (layout B)? The staff API is mounted at root paths
> (`/auth/*`, `/onboarding/*`, `/facility/*`), not only under `/api`. Read
> [`medilinka-frontend-deploy.md` §4](./medilinka-frontend-deploy.md#4-the-api-proxy-layout-b--read-this-before-copying-the-apache-sample)
> before signing off — a page that loads but cannot sign in is usually this.

**Fail:** read the first error line. `ServerName … already defined` means a wildcard
vhost already claims this name — add `ServerAlias medilinka.mylikita.com` to that
vhost instead. Do not reload with a failing test.

```bash
sudo systemctl reload apache2
sudo systemctl is-active apache2
```

---

## 5. Verify HTTP before TLS

```bash
curl -sI --resolve "medilinka.mylikita.com:80:$SERVER_IP" http://medilinka.mylikita.com/ | head -5
curl -s  --resolve "medilinka.mylikita.com:80:$SERVER_IP" http://medilinka.mylikita.com/version.json
```

**Pass:** `200` (or a `301` to https if a redirect already exists) and a JSON body
with a `build` value.

**Fail:** `502` → upstream not listening (check §0.2 / `ss -ltnp | grep 46990`).
`404` on `/version.json` → wrong `DocumentRoot` (layout B) or the SPA is not being served.

---

## 6. TLS certificate

```bash
sudo certbot --apache -d medilinka.mylikita.com
```

- Certbot edits the vhost file: adds the SSL vhost, certificate paths and the
  HTTP→HTTPS redirect.
- If it asks about redirecting, choose **Redirect**.
- Keep the existing `app.mylikita.com` certificate untouched.

```bash
# 6.1  Certificate is present and valid.
sudo certbot certificates | sed -n '1,40p'
sudo openssl x509 -in /etc/letsencrypt/live/medilinka.mylikita.com/fullchain.pem \
  -noout -dates -subject

# 6.2  Apache still valid after certbot's edits.
sudo apache2ctl configtest && sudo systemctl reload apache2

# 6.3  Renewal will work unattended.
sudo certbot renew --dry-run
```

**Pass:** the certificate lists `medilinka.mylikita.com`, expiry is ~90 days out,
and the dry run reports success.

**Fail:** HTTP-01 challenge failure → DNS not pointing here yet, port 80 blocked,
or Cloudflare proxying. Set the record to DNS-only and retry. Do not retry more
than a few times in an hour (Let's Encrypt rate limits).

---

## 7. Post-checks (TLS, app shell, API, realtime)

```bash
# 7.1  HTTPS + redirect
curl -sI https://medilinka.mylikita.com/ | head -6
curl -sI http://medilinka.mylikita.com/ | head -4          # expect 301 to https

# 7.2  The build the browser will load
curl -s https://medilinka.mylikita.com/version.json

# 7.3  MediLinka PWA manifest is reachable
curl -sI https://medilinka.mylikita.com/manifest.medilinka.json | head -4

# 7.4  API works on the new origin (CORS already allows *.mylikita.com)
curl -s -o /dev/null -w "preflight=%{http_code}\n" -X OPTIONS \
  -H "Origin: https://medilinka.mylikita.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  https://medilinka.mylikita.com/auth/login

# 7.5  SPA deep link returns the shell, not 404 (layout B)
curl -s -o /dev/null -w "deep_link=%{http_code}\n" https://medilinka.mylikita.com/signup/doctor

# 7.6  Realtime upgrade is accepted (401/400 from the app is fine; 404 is not)
curl -s -o /dev/null -w "socket=%{http_code}\n" \
  -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  "https://medilinka.mylikita.com/socket.io/?EIO=4&transport=websocket"
```

**Pass:** 7.1 shows `200` over HTTPS and `301` from HTTP; 7.2 returns JSON;
7.3 is `200`; 7.4 is `204`/`200`; 7.5 is `200`; 7.6 is not `404`.

Then in a browser (after the MediLinka landing ships):

1. `https://medilinka.mylikita.com/` shows the MediLinka landing (this requires the
   Phase 1 frontend deploy; until then it still redirects to `/auth`, which is
   expected).
2. `https://app.mylikita.com/` is unchanged.
3. Sign in with a test staff account on the new host and confirm the dashboard loads.
4. Open DevTools → Application → Manifest and confirm `MediLinka`.
5. Confirm no mixed-content or CORS errors in the console.

> Sessions are per origin. A staff member signed in on `app.mylikita.com` is **not**
> signed in on `medilinka.mylikita.com`; that is intended.

---

## 8. Rollback (any time, no data changes)

Fastest — send the host back to the HMS until the split is ready:

```bash
sudo tee /etc/apache2/sites-available/medilinka.mylikita.com.conf >/dev/null <<'CONF'
<VirtualHost *:80>
    ServerName medilinka.mylikita.com
    Redirect 302 / https://app.mylikita.com/
</VirtualHost>
CONF

# If certbot already created the SSL vhost, update it too:
# sudo tee /etc/apache2/sites-available/medilinka.mylikita.com-le-ssl.conf >/dev/null <<'CONF'
# <VirtualHost *:443>
#     ServerName medilinka.mylikita.com
#     SSLEngine on
#     SSLCertificateFile     /etc/letsencrypt/live/medilinka.mylikita.com/fullchain.pem
#     SSLCertificateKeyFile  /etc/letsencrypt/live/medilinka.mylikita.com/privkey.pem
#     Redirect 302 / https://app.mylikita.com/
# </VirtualHost>
# CONF

sudo apache2ctl configtest && sudo systemctl reload apache2
```

Full removal:

```bash
sudo a2dissite medilinka.mylikita.com.conf
sudo apache2ctl configtest && sudo systemctl reload apache2
```

The certificate and DNS record can stay — they cost nothing and make a retry instant.
Restoring the pre-change config: untar the backup from §0.4.

---

## 9. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `apache2ctl configtest`: `ServerName already defined` | wildcard/older vhost claims the name | add `ServerAlias medilinka.mylikita.com` to that vhost instead |
| certbot: "No virtualhost found" | site not enabled or `ServerName` typo | `a2ensite`, then re-run §6 |
| certbot: challenge failed | DNS not propagated / port 80 blocked / Cloudflare proxy | re-check §1.2, set DNS-only, retry later |
| `502 Bad Gateway` | upstream not listening on the configured port | `ss -ltnp \| grep 46990`, fix `ProxyPass` target |
| `/version.json` 404 | wrong `DocumentRoot` (layout B) or SPA not served | compare with the `app` vhost |
| login works over HTTP but not HTTPS | mixed content / wrong API origin | check the browser console; confirm `VITE_API_URL` or same-origin proxy |
| SPA deep link 404 | missing `FallbackResource /index.html` | add it inside the `<Directory>` block |
| WebSocket fails, everything else works | `proxy_wstunnel` not enabled or `RewriteRule` missing | `a2enmod proxy_wstunnel`, add the `RewriteRule` from §3A/3B |
| app host breaks after the change | a shared include was edited | restore the §0.4 backup and re-apply to the new file only |
| `mod_rewrite` or `mod_proxy` errors | modules not loaded | `a2enmod proxy proxy_http proxy_wstunnel rewrite headers` and restart |

---

## 10. Done criteria

- [ ] `dig +short medilinka.mylikita.com` matches `app.mylikita.com`
- [ ] Build deployed per [`medilinka-frontend-deploy.md`](./medilinka-frontend-deploy.md) (same build id on both hosts)
- [ ] `apache2ctl configtest` passes and Apache is reloaded
- [ ] `https://medilinka.mylikita.com/` serves the build (200) and HTTP redirects to HTTPS
- [ ] `certbot renew --dry-run` succeeds
- [ ] `https://app.mylikita.com/` is unchanged
- [ ] Browser sign-in on the new host reaches the dashboard
- [ ] Console has no CORS or mixed-content errors
