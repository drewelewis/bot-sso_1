#!/usr/bin/env pwsh

<#
.SYNOPSIS
Generate comprehensive Query Pack from ALL .kql files

.DESCRIPTION
This script scans all .kql files in the saved_queries directory and generates
a complete Query Pack with every single query, properly organized by category.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\completeQueryPack.bicep"
)

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$savedQueriesDir = Join-Path $scriptDir ".." "src" "telemetry" "saved_queries"

if (-not (Test-Path $savedQueriesDir)) {
    Write-Error "Saved queries directory not found: $savedQueriesDir"
    exit 1
}

Write-Host "=== Generating Complete Query Pack from ALL .kql files ===" -ForegroundColor Cyan
Write-Host "Source directory: $savedQueriesDir" -ForegroundColor Yellow
Write-Host "Output file: $OutputPath" -ForegroundColor Yellow
Write-Host ""

# Function to convert string to safe Bicep identifier
function ConvertTo-BicepIdentifier {
    param([string]$name)
    $safe = $name -replace '[^a-zA-Z0-9]', '-' -replace '--+', '-' -replace '^-|-$', ''
    if ($safe -match '^\d') { $safe = "query-$safe" }
    return $safe
}

# Function to escape KQL query for Bicep
function ConvertTo-BicepString {
    param([string]$content)
    # Remove comments and empty lines, then escape for Bicep
    $lines = $content -split "`n" | Where-Object { 
        $trim = $_.Trim()
        $trim -ne "" -and -not $trim.StartsWith("//") 
    }
    $cleanQuery = ($lines -join "`n").Trim()
    return $cleanQuery -replace "'", "''" -replace "`n", "\\n" -replace "`r", ""
}

# Function to extract display name from comment or filename
function Get-DisplayName {
    param([string]$content, [string]$fileName)
    $lines = $content -split "`n"
    foreach ($line in $lines) {
        if ($line.Trim().StartsWith("//") -and $line.Length -gt 3) {
            $comment = $line.Trim().Substring(2).Trim()
            if ($comment -ne "" -and -not $comment.ToLower().Contains("todo")) {
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
    Write-Host "  Found $($kqlFiles.Count) queries" -ForegroundColor Gray
    
    foreach ($file in $kqlFiles) {
        Write-Host "  - $($file.Name)" -ForegroundColor DarkGray
        
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) {
            Write-Warning "  Skipping empty file: $($file.Name)"
            continue
        }
        
        $queryId = ConvertTo-BicepIdentifier "$categoryName-$($file.BaseName)"
        $displayName = Get-DisplayName $content $file.BaseName
        $escapedQuery = ConvertTo-BicepString $content
        
        if ($escapedQuery.Length -gt 0) {
            $queryObj = @{
                id = $queryId
                displayName = $displayName
                description = "Teams bot $categoryName monitoring query"
                category = $categoryName
                body = $escapedQuery
            }
            
            $allQueries += $queryObj
        }
    }
}

Write-Host ""
Write-Host "✓ Found $($allQueries.Count) total queries across $($categories.Count) categories" -ForegroundColor Green

# Show summary by category
Write-Host ""
Write-Host "Queries by category:" -ForegroundColor Cyan
$allQueries | Group-Object category | Sort-Object Name | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) queries" -ForegroundColor Yellow
}

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

// All Query Pack Queries (Generated from .kql files)
resource allQueries 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = [for query in queriesArray: {
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
      source: ['kql-files']
    }
  }
}]

// Complete queries array - ALL $($allQueries.Count) queries
var queriesArray = [
"@

# Add each query to the array
for ($i = 0; $i -lt $allQueries.Count; $i++) {
    $query = $allQueries[$i]
    $comma = if ($i -lt $allQueries.Count - 1) { "," } else { "" }
    
    $bicepTemplate += @"

  {
    id: '$($query.id)'
    displayName: '$($query.displayName)'
    description: '$($query.description)'
    category: '$($query.category)'
    body: '$($query.body)'
  }$comma
"@
}

$bicepTemplate += @"

]

output queryPackId string = queryPack.id
output queryPackName string = queryPack.name
output queriesCount int = length(queriesArray)
output categoriesIncluded array = union([], map(queriesArray, query => query.category))
"@

# Write the generated template
try {
    $bicepTemplate | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host ""
    Write-Host "✅ Generated Complete Query Pack: $OutputPath" -ForegroundColor Green
    Write-Host "📊 Total queries: $($allQueries.Count)" -ForegroundColor Green
    Write-Host "📁 Categories: $($categories.Count)" -ForegroundColor Green
    
    # Validate the generated file size
    $fileInfo = Get-Item $OutputPath
    $fileSizeKB = [math]::Round($fileInfo.Length / 1024, 2)
    Write-Host "📄 File size: $fileSizeKB KB" -ForegroundColor Green
    
    if ($fileSizeKB -gt 500) {
        Write-Warning "Large file generated ($fileSizeKB KB). Consider breaking into smaller Query Packs if deployment fails."
    }
    
} catch {
    Write-Error "Failed to write Bicep template: $_"
    exit 1
}

Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Replace simple queryPack.bicep with this complete version" -ForegroundColor White
Write-Host "2. Deploy with: .\deploy-query-pack.ps1" -ForegroundColor White
Write-Host "3. Find your $($allQueries.Count) queries in Azure Portal > Monitor > Query Packs" -ForegroundColor White
Write-Host ""
Write-Host "=== Generation Complete ===" -ForegroundColor Green
