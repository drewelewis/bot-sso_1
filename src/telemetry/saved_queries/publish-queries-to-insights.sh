#!/bin/bash
# Bash script to publish all KQL queries to Application Insights
# Usage: ./publish-queries-to-insights.sh
# This script uses the dev environment configuration from env/.env.dev

ENV_FILE="../../env/.env.dev"

echo "🚀 Publishing KQL queries to Application Insights..."

# Load environment variables from .env.dev file
if [ -f "$ENV_FILE" ]; then
    echo "📋 Loading environment from $ENV_FILE..."
    
    # Export variables from env file, skipping comments and empty lines
    export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)
else
    echo "❌ Environment file not found: $ENV_FILE"
    exit 1
fi

# Extract configuration from environment
SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID
RESOURCE_GROUP_NAME=$AZURE_RESOURCE_GROUP_NAME
CONNECTION_STRING=$APPLICATIONINSIGHTS_CONNECTION_STRING

# Parse Application Insights details from connection string
INSTRUMENTATION_KEY=$(echo "$CONNECTION_STRING" | grep -o 'InstrumentationKey=[^;]*' | cut -d'=' -f2)
APPLICATION_ID=$(echo "$CONNECTION_STRING" | grep -o 'ApplicationId=[^;]*' | cut -d'=' -f2)

if [ -z "$INSTRUMENTATION_KEY" ]; then
    echo "❌ Could not parse InstrumentationKey from connection string"
    exit 1
fi

echo "📊 Configuration:"
echo "  Subscription: $SUBSCRIPTION_ID"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Instrumentation Key: $INSTRUMENTATION_KEY"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Login check
echo "🔐 Checking Azure CLI authentication..."
if ! az account show &> /dev/null; then
    echo "Please login to Azure CLI first..."
    az login
fi

# Set subscription
echo "🎯 Setting active subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

# Find Application Insights resource by instrumentation key
echo "🔍 Finding Application Insights resource..."
APP_INSIGHTS_RESOURCES=$(az monitor app-insights component list --resource-group "$RESOURCE_GROUP_NAME" --query "[?instrumentationKey=='$INSTRUMENTATION_KEY']" 2>/dev/null)

if [ "$(echo "$APP_INSIGHTS_RESOURCES" | jq '. | length')" -eq 0 ]; then
    echo "❌ Could not find Application Insights resource with instrumentation key: $INSTRUMENTATION_KEY"
    echo "Available Application Insights resources in $RESOURCE_GROUP_NAME:"
    az monitor app-insights component list --resource-group "$RESOURCE_GROUP_NAME" --query "[].{name:name,instrumentationKey:instrumentationKey}" --output table
    exit 1
fi

WORKSPACE_NAME=$(echo "$APP_INSIGHTS_RESOURCES" | jq -r '.[0].name')
echo "✅ Found Application Insights: $WORKSPACE_NAME"

categories=("core" "users" "performance" "errors" "advanced" "debugging")
total_queries=0
successful_queries=0

for category in "${categories[@]}"; do
    if [ -d "$category" ]; then
        echo "📁 Processing $category queries..."
        
        for query_file in "$category"/*.kql; do
            if [ -f "$query_file" ]; then
                query_name=$(basename "$query_file" .kql)
                query_content=$(cat "$query_file")
                full_query_name="$category-$query_name"
                category_name="TeamsBotTelemetry-$(echo "$category" | sed 's/.*/\u&/')"
                
                echo -n "  💾 Publishing: $full_query_name"
                
                # Publish query to Application Insights
                if az monitor log-analytics query save create \
                    --resource-group "$RESOURCE_GROUP_NAME" \
                    --workspace-name "$WORKSPACE_NAME" \
                    --name "$full_query_name" \
                    --description "Auto-saved KQL query from telemetry/$category/$(basename "$query_file") - $(date '+%Y-%m-%d %H:%M')" \
                    --query-text "$query_content" \
                    --category "$category_name" \
                    --output none 2>/dev/null; then
                    echo " ✅"
                    ((successful_queries++))
                else
                    echo " ❌ Failed"
                fi
                
                ((total_queries++))
            fi
        done
    fi
done

echo ""
echo "🎉 Completed! Published $successful_queries out of $total_queries queries to Application Insights."
echo "📍 Resource: $WORKSPACE_NAME in $RESOURCE_GROUP_NAME"
echo "🌐 You can access them in the Azure portal:"
echo "   https://portal.azure.com/#@/resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Insights/components/$WORKSPACE_NAME/logs"
echo "   Navigate to: Logs > Saved Queries > TeamsBotTelemetry-* categories"

if [ $successful_queries -lt $total_queries ]; then
    echo ""
    echo "⚠️  Some queries failed to publish. This might be due to:"
    echo "   - Insufficient permissions on the Application Insights resource"
    echo "   - Duplicate query names (if running multiple times)"
    echo "   - Network connectivity issues"
fi
