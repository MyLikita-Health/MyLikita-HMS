# Self-Hosted Jitsi — Production Runbook

This runbook deploys a private Jitsi Meet stack on a Linux VPS and connects it to
the MediLinka backend. It covers DNS, TLS, firewall, JWT authentication, the
doctor/patient moderator policy, coturn/TURN, and the exact backend environment
variables used by the mobile app.

The target is a **dedicated Jitsi hostname**, for example
`video.example.com`. The mobile app never opens a browser: it renders the room
with `@jitsi/react-native-sdk`, and the backend returns the room URL and Jitsi
JWT from the telemedicine join endpoint.

> **Do not use public `meet.jit.si` for production PHI.** It does not provide the
> room-scoped token policy or the operational control this deployment needs.

---

## 1. What gets deployed

The official `docker-jitsi-meet` stack contains:

| Component | Role |
|---|---|
| `web` | Jitsi web UI and nginx TLS termination |
| `prosody` | XMPP signalling and JWT verification |
| `jicofo` | Conference focus and room lifecycle |
| `jvb` | Jitsi Videobridge; routes audio/video media |
| `coturn` | Optional TURN/STUN relay for restrictive networks |

Only the web ports and JVB media port need to be public. Prosody, Jicofo, JVB
internal ports, and the backend must not be exposed to the internet.

### Capacity starting point

| Load | Suggested VPS |
|---|---|
| A few concurrent 1:1 consultations | 2 vCPU, 4 GB RAM, 40 GB disk, 100 Mbps uplink |
| A small clinic with 10–20 concurrent 1:1 calls | 4 vCPU, 8 GB RAM, 80 GB disk, 250 Mbps uplink |
| Recording/streaming with Jibri | Separate host; Jibri is CPU-heavy and needs audio-loopback support |

Bandwidth is the usual constraint, not CPU. Plan roughly 2–3 Mbps per active
HD participant and measure the actual JVB egress. JVB media is UDP; a host that
blocks UDP or has poor peering will produce one-way audio and frozen video even
when the web page loads.

This runbook assumes Ubuntu 22.04/24.04 and a dedicated VPS. If Apache, nginx, or
another web server already owns ports 80/443, do **not** run the built-in TLS
flow: follow §8.1, which disables it, binds the web container to loopback only,
and terminates TLS on the existing server (`apache/jitsi.conf` is a ready Apache
vhost). The built-in ACME flow needs host port 80 exclusively; when it is taken,
`web` crash-loops instead of starting.

---

## 2. Placeholders

Replace every value below before running commands.

| Placeholder | Example | Notes |
|---|---|---|
| `video.example.com` | `video.mylikita.com` | Public Jitsi hostname |
| `REPLACE_WITH_VPS_PUBLIC_IP` | `203.0.113.10` | Public IPv4 of the VPS |
| `REPLACE_WITH_ACME_EMAIL` | `ops@example.com` | Let's Encrypt expiry notices |
| `REPLACE_WITH_64_HEX_JWT_SECRET` | output of `openssl rand -hex 32` | Shared by Jitsi and backend |
| `REPLACE_WITH_64_HEX_TURN_SECRET` | output of `openssl rand -hex 32` | Shared by Jitsi Prosody and coturn |
| `REPLACE_WITH_64_HEX_JOIN_SECRET` | output of `openssl rand -hex 32` | Socket.IO join token; not the Jitsi JWT |

Never commit the filled `.env` files. Keep them root-owned, mode `0600`, and
back them up in the team password manager.

---

## 3. DNS

Create these records at your DNS provider:

```text
video.example.com.    A       REPLACE_WITH_VPS_PUBLIC_IP
video.example.com.    AAAA    <optional VPS IPv6>
```

If you use Cloudflare, set the record to **DNS only** (grey cloud), not proxied.
Jitsi needs direct HTTPS/WebSocket and UDP media; the HTTP proxy does not carry
JVB media.

Verify from your workstation:

```bash
dig +short video.example.com A
dig +short video.example.com AAAA
```

Use a short TTL (300 seconds) during setup, then raise it after cutover.

---

## 4. Firewall

### Public ports

| Port | Protocol | Purpose |
|---|---|---|
| `22` | TCP | SSH; restrict to admin IPs |
| `80` | TCP | ACME HTTP challenge and HTTPS redirect |
| `443` | TCP | Jitsi web, HTTPS, WebSocket signalling |
| `10000` | UDP | JVB media |
| `3478` | UDP and TCP | coturn STUN/TURN |
| `5349` | UDP and TCP | coturn TURN over TLS/DTLS |
| `49160–49200` | UDP | coturn relay allocations in this runbook |

Do **not** expose `3306` (MySQL), `46990` (backend), `5280` (Prosody HTTP),
`5222` (XMPP), `8888` (Jicofo REST), or `8080` (JVB Colibri) publicly.

### UFW baseline

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from REPLACE_WITH_ADMIN_IP to any port 22 proto tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 10000/udp
sudo ufw allow 3478/tcp
sudo ufw allow 3478/udp
sudo ufw allow 5349/tcp
sudo ufw allow 5349/udp
sudo ufw allow 49160:49200/udp
sudo ufw enable
sudo ufw status verbose
```

### Docker firewall caveat

Docker writes its own iptables rules. Published container ports can bypass UFW,
so make the **VPS provider firewall/security group the primary boundary** and
treat UFW as defense in depth. If you rely on host firewalling, add explicit
`DOCKER-USER` rules and test from an external host.

---

## 5. Install Docker

Install Docker Engine and the Compose plugin from Docker's official apt
repository. Do not use a snap package for production.

```bash
docker --version
docker compose version
```

Both commands must work as the deployment user. The user must be able to run
Docker (membership in the `docker` group is root-equivalent; restrict it to the
deploy account).

Create the deployment directory:

```bash
sudo mkdir -p /opt/jitsi
sudo chown "$USER":"$USER" /opt/jitsi
cd /opt/jitsi
```

---

## 6. Download the official Jitsi release

Download the latest release ZIP from:

<https://github.com/jitsi/docker-jitsi-meet/releases/latest>

Do not `git clone` the repository for production. Extract the release and enter
its directory:

```bash
cd /opt/jitsi
unzip docker-jitsi-meet-*.zip
cd docker-jitsi-meet-*
# Stable path for later commands and cron. Repoint it when you upgrade.
ln -sfn "$PWD" /opt/jitsi/current
cd /opt/jitsi/current
```

Record the release tag. You will pin it in `.env`; do not run `unstable` or
`latest` in production.

Create the persistent configuration directories outside the release directory:

```bash
export CONFIG=/opt/jitsi-meet-cfg
sudo mkdir -p "$CONFIG"/{web,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb}
sudo mkdir -p "$CONFIG"/storage/{prosody,transcripts,web}
sudo mkdir -p "$CONFIG"/tmp/{web-crontabs,web-load-test}
sudo mkdir -p "$CONFIG"/storage/web/acme-certs/video.example.com
sudo chown -R 1000:1000 "$CONFIG"/storage "$CONFIG"/tmp
sudo chmod 750 "$CONFIG"/storage "$CONFIG"/tmp
```

The containers run as uid/gid `1000`, so the `storage` and `tmp` trees must be
writable by that user. The certificate directory is created before the web
container starts so the coturn bind mount does not create it as root.

---

## 7. Jitsi `.env`

Copy the release template and generate the internal service passwords:

```bash
cp env.example .env
./gen-passwords.sh
chmod 600 .env
```

Edit `.env`. Start from the values below and replace every placeholder.

### Core, TLS, and image pinning

```dotenv
CONFIG=/opt/jitsi-meet-cfg
TZ=Africa/Lagos
COMPOSE_PROJECT_NAME=jitsi

PUBLIC_URL=https://video.example.com
HTTP_PORT=80
HTTPS_PORT=443
ENABLE_HTTP_REDIRECT=1

ENABLE_LETSENCRYPT=1
LETSENCRYPT_DOMAIN=video.example.com
LETSENCRYPT_EMAIL=REPLACE_WITH_ACME_EMAIL
LETSENCRYPT_USE_STAGING=0
# The upstream template defaults to ZeroSSL; select Let's Encrypt explicitly.
LETSENCRYPT_ACME_SERVER=letsencrypt

# Pin the release tag you downloaded. Never use "latest" or "unstable".
# Jitsi publishes stable builds to ghcr.io only — Docker Hub (jitsi/*) stops at
# stable-11031, so a tag like stable-11248-3 "does not exist" if the repo is left
# on docker.io. Keep JITSI_IMAGE_REPO=ghcr.io/jitsi.
JITSI_IMAGE_REPO=ghcr.io/jitsi
JITSI_IMAGE_VERSION=stable-11248-3
RESTART_POLICY=unless-stopped

# Public IPv4 of this VPS. If the VPS is behind 1:1 NAT, use the public IP.
JVB_ADVERTISE_IPS=REPLACE_WITH_VPS_PUBLIC_IP
JVB_PORT=10000
# Colibri REST/health port, bound to 127.0.0.1 only. Change it if 8080 is taken
# (`ss -ltnp 'sport = :8080'`) — do not publish it on 0.0.0.0.
JVB_COLIBRI_PORT=8080
```

Before the first `docker compose up`, confirm the compose file honours the repo
variable and that the tag really exists:

```bash
grep -n 'image:' docker-compose.yml | head -4   # must show ${JITSI_IMAGE_REPO:-...}
docker compose config | grep -m4 'image:'       # must print ghcr.io/jitsi/...
docker manifest inspect ghcr.io/jitsi/web:"$JITSI_IMAGE_VERSION" >/dev/null && echo tag ok
```

If `docker-compose.yml` lists plain `jitsi/web:` (an older release), either
re-extract the release matching the tag or pin `stable-11031`, the newest build
that exists on Docker Hub.

If you are testing Let's Encrypt rate limits, set `LETSENCRYPT_USE_STAGING=1`
first, then set it back to `0` and recreate the web container. Staging
certificates are not trusted by browsers or the mobile app.

### JWT authentication

```dotenv
ENABLE_AUTH=1
AUTH_TYPE=jwt
ENABLE_GUESTS=0
JWT_ALLOW_EMPTY=0

JWT_APP_ID=medilinka
JWT_APP_SECRET=REPLACE_WITH_64_HEX_JWT_SECRET
JWT_ACCEPTED_ISSUERS=medilinka
JWT_ACCEPTED_AUDIENCES=medilinka
JWT_SIGN_TYPE=HS256
JWT_ENABLE_DOMAIN_VERIFICATION=1
JWT_TOKEN_AUTH_MODULE=token_verification
JWT_AUTH_TYPE=token
```

`JWT_APP_SECRET` must be the exact same string in the backend's
`TELEMEDICINE_JITSI_APP_SECRET`. Generate it once with:

```bash
openssl rand -hex 32
```

The backend signs with HS256, names `medilinka` as issuer and audience, and
claims the consultation room. Do not put the secret in the mobile app, a
frontend bundle, a support ticket, or a screenshot.

### Doctor/patient moderator policy

The backend gives the doctor `context.user.moderator: true` and the patient
`false`. Jitsi does not enforce that claim by itself. Apply all three settings:

```dotenv
JICOFO_ENABLE_AUTH=0
ENABLE_AUTO_OWNER=0
XMPP_MUC_MODULES=token_affiliation
```

Why all three:

- `JICOFO_ENABLE_AUTH=0` stops Jicofo from making every authenticated JWT holder
  a moderator.
- `ENABLE_AUTO_OWNER=0` stops the first person to join from becoming moderator.
- `token_affiliation` makes Prosody apply the token's `context.user.moderator`
  claim.

Without all three, a patient token with `moderator: false` can still receive
moderator powers on some Docker releases. Test this with two devices; it is a
security acceptance test, not a cosmetic check.

If you enable the lobby later, test it separately. The baseline keeps the lobby
off so the patient's in-app auto-join is predictable:

```dotenv
ENABLE_LOBBY=0
```

### UI/feature defaults for the mobile consultation

```dotenv
ENABLE_PREJOIN_PAGE=0
ENABLE_WELCOME_PAGE=0
ENABLE_CLOSE_PAGE=0
ENABLE_BREAKOUT_ROOMS=0
ENABLE_RECORDING=0
ENABLE_LIVESTREAMING=0
ENABLE_TRANSCRIPTIONS=0
ENABLE_JAAS_COMPONENTS=0
DISABLE_DEEP_LINKING=1
```

The mobile Jitsi view also sets `prejoinPageEnabled: false` and disables
invites/recording/streaming in its own config. These server defaults keep the
web fallback consistent.

Do not enable Jibri on this host unless recording is an approved requirement
with a retention policy. Jibri is a separate, CPU-heavy service.

### TURN

```dotenv
TURN_CREDENTIALS=REPLACE_WITH_64_HEX_TURN_SECRET
TURN_HOST=video.example.com
TURN_PORT=3478
TURN_TRANSPORT=udp,tcp
TURNS_HOST=video.example.com
TURNS_PORT=5349
TURN_TTL=86400

# Use the same coturn as the JVB's STUN server; avoids a public STUN dependency.
JVB_STUN_SERVERS=video.example.com:3478
```

`TURN_CREDENTIALS` is a **shared secret**, not `username:password`. Prosody uses
it to issue short-lived TURN credentials, and coturn checks those credentials
with `use-auth-secret` / `static-auth-secret`.

### Internal XMPP domain

Leave the Docker default:

```dotenv
XMPP_DOMAIN=meet.jitsi
```

If you change `XMPP_DOMAIN`, update the backend's
`TELEMEDICINE_JITSI_SUB` to the same value. With
`JWT_ENABLE_DOMAIN_VERIFICATION=1`, `sub` must match `XMPP_DOMAIN`, not the public
hostname.

---

## 8. Start Jitsi and obtain the certificate

Start the core stack first:

```bash
cd /opt/jitsi/current
docker compose config >/dev/null
docker compose up -d
docker compose ps
docker compose logs --tail=100 web prosody jicofo jvb
```

The web container obtains the Let's Encrypt certificate on first boot. Wait for
it and verify:

```bash
ls -l /opt/jitsi-meet-cfg/storage/web/acme-certs/video.example.com/
curl -sS -o /dev/null -w '%{http_code}\n' https://video.example.com/
openssl s_client -connect video.example.com:443 \
  -servername video.example.com </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -dates
```

Expected: HTTP `200` and a valid certificate for `video.example.com`. Do not
continue while the certificate is self-signed or staging-only.

If the certificate is missing, inspect:

```bash
docker compose logs --tail=200 web
```

Common causes are DNS not pointing at the VPS, ports 80/443 already occupied, or
Let's Encrypt rate limiting from repeated failed attempts.

### 8.1 Host already runs Apache or nginx on 80/443

This is the common case when the VPS also serves the app or other sites. The
built-in flow uses **acme.sh standalone**, which must bind host port 80 for the
HTTP-01 challenge. It cannot share that port with Apache, so:

1. the challenge fails every attempt;
2. the `10-config` oneshot exits 1, so `/run/web/config/nginx/nginx.conf` is never
   generated and the container restarts forever with
   `open() "/run/web/config/nginx/nginx.conf" failed`;
3. five failed authorizations in an hour trip Let's Encrypt's *failed
   authorizations per identifier* limit, and the visible error becomes
   `429 … type: urn:ietf:params:acme:error:rateLimited`.

Never "fix" this by moving Apache off 80/443 on a server that already serves
other sites. Terminate TLS on Apache and proxy to the container over loopback.

```dotenv
DISABLE_HTTPS=1
ENABLE_HTTP_REDIRECT=0
ENABLE_LETSENCRYPT=0

# Must be the public URL Apache serves, and must match DNS.
PUBLIC_URL=https://video.example.com

# Loopback only: prevents Docker from binding 8000/8443 on the public interface.
HTTP_PORT=127.0.0.1:8000
HTTPS_PORT=127.0.0.1:8443
```

Delete the `LETSENCRYPT_*` lines (or leave them, unused). Do not leave
`LETSENCRYPT_DOMAIN` pointing at one name while `PUBLIC_URL` names another: the
container then orders a certificate for the wrong host, which is invisible until
validation fails.

Enable the Apache modules and install the vhost:

```bash
sudo a2enmod proxy proxy_http proxy_wstunnel headers ssl rewrite
sudo cp apache/jitsi.conf /etc/apache2/sites-available/jitsi.conf
sudo editor /etc/apache2/sites-available/jitsi.conf   # set ServerName + cert paths
sudo a2ensite jitsi
sudo apache2ctl configtest && sudo systemctl reload apache2
```

Get the certificate with the host's existing ACME tooling, not with Jitsi's:

```bash
sudo certbot --apache -d video.example.com          # or --certonly --webroot
sudo systemctl reload apache2
```

**`certbot --apache` copies whatever vhost it finds into a new `-le-ssl.conf` and
that copy wins name-based selection.** Run it *before* installing the proxy
vhost and you end up with two `:443` vhosts for the same name, the certbot copy
serving a stale `DocumentRoot` first: the page returns `403 Forbidden`
(`AH01276: Cannot serve directory /var/www/html/`) and `/http-bind` returns
`404`, even though `http://127.0.0.1:8000/` answers `200`. `apache2ctl -S` names
the winner next to `namevhost <host>`. If that is a `-le-ssl.conf`, put the
proxy directives into it (or delete it and re-enable the proxy vhost). Certbot
only rewrites the certificate lines on renewal, so hand-authored proxy config
there survives.

Then recreate the web container so the port and TLS changes apply:

```bash
cd /opt/jitsi/current
docker compose up -d --force-recreate web
docker compose logs --tail=50 web      # must stay Up, no acme.sh output
```

Verify in this order: loopback first, then the public name.

```bash
ss -ltnp 'sport = :8000'                                  # 127.0.0.1:8000 only
curl -sS -o /dev/null -w 'loopback %{http_code}\n' http://127.0.0.1:8000/
curl -sS -o /dev/null -w 'https    %{http_code}\n' https://video.example.com/
curl -sS -o /dev/null -w 'bosh     %{http_code}\n' https://video.example.com/http-bind
curl -sS --http1.1 -o /dev/null -w 'ws       %{http_code}\n' \
  -H 'Connection: Upgrade' -H 'Upgrade: websocket' \
  -H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
  -H 'Sec-WebSocket-Protocol: xmpp' \
  https://video.example.com/xmpp-websocket
```

Expect `200` everywhere; the WebSocket probe returns `101` when the upgrade
succeeds (Apache returns `200`/`400` on a failed upgrade, so compare it against
the container directly if you are unsure). Always send
`Sec-WebSocket-Protocol: xmpp`, as the client does; a probe without it can be
rejected by Prosody even though the browser path works.

A `501` on this route almost always means the probe did not offer the `xmpp`
subprotocol: Prosody rejects the upgrade, and the identical probe succeeds once
`Sec-WebSocket-Protocol: xmpp` is added. A correctly upgraded probe exits 28
(`curl: (28) Operation timed out`) because the socket stays open — that is
success when the status line reads `101`. If it still fails with the subprotocol
sent, look inside the stack before touching Apache: the web container's
`meet.conf` defines the route only when `ENABLE_XMPP_WEBSOCKET` is not `0`, and
forwards it to `XMPP_BOSH_URL_BASE` (default `http://xmpp.meet.jitsi:5280`).

Notes for this topology:

- Only `/xmpp-websocket` needs WebSocket handling. Media bypasses the proxy and
  goes straight to JVB on `10000/udp`, so the firewall rules in §4 are unchanged.
- Do **not** add a `/colibri-ws/` route or set `ENABLE_COLIBRI_WEBSOCKET`. Those
  variables were removed in `stable-11146+`; proxying a route the container no
  longer serves only produces 404s.
- Apache must forward the original `Host` and an `X-Forwarded-Proto: https`
  header. `PUBLIC_URL` drives the generated client config, but a wrong scheme
  header breaks redirects that Jitsi builds itself.
- coturn (§9.3) can no longer mount the container's `acme-certs` directory; see
  the note there before starting it.

---

## 9. coturn / TURN

`docker-jitsi-meet` does not bundle a TURN server. coturn is strongly recommended
because hospital Wi-Fi, corporate networks, and some mobile carriers block direct
UDP or restrict it to TCP 443.

This baseline runs coturn on the same VPS, in host networking mode, with its own
shared secret. It uses the certificate that Jitsi's web container already
obtained, so there is no second ACME flow to maintain.

### 9.1 Generate the TURN secret

```bash
openssl rand -hex 32
```

Put the same value in:

- Jitsi `.env`: `TURN_CREDENTIALS=...`
- coturn config: `static-auth-secret=...`

Do not use a username/password pair here. Do not reuse the JWT secret.

### 9.2 coturn config

Create the directory:

```bash
mkdir -p /opt/jitsi/coturn
```

Create `/opt/jitsi/coturn/turnserver.conf`:

```conf
listening-port=3478
tls-listening-port=5349

realm=video.example.com
use-auth-secret
static-auth-secret=REPLACE_WITH_64_HEX_TURN_SECRET

fingerprint
stale-nonce=600
no-cli
no-multicast-peers
no-loopback-peers
no-tlsv1
no-tlsv1_1

# Keep relay allocations bounded so the firewall range is explicit.
min-port=49160
max-port=49200

# Jitsi's web container writes these into its storage volume.
cert=/certs/fullchain.pem
pkey=/certs/key.pem

log-file=stdout
simple-log

# If the VPS is behind 1:1 NAT, uncomment and use public/private addresses:
# external-ip=REPLACE_WITH_VPS_PUBLIC_IP/REPLACE_WITH_VPS_PRIVATE_IP

# Do not relay to loopback, private, link-local, documentation, multicast,
# or reserved ranges.
denied-peer-ip=0.0.0.0-0.255.255.255
denied-peer-ip=10.0.0.0-10.255.255.255
denied-peer-ip=100.64.0.0-100.127.255.255
denied-peer-ip=127.0.0.0-127.255.255.255
denied-peer-ip=169.254.0.0-169.254.255.255
denied-peer-ip=172.16.0.0-172.31.255.255
denied-peer-ip=192.0.0.0-192.0.0.255
denied-peer-ip=192.0.2.0-192.0.2.255
denied-peer-ip=192.168.0.0-192.168.255.255
denied-peer-ip=198.18.0.0-198.19.255.255
denied-peer-ip=198.51.100.0-198.51.100.255
denied-peer-ip=203.0.113.0-203.0.113.255
denied-peer-ip=224.0.0.0-239.255.255.255
denied-peer-ip=240.0.0.0-255.255.255.255
```

If your VPS has IPv6 relay enabled, add the corresponding IPv6 deny ranges as
well. Keep the `denied-peer-ip` list current; it prevents the relay from being
used to reach private services.

### 9.3 coturn Compose file

Create `/opt/jitsi/current/compose.coturn.yml`:

```yaml
services:
  coturn:
    image: docker.io/coturn/coturn:4.18.0
    container_name: jitsi-coturn
    restart: unless-stopped

    # Host networking avoids Docker's large relay-port NAT overhead.
    network_mode: host

    # Match the uid/gid that owns the Jitsi certificate files.
    user: "1000:1000"

    volumes:
      - /opt/jitsi/coturn/turnserver.conf:/etc/coturn/turnserver.conf:ro
      - /opt/jitsi-meet-cfg/storage/web/acme-certs/video.example.com:/certs:ro

    tmpfs:
      - /var/lib/coturn

    command: ["-c", "/etc/coturn/turnserver.conf"]
```

**Reverse-proxy mode (§8.1):** there is no container certificate directory.
Mount the host's ACME store instead and point `turnserver.conf` at it:

```yaml
    user: "0:0"            # letsencrypt privkey.pem is 0600 root only
    volumes:
      - /opt/jitsi/coturn/turnserver.conf:/etc/coturn/turnserver.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
```

```conf
cert=/etc/letsencrypt/live/video.example.com/fullchain.pem
pkey=/etc/letsencrypt/live/video.example.com/privkey.pem
```

Running coturn as root is the least-surprising option here; the alternative is
copying the pair into a readable directory from a certbot deploy hook, which also
means the weekly restart in §9.4 has to re-copy it.

Start it after the certificate exists:

```bash
cd /opt/jitsi/current
docker compose -f docker-compose.yml -f compose.coturn.yml up -d coturn
docker compose -f docker-compose.yml -f compose.coturn.yml logs --tail=100 coturn
```

Verify the TURN TLS listener:

```bash
openssl s_client -connect video.example.com:5349 \
  -servername video.example.com </dev/null
```

You should see a trusted certificate chain. A certificate error here means the
mounted `fullchain.pem` / `key.pem` paths or permissions are wrong.

### 9.4 Certificate renewal

Jitsi's web container renews its certificate, but coturn will keep the old
certificate until restarted. Add a weekly restart or a renewal hook:

```bash
# /etc/cron.weekly/jitsi-coturn-restart
#!/bin/sh
set -e
cd /opt/jitsi/current
docker compose -f docker-compose.yml -f compose.coturn.yml restart coturn
```

Make it executable with `chmod 0755`. Restarting coturn drops active TURN
allocations, so schedule it in a low-traffic window and monitor the next call.

### 9.5 If 5349 is blocked

Some networks allow only TCP 443. The official Jitsi handbook documents sharing
port 443 with nginx stream multiplexing and a second DNS name. That is an
advanced change: it requires moving the web listener, adding `ssl_preread`, and
changing Prosody's advertised TURN port. Do not attempt it during the initial
launch; get the standard 3478/5349 path working first.

---

## 10. Validate the Jitsi stack

### Ports

```bash
sudo ss -lntup | grep -E ':(80|443|10000|3478|5349)\b'
```

Expected listeners:

- `80/tcp`, `443/tcp` — the web container on a dedicated host, or Apache/nginx
  in reverse-proxy mode (§8.1), where the container binds only `127.0.0.1:8000`
- `10000/udp` — JVB
- `3478/tcp`, `3478/udp`, `5349/tcp`, `5349/udp` — coturn

### Containers

```bash
docker compose ps
docker compose logs --tail=100 web prosody jicofo jvb
```

All core containers should be running. `jvb` should report a healthy bridge, and
`prosody` should not report JWT configuration errors.

### Tokenless access must fail

Open a private browser window to:

```text
https://video.example.com/medilinka-tokenless-test
```

With `ENABLE_GUESTS=0` and `JWT_ALLOW_EMPTY=0`, a participant without a token must
not be admitted to the room. The page may load, but joining must be rejected or
held. If a tokenless user can join, stop and fix the auth settings before
connecting the mobile app.

### JWT acceptance

The real acceptance path is the mobile app:

1. Patient signs in and opens a telemedicine visit.
2. Backend returns `room` and `jitsiToken`.
3. The native Jitsi view joins `https://video.example.com/{room}` with the token.
4. The doctor joins with a doctor token.
5. The doctor can mute the patient; the patient cannot mute the doctor.
6. The doctor ends the call; the patient sees the ended state and the backend
   records the leave.

Do not paste production JWTs into online decoders or support tickets.

---

## 11. Backend environment

`backend/docker-compose.yml` now interpolates every `TELEMEDICINE_*` value into
the `mylikita-backend` container, so the values belong in `backend/.env`
(Compose reads that file automatically, and it is gitignored) — the compose file
itself is not edited per deployment. The service still does **not** use
`env_file`, so a variable missing from the interpolation block is invisible to
the container even if it is set in `.env`. Empty values keep public meet.jit.si
mode: no Jitsi JWT is issued.

```dotenv
# Room URL returned to the mobile app. No trailing slash.
TELEMEDICINE_ROOM_URL_TEMPLATE=https://video.example.com/{room}

# Jitsi JWT. These must match the Jitsi .env exactly.
TELEMEDICINE_JITSI_APP_ID=medilinka
TELEMEDICINE_JITSI_APP_SECRET=REPLACE_WITH_64_HEX_JWT_SECRET
TELEMEDICINE_JITSI_ISSUER=medilinka
TELEMEDICINE_JITSI_AUDIENCE=medilinka

# Required while JWT_ENABLE_DOMAIN_VERIFICATION=1.
# Docker's default XMPP_DOMAIN is meet.jitsi. If you changed XMPP_DOMAIN in
# Jitsi's .env, use that value here instead.
TELEMEDICINE_JITSI_SUB=meet.jitsi
TELEMEDICINE_JITSI_TTL_SECONDS=14400

# Socket.IO room token. Keep separate from the Jitsi JWT.
# If omitted, the backend falls back to JWT_SECRET; set it explicitly.
TELEMEDICINE_JOIN_SECRET=REPLACE_WITH_64_HEX_JOIN_SECRET
TELEMEDICINE_JOIN_ISSUER=mylikita-hms
TELEMEDICINE_JOIN_AUDIENCE=mylikita-telemedicine
TELEMEDICINE_JOIN_TTL_SECONDS=600
TELEMEDICINE_JOIN_BEFORE_MIN=30
TELEMEDICINE_JOIN_AFTER_MIN=120
```

Important:

- `TELEMEDICINE_JITSI_APP_SECRET` and Jitsi's `JWT_APP_SECRET` must be the same
  string. A trailing space or newline counts as a different secret.
- Do not reuse `JWT_SECRET` for either the Jitsi secret or the join secret.
- Do not leave `TELEMEDICINE_JITSI_APP_ID` / `_APP_SECRET` empty in production.
  Empty values disable the Jitsi token; a self-hosted server with token auth will
  reject the join.
- `TELEMEDICINE_ROOM_URL_TEMPLATE` must contain the literal `{room}` placeholder.
- The backend already sets `context.user.moderator` from the authenticated role;
  the doctor gets `true`, the patient gets `false`.
- Recreate the backend with its normal process manager — environment changes
  need a recreate, not just a restart. For the repo Compose service:
  `docker compose up -d --force-recreate mylikita-backend`.
- Confirm the container actually received the values without echoing the
  secret (an empty value means the key never reached it):
  `docker compose exec mylikita-backend env | grep -E '^TELEMEDICINE_JITSI_(APP_ID|ISSUER|AUDIENCE|SUB)='`,
  then `docker compose exec mylikita-backend sh -c 'test -n "$TELEMEDICINE_JITSI_APP_SECRET" && echo app_secret=set'`.
  Do not run `env | grep TELEMEDICINE` — it prints the secret.
- A join response must then carry a `jitsiToken`; without it the deployment is
  still in tokenless mode and the token-auth server will reject the room.

No mobile-app rebuild is needed when only the Jitsi hostname changes, because the
mobile app receives the room URL and token from this backend endpoint. The app
still needs a native development/release build containing the Jitsi SDK; Expo Go
cannot render the native call.

---

## 12. Cutover

1. Schedule a low-traffic window.
2. Deploy and validate Jitsi with a test room.
3. Back up the current backend environment.
4. Set the backend variables above.
5. Restart the backend.
6. Run one test appointment end-to-end with two devices.
7. Only then route real consultations to the new hostname.

Existing calls on the old server are not moved. Let them finish, or reschedule
them. Do not silently fall back to `meet.jit.si` for a live PHI consultation.

---

## 13. Acceptance tests

Run these before calling the deployment production-ready.

### Server

- [ ] `https://video.example.com/` returns `200` over a valid certificate.
- [ ] `https://video.example.com/config.js` loads.
- [ ] A private browser window cannot join without a token.
- [ ] `ss` shows `10000/udp`, `3478`, and `5349` listening.
- [ ] `docker compose ps` shows web, Prosody, Jicofo, and JVB running.
- [ ] coturn logs show no certificate or shared-secret errors.
- [ ] An external port scan sees only the intended public ports.

### JWT and roles

- [ ] Patient joins with a patient token; doctor joins with a doctor token.
- [ ] Doctor can mute the patient; patient cannot mute the doctor.
- [ ] Patient joins first, then doctor joins late; doctor still gets moderator.
- [ ] A token for room A cannot join room B.
- [ ] A token with a bad signature is rejected.
- [ ] A token with the wrong `iss`, `aud`, or `sub` is rejected.
- [ ] An expired token is rejected on a new connection.

### Media and resilience

- [ ] Camera and microphone work on both devices.
- [ ] Audio is two-way; no one-way audio.
- [ ] A call survives a Wi-Fi/cellular handoff, or reconnects cleanly.
- [ ] A call works on a network that blocks UDP 10000 and falls back to TURN.
- [ ] Ending the call in Jitsi closes the app screen and records the leave.
- [ ] The post-visit record/bill flow still runs.

### TURN

- [ ] `openssl s_client -connect video.example.com:5349` shows a trusted cert.
- [ ] A restrictive network call produces a relay candidate/TURN allocation.
- [ ] coturn logs show successful authentication, not `401` or `Cannot find credentials`.

If TURN is not actually used on a network that blocks direct media, the call will
connect but have no audio/video. That is a failed acceptance test.

---

## 14. Operations

### Updates

1. Read the release notes.
2. Back up `.env`, `CONFIG`, `coturn/turnserver.conf`, and the backend env.
3. Pull the new pinned image tag in a staging environment.
4. Test JWT, moderator roles, TURN, and a two-device call.
5. Deploy in a maintenance window.
6. Copy `.env` and `compose.coturn.yml` into the new release, repoint
   `/opt/jitsi/current` to it, then run `docker compose up -d`.
7. Keep the previous tag available for rollback.

Do not use `latest` or `unstable`. Do not delete the configuration volume during
an upgrade.

### Backups

Back up:

- `/opt/jitsi/current/.env`
- `/opt/jitsi-meet-cfg/` (certificates, Prosody state, configuration)
- `/opt/jitsi/coturn/turnserver.conf`
- backend `.env` / secret-manager entries

Store backups encrypted. A backup of `.env` contains production secrets.

### Monitoring

- Container status and restart counts.
- JVB CPU, memory, and egress bandwidth.
- Disk space for Docker images, logs, and certificates.
- TLS expiry for `video.example.com` and the coturn certificate.
- coturn authentication failures and relay-port exhaustion.
- Backend telemedicine join failures and Jitsi token errors.

Set Docker log rotation; Jitsi can be noisy. Do not log JWTs or TURN secrets.

### Security

- Firewall: provider security group first, UFW second.
- SSH: keys only, no root login, restrict source IPs.
- Docker group membership is root-equivalent; limit it.
- Keep the host, Docker, Jitsi images, and coturn patched.
- Do not enable recording, streaming, or transcriptions without a retention and
  access policy.
- Keep the JWT and TURN secrets out of Git, chat, screenshots, and mobile code.
- Review Jitsi/Prosody logs for retention; they can contain room names and IPs.

### Scaling

For more concurrency, add JVBs rather than exposing more web containers. Jicofo
selects bridges from the JVB brewery. Keep `JVB_ADVERTISE_IPS` correct for every
bridge and monitor egress. A single small VPS is appropriate for the initial
clinic load, not for an unbounded number of simultaneous calls.

---

## 15. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Web page loads but join is rejected | JWT missing, expired, or wrong secret | Check backend `TELEMEDICINE_JITSI_APP_SECRET` equals Jitsi `JWT_APP_SECRET`; check `iss`/`aud`; restart both |
| `sub`/domain error | Domain verification is on but `sub` is the public host | Set backend `TELEMEDICINE_JITSI_SUB=meet.jitsi`, or the actual `XMPP_DOMAIN`, and restart |
| Room mismatch | Token room claim does not match the URL room | Ensure backend `{room}` and the mobile room name are identical; check URL encoding |
| Everyone is moderator | Jicofo auth/auto-owner still promoting users, or `token_affiliation` not loaded | Set `JICOFO_ENABLE_AUTH=0`, `ENABLE_AUTO_OWNER=0`, `XMPP_MUC_MODULES=token_affiliation`; recreate affected containers |
| Patient becomes moderator after doctor joins | Known first-joiner/module race on some releases | Upgrade to a release with the token-affiliation fix; retest patient-first and doctor-first |
| One-way audio or frozen video | UDP 10000 blocked, wrong `JVB_ADVERTISE_IPS`, or NAT | Open 10000/udp, set the public IP, test from an external network; add TURN |
| Call works on Wi-Fi but not hospital network | Direct UDP/TCP blocked | Verify coturn, 3478/5349, and TURN credentials; test a relay candidate |
| TURN `401` / auth failure | `TURN_CREDENTIALS` and `static-auth-secret` differ, or static user mode was mixed in | Use the same shared secret on both sides; remove `user=`/`lt-cred-mech` |
| coturn TLS error | Wrong cert path, key permissions, or hostname mismatch | Check `/certs/fullchain.pem` and `/certs/key.pem`; verify cert SAN and container uid |
| `502`/WebSocket errors behind a proxy | Proxy is not forwarding `/xmpp-websocket` | Use the official web container on 80/443, or configure the proxy for WebSocket upgrade |
| `https` returns `403` and `/http-bind` returns `404` while loopback returns `200` | A `certbot --apache` `-le-ssl.conf` copied a stale `DocumentRoot` vhost that wins name-based selection over the proxy vhost | `apache2ctl -S` to find the winning file; put the proxy directives in it or remove it (see §8.1) |
| Certificate issuance fails | DNS not propagated, ports 80/443 busy, or rate limit | Fix DNS/ports; use staging only for debugging; inspect `docker compose logs web` |
| `web` restarts with `10-config: command exited 1`, then `open() "/run/web/config/nginx/nginx.conf" failed` | acme.sh standalone cannot bind port 80 because Apache/nginx already owns it; five failures also trigger a `429 rateLimited` | Use reverse-proxy mode (§8.1); confirm `LETSENCRYPT_DOMAIN` and `PUBLIC_URL` name the same host; wait out the retry-after time |
| No space left on device | Docker images/logs or recordings filled the disk | Check `df -h`, `docker system df`; prune only after confirming what is safe |
| App shows “Video could not start” | Expo Go or a build without native Jitsi modules | Install a native development/release build; check `adb logcat` for Jitsi errors |

---

## 16. Rollback

1. Restore the previous backend environment and restart the backend.
2. Restore the previous Jitsi release tag and `.env`.
3. Do not delete `/opt/jitsi-meet-cfg` or the coturn certificate directory.
4. Run a test call before reopening consultations.

If the self-hosted service is unavailable and no previous self-hosted deployment
exists, pause/reschedule video visits rather than sending PHI to public
`meet.jit.si`.

---

## 17. Go-live checklist

- [ ] Dedicated DNS name resolves to the VPS.
- [ ] Ports 80/443/10000 open; 3478/5349/relay range open if using coturn.
- [ ] Valid TLS certificate for the Jitsi hostname.
- [ ] Jitsi pinned to a stable release tag.
- [ ] JWT auth enabled; guests and empty tokens disabled.
- [ ] `sub` matches `XMPP_DOMAIN` with domain verification on.
- [ ] Doctor token is moderator; patient token is not.
- [ ] `JICOFO_ENABLE_AUTH=0`, `ENABLE_AUTO_OWNER=0`, and `token_affiliation` set.
- [ ] TURN shared secret matches coturn; TURN TLS works.
- [ ] Backend `TELEMEDICINE_*` values set and backend restarted.
- [ ] Two-device call, late doctor, reconnect, and end-visit tests pass.
- [ ] Backups and monitoring are in place.
- [ ] No secrets committed to Git or printed in logs.
- [ ] Team knows the rollback procedure.

---

## References

- Jitsi Docker self-hosting guide:
  <https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker>
- Jitsi TURN setup:
  <https://jitsi.github.io/handbook/docs/devops-guide/turn>
- Jitsi JWT token claims:
  <https://github.com/jitsi/lib-jitsi-meet/blob/master/doc/tokens.md>
- Official Docker release and `env.example`:
  <https://github.com/jitsi/docker-jitsi-meet/releases/latest>
- coturn:
  <https://github.com/coturn/coturn>
