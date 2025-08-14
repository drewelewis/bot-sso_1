@description('Name of the query pack')
param queryPackName string = 'teams-bot-telemetry-queries'

@description('Location for the query pack')
param location string = resourceGroup().location

@description('Tags for the query pack')
param tags object = {}

// Query Pack Resource
resource queryPack 'Microsoft.OperationalInsights/queryPacks@2019-09-01' = {
  name: queryPackName
  location: location
  tags: tags
  properties: {}
}

// Deploy just the most essential queries first (8 queries with proper GUIDs)
resource essentialQueries 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = [for query in queriesArray: {
  parent: queryPack
  name: query.id
  properties: {
    displayName: query.displayName
    description: query.description
    body: query.body
    related: {
      categories: [
        'monitoring'
        'teams-bot'
        query.category
      ]
    }
    tags: {
      category: [query.category]
      type: ['teams-bot-telemetry']
    }
  }
}]

// Essential queries - 8 core queries with proper GUID format
var queriesArray = [
  {
    id: '1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d'
    displayName: 'Bot Activity Overview'
    description: 'Overall bot activity and message volume'
    category: 'core'
    body: 'traces | where customDimensions.activityType == "message" | summarize MessageCount = count() by bin(timestamp, 1h) | render timechart'
  }
  {
    id: '2b3c4d5e-6f7a-8b9c-0d1e-2f3a4b5c6d7e'
    displayName: 'Message Processing Success Rate'
    description: 'Success rate of message processing'
    category: 'core'
    body: 'traces | where customDimensions.activityType == "message" | summarize Total = count(), Success = countif(severityLevel < 3) by bin(timestamp, 1h) | extend SuccessRate = (Success * 100.0) / Total | render timechart'
  }
  {
    id: '3c4d5e6f-7a8b-9c0d-1e2f-3a4b5c6d7e8f'
    displayName: 'SSO Authentication Events'
    description: 'SSO authentication success and failure events'
    category: 'core'
    body: 'traces | where message contains "SSO" or message contains "authentication" | summarize count() by severityLevel, bin(timestamp, 1h) | render timechart'
  }
  {
    id: '4d5e6f7a-8b9c-0d1e-2f3a-4b5c6d7e8f9a'
    displayName: 'Error Rate Monitoring'
    description: 'Error rates and trends'
    category: 'errors'
    body: 'traces | where severityLevel >= 3 | summarize ErrorCount = count() by bin(timestamp, 1h) | render timechart'
  }
  {
    id: '5e6f7a8b-9c0d-1e2f-3a4b-5c6d7e8f9a0b'
    displayName: 'Response Time Distribution'
    description: 'Distribution of bot response times'
    category: 'performance'
    body: 'traces | where customDimensions.duration != "" | extend Duration = todouble(customDimensions.duration) | summarize avg(Duration), percentile(Duration, 50), percentile(Duration, 95) by bin(timestamp, 1h) | render timechart'
  }
  {
    id: '6f7a8b9c-0d1e-2f3a-4b5c-6d7e8f9a0b1c'
    displayName: 'Active Users'
    description: 'Daily and hourly active users'
    category: 'users'
    body: 'traces | where customDimensions.userId != "" | summarize UniqueUsers = dcount(tostring(customDimensions.userId)) by bin(timestamp, 1d) | render timechart'
  }
  {
    id: '7a8b9c0d-1e2f-3a4b-5c6d-7e8f9a0b1c2d'
    displayName: 'Application Lifecycle'
    description: 'App starts and shutdowns'
    category: 'advanced'
    body: 'traces | where name in ("Application_Started", "Application_Shutdown") | summarize Count = count() by name, bin(timestamp, 1d) | render timechart'
  }
  {
    id: '8b9c0d1e-2f3a-4b5c-6d7e-8f9a0b1c2d3e'
    displayName: 'Recent Errors (Last 24h)'
    description: 'Recent errors for debugging'
    category: 'debugging'
    body: 'traces | where timestamp > ago(24h) and severityLevel >= 3 | project timestamp, message, severityLevel, customDimensions | order by timestamp desc | take 50'
  }
]

output queryPackId string = queryPack.id
output queryPackName string = queryPack.name
output queriesCount int = length(queriesArray)
