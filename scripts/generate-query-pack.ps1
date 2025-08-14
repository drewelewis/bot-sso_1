#!/usr/bin/env pwsh

<#
.SYNOPSIS
Generate Query Pack Bicep template from .kql files

.DESCRIPTION
This script scans all .kql files in the saved_queries directory and generates
a comprehensive Query Pack Bicep template with all queries organized by category.

.PARAMETER OutputPath
Path where the generated Bicep file should be saved

.EXAMPLE
.\generate-query-pack.ps1 -OutputPath ".\generatedQueryPack.bicep"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\generatedQueryPack.bicep"
)

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$savedQueriesDir = Join-Path $scriptDir ".." "src" "telemetry" "saved_queries"

if (-not (Test-Path $savedQueriesDir)) {
    Write-Error "Saved queries directory not found: $savedQueriesDir"
    exit 1
}

Write-Host "=== Generating Query Pack from .kql files ===" -ForegroundColor Cyan
Write-Host "Source directory: $savedQueriesDir" -ForegroundColor Yellow
Write-Host "Output file: $OutputPath" -ForegroundColor Yellow
Write-Host ""

# Function to convert string to safe Bicep identifier
function ConvertTo-BicepIdentifier {
    param([string]$name)
    return $name -replace '[^a-zA-Z0-9]', '-' -replace '^(\d)', 'query-$1'
}

# Function to escape KQL query for Bicep
function ConvertTo-BicepString {
    param([string]$content)
    # Remove comments and empty lines, then escape for Bicep
    $lines = $content -split "`n" | Where-Object { 
        $_.Trim() -ne "" -and -not $_.Trim().StartsWith("//") 
    }
    $cleanQuery = ($lines -join "`n").Trim()
    return $cleanQuery -replace "'", "''" -replace "`n", "\\n" -replace "`r", ""
}

# Function to extract display name from comment
function Get-DisplayName {
    param([string]$content, [string]$fileName)
    $lines = $content -split "`n"
    foreach ($line in $lines) {
        if ($line.Trim().StartsWith("//") -and $line.Length -gt 3) {
            $comment = $line.Trim().Substring(2).Trim()
            if ($comment -ne "" -and -not $comment.ToLower().Contains("todo") -and -not $comment.ToLower().Contains("note")) {
                return $comment
            }
        }
    }
    # Fallback to filename
    return ($fileName -replace '\.kql$', '' -replace '-', ' ' -replace '_', ' ' | 
           ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) })
}

# Scan for all .kql files
$allQueries = @()
$categories = Get-ChildItem -Path $savedQueriesDir -Directory

foreach ($category in $categories) {
    $categoryName = $category.Name
    Write-Host "Processing category: $categoryName" -ForegroundColor Cyan
    
    $kqlFiles = Get-ChildItem -Path $category.FullName -Filter "*.kql"
    
    foreach ($file in $kqlFiles) {
        Write-Host "  - $($file.Name)" -ForegroundColor Gray
        
        $content = Get-Content -Path $file.FullName -Raw
        $queryId = ConvertTo-BicepIdentifier "$categoryName-$($file.BaseName)"
        $displayName = Get-DisplayName $content $file.BaseName
        $escapedQuery = ConvertTo-BicepString $content
        
        $queryObj = @{
            id = $queryId
            displayName = $displayName
            description = "Teams bot monitoring query for $categoryName"
            category = $categoryName
            body = $escapedQuery
        }
        
        $allQueries += $queryObj
    }
}

Write-Host ""
Write-Host "Found $($allQueries.Count) queries across $($categories.Count) categories" -ForegroundColor Green

# Generate Bicep template
$bicepTemplate = @"
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

// All Query Pack Queries
resource queries 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = [for query in queriesArray: {
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

// Generated queries array
var queriesArray = [
"@

# Add each query to the array
foreach ($query in $allQueries) {
    $bicepTemplate += @"

  {
    id: '$($query.id)'
    displayName: '$($query.displayName)'
    description: '$($query.description)'
    category: '$($query.category)'
    body: '$($query.body)'
  }
"@
}

$bicepTemplate += @"

]

output queryPackId string = queryPack.id
output queryPackName string = queryPack.name
output queriesCount int = length(queriesArray)
"@

# Write the generated template
try {
    $bicepTemplate | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "✓ Generated Query Pack Bicep template: $OutputPath" -ForegroundColor Green
    Write-Host "✓ Total queries: $($allQueries.Count)" -ForegroundColor Green
    
    # Show summary by category
    Write-Host ""
    Write-Host "Queries by category:" -ForegroundColor Cyan
    $allQueries | Group-Object category | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count) queries" -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "Failed to write Bicep template: $_"
    exit 1
}

Write-Host ""
Write-Host "=== Generation Complete ===" -ForegroundColor Green
Write-Host "Deploy with: .\deploy-query-pack.ps1" -ForegroundColor White
"@
