@echo off
REM Batch script to publish all KQL queries to Application Insights
REM This script calls the PowerShell script with your dev environment settings

echo 🚀 Publishing KQL queries to Application Insights using dev environment...
echo.

REM Check if PowerShell is available
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ PowerShell not found. Please install PowerShell or run the .ps1 script directly.
    pause
    exit /b 1
)

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "publish-queries-to-insights.ps1"

if %errorlevel% equ 0 (
    echo.
    echo ✅ Script completed successfully!
) else (
    echo.
    echo ❌ Script failed. Check the output above for details.
)

echo.
pause
