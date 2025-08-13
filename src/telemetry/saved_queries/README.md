# Saved Queries Index

This folder contains individual KQL files organized by category. Each file can be copied directly into Application Insights Logs.

## 📊 Core Bot Metrics (`core/`)
- **`message-volume.kql`** - Message volume over time
- **`response-time.kql`** - Response time analysis with percentiles
- **`success-rate.kql`** - Bot success rate by hour
- **`all-events.kql`** - Overview of all bot events
- **`sso-flow.kql`** - SSO authentication flow tracking

## 👥 User Analytics (`users/`)
- **`active-users.kql`** - Daily active users
- **`most-active-users.kql`** - Top 10 most active users
- **`peak-hours.kql`** - Usage patterns by hour
- **`engagement-funnel.kql`** - User journey through features
- **`conversation-patterns.kql`** - Message count per conversation

## ⚡ Performance Monitoring (`performance/`)
- **`operation-performance.kql`** - All operations performance analysis
- **`ai-response-time.kql`** - AI response time distribution
- **`bottlenecks.kql`** - Performance bottlenecks
- **`retry-patterns.kql`** - AI request retry analysis

## 🚨 Error Analysis (`errors/`)
- **`failed-operations.kql`** - Failed operations tracking
- **`all-exceptions.kql`** - Exception monitoring
- **`sso-errors.kql`** - SSO-specific issues
- **`error-context.kql`** - Errors with user context

## 📈 Advanced Analytics (`advanced/`)
- **`app-lifecycle.kql`** - Application starts/shutdowns
- **`proactive-messaging.kql`** - Proactive message flow
- **`message-types.kql`** - Message type distribution
- **`history-clearing.kql`** - Conversation history patterns
- **`custom-metrics.kql`** - OpenTelemetry custom metrics
- **`health-dashboard.kql`** - Comprehensive health metrics

## 🔍 Debugging (`debugging/`)
- **`basic-data-check.kql`** - Basic data exploration
- **`span-names.kql`** - All available span names
- **`custom-dimensions.kql`** - Custom dimensions structure
- **`recent-activity.kql`** - Recent bot activity
- **`available-tables.kql`** - All available data tables
- **`telemetry-init.kql`** - Telemetry initialization check

## 🚀 Usage

### Manual Usage
1. **Copy individual files**: Open any `.kql` file and copy the content to Application Insights
2. **Run queries**: Paste into Application Insights > Logs and execute

### Automated Deployment to Azure (Using Dev Environment)
The scripts automatically use your dev environment settings from `env\.env.dev`:

**Windows PowerShell:**
```powershell
# Run the PowerShell script (uses dev environment automatically)
.\publish-queries-to-insights.ps1
```

**Windows Batch:**
```batch
# Simple batch file that calls PowerShell
.\publish-queries-to-insights.bat
```

**Cross-platform Bash:**
```bash
# Make executable and run
chmod +x publish-queries-to-insights.sh
./publish-queries-to-insights.sh
```

All scripts will:
- ✅ Load configuration from your `env\.env.dev` file
- ✅ Parse your Application Insights connection string  
- ✅ Automatically find your Azure resources
- ✅ Publish all 30+ queries to Application Insights with separate categories:
  - **TeamsBotTelemetry-Core** - Essential bot metrics
  - **TeamsBotTelemetry-Users** - User analytics  
  - **TeamsBotTelemetry-Performance** - Performance monitoring
  - **TeamsBotTelemetry-Errors** - Error analysis
  - **TeamsBotTelemetry-Advanced** - Business intelligence
  - **TeamsBotTelemetry-Debugging** - Data exploration
- ✅ Provide direct Azure portal links to access the published queries

### Getting Started
3. **Start with debugging**: Use debugging queries first to understand your data structure

## Tips

- Start with `debugging/basic-data-check.kql` to verify data is flowing
- Use `debugging/span-names.kql` to see what events you're tracking
- Core metrics in `core/` folder are essential for daily monitoring
- Advanced analytics provide business insights
