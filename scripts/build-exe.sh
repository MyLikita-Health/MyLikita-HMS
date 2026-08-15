#!/usr/bin/env bash
# =============================================================================
# build-exe.sh — build the MyLikita Windows installer (.exe) from the CURRENT
# codebase, using the local Parallels "Windows 11" VM as the Windows build box.
#
# WHY A VM: the real builder (deploy/windows-installer/build-installer.bat)
# must run on 64-bit Windows with Inno Setup 6 installed, because ISCC.exe is
# Windows-only and the bundled Node / MySQL / NSSM runtimes are Windows
# binaries. This script makes the VM a transparent build machine:
#
#   1. packs the current source (backend + frontend + deploy + booking widget)
#   2. ships it into the VM over the Parallels NAT
#   3. runs build-installer.bat in the guest (detached, polled to completion)
#   4. fetches the finished .exe + bundle-manifest.json back to this Mac
#
# Hard-won lessons encoded here (all hit during the v0.1.x installer work):
#   - the bat ends with `pause` unless CI=1 is set; a paused cmd holds the
#     build log open and silently kills every re-run that reuses the file
#   - stale dist/ trees poison builds; every run uses a FRESH guest dir
#   - the bat trusts cached runtime zips, so a truncated download breaks
#     extraction; a fresh dir per build avoids reusing garbage
#   - fresh Windows machines lack the VC++ runtime (kills mysqld with
#     0xC0000135 — the blank-page saga); if deploy/windows-installer/vcrt/
#     has the redistributable DLLs the bat bundles them next to the exes
#   - guest npm installs die with ECONNRESET on slow networks; node_modules
#     are cached between builds so installs become fast no-ops
#
# PREREQUISITES (one-time, already done on this machine):
#   - Parallels Desktop with a "Windows 11" VM
#   - Inno Setup 6 installed INSIDE the VM
#     (https://jrsoftware.org/isinfo.php → run its installer in the VM)
#
# USAGE:
#   ./scripts/build-exe.sh                       # version from newest git tag (or 1.0.0)
#   MYLIKITA_VERSION=1.2.3 ./scripts/build-exe.sh
#   MYLIKITA_VM="Windows 11"   ./scripts/build-exe.sh   # different VM name
#
# OUTPUT:
#   deploy/windows-installer/dist/output/MyLikita-Setup-<version>.exe
#   deploy/windows-installer/dist/output/bundle-manifest.json
#
# The produced .exe is fully self-contained: install on a CLEAN Windows
# machine, then verify http://localhost:46990/ shows the login page.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------- config ----
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRLCTL="/Applications/Parallels Desktop.app/Contents/MacOS/prlctl"
VM_NAME="${MYLIKITA_VM:-Windows 11}"
VERSION="${MYLIKITA_VERSION:-$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null || echo 1.0.0)}"
STAMP="$(date +%Y%m%d-%H%M%S)"
WORK="$(mktemp -d /tmp/mylikita-build.XXXXXX)"
ZIP="$WORK/mylikita-src.zip"
HOST_PORT=""  # picked on a free port in phase 2 (8910 has been squatted on)
HOST_OUT="$REPO_ROOT/deploy/windows-installer/dist/output"
# NOTE: single backslashes on purpose — these strings go through cmd /c and
# (where quoted) through PowerShell single quotes, where \\ is literal.
GUEST_ROOT="C:\mylikita-builds\\$STAMP"
GUEST_SRC="$GUEST_ROOT\\src"
GUEST_LOG="$GUEST_ROOT\\build.log"
GUEST_NPM_CACHE="C:\mylikita-npmcache"
BUILD_TIMEOUT="${MYLIKITA_BUILD_TIMEOUT:-2700}"   # 45 min default
POLL_EVERY=45

# --------------------------------------------------------------- helpers ----
say()  { printf '\n\033[1;34m== %s ==\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

guest() { "$PRLCTL" exec "$VM_NAME" cmd /c "$@"; }

usage() {
  sed -n '2,60p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage

on_exit() {
  # best-effort cleanup: stop the host HTTP server + output receiver and
  # the scratch dir. (Guest-side servers die with the VM / next reboot.)
  pkill -f "http.server $HOST_PORT" >/dev/null 2>&1 || true
  pkill -f "receive-output.js" >/dev/null 2>&1 || true
  rm -rf "$WORK" || true
}
trap on_exit EXIT

# ------------------------------------------------------------- phase 0 -----
say "Prerequisites"

command -v "$PRLCTL" >/dev/null 2>&1 || die "Parallels prlctl not found at $PRLCTL — is Parallels Desktop installed?"

if ! "$PRLCTL" list --all 2>/dev/null | grep -q "$VM_NAME"; then
  die "No Parallels VM named '$VM_NAME' found. Set MYLIKITA_VM to your VM's name."
fi
ok "VM '$VM_NAME' exists"

# start the VM if it is stopped, and wait until we can exec into it.
# The ~5 GB host-disk guard only applies when the VM has to START; an
# already-running VM doesn't need that headroom, so a full-ish host is a
# warning (build may fail late) rather than a hard stop.
STATE=$("$PRLCTL" list 2>/dev/null | grep "$VM_NAME" | awk '{print $2}')
HOST_FREE_GB=$(df -k / | awk 'NR==2 {print int($4/1024/1024)}')
if [[ "$STATE" != "running" ]]; then
  if (( HOST_FREE_GB < 6 )); then
    die "Host disk is low (${HOST_FREE_GB} GB free). The VM needs ~5 GB to start. Free some space and re-run."
  fi
  ok "Host disk: ${HOST_FREE_GB} GB free"
  warn "VM is '$STATE' — starting it..."
  "$PRLCTL" start "$VM_NAME" >/dev/null 2>&1 || die "Could not start the VM (host disk full?)"
else
  if (( HOST_FREE_GB < 6 )); then
    warn "Host disk is only ${HOST_FREE_GB} GB free — VM is already running, proceeding anyway (guest build may fail if it needs more host space)."
  else
    ok "Host disk: ${HOST_FREE_GB} GB free"
  fi
fi
for i in $(seq 1 40); do
  if guest "echo up" >/dev/null 2>&1; then break; fi
  [[ $i -eq 40 ]] && die "VM did not become reachable within 2 minutes"
  sleep 3
done
ok "VM is up and prlctl exec works"

# ------------------------------------------------------------- phase 1 -----
say "Packing current source (version $VERSION)"

for d in backend frontend deploy packages; do
  [[ -d "$REPO_ROOT/$d" ]] || die "Expected $REPO_ROOT/$d — run this from the mylikita repo root."
done

# backend/frontend are git submodules; pack their working trees as plain
# folders (no .git needed) and exclude everything the build regenerates.
# vcrt/ IS shipped: the bat bundles those DLLs into the installer.
( cd "$REPO_ROOT" && zip -qr "$ZIP" backend frontend deploy packages \
    -x "*/node_modules/*" \
    -x "*/.git/*" \
    -x "*/dist/*" \
    -x "*/uploads/*" \
    -x "*/log/*" \
    -x "*.env" -x "*.env.*" ) \
  || die "Could not pack the source tree"

# the booking-widget dist is COMMITTED and required by the build, so restore
# it after the blanket dist/ exclusion above
( cd "$REPO_ROOT" && zip -qr "$ZIP" packages/booking-widget/dist ) \
  || die "Could not pack the booking-widget bundle"

ZIP_BYTES=$(stat -f%z "$ZIP")
ok "Source packed: $(echo "$ZIP_BYTES" | awk '{printf "%.0f MB", $1/1048576}')"

# ------------------------------------------------------------- phase 2 -----
say "Shipping source into the VM"

# host-side HTTP server (the guest pulls files from us). A fixed port is
# fragile: a stray server has squatted on 8910 here (serving /tmp) and
# silently 404'd every transfer. Use a random verified-free port instead.
printf 'probe' > "$WORK/host-ip-probe.txt"
for _ in $(seq 1 50); do
  p=$((20000 + RANDOM % 20000))
  if ! lsof -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1; then
    HOST_PORT="$p"
    break
  fi
done
[[ -n "$HOST_PORT" ]] || HOST_PORT=$((8910 + RANDOM % 1000))
(cd "$WORK" && python3 -m http.server "$HOST_PORT" --bind 0.0.0.0 >/dev/null 2>&1) &
sleep 1
curl -sf --max-time 5 "http://127.0.0.1:$HOST_PORT/host-ip-probe.txt" >/dev/null \
  || die "Host file server failed to bind on port $HOST_PORT (Address already in use?)"
ok "Host file server up on port $HOST_PORT"

# The host's IP as seen from the guest. The Parallels NAT default gateway
# is USUALLY the host, but on some network layouts the gateway is the NAT
# router (10.211.55.1) while the host itself sits at 10.211.55.2 — trusting
# ipconfig alone then sends every transfer into the void. Probe a tiny file
# from the guest against each candidate and take the first one that answers
# (-f so a 404 page can't masquerade as success).
HOST_IP=""
for cand in $(guest "ipconfig | findstr /i \"Default Gateway\"" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1) 10.211.55.2; do
  [[ -n "$cand" ]] || continue
  if guest "curl -sf -m 10 -o NUL http://$cand:$HOST_PORT/host-ip-probe.txt" >/dev/null 2>&1; then
    HOST_IP="$cand"
    break
  fi
done
[[ -n "$HOST_IP" ]] || die "Could not reach the host HTTP server from the guest (tried 10.211.55.1/10.211.55.2)"
ok "Host reachable from guest at $HOST_IP"

# one-time guest prerequisite: Inno Setup 6
if ! guest "if exist \"C:\Program Files (x86)\Inno Setup 6\ISCC.exe\" (echo ISCC_OK)" 2>/dev/null | grep -q ISCC_OK; then
  die "Inno Setup 6 is not installed in the VM. Install it (https://jrsoftware.org/isinfo.php) inside the VM and re-run."
fi
ok "Inno Setup 6 found in the guest"

GUEST_FREE_GB=$(guest "powershell -Command \"Write-Host ([math]::Round((Get-PSDrive C).Free/1GB,1))\"" 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)
if [[ -z "$GUEST_FREE_GB" || "$(echo "$GUEST_FREE_GB < 6" | bc -l 2>/dev/null || echo 1)" == "1" ]]; then
  warn "Guest free disk is only ${GUEST_FREE_GB} GB — the build needs ~6 GB. Proceeding anyway (may fail late)."
else
  ok "Guest disk: ${GUEST_FREE_GB} GB free"
fi

guest "if not exist \"$GUEST_ROOT\" mkdir \"$GUEST_ROOT\"" >/dev/null 2>&1
guest "curl -s -o \"$GUEST_ROOT\src.zip\" http://$HOST_IP:$HOST_PORT/mylikita-src.zip" \
  || die "Could not transfer the source zip into the VM"
ZIP_IN_GUEST=$(guest "powershell -Command \"(Get-Item '$GUEST_ROOT\src.zip').Length\"" 2>/dev/null | grep -oE '[0-9]+' | head -1)
if [[ "$ZIP_IN_GUEST" != "$ZIP_BYTES" ]]; then
  die "Transfer mismatch (guest got $ZIP_IN_GUEST bytes, expected $ZIP_BYTES). Network issue — re-run."
fi
ok "Source transferred ($ZIP_IN_GUEST bytes)"

guest "powershell -Command \"Expand-Archive -Path '$GUEST_ROOT\src.zip' -DestinationPath '$GUEST_SRC' -Force\"" \
  || die "Could not extract the source zip in the guest"
ok "Source extracted in the guest"

# restore cached node_modules (makes npm install a fast no-op on re-runs)
if guest "if exist \"$GUEST_NPM_CACHE\frontend\" (echo CACHED)" 2>/dev/null | grep -q CACHED; then
  guest "robocopy \"$GUEST_NPM_CACHE\frontend\" \"$GUEST_SRC\frontend\node_modules\" /E /NFL /NDL /NJH /NJS /NP >nul" >/dev/null 2>&1 || true
  guest "robocopy \"$GUEST_NPM_CACHE\backend\"  \"$GUEST_SRC\backend\node_modules\"  /E /NFL /NDL /NJH /NJS /NP >nul" >/dev/null 2>&1 || true
  ok "Restored cached node_modules (fast install)"
fi

# ------------------------------------------------------------- phase 3 -----
say "Launching the build in the guest (version $VERSION)"

cat > "$WORK/run-build.cmd" <<EOF
@echo off
setlocal EnableExtensions
cd /d "$GUEST_SRC\deploy\windows-installer"
set CI=1
set MYLIKITA_VERSION=$VERSION
set CYPRESS_INSTALL_BINARY=0
call build-installer.bat > "$GUEST_LOG" 2>&1
echo BUILD_EXIT=%errorlevel% >> "$GUEST_LOG"
EOF

guest "curl -s -o \"$GUEST_ROOT\run-build.cmd\" http://$HOST_IP:$HOST_PORT/run-build.cmd" || die "Could not ship the build runner"
guest "powershell -Command \"Start-Process -FilePath $GUEST_ROOT\run-build.cmd -WindowStyle Hidden\"" >/dev/null 2>&1 \
  || die "Could not launch the build in the guest"
ok "Build launched (guest log: $GUEST_LOG)"

# ------------------------------------------------------------- phase 4 -----
say "Polling the build (timeout ${BUILD_TIMEOUT}s, every ${POLL_EVERY}s)"

START=$SECONDS
LAST_LINE=""
while (( SECONDS - START < BUILD_TIMEOUT )); do
  sleep "$POLL_EVERY"
  if guest "findstr /b /c:\"BUILD_EXIT=\" \"$GUEST_LOG\"" >/dev/null 2>&1; then
    break
  fi
  TAIL=$(guest "powershell -Command \"Get-Content '$GUEST_LOG' -Tail 1\"" 2>/dev/null | tail -1 | tr -d '\r')
  if [[ -n "$TAIL" && "$TAIL" != "$LAST_LINE" ]]; then
    printf '  [%4ss] %s\n' "$((SECONDS-START))" "$TAIL"
    LAST_LINE="$TAIL"
  fi
done

BUILD_EXIT=$(guest "powershell -Command \"Select-String -Path '$GUEST_LOG' -Pattern '^BUILD_EXIT=' | Select-Object -Last 1 | ForEach-Object { \$_.Line }\"" 2>/dev/null | grep -oE '[0-9]+' | tail -1 || true)
if [[ -z "$BUILD_EXIT" ]]; then
  echo "  --- last 25 log lines ---"
  guest "powershell -Command \"Get-Content '$GUEST_LOG' -Tail 25\"" 2>/dev/null | tail -25
  die "Build did not finish within ${BUILD_TIMEOUT}s. See the guest log at $GUEST_LOG"
fi
if [[ "$BUILD_EXIT" != "0" ]]; then
  echo "  --- last 30 log lines ---"
  guest "powershell -Command \"Get-Content '$GUEST_LOG' -Tail 30\"" 2>/dev/null | tail -30
  die "Build failed (exit $BUILD_EXIT). See the guest log at $GUEST_LOG"
fi
ok "Build completed (exit 0) in $((SECONDS-START))s"

# ------------------------------------------------------------- phase 5 -----
say "Fetching the installer back to the Mac"

EXE="MyLikita-Setup-$VERSION.exe"
GUEST_EXE="$GUEST_SRC\\deploy\\windows-installer\\dist\\output\\$EXE"
GUEST_MANIFEST="$GUEST_SRC\\deploy\\windows-installer\\dist\\bundle-manifest.json"
mkdir -p "$HOST_OUT"

# The Parallels NAT here is one-way: the guest can reach the host, but the
# host cannot reach the guest — so pulling the built files via a guest-side
# file server (the old approach) times out. Instead the guest PUSHES them to
# a tiny receiver on the host, mirroring the direction that ships the source.
cat > "$WORK/receive-output.js" <<'EOF'
const http=require('http'),fs=require('fs'),path=require('path');
const dir=process.argv[2]||'.',port=parseInt(process.argv[3]||'9000',10);
http.createServer((req,res)=>{
  const f=path.join(dir,path.basename(req.url.split('?')[0]));
  const ws=fs.createWriteStream(f);
  req.pipe(ws);
  req.on('end',()=>{res.writeHead(200);res.end('saved '+f);console.log('saved '+f+' ('+fs.statSync(f).size+' bytes)');});
  ws.on('error',e=>{res.writeHead(500);res.end(String(e));});
}).listen(port,'0.0.0.0',()=>console.log('receiving on '+port));
EOF
RECV_PORT=$((25000 + RANDOM % 5000))
(node "$WORK/receive-output.js" "$HOST_OUT" "$RECV_PORT" >"$WORK/receive.log" 2>&1) &
sleep 1

guest "curl -s -m 900 -T \"$GUEST_EXE\" http://$HOST_IP:$RECV_PORT/$EXE" \
  || die "Could not push the installer to the host"
guest "curl -s -m 60 -T \"$GUEST_MANIFEST\" http://$HOST_IP:$RECV_PORT/bundle-manifest.json" \
  || warn "Could not push bundle-manifest.json"
EXE_BYTES=$(stat -f%z "$HOST_OUT/$EXE" 2>/dev/null || echo 0)
(( EXE_BYTES > 0 )) || die "Installer fetch produced an empty file"
ok "Installer fetched ($(echo "$EXE_BYTES" | awk '{printf "%.0f MB", $1/1048576}'))"

# refresh the node_modules cache for the next build (best-effort)
guest "robocopy \"$GUEST_SRC\frontend\node_modules\" \"$GUEST_NPM_CACHE\frontend\" /E /NFL /NDL /NJH /NJS /NP >nul" >/dev/null 2>&1 || true
guest "robocopy \"$GUEST_SRC\backend\node_modules\"  \"$GUEST_NPM_CACHE\backend\"  /E /NFL /NDL /NJH /NJS /NP >nul" >/dev/null 2>&1 || true

# ------------------------------------------------------------- summary -----
EXE_BYTES=$(stat -f%z "$HOST_OUT/$EXE" 2>/dev/null || echo 0)
cat <<EOF

==============================================
  BUILD COMPLETE — MyLikita v$VERSION
==============================================
  Installer : $HOST_OUT/$EXE
              ($(echo "$EXE_BYTES" | awk '{printf "%.0f MB", $1/1048576}'))
  Manifest  : $HOST_OUT/bundle-manifest.json

  Next steps:
  1. Install on a CLEAN Windows machine (double-click or
     MyLikita-Setup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART).
  2. Verify the login page at http://localhost:46990/ renders.
  3. Ship ONLY the .exe to clients — it is fully self-contained.
EOF
