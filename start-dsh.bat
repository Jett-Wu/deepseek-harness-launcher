@echo off
setlocal EnableExtensions
title DeepSeek Harness Launcher

rem ===========================================================================
rem  DeepSeek Harness one-click launcher (official npm package @deepseek-ai/dsh)
rem  Double-click to start | "<name> update" | "<name> check" | "<name> uninstall"
rem  Uses the npmmirror China registry by default (falls back to official)
rem  Self-heals: a failed update or a Node.js upgrade triggers an auto rebuild
rem ===========================================================================

rem ---- configuration ----
set "PORT=3080"
set "URL=http://127.0.0.1:%PORT%"
set "APP=DeepSeek Harness"
set "INSTALL_DIR=%LOCALAPPDATA%\DeepSeek-Harness"
set "BIN=%INSTALL_DIR%\node_modules\.bin\dsh.cmd"
set "LOGDIR=%INSTALL_DIR%\logs"
set "LOGF=%LOGDIR%\install.log"
set "BROKEN=%INSTALL_DIR%\.install-failed"
set "NODEFILE=%INSTALL_DIR%\.node-version"
set "AVAILF=%INSTALL_DIR%\.update-available"
rem minimum Node.js required by dsh dependencies (undici / pi-ai / pi-telemetry)
set "MIN_NODE=22.19.0"
rem The update probe runs on every launch (read-only - nothing is installed
rem automatically). A release is only offered once it is at least MIN_AGE_DAYS old:
rem dsh ships about every 1.8 days and its "latest" is an rc, so this skips the
rem freshest build and lets early bugs surface before you are told about it.
set "MIN_AGE_DAYS=2"
rem remind when the newest backup is older than N days
set "BACKUP_DAYS=7"

rem ---- locate the optional dsh-backup helper (sessions + plugins) ----
set "BACKUP_PS1="
if defined DSH_BACKUP_PS1 if exist "%DSH_BACKUP_PS1%" set "BACKUP_PS1=%DSH_BACKUP_PS1%"
if not defined BACKUP_PS1 if exist "%~dp0dsh-backup\dsh-backup.ps1" set "BACKUP_PS1=%~dp0dsh-backup\dsh-backup.ps1"
if not defined BACKUP_PS1 if exist "%~dp0dsh-backup.ps1" set "BACKUP_PS1=%~dp0dsh-backup.ps1"
if not defined BACKUP_PS1 if exist "D:\dsh-backup\dsh-backup.ps1" set "BACKUP_PS1=D:\dsh-backup\dsh-backup.ps1"
set "BACKUP_DIR="
if defined BACKUP_PS1 for %%f in ("%BACKUP_PS1%") do set "BACKUP_DIR=%%~dpf"
if defined BACKUP_DIR if "%BACKUP_DIR:~-1%"=="\" set "BACKUP_DIR=%BACKUP_DIR:~0,-1%"

rem ---- speed up npm / npx ----
set "npm_config_update_notifier=false"
set "npm_config_fund=false"
set "npm_config_audit=false"

rem ---- subcommands (command line) ----
if /i "%~1"=="check"        goto :check_env
if /i "%~1"=="update"       goto :do_update
if /i "%~1"=="update-check" goto :update_check
if /i "%~1"=="uninstall"    goto :do_uninstall
if /i "%~1"=="backup"       goto :do_backup
if /i "%~1"=="diagnose"     goto :do_diagnose
if /i "%~1"=="repair"       goto :do_repair
if /i "%~1"=="start"        goto :main

rem ---- no arguments (double-click): show the menu ----
if "%~1"=="" goto :menu

rem ---- interactive menu ----
:menu
echo ==========================================
echo   %APP% Launcher
echo ==========================================
call :show_status
echo.
echo   [1] Start                    (default - just press Enter)
echo   [2] Update now
echo   [3] Backup sessions + plugins
echo   [4] Diagnose / Repair
echo   [5] Uninstall
echo   [0] Exit
echo.
set "PICK="
set /p "PICK=Choose [1]: "
if not defined PICK set "PICK=1"
if "%PICK%"=="1" goto :main
if "%PICK%"=="2" goto :do_update
if "%PICK%"=="3" goto :do_backup
if "%PICK%"=="4" goto :do_diagnose
if "%PICK%"=="5" goto :do_uninstall
if "%PICK%"=="0" goto :menu_exit
echo.
echo   Invalid choice: "%PICK%"
timeout /t 2 >nul
goto :menu

:menu_exit
exit /b 0

:show_status
set "AVAIL="
if exist "%AVAILF%" set /p AVAIL=<"%AVAILF%"
if defined AVAIL echo   update   : %AVAIL% available - press 2 to install
if not defined AVAIL echo   update   : up to date ^(checked on every launch^)
set "SNAP="
if defined BACKUP_DIR if exist "%BACKUP_DIR%\snapshots" for /f "delims=" %%d in ('dir /b /ad /o-d "%BACKUP_DIR%\snapshots" 2^>nul') do if not defined SNAP set "SNAP=%%d"
if not defined SNAP goto :status_none
set "BK_OLD="
for /f "delims=" %%f in ('forfiles /p "%BACKUP_DIR%\snapshots" /m "%SNAP%" /d -%BACKUP_DAYS% /c "cmd /c echo @file" 2^>nul') do set "BK_OLD=1"
if defined BK_OLD goto :status_old
echo   last backup: %SNAP%
exit /b 0
:status_old
echo   last backup: %SNAP%  ^(over %BACKUP_DAYS% days old - press 3 to back up^)
exit /b 0
:status_none
echo   last backup: none yet  ^(press 3 to back up^)
exit /b 0

rem ---- main: reuse / detect / install ----
:main

rem ---- main: reuse / detect / install ----
curl -s -o nul -m 1 "%URL%/" 2>nul && goto :already_running

if exist "%BIN%" goto :check_local
where dsh >nul 2>nul
if not errorlevel 1 goto :use_global

where node >nul 2>nul
if errorlevel 1 goto :install_node
where npm >nul 2>nul
if errorlevel 1 (
    set "BAIL_MSG=Node.js found but npm is missing. Please reinstall Node.js:"
    goto :bail
)

rem ---- local install health check (repair if a previous update failed or Node.js changed) ----
:check_local
if exist "%BROKEN%" goto :do_repair
set "NODEVER="
for /f "delims=" %%v in ('node -v 2^>nul') do set "NODEVER=%%v"
call :check_node_ver
if errorlevel 1 (
    echo.
    echo [warning] Node.js %NODEVER% is older than %MIN_NODE%, which some packages require.
    echo   If installs keep failing, upgrade Node.js LTS: https://nodejs.org/
    echo.
)
set "OLDNODE="
if exist "%NODEFILE%" set /p OLDNODE=<"%NODEFILE%"
if defined OLDNODE if defined NODEVER if not "%OLDNODE%"=="%NODEVER%" goto :do_repair
goto :use_local

rem ---- first-run install ----
:do_install
echo.
echo First run: installing %APP% locally (needs internet, ~1-3 min)...
echo Location: %INSTALL_DIR%
echo.
call :set_mirror
call :npm_install
if errorlevel 1 goto :install_failed
if not exist "%BIN%" goto :install_failed
call :save_node_ver
echo Installed! Future launches are faster.
goto :use_local

:install_failed
echo.
echo [notice] Auto-install failed; using npx instead (slower start, same features).
goto :use_npx

rem ---- repair a broken local install ----
:do_repair
echo.
echo [repair] The local install needs a rebuild (an update failed, or Node.js changed).
echo.
if exist "%BROKEN%" del "%BROKEN%" >nul 2>nul
call :npm_install
if errorlevel 1 (
    echo [repair] First attempt failed - cleaning node_modules and retrying ^(may take a few minutes^)...
    if exist "%INSTALL_DIR%\node_modules" rmdir /s /q "%INSTALL_DIR%\node_modules"
    call :npm_install
)
if errorlevel 1 goto :repair_failed
call :save_node_ver
call "%BIN%" --version >nul 2>nul
if errorlevel 1 goto :repair_failed
echo [repair] Repaired successfully.
echo.
goto :use_local

:repair_failed
echo.
echo [repair] Could not repair the local install. Details: %LOGF%
echo   If npm blocked package install scripts, try: npm install-scripts approve --all
echo   Run "%~nx0 check" for environment info. Falling back to npx for now.
goto :use_npx

rem ---- run mode selection ----
:use_local
echo Using local dsh (update with: %~nx0 update)
set "MODE=local"
goto :run

:use_global
echo Using global dsh (update with: npm install -g @deepseek-ai/dsh --registry=https://registry.npmmirror.com)
set "MODE=global"
goto :run

:use_npx
echo Using npx (first time needs internet, then cached)
set "npm_config_prefer_offline=true"
set "MODE=npx"
goto :run

rem ---- run ----
:run
echo.
echo Starting %APP%... the browser opens automatically when ready.
echo Page: %URL%    Close this window to stop the service.
echo.
if "%MODE%"=="local" start "" /b cmd /c call "%~f0" update-check
rem dsh opens the browser itself once the server is listening (see: dsh web --no-open)
if "%MODE%"=="local"  call "%BIN%" web
if "%MODE%"=="global" call dsh web
if "%MODE%"=="npx"    call npx --yes @deepseek-ai/dsh web
if errorlevel 1 goto :run_failed
echo.
echo %APP% stopped.
goto :done_pause

:run_failed
echo.
echo [error] %APP% exited abnormally (code %ERRORLEVEL%).
echo   Manual stop (Ctrl+C)? Ignore this. Otherwise: check network, port
echo   %PORT% in use, or run "%~nx0 update".
goto :done_pause

:already_running
echo Already running - opening browser.
start "" "%URL%"
goto :done_pause

rem ---- Node.js setup ----
:install_node
echo.
echo Node.js is required but not found.
where winget >nul 2>nul
if errorlevel 1 (
    set "BAIL_MSG=Please install Node.js LTS manually, then run this script again:"
    goto :bail
)
echo Installing Node.js LTS via winget (~1-2 min; approve UAC prompt if asked)...
winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements --disable-interactivity
if errorlevel 1 (
    set "BAIL_MSG=winget install failed. Please install Node.js LTS manually:"
    goto :bail
)
echo Node.js installed. Continuing...
goto :refresh_path

:bail
echo.
echo %BAIL_MSG%
echo   https://nodejs.org/
start "" https://nodejs.org/
pause
exit /b 1

:refresh_path
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%b"
if defined SYS_PATH set "PATH=%SYS_PATH%;%PATH%"
if exist "%ProgramFiles%\nodejs\node.exe" set "PATH=%ProgramFiles%\nodejs;%PATH%"
if exist "%LOCALAPPDATA%\Programs\nodejs\node.exe" set "PATH=%LOCALAPPDATA%\Programs\nodejs;%PATH%"
where node >nul 2>nul
if errorlevel 1 (
    echo [error] Node.js still not usable. Restart and try again.
    pause
    exit /b 1
)
goto :do_install

rem ---- install / update helper ----
:set_mirror
rem point npm at the China mirror for faster installs (skip if DSH_OFFICIAL_REGISTRY is set)
if defined DSH_OFFICIAL_REGISTRY exit /b 0
call npm config set registry https://registry.npmmirror.com >nul 2>nul
exit /b 0

:npm_install
if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>nul
rem drop npm debug logs older than 7 days to keep the folder small
forfiles /p "%LOGDIR%" /m *-debug-0.log /d -7 /c "cmd /c del @path" >nul 2>nul
set "npm_config_logs_dir=%LOGDIR%"
call npm install --prefix "%INSTALL_DIR%" @deepseek-ai/dsh@latest --no-fund --no-audit --no-package-lock
if not errorlevel 1 goto :install_ok
rem mirror failed - retry once with the official registry
call npm install --prefix "%INSTALL_DIR%" @deepseek-ai/dsh@latest --no-fund --no-audit --no-package-lock --registry=https://registry.npmjs.org/
if not errorlevel 1 goto :install_ok
rem both attempts failed - mark for repair on the next launch
> "%BROKEN%" echo failed
exit /b 1

:install_ok
if exist "%BROKEN%" del "%BROKEN%" >nul 2>nul
if exist "%AVAILF%" del "%AVAILF%" >nul 2>nul
exit /b 0

:save_node_ver
for /f "delims=" %%v in ('node -v 2^>nul') do > "%NODEFILE%" echo %%v
exit /b 0

:check_node_ver
rem returns 0 when Node.js satisfies MIN_NODE (reuses NODEVER if already set)
if not defined NODEVER for /f "delims=" %%v in ('node -v 2^>nul') do set "NODEVER=%%v"
if not defined NODEVER exit /b 1
set "NMAJOR="
set "NMINOR="
for /f "tokens=1,2 delims=." %%a in ("%NODEVER%") do (
    set "NMAJOR=%%a"
    set "NMINOR=%%b"
)
if not defined NMAJOR exit /b 1
set "NMAJOR=%NMAJOR:v=%"
set "MMAJOR="
set "MMINOR="
for /f "tokens=1,2 delims=." %%a in ("%MIN_NODE%") do (
    set "MMAJOR=%%a"
    set "MMINOR=%%b"
)
if not defined MMAJOR exit /b 0
if %NMAJOR% LSS %MMAJOR% exit /b 1
if %NMAJOR% GTR %MMAJOR% exit /b 0
if not defined NMINOR exit /b 1
if not defined MMINOR exit /b 0
if %NMINOR% LSS %MMINOR% exit /b 1
exit /b 0

rem ---- background auto-update (once per day, silent) ----
:update_check
rem probe on every launch - read-only, nothing gets installed automatically
set "npm_config_fetch_timeout=10000"
set "npm_config_fetch_retries=1"
set "REMOTE="
for /f "delims=" %%v in ('npm view @deepseek-ai/dsh version --no-fund --no-audit 2^>nul') do set "REMOTE=%%v"
if not defined REMOTE exit /b 0
set "LOCAL="
for /f "delims=" %%v in ('call "%BIN%" --version 2^>nul') do set "LOCAL=%%v"
if not defined LOCAL exit /b 0
if "%REMOTE:~0,1%"=="v" set "REMOTE=%REMOTE:~1%"
if "%LOCAL:~0,1%"=="v" set "LOCAL=%LOCAL:~1%"
if not "%REMOTE%"=="%LOCAL%" goto :uc_newer
if exist "%AVAILF%" del "%AVAILF%" >nul 2>nul
exit /b 0

:uc_newer
rem delayed adoption: only mention a release at least MIN_AGE_DAYS days old
set "PUB="
for /f "delims=" %%d in ('npm view @deepseek-ai/dsh time.%REMOTE% --no-fund --no-audit 2^>nul') do set "PUB=%%d"
set "AGE="
if defined PUB for /f "delims=" %%a in ('powershell -NoProfile -Command "if($env:PUB){[int]((Get-Date).ToUniversalTime()-[datetime]::Parse($env:PUB).ToUniversalTime()).TotalDays}" 2^>nul') do set "AGE=%%a"
if not defined AGE goto :uc_offer
if %AGE% LSS %MIN_AGE_DAYS% exit /b 0
:uc_offer
rem no silent auto-install: just record it and tell the user
> "%AVAILF%" echo %REMOTE%
echo.
echo ============================================================
echo  Update available: %REMOTE%  ^(you have %LOCAL%^)
echo  Run "%~nx0 update" to upgrade, or press 2 in the menu.
echo ============================================================
echo.
exit /b 0

rem ---- update ----
:do_update
where node >nul 2>nul
if errorlevel 1 goto :install_node
echo Updating %APP%...
call :set_mirror
call :npm_install
if errorlevel 1 (
    echo Update failed. Check your network.
    echo Log: %LOGF%
) else (
    echo Updated!
)
goto :done_pause

rem ---- backup (uses the optional dsh-backup helper) ----
:do_backup
echo.
if not defined BACKUP_PS1 goto :backup_missing
echo [backup] Backing up DSH sessions and plugins - takes about 8 seconds...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%BACKUP_PS1%"
echo.
if errorlevel 1 (
    echo [backup] Finished with warnings - review the output above.
) else (
    echo [backup] Done.
)
goto :done_pause

:backup_missing
echo [backup] Backup helper not found. Looked for:
echo   %~dp0dsh-backup\dsh-backup.ps1
echo   %~dp0dsh-backup.ps1
echo   D:\dsh-backup\dsh-backup.ps1
echo   Set DSH_BACKUP_PS1 to its full path if it lives elsewhere.
goto :done_pause

rem ---- diagnose, with optional repair ----
:do_diagnose
call :show_env
set "NEEDFIX="
if exist "%BROKEN%" set "NEEDFIX=1"
if not exist "%BIN%" set "NEEDFIX=1"
if exist "%BIN%" call "%BIN%" --version >nul 2>nul
if errorlevel 1 set "NEEDFIX=1"
echo.
if not defined NEEDFIX goto :diag_ok
echo   [!] The local install looks unhealthy.
set "FIXNOW="
set /p "FIXNOW=Repair it now? [y/N]: "
if /i "%FIXNOW%"=="y" goto :do_repair
goto :done_pause
:diag_ok
echo   Looks healthy.
goto :done_pause

rem ---- uninstall ----
:do_uninstall
echo.
echo Uninstalling %APP%...
curl -s -o nul -m 1 "%URL%/" 2>nul
if not errorlevel 1 echo   [notice] %APP% appears to be running - close it first for a clean removal.
if not exist "%INSTALL_DIR%" goto :uninstall_done
echo   Removing %INSTALL_DIR% ...
rmdir /s /q "%INSTALL_DIR%"
if exist "%INSTALL_DIR%" (
    echo   [notice] Some files could not be removed. Close %APP% and retry.
) else (
    echo   Removed.
)
:uninstall_done
echo.
echo Uninstall finished. Delete this script file if you no longer need it.
echo Note: npm registry stays on the China mirror. To restore the official
echo registry, run: npm config set registry https://registry.npmjs.org/
goto :done_pause

rem ---- diagnose ----
:check_env
call :show_env
echo.
pause
exit /b 0

:show_env
echo ==========================================
echo   %APP% environment
echo ==========================================
set "NODEVER="
for /f "delims=" %%v in ('node -v 2^>nul') do set "NODEVER=%%v"
call :check_node_ver
if not defined NODEVER (echo   [x] Node.js   : not found) else if errorlevel 1 (echo   [!] Node.js   : %NODEVER%  ^(needs %MIN_NODE%+^)) else echo   [v] Node.js   : %NODEVER%
set "NPMVER="
for /f "delims=" %%v in ('npm -v 2^>nul') do set "NPMVER=%%v"
if defined NPMVER (echo   [v] npm       : %NPMVER%) else echo   [x] npm       : not found
set "REG="
for /f "delims=" %%v in ('npm config get registry 2^>nul') do set "REG=%%v"
if defined REG (echo   [v] registry  : %REG%) else echo   [x] registry  : unknown
set "PROXY="
for /f "delims=" %%v in ('npm config get proxy 2^>nul') do set "PROXY=%%v"
if "%PROXY%"=="null" set "PROXY="
if defined PROXY (echo   [!] proxy     : %PROXY%  ^(make sure it is running^)) else echo   [-] proxy     : not set
where dsh >nul 2>nul
if errorlevel 1 (echo   [x] global dsh: not found) else echo   [v] global dsh: installed
set "VER="
if exist "%BIN%" for /f "delims=" %%v in ('call "%BIN%" --version 2^>nul') do set "VER=%%v"
if exist "%BIN%" (echo   [v] local dsh : ready ^(%VER%^)) else echo   [x] local dsh : not installed ^(auto-installs on first run^)
set "LATEST="
for /f "delims=" %%v in ('npm view @deepseek-ai/dsh version --no-fund --no-audit 2^>nul') do set "LATEST=%%v"
if not defined LATEST echo   [-] latest    : unknown ^(offline?^)
if defined VER if defined LATEST if "%LATEST%"=="%VER%" echo   [v] latest    : %LATEST%  ^(up to date^)
if defined VER if defined LATEST if not "%LATEST%"=="%VER%" echo   [!] latest    : %LATEST%  ^(local %VER% - run "%~nx0 update"^)
if exist "%BROKEN%" echo   [!] last install: FAILED - the next launch will repair it
if exist "%LOGF%" echo   [i] install log : %LOGF%
where curl >nul 2>nul
if errorlevel 1 (echo   [-] server    : skipped ^(no curl^)) else (
    curl -s -o nul -m 1 "%URL%/"
    if errorlevel 1 (echo   [x] server    : not running) else echo   [v] server    : running at %URL%
)
exit /b 0

rem ---- done ----
:done_pause
echo.
pause
exit /b 0
