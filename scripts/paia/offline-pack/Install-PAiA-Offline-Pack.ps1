<#
.SYNOPSIS
  Installs the PAiA offline pack (default model + llama.cpp engines) into the
  PAiA data folder. No network access is used.

.DESCRIPTION
  1. Finds PAiA's data folder (custom location from settings.json, or the
     default %APPDATA%\Jan\data).
  2. Verifies every file in the pack against manifest.sha256.
  3. Copies the files into the data folder.

  Install PAiA and start it once before running this, then close it.

.PARAMETER DataFolder
  Override the destination data folder.

.PARAMETER SkipVerify
  Skip checksum verification (not recommended).
#>
[CmdletBinding()]
param(
  [string]$DataFolder,
  [switch]$SkipVerify
)

$ErrorActionPreference = 'Stop'
$Pack = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

# --- 1. Data folder ---------------------------------------------------------
if (-not $DataFolder) {
  $appDir = Join-Path $env:APPDATA 'Jan'
  $settings = Join-Path $appDir 'settings.json'
  $DataFolder = Join-Path $appDir 'data'
  if (Test-Path $settings) {
    try {
      $cfg = Get-Content $settings -Raw | ConvertFrom-Json
      if ($cfg.data_folder -and $cfg.data_folder -ne './data') {
        $DataFolder = $cfg.data_folder
      }
    } catch {
      Write-Warning "Could not read $settings; using default data folder."
    }
  } else {
    Write-Warning "PAiA has not been started yet on this account. Start it once, close it, then rerun for best results."
  }
}
Write-Step "Data folder: $DataFolder"

# --- 2. App must be closed --------------------------------------------------
$running = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -in @('jan', 'Jan', 'llama-server') }
if ($running) {
  throw "PAiA is running. Close it (including the tray icon) and run this again."
}

# --- 3. Verify --------------------------------------------------------------
$manifest = Join-Path $Pack 'manifest.sha256'
if (-not $SkipVerify) {
  if (-not (Test-Path $manifest)) { throw "manifest.sha256 not found in $Pack" }
  Write-Step "Verifying files (the 4.7 GB model takes a minute)..."
  $bad = @()
  $entries = Get-Content $manifest | Where-Object { $_ -and -not $_.StartsWith('#') }
  foreach ($line in $entries) {
    $hash, $rel = $line -split '\s+', 2
    $file = Join-Path $Pack ($rel -replace '/', '\')
    if (-not (Test-Path $file)) { $bad += "missing: $rel"; continue }
    $got = (Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash.ToLower()
    if ($got -ne $hash.ToLower()) { $bad += "corrupt: $rel" }
  }
  if ($bad.Count -gt 0) {
    $bad | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    throw "Pack verification failed ($($bad.Count) problem(s)). Re-copy the pack and try again."
  }
  Write-Host "    $($entries.Count) files OK" -ForegroundColor Green
}

# --- 4. Copy ----------------------------------------------------------------
Write-Step "Copying model and engines..."
New-Item -ItemType Directory -Force -Path $DataFolder | Out-Null
$src = Join-Path $Pack 'data'
& robocopy $src $DataFolder /E /NFL /NDL /NJH /NJS /NP /R:2 /W:2 | Out-Null
if ($LASTEXITCODE -ge 8) { throw "Copy failed (robocopy exit code $LASTEXITCODE)." }

# --- 5. Check ---------------------------------------------------------------
$modelYml = Get-ChildItem -Path (Join-Path $DataFolder 'llamacpp\models') -Filter model.yml -Recurse -ErrorAction SilentlyContinue
$servers  = Get-ChildItem -Path (Join-Path $DataFolder 'llamacpp\backends') -Filter llama-server.exe -Recurse -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "Installed:" -ForegroundColor Green
$modelYml | ForEach-Object { Write-Host "  model : $($_.Directory.Name)" }
$servers  | ForEach-Object { Write-Host "  engine: $($_.Directory.Parent.Parent.Name)" }
Write-Host ""
Write-Host "Start PAiA, open a new chat and pick 'Qwen2.5 7B Instruct (PAiA default)'."
