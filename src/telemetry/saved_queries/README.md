# Teams Bot Telemetry - Complete Query Pack

This folder contains **30 KQL files** organized by category. These queries are deployed as an **Azure Monitor Query Pack** for efficient management and sharing.

## 🎯 What is a Query Pack?

Query Packs are Azure's modern approach for managing and sharing KQL queries:
- **Bulk Deployment**: All 30 queries deployed as a single unit
- **Better Organization**: Logical grouping with categories and tags  
- **Version Control**: Integrated with Infrastructure as Code
- **Easy Sharing**: Can be shared across workspaces and teams
- **Reliability**: Avoids timeout issues with individual query deployment

## 📊 Query Categories

### � Core Bot Metrics (`core/`)
- **Message Volume**: Bot activity and message patterns
- **Response Time**: Performance analysis with percentiles  
- **Success Rate**: Bot success metrics over time
- **SSO Events**: Authentication flow tracking
- **Conversation Health**: Overall conversation metrics

### 👥 User Analytics (`users/`)
- **Active Users**: Daily and hourly user activity
- **User Engagement**: Interaction patterns and behavior
- **Peak Usage**: Usage patterns by time of day

### ⚡ Performance Monitoring (`performance/`)
- **Response Times**: Bot response time distribution
- **Slow Operations**: Operations taking longer than expected
- **Memory Usage**: Resource consumption patterns

### 🚨 Error Analysis (`errors/`)
- **Error Rates**: Error frequency and trends
- **Authentication Failures**: SSO and auth-related issues
- **Exception Details**: Detailed error information

### 📈 Advanced Analytics (`advanced/`)
- **Application Lifecycle**: App starts, shutdowns, health
- **Conversation Flows**: Advanced conversation analysis

### 🔍 Debugging (`debugging/`)
- **Recent Errors**: Latest issues for troubleshooting
- **Trace Correlation**: Correlate traces by operation and conversation

## 🚀 Deployment

### Deploy Query Pack
```powershell
cd infra
.\deploy-query-pack.ps1
```

This will:
1. Auto-detect settings from `env/.env.dev`
2. Deploy the Query Pack to your Azure subscription
3. Make all queries available in Azure Monitor

## 📍 Accessing Your Queries

After deployment, find your queries at:

1. **Azure Portal** → **Monitor** → **Query Packs**
2. **Log Analytics Workspace** → **Logs** → **Query explorer**
3. Look for: `{resourceBaseName}-telemetry-queries`

## 🎨 Using the Queries

1. Navigate to your **Application Insights** resource
2. Go to **Logs** 
3. Open **Query explorer** (folder icon)
4. Find your **Query Pack** in the explorer
5. Click any query to load it into the editor
6. Run the query to see your telemetry data

## 📝 Manual Usage (Alternative)

You can also copy individual `.kql` files directly:
1. Open any `.kql` file in this folder
2. Copy the KQL content  
3. Paste into Application Insights **Logs** query editor
4. Run the query

## 🔧 Infrastructure as Code

The Query Pack is deployed via:
- **`infra/queryPack.bicep`** - Query Pack template with 8 essential queries
- **`infra/azure.bicep`** - Main template (set `deployTelemetry=true`)
- **`infra/deploy-query-pack.ps1`** - Standalone deployment script

## 📊 Sample Queries Included

The Query Pack includes these pre-configured queries:
- Bot Activity Overview
- Message Processing Success Rate  
- SSO Authentication Events
- Error Rate Monitoring
- Response Time Distribution
- Active Users
- Application Lifecycle
- Recent Errors (Last 24h)

## 🎯 Next Steps

1. **Deploy the Query Pack**: Run `.\deploy-query-pack.ps1`
2. **Access in Portal**: Monitor → Query Packs  
3. **Start Monitoring**: Use the pre-built queries
4. **Customize**: Modify queries as needed for your specific monitoring requirements
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

## 🔍 Finding Your Saved Queries in Azure Portal

### Step-by-Step Navigation:
1. **Open Azure Portal**: Go to [portal.azure.com](https://portal.azure.com)
2. **Find Your Application Insights**: 
   - Search for "Application Insights" in the top search bar
   - Select your Application Insights resource (from your dev environment: `devops-ai-rg` resource group)
3. **Navigate to Logs**:
   - In the left sidebar, click **"Logs"** under the "Monitoring" section
4. **Access Saved Queries**:
   - In the Logs interface, look for **"Saved Queries"** in the left panel
   - Expand the saved queries section
5. **Find Your Categories**:
   - Look for categories starting with **"TeamsBotTelemetry-"**:
     - 📊 **TeamsBotTelemetry-Core** - Essential bot metrics
     - 👥 **TeamsBotTelemetry-Users** - User analytics  
     - ⚡ **TeamsBotTelemetry-Performance** - Performance monitoring
     - 🚨 **TeamsBotTelemetry-Errors** - Error analysis
     - 📈 **TeamsBotTelemetry-Advanced** - Business intelligence
     - 🔍 **TeamsBotTelemetry-Debugging** - Data exploration

### Quick Access:
- **Direct Portal Link**: The deployment script provides a direct URL like:
  ```
  https://portal.azure.com/#@/resource/subscriptions/[your-sub-id]/resourceGroups/devops-ai-rg/providers/Microsoft.Insights/components/[your-app-insights]/logs
  ```
- **Search**: In the saved queries panel, you can search for "core-", "users-", "performance-", etc.

### Using the Queries:
1. **Click any saved query** to load it into the editor
2. **Click "Run"** to execute the query
3. **Customize** time ranges and filters as needed
4. **Pin to Dashboard** for ongoing monitoring

## Tips

- Start with `debugging/basic-data-check.kql` to verify data is flowing
- Use `debugging/span-names.kql` to see what events you're tracking
- Core metrics in `core/` folder are essential for daily monitoring
- Advanced analytics provide business insights
