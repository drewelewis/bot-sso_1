# Telemetry Module

This folder contains all telemetry-related code and documentation for the Teams Bot.

## 📁 Files

### Core Implementation
- **`telemetryService.ts`** - Main OpenTelemetry service implementation
- **`index.ts`** - Module exports for easy importing

### Documentation
- **`queries.md`** - Complete KQL queries documentation
- **`saved_queries/`** - Individual KQL files organized by category
  - `core/` - Essential bot metrics
  - `users/` - User analytics
  - `performance/` - Performance monitoring
  - `errors/` - Error analysis
  - `advanced/` - Business intelligence
  - `debugging/` - Data exploration and troubleshooting
- **`README.md`** - This documentation file

### Automation Scripts (Updated!)
- **`saved_queries/publish-queries-to-insights.ps1`** - PowerShell script using dev environment
- **`saved_queries/publish-queries-to-insights.sh`** - Bash script for Linux/Mac  
- **`saved_queries/publish-queries-to-insights.bat`** - Windows batch script
- **`saved_queries/README.md`** - Complete automation documentation

### Quick Deploy All Queries
The automation scripts now automatically use your `env\.env.dev` settings:

```powershell
# Windows - Just run this in saved_queries folder:
.\publish-queries-to-insights.bat

# Or directly with PowerShell:
.\publish-queries-to-insights.ps1
```

The script will:
- ✅ Load your Azure settings from `env\.env.dev`
- ✅ Find your Application Insights resource automatically  
- ✅ Deploy all 30+ KQL queries with "TeamsBotTelemetry" category
- ✅ Provide direct portal links to access your published queries

## 🚀 Usage

### Importing the Telemetry Service
```typescript
import { telemetryService } from './telemetry';

// Initialize (call once at app startup)
telemetryService.initialize();

// Track messages
telemetryService.trackMessage({
  userId: 'user123',
  conversationId: 'conv456',
  messageType: 'text',
  success: true,
  responseTime: 250
});

// Track custom events
telemetryService.trackCustomEvent('User_Action', {
  action: 'button_click',
  userId: 'user123'
});

// Track operations with timing
const timer = telemetryService.startOperation('AI_Request')
  .setContext('user123', 'conv456');
// ... do work ...
timer.stop(true); // success = true
```

## 📊 Monitoring

### Quick Health Check
Use these queries in Application Insights (or copy from `saved_queries/debugging/`):

```kql
// Check if telemetry is working
traces | take 10

// See all your events
traces | summarize count() by name | order by count_ desc

// Bot health dashboard
traces
| where name == "bot_message_processing"
| extend Success = tobool(customDimensions["bot.success"])
| summarize 
    Total = count(),
    SuccessRate = todouble(countif(Success == true)) / count() * 100
```

### Individual Query Files
All queries are available as individual `.kql` files in `saved_queries/`:
- Copy and paste any query directly into Application Insights
- Organized by category for easy navigation
- See `saved_queries/README.md` for complete index

### Automated Query Setup
Run the PowerShell script to set up all monitoring queries:
```powershell
.\save-queries.ps1 -ResourceGroupName "your-rg" -ApplicationInsightsName "your-app-insights" -SubscriptionId "your-subscription"
```

## 🔧 Configuration

The telemetry service is configured through `src/config.ts`:
- `applicationInsightsConnectionString` - App Insights connection
- `telemetryServiceName` - Service name for OpenTelemetry
- `telemetryServiceVersion` - Service version
- `environment` - Deployment environment

## 📈 What's Tracked

### Automatic Tracking
- **Message Processing**: Volume, response time, success rate
- **Operations**: Performance timing for all major operations
- **Errors**: Exceptions with context
- **SSO Authentication**: Login flow tracking
- **AI Interactions**: External API calls and performance

### Custom Events
- User actions and feature usage
- Application lifecycle events
- Business-specific metrics

## 🎯 Best Practices

1. **Initialize Once**: Call `telemetryService.initialize()` at app startup
2. **Use Operation Timers**: For tracking performance of long-running operations
3. **Include Context**: Always provide userId and conversationId when available
4. **Handle Errors**: Use `trackException()` for error tracking
5. **Meaningful Names**: Use descriptive event names for custom tracking

## 🔍 Troubleshooting

### No Data in App Insights
1. Check connection string configuration
2. Verify `telemetryService.initialize()` is called
3. Check Azure subscription and resource access

### Missing Fields in Queries
1. Check the `traces` table structure: `traces | take 5 | project *`
2. Verify customDimensions field names match your queries
3. Use debugging queries to explore actual data structure

## 📚 Additional Resources

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Azure Monitor OpenTelemetry](https://docs.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-overview)
- [KQL Query Language](https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/)
