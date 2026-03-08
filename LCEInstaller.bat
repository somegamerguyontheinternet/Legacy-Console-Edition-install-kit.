@echo off
title LCE Windows Installer
setlocal EnableDelayedExpansion

:: --- CONSTANT PATHS ---
set INSTALL_DIR=C:\Program Files\LCEWindows64
set ZIP_FILE=LCEWindows64.zip
set USERFILE=%INSTALL_DIR%\username.txt
set SERVERFILE=%INSTALL_DIR%\servers.txt

:: --- MAIN MENU ---
:menu
cls
echo ================================
echo   LCE Windows Install Utility
echo ================================
echo 1) Install / Reinstall LCE
echo 2) Change Username
echo 3) Add a Server
echo 4) Remove a Server
echo 5) Exit
echo.
set /p choice=Select an option: 

if "%choice%"=="1" goto install
if "%choice%"=="2" goto changeuser
if "%choice%"=="3" goto addserver
if "%choice%"=="4" goto removeserver
if "%choice%"=="5" exit
goto menu

:: --- INSTALLATION ---
:install
cls
echo WARNING: NOT APPROVED OR ASSOCIATED WITH MOJANG
echo Side note: You may get a Windows pop-up because this project has no publisher.
echo.
echo Installing to: %INSTALL_DIR%
echo.

if not exist "%ZIP_FILE%" (
    echo ERROR: %ZIP_FILE% not found in this folder.
    pause
    goto menu
)

echo Creating install directory...
mkdir "%INSTALL_DIR%" >nul 2>&1

echo Extracting files...
powershell -command "Expand-Archive -Force '%ZIP_FILE%' '%INSTALL_DIR%'" >nul 2>&1

echo Extraction complete.
echo.

:: --- USERNAME SETUP ---
:username_prompt
echo Enter username you wish to identify as:
set /p username=

:: Username must be 3–16 chars, letters/numbers/underscore
echo %username%| findstr /R "^[a-zA-Z0-9_][a-zA-Z0-9_][a-zA-Z0-9_][a-zA-Z0-9_]*$" >nul
if errorlevel 1 (
    echo WARNING: This username is invalid and multiplayer may fail.
    set /p confirm=RE ENTER TO CONFIRM: 
    if "%confirm%" NEQ "%username%" goto username_prompt
)

echo %username%>"%USERFILE%"
echo Username saved.
echo.

:: --- SERVER SETUP ---
:add_server_prompt
echo Enter the IP for a starting server (Type "SKIP" to skip):
set /p ip=

if /I "%ip%"=="SKIP" goto shortcut

set /p port=What is the port of your server? (DEFAULT: 25565): 
if "%port%"=="" set port=25565

set /p sname=What would you like the name to be?: 

echo %ip%>>"%SERVERFILE%"
echo %port%>>"%SERVERFILE%"
echo %sname%>>"%SERVERFILE%"

echo Server added.
echo.

goto shortcut

:: --- SHORTCUT CREATION ---
:shortcut
echo Create a desktop shortcut? (HIGHLY RECOMMENDED)
set /p sc=Y/N: 
if /I "%sc%"=="Y" goto makeshortcut
goto finish

:makeshortcut
set DESKTOP=%USERPROFILE%\Desktop
powershell -command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%DESKTOP%\LCE.lnk');$s.TargetPath='%INSTALL_DIR%\Minecraft.Client.exe';$s.Save()"
echo Shortcut created.
goto finish

:: --- CHANGE USERNAME ---
:changeuser
cls
if not exist "%INSTALL_DIR%" (
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

:: --- ADD SERVER ---
:addserver
cls
if not exist "%INSTALL_DIR%" (
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

:: --- REMOVE SERVER ---
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

:finish
echo Thanks for using the LCE install kit!
echo Visit https://github.com/smartcmd/MinecraftConsoles/graphs/contributors for credits.
pause
goto menu