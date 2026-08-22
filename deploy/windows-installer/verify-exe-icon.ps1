<#
.SYNOPSIS
  Asserts a built MyLikita-Setup.exe embeds the expected favicon bytes.

.DESCRIPTION
  The Inno Setup directive SetupIconFile (mylikita.ico, copied by
  build-installer.bat from the built frontend's favicon.ico) is embedded
  UNCOMPRESSED as RT_ICON resources in the setup loader, so the icon's PNG
  images can be byte-matched directly inside the .exe — no third-party PE
  unpacker required (7-Zip and innounp both fail on current Inno Setup
  output). This catches a stale/broken icon chain before the installer ships.

  It also verifies the chain integrity: mylikita.ico (what the .iss embedded)
  must be byte-identical to every -ExpectedIcoPaths entry (the built
  frontend/dist copy AND the source frontend/public copy), so a stale built
  dist or a hand-edited copy can never drift from the vector source.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File verify-exe-icon.ps1 `
    -ExePath dist\output\MyLikita-Setup-1.0.0.exe `
    -IcoPath dist\mylikita.ico `
    -ExpectedIcoPaths dist\frontend\dist\icons\favicon.ico, frontend\public\icons\favicon.ico

  Exits 0 when the exe embeds every icon image byte-identical and the chain
  matches; exits 1 otherwise.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$ExePath,

  # mylikita.ico — the SetupIconFile the .iss actually embedded.
  [Parameter(Mandatory = $true)]
  [string]$IcoPath,

  # Canonical favicon.ico copies that mylikita.ico must equal (chain check).
  [string[]]$ExpectedIcoPaths = @()
)

$ErrorActionPreference = 'Stop'

function Fail([string]$msg) {
  Write-Output "[FAIL] $msg"
  exit 1
}

if (-not (Test-Path -LiteralPath $ExePath)) { Fail "Installer not found: $ExePath" }
if (-not (Test-Path -LiteralPath $IcoPath)) { Fail "Icon not found: $IcoPath" }

# ── 1. Chain integrity: mylikita.ico == every expected favicon copy ─────────
foreach ($expected in $ExpectedIcoPaths) {
  if (-not (Test-Path -LiteralPath $expected)) { Fail "Expected icon not found: $expected" }
  $a = (Get-FileHash -LiteralPath $IcoPath -Algorithm SHA256).Hash
  $b = (Get-FileHash -LiteralPath $expected -Algorithm SHA256).Hash
  if ($a -ne $b) {
    Fail "Icon chain drift: $IcoPath (sha256 $a) differs from $expected (sha256 $b) — the .iss embeds a different icon than the repo's favicon."
  }
  Write-Output "[OK] $IcoPath is byte-identical to $expected"
}

# ── 2. Parse the ICO (ICONDIR) and extract its embedded images ──────────────
$ico = [System.IO.File]::ReadAllBytes($IcoPath)
$count = [BitConverter]::ToUInt16($ico, 4)
if ($count -lt 1) { Fail "$IcoPath declares no images" }
Write-Output "Icon images in `${IcoPath}: $count"

$blobs = @()
for ($i = 0; $i -lt $count; $i++) {
  $off = 6 + 16 * $i
  $w   = if ($ico[$off] -eq 0) { 256 } else { [int]$ico[$off] }
  $h   = if ($ico[$off + 1] -eq 0) { 256 } else { [int]$ico[$off + 1] }
  $size    = [BitConverter]::ToUInt32($ico, $off + 8)
  $dataOff = [BitConverter]::ToUInt32($ico, $off + 12)
  $blob = New-Object byte[] $size
  [Array]::Copy($ico, $dataOff, $blob, 0, $size)
  $blobs += [pscustomobject]@{ Width = $w; Height = $h; Size = $size; Bytes = $blob }
}

# ── 3. Search each image byte-identically inside the EXE ────────────────────
# The icon images are stored raw (PNG) in the loader's RT_ICON resources, so a
# byte match proves the SetupIconFile made it into the .exe. Latin-1 is a
# perfect byte<->char bijection, so an Ordinal string IndexOf over the whole
# file is an exact byte search (SIMD-accelerated).
Write-Output "Scanning $ExePath for the icon bytes..."
$exe = [System.IO.File]::ReadAllBytes($ExePath)
$latin1 = [System.Text.Encoding]::Latin1
$exeStr = $latin1.GetString($exe)
$exeBytes = $exe.Length

$found = 0
foreach ($blob in $blobs) {
  $needle = $latin1.GetString($blob.Bytes)
  $idx = $exeStr.IndexOf($needle, [StringComparison]::Ordinal)
  if ($idx -ge 0) {
    $found++
    Write-Output ("[OK] {0}x{1} ({2} B) embedded at EXE offset {3}" -f $blob.Width, $blob.Height, $blob.Size, $idx)
  } else {
    Write-Output ("[MISSING] {0}x{1} ({2} B) NOT found in the EXE" -f $blob.Width, $blob.Height, $blob.Size)
  }
}
$exeStr = $null
$exe = $null
[GC]::Collect()

if ($found -ne $blobs.Count) {
  Fail "$found/$($blobs.Count) icon images embedded — the installer does NOT carry the expected favicon."
}
Write-Output "[OK] Installer embeds all $found icon image(s) byte-identical to $IcoPath ($exeBytes bytes scanned)."
Write-Output 'ICON VERIFICATION PASSED'
