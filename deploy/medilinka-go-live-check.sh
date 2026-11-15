#!/usr/bin/env bash
#
# MediLinka go-live acceptance check.
#
# Runs the machine-checkable half of the go-live criteria against a DEPLOYED
# host (no repo checkout needed), then prints the doctor/patient walkthrough for
# a human to confirm the half that needs eyes and a phone.
#
# Usage:
#   ./medilinka-go-live-check.sh                      # defaults to production
#   HOST=https://stage.example.com \
#   HMS=https://hms.stage.example.com \
#   API=https://api.stage.example.com \
#     ./medilinka-go-live-check.sh
#
# Optional, for the authenticated doctor checks:
#   DOCTOR_USER='dr.bello' DOCTOR_PASS='…' ./medilinka-go-live-check.sh
#   (performs one normal staff login — it creates a real session row)
#
# Variables:
#   HOST         MediLinka origin under test         (default https://medilinka.mylikita.com)
#   HMS          the hospital origin to compare with (default https://app.mylikita.com, "" to skip)
#   API          the API origin the bundle talks to  (default: same as HOST)
#   LINK_HOST    origin patient links must open on   (default: same as HOST — the backend's
#                MEDILINKA_URL; set it if MEDILINKA_URL points somewhere else)
#   DOCTOR_USER  staff username/email for the optional authenticated checks
#   DOCTOR_PASS  that account's password
#   TIMEOUT      per-request timeout in seconds      (default 15)
#   WALKTHROUGH  1 to print the manual checklist, 0 to skip (default 1)
#
# Exit status: 0 when every automated check passed, 1 otherwise. Skipped checks
# do not fail the run — they are reported, never counted as passes.
#
# The production-HTTP-shape checks are SKIPPED automatically when HOST is an
# http:// URL, so the same script can smoke-test a local server.

set -u

HOST="${HOST:-https://medilinka.mylikita.com}"
HMS="${HMS-https://app.mylikita.com}"   # HMS='' skips the hospital comparisons
API="${API:-}"
LINK_HOST="${LINK_HOST:-}"
DOCTOR_USER="${DOCTOR_USER:-}"
DOCTOR_PASS="${DOCTOR_PASS:-}"
TIMEOUT="${TIMEOUT:-15}"
WALKTHROUGH="${WALKTHROUGH:-1}"

case "$HOST" in
  http://*) IS_TLS=0 ;;
  *)        IS_TLS=1 ;;
esac
[ -z "$API" ] && API="$HOST"
[ -z "$LINK_HOST" ] && LINK_HOST="$HOST"

PASS=0
FAIL=0
SKIP=0

if [ -t 1 ]; then C_OK=$'\033[32m'; C_BAD=$'\033[31m'; C_OFF=$'\033[0m'; else C_OK=''; C_BAD=''; C_OFF=''; fi

pass() { PASS=$((PASS + 1)); printf '%s[PASS]%s %s%s\n' "$C_OK" "$C_OFF" "$1" "${2:+ — $2}"; }
fail() { FAIL=$((FAIL + 1)); printf '%s[FAIL]%s %s%s\n' "$C_BAD" "$C_OFF" "$1" "${2:+ — $2}"; }
skip() { SKIP=$((SKIP + 1)); printf '[SKIP] %s%s\n' "$1" "${2:+ — $2}"; }
section() { printf '\n== %s ==\n' "$1"; }

TMP="$(mktemp -d)" || exit 1
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

BODY="$TMP/body"
HDRS="$TMP/headers"
ERR="$TMP/err"
STATUS=000
CURL_ERR=''

status_in() { # "400 401 422"
  local s
  for s in $1; do [ "$STATUS" = "$s" ] && return 0; done
  return 1
}

body_has() { grep -qi -- "$1" "$BODY"; }
# True when the response is the SPA shell rather than an API answer — the tell
# that a public API path is not proxied and index.html answered instead.
shell_answered() { grep -qiE '<div id="root"|<!doctype html' "$BODY"; }

# method url [json] → $STATUS + $BODY
request() {
  local method="$1" url="$2" data="${3:-}"
  : >"$ERR"
  if [ -n "$data" ]; then
    STATUS=$(curl -sS -o "$BODY" -w '%{http_code}' --max-time "$TIMEOUT" \
      -X "$method" -H 'Content-Type: application/json' -d "$data" "$url" 2>"$ERR") || STATUS=000
  else
    STATUS=$(curl -sS -o "$BODY" -w '%{http_code}' --max-time "$TIMEOUT" \
      -X "$method" "$url" 2>"$ERR") || STATUS=000
  fi
  CURL_ERR="$(tr '\n' ' ' <"$ERR" | cut -c1-160)"
}

# url [HEAD|GET] → $STATUS + $HDRS
headers_for() {
  local url="$1" method="${2:-HEAD}"
  : >"$ERR"
  if [ "$method" = "GET" ]; then
    STATUS=$(curl -sS -D "$HDRS" -o /dev/null -w '%{http_code}' --max-time "$TIMEOUT" "$url" 2>"$ERR") || STATUS=000
  else
    STATUS=$(curl -sS -I -D "$HDRS" -o /dev/null -w '%{http_code}' --max-time "$TIMEOUT" "$url" 2>"$ERR") || STATUS=000
  fi
  CURL_ERR="$(tr '\n' ' ' <"$ERR" | cut -c1-160)"
}

build_id_of() { # url
  request GET "$1"
  [ "$STATUS" = "200" ] || return 1
  tr -d '\n' <"$BODY" | sed -n 's/.*"build"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

printf 'MediLinka go-live acceptance check\n'
printf '  host      %s\n' "$HOST"
printf '  hospital  %s\n' "${HMS:-<skipped>}"
printf '  api       %s\n' "$API"
printf '  links     %s\n' "$LINK_HOST"

# ── 1. The shell ─────────────────────────────────────────────────────────────
section 'Shell and routing'

request GET "$HOST/"
if [ "$STATUS" = "200" ] && body_has 'MediLinka'; then
  pass 'landing renders' '200 and mentions MediLinka'
elif [ "$STATUS" = "200" ]; then
  fail 'landing renders' '200 but the body never says MediLinka — HMS surface? (VITE_MEDILINKA_HOSTS missing?)'
else
  fail 'landing renders' "status=$STATUS ${CURL_ERR}"
fi

request GET "$HOST/signup/doctor"
if [ "$STATUS" = "200" ]; then
  pass 'SPA deep link' '/signup/doctor returns the shell'
else
  fail 'SPA deep link' "status=$STATUS (missing try_files … /index.html?) ${CURL_ERR}"
fi

request GET "$HOST/version.json"
BUILD_HOST=''
if [ "$STATUS" = "200" ] && body_has '"build"'; then
  BUILD_HOST="$(tr -d '\n' <"$BODY" | sed -n 's/.*"build"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  pass 'build stamp' "build=$BUILD_HOST"
elif shell_answered; then
  fail 'build stamp' 'the SPA shell answered — dist/version.json is missing from this deploy'
else
  fail 'build stamp' "status=$STATUS (is dist/version.json deployed?)"
fi

request GET "$HOST/manifest.medilinka.json"
if [ "$STATUS" = "200" ] && body_has '"MediLinka"'; then
  pass 'MediLinka manifest' 'served and named MediLinka'
else
  fail 'MediLinka manifest' "status=$STATUS"
fi

# ── 2. HTTP → HTTPS and TLS ──────────────────────────────────────────────────
section 'TLS and redirect'

if [ "$IS_TLS" -eq 0 ]; then
  skip 'HTTP → HTTPS redirect' 'HOST is http:// (local smoke test)'
  skip 'certificate expiry' 'HOST is http://'
else
  PLAIN="http://${HOST#https://}"
  headers_for "$PLAIN/" HEAD
  case "$STATUS" in
    301|302|307|308)
      if grep -qi '^location:[[:space:]]*https://' "$HDRS"; then
        pass 'HTTP → HTTPS redirect' "status=$STATUS to HTTPS"
      else
        fail 'HTTP → HTTPS redirect' "status=$STATUS but Location is not https"
      fi
      ;;
    *) fail 'HTTP → HTTPS redirect' "status=$STATUS (expected 301/308) ${CURL_ERR}" ;;
  esac

  if command -v openssl >/dev/null 2>&1; then
    HOSTPORT="${HOST#https://}"
    EXPIRY="$(echo | openssl s_client -servername "$HOSTPORT" -connect "$HOSTPORT:443" 2>/dev/null \
      | openssl x509 -noout -enddate 2>/dev/null | sed 's/^notAfter=//')"
    EPOCH=''
    if [ -n "$EXPIRY" ]; then
      EPOCH="$(date -d "$EXPIRY" +%s 2>/dev/null || date -j -f '%b %d %T %Y %Z' "$EXPIRY" +%s 2>/dev/null || true)"
    fi
    if [ -n "$EPOCH" ]; then
      DAYS=$(( (EPOCH - $(date +%s)) / 86400 ))
      if [ "$DAYS" -ge 14 ]; then
        pass 'certificate expiry' "${DAYS} days left"
      elif [ "$DAYS" -gt 0 ]; then
        fail 'certificate expiry' "only ${DAYS} days left"
      else
        fail 'certificate expiry' "expired or unreadable ($EXPIRY)"
      fi
    else
      skip 'certificate expiry' 'could not read the certificate date'
    fi
  else
    skip 'certificate expiry' 'openssl not installed'
  fi
fi

# ── 3. Cache headers ─────────────────────────────────────────────────────────
section 'Cache headers'

headers_for "$HOST/index.html" GET
if [ "$STATUS" = "200" ] && grep -qi '^cache-control:.*no-cache' "$HDRS"; then
  pass 'index.html no-cache' ''
else
  fail 'index.html no-cache' "status=$STATUS (a cached shell pins users to the old build)"
fi

headers_for "$HOST/sw.js" GET
if [ "$STATUS" = "200" ] && grep -qi '^cache-control:.*no-cache' "$HDRS"; then
  pass 'sw.js no-cache' ''
else
  fail 'sw.js no-cache' "status=$STATUS"
fi

headers_for "$HOST/version.json" GET
if [ "$STATUS" = "200" ] && grep -qi '^cache-control:.*no-cache' "$HDRS"; then
  pass 'version.json no-cache' ''
else
  fail 'version.json no-cache' "status=$STATUS (the UpdateBanner polls this)"
fi

request GET "$HOST/"
ASSET="$(grep -o '/assets/[^"]*\.js' "$BODY" | head -1)"
if [ -z "$ASSET" ]; then
  skip 'hashed asset immutable' 'no /assets/*.js in the shell (dev server?)'
else
  headers_for "$HOST$ASSET" GET
  if [ "$STATUS" = "200" ] && grep -qi '^cache-control:.*immutable' "$HDRS"; then
    pass 'hashed asset immutable' "$ASSET"
  else
    fail 'hashed asset immutable' "$ASSET status=$STATUS"
  fi
fi

# ── 4. API reachability from this origin ─────────────────────────────────────
section 'API, CORS and realtime'

request POST "$API/auth/login" '{}'
if status_in '400 401 422 429'; then
  pass 'staff API reachable' "POST /auth/login → $STATUS"
elif [ "$STATUS" = "404" ]; then
  fail 'staff API reachable' '404 — wrong API origin, or a static host with no proxy for the root /auth path'
else
  fail 'staff API reachable' "status=$STATUS ${CURL_ERR}"
fi

: >"$ERR"
STATUS=$(curl -sS -o "$BODY" -D "$HDRS" -w '%{http_code}' --max-time "$TIMEOUT" -X OPTIONS \
  -H "Origin: $HOST" \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type' \
  "$API/auth/login" 2>"$ERR") || STATUS=000
CURL_ERR="$(tr '\n' ' ' <"$ERR" | cut -c1-160)"
if status_in '200 204' && grep -i '^access-control-allow-origin:' "$HDRS" | grep -qF "$HOST"; then
  pass 'CORS preflight' "allows $HOST"
elif status_in '200 204'; then
  fail 'CORS preflight' "answered $STATUS but did not echo $HOST in Access-Control-Allow-Origin"
else
  fail 'CORS preflight' "status=$STATUS (is this origin in ALLOWED_ORIGINS?) ${CURL_ERR}"
fi

request GET "$API/socket.io/?EIO=4&transport=polling"
if [ "$STATUS" = "200" ] && grep -q '^0{' "$BODY"; then
  pass 'socket.io handshake' 'engine.io polling handshake returned'
elif [ "$STATUS" = "404" ]; then
  fail 'socket.io handshake' '404 — realtime not served/proxied here (no ring, no live queue)'
else
  fail 'socket.io handshake' "status=$STATUS ${CURL_ERR}"
fi

# ── 5. Patient link origins ──────────────────────────────────────────────────
section 'Patient links (the two public routes letters and reminders use)'

request GET "$LINK_HOST/api/patient/letters/not-a-real-token"
if [ "$STATUS" = "410" ]; then
  pass 'letter link host' 'invalid token → 410 from the app'
elif [ "$STATUS" = "404" ]; then
  fail 'letter link host' "404 — $LINK_HOST does not serve /api/patient/letters (proxy missing, or MEDILINKA_URL is wrong)"
elif shell_answered; then
  fail 'letter link host' "$LINK_HOST answered with the SPA shell — /api/patient/letters is not routed to the backend there"
else
  fail 'letter link host' "status=$STATUS (expected 410 for an invalid token) ${CURL_ERR}"
fi

request GET "$LINK_HOST/appointments/public/confirm/not-a-real-token"
if [ "$STATUS" = "400" ]; then
  pass 'confirmation link host' 'invalid token → 400 from the app'
elif [ "$STATUS" = "404" ]; then
  fail 'confirmation link host' "404 — $LINK_HOST does not serve /appointments/public/confirm"
elif shell_answered; then
  fail 'confirmation link host' "$LINK_HOST answered with the SPA shell — /appointments/public/confirm is not routed to the backend there"
else
  fail 'confirmation link host' "status=$STATUS (expected 400 for an invalid token) ${CURL_ERR}"
fi

# ── 6. Same build on both hosts ──────────────────────────────────────────────
section 'Build consistency'

if [ -z "$HMS" ]; then
  skip 'same build as the hospital host' 'HMS is empty'
  skip 'hospital landing unchanged' 'HMS is empty'
else
  HMS_BUILD="$(build_id_of "$HMS/version.json" || true)"
  if [ -z "$HMS_BUILD" ]; then
    fail 'same build as the hospital host' "$HMS/version.json unreadable (status=$STATUS)"
  elif [ -n "$BUILD_HOST" ] && [ "$HMS_BUILD" = "$BUILD_HOST" ]; then
    pass 'same build as the hospital host' "both $BUILD_HOST"
  else
    fail 'same build as the hospital host' "MediLinka=${BUILD_HOST:-?} HMS=$HMS_BUILD — the two products have drifted"
  fi

  request GET "$HMS/"
  if [ "$STATUS" = "200" ] && ! body_has 'MediLinka'; then
    pass 'hospital landing unchanged' '200 and still the HMS front door'
  elif [ "$STATUS" = "200" ]; then
    fail 'hospital landing unchanged' '200 but the body mentions MediLinka — surface resolution is wrong on the HMS host'
  else
    fail 'hospital landing unchanged' "status=$STATUS ${CURL_ERR}"
  fi
fi

# ── 7. Authenticated doctor checks (optional) ────────────────────────────────
section 'Doctor workspace (optional, needs DOCTOR_USER/DOCTOR_PASS)'

if [ -z "$DOCTOR_USER" ] || [ -z "$DOCTOR_PASS" ]; then
  skip 'doctor login' 'set DOCTOR_USER and DOCTOR_PASS to enable'
  skip 'telemedicine profile' 'set DOCTOR_USER and DOCTOR_PASS to enable'
else
  PAYLOAD="$(printf '{"username":"%s","password":"%s"}' "$DOCTOR_USER" "$DOCTOR_PASS")"
  request POST "$API/auth/login" "$PAYLOAD"
  TOKEN=''
  if [ "$STATUS" = "200" ]; then
    TOKEN="$(tr -d '\n' <"$BODY" | sed -n 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  fi
  if [ -n "$TOKEN" ]; then
    pass 'doctor login' "$DOCTOR_USER authenticated"
  else
    fail 'doctor login' "status=$STATUS (no token) ${CURL_ERR}"
  fi

  if [ -n "$TOKEN" ]; then
    with_token() { # url → $STATUS + $BODY
      : >"$ERR"
      STATUS=$(curl -sS -o "$BODY" -w '%{http_code}' --max-time "$TIMEOUT" \
        -H "Authorization: Bearer $TOKEN" "$1" 2>"$ERR") || STATUS=000
      CURL_ERR="$(tr '\n' ' ' <"$ERR" | cut -c1-160)"
    }

    # The workspace calls this against the API base; try the mounted shape and
    # the prefix-stripped shape so the check reports which one this host uses.
    with_token "$API/api/telemedicine/me/profile"
    SHAPE='/api/telemedicine/me/profile'
    if [ "$STATUS" = "404" ]; then
      with_token "$API/telemedicine/me/profile"
      SHAPE='/telemedicine/me/profile'
    fi

    if [ "$STATUS" = "200" ] && body_has 'verificationStatus'; then
      pass 'telemedicine profile' "$SHAPE served the practice profile"
    elif status_in '401 403'; then
      fail 'telemedicine profile' "$SHAPE → $STATUS (account lacks the Telemedicine module?)"
    else
      fail 'telemedicine profile' "status=$STATUS ${CURL_ERR}"
    fi
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────────────
printf '\nResult: %d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
if [ "$FAIL" -ne 0 ]; then
  printf '%sAutomated checks FAILED.%s Fix these before the manual walkthrough.\n' "$C_BAD" "$C_OFF"
fi

if [ "$WALKTHROUGH" != "0" ]; then
  cat <<'WALK'

== Manual walkthrough (not automated — needs a browser and a phone) ==

Doctor
  [ ] MediLinka landing: teal, Patient/Doctor tabs, "Hospital management system" link
  [ ] Doctor tab → sign in → lands on /me/telemedicine (Today panel)
      · navbar is teal and reads "Practice" (and "Settings") with a MediLinka chip
      · no hospital Dashboard link, no notification bell
  [ ] Hard-refresh on /me/telemedicine → stays there and Today reloads
  [ ] Practice tab: add a consulting window and save; the fee is already set
  [ ] Visits tab: the booked video visit is listed with its triage summary

Patient (second browser profile or a phone; use a test patient number)
  [ ] / → Patient → "Create an account" → phone OTP completes
  [ ] Book a video visit with the practice doctor → pay (sandbox card)
  [ ] Waiting room opens and shows the doctor's name
  [ ] Join video visit → camera/mic prompt → doctor is in the room

Consultation (both devices)
  [ ] Doctor sees the patient as Waiting, then Live in Visits
  [ ] Doctor can mute the patient; the patient cannot mute the doctor
  [ ] Consult tab: notes + a prescription save; "send to patient" reports delivered
  [ ] The letter link the patient receives opens on the MediLinka origin
      (not app.mylikita.com) — this is the patientLinkOrigin change
  [ ] End the call from the doctor: both sides return cleanly, no stuck spinner
  [ ] Patient portal: visit summary shows the doctor's name and the letter

Realtime and edge cases
  [ ] Book a visit due now; the "visit is starting" ring appears for the doctor
  [ ] Open /me/hr, /me/appointments, /me/report directly as the practice doctor →
      hospital modules should not render (known gap if they do)
  [ ] DevTools console: no CORS errors, no mixed content, no 404 on /socket.io/
  [ ] Application → Manifest: name "MediLinka", theme #0f766e
  [ ] https://app.mylikita.com/ unchanged for hospital staff
  [ ] Sign out on MediLinka; the HMS origin's own session is unaffected
      (sessions are per origin — expected, not a bug)
WALK
fi

[ "$FAIL" -eq 0 ]
