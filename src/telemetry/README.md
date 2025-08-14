# 🔍 OpenTelemetry Telemetry Implementation

This module provides comprehensive telemetry for the Teams Bot using **OpenTelemetry** and **Azure Application Insights**. The implementation follows Microsoft's recommended patterns for observability in cloud-native applications.

## 🏗️ Architecture Overview

### OpenTelemetry Integration
Our implementation uses the **dual approach** recommended by Microsoft:

```typescript
// 1. Console.log statements for TRACES table
console.log('📨 Bot Message:', eventData);

// 2. OpenTelemetry spans for DEPENDENCIES table  
const span = tracer.startSpan('operation-name');
span.end();
```

This ensures telemetry data appears in the correct Application Insights tables:
- **Traces Table**: Console logs, custom events, messages
- **Dependencies Table**: Operation spans, API calls, external services
- **Exceptions Table**: Error tracking and stack traces

### Data Flow Architecture
```
Teams Bot → OpenTelemetry → Azure Monitor Exporter → Application Insights
                     ↓
              Console Logs (Traces)
              Spans (Dependencies)  
              Exceptions (Errors)
```

## 📁 Project Structure

### Core Implementation
- **`otel-init.ts`** - Early OpenTelemetry initialization (imported first!)
- **`telemetryService.ts`** - Main service with bot-specific methods
- **`index.ts`** - Module exports for easy importing

### Query Management
- **`saved_queries/`** - 30+ organized KQL queries by category:
  - `core/` - Essential bot metrics (message volume, response time)
  - `users/` - User analytics and engagement patterns
  - `performance/` - Performance monitoring and bottlenecks
  - `errors/` - Error analysis and troubleshooting
  - `advanced/` - Business intelligence and trends
  - `debugging/` - Data exploration and development support

### Infrastructure
- **`infra/queryPackFixed.bicep`** - Deploys all queries as a Query Pack to Azure
- **`infra/set-app-service-env.ps1`** - Environment configuration script

## 🚀 Implementation Details

### 1. Early Initialization Pattern
**Critical**: OpenTelemetry must be initialized before other imports to prevent duplicate registration:

```typescript
// src/index.ts - FIRST import
import './telemetry/otel-init';  // Must be first!
import { telemetryService } from './telemetry';
```

### 2. OpenTelemetry Configuration
```typescript
// otel-init.ts
import { useAzureMonitor } from '@azure/monitor-opentelemetry';

useAzureMonitor({
  azureMonitorExporterOptions: {
    connectionString: config.applicationInsightsConnectionString,
  },
});
```

### 3. Service Implementation
```typescript
// Dual approach for complete coverage
export class TelemetryService {
  // Console.log for traces table
  trackMessage(message: string, properties?: Record<string, any>): void {
    console.log('📨 Bot Message:', message, properties);
  }

  // Spans for dependencies table
  startOperation(name: string): OperationTimer {
    const span = this.tracer.startSpan(name);
    return {
      setContext: (userId, conversationId) => {
        span.setAttributes({ user_id: userId, conversation_id: conversationId });
        return this;
      },
      stop: (success: boolean, error?: string) => {
        span.setStatus({ code: success ? SpanStatusCode.OK : SpanStatusCode.ERROR });
        span.end();
      }
    };
  }
}
```

## � Usage Patterns

### Basic Tracking
```typescript
import { telemetryService } from './telemetry';

// Initialize once at app startup
telemetryService.initialize();

// Track messages (appears in traces table)
telemetryService.trackMessage('User login successful', {
  userId: 'user123',
  loginMethod: 'SSO'
});

// Track custom events (appears in traces table)
telemetryService.trackCustomEvent('Feature_Used', {
  feature: 'profile_view',
  userId: 'user123'
});

// Track exceptions (appears in exceptions table)
try {
  // risky operation
} catch (error) {
  telemetryService.trackException(error, { 
    operation: 'user_profile_fetch',
    userId: 'user123' 
  });
}
```

### Operation Timing
```typescript
// Track operations with timing (appears in dependencies table)
const operation = telemetryService.startOperation('AI_API_Call')
  .setContext(userId, conversationId);

try {
  const result = await callExternalAPI();
  operation.stop(true); // success
  return result;
} catch (error) {
  operation.stop(false, error.message); // failure
  throw error;
}
```

### Bot Context Extraction
```typescript
// Extract telemetry context from bot framework
const { userId, conversationId, messageType } = 
  telemetryService.extractTelemetryFromContext(context);

telemetryService.trackMessage('Message processed', {
  userId,
  conversationId,
  messageType,
  success: true
});
```

## 🎯 Best Practices & Recommendations

### ✅ Do's
1. **Initialize Early**: Import `otel-init.ts` first to prevent duplicate registration
2. **Use Both Approaches**: Console.log for events, spans for operations
3. **Include Context**: Always provide userId, conversationId when available
4. **Meaningful Names**: Use descriptive event and operation names
5. **Structured Properties**: Use consistent property names across events
6. **Handle Errors**: Always track exceptions with context

### ❌ Don'ts
1. **Don't Skip Initialization**: Missing `otel-init.ts` import causes errors
2. **Don't Mix Approaches**: Don't use only spans or only console.log
3. **Don't Log Sensitive Data**: Avoid PII in telemetry properties
4. **Don't Ignore Errors**: Always track exceptions for debugging
5. **Don't Use Generic Names**: Avoid vague event names like "event" or "data"

### 🏆 Performance Recommendations
```typescript
// ✅ Good: Structured, meaningful data
telemetryService.trackCustomEvent('SSO_Login_Success', {
  userId: sanitizedUserId,
  method: 'microsoft_graph',
  duration_ms: loginDuration,
  retry_count: 0
});

// ❌ Bad: Unstructured, generic data  
telemetryService.trackCustomEvent('event', {
  data: 'some stuff happened'
});
```

## 📈 Sample Queries

### Quick Health Check
```kql
// Verify telemetry is flowing
traces 
| where timestamp > ago(1h)
| summarize count() by name
| order by count_ desc
```

### Bot Performance Dashboard
```kql
// Message volume and response times
traces
| where name contains "Bot Message"
| extend ResponseTime = todouble(customDimensions["response_time_ms"])
| where isnotnull(ResponseTime)
| summarize 
    MessageCount = count(),
    AvgResponse = avg(ResponseTime),
    P95Response = percentile(ResponseTime, 95)
by bin(timestamp, 1h)
| render timechart
```

### Error Analysis
```kql
// Error rate trends
union traces, exceptions
| where timestamp > ago(24h)
| extend IsError = iff(itemType == "exception" or 
                      (itemType == "trace" and severityLevel >= 3), 1, 0)
| summarize 
    Total = count(),
    Errors = sum(IsError),
    ErrorRate = todouble(sum(IsError)) / count() * 100
by bin(timestamp, 1h)
| render timechart
```

### User Engagement
```kql
// Active users and session patterns
traces
| where name contains "Message"
| extend UserId = tostring(customDimensions["userId"])
| where isnotempty(UserId)
| summarize 
    MessageCount = count(),
    FirstMessage = min(timestamp),
    LastMessage = max(timestamp)
by UserId, bin(timestamp, 1d)
| extend SessionDuration = LastMessage - FirstMessage
| summarize 
    ActiveUsers = dcount(UserId),
    AvgSessionDuration = avg(SessionDuration),
    TotalMessages = sum(MessageCount)
by bin(timestamp, 1d)
```

### SSO Authentication Flow
```kql
// SSO success rates and timing
traces
| where name contains "SSO"
| extend 
    UserId = tostring(customDimensions["userId"]),
    Success = tobool(customDimensions["success"]),
    Step = tostring(customDimensions["step"])
| summarize 
    Total = count(),
    SuccessRate = todouble(countif(Success == true)) / count() * 100,
    AvgDuration = avg(todouble(customDimensions["duration_ms"]))
by Step
| order by Total desc
```

## 🔧 Configuration

### Environment Variables
Required in your `.env.dev` file:
```bash
APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=xxx;IngestionEndpoint=https://eastus-8.in.applicationinsights.azure.com/"
```

### TypeScript Configuration
```typescript
// src/config.ts
export const config = {
  applicationInsightsConnectionString: process.env.APPLICATIONINSIGHTS_CONNECTION_STRING,
  telemetryServiceName: 'teams-bot',
  telemetryServiceVersion: '1.0.0',
  environment: process.env.ENVIRONMENT || 'development'
};
```

## 🚀 Deployment & Query Management

### Deploy Query Pack to Azure
```powershell
# Deploy all 30+ queries as a Query Pack
cd infra
az deployment group create \
  --resource-group your-resource-group \
  --template-file queryPackFixed.bicep \
  --parameters resourceSuffix=your-suffix
```

### Access Queries in Azure Portal
1. **Azure Portal** → **Monitor** → **Query Packs**
2. Look for: `calendar-assistant-{suffix}-telemetry-queries`
3. Use queries directly in Application Insights logs

### Available Query Categories
- **Core Metrics**: Message volume, response times, success rates
- **User Analytics**: Engagement patterns, session analysis
- **Performance**: Bottlenecks, slow operations, resource usage
- **Error Analysis**: Exception tracking, failure patterns
- **Advanced**: Business intelligence, trend analysis
- **Debugging**: Data exploration, development support

## 🔍 Troubleshooting

### No Telemetry Data
```typescript
// 1. Check initialization order
import './telemetry/otel-init';  // Must be first!

// 2. Verify connection string
console.log('Connection string:', config.applicationInsightsConnectionString ? 'SET' : 'MISSING');

// 3. Check service initialization
telemetryService.initialize(); // Call once at startup
```

### Missing Data in Queries
```kql
// Explore actual data structure
traces | take 5 | project timestamp, name, customDimensions

// Check table schemas
union traces, dependencies, exceptions
| summarize count() by itemType
```

### Common OpenTelemetry Issues
1. **Duplicate Registration**: Ensure `otel-init.ts` imported first
2. **Missing Dependencies**: Install `@azure/monitor-opentelemetry`
3. **Wrong Table**: Console.log → traces, spans → dependencies
4. **Timing Issues**: Wait 2-3 minutes for data to appear

## 📚 Additional Resources

- [Microsoft OpenTelemetry Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-overview)
- [OpenTelemetry Best Practices](https://opentelemetry.io/docs/instrumentation/js/getting-started/nodejs/)
- [Azure Monitor Query Language (KQL)](https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/)
- [Application Insights Data Model](https://docs.microsoft.com/en-us/azure/azure-monitor/app/data-model)

---

## 📋 Quick Start Checklist

- [ ] Import `otel-init.ts` first in main entry point
- [ ] Set `APPLICATIONINSIGHTS_CONNECTION_STRING` environment variable  
- [ ] Call `telemetryService.initialize()` at app startup
- [ ] Deploy Query Pack using `infra/queryPackFixed.bicep`
- [ ] Test with sample queries in Application Insights
- [ ] Monitor data flow (2-3 minute delay expected)
