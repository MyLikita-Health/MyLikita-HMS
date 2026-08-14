param(
    # URL of the SPA to boot. The login page (/auth) is used because it is the
    # first thing React renders for any staff member.
    [string]$Url = 'http://localhost:46990/auth',
    # How long to poll the server for HTTP 200 before giving up (the service
    # may still be starting when postinstall reaches this check).
    [int]$ServerPollSec = 90,
    # Real-time settle time handed to the CDP check after the page loads.
    [int]$SettleMs = 6000,
    # Overall budget for the boot (page load + render) before failing.
    [int]$TimeoutSec = 90,
    # Overrides for the Chromium binary / Node binary (used by dev machines
    # running the check outside the installed server; empty = auto-detect).
    [string]$BrowserPath = '',
    [string]$NodePath = ''
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$checkJs = Join-Path $here 'spa-boot-check.js'

if (-not (Test-Path $checkJs)) {
    Write-Output "[FAIL] spa-boot-check.js missing next to this script: $checkJs"
    exit 1
}

# --- locate Node: the installed server's embedded node first (postinstall
#     always has it), then whatever is on PATH (CI / dev machines).
$node = $null
if ($NodePath -and (Test-Path $NodePath)) {
    $node = $NodePath
} elseif (Test-Path 'C:\MyLikita\runtime\node\node.exe') {
    $node = 'C:\MyLikita\runtime\node\node.exe'
} else {
    $cmd = Get-Command node -ErrorAction SilentlyContinue
    if ($cmd) { $node = $cmd.Source }
}
if (-not $node) {
    Write-Output '[FAIL] No Node.js found - cannot run the SPA boot check.'
    Write-Output '       Expected C:\MyLikita\runtime\node\node.exe or node on PATH.'
    exit 1
}
Write-Output "[OK] Using Node: $node"

# --- wait for the server to answer HTTP 200 (shell may still be booting).
$deadline = (Get-Date).AddSeconds($ServerPollSec)
$up = $false
while ((Get-Date) -lt $deadline) {
    try {
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
        if ($r.StatusCode -eq 200) { $up = $true; break }
    } catch {
        # server not up yet - retry
    }
    Start-Sleep -Seconds 3
}
if (-not $up) {
    Write-Output "[FAIL] Server did not answer HTTP 200 at $Url within ${ServerPollSec}s."
    Write-Output '       The install is incomplete - no SPA boot check possible.'
    exit 1
}
Write-Output "[OK] Server answers HTTP 200 at $Url (shell served)"

# --- run the CDP boot check with the found Node.
$jsArgs = @("--url=$Url", "--settleMs=$SettleMs", "--timeoutMs=$($TimeoutSec * 1000)")
if ($BrowserPath) { $jsArgs += "--browser=$BrowserPath" }

& $node $checkJs @jsArgs
$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Output '[FAIL] SPA boot check failed - see the [FAIL] lines above.'
    exit 1
}
exit 0
