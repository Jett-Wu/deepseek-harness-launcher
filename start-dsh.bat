@echo off
setlocal EnableExtensions
title DeepSeek Harness Launcher

rem ===========================================================================
rem  DeepSeek Harness one-click launcher (official npm package @deepseek-ai/dsh)
rem  Double-click to start | "<name> update" | "<name> check" | "<name> uninstall"
rem ===========================================================================

rem ---- configuration ----
set "PORT=3080"
set "URL=http://127.0.0.1:%PORT%"
set "APP=DeepSeek Harness"
set "INSTALL_DIR=%LOCALAPPDATA%\DeepSeek-Harness"
set "BIN=%INSTALL_DIR%\node_modules\.bin\dsh.cmd"
set "STAMP=%INSTALL_DIR%\.dsh-last-check"

rem ---- speed up npm / npx ----
set "npm_config_update_notifier=false"
set "npm_config_fund=false"
set "npm_config_audit=false"

rem ---- subcommands ----
if /i "%~1"=="check"        goto :check_env
if /i "%~1"=="update"       goto :do_update
if /i "%~1"=="update-check" goto :update_check
if /i "%~1"=="uninstall"    goto :do_uninstall

rem ---- main: reuse / detect / install ----
curl -s -o nul -m 1 "%URL%/" 2>nul && goto :already_running

if exist "%BIN%" goto :use_local
where dsh >nul 2>nul
if not errorlevel 1 goto :use_global

where node >nul 2>nul
if errorlevel 1 goto :install_node
where npm >nul 2>nul
if errorlevel 1 (
    set "BAIL_MSG=Node.js found but npm is missing. Please reinstall Node.js:"
    goto :bail
)

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
echo Installed! Future launches are faster.
goto :use_local

:install_failed
echo.
echo [notice] Auto-install failed; using npx instead (slower start, same features).
goto :use_npx

rem ---- run mode selection ----
:use_local
echo Using local dsh (update with: %~nx0 update)
set "MODE=local"
goto :run

:use_global
echo Using global dsh (update with: npm install -g @deepseek-ai/dsh)
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
where curl >nul 2>nul
if not errorlevel 1 (
    start "" /b cmd /c "curl --retry 120 --retry-delay 1 --retry-connrefused -s -o nul -m 1 %URL%/ && start %URL%"
) else (
    start "" powershell -NoProfile -WindowStyle Hidden -Command "$p=%PORT%;$u='%URL%';for($i=0;$i -lt 240;$i++){try{$c=[Net.Sockets.TcpClient]::new();$c.Connect('127.0.0.1',$p);if($c.Connected){Start-Process $u;break}}catch{};Start-Sleep -Milliseconds 250}"
)
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
call npm install --prefix "%INSTALL_DIR%" @deepseek-ai/dsh@latest --no-fund --no-audit --no-package-lock
if not errorlevel 1 exit /b 0
rem mirror failed - retry once with the official registry
call npm install --prefix "%INSTALL_DIR%" @deepseek-ai/dsh@latest --no-fund --no-audit --no-package-lock --registry=https://registry.npmjs.org/
exit /b %ERRORLEVEL%

rem ---- background auto-update (once per day, silent) ----
:update_check
set "LAST="
if exist "%STAMP%" set /p LAST=<"%STAMP%"
if "%LAST%"=="%date%" exit /b 0
> "%STAMP%" echo %date%
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
if "%REMOTE%"=="%LOCAL%" exit /b 0
echo.
echo [update] New version %REMOTE% (current %LOCAL%). Updating in background...
call :npm_install >nul 2>nul
if errorlevel 1 (
    echo [update] Update failed. Retry later: %~nx0 update
) else (
    echo [update] Updated to %REMOTE%. Takes effect on next launch.
)
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
) else (
    echo Updated!
    > "%STAMP%" echo %date%
)
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
goto :done_pause

rem ---- diagnose ----
:check_env
echo ==========================================
echo   %APP% environment
echo ==========================================
where node >nul 2>nul
if errorlevel 1 (echo   [x] Node.js   : not found) else echo   [v] Node.js   : installed
where npm >nul 2>nul
if errorlevel 1 (echo   [x] npm       : not found) else echo   [v] npm       : installed
where dsh >nul 2>nul
if errorlevel 1 (echo   [x] global dsh: not found) else echo   [v] global dsh: installed
set "VER="
if exist "%BIN%" for /f "delims=" %%v in ('call "%BIN%" --version 2^>nul') do set "VER=%%v"
if exist "%BIN%" (echo   [v] local dsh : ready ^(%VER%^)) else echo   [x] local dsh : not installed ^(auto-installs on first run^)
where curl >nul 2>nul
if errorlevel 1 (echo   [-] server    : skipped ^(no curl^)) else (
    curl -s -o nul -m 1 "%URL%/"
    if errorlevel 1 (echo   [x] server    : not running) else echo   [v] server    : running at %URL%
)
echo.
pause
exit /b 0

rem ---- done ----
:done_pause
echo.
pause
exit /b 0
