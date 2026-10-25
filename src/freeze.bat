
@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Seewo Freeze API Tool

rem ============================================================
rem  Configuration
rem ============================================================
set "IP=127.0.0.1"
set "DEF_PORT=6082"
set "REGKEY=HKLM\SOFTWARE\WOW6432Node\Zeus\Rpc\freeze"
set "PORT=%DEF_PORT%"
set "PORT_FOUND=0"

rem ============================================================
rem  1. Read port from registry (same as HFreezeApi::Init)
rem     Path: HKLM\SOFTWARE\WOW6432Node\Zeus\Rpc\freeze
rem     Value: port (REG_DWORD), fallback to 6082 if missing
rem ============================================================
set "PORT_HEX="
for /f "tokens=3" %%A in ('reg query "%REGKEY%" /v port /reg:64 2^>nul ^| findstr /i "REG_DWORD"') do set "PORT_HEX=%%A"

if defined PORT_HEX (
    set "PORT_HEX=!PORT_HEX:X=x!"
    set /a PORT=!PORT_HEX! 2>nul
    if !PORT! lss 1 set "PORT=%DEF_PORT%"
    if !PORT! gtr 0 set "PORT_FOUND=1"
)
if "%PORT_FOUND%"=="0" echo [INFO] Port not found in registry, using default %DEF_PORT%
echo [INFO] Registry: %REGKEY%
echo [INFO] Target:   %IP%:%PORT%
echo.

rem ============================================================
rem  Check curl
rem ============================================================
where curl >nul 2>nul
if errorlevel 1 (
    echo [ERROR] curl.exe not found. Windows 10 1803 or later is required.
    pause
    exit /b 1
)

rem ============================================================
rem  Main menu
rem ============================================================
:menu
cls
echo ========== Seewo Freeze API Tool ==========
echo Target: %IP%:%PORT%
echo.
echo   1. Query freeze status
echo   2. Set freeze (freeze specified drives)
echo   3. Clear freeze (unfreeze all)
echo   0. Exit
echo.
set "CHOICE="
set /p "CHOICE=Select [0-3]: "
if not defined CHOICE goto menu
if "%CHOICE%"=="1" goto do_query
if "%CHOICE%"=="2" goto do_set
if "%CHOICE%"=="3" goto do_clear
if "%CHOICE%"=="0" goto end
echo Invalid choice
pause
goto menu

rem ============================================================
rem  1. Query: GET /api/v1/get_disk_data
rem ============================================================
:do_query
echo.
echo ----- Current freeze status -----
curl -sS --max-time 10 -w "\n[HTTP] %%{http_code}\n" "http://%IP%:%PORT%/api/v1/get_disk_data"
if errorlevel 1 echo [ERROR] Request failed. Make sure the freeze service is running and the port is correct.
echo.
pause
goto menu

rem ============================================================
rem  2. Set: GET /api/v1/set?vol=<mask>
rem     mask = Σ (1 << (letter - 'A'))
rem ============================================================
:do_set
echo.
set "LETTERS="
set /p "LETTERS=Enter drive letters to freeze (e.g. CDE): "
if not defined LETTERS goto do_set
rem strip spaces
set "LETTERS=%LETTERS: =%"
call :CalcMask "%LETTERS%"
if "%MASK%"=="-1" (
    echo [ERROR] Invalid drive letters. Only A-Z are allowed.
    pause
    goto menu
)
echo [INFO] Letters %LETTERS% -^> vol=%MASK%
curl -sS --max-time 10 -w "\n[HTTP] %%{http_code}\n" "http://%IP%:%PORT%/api/v1/set?vol=%MASK%"
if errorlevel 1 echo [ERROR] Request failed. Make sure the freeze service is running and the port is correct.
echo.
pause
goto menu

rem ============================================================
rem  3. Clear: GET /api/v1/set?vol=0
rem     ("0" in SetFreezeVolume -> empty letters -> vol=0)
rem ============================================================
:do_clear
echo.
echo ----- Clear all freezes -----
curl -sS --max-time 10 -w "\n[HTTP] %%{http_code}\n" "http://%IP%:%PORT%/api/v1/set?vol=0"
if errorlevel 1 echo [ERROR] Request failed. Make sure the freeze service is running and the port is correct.
echo.
pause
goto menu

:end
echo Bye.
exit /b 0

rem ============================================================
rem  Subroutine: compute drive-letter mask
rem  Input : %1 = drive letters (e.g. "CDE")
rem  Output: MASK (-1 means invalid)
rem  Note  : matches HFreezeApi::CalculateVolumeMask
rem          A=bit0, B=bit1, C=bit2 ...
rem ============================================================
:CalcMask
set "LETTERS=%~1"
set "MASK="
set "PS_CMD=$s=$env:LETTERS;$m=0;$ok=$false;foreach($c in $s.ToUpper().ToCharArray()){$v=[int]$c;if($v -ge 65 -and $v -le 90){$m=$m -bor (1 -shl ($v-65));$ok=$true}};if($ok){$m}else{-1}"
for /f "delims=" %%M in ('powershell -NoProfile -Command "!PS_CMD!"') do set "MASK=%%M"
if not defined MASK set "MASK=-1"
exit /b 0