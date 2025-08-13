# PowerShell script to publish all KQL queries to Application Insights
# Usage: .\publish-queries-to-insights.ps1
# This script uses the dev environment configuration from env\.env.dev

param(
    [string]$EnvFile = "..\..\env\.env.dev"
)

Write-Host "🚀 Publishing KQL queries to Application Insights..." -ForegroundColor Green

# Load environment variables from .env.dev file
if (Test-Path $EnvFile) {
    Write-Host "📋 Loading environment from $EnvFile..." -ForegroundColor Cyan
    
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^([^#=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
} else {
    Write-Error "Environment file not found: $EnvFile"
    exit 1
}

# Extract configuration from environment
$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID
$ResourceGroupName = $env:AZURE_RESOURCE_GROUP_NAME
$ConnectionString = $env:APPLICATIONINSIGHTS_CONNECTION_STRING

# Parse Application Insights details from connection string
if ($ConnectionString -match 'InstrumentationKey=([^;]+)') {
    $InstrumentationKey = $matches[1]
} else {
    Write-Error "Could not parse InstrumentationKey from connection string"
    exit 1
}

if ($ConnectionString -match 'ApplicationId=([^;]+)') {
    $ApplicationId = $matches[1]
} else {
    Write-Warning "ApplicationId not found in connection string"
}

Write-Host "📊 Configuration:" -ForegroundColor Yellow
Write-Host "  Subscription: $SubscriptionId"
Write-Host "  Resource Group: $ResourceGroupName"
Write-Host "  Instrumentation Key: $InstrumentationKey"

# Check if Azure CLI is installed
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI is not installed. Please install it first: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Login check
Write-Host "🔐 Checking Azure CLI authentication..." -ForegroundColor Cyan
$loginStatus = az account show 2>$null
if (!$loginStatus) {
    Write-Host "Please login to Azure CLI first..." -ForegroundColor Yellow
    az login
}

# Set subscription
Write-Host "🎯 Setting active subscription..." -ForegroundColor Cyan
az account set --subscription $SubscriptionId

# Find Application Insights resource by instrumentation key
Write-Host "🔍 Finding Application Insights resource..." -ForegroundColor Cyan
$appInsightsResources = az monitor app-insights component show --resource-group $ResourceGroupName --query "[?instrumentationKey=='$InstrumentationKey']" 2>$null | ConvertFrom-Json

if ($appInsightsResources.Count -eq 0) {
    # Try to find by resource group if direct lookup fails
    $allResources = az monitor app-insights component list --resource-group $ResourceGroupName 2>$null | ConvertFrom-Json
    $appInsightsResource = $allResources | Where-Object { $_.instrumentationKey -eq $InstrumentationKey } | Select-Object -First 1
    
    if (!$appInsightsResource) {
        Write-Error "Could not find Application Insights resource with instrumentation key: $InstrumentationKey"
        Write-Host "Available Application Insights resources in $ResourceGroupName:" -ForegroundColor Yellow
        $allResources | ForEach-Object { Write-Host "  - $($_.name) ($($_.instrumentationKey))" }
        exit 1
    }
} else {
    $appInsightsResource = $appInsightsResources[0]
}

$WorkspaceName = $appInsightsResource.name
Write-Host "✅ Found Application Insights: $WorkspaceName" -ForegroundColor Green

$categories = @("core", "users", "performance", "errors", "advanced", "debugging")
$totalQueries = 0
$successfulQueries = 0

foreach ($category in $categories) {
    if (Test-Path $category) {
        Write-Host "📁 Processing $category queries..." -ForegroundColor Cyan
        
        $queries = Get-ChildItem "$category\*.kql"
        foreach ($query in $queries) {
            $queryName = [System.IO.Path]::GetFileNameWithoutExtension($query.Name)
            $queryContent = Get-Content $query.FullName -Raw
            $fullQueryName = "$category-$queryName"
            $categoryName = "TeamsBotTelemetry-$(([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($category)))"
            
            Write-Host "  💾 Publishing: $fullQueryName" -NoNewline
            
            try {
                # Publish query to Application Insights using Log Analytics workspace
                $result = az monitor log-analytics query save create `
                    --resource-group $ResourceGroupName `
                    --workspace-name $WorkspaceName `
                    --name $fullQueryName `
                    --description "Auto-saved KQL query from telemetry/$category/$($query.Name) - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" `
                    --query-text $queryContent `
                    --category $categoryName `
                    --output none 2>$null
                    
                if ($LASTEXITCODE -eq 0) {
                    Write-Host " ✅" -ForegroundColor Green
                    $successfulQueries++
                } else {
                    Write-Host " ❌ Failed" -ForegroundColor Red
                }
            } catch {
                Write-Host " ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
            }
            
            $totalQueries++
        }
    }
}

Write-Host "`n🎉 Completed! Published $successfulQueries out of $totalQueries queries to Application Insights." -ForegroundColor Green
Write-Host "📍 Resource: $WorkspaceName in $ResourceGroupName" -ForegroundColor Cyan
Write-Host "🌐 You can access them in the Azure portal:" -ForegroundColor Cyan
Write-Host "   https://portal.azure.com/#@/resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Insights/components/$WorkspaceName/logs" -ForegroundColor Blue
Write-Host "   Navigate to: Logs > Saved Queries > TeamsBotTelemetry-* categories" -ForegroundColor Cyan

if ($successfulQueries -lt $totalQueries) {
    Write-Host "`n⚠️  Some queries failed to publish. This might be due to:" -ForegroundColor Yellow
    Write-Host "   - Insufficient permissions on the Application Insights resource" -ForegroundColor Yellow
    Write-Host "   - Duplicate query names (if running multiple times)" -ForegroundColor Yellow
    Write-Host "   - Network connectivity issues" -ForegroundColor Yellow
}
