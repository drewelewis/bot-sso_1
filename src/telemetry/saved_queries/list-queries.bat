@echo off
REM List all available KQL queries

echo 📊 Available KQL Queries
echo ========================

for /d %%d in (core users performance errors advanced debugging) do (
    if exist "%%d" (
        echo.
        echo 📁 %%d/
        for %%f in ("%%d\*.kql") do echo    %%f
    )
)

echo.
echo Usage: Copy any .kql file content to Application Insights Logs
pause
