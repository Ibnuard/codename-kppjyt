@echo off
setlocal enabledelayedexpansion

:: Generate ESC char for colors
for /F "delims=#" %%E in ('"prompt #$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%E"

:: Resolve absolute path to app root
set "BIN_DIR=%~dp0"
pushd "%BIN_DIR%.."
set "APP_ROOT=%CD%"
popd

set "VENV_PYTHON=%APP_ROOT%\venv\Scripts\python.exe"
set "PID_FILE=%APP_ROOT%\klipah.pid"

if "%1"=="start" goto start
if "%1"=="stop" goto stop
if "%1"=="update" goto update
if "%1"=="uninstall" goto uninstall
if "%1"=="status" goto status
if "%1"=="version" goto version
if "%1"=="token" goto token
goto usage

:usage
echo Klipah Management Tool
echo.
echo Usage: klipah ^<command^>
echo.
echo   start      Start the Klipah service in the foreground
echo   stop       Stop the Klipah service
echo   status     Check if Klipah is running
echo   update     Check and install updates
echo   uninstall  Remove Klipah from this system
echo   version    Display the current version
echo   token      Update your license: klipah token ^<your-base64-token^>
exit /b 1

:version
if exist "%APP_ROOT%\app\version.txt" (
    type "%APP_ROOT%\app\version.txt"
) else (
    echo Version info not found.
)
exit /b 0

:start
:: Foreground Start with UI
echo %ESC%[94m========================================================%ESC%[0m
echo %ESC%[96m     __ __  __    ___  ___  ___    __ __                 %ESC%[0m
echo %ESC%[96m    / //_/ / /   / _ \/ _ \/ _ ^|  / // /                 %ESC%[0m
echo %ESC%[96m   / ,^<   / /__ / , _/ ___/ __ ^| / _  /                  %ESC%[0m
echo %ESC%[96m  /_/^|_^| /____//_/^|_/_/  /_/ ^|_^|/_//_/                   %ESC%[0m
echo %ESC%[94m========================================================%ESC%[0m
echo %ESC%[32m [ SYSTEM ] Booting Klipah AI Core... %ESC%[0m

:: Check if server.py was self-destructed
if not exist "%APP_ROOT%\app\server.py" (
    echo %ESC%[31m [ ERROR ] CRITICAL SYSTEM FILES MISSING OR LOCKED. %ESC%[0m
    echo %ESC%[31m [ ERROR ] Your license has expired and the system self-destructed. %ESC%[0m
    echo %ESC%[33m [ ACTION ] Activate a new token by typing: klipah token ^<your-token^> %ESC%[0m
    exit /b 1
)

cd /d "%APP_ROOT%\app"
echo %ESC%[33m [ SERVER ] Klipah is now RUNNING on http://localhost:8000 %ESC%[0m
echo %ESC%[33m [ SERVER ] Press CTRL+C to stop the service gracefully. %ESC%[0m
echo %ESC%[90m -------------------------------------------------------- %ESC%[0m
"%VENV_PYTHON%" -m uvicorn server:app --host 0.0.0.0 --port 8000
echo %ESC%[90m -------------------------------------------------------- %ESC%[0m
echo %ESC%[31m [ SERVER ] Klipah Service has been stopped. %ESC%[0m
exit /b 0

:stop
echo [^>] Stopping Klipah Service...
if not exist "%PID_FILE%" goto no_pid
set /p PID=<"%PID_FILE%"
taskkill /F /PID %PID% /T >nul 2>&1
if errorlevel 1 goto stop_fail
echo [OK] Stopped Klipah (PID: %PID%).
del "%PID_FILE%" 2>nul
exit /b 0

:stop_fail
echo [!] Could not stop process %PID%. It may have already exited.
del "%PID_FILE%" 2>nul
exit /b 0

:no_pid
echo [!] No PID file found. Klipah may not be running.
exit /b 0

:status
echo %ESC%[33m [*] The Klipah system now runs dynamically. %ESC%[0m
echo If you used 'klipah start', it is running in that terminal window.
exit /b 0

:token
if "%2"=="" (
    echo %ESC%[31m[!] Missing token. Usage: klipah token ^<your-base64-token^>%ESC%[0m
    exit /b 1
)

set "TOKEN=%2"
echo %ESC%[94m[^>] Validating new token...%ESC%[0m
echo %TOKEN% > "%APP_ROOT%\temp_token.txt"

:: Run validation via temp script
echo import os, sys > "%APP_ROOT%\temp_val.py"
echo sys.path.append(os.path.join(r'%APP_ROOT%', 'app')) >> "%APP_ROOT%\temp_val.py"
echo from src.license_utils import activate_token, verify_license >> "%APP_ROOT%\temp_val.py"
echo with open(os.path.join(r'%APP_ROOT%', 'temp_token.txt'), 'r') as f: token=f.read().strip() >> "%APP_ROOT%\temp_val.py"
echo success, msg = activate_token(token, r'%APP_ROOT%') >> "%APP_ROOT%\temp_val.py"
echo if os.path.exists(os.path.join(r'%APP_ROOT%', 'temp_token.txt')): os.remove(os.path.join(r'%APP_ROOT%', 'temp_token.txt')) >> "%APP_ROOT%\temp_val.py"
echo if not success: print(f'\n\033[31m[ERROR] {msg}\033[0m'); sys.exit(1) >> "%APP_ROOT%\temp_val.py"
echo print(f'\n\033[32m[OK] {msg}\033[0m') >> "%APP_ROOT%\temp_val.py"

"%VENV_PYTHON%" "%APP_ROOT%\temp_val.py"
set PY_ERRORLEVEL=%ERRORLEVEL%
del "%APP_ROOT%\temp_val.py" 2>nul
if %PY_ERRORLEVEL% NEQ 0 (
    exit /b 1
)

:: Check if restoration is needed
if not exist "%APP_ROOT%\app\server.py" (
    echo %ESC%[33m[^>] Executing DRM Restoration Sequence...%ESC%[0m
    echo %ESC%[90mDownloading missing core assets from secure server...%ESC%[0m
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Ibnuard/codename-kppjyt/master/klipah-dist.zip' -OutFile '%APP_ROOT%\restore.zip'"
    if exist "%APP_ROOT%\restore.zip" (
        echo %ESC%[90mExtracting source matrix...%ESC%[0m
        powershell -Command "Expand-Archive -Path '%APP_ROOT%\restore.zip' -DestinationPath '%APP_ROOT%' -Force"
        del "%APP_ROOT%\restore.zip"
        echo %ESC%[32m[OK] System fully restored to normal working condition.%ESC%[0m
    ) else (
        echo %ESC%[31m[ERROR] Failed to download restoration assets. Please reinstall Klipah.%ESC%[0m
        exit /b 1
    )
)
echo %ESC%[32m[OK] You may now use 'klipah start'.%ESC%[0m
exit /b 0

:update
echo [^>] Checking for updates...
echo [!] Feature in development.

:uninstall
echo [!] CAUTION: This will delete Klipah from %APP_ROOT%
set /p CONFIRM="Are you sure? (y/N): "
if /i "%CONFIRM%"=="y" (
    call :stop
    echo [^>] Removing files...
    cd /d "%TEMP%"
    rmdir /s /q "%APP_ROOT%"
    echo [OK] Klipah uninstalled. Please manually remove it from your PATH if needed.
)
exit /b 0
