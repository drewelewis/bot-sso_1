# Set environment variables for Azure App Service
param(
    [string]$AppServiceName = "botd8b23c",
    [string]$ResourceGroup = "devops-ai-rg"
)

Write-Host "Setting environment variables for App Service: $AppServiceName"

# Application Insights and Telemetry Settings
$settings = @{
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = "InstrumentationKey=4712eaf5-9aa5-4a61-b07a-b184b446570a;IngestionEndpoint=https://eastus-8.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus.livediagnostics.monitor.azure.com/;ApplicationId=aa17ec95-b0ac-4838-988a-168c7d56977e"
    "TELEMETRY_SERVICE_NAME" = "ai-calendar-assistant"
    "TELEMETRY_SERVICE_VERSION" = "1.0.0"
    "ENVIRONMENT" = "production"
    
    # Bot Configuration
    "BOT_ID" = "2f25249c-5e31-4bbf-968a-c64164178c1b"
    "BOT_DOMAIN" = "botd8b23c.azurewebsites.net"
    "AAD_APP_CLIENT_ID" = "fbfc8778-52a1-47a0-9565-a95abf7effae"
    "AAD_APP_TENANT_ID" = "00648bab-6c91-4292-9a2a-2297df511222"
    "AAD_APP_OAUTH_AUTHORITY_HOST" = "https://login.microsoftonline.com"
    "BOT_TENANT_ID" = "00648bab-6c91-4292-9a2a-2297df511222"
}

# Convert settings to Azure CLI format
$settingsArray = @()
foreach ($key in $settings.Keys) {
    $settingsArray += "$key=`"$($settings[$key])`""
}
$settingsString = $settingsArray -join " "

# Set the app settings
Write-Host "Applying settings..."
$command = "az webapp config appsettings set --name $AppServiceName --resource-group $ResourceGroup --settings $settingsString"
Invoke-Expression $command

# Restart the app service
Write-Host "Restarting App Service..."
az webapp restart --name $AppServiceName --resource-group $ResourceGroup

Write-Host "Environment variables set successfully!"
Write-Host "Your bot should now start sending telemetry data to Application Insights."
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Wait 2-3 minutes for the restart to complete"
Write-Host "2. Send some messages to your bot in Teams"
Write-Host "3. Check Application Insights Logs for data"
