@echo off
title LCE Windows Installer
setlocal EnableDelayedExpansion

:: Always run from the script's folder
cd /d "%~dp0"

:: ============================================================
:: CONSTANT PATHS
:: ============================================================
set CACHE_DIR=%AppData%\lce_cache
set ZIP_URL=https://github.com/smartcmd/MinecraftConsoles/releases/download/nightly/LCEWindows64.zip
set ZIP_FILE=%CACHE_DIR%\LCEWindows64.zip
set INSTALL_DIR=C:\Program Files\LCEWindows64
set USERFILE=%INSTALL_DIR%\username.txt
set SERVERFILE=%INSTALL_DIR%\servers.txt

if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"

:: ============================================================
:: MAIN MENU
:: ============================================================
:menu
cls
echo ================================
echo   LCE Windows Install Utility
echo ================================
echo 1) Install LCE
echo 2) Update LCE
echo 3) Change Username
echo 4) Add a Server
echo 5) Remove a Server
echo 6) Exit
echo.
set /p choice=Select an option: 

if "%choice%"=="1" goto install
if "%choice%"=="2" goto update
if "%choice%"=="3" goto changeuser
if "%choice%"=="4" goto addserver
if "%choice%"=="5" goto removeserver
if "%choice%"=="6" exit
goto menu

:: ============================================================
:: DOWNLOAD FUNCTION (SUPER FAST CURL VERSION)
:: ============================================================
:download_zip
echo Downloading latest LCE build...

curl.exe -L --retry 5 --retry-delay 2 --ssl-no-revoke --compressed ^
  -o "%ZIP_FILE%" "%ZIP_URL%"

if not exist "%ZIP_FILE%" (
    echo ERROR: Failed to download ZIP.
    pause
    goto menu
)

:: Sanity check for 0‑byte or corrupted download
for %%A in ("%ZIP_FILE%") do set ZIPSIZE=%%~zA
if "%ZIPSIZE%"=="0" (
    echo ERROR: Download returned empty file.
    del "%ZIP_FILE%"
    pause
    goto menu
)

echo Download complete.
goto :eof

:: ============================================================
:: INSTALL (ELEVATES ONLY HERE)
:: ============================================================
:install
echo Checking permissions for install...
powershell -Command ^
  "if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) { exit 1 }"
if %errorlevel%==1 (
    echo Requesting administrator privileges for installation...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cls
echo WARNING: NOT APPROVED OR ASSOCIATED WITH MOJANG
echo Side note: You may get a Windows pop-up because this project has no publisher.
echo.

call :download_zip

echo Creating install directory...
mkdir "%INSTALL_DIR%" >nul 2>&1

echo Extracting files to "%INSTALL_DIR%"...
powershell -Command "Expand-Archive -Force '%ZIP_FILE%' '%INSTALL_DIR%'"

powershell -Command "Unblock-File -Path '%INSTALL_DIR%\Minecraft.Client.exe'"

echo Extraction complete.
echo.

goto username_setup

:: ============================================================
:: UPDATE (ELEVATES ONLY HERE)
:: ============================================================
:update
echo Checking permissions for update...
powershell -Command ^
  "if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) { exit 1 }"
if %errorlevel%==1 (
    echo Requesting administrator privileges for update...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cls
echo Updating LCE installation...
echo.

if not exist "%INSTALL_DIR%\Minecraft.Client.exe" (
    echo LCE is not installed. Install first.
    pause
    goto menu
)

call :download_zip

echo Overwriting existing files in "%INSTALL_DIR%"...
powershell -Command "Expand-Archive -Force '%ZIP_FILE%' '%INSTALL_DIR%'"

powershell -Command "Unblock-File -Path '%INSTALL_DIR%\Minecraft.Client.exe'"

echo Update complete.
pause
goto menu

:: ============================================================
:: USERNAME SETUP
:: ============================================================
:username_setup
:username_prompt
echo Enter username you wish to identify as (Must be valid for online play):
set /p username=

echo %username%| findstr /R "^[a-zA-Z0-9_][a-zA-Z0-9_]*$" >nul
if errorlevel 1 (
    echo WARNING: Invalid username. Multiplayer may fail.
    set /p confirm=RE ENTER TO CONFIRM: 
    if "%confirm%" NEQ "%username%" goto username_prompt
)

echo %username%>"%USERFILE%"
echo Username saved.
echo.

goto server_prompt

:: ============================================================
:: SERVER SETUP
:: ============================================================
:server_prompt
echo Enter the IP for a starting server (Type "SKIP" to skip):
set /p ip=

if /I "%ip%"=="SKIP" goto shortcut

set /p port=What is the port? (DEFAULT: 25565): 
if "%port%"=="" set port=25565

set /p sname=What would you like the name to be?: 

echo %ip%>>"%SERVERFILE%"
echo %port%>>"%SERVERFILE%"
echo %sname%>>"%SERVERFILE%"

echo Server added.
echo.

goto shortcut

:: ============================================================
:: SHORTCUT CREATION
:: ============================================================
:shortcut
echo Create a desktop shortcut? (HIGHLY RECOMMENDED)
set /p sc=Y/N: 
if /I "%sc%"=="Y" goto makeshortcut
goto finish

:makeshortcut
set DESKTOP=%USERPROFILE%\Desktop
powershell -command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%DESKTOP%\LCE.lnk');$s.TargetPath='\"C:\Program Files\LCEWindows64\Minecraft.Client.exe\"';$s.Save()"
echo Shortcut created.
goto finish

:: ============================================================
:: CHANGE USERNAME
:: ============================================================
:changeuser
cls
if not exist "%INSTALL_DIR%\Minecraft.Client.exe" (
    echo LCE is not installed.
    pause
    goto menu
)

echo Enter new username:
set /p newuser=
echo %newuser%>"%USERFILE%"
echo Username updated.
pause
goto menu

:: ============================================================
:: ADD SERVER
:: ============================================================
:addserver
cls
if not exist "%INSTALL_DIR%\Minecraft.Client.exe" (
    echo LCE is not installed.
    pause
    goto menu
)

echo Enter server IP:
set /p ip=
set /p port=Port (DEFAULT 25565): 
if "%port%"=="" set port=25565
set /p sname=Server name: 

echo %ip%>>"%SERVERFILE%"
echo %port%>>"%SERVERFILE%"
echo %sname%>>"%SERVERFILE%"

echo Server added.
pause
goto menu

:: ============================================================
:: REMOVE SERVER
:: ============================================================
:removeserver
cls
if not exist "%SERVERFILE%" (
    echo No servers to remove.
    pause
    goto menu
)

echo Current servers:
echo --------------------
set /a count=0
for /f "tokens=1-3" %%a in (%SERVERFILE%) do (
    set /a count+=1
    echo !count!) %%a %%b %%c
)

echo.
set /p del=Enter server number to remove: 

set /a lineStart=(del-1)*3+1
set /a lineEnd=lineStart+2

powershell -command "(Get-Content '%SERVERFILE%') | Where-Object {(\$global:i+=1) -lt %lineStart% -or \$i -gt %lineEnd%} | Set-Content '%SERVERFILE%'"

echo Server removed.
pause
goto menu

:: ============================================================
:: FINISH
:: ============================================================
:finish
echo Thanks for using the LCE install kit!
echo Visit https://github.com/smartcmd/MinecraftConsoles/graphs/contributors for credits.
pause
goto menu
