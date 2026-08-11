#!/usr/bin/env bash
#
# MyLikita Relay — fresh-server provisioning script.
#
# Installs and starts the relay (backend/relay) on a new cloud server:
#   • system deps (Node 18+, nginx, certbot, mysql client/server, rsync)
#   • copies the relay source to its install dir + `npm ci --omit=dev`
#   • generates .env with openssl-random secrets (never clobbers an existing one)
#   • creates the relay MySQL database + dedicated user (schema auto-bootstraps)
#   • nginx TLS block (HTTP by default, certbot --nginx when --domain given)
#   • PM2 ecosystem startup + pm2 save + pm2 startup (survives reboot)
#
# Idempotent: safe to re-run. An existing .env, DB, and PM2 app are reused.
#
# Usage:
#   sudo bash deploy/relay-install.sh [--domain relay.mylikita.com] [--email ops@mylikita.com]
#
# Options:
#   --domain DOMAIN            Public hostname (nginx server_name + certbot TLS).
#   --email EMAIL              Let's Encrypt contact (required with --domain).
#   --install-dir DIR          Relay install dir (default /opt/mylikita-relay).
#   --in-place                 Provision from the repo checkout instead of copying.
#   --relay-port PORT          Relay HTTP port (default 46995).
#   --db-host HOST             MySQL host (default 127.0.0.1; remote needs
#                              --mysql-root-password).
#   --db-name NAME             Relay database name (default mylikita_relay).
#   --db-user USER             Dedicated DB user (default relay).
#   --db-password PASS         DB password (default: openssl rand -hex 16).
#   --mysql-root-password PASS Root password, only needed for a REMOTE DB host.
#   --no-nginx                 Skip nginx install/config.
#   --no-cert                  Skip certbot even if --domain is set.
#   --no-pm2                   Skip PM2 install/start (run `node app.js` manually).
#   -h, --help                 Show this help.
#
set -euo pipefail

# ── where we are ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$REPO_ROOT/backend/relay"

# ── defaults ────────────────────────────────────────────────────────────────
DOMAIN=""
EMAIL=""
INSTALL_DIR="/opt/mylikita-relay"
IN_PLACE=0
RELAY_PORT=46995
DB_HOST="127.0.0.1"
DB_NAME="mylikita_relay"
DB_USER="relay"
DB_PASSWORD=""
MYSQL_ROOT_PASSWORD=""
DO_NGINX=1
DO_CERT=1
DO_PM2=1

log()  { printf '\033[1;34m[relay-install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[relay-install]\033[0m WARN %s\n' "$*"; }
die()  { printf '\033[1;31m[relay-install]\033[0m ERROR %s\n' "$*" >&2; exit 1; }

usage() { sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

# ── parse args ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)            DOMAIN="$2"; shift 2 ;;
    --email)             EMAIL="$2"; shift 2 ;;
    --install-dir)       INSTALL_DIR="$2"; shift 2 ;;
    --in-place)          IN_PLACE=1; shift ;;
    --relay-port)        RELAY_PORT="$2"; shift 2 ;;
    --db-host)           DB_HOST="$2"; shift 2 ;;
    --db-name)           DB_NAME="$2"; shift 2 ;;
    --db-user)           DB_USER="$2"; shift 2 ;;
    --db-password)       DB_PASSWORD="$2"; shift 2 ;;
    --mysql-root-password) MYSQL_ROOT_PASSWORD="$2"; shift 2 ;;
    --no-nginx)          DO_NGINX=0; shift ;;
    --no-cert)           DO_CERT=0; shift ;;
    --no-pm2)            DO_PM2=0; shift ;;
    -h|--help)           usage ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
done

[[ -d "$SOURCE_DIR" ]] || die "relay source not found at $SOURCE_DIR — run from the repo checkout"

if [[ "$IN_PLACE" == 1 ]]; then
  INSTALL_DIR="$SOURCE_DIR"
fi
if [[ "$DO_CERT" == 1 && -n "$DOMAIN" && -z "$EMAIL" ]]; then
  die "--domain requires --email (Let's Encrypt contact)"
fi
IS_REMOTE_DB=0
if [[ "$DB_HOST" != "127.0.0.1" && "$DB_HOST" != "localhost" ]]; then
  IS_REMOTE_DB=1
  [[ -n "$MYSQL_ROOT_PASSWORD" ]] || die "remote --db-host requires --mysql-root-password"
fi
if [[ -z "$DB_PASSWORD" ]]; then
  DB_PASSWORD="$(openssl rand -hex 16)"
fi
if [[ -z "$DOMAIN" && "$DO_NGINX" == 1 ]]; then
  warn "no --domain given — nginx will serve plain HTTP on port 80 (TLS skipped)"
fi

# Only sudo-required steps use sudo; npm/pm2 run as the invoking user so PM2
# keeps a per-user daemon. If run via sudo, target the real user.
RUNTIME_USER="${SUDO_USER:-$USER}"
RUNTIME_HOME="$(eval echo "~$RUNTIME_USER")"

# ── 1. system dependencies ─────────────────────────────────────────────────
need_cmd() { command -v "$1" >/dev/null 2>&1 || return 1; }

install_system_deps() {
  log "installing system dependencies"
  sudo apt-get update -y -qq
  sudo apt-get install -y -qq curl rsync openssl mysql-client >/dev/null

  # MySQL server only when the relay should use a LOCAL database
  if [[ "$IS_REMOTE_DB" == 0 ]] && ! need_cmd mysqld && ! need_cmd mysql; then
    log "installing mysql-server (local relay DB)"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mysql-server >/dev/null
    sudo systemctl enable --now mysql >/dev/null 2>&1 || sudo service mysql start >/dev/null 2>&1 || true
  fi

  # Node 18+ (relay engines requirement) — NodeSource on Debian/Ubuntu
  if ! need_cmd node || [[ "$(node -v | tr -d 'v' | cut -d. -f1)" -lt 18 ]]; then
    log "installing Node.js 20 via NodeSource"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - >/dev/null
    sudo apt-get install -y -qq nodejs >/dev/null
  fi

  if [[ "$DO_NGINX" == 1 ]] && ! need_cmd nginx; then
    log "installing nginx"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx >/dev/null
  fi
  if [[ "$DO_NGINX" == 1 && "$DO_CERT" == 1 && -n "$DOMAIN" ]] && ! need_cmd certbot; then
    log "installing certbot + nginx plugin"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq certbot python3-certbot-nginx >/dev/null
  fi
}

# ── 2. copy source + install deps ───────────────────────────────────────────
install_source() {
  if [[ "$IN_PLACE" == 1 ]]; then
    log "in-place install (source already at $INSTALL_DIR)"
  else
    log "copying relay source to $INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR"
    # Keep the checkout pristine: exclude node_modules, .env, and test files.
    sudo rsync -a --exclude node_modules --exclude .env --exclude '*.test.js' "$SOURCE_DIR/" "$INSTALL_DIR/"
    sudo chown -R "$RUNTIME_USER":"$RUNTIME_USER" "$INSTALL_DIR"
  fi

  log "installing production dependencies (npm ci --omit=dev)"
  (
    cd "$INSTALL_DIR"
    if [[ -f package-lock.json ]]; then
      npm ci --omit=dev --no-audit --no-fund >/dev/null 2>&1 || npm install --omit=dev --no-audit --no-fund >/dev/null
    else
      npm install --omit=dev --no-audit --no-fund >/dev/null
    fi
  )
}

# ── 3. .env generation (never clobber) ─────────────────────────────────────
set_env() { # set_env KEY VALUE — replaces ^KEY=… or appends
  local key="$1" val="$2" f="$INSTALL_DIR/.env"
  if ! grep -q "^${key}=" "$f" 2>/dev/null; then
    printf '%s=%s\n' "$key" "$val" >> "$f"
  else
    sed -i.bak "s|^${key}=.*|${key}=${val}|" "$f" && rm -f "$f.bak"
  fi
}

generate_env() {
  local f="$INSTALL_DIR/.env"
  if [[ -f "$f" ]]; then
    warn "$f exists — keeping it (missing keys will be appended)"
  else
    if [[ -f "$INSTALL_DIR/.env.example" ]]; then
      cp "$INSTALL_DIR/.env.example" "$f"
    else
      : > "$f"
    fi
    chown "$RUNTIME_USER":"$RUNTIME_USER" "$f" 2>/dev/null || true
  fi
  set_env RELAY_PORT             "$RELAY_PORT"
  set_env RELAY_DB_HOST          "$DB_HOST"
  set_env RELAY_DB_NAME          "$DB_NAME"
  set_env RELAY_DB_USER          "$DB_USER"
  set_env RELAY_DB_PASSWORD      "$DB_PASSWORD"
  set_env RELAY_SUPER_ADMIN_KEY  "$(openssl rand -hex 32)"
  set_env NODE_ENV               "production"
  chmod 600 "$f"
}

# ── 4. MySQL database + dedicated user ─────────────────────────────────────
provision_db() {
  log "provisioning database $DB_NAME (user $DB_USER)"
  local root_args=()
  if [[ "$IS_REMOTE_DB" == 1 ]]; then
    root_args=(-h "$DB_HOST" -u root -p"$MYSQL_ROOT_PASSWORD")
  fi
  sudo mysql "${root_args[@]}" <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
ALTER USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
SQL
  log "schema is auto-created by the relay on first boot (CREATE TABLE IF NOT EXISTS)"
}

# ── 5. PM2 ecosystem ───────────────────────────────────────────────────────
write_ecosystem() {
  cat > "$INSTALL_DIR/ecosystem.config.js" <<EOF
// Generated by deploy/relay-install.sh — manages ONLY the relay process.
// (The hospital backend is a separate app; add it here if it shares this box.)
module.exports = {
  apps: [
    {
      name: 'mylikita-relay',
      cwd: '$INSTALL_DIR',
      script: 'app.js',
      instances: 1,
      autorestart: true,
      max_memory_restart: '300M',
      env: { NODE_ENV: 'production' },
    },
  ],
};
EOF
  chown "$RUNTIME_USER":"$RUNTIME_USER" "$INSTALL_DIR/ecosystem.config.js" 2>/dev/null || true
}

setup_pm2() {
  log "installing pm2 (global)"
  sudo npm install -g pm2 >/dev/null
  write_ecosystem
  log "starting relay under pm2"
  sudo -u "$RUNTIME_USER" -H bash -lc "export PATH=\$PATH:$(npm prefix -g)/bin; pm2 startOrReload '$INSTALL_DIR/ecosystem.config.js' --update-env >/dev/null && pm2 save >/dev/null" || {
    warn "pm2 start as $RUNTIME_USER failed — trying as $USER"
    pm2 startOrReload "$INSTALL_DIR/ecosystem.config.js" --update-env >/dev/null
    pm2 save >/dev/null
  }
  log "configuring pm2 to survive reboots"
  # pm2 startup prints a systemd enable line; run it for the real user.
  sudo -u "$RUNTIME_USER" -H bash -lc "export PATH=\$PATH:$(npm prefix -g)/bin; pm2 startup systemd -u '$RUNTIME_USER' --hp '$RUNTIME_HOME' >/dev/null" || \
    warn "pm2 startup failed — run 'pm2 startup' manually after install"
}

# ── 6. nginx ───────────────────────────────────────────────────────────────
write_nginx() {
  local conf="/etc/nginx/sites-available/mylikita-relay"
  log "writing nginx config: $conf"
  if [[ -n "$DOMAIN" ]]; then
    cat > /tmp/mylikita-relay.nginx <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$RELAY_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto \$scheme;   # booking pages build their own URL from this
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_read_timeout 60s;
    }
}
EOF
  else
    cat > /tmp/mylikita-relay.nginx <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:$RELAY_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_read_timeout 60s;
    }
}
EOF
  fi
  sudo cp /tmp/mylikita-relay.nginx "$conf"
  sudo ln -sf "$conf" /etc/nginx/sites-enabled/mylikita-relay
  sudo nginx -t && sudo systemctl reload nginx || warn "nginx config at $conf needs attention (nginx -t failed)"
}

setup_certbot() {
  [[ "$DO_NGINX" == 1 && "$DO_CERT" == 1 && -n "$DOMAIN" ]] || return 0
  log "requesting Let's Encrypt certificate for $DOMAIN"
  if sudo certbot --nginx -d "$DOMAIN" -m "$EMAIL" --agree-tos --non-interactive --redirect >/dev/null 2>&1; then
    log "TLS configured — https://$DOMAIN"
  else
    warn "certbot failed — run manually: sudo certbot --nginx -d $DOMAIN -m $EMAIL --agree-tos --redirect"
  fi
}

# ── 7. health check + summary ──────────────────────────────────────────────
wait_for_health() {
  log "waiting for relay health endpoint"
  for _ in $(seq 1 20); do
    if curl -fsS "http://127.0.0.1:$RELAY_PORT/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  warn "relay did not answer /health on :$RELAY_PORT — check logs: pm2 logs mylikita-relay"
}

print_summary() {
  local opkey dbpass
  opkey="$(grep -E '^RELAY_SUPER_ADMIN_KEY=' "$INSTALL_DIR/.env" | cut -d= -f2-)"
  dbpass="$(grep -E '^RELAY_DB_PASSWORD=' "$INSTALL_DIR/.env" | cut -d= -f2-)"
  local base="http://127.0.0.1:$RELAY_PORT"
  [[ -n "$DOMAIN" ]] && base="https://$DOMAIN"
  cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 MyLikita Relay installed — summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Install dir      : $INSTALL_DIR
  Public base URL  : $base
  Health check     : $base/health
  DB               : $DB_NAME (user: $DB_USER @ $DB_HOST)
  PM2 app          : mylikita-relay   (pm2 status)

  SECRETS (stored in $INSTALL_DIR/.env — keep it safe):
    RELAY_SUPER_ADMIN_KEY = $opkey
    RELAY_DB_PASSWORD     = $dbpass

 NEXT STEPS
  1. Register a facility (returns sync_key + website_key once):
       curl -X POST $base/v1/facilities/register \\
         -H "Authorization: Bearer $opkey" \\
         -H "Content-Type: application/json" \\
         -d '{"facility_id":"FAC-001","name":"Clinic Name","website_domain":"https://clinic.example.com"}'
  2. Paste the two keys into that hospital's Settings → Website Booking
     Relay card (or its .env), then enable the hosted booking page.
  3. Full operational guide: backend/relay/DEPLOY.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# ── run ────────────────────────────────────────────────────────────────────
install_system_deps
install_source
generate_env
provision_db
if [[ "$DO_PM2" == 1 ]]; then
  setup_pm2
else
  warn "--no-pm2 — start manually: (cd $INSTALL_DIR && node app.js)"
fi
if [[ "$DO_NGINX" == 1 ]]; then
  write_nginx
  setup_certbot
fi
if [[ "$DO_PM2" == 1 ]]; then
  wait_for_health
else
  warn "skipping health wait (--no-pm2)"
fi
print_summary
log "done."
