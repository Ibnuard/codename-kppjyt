@echo off
setlocal enabledelayedexpansion

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
goto usage

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
if exist "%APP_ROOT%\app\version.txt" (
    type "%APP_ROOT%\app\version.txt"
) else (
    echo Version info not found.
)
exit /b 0

:start
echo [^>] Starting Klipah Service...

:: Check if already running
if not exist "%PID_FILE%" goto do_start
set /p OLD_PID=<"%PID_FILE%"
tasklist /FI "PID eq %OLD_PID%" 2>nul | findstr /i "python" >nul
if errorlevel 1 (
    del "%PID_FILE%" 2>nul
    goto do_start
)
echo [!] Klipah is already running (PID: %OLD_PID%).
exit /b 0

:do_start
cd /d "%APP_ROOT%\app"
start /B "" "%VENV_PYTHON%" -m uvicorn server:app --host 0.0.0.0 --port 8000 > "%APP_ROOT%\server.log" 2>&1
ping 127.0.0.1 -n 4 >nul

:: Find PID
set "FOUND_PID="
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq python.exe" /NH 2^>nul ^| findstr /i "python"') do (
    if not defined FOUND_PID set "FOUND_PID=%%a"
)

if defined FOUND_PID (
    echo %FOUND_PID%> "%PID_FILE%"
    echo [OK] Klipah started on http://localhost:8000 (PID: %FOUND_PID%)
) else (
    echo [!] Failed to start Klipah. Check %APP_ROOT%\server.log for details.
)
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
if not exist "%PID_FILE%" goto no_pid_stat
set /p PID=<"%PID_FILE%"
tasklist /FI "PID eq %PID%" 2>nul | findstr /i "python" >nul
if errorlevel 1 goto stat_stale
echo [*] Klipah is RUNNING (PID: %PID%)
exit /b 0

:stat_stale
echo [*] Klipah is NOT running (stale PID file).
del "%PID_FILE%" 2>nul
exit /b 0

:no_pid_stat
echo [*] Klipah is NOT running.
exit /b 0

:update
echo [^>] Checking for updates...
echo [!] Fetching latest klipah-dist.zip...
:: Placeholder for download logic
exit /b 0

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
