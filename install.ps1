# Kilpah Windows Installer (PowerShell) - Secure Edition
$ErrorActionPreference = "Stop"

# Force TLS 1.2 for GitHub connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$InstallDir = "$env:LOCALAPPDATA\Kilpah"
$DistRepo = "https://github.com/Ibnuard/codename-kppjyt"
$ZipUrl = "https://raw.githubusercontent.com/Ibnuard/codename-kppjyt/master/klipah-dist.zip"
$SecretKey = "Klipah-Global-Secret-Key-2026"

function Get-HMACSignature($date, $secret) {
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.Key = [System.Text.Encoding]::UTF8.GetBytes($secret)
    $hash = $hmacsha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($date))
    return [System.BitConverter]::ToString($hash).Replace("-", "").ToUpper().Substring(0, 12)
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "       Klipah Professional Installer       " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. License Prompt
$isValid = $false
while (!$isValid) {
    $key = Read-Host "Please enter your Secure Token"
    
    # Simple length check (base64 is usually > 30 chars), will be validated properly by Python later.
    if ($key.Length -gt 10) {
        $isValid = $true
        Write-Host "[OK] Token format accepted. Will be activated during setup." -ForegroundColor Green
    } else {
        Write-Host "[!] Invalid token." -ForegroundColor Red
    }
}

# 2. Check Prerequisites
Write-Host "`n[>] Checking Python..."
if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Python not found. Please install Python 3.10+ from python.org" -ForegroundColor Yellow
    exit 1
}

# 3. Stop running services & Download
Write-Host "[>] Stopping any existing Klipah background services..."
# Look for Klipah PID if it exists
if (Test-Path "$InstallDir\klipah.pid") {
    $pidToKill = Get-Content "$InstallDir\klipah.pid"
    Stop-Process -Id $pidToKill -Force -ErrorAction SilentlyContinue
}
# Backup kill for any orphaned python processes in that dir
Get-Process python -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*$InstallDir*" } | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "[>] Downloading Kilpah package..."
if (!(Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force }
$LocalZip = "$env:TEMP\kilpah.zip"
Invoke-WebRequest -Uri $ZipUrl -OutFile $LocalZip

Write-Host "[>] Extracting..."
Expand-Archive -Path $LocalZip -DestinationPath $InstallDir -Force

# Save the Token locally for python setup
[IO.File]::WriteAllText("$InstallDir\temp_token.txt", $key.Trim())

# 4. Setup Venv
Write-Host "[>] Initializing Virtual Environment (this may take a few mins)..."
cd $InstallDir
python -m venv venv
.\venv\Scripts\python.exe -m pip install --upgrade pip
.\venv\Scripts\python.exe -m pip install -r .\app\requirements.txt

$CleanInstallDir = $InstallDir.Replace('\', '\\')

Write-Host "[>] Activating License Token..."
$py_script = @"
import os, sys
sys.path.append(os.path.join('$CleanInstallDir', 'app'))
from src.license_utils import activate_token
with open(os.path.join('$CleanInstallDir', 'temp_token.txt'), 'r') as f:
    token = f.read().strip()
success, msg = activate_token(token, '$CleanInstallDir')
if success:
    print('\n[OK] ' + msg)
    os.remove(os.path.join('$CleanInstallDir', 'temp_token.txt'))
else:
    print('\n[ERROR] ' + msg)
    sys.exit(1)
"@

.\venv\Scripts\python.exe -c $py_script
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Token activation failed. Please check your token or contact support." -ForegroundColor Red
    # Cleanup temp installation since token failed
    Remove-Item -Path $InstallDir -Recurse -Force
    exit 1
}
# 5. FFmpeg Check/Download
if (!(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "[>] FFmpeg missing. Downloading local copy..."
}

Write-Host "`n[>] --- 6/6 Adding Klipah to PATH ---"
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$InstallDir\bin*") {
    [Environment]::SetEnvironmentVariable("Path", $UserPath + ";$InstallDir\bin", "User")
    Write-Host "[OK] Klipah added to User PATH." -ForegroundColor Green
} else {
    Write-Host "[*] Klipah is already in PATH." -ForegroundColor Gray
}

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "       Installation Successful!            " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Please restart your terminal."
Write-Host "Then type 'klipah start' to run."
