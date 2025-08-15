---
page_type: sample
languages:
  - typescript
products:
  - office-teams
  - office
name: Bot App with SSO Enabled
urlFragment: officedev-teamsfx-samples-bot-bot-sso
description: A Hello World app of Microsoft Teams Bot app with SSO
extensions:
  createdDate: "2021-10-19"
---

# Getting Started with Bot SSO

A bot, chatbot, or conversational bot is an app that responds to simple commands sent in chat and replies in meaningful ways. Examples of bots in everyday use include: bots that notify about build failures, bots that provide information about the weather or bus schedules, or provide travel information. A bot interaction can be a quick question and answer, or it can be a complex conversation. Being a cloud application, a bot can provide valuable and secure access to cloud services and corporate resources.

This is a sample chatbot application demonstrating Single Sign-on using `botbuilder` and Teams Framework that can respond to a `show` message.

![Bot SSO Overview](assets/sampleDemo.gif)

## This sample illustrates

- Use Microsoft 365 Agents Toolkit to create a Teams bot app.
- Use Microsoft Graph to get User info and picture in Teams app.
- Use TeamsFx SDK to implementing SSO for Teams bot.

## Prerequisite to use this sample

- [Node.js](https://nodejs.org/), supported versions: 18, 20, 22
- A Microsoft 365 tenant in which you have permission to upload Teams apps. You can get a free Microsoft 365 developer tenant by joining the [Microsoft 365 developer program](https://developer.microsoft.com/en-us/microsoft-365/dev-program).
- [Microsoft 365 Agents Toolkit Visual Studio Code Extension](https://aka.ms/teams-toolkit) version 5.0.0 and higher or [Microsoft 365 Agents Toolkit CLI](https://aka.ms/teams-toolkit-cli)

> Note: If you are using node 20, you can add following snippet in package.json to remove the warning of incompatibility. (Related discussion: https://github.com/microsoft/botbuilder-js/issues/4550)

```
"overrides": {
  "@azure/msal-node": "^2.6.0"
}
```

## Minimal path to awesome

### Run the app locally

- From VS Code:
  1. hit `F5` to start debugging. Alternatively open the `Run and Debug Activity` Panel and select `Debug in Teams (Edge)` or `Debug in Teams (Chrome)`.
- From Microsoft 365 Agents Toolkit CLI:
  1.  Install [dev tunnel cli](https://aka.ms/teamsfx-install-dev-tunnel).
  1.  Login with your M365 Account using the command `devtunnel user login`.
  1.  Start your local tunnel service by running the command `devtunnel host -p 3978 --protocol http --allow-anonymous`.
  1.  In the `env/.env.local` file, fill in the values for `BOT_DOMAIN` and `BOT_ENDPOINT` with your dev tunnel URL.
      ```
      BOT_DOMAIN=sample-id-3978.devtunnels.ms
      BOT_ENDPOINT=https://sample-id-3978.devtunnels.ms
      ```
  1.  Run command: `atk provision --env local` .
  1.  Run command: `atk deploy --env local` .
  1.  Run command: `atk preview --env local` .

### Deploy the app to Azure

- From VS Code:
  1. Sign into Azure by clicking the `Sign in to Azure` under the `ACCOUNTS` section from sidebar.
  1. Click `Provision` from `LIFECYCLE` section or open the command palette and select: `Microsoft 365 Agents: Provision`.
  1. Click `Deploy` or open the command palette and select: `Microsoft 365 Agents: Deploy`.
- From Microsoft 365 Agents Toolkit CLI:
  1. Run command: `atk auth login azure`.
  1. Run command: `atk provision --env dev`.
  1. Run command: `atk deploy --env dev`.

### Preview the app in Teams

- From VS Code:
  1. Open the `Run and Debug Activity` Panel. Select `Launch Remote (Edge)` or `Launch Remote (Chrome)` from the launch configuration drop-down.
- From Microsoft 365 Agents Toolkit CLI:
  1. Run command: `atk preview --env dev`.

## Project Structure

```
src/
├── commands/          # Bot command handlers
├── telemetry/         # Telemetry and monitoring
│   ├── telemetryService.ts     # OpenTelemetry implementation
│   ├── saved_queries/          # Individual KQL files by category
│   │   ├── core/              # Essential bot metrics
│   │   ├── users/             # User analytics
│   │   ├── performance/       # Performance monitoring
│   │   ├── errors/            # Error analysis
│   │   ├── advanced/          # Business intelligence
│   │   ├── debugging/         # Data exploration
│   │   ├── publish-queries-to-insights.*  # Deployment scripts
│   │   └── README.md          # Query documentation
│   ├── index.ts               # Module exports
│   └── README.md              # Telemetry documentation
├── authConfig.ts      # Authentication configuration
├── config.ts          # Application configuration
├── index.ts           # Main application entry point
├── ssoDialog.ts       # SSO authentication dialog
└── teamsBot.ts        # Main bot implementation
```

## 📊 Telemetry & Monitoring

This bot includes **enterprise-grade telemetry** using **OpenTelemetry** and **Azure Application Insights** for comprehensive observability and monitoring.

### 🏗️ Implementation Architecture
- **OpenTelemetry Integration**: Industry-standard observability framework
- **Dual Data Collection**: Console logs (traces) + spans (dependencies) for complete coverage
- **Azure Application Insights**: Cloud-native analytics and alerting
- **Query Pack Deployment**: 30+ pre-built KQL queries for instant insights

## 🔬 Why OpenTelemetry vs Classic Application Insights?

### **Strategic Technology Choice**

This implementation uses **OpenTelemetry (OTel)** instead of the classic Application Insights SDK for compelling technical and business reasons:

#### 🌐 **Vendor Independence & Future-Proofing**
- **Avoid Vendor Lock-in**: OpenTelemetry is vendor-neutral, supporting 40+ observability backends
- **Cloud Portability**: Same telemetry code works with Azure, AWS CloudWatch, Google Cloud, Datadog, New Relic
- **Strategic Flexibility**: Change monitoring providers without rewriting instrumentation code
- **Industry Standard**: CNCF graduated project with enterprise backing from major tech companies

#### 🚀 **Technical Advantages**

| Feature | OpenTelemetry | Classic App Insights SDK |
|---------|---------------|---------------------------|
| **Vendor Lock-in** | ❌ None - Works everywhere | ✅ Microsoft Azure only |
| **Data Model** | W3C standard traces/spans | Proprietary telemetry model |
| **Ecosystem** | 1000+ integrations | Limited to Microsoft stack |
| **Performance** | Optimized, async collection | Synchronous, higher overhead |
| **Customization** | Highly extensible | Limited extension points |
| **Cost Control** | Advanced sampling/filtering | Basic sampling options |

#### 📊 **Enterprise Benefits**

**1. Observability Standardization**
```typescript
// Same OpenTelemetry code works across platforms
const span = tracer.startSpan('user_authentication');
span.setAttributes({
  'user.id': userId,
  'auth.method': 'sso'
});
// Works with Azure, AWS, Google Cloud, on-premises
```

**2. Advanced Instrumentation**
- **Distributed Tracing**: Full request correlation across microservices
- **Custom Metrics**: Business KPIs alongside technical metrics  
- **Structured Events**: Rich context with typed custom dimensions
- **Sampling Control**: Intelligent data collection to manage costs

**3. Developer Experience**
- **IDE Integration**: Rich tooling and debugging support
- **Testing**: Local development with OTLP exporters
- **Documentation**: Comprehensive community resources
- **Skills Transfer**: Knowledge applies across cloud providers

#### 🎯 **Implementation Strategy**

**Dual Collection Approach:**
```typescript
// Console logs → Application Insights traces table
console.log('User message processed', { userId, responseTime });

// OpenTelemetry spans → Application Insights dependencies table  
const span = tracer.startSpan('message_processing');
span.setAttributes({ 'user.id': userId, 'response.time': responseTime });
```

**Why This Works:**
- ✅ **Rich Data**: Both structured spans AND debug logs
- ✅ **Backwards Compatibility**: Existing App Insights queries still work
- ✅ **Migration Path**: Gradual transition from logs to spans
- ✅ **Complete Coverage**: No telemetry gaps during modernization

#### 💼 **Business Case**

**Cost Optimization:**
- Advanced sampling reduces ingestion costs by 60-80%
- Intelligent filtering focuses on business-critical events
- Predictable pricing with volume controls

**Risk Mitigation:**
- Multi-cloud readiness for enterprise cloud strategy
- No vendor dependency for critical observability
- Future-proof architecture for acquisitions/mergers

**Competitive Advantage:**
- Industry-standard observability practices
- Faster troubleshooting with distributed tracing
- Better insights with richer data model

#### 🔄 **Migration Benefits**

**For Existing Applications:**
- **Drop-in Replacement**: OpenTelemetry exports to Application Insights
- **Gradual Migration**: Run both SDKs during transition
- **Query Compatibility**: Existing KQL queries continue working
- **Team Training**: Incremental learning curve

**Example Migration:**
```typescript
// Before: Classic Application Insights
appInsights.trackEvent('UserAction', { userId, action });

// After: OpenTelemetry (same data, better structure)
tracer.startSpan('UserAction', {
  attributes: { 'user.id': userId, 'action.type': action }
});
```

### 🎖️ **Enterprise Adoption**

**Industry Leaders Using OpenTelemetry:**
- **Netflix**: Distributed tracing across microservices
- **Shopify**: E-commerce platform observability
- **Uber**: Real-time performance monitoring
- **Microsoft**: Azure services internal monitoring

**Compliance & Governance:**
- ✅ **SOC 2 Ready**: Audit-friendly observability practices
- ✅ **GDPR Compliant**: Built-in data privacy controls
- ✅ **Enterprise Security**: Encrypted data transmission
- ✅ **Retention Policies**: Configurable data lifecycle management

## 🔗 Distributed Tracing Setup

This bot is designed to work with **distributed tracing** across multiple services. The bot automatically propagates trace context to external services, enabling complete request correlation.

### **Current Implementation**
The bot's `getAIResponse()` method automatically adds OpenTelemetry trace headers to HTTP requests:

```typescript
// Automatic trace context propagation
const traceHeaders = telemetryService.getTraceHeaders();
Object.entries(traceHeaders).forEach(([key, value]) => {
  if (typeof value === 'string') {
    headers.set(key, value);
  }
});
```

### **FastAPI Service Integration**
To connect your Azure Container Apps FastAPI endpoint with this bot's telemetry:

1. **Quick Setup**: See [`DISTRIBUTED_TRACING_SETUP.md`](DISTRIBUTED_TRACING_SETUP.md) for complete FastAPI integration
2. **Auto-Instrumentation**: Use OpenTelemetry FastAPI instrumentation 
3. **Same App Insights**: Configure same `APPLICATIONINSIGHTS_CONNECTION_STRING`
4. **Connected Traces**: See complete Bot → FastAPI → AI Service flows

### **Benefits of Connected Services**
- 🔍 **End-to-end visibility**: Complete request journey across all services
- ⚡ **Performance insights**: Identify bottlenecks in the entire pipeline  
- 🚨 **Error correlation**: Know exactly which service failed
- 📊 **Business metrics**: Track AI response quality and user satisfaction

**Example Connected Flow:**
```
Teams Bot → Azure Container Apps → Semantic Kernel → OpenAI
     ↓              ↓                    ↓           ↓
  Bot telemetry → FastAPI spans → SK spans → HTTP spans
```

All appearing as **one connected trace** in Application Insights! 🎯

## 🔧 Distributed Tracing Configuration Recommendations

To ensure proper distributed tracing setup between this Teams Bot and external FastAPI services, follow these configuration guidelines:

### **🎯 Essential Configuration Requirements**

#### 1. **Environment Variables Alignment**
Both the Teams Bot and FastAPI service must use the **same Application Insights connection string**:

```bash
# Teams Bot (.env files)
APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=12345678-1234-1234-1234-123456789012;IngestionEndpoint=https://your-region.in.applicationinsights.azure.com/;LiveEndpoint=https://your-region.livediagnostics.monitor.azure.com/

# FastAPI Service (environment variables)
APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=12345678-1234-1234-1234-123456789012;IngestionEndpoint=https://your-region.in.applicationinsights.azure.com/;LiveEndpoint=https://your-region.livediagnostics.monitor.azure.com/
```

#### 2. **Service Name Configuration**
Set **different service names** to distinguish traces in Application Insights:

```bash
# Teams Bot
TELEMETRY_SERVICE_NAME=teams-bot
TELEMETRY_SERVICE_VERSION=1.0.0

# FastAPI Service  
TELEMETRY_SERVICE_NAME=ai-calendar-assistant
TELEMETRY_SERVICE_VERSION=1.4.0
```

#### 3. **Agent URL Configuration**
Point your Teams Bot to the correct FastAPI endpoint:

```bash
# Teams Bot environment
AGENT_URL=https://your-fastapi-service.azurecontainerapps.io/agent_chat
CLEAR_HISTORY_URL=https://your-fastapi-service.azurecontainerapps.io/clear_chat_history
```

### **📊 Verification Steps**

#### Step 1: Deploy and Test
1. **Deploy both services** with the same Application Insights connection string
2. **Send a test message** through Teams to trigger the full flow
3. **Wait 2-3 minutes** for telemetry data to appear in Application Insights

#### Step 2: Verify Distributed Tracing
Use the provided KQL queries to validate the setup:

**Quick Connectivity Check:**
```kql
// Verify both services are sending data
dependencies
| where timestamp > ago(30m)
| where name == "Custom Event"
| where customDimensions["event.name"] in ("External_AI_Request", "api.agent_chat")
| summarize count() by tostring(customDimensions["event.name"]), cloud_RoleName
| order by cloud_RoleName
```

**End-to-End Trace Validation:**
```kql
// Find connected traces across services
dependencies
| where timestamp > ago(30m) 
| where name == "Custom Event"
| where customDimensions["event.name"] == "External_AI_Request"
| extend bot_operation_Id = operation_Id
| join kind=inner (
    dependencies
    | where timestamp > ago(30m)
    | where name == "Custom Event"  
    | where customDimensions["event.name"] == "api.agent_chat"
    | extend fastapi_operation_Id = operation_Id
) on $left.bot_operation_Id == $right.fastapi_operation_Id
| project 
    timestamp,
    bot_service = cloud_RoleName,
    fastapi_service = cloud_RoleName1,
    connected_trace = operation_Id,
    user_session = tostring(customDimensions["sessionId"])
```

#### Step 3: Use Monitoring Queries
The bot includes pre-built distributed tracing queries:

- **`distributed-tracing.kql`** - Complete trace analysis
- **`end-to-end-performance.kql`** - Performance monitoring  
- **`distributed-tracing-debug.kql`** - Connectivity troubleshooting

### **🚨 Common Configuration Issues**

#### Issue 1: No Connected Traces
**Symptoms:** Bot and FastAPI telemetry appear separately
**Solution:**
```bash
# Verify same connection string
az monitor app-insights component show --app your-app-insights --resource-group your-rg --query connectionString
```

#### Issue 2: Missing Trace Headers
**Symptoms:** Individual service telemetry but no correlation
**Check:** Ensure the bot's `getTraceHeaders()` method is working:
```typescript
// Verify trace headers are being added
const traceHeaders = telemetryService.getTraceHeaders();
console.log('Trace headers:', traceHeaders);
// Should show: { 'traceparent': '00-...', 'tracestate': '...' }
```

#### Issue 3: Service Name Conflicts
**Symptoms:** Can't distinguish between services in queries
**Solution:** Use different `TELEMETRY_SERVICE_NAME` values for each service

### **🎯 Expected Trace Flow**

When properly configured, you'll see this connected flow in Application Insights:

```
📱 Teams Bot (teams-bot)
    ↓ [HTTP Request with W3C trace context]
🌐 FastAPI Service (ai-calendar-assistant)  
    ↓ [Semantic Kernel agent call]
🤖 Agent Processing (ai-calendar-assistant)
    ↓ [Azure OpenAI API call]
🧠 OpenAI Service (ai-calendar-assistant)
    ↓ [CosmosDB storage]
🗄️ CosmosDB (ai-calendar-assistant)
```

**All operations share the same `operation_Id`** enabling complete request correlation! ✅

### **🚀 FastAPI Service Setup**

For the FastAPI service configuration, refer to the **AI Calendar Assistant** repository:
- **Repository**: `https://github.com/drewelewis/ai-calendar-assistant`
- **Telemetry Setup**: Already includes comprehensive OpenTelemetry instrumentation
- **Required Endpoints**: `/agent_chat` and `/clear_chat_history` are implemented
- **Auto-Instrumentation**: HTTP requests, Semantic Kernel, and Azure services

### **📋 Deployment Checklist**

- [ ] Same `APPLICATIONINSIGHTS_CONNECTION_STRING` on both services
- [ ] Different `TELEMETRY_SERVICE_NAME` for each service  
- [ ] Correct `AGENT_URL` pointing to FastAPI service
- [ ] FastAPI service has OpenTelemetry configured
- [ ] Test message sent through Teams
- [ ] Distributed tracing queries return connected data
- [ ] Performance monitoring shows end-to-end timing

### 📈 What's Monitored
- ✅ **Message Processing**: Volume, response times, success rates
- ✅ **User Engagement**: Active users, session patterns, retention metrics
- ✅ **SSO Authentication**: Login flows, success/failure tracking
- ✅ **Performance**: API response times, bottlenecks, throughput analysis
- ✅ **Error Tracking**: Detailed exception tracking with context
- ✅ **Business Metrics**: Custom events and KPIs

### 🚀 Quick Setup

#### 1. Environment Configuration
Telemetry is automatically configured via your development environment:

```bash
# Already configured in env/.env.dev
APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=...;IngestionEndpoint=...
```

#### 2. Deploy Monitoring Queries (One-Time Setup)
```powershell
# Deploy 30+ pre-built queries to Application Insights
cd infra
az deployment group create \
  --resource-group your-resource-group \
  --template-file queryPackFixed.bicep \
  --parameters resourceSuffix=your-suffix
```

#### 3. Access Your Dashboards
**Azure Portal** → **Monitor** → **Query Packs** → `calendar-assistant-{suffix}-telemetry-queries`

### 📊 Available Query Categories

| Category | Queries | Purpose |
|----------|---------|---------|
| **Core Metrics** | 8 queries | Message volume, response times, health dashboard |
| **User Analytics** | 5 queries | Active users, engagement patterns, session analysis |
| **Performance** | 5 queries | Response time analysis, bottlenecks, throughput |
| **Error Analysis** | 5 queries | Exception tracking, failure patterns, recovery |
| **Advanced** | 4 queries | Trend analysis, anomaly detection, correlations |
| **Debugging** | 6+ queries | Data exploration, validation, troubleshooting |

## 📋 Complete KQL Query Reference

All queries are located in `src/telemetry/saved_queries/` and work with OpenTelemetry data in Azure Application Insights.

### 🎯 Core Metrics (`core/`)
Essential monitoring queries for daily operations:

| Query File | Purpose | When to Use |
|------------|---------|-------------|
| **`all-events.kql`** | Overview of all bot events and activity | First query to run for general health check |
| **`message-volume.kql`** | Message traffic patterns and trends | Monitor bot usage patterns, capacity planning |
| **`response-time.kql`** | Bot response time analysis | Performance monitoring, SLA compliance |
| **`success-rate.kql`** | Message processing success rate | Quality assurance, error rate monitoring |
| **`sso-flow.kql`** | SSO authentication flow analysis | Track auth success rates, troubleshoot login issues |

### 👥 User Analytics (`users/`)
Understanding user behavior and engagement:

| Query File | Purpose | When to Use |
|------------|---------|-------------|
| **`active-users.kql`** | Daily active user counts and trends | Growth tracking, engagement measurement |
| **`most-active-users.kql`** | Top users by message volume | Identify power users, usage patterns |
| **`peak-hours.kql`** | Usage patterns by hour of day | Capacity planning, optimal maintenance windows |
| **`engagement-funnel.kql`** | User journey through bot features | Feature adoption analysis, conversion rates |
| **`conversation-patterns.kql`** | Session length and message patterns | User behavior insights, feature optimization |

### ⚡ Performance Monitoring (`performance/`)
Identifying bottlenecks and optimization opportunities:

| Query File | Purpose | When to Use |
|------------|---------|-------------|
| **`ai-response-time.kql`** | AI service call performance | Monitor external API performance |
| **`bottlenecks.kql`** | Operations taking longer than expected | Performance troubleshooting, optimization |
| **`operation-performance.kql`** | Detailed operation timing analysis | Deep performance analysis |
| **`retry-patterns.kql`** | Failed operation retry behavior | Reliability analysis, error recovery |

### 🚨 Error Analysis (`errors/`)
Comprehensive error tracking and analysis:

| Query File | Purpose | When to Use |
|------------|---------|-------------|
| **`all-exceptions.kql`** | Complete exception overview and trends | Error monitoring dashboard, incident response |
| **`error-context.kql`** | Errors with user context and impact | User-specific troubleshooting |
| **`failed-operations.kql`** | Failed operations and their patterns | Reliability analysis, system health |
| **`sso-errors.kql`** | SSO-specific authentication failures | Authentication troubleshooting |

### 🔬 Advanced Analytics (`advanced/`)
Business intelligence and deep insights:

| Query File | Purpose | When to Use |
|------------|---------|-------------|
| **`health-dashboard.kql`** | Comprehensive service health metrics | Executive dashboards, SLA reporting |
| **`history-clearing.kql`** | User conversation history management | Privacy compliance, feature usage |
| **`message-types.kql`** | Message type categorization and analysis | Content strategy, feature planning |
| **`proactive-messaging.kql`** | Proactive message effectiveness | Marketing campaign analysis |

### 🔧 Debugging Tools (`debugging/`)
Data exploration and troubleshooting utilities:

| Query File | Purpose | When to Use |
|------------|---------|-------------|
| **`simple-data-check.kql`** | **START HERE** - Basic telemetry validation | First query to verify data is flowing |
| **`span-names.kql`** | Available span names and event types | Understand data structure, build new queries |
| **`custom-dimensions.kql`** | Custom dimension analysis | Data exploration, field discovery |
| **`check-all-tables.kql`** | Data distribution across Application Insights tables | Troubleshoot missing data, verify collection |
| **`recent-activity.kql`** | Latest bot activity and events | Real-time troubleshooting |
| **`count-bot-events.kql`** | Event count summary by type | Volume analysis, data validation |
| **`telemetry-init.kql`** | Telemetry service initialization tracking | Startup troubleshooting |
| **`quick-data-check.kql`** | Fast telemetry health check | Quick validation after deployment |

## 🚀 Query Usage Guide

### For Daily Operations
1. **`simple-data-check.kql`** - Start here to verify telemetry is working
2. **`all-events.kql`** - General bot health overview
3. **`active-users.kql`** - Monitor user engagement
4. **`all-exceptions.kql`** - Check for any errors

### For Performance Analysis
1. **`response-time.kql`** - Overall bot performance
2. **`ai-response-time.kql`** - External API performance
3. **`bottlenecks.kql`** - Identify slow operations
4. **`operation-performance.kql`** - Detailed timing analysis

### For Troubleshooting
1. **`simple-data-check.kql`** - Verify data collection
2. **`span-names.kql`** - Understand available events
3. **`recent-activity.kql`** - See latest activity
4. **`error-context.kql`** - User-specific issues

### For Business Intelligence
1. **`health-dashboard.kql`** - Executive summary
2. **`engagement-funnel.kql`** - Feature adoption
3. **`peak-hours.kql`** - Usage patterns
4. **`conversation-patterns.kql`** - User behavior

### 🎯 Quick Start Tips
- **New to the data?** Start with `simple-data-check.kql`
- **Building new queries?** Use `span-names.kql` to see available events
- **Troubleshooting issues?** Use `recent-activity.kql` for latest events
- **Performance problems?** Start with `bottlenecks.kql`
- **All queries use 7-day windows** - modify `ago(7d)` as needed
- **User IDs use flexible matching** - handles multiple field name variations

### 🔍 Sample Monitoring Queries

#### Bot Health Dashboard
```kql
// Real-time bot performance overview
traces
| where timestamp > ago(1h)
| summarize 
    Messages = countif(name contains "Message"),
    Errors = countif(severityLevel >= 3),
    AvgResponse = avg(todouble(customDimensions["response_time_ms"]))
by bin(timestamp, 5m)
| render timechart
```

#### User Engagement Analysis
```kql
// Daily active users and message patterns
traces
| where name contains "Message" and timestamp > ago(7d)
| extend UserId = tostring(customDimensions["userId"])
| summarize 
    ActiveUsers = dcount(UserId),
    TotalMessages = count()
by bin(timestamp, 1d)
| render timechart
```

#### Error Trending
```kql
// Error rate monitoring
union traces, exceptions
| where timestamp > ago(24h)
| extend IsError = iff(itemType == "exception" or severityLevel >= 3, 1, 0)
| summarize 
    ErrorRate = todouble(sum(IsError)) / count() * 100
by bin(timestamp, 1h)
| render timechart
```

### 🎯 Implementation Highlights

#### OpenTelemetry Best Practices
- **Early Initialization**: OpenTelemetry initialized before other imports
- **Dual Approach**: Console.log for traces + spans for dependencies
- **Structured Logging**: Consistent property names and data types
- **Context Propagation**: User and conversation tracking across operations

#### Key Features
```typescript
// Track user interactions
telemetryService.trackMessage('User message processed', {
  userId: 'user123',
  messageType: 'text',
  responseTime: 245,
  success: true
});

// Monitor operations with timing
const operation = telemetryService.startOperation('AI_API_Call')
  .setContext(userId, conversationId);
try {
  const result = await callAPI();
  operation.stop(true); // success
} catch (error) {
  operation.stop(false, error.message); // failure
}
```

### 📚 Documentation
- **Complete Implementation Guide**: [`src/telemetry/README.md`](src/telemetry/README.md)
- **Query Documentation**: [`src/telemetry/queries.md`](src/telemetry/queries.md)
- **Individual Query Files**: [`src/telemetry/saved_queries/`](src/telemetry/saved_queries/)

---

## Version History

| Date         | Author     | Comments                               |
| ------------ | ---------- | -------------------------------------- |
| Apr 19, 2022 | IvanJobs   | update to support Teams Toolkit v4.0.0 |
| Dec 7, 2022  | yukun-dong | update to support Teams Toolkit v5.0.0 |
| Feb 22, 2024 | yukun-dong | update card to adaptive card           |

## Feedback

We really appreciate your feedback! If you encounter any issue or error, please report issues to us following the [Supporting Guide](https://github.com/OfficeDev/TeamsFx-Samples/blob/dev/SUPPORT.md). Meanwhile you can make [recording](https://aka.ms/teamsfx-record) of your journey with our product, they really make the product better. Thank you!

test git