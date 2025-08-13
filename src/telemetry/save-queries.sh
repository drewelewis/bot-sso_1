# Bash script for Linux/Mac users
#!/bin/bash

# Application Insights Saved Queries Setup Script
# Usage: ./save-queries.sh <resource-group> <app-insights-name> <subscription-id>

if [ $# -ne 3 ]; then
    echo "Usage: $0 <resource-group> <app-insights-name> <subscription-id>"
    echo "Example: $0 my-rg my-app-insights 12345678-1234-1234-1234-123456789012"
    exit 1
fi

RESOURCE_GROUP=$1
APP_INSIGHTS_NAME=$2
SUBSCRIPTION_ID=$3

echo "🚀 Setting up saved queries for Application Insights: $APP_INSIGHTS_NAME"

# Set subscription
az account set --subscription $SUBSCRIPTION_ID

# Function to create saved query
create_saved_query() {
    local name=$1
    local display_name=$2
    local description=$3
    local category=$4
    local query=$5
    
    local json_body=$(cat <<EOF
{
    "displayName": "$display_name",
    "description": "$description", 
    "body": "$query",
    "categories": ["$category"],
    "tags": {
        "created-by": "automation",
        "bot-queries": "true"
    }
}
EOF
)
    
    echo "Creating query: $display_name"
    
    az rest --method POST \
        --url "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Insights/components/$APP_INSIGHTS_NAME/savedqueries/$name?api-version=2015-05-01" \
        --body "$json_body" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Created: $display_name"
    else
        echo "❌ Failed: $display_name"
    fi
}

# Core Bot Metrics
echo "📊 Creating Core Bot Metrics..."

create_saved_query "Bot-MessageVolume" \
    "Message Volume Over Time" \
    "Shows bot message volume by hour" \
    "Bot-Core" \
    "traces | where name == \"bot_message_processing\" | summarize MessageCount = count() by bin(timestamp, 1h) | render timechart"

create_saved_query "Bot-ResponseTime" \
    "Response Time Analysis" \
    "Bot response time percentiles" \
    "Bot-Core" \
    "traces | where name == \"bot_message_processing\" | extend ResponseTime = todouble(customDimensions[\"bot.response_time_ms\"]) | where isnotnull(ResponseTime) | summarize AvgResponseTime = avg(ResponseTime), P50ResponseTime = percentile(ResponseTime, 50), P95ResponseTime = percentile(ResponseTime, 95), P99ResponseTime = percentile(ResponseTime, 99) by bin(timestamp, 1h) | render timechart"

create_saved_query "Bot-SuccessRate" \
    "Success Rate by Hour" \
    "Bot message processing success rate" \
    "Bot-Core" \
    "traces | where name == \"bot_message_processing\" | extend Success = tobool(customDimensions[\"bot.success\"]) | summarize Total = count(), Successful = countif(Success == true), SuccessRate = todouble(countif(Success == true)) / count() * 100 by bin(timestamp, 1h) | render timechart"

# User Analytics
echo "👥 Creating User Analytics..."

create_saved_query "Bot-ActiveUsers" \
    "Active Users" \
    "Daily active users" \
    "Bot-Users" \
    "traces | where name == \"bot_message_processing\" | extend UserId = tostring(customDimensions[\"bot.user_id\"]) | where isnotempty(UserId) and UserId != \"unknown\" | summarize UniqueUsers = dcount(UserId) by bin(timestamp, 1d) | render timechart"

create_saved_query "Bot-PeakHours" \
    "Peak Usage Hours" \
    "Bot usage by hour of day" \
    "Bot-Users" \
    "traces | where name == \"Message_Received\" | extend HourOfDay = hourofday(timestamp) | summarize MessageCount = count() by HourOfDay | render columnchart"

# Health Dashboard
echo "🏥 Creating Health Dashboard..."

create_saved_query "Bot-HealthDashboard" \
    "Bot Health Dashboard" \
    "Comprehensive system health metrics" \
    "Bot-Health" \
    "let timeWindow = 1h; let messages = traces | where timestamp > ago(timeWindow) and name == \"bot_message_processing\" | count; let errors = exceptions | where timestamp > ago(timeWindow) | count; let avgResponseTime = traces | where timestamp > ago(timeWindow) and isnotnull(customDimensions[\"bot.response_time_ms\"]) | extend ResponseTime = todouble(customDimensions[\"bot.response_time_ms\"]) | summarize avg(ResponseTime); print Messages = toscalar(messages), Errors = toscalar(errors), AvgResponseTime_ms = toscalar(avgResponseTime)"

echo "✅ Saved queries setup complete!"
echo "You can now find these queries in Application Insights > Logs > Saved Queries"
