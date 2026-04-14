@echo off
setlocal enabledelayedexpansion

:: Get the absolute path to the app root (one level up from bin)
set "BIN_DIR=%~dp0"
for %%i in ("%BIN_DIR%..") do set "APP_ROOT=%%~fi"
set "VENV_PYTHON=%APP_ROOT%\venv\Scripts\python.exe"
set "PID_FILE=%APP_ROOT%\klipah.pid"

if "%1"=="start" goto start
if "%1"=="stop" goto stop
if "%1"=="update" goto update
if "%1"=="uninstall" goto uninstall
if "%1"=="status" goto status
if "%1"=="version" goto version

:usage
echo Klipah Management Tool
echo.
echo Usage: klipah ^<command^>
echo.
echo Commands:
echo   start      Start the Klipah service
echo   stop       Stop the Klipah service
echo   status     Check if Klipah is running
echo   update     Check and install updates
echo   uninstall  Remove Klipah from this system
echo   version    Display the current version
exit /b 1

:version
type "%APP_ROOT%\app\version.txt"
goto :eof

:start
echo [^>] Starting Klipah Service...

:: Simple PID check
if exist "%PID_FILE%" (
    set /p OLD_PID=<"%PID_FILE%"
    tasklist /FI "PID eq !OLD_PID!" 2>nul | findstr /i "python.exe" >nul
    if not errorlevel 1 (
        echo [!] Klipah is already running (PID: !OLD_PID!).
        exit /b 0
    )
    del "%PID_FILE%"
)

cd /d "%APP_ROOT%\app"
start /B "" "%VENV_PYTHON%" -m uvicorn server:app --host 0.0.0.0 --port 8000 > "%APP_ROOT%\server.log" 2>&1

:: Wait and capture PID
timeout /t 2 >nul
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq python.exe" /NH /FO TABLE ^| find /v ""') do (
    set "NEW_PID=%%a"
)
echo %NEW_PID% > "%PID_FILE%"
echo [OK] Klipah started on http://localhost:8000 (PID: %NEW_PID%)
exit /b 0

:stop
echo [^>] Stopping Klipah Service...
if not exist "%PID_FILE%" (
    echo [!] No PID file found. Try killing python.exe manually if it's still running.
    exit /b 0
)
set /p PID=^<"%PID_FILE%"
taskkill /F /PID !PID! /T >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Stopped Klipah (PID: !PID!).
) else (
    echo [!] Could not stop process !PID!. It might have already crashed.
)
del "%PID_FILE%"
exit /b 0

:status
if exist "%PID_FILE%" (
    set /p PID=^<"%PID_FILE%"
    tasklist /FI "PID eq !PID!" | findstr /i "python.exe" >nul
    if !errorlevel! equ 0 (
        echo [*] Klipah is RUNNING (PID: !PID!)
    ) else (
        echo [*] Klipah is NOT running (stale PID file)
        del "%PID_FILE%"
    )
) else (
    echo [*] Klipah is NOT running
)
exit /b 0

:update
echo [^>] Checking for updates...
echo [!] Update logic depends on your distribution server. 
echo [!] Fetching latest klipah-dist.zip...
:: Placeholder for curl/powershell download
exit /b 0

:uninstall
echo [!] CAUTION: This will delete Kilpah from %APP_ROOT%
set /p CONFIRM="Are you sure? (y/N): "
if /i "!CONFIRM!"=="y" (
    call :stop
    echo [^>] Removing files...
    cd /d %TEMP%
    rmdir /s /q "%APP_ROOT%"
    echo [OK] Kilpah uninstalled. Please manually remove it from your PATH if needed.
)
exit /b 0
