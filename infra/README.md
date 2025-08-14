# Infrastructure as Code for Telemetry Queries

This directory contains Bicep templates and scripts to deploy your bot infrastructure with telemetry monitoring using Infrastructure as Code.

## Files Overview

### Core Infrastructure
- **`azure.bicep`** - Main infrastructure template (App Service, Bot Registration, Log Analytics)
- **`azure.parameters.json`** - Parameter file for deployment
- **`cosmosdb.bicep`** - Optional Cosmos DB for bot state storage

### Telemetry Modules
- **`savedQueries.bicep`** - Static sample saved queries (3 examples)
- **`generatedSavedQueries.bicep`** - Generated from your .kql files (15+ queries)

### Deployment Scripts
- **`deploy-with-telemetry.ps1`** - Complete deployment script with telemetry
- **`../scripts/generate-saved-queries-bicep.ps1`** - Converts .kql to Bicep

## Quick Start

### 1. Deploy with Auto-Detected Parameters (Recommended)
```powershell
cd infra
# Uses your existing .env.dev values automatically
.\deploy-with-telemetry.ps1
```

### 2. Deploy with Custom Parameters
```powershell
.\deploy-with-telemetry.ps1 -ResourceBaseName "mybot" -ResourceGroup "mybot-rg"
```

### 3. Deploy with Static Sample Queries
```powershell
.\deploy-with-telemetry.ps1 -UseStaticQueries
```

### 4. Test Deployment (What-If)
```powershell
.\deploy-with-telemetry.ps1 -WhatIf
```

## Generated vs Static Queries

| Feature | Generated (`generatedSavedQueries.bicep`) | Static (`savedQueries.bicep`) |
|---------|-------------------------------------------|-------------------------------|
| **Source** | Auto-converted from your .kql files | Hand-written examples |
| **Count** | 15+ queries across all categories | 3 sample queries |
| **Maintenance** | Regenerate when .kql files change | Manual updates |
| **Content** | Your actual monitoring queries | Basic examples |

## Regenerating Queries

When you modify .kql files in `src/telemetry/saved_queries/`, regenerate the Bicep:

```powershell
cd scripts
.\generate-saved-queries-bicep.ps1
```

This updates `infra/generatedSavedQueries.bicep` with your latest queries.

## Deployment Parameters

### Auto-Detected from .env.dev
The deployment script automatically reads these values from your `env/.env.dev` file:
- **`AZURE_SUBSCRIPTION_ID`** → Sets target subscription
- **`AZURE_RESOURCE_GROUP_NAME`** → Sets target resource group  
- **`RESOURCE_SUFFIX`** → Used to build resourceBaseName (e.g., "d8b23c" → "botd8b23c")
- **`AAD_APP_CLIENT_ID`** → Azure AD app client ID
- **`AAD_APP_TENANT_ID`** → Azure AD tenant ID
- **`AAD_APP_OAUTH_AUTHORITY_HOST`** → OAuth authority host
- **`SECRET_AAD_APP_CLIENT_SECRET`** → Azure AD app client secret (if available)

### Manual Override Parameters
- **`-ResourceBaseName`** - Override auto-detected base name
- **`-ResourceGroup`** - Override auto-detected resource group
- **`-SubscriptionId`** - Override auto-detected subscription
- **`-Location`** - Azure region (default: eastus)

### Optional Telemetry Parameters
- **`-UseStaticQueries`** - Use sample queries instead of generated ones
- **`-WhatIf`** - Preview changes without deploying

## What Gets Deployed

### Always
- App Service + App Service Plan
- User-Assigned Managed Identity  
- Bot Framework Registration

### With `deployTelemetry=true`
- Log Analytics Workspace (30-day retention)
- Saved KQL queries in categories:
  - **TeamsBotTelemetry-Core** - Message volume, response times, success rates
  - **TeamsBotTelemetry-Users** - Active users, engagement patterns
  - **TeamsBotTelemetry-Performance** - AI response times, bottlenecks
  - **TeamsBotTelemetry-Errors** - SSO errors, exceptions
  - **TeamsBotTelemetry-Advanced** - Health dashboard, custom metrics
  - **TeamsBotTelemetry-Debugging** - Data exploration, troubleshooting

## Accessing Deployed Queries

After deployment:

1. **Azure Portal** → **Log Analytics workspaces** → `<resourceBaseName>-law`
2. **Logs** → **Saved Queries** 
3. Look for **TeamsBotTelemetry-*** categories
4. Click any query → **Run** → Customize time range

## Integration with Bot Code

Your bot's telemetry service (`src/telemetry/telemetryService.ts`) will automatically send data to the Log Analytics workspace. Update your connection string:

```typescript
// In your bot's environment configuration
APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=<key>;IngestionEndpoint=https://<region>.in.applicationinsights.azure.com/"
```

## Advanced Usage

### Custom Deployment
```bash
az deployment group create \
  --resource-group mybot-rg \
  --template-file azure.bicep \
  --parameters resourceBaseName=mybot deployTelemetry=true useGeneratedSavedQueries=true
```

### CI/CD Integration
```yaml
# Azure DevOps Pipeline
- task: AzureCLI@2
  inputs:
    azureSubscription: 'my-subscription'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      cd infra
      az deployment group create --resource-group $(resourceGroup) --template-file azure.bicep --parameters @azure.parameters.json deployTelemetry=true
```

### Updating Queries
1. Modify .kql files in `src/telemetry/saved_queries/`
2. Run `scripts/generate-saved-queries-bicep.ps1`
3. Redeploy: `az deployment group create ...`

## Troubleshooting

### Common Issues
- **"File not found: generatedSavedQueries.bicep"** → Run the generator script first
- **"Invalid KQL syntax"** → Check your .kql files for syntax errors
- **"Deployment failed"** → Verify AAD app parameters in `.env.dev`

### Validation
```powershell
# Check Bicep syntax
az bicep build --file azure.bicep

# Validate deployment
az deployment group validate --resource-group mybot-rg --template-file azure.bicep --parameters @azure.parameters.json
```

This IaC approach ensures your telemetry queries are versioned, deployable, and consistent across environments!
