# Corrected OpenTelemetry KQL Queries for Teams Bot

This document contains **corrected** KQL queries that work with your actual OpenTelemetry implementation.

## Your Actual Data Structure

Based on your telemetry service, data appears in:
- **`traces`** - Contains spans with `name` field (not `message`)
- **`customMetrics`** - Contains metrics from your meter
- **`dependencies`** - External API calls
- **`exceptions`** - Exception data

## Core Bot Metrics (Corrected)

### Message Volume Over Time
```kql
traces
| where name == "bot_message_processing"
| summarize MessageCount = count() by bin(timestamp, 1h)
| render timechart
```

### Response Time Analysis (Fixed Field References)
```kql
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
```

### Success Rate by Hour (Fixed)
```kql
traces
| where name == "bot_message_processing"
| extend Success = tobool(customDimensions["bot.success"])
| summarize 
    Total = count(),
    Successful = countif(Success == true),
    SuccessRate = todouble(countif(Success == true)) / count() * 100
    by bin(timestamp, 1h)
| render timechart
```

## Your Actual Custom Events

### All Bot Events Overview
```kql
traces
| where name in (
    "Message_Received", "AI_Response_Requested", "AI_Response_Sent",
    "SSO_Command_Triggered", "SSO_Dialog_Started", "SSO_Dialog_Completed",
    "External_AI_Request", "External_AI_Success", "External_AI_Error",
    "Clear_History_Started", "Clear_History_Success", "ProactiveMessage_Sent"
)
| summarize Count = count() by name, bin(timestamp, 1h)
| render timechart
```

### SSO Authentication Flow
```kql
traces
| where name has "SSO"
| summarize Count = count() by name, bin(timestamp, 1h)
| render timechart
```

### AI Response Performance
```kql
traces
| where name in ("AI_Response_Requested", "AI_Response_Sent", "External_AI_Success", "External_AI_Error")
| summarize Count = count() by name, bin(timestamp, 1h)
| render timechart
```

## User Engagement Analytics (Fixed)

### Active Users
```kql
traces
| where name == "bot_message_processing"
| extend UserId = tostring(customDimensions["bot.user_id"])
| where isnotempty(UserId) and UserId != "unknown"
| summarize UniqueUsers = dcount(UserId) by bin(timestamp, 1d)
| render timechart
```

### Most Active Users
```kql
traces
| where name == "bot_message_processing"
| extend UserId = tostring(customDimensions["bot.user_id"])
| where isnotempty(UserId) and UserId != "unknown"
| summarize MessageCount = count() by UserId
| top 10 by MessageCount
```

### Operation Performance Analysis
```kql
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
```

## Error Analysis (Corrected)

### Failed Operations
```kql
traces
| where customDimensions["operation.success"] == "false"
| extend OperationName = tostring(customDimensions["operation.name"])
| summarize ErrorCount = count() by OperationName, bin(timestamp, 1h)
| render timechart
```

### All Exceptions
```kql
exceptions
| summarize Count = count() by type, bin(timestamp, 1h)
| render timechart
```

### SSO-Specific Issues
```kql
traces
| where name has "SSO" and (name has "Failed" or name has "Missing" or name has "Error")
| summarize Count = count() by name, bin(timestamp, 1h)
| render timechart
```

## Quick Debugging Queries

### Check What Data You Actually Have
```kql
// See all span names in your data
traces
| summarize count() by name
| order by count_ desc
```

```kql
// Check your custom dimensions structure
traces
| take 5
| project name, customDimensions
```

```kql
// Look for recent bot activity
traces
| where timestamp > ago(1h) and (name has "bot" or name has "Message" or name has "SSO" or name has "AI")
| project timestamp, name, customDimensions
| order by timestamp desc
| take 20
```

## Performance Dashboard Query
```kql
let timeRange = 1h;
let totalMessages = traces
| where timestamp > ago(timeRange) and name == "bot_message_processing"
| count;
let successRate = traces
| where timestamp > ago(timeRange) and name == "bot_message_processing"
| extend Success = tobool(customDimensions["bot.success"])
| summarize SuccessRate = todouble(countif(Success == true)) / count() * 100;
let avgResponseTime = traces
| where timestamp > ago(timeRange) and isnotnull(customDimensions["bot.response_time_ms"])
| extend ResponseTime = todouble(customDimensions["bot.response_time_ms"])
| summarize AvgResponseTime = avg(ResponseTime);
print 
    TotalMessages = toscalar(totalMessages), 
    SuccessRate = toscalar(successRate), 
    AvgResponseTime = toscalar(avgResponseTime)
```

## 🚀 Next Steps

1. **Test Basic Query First:**
```kql
traces | take 10
```

2. **Find Your Span Names:**
```kql
traces | summarize count() by name | order by count_ desc
```

3. **Use the corrected queries above** - they match your actual telemetry service implementation

## 📊 Additional Valuable Queries

### Application Lifecycle Monitoring
```kql
// App starts and shutdowns
traces
| where name in ("Application_Started", "Application_Shutdown")
| summarize Count = count() by name, bin(timestamp, 1d)
| render timechart
```

### Proactive Messaging Analytics
```kql
// Proactive message flow
traces
| where name has "ProactiveMessage"
| summarize Count = count() by name, bin(timestamp, 1h)
| render timechart
```

### Complete SSO Authentication Journey
```kql
// Full SSO flow from start to finish
traces
| where name has "SSO"
| summarize Count = count() by name
| render piechart title="SSO Event Distribution"
```

### AI Response Time Distribution
```kql
// AI response performance breakdown
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
```

### User Conversation Patterns
```kql
// Messages per user session
traces
| where name == "bot_message_processing"
| extend 
    UserId = tostring(customDimensions["bot.user_id"]),
    ConversationId = tostring(customDimensions["bot.conversation_id"])
| where isnotempty(UserId) and UserId != "unknown"
| summarize MessageCount = count() by UserId, ConversationId
| summarize 
    SingleMessage = countif(MessageCount == 1),
    ShortConvo = countif(MessageCount >= 2 and MessageCount <= 5),
    MediumConvo = countif(MessageCount >= 6 and MessageCount <= 15),
    LongConvo = countif(MessageCount > 15)
```

### Error Context Analysis
```kql
// Errors with user context
exceptions
| join kind=leftouter (
    traces
    | where timestamp > ago(1d)
    | extend UserId = tostring(customDimensions["bot.user_id"])
    | where isnotempty(UserId)
    | summarize by UserId, bin(timestamp, 1m)
) on $left.timestamp == $right.timestamp
| project timestamp, type, outerMessage, UserId
| where isnotempty(UserId)
| summarize ErrorCount = count() by UserId, type
| top 10 by ErrorCount
```

### Peak Usage Hours
```kql
// Bot usage by hour of day
traces
| where name == "Message_Received"
| extend HourOfDay = hourofday(timestamp)
| summarize MessageCount = count() by HourOfDay
| render columnchart title="Bot Usage by Hour (UTC)"
```

### Message Type Analysis
```kql
// What types of messages are users sending
traces
| where name == "bot_message_processing"
| extend MessageType = tostring(customDimensions["bot.message_type"])
| summarize Count = count() by MessageType
| render piechart title="Message Types"
```

### Conversation History Clearing Patterns
```kql
// How often users clear their history
traces
| where name has "Clear_History"
| extend 
    UserId = tostring(customDimensions["userId"]),
    Success = name == "Clear_History_Success"
| summarize 
    TotalAttempts = count(),
    SuccessfulClears = countif(Success),
    UniqueUsers = dcount(UserId)
    by bin(timestamp, 1d)
| render timechart
```

### Custom Metrics Analysis
```kql
// Your OpenTelemetry custom metrics
customMetrics
| where name startswith "bot_"
| summarize Count = count(), AvgValue = avg(value), MaxValue = max(value) by name
| order by Count desc
```

### Retry Pattern Analysis
```kql
// Look for retry patterns in AI requests
traces
| where name == "External_AI_Request"
| extend 
    UserId = tostring(customDimensions["userId"]),
    ConversationId = tostring(customDimensions["conversationId"])
| summarize RequestCount = count() by UserId, ConversationId, bin(timestamp, 1m)
| where RequestCount > 1
| summarize RetryUsers = dcount(UserId), TotalRetries = sum(RequestCount - 1) by bin(timestamp, 1h)
| render timechart title="AI Request Retries"
```

### Service Health Dashboard (Advanced)
```kql
// Comprehensive health metrics
let timeWindow = 1h;
let messages = traces | where timestamp > ago(timeWindow) and name == "bot_message_processing" | count;
let errors = exceptions | where timestamp > ago(timeWindow) | count;
let avgResponseTime = traces 
    | where timestamp > ago(timeWindow) and isnotnull(customDimensions["bot.response_time_ms"])
    | extend ResponseTime = todouble(customDimensions["bot.response_time_ms"])
    | summarize avg(ResponseTime);
let aiRequests = traces | where timestamp > ago(timeWindow) and name == "External_AI_Request" | count;
let aiErrors = traces | where timestamp > ago(timeWindow) and name == "External_AI_Error" | count;
let ssoAttempts = traces | where timestamp > ago(timeWindow) and name == "SSO_Dialog_Started" | count;
let ssoSuccess = traces | where timestamp > ago(timeWindow) and name == "SSO_Dialog_Completed" | count;
print 
    Messages = toscalar(messages),
    Errors = toscalar(errors),
    AvgResponseTime_ms = toscalar(avgResponseTime),
    AIRequests = toscalar(aiRequests),
    AIErrors = toscalar(aiErrors),
    AISuccessRate = round(100.0 * (toscalar(aiRequests) - toscalar(aiErrors)) / toscalar(aiRequests), 2),
    SSOAttempts = toscalar(ssoAttempts),
    SSOSuccessRate = round(100.0 * toscalar(ssoSuccess) / toscalar(ssoAttempts), 2)
```

### User Engagement Funnel
```kql
// User journey through your bot
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
```

## Notes

- Your telemetry service creates spans with specific names like `bot_message_processing`
- Custom properties are in `customDimensions["key"]` format (no dot notation)
- Operations have duration tracked in `customDimensions["operation.duration_ms"]`
- All your events are trackable using the span `name` field
