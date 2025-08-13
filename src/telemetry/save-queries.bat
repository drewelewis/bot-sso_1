@echo off
REM Batch script to save KQL queries in Application Insights
REM Usage: save-queries.bat <resource-group> <app-insights-name> <subscription-id>

if "%~3"=="" (
    echo Usage: %0 ^<resource-group^> ^<app-insights-name^> ^<subscription-id^>
    echo Example: %0 my-rg my-app-insights 12345678-1234-1234-1234-123456789012
    exit /b 1
)

set RESOURCE_GROUP=%1
set APP_INSIGHTS_NAME=%2
set SUBSCRIPTION_ID=%3

echo 🚀 Setting up saved queries for Application Insights: %APP_INSIGHTS_NAME%

REM Set subscription
az account set --subscription %SUBSCRIPTION_ID%

echo ✅ Use the PowerShell script save-queries.ps1 for full functionality
echo    PowerShell: .\save-queries.ps1 -ResourceGroupName "%RESOURCE_GROUP%" -ApplicationInsightsName "%APP_INSIGHTS_NAME%" -SubscriptionId "%SUBSCRIPTION_ID%"

pause
