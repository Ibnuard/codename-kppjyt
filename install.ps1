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
    $key = Read-Host "Please enter your License Key"
    if ($key -like "*-*") {
        $parts = $key.Split("-")
        $expiryStr = $parts[0]
        $signature = $parts[1]
        
        # Verify Signature
        $expected = Get-HMACSignature $expiryStr $SecretKey
        if ($signature.ToUpper() -eq $expected) {
            # Check Expiry
            try {
                $expiryDate = [datetime]::ParseExact($expiryStr, "yyyyMMdd", $null)
                if ((Get-Date) -lt $expiryDate) {
                    $isValid = $true
                    Write-Host "[OK] License valid until $($expiryDate.ToString('dd-MM-yyyy'))" -ForegroundColor Green
                } else {
                    Write-Host "[!] License EXPIRED on $($expiryDate.ToString('dd-MM-yyyy'))" -ForegroundColor Red
                }
            } catch {
                Write-Host "[!] Invalid date format in key." -ForegroundColor Red
            }
        } else {
            Write-Host "[!] Invalid license signature." -ForegroundColor Red
        }
    } else {
        Write-Host "[!] Invalid key format. Expected: YYYYMMDD-XXXXXX" -ForegroundColor Red
    }
}

# 2. Check Prerequisites
Write-Host "`n[>] Checking Python..."
if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Python not found. Please install Python 3.10+ from python.org" -ForegroundColor Yellow
    exit 1
}

# 3. Download & Install
Write-Host "[>] Downloading Kilpah package..."
if (!(Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force }
$LocalZip = "$env:TEMP\kilpah.zip"
Invoke-WebRequest -Uri $ZipUrl -OutFile $LocalZip

Write-Host "[>] Extracting..."
Expand-Archive -Path $LocalZip -DestinationPath $InstallDir -Force

# Save License Key
$key | Out-File -FilePath "$InstallDir\license.txt" -Encoding utf8

# 4. Setup Venv
Write-Host "[>] Initializing Virtual Environment (this may take a few mins)..."
cd $InstallDir
python -m venv venv
.\venv\Scripts\python.exe -m pip install --upgrade pip
.\venv\Scripts\python.exe -m pip install -r .\app\requirements.txt

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
Write-Host "Then type 'kilpah start' to run."
