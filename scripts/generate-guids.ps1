#!/usr/bin/env pwsh

# Generate GUIDs for all 30 queries and update the Query Pack

$queries = @(
    'core-message-volume',
    'core-response-time', 
    'core-success-rate',
    'core-all-events',
    'core-sso-flow',
    'users-active-users',
    'users-most-active',
    'users-peak-hours',
    'users-engagement-funnel',
    'users-conversation-patterns',
    'performance-ai-response',
    'performance-bottlenecks',
    'performance-operations',
    'performance-retry-patterns',
    'errors-failed-operations',
    'errors-all-exceptions',
    'errors-sso-errors',
    'errors-context',
    'advanced-app-lifecycle',
    'advanced-proactive-messaging',
    'advanced-message-types',
    'advanced-history-clearing',
    'advanced-custom-metrics',
    'advanced-health-dashboard',
    'debugging-basic-data-check',
    'debugging-span-names',
    'debugging-custom-dimensions',
    'debugging-recent-activity',
    'debugging-available-tables',
    'debugging-telemetry-init'
)

Write-Host "Generating GUIDs for $($queries.Count) queries:" -ForegroundColor Cyan

foreach ($query in $queries) {
    $guid = [System.Guid]::NewGuid().ToString()
    Write-Host "  $query -> $guid" -ForegroundColor Gray
}
