# PowerShell Script to Save KQL Queries in Application Insights
# Update these variables with your Azure details

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ApplicationInsightsName,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId
)

# Set the subscription
az account set --subscription $SubscriptionId

Write-Host "Setting up saved queries for Application Insights: $ApplicationInsightsName" -ForegroundColor Green

# Core Bot Metrics Queries
$coreQueries = @(
    @{
        name = "Bot-MessageVolume"
        displayName = "Message Volume Over Time"
        description = "Shows bot message volume by hour"
        category = "Bot-Core"
        query = @"
traces
| where name == "bot_message_processing"
| summarize MessageCount = count() by bin(timestamp, 1h)
| render timechart
"@
    },
    @{
        name = "Bot-ResponseTime"
        displayName = "Response Time Analysis"
        description = "Bot response time percentiles"
        category = "Bot-Core"
        query = @"
traces
| where name == "bot_message_processing"
| extend ResponseTime = todouble(customDimensions["bot.response_time_ms"])
| where isnotnull(ResponseTime)
| summarize 
    AvgResponseTime = avg(ResponseTime),
    P50ResponseTime = percentile(ResponseTime, 50),
    P95ResponseTime = percentile(ResponseTime, 95),
    P99ResponseTime = percentile(ResponseTime, 99)
    by bin(timestamp, 1h)
| render timechart
"@
    },
    @{
        name = "Bot-SuccessRate"
        displayName = "Success Rate by Hour"
        description = "Bot message processing success rate"
        category = "Bot-Core"
        query = @"
traces
| where name == "bot_message_processing"
| extend Success = tobool(customDimensions["bot.success"])
| summarize 
    Total = count(),
    Successful = countif(Success == true),
    SuccessRate = todouble(countif(Success == true)) / count() * 100
    by bin(timestamp, 1h)
| render timechart
"@
    },
    @{
        name = "Bot-EventOverview"
        displayName = "All Bot Events Overview"
        description = "Overview of all bot events"
        category = "Bot-Core"
        query = @"
traces
| where name in (
    "Message_Received", "AI_Response_Requested", "AI_Response_Sent",
    "SSO_Command_Triggered", "SSO_Dialog_Started", "SSO_Dialog_Completed",
    "External_AI_Request", "External_AI_Success", "External_AI_Error",
    "Clear_History_Started", "Clear_History_Success", "ProactiveMessage_Sent"
)
| summarize Count = count() by name, bin(timestamp, 1h)
| render timechart
"@
    },
    @{
        name = "Bot-HealthDashboard"
        displayName = "Bot Health Dashboard"
        description = "Comprehensive system health metrics"
        category = "Bot-Health"
        query = @"
let timeWindow = 1h;
let messages = traces | where timestamp > ago(timeWindow) and name == "bot_message_processing" | count;
let errors = exceptions | where timestamp > ago(timeWindow) | count;
let avgResponseTime = traces 
    | where timestamp > ago(timeWindow) and isnotnull(customDimensions["bot.response_time_ms"])
    | extend ResponseTime = todouble(customDimensions["bot.response_time_ms"])
    | summarize avg(ResponseTime);
let aiRequests = traces | where timestamp > ago(timeWindow) and name == "External_AI_Request" | count;
let aiErrors = traces | where timestamp > ago(timeWindow) and name == "External_AI_Error" | count;
print 
    Messages = toscalar(messages),
    Errors = toscalar(errors),
    AvgResponseTime_ms = toscalar(avgResponseTime),
    AIRequests = toscalar(aiRequests),
    AIErrors = toscalar(aiErrors),
    AISuccessRate = round(100.0 * (toscalar(aiRequests) - toscalar(aiErrors)) / toscalar(aiRequests), 2)
"@
    }
)

# User Analytics Queries
$userQueries = @(
    @{
        name = "Bot-ActiveUsers"
        displayName = "Active Users"
        description = "Daily active users"
        category = "Bot-Users"
        query = @"
traces
| where name == "bot_message_processing"
| extend UserId = tostring(customDimensions["bot.user_id"])
| where isnotempty(UserId) and UserId != "unknown"
| summarize UniqueUsers = dcount(UserId) by bin(timestamp, 1d)
| render timechart
"@
    },
    @{
        name = "Bot-PeakHours"
        displayName = "Peak Usage Hours"
        description = "Bot usage by hour of day"
        category = "Bot-Users"
        query = @"
traces
| where name == "Message_Received"
| extend HourOfDay = hourofday(timestamp)
| summarize MessageCount = count() by HourOfDay
| render columnchart title="Bot Usage by Hour (UTC)"
"@
    },
    @{
        name = "Bot-EngagementFunnel"
        displayName = "User Engagement Funnel"
        description = "User journey through bot features"
        category = "Bot-Users"
        query = @"
let users = traces
| where timestamp > ago(1d) and name == "Message_Received"
| extend UserId = tostring(customDimensions["userId"])
| where isnotempty(UserId)
| summarize by UserId;
let ssoUsers = traces
| where timestamp > ago(1d) and name == "SSO_Command_Triggered"
| extend UserId = tostring(customDimensions["userId"])
| where isnotempty(UserId)
| summarize by UserId;
let aiUsers = traces
| where timestamp > ago(1d) and name == "AI_Response_Requested"
| extend UserId = tostring(customDimensions["userId"])
| where isnotempty(UserId)
| summarize by UserId;
print 
    TotalUsers = toscalar(users | count),
    UsersWhoTriedSSO = toscalar(ssoUsers | count),
    UsersWhoUsedAI = toscalar(aiUsers | count),
    SSOAdoptionRate = round(100.0 * toscalar(ssoUsers | count) / toscalar(users | count), 2),
    AIAdoptionRate = round(100.0 * toscalar(aiUsers | count) / toscalar(users | count), 2)
"@
    }
)

# Performance Queries
$performanceQueries = @(
    @{
        name = "Bot-OperationPerformance"
        displayName = "Operation Performance Analysis"
        description = "Performance analysis for all operations"
        category = "Bot-Performance"
        query = @"
traces
| where isnotempty(customDimensions["operation.duration_ms"])
| extend 
    OperationName = tostring(customDimensions["operation.name"]),
    Duration = todouble(customDimensions["operation.duration_ms"]),
    Success = tobool(customDimensions["operation.success"])
| summarize 
    Count = count(),
    AvgDuration = avg(Duration),
    P95Duration = percentile(Duration, 95),
    SuccessRate = todouble(countif(Success == true)) / count() * 100
    by OperationName
| order by AvgDuration desc
"@
    },
    @{
        name = "Bot-AIResponseTime"
        displayName = "AI Response Time Distribution"
        description = "AI response performance breakdown"
        category = "Bot-Performance"
        query = @"
traces
| where name == "External_AI_API"
| extend Duration = todouble(customDimensions["operation.duration_ms"])
| where isnotnull(Duration)
| summarize 
    ["< 1sec"] = countif(Duration < 1000),
    ["1-3sec"] = countif(Duration >= 1000 and Duration < 3000),
    ["3-5sec"] = countif(Duration >= 3000 and Duration < 5000),
    ["5-10sec"] = countif(Duration >= 5000 and Duration < 10000),
    ["> 10sec"] = countif(Duration >= 10000)
"@
    }
)

# Error Analysis Queries
$errorQueries = @(
    @{
        name = "Bot-FailedOperations"
        displayName = "Failed Operations"
        description = "Operations that failed"
        category = "Bot-Errors"
        query = @"
traces
| where customDimensions["operation.success"] == "false"
| extend OperationName = tostring(customDimensions["operation.name"])
| summarize ErrorCount = count() by OperationName, bin(timestamp, 1h)
| render timechart
"@
    },
    @{
        name = "Bot-SSOErrors"
        displayName = "SSO-Specific Issues"
        description = "SSO authentication problems"
        category = "Bot-Errors"
        query = @"
traces
| where name has "SSO" and (name has "Failed" or name has "Missing" or name has "Error")
| summarize Count = count() by name, bin(timestamp, 1h)
| render timechart
"@
    }
)

# Function to create saved query
function New-SavedQuery {
    param($query, $resourceGroup, $appInsightsName)
    
    $queryJson = @{
        displayName = $query.displayName
        description = $query.description
        body = $query.query
        categories = @($query.category)
        tags = @{
            "created-by" = "automation"
            "bot-queries" = "true"
        }
    } | ConvertTo-Json -Depth 3
    
    Write-Host "Creating query: $($query.displayName)" -ForegroundColor Yellow
    
    try {
        # Create the saved query using REST API call through Azure CLI
        $result = az rest --method POST `
            --url "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Insights/components/$appInsightsName/savedqueries/$($query.name)?api-version=2015-05-01" `
            --body $queryJson
            
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Created: $($query.displayName)" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed: $($query.displayName)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Error creating $($query.displayName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create all queries
Write-Host "`n🚀 Creating Core Bot Metrics..." -ForegroundColor Cyan
foreach ($query in $coreQueries) {
    New-SavedQuery -query $query -resourceGroup $ResourceGroupName -appInsightsName $ApplicationInsightsName
}

Write-Host "`n👥 Creating User Analytics..." -ForegroundColor Cyan
foreach ($query in $userQueries) {
    New-SavedQuery -query $query -resourceGroup $ResourceGroupName -appInsightsName $ApplicationInsightsName
}

Write-Host "`n⚡ Creating Performance Queries..." -ForegroundColor Cyan
foreach ($query in $performanceQueries) {
    New-SavedQuery -query $query -resourceGroup $ResourceGroupName -appInsightsName $ApplicationInsightsName
}

Write-Host "`n🚨 Creating Error Analysis..." -ForegroundColor Cyan
foreach ($query in $errorQueries) {
    New-SavedQuery -query $query -resourceGroup $ResourceGroupName -appInsightsName $ApplicationInsightsName
}

Write-Host "`n✅ Saved queries setup complete!" -ForegroundColor Green
Write-Host "You can now find these queries in Application Insights > Logs > Saved Queries" -ForegroundColor Yellow
