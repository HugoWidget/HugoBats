@echo off
setlocal enabledelayedexpansion
title Continuously close seewo processes - Press Ctrl+C to exit

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Requesting administrator privileges...
    powershell.exe -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\" %*\"' -Verb RunAs"
    exit /b
)

echo [INFO] Administrator privileges confirmed.

set "INTERVAL=3"
set "EXCLUDE=SeewoFreezeUpdateAssist.exe"
set /a total=0

:loop
set /a round=0

:retry
set /a round+=1
set "killed=0"

for /f "tokens=1 delims=," %%A in ('tasklist /FO CSV /NH 2^>nul') do (
    set "pname=%%~A"
    if /i "!pname:~0,5!"=="seewo" (
        if /i not "!pname!"=="!EXCLUDE!" (
            echo [!date! !time!] Killing process: !pname!
            taskkill /F /T /IM "!pname!" >nul 2>&1
            set "killed=1"
        ) else (
            echo [!date! !time!] Skipping process: !pname!
        )
    )
)

if "!killed!"=="1" (
    set /a total+=1
    if !round! lss 5 (
        timeout /t 1 /nobreak >nul
        goto retry
    )
)

timeout /t !INTERVAL! /nobreak >nul
goto loop